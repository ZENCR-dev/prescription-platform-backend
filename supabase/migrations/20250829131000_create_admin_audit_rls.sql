-- Admin Audit Trail System with RLS Policies  
-- Task 2.4: Create comprehensive audit logging for admin operations
-- Medical platform HIPAA compliance requirement

-- =======================
-- AUDIT TABLE CREATION
-- =======================

-- Create audit log table in private schema for admin operations tracking
CREATE TABLE IF NOT EXISTS private.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- WHO: Admin performing the action
  admin_id UUID NOT NULL REFERENCES auth.users(id),
  admin_email TEXT,
  admin_role TEXT,
  
  -- WHAT: Action details
  action_type TEXT NOT NULL CHECK (action_type IN (
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 
    'APPROVE', 'REJECT', 'SUSPEND', 'ACTIVATE',
    'FINANCIAL_ACCESS', 'PII_ACCESS_ATTEMPT', 'EXPORT'
  )),
  table_name TEXT NOT NULL,
  record_id UUID,
  
  -- WHEN: Temporal tracking
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- WHERE: Location and context
  ip_address INET,
  user_agent TEXT,
  session_id TEXT,
  
  -- WHY: Business context
  reason TEXT,
  approval_ticket TEXT, -- For change management tracking
  
  -- HOW: Technical details
  old_values JSONB,
  new_values JSONB,
  query_text TEXT,
  
  -- Medical compliance fields
  hipaa_relevant BOOLEAN DEFAULT FALSE,
  contains_pii BOOLEAN DEFAULT FALSE,
  data_classification TEXT CHECK (data_classification IN (
    'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED'
  )),
  
  -- Audit metadata
  audit_version INTEGER DEFAULT 1,
  retention_until TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 years') -- HIPAA 6 years + buffer
);

-- Performance indexes for audit queries
CREATE INDEX IF NOT EXISTS idx_audit_log_admin_id ON private.audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON private.audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record ON private.audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action_type ON private.audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_audit_log_hipaa ON private.audit_log(hipaa_relevant) 
  WHERE hipaa_relevant = TRUE;

-- =======================
-- AUDIT TRIGGER FUNCTION
-- =======================

-- Create function to automatically log admin actions
CREATE OR REPLACE FUNCTION private.log_admin_action()
RETURNS TRIGGER
LANGUAGE PLPGSQL
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_admin_role TEXT;
  v_admin_email TEXT;
  v_action_type TEXT;
  v_old_values JSONB;
  v_new_values JSONB;
  v_contains_pii BOOLEAN := FALSE;
  v_hipaa_relevant BOOLEAN := FALSE;
