-- =====================================================
-- TCM Practitioner RLS Policies - Authentication Only (M1.1 Scope)
-- =====================================================
-- Purpose: Practitioner-specific authentication and profile access
-- Scope: Limited to M1.1 authentication infrastructure
-- Note: Full practitioner RLS for prescriptions will be in M2
-- =====================================================

-- Create private schema if not exists
CREATE SCHEMA IF NOT EXISTS private;

-- =====================================================
-- 1. SECURITY DEFINER FUNCTIONS FOR PRACTITIONERS
-- =====================================================

-- Function to get current practitioner ID (optimized)
CREATE OR REPLACE FUNCTION private.get_current_practitioner_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = private, public
AS $$
  SELECT id 
  FROM public.user_profiles 
  WHERE id = auth.uid() 
    AND role = 'tcm_practitioner'
    AND status = 'active'
  LIMIT 1;
$$;

-- Function to check if user is active practitioner
CREATE OR REPLACE FUNCTION private.is_active_practitioner()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = private, public
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM public.user_profiles 
    WHERE id = auth.uid() 
      AND role = 'tcm_practitioner'
      AND status = 'active'
    LIMIT 1
  );
$$;

-- Function to verify practitioner license status (placeholder for M1.5)
CREATE OR REPLACE FUNCTION private.is_practitioner_licensed()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = private, public
AS $$
  -- For M1.1, check basic profile completion
  -- M1.5 will add actual license verification
  SELECT EXISTS (
    SELECT 1 
    FROM public.user_profiles 
    WHERE id = auth.uid() 
      AND role = 'tcm_practitioner'
      AND status = 'active'
      AND business_info IS NOT NULL
      AND business_info->>'license_number' IS NOT NULL
    LIMIT 1
  );
$$;

-- =====================================================
-- 2. PRACTITIONER-SPECIFIC USER PROFILE POLICIES
-- =====================================================

-- Drop existing practitioner policies if any
DROP POLICY IF EXISTS "Practitioners view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Practitioners update own profile" ON public.user_profiles;

-- Practitioner can view their own profile
CREATE POLICY "Practitioners view own profile"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() 
    AND role = 'tcm_practitioner'
  );

-- Practitioner can update their own profile (restricted fields)
CREATE POLICY "Practitioners update own profile"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() 
    AND role = 'tcm_practitioner'
  )
  WITH CHECK (
    id = auth.uid()
    AND role = 'tcm_practitioner'
    -- Cannot change their own role or ID
    AND role = (SELECT role FROM public.user_profiles WHERE id = auth.uid())
  );

-- =====================================================
-- 3. PRACTITIONER AUDIT LOG (M1.1 Authentication Scope)
-- =====================================================

-- Create practitioner authentication audit log
CREATE TABLE IF NOT EXISTS private.practitioner_auth_audit (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  practitioner_id uuid NOT NULL REFERENCES auth.users(id),
  event_type text NOT NULL CHECK (event_type IN (
    'login', 'logout', 'profile_update', 'license_check', 
    'mfa_enabled', 'mfa_disabled', 'password_change'
  )),
  event_data jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Create index for audit queries
CREATE INDEX IF NOT EXISTS idx_practitioner_auth_audit_practitioner_id 
  ON private.practitioner_auth_audit(practitioner_id);
CREATE INDEX IF NOT EXISTS idx_practitioner_auth_audit_created_at 
  ON private.practitioner_auth_audit(created_at DESC);

-- Enable RLS on audit log
ALTER TABLE private.practitioner_auth_audit ENABLE ROW LEVEL SECURITY;

-- Practitioners can view their own audit log
CREATE POLICY "Practitioners view own auth audit"
  ON private.practitioner_auth_audit
  FOR SELECT
  TO authenticated
  USING (
    practitioner_id = auth.uid()
    AND private.is_active_practitioner()
  );

-- =====================================================
-- 4. HELPER FUNCTIONS FOR PRACTITIONER VALIDATION
-- =====================================================

-- Function to validate practitioner business info
CREATE OR REPLACE FUNCTION private.validate_practitioner_business_info(info jsonb)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  -- Check required fields for practitioner
  IF info IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Required fields for TCM practitioner
  IF info->>'practice_name' IS NULL OR 
     info->>'license_number' IS NULL OR
     info->>'registration_number' IS NULL THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$;

-- =====================================================
-- 5. PERFORMANCE OPTIMIZATION INDEXES
-- =====================================================

-- Create composite index for practitioner queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_practitioner_status
  ON public.user_profiles(id, role, status)
  WHERE role = 'tcm_practitioner';

-- =====================================================
-- 6. DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION private.get_current_practitioner_id() IS 
'Returns current user ID if they are an active TCM practitioner, NULL otherwise';

COMMENT ON FUNCTION private.is_active_practitioner() IS 
'Checks if current user is an active TCM practitioner';

COMMENT ON FUNCTION private.is_practitioner_licensed() IS 
'Checks if practitioner has valid license info (full verification in M1.5)';

COMMENT ON TABLE private.practitioner_auth_audit IS 
'Audit log for practitioner authentication events (M1.1 scope)';

COMMENT ON FUNCTION private.validate_practitioner_business_info(jsonb) IS 
'Validates required business information for TCM practitioners';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration creates practitioner-specific authentication
-- infrastructure for M1.1. Full practitioner RLS for prescriptions
-- and medical data will be implemented in M2 modules.