-- ============================================================================
-- INTEGRATION ENVIRONMENT VIEW DEPLOYMENT SCRIPT
-- ============================================================================
-- Purpose: Deploy controlled views to integration environment for frontend IRG testing
-- Date: 2025-09-07
-- Target: Frontend integration environment
-- Evidence: Addresses architect directive for missing views blocking IRG
-- ============================================================================

\echo '=== INTEGRATION ENVIRONMENT VIEW DEPLOYMENT ==='

-- ============================================================================
-- PRE-DEPLOYMENT VALIDATION
-- ============================================================================

-- Check if base table exists
DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE EXCEPTION 'DEPLOYMENT FAILED: user_profiles table does not exist in integration environment';
    END IF;
    
    RAISE NOTICE '✅ Base table validation passed: user_profiles exists';
END $$;

-- ============================================================================
-- HELPER FUNCTIONS DEPLOYMENT
-- ============================================================================

-- Function: get_current_user_id (simple auth.uid() wrapper)
CREATE OR REPLACE FUNCTION private.get_current_user_id()
RETURNS UUID
LANGUAGE SQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
    SELECT auth.uid();
$$;

-- Function: has_prescription_business_relationship
CREATE OR REPLACE FUNCTION private.has_prescription_business_relationship(
    requester_id UUID, 
    target_id UUID
)
RETURNS BOOLEAN
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    -- Business relationship validation for prescription workflow
    RETURN EXISTS (
        SELECT 1 
        FROM user_profiles requester, user_profiles target
        WHERE requester.id = requester_id 
        AND target.id = target_id
        AND (
            (requester.role = 'pharmacy' AND target.role = 'tcm_practitioner') OR
            (requester.role = 'tcm_practitioner' AND target.role = 'pharmacy')
        )
        AND requester.status = 'active'
        AND target.status = 'active'
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id IN (requester_id, target_id) 
            AND business_info IS NOT NULL
        )
    );
END $$;

-- Function: has_referral_business_relationship
CREATE OR REPLACE FUNCTION private.has_referral_business_relationship(
    requester_id UUID, 
    target_id UUID
)
RETURNS BOOLEAN
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    -- Business relationship validation for referral workflow
    RETURN EXISTS (
        SELECT 1 
        FROM user_profiles requester, user_profiles target
        WHERE requester.id = requester_id 
        AND target.id = target_id
        AND (
            (requester.role = 'tcm_practitioner' AND target.role = 'pharmacy') OR
            (requester.role = 'pharmacy' AND target.role = 'tcm_practitioner')
        )
        AND requester.status = 'active'
        AND target.status = 'active'
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id IN (requester_id, target_id) 
            AND business_info IS NOT NULL
        )
    );
END $$;

-- Function: get_current_user_role
CREATE OR REPLACE FUNCTION private.get_current_user_role()
RETURNS TEXT
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role
    FROM user_profiles 
    WHERE id = auth.uid();
    
    IF user_role NOT IN ('tcm_practitioner', 'pharmacy', 'admin') THEN
        RAISE WARNING 'Non-canonical role detected: %. Expected: tcm_practitioner, pharmacy, admin', user_role;
        RETURN NULL;
    END IF;
    
    RETURN user_role;
END $$;

-- Function: is_current_user_admin
CREATE OR REPLACE FUNCTION private.is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    RETURN (
        SELECT role = 'admin'
        FROM user_profiles 
        WHERE id = auth.uid()
    );
END $$;

-- Update function volatility to STABLE as required by architect
ALTER FUNCTION private.get_current_user_id() STABLE;
ALTER FUNCTION private.has_prescription_business_relationship(uuid, uuid) STABLE;
ALTER FUNCTION private.has_referral_business_relationship(uuid, uuid) STABLE;
ALTER FUNCTION private.get_current_user_role() STABLE;
ALTER FUNCTION private.is_current_user_admin() STABLE;

RAISE NOTICE '✅ Helper functions deployed with SECURITY DEFINER + STABLE + fixed search_path';

-- ============================================================================
-- CONTROLLED VIEWS DEPLOYMENT
-- ============================================================================

-- Clean up existing views if they exist
DROP VIEW IF EXISTS public.v_profiles_tcm_context CASCADE;
DROP VIEW IF EXISTS public.v_profiles_pharmacy_context CASCADE;
DROP VIEW IF EXISTS public.v_profiles_public CASCADE;