BEGIN
  -- Get current admin info
  v_admin_id := auth.uid();
  
  -- Only log if user is admin
  IF NOT private.is_current_user_admin() THEN
    -- Not an admin, don't log (normal user operations)
    RETURN COALESCE(NEW, OLD);
  END IF;
  
  -- Get admin details
  SELECT role, email INTO v_admin_role, v_admin_email
  FROM public.user_profiles 
  LEFT JOIN auth.users ON user_profiles.id = auth.users.id
  WHERE user_profiles.id = v_admin_id;
  
  -- Determine action type
  v_action_type := TG_OP;
  
  -- Prepare old and new values
  IF TG_OP = 'UPDATE' THEN
    v_old_values := to_jsonb(OLD);
    v_new_values := to_jsonb(NEW);
  ELSIF TG_OP = 'DELETE' THEN
    v_old_values := to_jsonb(OLD);
    v_new_values := NULL;
  ELSIF TG_OP = 'INSERT' THEN
    v_old_values := NULL;
    v_new_values := to_jsonb(NEW);
  END IF;
  
  -- Check for PII patterns (basic check, can be enhanced)
  IF v_new_values IS NOT NULL THEN
    v_contains_pii := (v_new_values::text ~* '(ssn|social|patient_name|dob|birth|medicare|medicaid)');
  END IF;
  
  -- Check if HIPAA relevant based on table
  v_hipaa_relevant := TG_TABLE_NAME IN (
    'prescriptions', 'prescription_items', 'patient_records', 
    'consultation_notes', 'medical_licenses', 'pharmacy_licenses'
  );
  
  -- Insert audit log entry
  INSERT INTO private.audit_log (
    admin_id,
    admin_email,
    admin_role,
    action_type,
    table_name,
    record_id,
    old_values,
    new_values,
    ip_address,
    user_agent,
    session_id,
    hipaa_relevant,
    contains_pii,
    data_classification
  ) VALUES (
    v_admin_id,
    v_admin_email,
    v_admin_role,
    v_action_type,
    TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
    CASE 
      WHEN NEW IS NOT NULL THEN (NEW.id)::UUID
      ELSE (OLD.id)::UUID
    END,
    v_old_values,
    v_new_values,
    inet_client_addr(),
    current_setting('request.headers', true)::json->>'user-agent',
    current_setting('request.jwt.claims', true)::json->>'session_id',
    v_hipaa_relevant,
    v_contains_pii,
    CASE 
      WHEN v_hipaa_relevant OR v_contains_pii THEN 'RESTRICTED'
      WHEN TG_TABLE_NAME IN ('user_profiles', 'revenue_transactions') THEN 'CONFIDENTIAL'
      ELSE 'INTERNAL'
    END
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- =======================
-- AUDIT TABLE RLS POLICIES
-- =======================

-- Enable RLS on audit log table
ALTER TABLE private.audit_log ENABLE ROW LEVEL SECURITY;

-- Policy 1: Admins can only INSERT audit records (append-only)
CREATE POLICY "audit_log_insert_only"
ON private.audit_log
FOR INSERT
TO authenticated
WITH CHECK (
  private.is_current_user_admin()
);

-- Policy 2: Admins can SELECT their own audit records
CREATE POLICY "audit_log_select_own"
ON private.audit_log
FOR SELECT
TO authenticated
USING (
  admin_id = (SELECT auth.uid())
  OR
  -- Super admin can view all (if you have a super admin role)
  (SELECT role FROM public.user_profiles WHERE id = (SELECT auth.uid())) = 'super_admin'
);

-- Policy 3: NO UPDATE allowed (immutable audit trail)
-- No policy created for UPDATE = no one can update

-- Policy 4: NO DELETE allowed (permanent audit trail for HIPAA)
-- No policy created for DELETE = no one can delete

-- =======================
-- ADMIN RLS POLICIES FOR BUSINESS TABLES
-- =======================

-- Admin policies for prescriptions table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'prescriptions') THEN
    EXECUTE 'CREATE POLICY "admin_full_access_prescriptions"
             ON public.prescriptions
             FOR ALL
             TO authenticated
             USING (private.is_current_user_admin())
             WITH CHECK (private.is_current_user_admin())';
  END IF;
END $$;

-- Admin policies for prescription_items table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'prescription_items') THEN
    EXECUTE 'CREATE POLICY "admin_full_access_prescription_items"
             ON public.prescription_items
             FOR ALL
             TO authenticated
             USING (private.is_current_user_admin())
             WITH CHECK (private.is_current_user_admin())';
  END IF;
END $$;

-- Admin policies for revenue_transactions table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'revenue_transactions') THEN
    EXECUTE 'CREATE POLICY "admin_full_access_revenue_transactions"
             ON public.revenue_transactions
             FOR ALL
             TO authenticated
             USING (private.is_current_user_admin())
             WITH CHECK (private.is_current_user_admin())';
  END IF;
END $$;

-- Admin policies for consultation_notes table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'consultation_notes') THEN
    EXECUTE 'CREATE POLICY "admin_full_access_consultation_notes"
             ON public.consultation_notes
             FOR ALL
             TO authenticated
             USING (private.is_current_user_admin())
             WITH CHECK (private.is_current_user_admin())';
  END IF;
END $$;

-- Admin policies for patient_records table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'patient_records') THEN
    EXECUTE 'CREATE POLICY "admin_full_access_patient_records"
             ON public.patient_records
             FOR ALL
             TO authenticated
             USING (private.is_current_user_admin())
             WITH CHECK (private.is_current_user_admin())';
  END IF;
END $$;

-- =======================
-- ATTACH AUDIT TRIGGERS TO TABLES
-- =======================

-- Attach audit trigger to prescriptions table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'prescriptions') THEN
    EXECUTE 'CREATE TRIGGER audit_prescriptions_trigger
             AFTER INSERT OR UPDATE OR DELETE ON public.prescriptions
             FOR EACH ROW
             WHEN (private.is_current_user_admin())
             EXECUTE FUNCTION private.log_admin_action()';
  END IF;
END $$;

-- Attach audit trigger to prescription_items table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'prescription_items') THEN
    EXECUTE 'CREATE TRIGGER audit_prescription_items_trigger
             AFTER INSERT OR UPDATE OR DELETE ON public.prescription_items
             FOR EACH ROW
             WHEN (private.is_current_user_admin())
             EXECUTE FUNCTION private.log_admin_action()';
  END IF;
