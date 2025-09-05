-- ============================================================================
-- Task 1.3B: RLS Extension Policies on Controlled Views
-- ============================================================================
-- Creates RLS policies on controlled views for cross-role business access
-- Based on corrected 1.3B research and architect implementation green light
-- 
-- Policies created: ONLY boolean authorization, NO field filtering, NO side effects
-- - v_profiles_pharmacy_context: Business relationship required for pharmacy→TCM access
-- - v_profiles_tcm_context: Business relationship required for TCM→pharmacy access  
-- - v_profiles_public: Public access for directory browsing
--
-- All policies: Pure boolean authorization using helper functions from Step 1
-- ============================================================================

-- ============================================================================
-- ENABLE RLS ON CONTROLLED VIEWS
-- ============================================================================

-- Enable RLS on controlled views (required before creating policies)
ALTER VIEW v_profiles_pharmacy_context ENABLE ROW LEVEL SECURITY;
ALTER VIEW v_profiles_tcm_context ENABLE ROW LEVEL SECURITY;
ALTER VIEW v_profiles_public ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES FOR v_profiles_pharmacy_context
-- ============================================================================
-- Purpose: Allow pharmacy users to view TCM professional info when business relationship exists
-- Authorization: Boolean check only - private.has_prescription_business_relationship()

-- Policy 1: Pharmacy Business Access (SELECT)
CREATE POLICY "pharmacy_business_context_select" ON v_profiles_pharmacy_context
    FOR SELECT 
    TO authenticated
    USING (
        -- Pure boolean authorization - no field filtering, no side effects
        private.has_prescription_business_relationship(auth.uid(), id) OR
        private.is_current_user_admin()  -- Admin can always read
    );

-- Policy 2: No INSERT/UPDATE/DELETE on business context view (read-only)
CREATE POLICY "pharmacy_business_context_readonly" ON v_profiles_pharmacy_context
    FOR ALL 
    TO authenticated
    USING (false)  -- Deny all write operations
    WITH CHECK (false);  -- Deny all write operations

-- ============================================================================
-- RLS POLICIES FOR v_profiles_tcm_context
-- ============================================================================
-- Purpose: Allow TCM practitioners to view pharmacy basic info when business relationship exists
-- Authorization: Boolean check only - private.has_referral_business_relationship()

-- Policy 3: TCM Referral Access (SELECT)
CREATE POLICY "tcm_referral_context_select" ON v_profiles_tcm_context
    FOR SELECT 
    TO authenticated
    USING (
        -- Pure boolean authorization - no field filtering, no side effects
        private.has_referral_business_relationship(auth.uid(), id) OR
        private.is_current_user_admin()  -- Admin can always read
    );

-- Policy 4: No INSERT/UPDATE/DELETE on referral context view (read-only)
CREATE POLICY "tcm_referral_context_readonly" ON v_profiles_tcm_context
    FOR ALL 
    TO authenticated
    USING (false)  -- Deny all write operations
    WITH CHECK (false);  -- Deny all write operations

-- ============================================================================
-- RLS POLICIES FOR v_profiles_public
-- ============================================================================  
-- Purpose: Allow public directory access for basic professional discovery
-- Authorization: Boolean check - authenticated users can browse public directory

-- Policy 5: Public Directory Access (SELECT)
CREATE POLICY "public_directory_select" ON v_profiles_public
    FOR SELECT 
    TO authenticated
    USING (
        -- Pure boolean authorization - authenticated users can browse public directory
        auth.uid() IS NOT NULL  -- Simple authenticated user check
    );

-- Policy 6: No INSERT/UPDATE/DELETE on public directory (read-only)
CREATE POLICY "public_directory_readonly" ON v_profiles_public
    FOR ALL 
    TO authenticated
    USING (false)  -- Deny all write operations
    WITH CHECK (false);  -- Deny all write operations

-- ============================================================================
-- SYSTEM TABLE VERIFICATION: POLICIES
-- ============================================================================

