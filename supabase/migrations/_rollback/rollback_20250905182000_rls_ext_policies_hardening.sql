-- ============================================================================
-- Rollback: Task 1.3B RLS Extension Policies Security Hardening
-- ============================================================================
-- Complete rollback of 20250905182000_rls_ext_policies_hardening migration
-- Target: Restore original state before security hardening
-- Scope: Remove public visibility field, restore admin OR clauses, remove security barriers
-- ============================================================================

-- ============================================================================
-- ROLLBACK VALIDATION: PRE-ROLLBACK STATUS CHECK
-- ============================================================================

DO $$
DECLARE
    public_field_exists BOOLEAN;
    hardened_policy_count INTEGER;
    security_barrier_count INTEGER;
    target_components INTEGER := 0;
BEGIN
    RAISE NOTICE '=== ROLLBACK VALIDATION: PRE-ROLLBACK STATUS ==='
    
    -- Check if public visibility field exists
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'is_public_profile'
    ) INTO public_field_exists;
    
    IF public_field_exists THEN
        RAISE NOTICE '🎯 Target field found: is_public_profile (will be removed)';
        target_components := target_components + 1;
    ELSE
        RAISE NOTICE '⚠️ Public visibility field not found (may have been manually removed)';
    END IF;
    
    -- Check hardened policies
    SELECT COUNT(*) INTO hardened_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname IN ('cross_role_pharmacy_select', 'cross_role_tcm_select', 'public_directory_select')
    AND qual NOT LIKE '%is_current_user_admin%';
    
    IF hardened_policy_count > 0 THEN
        RAISE NOTICE '🎯 Found % hardened policies (will restore admin clauses)', hardened_policy_count;
        target_components := target_components + hardened_policy_count;
    END IF;
    
    -- Check SECURITY BARRIER views
    SELECT COUNT(*) INTO security_barrier_count
    FROM pg_views v
    JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
    LEFT JOIN pg_options_to_table(c.reloptions) opts ON opts.option_name = 'security_barrier'
    WHERE v.schemaname = 'public' 
    AND v.viewname LIKE 'v_profiles_%'
    AND COALESCE(opts.option_value, 'false') = 'true';
    
    IF security_barrier_count > 0 THEN
        RAISE NOTICE '🎯 Found % SECURITY BARRIER views (will remove barriers)', security_barrier_count;
        target_components := target_components + security_barrier_count;
    END IF;
    
    -- Summary of rollback scope
    IF target_components > 0 THEN
        RAISE NOTICE '✅ Rollback scope: % components will be reverted', target_components;
    ELSE
        RAISE NOTICE '⚠️ No hardening components found - rollback may be unnecessary';
    END IF;
END $$;

-- ============================================================================
-- STEP 1: RESTORE ORIGINAL POLICIES WITH ADMIN OR CLAUSES
-- ============================================================================

-- Restore cross_role_pharmacy_select with admin OR clause
DROP POLICY IF EXISTS "cross_role_pharmacy_select" ON user_profiles;
CREATE POLICY "cross_role_pharmacy_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Restore original admin OR clause
        private.has_prescription_business_relationship(auth.uid(), id) OR
        private.is_current_user_admin()
    );

-- Restore cross_role_tcm_select with admin OR clause
DROP POLICY IF EXISTS "cross_role_tcm_select" ON user_profiles;
CREATE POLICY "cross_role_tcm_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Restore original admin OR clause
        private.has_referral_business_relationship(auth.uid(), id) OR
        private.is_current_user_admin()
    );

-- Restore public_directory_select with original conditions and admin OR clause
DROP POLICY IF EXISTS "public_directory_select" ON user_profiles;
CREATE POLICY "public_directory_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Restore original conditions without is_public_profile requirement
        (status = 'active' AND role IN ('tcm_practitioner', 'pharmacy')) OR
        private.is_current_user_admin()
    );

-- ============================================================================
-- STEP 2: REMOVE SECURITY BARRIERS FROM VIEWS
-- ============================================================================

-- Restore v_profiles_pharmacy_context without SECURITY BARRIER
DROP VIEW IF EXISTS v_profiles_pharmacy_context;
CREATE VIEW v_profiles_pharmacy_context AS 
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

