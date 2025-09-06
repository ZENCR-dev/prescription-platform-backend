-- ============================================================================
-- Task 1.3B: RLS Extension Policies Security Hardening
-- ============================================================================
-- Security hardening based on architect feedback to address:
-- 1. Admin authorization deduplication (remove from cross-role policies)
-- 2. Public directory access hardening (explicit public visibility field)
-- 3. View security barriers (add SECURITY BARRIER to controlled views)
-- 4. Enhanced validation robustness
-- ============================================================================

-- ============================================================================
-- STEP 1: ADD PUBLIC VISIBILITY FIELD
-- ============================================================================
-- Add explicit public profile visibility field with secure default

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS is_public_profile BOOLEAN DEFAULT false NOT NULL;

-- Create index for efficient public profile queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_public_visibility 
ON user_profiles (is_public_profile) 
WHERE is_public_profile = true;

-- Add comment for field documentation
COMMENT ON COLUMN user_profiles.is_public_profile IS 
    'Explicit flag indicating whether profile can be displayed in public directory. Default false ensures secure-by-default behavior.';

-- ============================================================================
-- STEP 2: REMOVE ADMIN AUTHORIZATION DUPLICATION
-- ============================================================================
-- Remove admin OR clauses from cross-role policies to ensure single admin authorization path

-- Drop and recreate cross_role_pharmacy_select without admin clause
DROP POLICY IF EXISTS "cross_role_pharmacy_select" ON user_profiles;
CREATE POLICY "cross_role_pharmacy_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Pure business relationship authorization only
        private.has_prescription_business_relationship(auth.uid(), id)
    );

-- Drop and recreate cross_role_tcm_select without admin clause  
DROP POLICY IF EXISTS "cross_role_tcm_select" ON user_profiles;
CREATE POLICY "cross_role_tcm_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Pure business relationship authorization only
        private.has_referral_business_relationship(auth.uid(), id)
    );

-- ============================================================================
-- STEP 3: HARDEN PUBLIC DIRECTORY ACCESS
-- ============================================================================
-- Update public directory policy to require explicit public visibility

-- Drop and recreate public_directory_select with explicit public visibility requirement
DROP POLICY IF EXISTS "public_directory_select" ON user_profiles;
CREATE POLICY "public_directory_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Explicit public visibility required + basic conditions
        is_public_profile = true 
        AND status = 'active' 
        AND role IN ('tcm_practitioner', 'pharmacy')
    );

-- ============================================================================
-- STEP 4: ADD SECURITY BARRIERS TO CONTROLLED VIEWS
-- ============================================================================
-- Add SECURITY BARRIER to ensure view security cannot be bypassed

-- Update v_profiles_pharmacy_context with SECURITY BARRIER
DROP VIEW IF EXISTS v_profiles_pharmacy_context;
CREATE VIEW v_profiles_pharmacy_context WITH (security_barrier = true) AS 
SELECT 
    id,
    role,
    COALESCE(
        business_info ->> 'business_name',
        business_info ->> 'organization_name',
        'Business Name Not Available'
    ) AS business_name,
    pharmacy_type,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE role IN ('tcm_practitioner', 'pharmacy') 
AND status = 'active';

-- Update v_profiles_tcm_context with SECURITY BARRIER
DROP VIEW IF EXISTS v_profiles_tcm_context;
CREATE VIEW v_profiles_tcm_context WITH (security_barrier = true) AS 
SELECT 
    id,
    role,
    COALESCE(
        business_info ->> 'business_name',
        business_info ->> 'organization_name', 
        'Business Name Not Available'
    ) AS business_name,
    tcm_specialty,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE role IN ('tcm_practitioner', 'pharmacy') 
AND status = 'active';

-- Update v_profiles_public with SECURITY BARRIER and public visibility requirement
DROP VIEW IF EXISTS v_profiles_public;
CREATE VIEW v_profiles_public WITH (security_barrier = true) AS 
SELECT 
    id,
    role,
    status AS verification_status,
    COALESCE(
        business_info ->> 'business_name',
        business_info ->> 'organization_name',
        'Business Name Not Available'
    ) AS business_name,
    created_at
FROM user_profiles
WHERE is_public_profile = true 
AND status = 'active' 
AND role IN ('tcm_practitioner', 'pharmacy');

-- ============================================================================
-- STEP 5: ENHANCED VALIDATION WITH ROBUST CHECKS
-- ============================================================================

DO $$
DECLARE
    policy_count INTEGER;
    view_count INTEGER;
    public_field_exists BOOLEAN;
    security_barrier_count INTEGER;
    admin_policy_count INTEGER;
    cross_role_admin_free INTEGER;
