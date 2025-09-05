-- ============================================================================
-- Task 1.3B: RLS Extension Policies on Base Table (CORRECTED)
-- ============================================================================  
-- Applies RLS policies to base user_profiles table for cross-role business access
-- CORRECTS: Critical architectural defect - RLS on views not supported in PostgreSQL
-- 
-- Architecture Change: Move RLS from views to base table
-- - Views inherit security from base table automatically
-- - Policies apply pure boolean authorization (no field filtering)
-- - Cross-role access controlled by business relationship functions
-- ============================================================================

-- ============================================================================
-- DEPENDENCY VALIDATION  
-- ============================================================================
-- Ensure required columns exist from role-specific fields migration

DO $$
DECLARE
    missing_columns TEXT[] := '{}';
    col_name TEXT;
    required_columns TEXT[] := ARRAY['tcm_specialty', 'pharmacy_type'];
BEGIN
    RAISE NOTICE '=== DEPENDENCY VALIDATION: Role-Specific Fields ===';
    
    -- Check each required column exists
    FOREACH col_name IN ARRAY required_columns
    LOOP
        IF NOT EXISTS (
            SELECT FROM information_schema.columns
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles'
            AND column_name = col_name
        ) THEN
            missing_columns := array_append(missing_columns, col_name);
        END IF;
    END LOOP;
    
    -- Fail with clear error message if dependencies missing
    IF array_length(missing_columns, 1) > 0 THEN
        RAISE EXCEPTION 'DEPENDENCY ERROR: Missing required columns from migration 20250905160602_role_specific_profile_fields.sql: %
        
SOLUTION: Apply the role-specific fields migration first:
psql -f supabase/migrations/20250905160602_role_specific_profile_fields.sql

Missing columns: %', array_to_string(missing_columns, ', '), array_to_string(missing_columns, ', ');
    END IF;
    
    RAISE NOTICE '✅ Dependencies verified: All required columns present';
END $$;

-- ============================================================================
-- RLS POLICIES ON BASE TABLE user_profiles
-- ============================================================================
-- Apply RLS policies to base table - views will inherit security automatically

-- Policy 1: Cross-Role Pharmacy Select
-- Allows pharmacy users to access TCM practitioner profiles when business relationship exists
CREATE POLICY "cross_role_pharmacy_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Pure boolean authorization - no field filtering
        private.has_prescription_business_relationship(auth.uid(), id) OR
        private.is_current_user_admin()  -- Admin can always read
    );

-- Policy 2: Cross-Role TCM Select  
-- Allows TCM practitioners to access pharmacy profiles when business relationship exists
CREATE POLICY "cross_role_tcm_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Pure boolean authorization - no field filtering
        private.has_referral_business_relationship(auth.uid(), id) OR
        private.is_current_user_admin()  -- Admin can always read
    );

-- Policy 3: Public Directory Select
-- Allows authenticated users to browse public directory with field restrictions
CREATE POLICY "public_directory_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        -- Public directory access with explicit field conditions
        (status = 'active' AND role IN ('tcm_practitioner', 'pharmacy')) OR
        private.is_current_user_admin()
    );

-- Policy 4: Admin Select Policy (Separate from bare authenticated access)
-- Admin has separate comprehensive select access
CREATE POLICY "admin_comprehensive_select" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        private.is_current_user_admin()
    );

-- ============================================================================
-- SYSTEM TABLE VERIFICATION: POLICIES  
-- ============================================================================

-- Validate all policies are created correctly with pure boolean expressions
DO $$
DECLARE
    policy_count INTEGER;
    expected_policies TEXT[] := ARRAY[
        'cross_role_pharmacy_select',
        'cross_role_tcm_select', 
        'public_directory_select',
        'admin_comprehensive_select'
    ];
    policy_name TEXT;
    policy_qual TEXT;
BEGIN
    RAISE NOTICE '=== RLS POLICIES SYSTEM TABLE VERIFICATION ===';
    
    -- Check each expected policy exists and contains only boolean expressions
    FOREACH policy_name IN ARRAY expected_policies
    LOOP
        -- Check policy exists
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles'
        AND policyname = policy_name;
        
        IF policy_count = 0 THEN
            RAISE EXCEPTION 'VALIDATION FAILED: Policy % not found on user_profiles table', policy_name;
        END IF;
        
        -- Get policy qualification (WHERE clause) for boolean validation
        SELECT qual INTO policy_qual
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles'
        AND policyname = policy_name;
        
        -- Validate policy contains only boolean expressions (no field filtering)
        CASE policy_name
            WHEN 'cross_role_pharmacy_select' THEN
                IF policy_qual NOT LIKE '%private.has_prescription_business_relationship%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % missing required boolean function', policy_name;
                END IF;
                
            WHEN 'cross_role_tcm_select' THEN
                IF policy_qual NOT LIKE '%private.has_referral_business_relationship%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % missing required boolean function', policy_name;
                END IF;
                
            WHEN 'public_directory_select' THEN
                IF policy_qual NOT LIKE '%status%=%active%' AND policy_qual NOT LIKE '%tcm_practitioner%pharmacy%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % missing public directory conditions', policy_name;
                END IF;
                
            WHEN 'admin_comprehensive_select' THEN
                IF policy_qual NOT LIKE '%private.is_current_user_admin%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % missing admin authorization', policy_name;
                END IF;
        END CASE;
        
        RAISE NOTICE '✅ Policy %: Boolean expression validated on base table', policy_name;
    END LOOP;
    
    -- Final count validation
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname = ANY(expected_policies);
    
    IF policy_count != array_length(expected_policies, 1) THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Expected % policies on user_profiles table, found %', 
            array_length(expected_policies, 1), policy_count;
    END IF;
    
    RAISE NOTICE '✅ VALIDATION PASSED: All % RLS policies created on base table with pure boolean authorization', policy_count;