-- Restore v_profiles_tcm_context without SECURITY BARRIER  
DROP VIEW IF EXISTS v_profiles_tcm_context;
CREATE VIEW v_profiles_tcm_context AS 
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

-- Restore v_profiles_public without SECURITY BARRIER and without is_public_profile
DROP VIEW IF EXISTS v_profiles_public;
CREATE VIEW v_profiles_public AS 
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
WHERE status = 'active' 
AND role IN ('tcm_practitioner', 'pharmacy');

-- ============================================================================
-- STEP 3: REMOVE PUBLIC VISIBILITY FIELD
-- ============================================================================

-- Remove index first
DROP INDEX IF EXISTS idx_user_profiles_public_visibility;

-- Remove the public visibility field
ALTER TABLE user_profiles DROP COLUMN IF EXISTS is_public_profile;

-- ============================================================================
-- ROLLBACK VERIFICATION: POST-ROLLBACK STATUS CHECK
-- ============================================================================

DO $$
DECLARE
    public_field_exists BOOLEAN;
    admin_clause_count INTEGER;
    security_barrier_count INTEGER;
    original_policy_count INTEGER;
BEGIN
    RAISE NOTICE '=== ROLLBACK VERIFICATION: POST-ROLLBACK STATUS ==='
    
    -- Check if public visibility field was removed
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'is_public_profile'
    ) INTO public_field_exists;
    
    IF NOT public_field_exists THEN
        RAISE NOTICE '✅ Public visibility field removed successfully';
    ELSE
        RAISE EXCEPTION 'ROLLBACK FAILED: is_public_profile field still exists';
    END IF;
    
    -- Check if admin OR clauses were restored
    SELECT COUNT(*) INTO admin_clause_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname IN ('cross_role_pharmacy_select', 'cross_role_tcm_select', 'public_directory_select')
    AND qual LIKE '%is_current_user_admin%';
    
    IF admin_clause_count = 3 THEN
        RAISE NOTICE '✅ Admin OR clauses restored in all 3 policies';
    ELSE
        RAISE EXCEPTION 'ROLLBACK FAILED: Expected 3 policies with admin clauses, found %', admin_clause_count;
    END IF;
    
    -- Check if SECURITY BARRIERS were removed
    SELECT COUNT(*) INTO security_barrier_count
    FROM pg_views v
    JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
    LEFT JOIN pg_options_to_table(c.reloptions) opts ON opts.option_name = 'security_barrier'
    WHERE v.schemaname = 'public' 
    AND v.viewname LIKE 'v_profiles_%'
    AND COALESCE(opts.option_value, 'false') = 'true';
    
    IF security_barrier_count = 0 THEN
        RAISE NOTICE '✅ All SECURITY BARRIERS removed from controlled views';
    ELSE
        RAISE EXCEPTION 'ROLLBACK FAILED: % views still have SECURITY BARRIER', security_barrier_count;
    END IF;
    
    -- Final validation - check total policy count is reasonable
    SELECT COUNT(*) INTO original_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'user_profiles';
    
    RAISE NOTICE '📊 Total policies on user_profiles table: %', original_policy_count;
    RAISE NOTICE '✅ ROLLBACK SUCCESSFUL: All hardening changes reverted';
END $$;

-- ============================================================================
-- SYSTEM STATE VERIFICATION: ORIGINAL STATE RESTORED
-- ============================================================================

DO $$
DECLARE
    helper_function_count INTEGER;
    controlled_view_count INTEGER; 
    admin_policy_count INTEGER;