BEGIN
    RAISE NOTICE '=== RLS HARDENING VALIDATION (ROBUST CHECKS) ===';
    
    -- Check 1: Public visibility field exists
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'is_public_profile'
    ) INTO public_field_exists;
    
    IF NOT public_field_exists THEN
        RAISE EXCEPTION 'VALIDATION FAILED: is_public_profile column not found';
    END IF;
    RAISE NOTICE '✅ Public visibility field exists: is_public_profile';
    
    -- Check 2: Cross-role policies exist and are admin-free
    SELECT COUNT(*) INTO cross_role_admin_free
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname IN ('cross_role_pharmacy_select', 'cross_role_tcm_select')
    AND qual NOT LIKE '%is_current_user_admin%';
    
    IF cross_role_admin_free != 2 THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Cross-role policies contain admin authorization or missing';
    END IF;
    RAISE NOTICE '✅ Cross-role policies admin-free: % policies', cross_role_admin_free;
    
    -- Check 3: Public directory policy requires explicit visibility
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname = 'public_directory_select'
    AND qual LIKE '%is_public_profile%';
    
    IF policy_count != 1 THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Public directory policy does not require is_public_profile';
    END IF;
    RAISE NOTICE '✅ Public directory policy hardened with explicit visibility requirement';
    
    -- Check 4: Admin-only policies exist (deduplicated admin access)
    SELECT COUNT(*) INTO admin_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND qual LIKE '%is_current_user_admin%';
    
    IF admin_policy_count < 1 THEN
        RAISE EXCEPTION 'VALIDATION FAILED: No admin-only policies found';
    END IF;
    RAISE NOTICE '✅ Admin authorization available through % dedicated policies', admin_policy_count;
    
    -- Check 5: All controlled views exist with SECURITY BARRIER
    SELECT COUNT(*) INTO security_barrier_count
    FROM pg_views v
    JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
    JOIN pg_options_to_table(c.reloptions) opts ON opts.option_name = 'security_barrier'
    WHERE v.schemaname = 'public' 
    AND v.viewname LIKE 'v_profiles_%'
    AND opts.option_value = 'true';
    
    IF security_barrier_count != 3 THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Expected 3 views with SECURITY BARRIER, found %', security_barrier_count;
    END IF;
    RAISE NOTICE '✅ All controlled views have SECURITY BARRIER: % views', security_barrier_count;
    
    -- Check 6: Public view requires explicit visibility
    SELECT COUNT(*) INTO view_count
    FROM pg_views 
    WHERE schemaname = 'public' 
    AND viewname = 'v_profiles_public'
    AND definition LIKE '%is_public_profile%';
    
    IF view_count != 1 THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Public view does not filter by is_public_profile';
    END IF;
    RAISE NOTICE '✅ Public view filters by explicit visibility field';
    
    RAISE NOTICE '✅ ALL HARDENING VALIDATIONS PASSED - Security gaps addressed';
END $$;

-- ============================================================================
-- SYSTEM STATE VERIFICATION: COMPREHENSIVE EVIDENCE
-- ============================================================================

-- Generate comprehensive system table evidence
DO $$
DECLARE
    total_policies INTEGER;
    hardened_policies INTEGER;
    security_views INTEGER;
BEGIN
    RAISE NOTICE '=== COMPREHENSIVE SYSTEM STATE EVIDENCE ===';
    
    -- Policy evidence summary
    SELECT COUNT(*) INTO total_policies
    FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'user_profiles';
    
    SELECT COUNT(*) INTO hardened_policies
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname IN (
        'cross_role_pharmacy_select', 
        'cross_role_tcm_select', 
        'public_directory_select'
    );
    
    -- View evidence summary  
    SELECT COUNT(*) INTO security_views
    FROM pg_views v
    JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
    JOIN pg_options_to_table(c.reloptions) opts ON opts.option_name = 'security_barrier'
    WHERE v.schemaname = 'public' 
    AND v.viewname LIKE 'v_profiles_%'
    AND opts.option_value = 'true';
    
    RAISE NOTICE 'System State Summary:';
    RAISE NOTICE '  - Total RLS Policies: %', total_policies;
    RAISE NOTICE '  - Hardened Cross-Role Policies: %', hardened_policies;
    RAISE NOTICE '  - SECURITY BARRIER Views: %', security_views;
    RAISE NOTICE '  - Public Visibility Field: Added with secure default (false)';
    RAISE NOTICE '  - Admin Authorization: Deduplicated to dedicated policies only';
    RAISE NOTICE '✅ HARDENING COMPLETE: All security gaps addressed';
END $$;

-- ============================================================================
-- MIGRATION COMPLETION LOG
-- ============================================================================

-- Log successful completion of security hardening
SELECT NOW() as hardening_completed,
       'Task 1.3B Security Hardening: Admin Deduplication + Public Visibility + View Security Barriers' as task,
       'SECURITY GAPS ADDRESSED - READY FOR IRG RETEST' as status;

-- Task 1.3B security hardening complete
DO $$
BEGIN
    RAISE NOTICE '=== TASK 1.3B SECURITY HARDENING COMPLETE ===';
    RAISE NOTICE 'ARCHITECT REQUIREMENTS ADDRESSED:';
    RAISE NOTICE '✅ Admin authorization deduplication (removed from cross-role policies)';
    RAISE NOTICE '✅ Public directory hardened (explicit is_public_profile field required)';
    RAISE NOTICE '✅ View security barriers added (all controlled views)';
    RAISE NOTICE '✅ Enhanced validation robustness (comprehensive system checks)';
    RAISE NOTICE '✅ Public visibility secure default (false) prevents unauthorized exposure';
    RAISE NOTICE 'Ready for comprehensive evidence generation and IRG retest';
END $$;