-- View 1: v_profiles_tcm_context (TCM practitioners visible to pharmacy users)
CREATE VIEW public.v_profiles_tcm_context AS 
SELECT 
    id,
    role,
    COALESCE(
        business_info->>'business_name', 
        business_info->>'organization_name', 
        business_name::text, 
        'Business Name Not Available'
    ) AS business_name,
    tcm_specialty,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE 
    role::text = 'tcm_practitioner'::text 
    AND status::text = 'active'::text 
    AND private.has_prescription_business_relationship(private.get_current_user_id(), id);

-- View 2: v_profiles_pharmacy_context (Pharmacies visible to TCM practitioners) 
CREATE VIEW public.v_profiles_pharmacy_context AS
SELECT 
    id,
    role,
    COALESCE(
        business_info->>'business_name', 
        business_info->>'organization_name', 
        business_name::text, 
        'Business Name Not Available'
    ) AS business_name,
    pharmacy_type,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE 
    role::text = 'pharmacy'::text 
    AND status::text = 'active'::text 
    AND private.has_referral_business_relationship(private.get_current_user_id(), id);

-- View 3: v_profiles_public (Public directory)
CREATE VIEW public.v_profiles_public AS
SELECT 
    id,
    role,
    status AS verification_status,
    COALESCE(
        business_info->>'business_name', 
        business_info->>'organization_name', 
        business_name::text, 
        'Business Name Not Available'
    ) AS business_name,
    created_at
FROM user_profiles
WHERE 
    is_public_profile = true 
    AND status::text = 'active'::text 
    AND (role::text = ANY (ARRAY['tcm_practitioner'::character varying, 'pharmacy'::character varying]::text[]));

RAISE NOTICE '✅ Controlled views created with business relationship filtering';

-- ============================================================================
-- SECURITY BARRIER CONFIGURATION
-- ============================================================================

-- Set security_barrier=true for all views
ALTER VIEW public.v_profiles_tcm_context SET (security_barrier=true);
ALTER VIEW public.v_profiles_pharmacy_context SET (security_barrier=true);
ALTER VIEW public.v_profiles_public SET (security_barrier=true);

RAISE NOTICE '✅ Security barriers enabled on all controlled views';

-- ============================================================================
-- PERMISSION GRANTS
-- ============================================================================

-- Grant schema usage and view access to authenticated role
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA private TO authenticated;

-- Grant SELECT permissions on all controlled views
GRANT SELECT ON public.v_profiles_tcm_context TO authenticated;
GRANT SELECT ON public.v_profiles_pharmacy_context TO authenticated;
GRANT SELECT ON public.v_profiles_public TO authenticated;

-- Grant EXECUTE permissions on helper functions
GRANT EXECUTE ON FUNCTION private.get_current_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_prescription_business_relationship(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_referral_business_relationship(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.get_current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_current_user_admin() TO authenticated;

RAISE NOTICE '✅ Permissions granted to authenticated role for PostgREST access';

-- ============================================================================
-- DEPLOYMENT VERIFICATION
-- ============================================================================

-- Verify all views exist and are accessible
DO $$
DECLARE
    view_count INTEGER;
    expected_views TEXT[] := ARRAY[
        'v_profiles_tcm_context',
        'v_profiles_pharmacy_context',
        'v_profiles_public'
    ];
    view_name TEXT;
BEGIN
    RAISE NOTICE '=== DEPLOYMENT VERIFICATION ===';
    
    FOREACH view_name IN ARRAY expected_views
    LOOP
        SELECT COUNT(*) INTO view_count
        FROM information_schema.views
        WHERE table_schema = 'public' 
        AND table_name = view_name;
        
        IF view_count = 0 THEN
            RAISE EXCEPTION 'DEPLOYMENT FAILED: View % not created', view_name;
        END IF;
        
        RAISE NOTICE '✅ View % created successfully', view_name;
    END LOOP;
    
    RAISE NOTICE '✅ DEPLOYMENT VERIFICATION PASSED: All controlled views deployed';
END $$;

-- Add view documentation
COMMENT ON VIEW public.v_profiles_tcm_context IS 
    'Integration deployment: TCM context view for pharmacy users with business relationship filtering';
COMMENT ON VIEW public.v_profiles_pharmacy_context IS 
    'Integration deployment: Pharmacy context view for TCM users with business relationship filtering';
COMMENT ON VIEW public.v_profiles_public IS 
    'Integration deployment: Public directory view with is_public_profile filtering';

-- Log deployment completion
SELECT NOW() as deployment_completed,
       'Integration Environment Controlled Views' as deployment_target,
       'SUCCESS: Three views deployed with security barriers and permissions' as status;

\echo '=== INTEGRATION ENVIRONMENT VIEW DEPLOYMENT COMPLETE ===';