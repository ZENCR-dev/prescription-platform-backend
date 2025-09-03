-- =====================================================
-- Auth Audit Logs Table for Session Validation Tracking
-- =====================================================
-- Purpose: Track all session validation attempts for compliance
-- Date: 2025-09-03
-- Part of: Task 3.3 - Session Validation with MFA Function
-- =====================================================

-- Create auth_audit_logs table for tracking validation attempts
CREATE TABLE IF NOT EXISTS public.auth_audit_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id TEXT,
    operation_type TEXT NOT NULL,
    resource_id TEXT,
    aal_level TEXT NOT NULL CHECK (aal_level IN ('aal1', 'aal2')),
    mfa_enrolled BOOLEAN NOT NULL DEFAULT false,
    validation_result BOOLEAN NOT NULL,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Indexes for query performance
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for common query patterns
CREATE INDEX idx_auth_audit_logs_user_id ON public.auth_audit_logs(user_id);
CREATE INDEX idx_auth_audit_logs_timestamp ON public.auth_audit_logs(timestamp DESC);
CREATE INDEX idx_auth_audit_logs_operation_type ON public.auth_audit_logs(operation_type);
CREATE INDEX idx_auth_audit_logs_validation_result ON public.auth_audit_logs(validation_result);

-- Create composite index for compliance reporting
CREATE INDEX idx_auth_audit_logs_compliance ON public.auth_audit_logs(
    user_id, 
    operation_type, 
    validation_result, 
    timestamp DESC
);

-- RLS Policies for auth_audit_logs
ALTER TABLE public.auth_audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own audit logs
CREATE POLICY "Users can view own audit logs" ON public.auth_audit_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Service role can insert audit logs (Edge Functions)
CREATE POLICY "Service role can insert audit logs" ON public.auth_audit_logs
    FOR INSERT
    WITH CHECK (true);  -- Service role bypass RLS

-- Policy: Admins can view all audit logs
CREATE POLICY "Admins can view all audit logs" ON public.auth_audit_logs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE user_profiles.id = auth.uid()
            AND user_profiles.role = 'admin'
        )
    );

-- Grant necessary permissions
GRANT SELECT ON public.auth_audit_logs TO authenticated;
GRANT INSERT ON public.auth_audit_logs TO service_role;

-- Add table comment
COMMENT ON TABLE public.auth_audit_logs IS 
'Audit trail for session validation attempts. 
Tracks MFA enforcement, operation types, and validation results.
Critical for HIPAA compliance and security monitoring.';

-- Add column comments
COMMENT ON COLUMN public.auth_audit_logs.operation_type IS 
'Type of operation being validated: read_only, profile_update, financial, medical, admin';

COMMENT ON COLUMN public.auth_audit_logs.aal_level IS 
'Authenticator Assurance Level: aal1 (password only) or aal2 (password + MFA)';

COMMENT ON COLUMN public.auth_audit_logs.validation_result IS 
'Whether the session validation passed (true) or failed (false)';

-- Create function to auto-cleanup old audit logs (keep 90 days for compliance)
CREATE OR REPLACE FUNCTION public.cleanup_old_audit_logs()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.auth_audit_logs
    WHERE timestamp < NOW() - INTERVAL '90 days';
END;
$$;

-- Schedule cleanup (would be done via pg_cron in production)
COMMENT ON FUNCTION public.cleanup_old_audit_logs() IS 
'Removes audit logs older than 90 days. Should be scheduled via pg_cron in production.';