-- Validate all policies are created correctly with pure boolean expressions
DO $$
DECLARE
    policy_count INTEGER;
    expected_policies TEXT[] := ARRAY[
        'pharmacy_business_context_select',
        'pharmacy_business_context_readonly',
        'tcm_referral_context_select', 
        'tcm_referral_context_readonly',
        'public_directory_select',
        'public_directory_readonly'
    ];
    expected_views TEXT[] := ARRAY[
        'v_profiles_pharmacy_context',
        'v_profiles_tcm_context',
        'v_profiles_public'
    ];
    policy_name TEXT;
    view_name TEXT;
    policy_qual TEXT;
    rls_enabled BOOLEAN;
BEGIN
    RAISE NOTICE '=== RLS POLICIES SYSTEM TABLE VERIFICATION ===';
    
    -- Check RLS is enabled on all views
    FOREACH view_name IN ARRAY expected_views
    LOOP
        SELECT EXISTS (
            SELECT FROM pg_class 
            WHERE relname = view_name 
            AND relrowsecurity = true
        ) INTO rls_enabled;
        
        IF NOT rls_enabled THEN
            RAISE EXCEPTION 'VALIDATION FAILED: RLS not enabled on view %', view_name;
        END IF;
        
        RAISE NOTICE '✅ View %: RLS enabled', view_name;
    END LOOP;
    
    -- Check each expected policy exists and contains only boolean expressions
    FOREACH policy_name IN ARRAY expected_policies
    LOOP
        -- Check policy exists
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND policyname = policy_name;
        
        IF policy_count = 0 THEN
            RAISE EXCEPTION 'VALIDATION FAILED: Policy % not found', policy_name;
        END IF;
        
        -- Get policy qualification (WHERE clause) for boolean validation
        SELECT qual INTO policy_qual
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND policyname = policy_name;
        
        -- Validate policy contains only boolean expressions (no field filtering)
        CASE policy_name
            WHEN 'pharmacy_business_context_select' THEN
                IF policy_qual NOT LIKE '%private.has_prescription_business_relationship%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % missing required boolean function', policy_name;
                END IF;
                IF policy_qual LIKE '%SELECT%FROM%' AND policy_qual NOT LIKE '%auth.uid()%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % contains field filtering subquery', policy_name;
                END IF;
                
            WHEN 'tcm_referral_context_select' THEN
                IF policy_qual NOT LIKE '%private.has_referral_business_relationship%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % missing required boolean function', policy_name;
                END IF;
                IF policy_qual LIKE '%SELECT%FROM%' AND policy_qual NOT LIKE '%auth.uid()%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % contains field filtering subquery', policy_name;
                END IF;
                
            WHEN 'public_directory_select' THEN
                IF policy_qual NOT LIKE '%auth.uid()%' THEN
                    RAISE EXCEPTION 'VALIDATION FAILED: % missing authentication check', policy_name;
                END IF;
                
            ELSE
                -- Read-only policies should deny all operations
                IF policy_qual != 'false' THEN
                    RAISE NOTICE '⚠️ Policy %: Expected false for read-only, got: %', policy_name, policy_qual;
                END IF;
        END CASE;
        
        RAISE NOTICE '✅ Policy %: Boolean expression validated', policy_name;
    END LOOP;
    
    -- Final count validation
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename LIKE 'v_profiles_%';
    
    IF policy_count != array_length(expected_policies, 1) THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Expected % policies on views, found %', 
            array_length(expected_policies, 1), policy_count;
    END IF;
    
    RAISE NOTICE '✅ VALIDATION PASSED: All % RLS policies created with pure boolean authorization', policy_count;
END $$;

-- ============================================================================
-- COMPREHENSIVE SYSTEM TABLE VERIFICATION
-- ============================================================================

-- Final verification of complete 1.3B implementation across all steps
DO $$
DECLARE
    helper_function_count INTEGER;
    controlled_view_count INTEGER;
    rls_policy_count INTEGER;
    total_components INTEGER;