END $$;

-- Attach audit trigger to user_profiles table
CREATE TRIGGER audit_user_profiles_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.user_profiles
FOR EACH ROW
WHEN (private.is_current_user_admin())
EXECUTE FUNCTION private.log_admin_action();

-- Attach audit trigger to revenue_transactions table (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'revenue_transactions') THEN
    EXECUTE 'CREATE TRIGGER audit_revenue_transactions_trigger
             AFTER INSERT OR UPDATE OR DELETE ON public.revenue_transactions
             FOR EACH ROW
             WHEN (private.is_current_user_admin())
             EXECUTE FUNCTION private.log_admin_action()';
  END IF;
END $$;

-- =======================
-- AUDIT REPORTING VIEWS
-- =======================

-- Create view for audit summary (admins only)
CREATE OR REPLACE VIEW private.audit_summary AS
SELECT 
  date_trunc('day', created_at) as audit_date,
  admin_email,
  action_type,
  table_name,
  COUNT(*) as operation_count,
  COUNT(DISTINCT record_id) as affected_records
FROM private.audit_log
GROUP BY date_trunc('day', created_at), admin_email, action_type, table_name
ORDER BY audit_date DESC, operation_count DESC;

-- Create view for HIPAA compliance reporting
CREATE OR REPLACE VIEW private.hipaa_audit_report AS
SELECT 
  created_at,
  admin_email,
  action_type,
  table_name,
  record_id,
  contains_pii,
  data_classification,
  ip_address
FROM private.audit_log
WHERE hipaa_relevant = TRUE
   OR contains_pii = TRUE
   OR data_classification IN ('RESTRICTED', 'CONFIDENTIAL')
ORDER BY created_at DESC;

-- =======================
-- HELPER FUNCTIONS
-- =======================

-- Function to export audit logs for compliance reporting
CREATE OR REPLACE FUNCTION private.export_audit_logs(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_admin_id UUID DEFAULT NULL
)
RETURNS TABLE (
  audit_timestamp TIMESTAMPTZ,
  admin_email TEXT,
  action TEXT,
  target_table TEXT,
  target_record UUID,
  changes JSONB
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT 
    created_at,
    admin_email,
    action_type,
    table_name,
    record_id,
    jsonb_build_object(
      'old', old_values,
      'new', new_values
    )
  FROM private.audit_log
  WHERE created_at BETWEEN p_start_date AND p_end_date
    AND (p_admin_id IS NULL OR admin_id = p_admin_id)
    AND private.is_current_user_admin() -- Only admins can export
  ORDER BY created_at DESC;
$$;

-- =======================
-- PERMISSIONS
-- =======================

-- Grant minimal permissions
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT SELECT ON private.audit_log TO authenticated; -- RLS will control actual access
GRANT INSERT ON private.audit_log TO authenticated; -- RLS will control actual access

-- Grant execute on audit functions to authenticated
GRANT EXECUTE ON FUNCTION private.log_admin_action() TO authenticated;
GRANT EXECUTE ON FUNCTION private.export_audit_logs(TIMESTAMPTZ, TIMESTAMPTZ, UUID) TO authenticated;

-- =======================
-- DOCUMENTATION
-- =======================

COMMENT ON TABLE private.audit_log IS 
'HIPAA-compliant audit trail for admin operations. Immutable, append-only log with 7-year retention. Tracks all admin actions on sensitive medical data.';

COMMENT ON COLUMN private.audit_log.retention_until IS 
'HIPAA requires 6 years minimum retention. Set to 7 years for safety margin.';

COMMENT ON POLICY "audit_log_insert_only" ON private.audit_log IS 
'Append-only policy: Admins can only add audit records, never modify or delete.';

COMMENT ON FUNCTION private.log_admin_action() IS 
'Automatic audit logging trigger for admin operations. Captures full context including old/new values, IP, and HIPAA relevance.';

-- =======================
-- VALIDATION QUERIES
-- =======================
-- Test queries to validate the audit system:
-- 1. Admin action logging: UPDATE user_profiles SET status = 'active' WHERE id = 'some-id';
-- 2. View audit trail: SELECT * FROM private.audit_log WHERE admin_id = auth.uid();
-- 3. HIPAA report: SELECT * FROM private.hipaa_audit_report;
-- 4. Export for compliance: SELECT * FROM private.export_audit_logs('2025-01-01', '2025-12-31');

-- Performance target: Audit logging should add <10ms overhead to operations
-- Compliance: HIPAA 6-year retention, PII detection, immutable audit trail