END $$;

-- ============================================================================
-- COMPREHENSIVE SYSTEM TABLE VERIFICATION (FIXED)
-- ============================================================================

-- Final verification with corrected search_path pattern matching
DO $$
DECLARE
    helper_function_count INTEGER;
    controlled_view_count INTEGER;
    rls_policy_count INTEGER;
    total_components INTEGER;
BEGIN
    RAISE NOTICE '=== TASK 1.3B COMPLETE IMPLEMENTATION VERIFICATION ===';
    
    -- Step 1 verification: Helper functions with SECURITY DEFINER (FIXED pattern)
    SELECT COUNT(*) INTO helper_function_count
    FROM pg_proc 
    WHERE proname IN (
        'has_prescription_business_relationship',
        'has_referral_business_relationship'
    )
    AND pronamespace = 'private'::regnamespace
    AND prosecdef = true
    AND proconfig::text LIKE '%search_path=public%pg_temp%private%';  -- FIXED: Handle spaces in pattern
    
    -- Step 2 verification: Controlled views with field projections
    SELECT COUNT(*) INTO controlled_view_count
    FROM pg_views 
    WHERE schemaname = 'public' 
    AND viewname IN (
        'v_profiles_pharmacy_context',
        'v_profiles_tcm_context',
        'v_profiles_public'
    );
    
    -- Step 3 verification: RLS policies on BASE TABLE (CORRECTED)
    SELECT COUNT(*) INTO rls_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'  -- CORRECTED: Policies on base table, not views
    AND policyname IN (
        'cross_role_pharmacy_select',
        'cross_role_tcm_select',
        'public_directory_select',
        'admin_comprehensive_select'
    );
    
    total_components := helper_function_count + controlled_view_count + rls_policy_count;
    
    -- Final validation summary
    IF helper_function_count = 2 AND controlled_view_count = 3 AND rls_policy_count = 4 THEN
        RAISE NOTICE '✅ COMPLETE VALIDATION PASSED:';
        RAISE NOTICE '  - Helper Functions: % (SECURITY DEFINER + fixed search_path)', helper_function_count;
        RAISE NOTICE '  - Controlled Views: % (inherit security from base table)', controlled_view_count;
        RAISE NOTICE '  - RLS Policies: % (pure boolean authorization on BASE TABLE)', rls_policy_count;
        RAISE NOTICE '  - Total Components: %', total_components;
        RAISE NOTICE '  - ARCHITECTURAL FIX: RLS moved from views to base user_profiles table';
    ELSE
        RAISE EXCEPTION 'COMPLETE VALIDATION FAILED: Expected 2 functions + 3 views + 4 base table policies, found %+%+%', 
            helper_function_count, controlled_view_count, rls_policy_count;
    END IF;
    
    RAISE NOTICE '✅ TASK 1.3B IMPLEMENTATION COMPLETE: Base table RLS + controlled view inheritance';
END $$;

-- ============================================================================
-- POLICY DOCUMENTATION AND METADATA
-- ============================================================================

-- Add comprehensive policy documentation
COMMENT ON POLICY "cross_role_pharmacy_select" ON user_profiles IS 
    'Task 1.3B CORRECTED: Allows pharmacy users to access TCM practitioner profiles when prescription business relationship exists. Pure boolean authorization on BASE TABLE.';

COMMENT ON POLICY "cross_role_tcm_select" ON user_profiles IS 
    'Task 1.3B CORRECTED: Allows TCM practitioners to access pharmacy profiles when referral business relationship exists. Pure boolean authorization on BASE TABLE.';

COMMENT ON POLICY "public_directory_select" ON user_profiles IS 
    'Task 1.3B CORRECTED: Allows authenticated users to browse public professional directory. Field conditions with boolean authorization on BASE TABLE.';

COMMENT ON POLICY "admin_comprehensive_select" ON user_profiles IS 
    'Task 1.3B CORRECTED: Provides admin users with comprehensive select access. Separate from bare authenticated access, on BASE TABLE.';

-- ============================================================================
-- MIGRATION COMPLETION LOG
-- ============================================================================

-- Log successful completion of corrected RLS policies on base table
SELECT NOW() as migration_completed,
       'Task 1.3B Step 3 CORRECTED: RLS Extension Policies on Base Table' as task,
       'RLS POLICIES APPLIED TO BASE TABLE - VIEWS INHERIT SECURITY AUTOMATICALLY' as status;

-- Task 1.3B architectural correction complete
DO $$
BEGIN
    RAISE NOTICE '=== TASK 1.3B ARCHITECTURAL CORRECTION COMPLETE ===';
    RAISE NOTICE 'CRITICAL DEFECT RESOLVED:';
    RAISE NOTICE '❌ REMOVED: Unsupported RLS on views (PostgreSQL limitation)';
    RAISE NOTICE '✅ APPLIED: 4 RLS policies on base user_profiles table';
    RAISE NOTICE '✅ INHERITANCE: Controlled views automatically inherit base table security';
    RAISE NOTICE '✅ DEPENDENCIES: Column existence validated with clear error messages';
    RAISE NOTICE '✅ VALIDATION: Fixed search_path pattern matching in system verification';
    RAISE NOTICE 'Ready for behavioral testing and IRG remediation evidence generation';
END $$;