BEGIN
    RAISE NOTICE '=== SYSTEM STATE AFTER ROLLBACK ==='
    
    -- Helper functions should remain unchanged
    SELECT COUNT(*) INTO helper_function_count
    FROM pg_proc 
    WHERE proname IN (
        'has_prescription_business_relationship',
        'has_referral_business_relationship',
        'is_current_user_admin'
    )
    AND pronamespace = 'private'::regnamespace
    AND prosecdef = true;
    
    -- Controlled views should exist without security barriers
    SELECT COUNT(*) INTO controlled_view_count
    FROM pg_views 
    WHERE schemaname = 'public' 
    AND viewname IN (
        'v_profiles_pharmacy_context',
        'v_profiles_tcm_context', 
        'v_profiles_public'
    );
    
    -- Admin policies should exist with OR clauses restored
    SELECT COUNT(*) INTO admin_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND qual LIKE '%is_current_user_admin%';
    
    -- Report system state
    RAISE NOTICE 'Component Status After Rollback:';
    RAISE NOTICE '  - Helper Functions: % (unchanged - not managed by hardening)', helper_function_count;
    RAISE NOTICE '  - Controlled Views: % (SECURITY BARRIER removed)', controlled_view_count;
    RAISE NOTICE '  - Policies with Admin Access: % (OR clauses restored)', admin_policy_count;
    RAISE NOTICE '  - Public Visibility Field: Removed (secure-by-default reverted)';
    
    -- Final validation
    IF controlled_view_count = 3 AND admin_policy_count >= 3 THEN
        RAISE NOTICE '✅ SYSTEM STATE ROLLBACK COMPLETE: Original configuration restored';
    ELSE
        RAISE EXCEPTION 'SYSTEM STATE ROLLBACK INCOMPLETE: Views=%, Admin Policies=%', controlled_view_count, admin_policy_count;
    END IF;
END $$;

-- ============================================================================
-- ROLLBACK COMPLETION LOG (PORTABLE AUDIT HANDLING)
-- ============================================================================

-- Portable audit logging - only insert if table exists
DO $$
BEGIN
    -- Check if audit table exists and insert if available
    IF EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'audit_log_entries'
    ) THEN
        -- Insert audit record for rollback completion
        INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at)
        VALUES (
            '00000000-0000-0000-0000-000000000000'::uuid,
            gen_random_uuid(),
            jsonb_build_object(
                'event', 'task_1_3b_hardening_rollback',
                'migration_file', 'rollback_20250905182000_rls_ext_policies_hardening.sql',
                'description', 'Rolled back RLS security hardening changes',
                'changes_reverted', ARRAY[
                    'removed_is_public_profile_field',
                    'restored_admin_or_clauses_in_policies', 
                    'removed_security_barriers_from_views'
                ],
                'rollback_scope', 'security_hardening_reversal',
                'policies_affected', ARRAY[
                    'cross_role_pharmacy_select',
                    'cross_role_tcm_select', 
                    'public_directory_select'
                ],
                'views_affected', ARRAY[
                    'v_profiles_pharmacy_context',
                    'v_profiles_tcm_context',
                    'v_profiles_public'
                ]
            ),
            NOW()
        );
        RAISE NOTICE '✅ Audit record created in auth.audit_log_entries';
    ELSE
        RAISE NOTICE '⚠️ Audit table auth.audit_log_entries not found - skipping audit record';
        RAISE NOTICE 'ℹ️ This is expected in environments without Supabase Auth audit tables';
    END IF;
END $$;

-- Log successful rollback completion (always available)
SELECT NOW() as rollback_completed,
       'Task 1.3B Hardening Rollback: Security Hardening Changes Reverted' as task,
       'ORIGINAL CONFIGURATION RESTORED - HARDENING ROLLED BACK' as status;

-- Rollback completion summary
DO $$
BEGIN
    RAISE NOTICE '=================================================================='
    RAISE NOTICE 'ROLLBACK COMPLETED: 20250905182000_rls_ext_policies_hardening';
    RAISE NOTICE '=================================================================='
    RAISE NOTICE '✅ Public visibility field removed (is_public_profile)';
    RAISE NOTICE '✅ Admin OR clauses restored in cross-role policies';
    RAISE NOTICE '✅ Public directory policy reverted to original conditions';
    RAISE NOTICE '✅ SECURITY BARRIER removed from all controlled views';
    RAISE NOTICE '✅ System restored to pre-hardening state';
    RAISE NOTICE 'Architecture Impact: Original security model restored';
    RAISE NOTICE 'Next Steps: Can safely re-apply hardening or implement alternative approach';
    RAISE NOTICE '=================================================================='
END $$;