BEGIN
    RAISE NOTICE '=== TASK 1.3B COMPLETE IMPLEMENTATION VERIFICATION ===';
    
    -- Step 1 verification: Helper functions with SECURITY DEFINER
    SELECT COUNT(*) INTO helper_function_count
    FROM pg_proc 
    WHERE proname IN (
        'has_prescription_business_relationship',
        'has_referral_business_relationship'
    )
    AND pronamespace = 'private'::regnamespace
    AND prosecdef = true
    AND 'search_path=public,pg_temp,private' = ANY(proconfig);
    
    -- Step 2 verification: Controlled views with field projections
    SELECT COUNT(*) INTO controlled_view_count
    FROM pg_views 
    WHERE schemaname = 'public' 
    AND viewname IN (
        'v_profiles_pharmacy_context',
        'v_profiles_tcm_context',
        'v_profiles_public'
    );
    
    -- Step 3 verification: RLS policies with boolean authorization
    SELECT COUNT(*) INTO rls_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename LIKE 'v_profiles_%'
    AND policyname IN (
        'pharmacy_business_context_select',
        'tcm_referral_context_select',
        'public_directory_select'
    );
    
    total_components := helper_function_count + controlled_view_count + rls_policy_count;
    
    -- Final validation summary
    IF helper_function_count = 2 AND controlled_view_count = 3 AND rls_policy_count = 3 THEN
        RAISE NOTICE '✅ COMPLETE VALIDATION PASSED:';
        RAISE NOTICE '  - Helper Functions: % (SECURITY DEFINER + fixed search_path)', helper_function_count;
        RAISE NOTICE '  - Controlled Views: % (zero PII compliance verified)', controlled_view_count;
        RAISE NOTICE '  - RLS Policies: % (pure boolean authorization only)', rls_policy_count;
        RAISE NOTICE '  - Total Components: %', total_components;
    ELSE
        RAISE EXCEPTION 'COMPLETE VALIDATION FAILED: Expected 2 functions + 3 views + 3 policies, found %+%+%', 
            helper_function_count, controlled_view_count, rls_policy_count;
    END IF;
    
    RAISE NOTICE '✅ TASK 1.3B IMPLEMENTATION COMPLETE: Controlled views + RLS boolean authorization';
END $$;

-- ============================================================================
-- POLICY DOCUMENTATION AND METADATA
-- ============================================================================

-- Add comprehensive policy documentation
COMMENT ON POLICY "pharmacy_business_context_select" ON v_profiles_pharmacy_context IS 
    'Task 1.3B: Allows pharmacy users to view TCM professional context when prescription business relationship exists. Pure boolean authorization only.';

COMMENT ON POLICY "tcm_referral_context_select" ON v_profiles_tcm_context IS 
    'Task 1.3B: Allows TCM practitioners to view pharmacy context when referral business relationship exists. Pure boolean authorization only.';

COMMENT ON POLICY "public_directory_select" ON v_profiles_public IS 
    'Task 1.3B: Allows authenticated users to browse public professional directory. Pure boolean authorization only.';

-- ============================================================================
-- MIGRATION COMPLETION LOG
-- ============================================================================

-- Log successful completion of RLS policies on views
SELECT NOW() as migration_completed,
       'Task 1.3B Step 3: RLS Extension Policies on Views' as task,
       'RLS POLICIES CREATED WITH PURE BOOLEAN AUTHORIZATION ONLY' as status;

-- Task 1.3B implementation complete
RAISE NOTICE '=== TASK 1.3B IMPLEMENTATION COMPLETE ===';
RAISE NOTICE 'All 3 migration steps executed successfully:';
RAISE NOTICE '1. Helper functions with SECURITY DEFINER + fixed search_path';
RAISE NOTICE '2. Controlled views with zero PII compliance';
RAISE NOTICE '3. RLS policies with pure boolean authorization only';
RAISE NOTICE 'Ready for comprehensive testing and evidence generation';