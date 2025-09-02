-- =====================================================
-- RLS Decision Implementation for License Verifications
-- =====================================================
-- Decision: Option A - Service Role Only Write Access
-- Date: 2025-09-02
-- Rationale: Edge Function使用service_role进行数据写入，确保安全性
-- =====================================================

-- Revoke INSERT permission from authenticated role
-- This ensures only Edge Functions with service_role can write
REVOKE INSERT ON public.license_verifications FROM authenticated;

-- Revoke UPDATE permission as well (for consistency)
REVOKE UPDATE ON public.license_verifications FROM authenticated;

-- Ensure SELECT permission remains (users can view their own records)
-- This is already granted, but we explicitly confirm it
GRANT SELECT ON public.license_verifications TO authenticated;

-- Document the security model
COMMENT ON TABLE public.license_verifications IS 
'License verification records table. 
Write access: Only via Edge Functions using service_role key.
Read access: Users can SELECT their own records via RLS policies.
Security model: Edge Function acts as trusted intermediary for all write operations.';

-- Add security notice to relevant columns
COMMENT ON COLUMN public.license_verifications.user_id IS 
'User ID from auth.users. RLS policy ensures users can only view their own records.';

COMMENT ON COLUMN public.license_verifications.status IS 
'Verification status managed by Edge Function state machine. Cannot be directly modified by clients.';