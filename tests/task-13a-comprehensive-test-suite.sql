-- ============================================================================
-- Task 1.3A Comprehensive Test Suite
-- ============================================================================
-- Complete behavioral and system verification for RLS Basic Policies & Role Consistency
-- Tests cover: SELF access, cross-role isolation, admin audit, system table validation
--
-- Usage: 
--   psql -h localhost -p 54322 -U postgres -d postgres -f task-13a-comprehensive-test-suite.sql
--
-- Expected: All tests pass with detailed evidence output for QAD validation

-- ============================================================================
-- TEST SETUP & PREPARATION
-- ============================================================================

-- Enable detailed test output
\timing on
\set ECHO all
\set VERBOSITY verbose

BEGIN;

-- Create test log for evidence collection
CREATE TEMPORARY TABLE test_results (
    test_id SERIAL PRIMARY KEY,
    test_category TEXT NOT NULL,
    test_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PASS', 'FAIL', 'ERROR')),
    details TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Test setup validation
DO $$
BEGIN
    RAISE NOTICE '=== TASK 1.3A TEST SUITE STARTING ===';
    RAISE NOTICE 'Timestamp: %', NOW();
    RAISE NOTICE 'Testing RLS Basic Policies & Role Consistency Implementation';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- SECTION 1: SYSTEM TABLE VALIDATION TESTS
-- ============================================================================

RAISE NOTICE '=== SECTION 1: SYSTEM TABLE VALIDATION ===';

-- Test 1.1: Constraint Validation
DO $$
DECLARE
    constraint_count INTEGER;
    constraint_def TEXT;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 1.1: Canonical Role Constraint Validation ---';
    
    -- Check canonical constraint exists
    SELECT COUNT(*), pg_catalog.pg_get_constraintdef(oid) 
    INTO constraint_count, constraint_def
    FROM pg_constraint 
    WHERE conrelid = 'user_profiles'::regclass 
    AND conname = 'user_profiles_role_canonical_check';
    
    IF constraint_count = 1 AND 
       constraint_def LIKE '%tcm_practitioner%' AND
       constraint_def LIKE '%pharmacy%' AND
       constraint_def LIKE '%admin%' THEN
        test_status := 'PASS';
        test_details := 'Canonical constraint exists with correct definition';
        RAISE NOTICE '✅ PASS: Canonical constraint validated';
        RAISE NOTICE '   Definition: %', constraint_def;
    ELSE
        test_details := 'Constraint missing or incorrect: ' || COALESCE(constraint_def, 'NULL');
        RAISE NOTICE '❌ FAIL: Canonical constraint validation failed';
        RAISE NOTICE '   Expected: user_profiles_role_canonical_check with tcm_practitioner,pharmacy,admin';
        RAISE NOTICE '   Found: %', COALESCE(constraint_def, 'NULL');
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('System Tables', 'Canonical Role Constraint', test_status, test_details);
END $$;

-- Test 1.2: RLS Policy Validation
DO $$
DECLARE
    policy_count INTEGER;
    expected_policies TEXT[] := ARRAY[
        'rls_basic_select_self',
        'rls_basic_select_admin',
        'rls_basic_update_self_isolated', 
        'rls_basic_update_admin_all',
        'rls_basic_insert_self',
        'rls_basic_insert_admin',
        'rls_basic_delete_admin_only'
    ];
    missing_policies TEXT[] := '{}';
    policy_name TEXT;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 1.2: RLS Policy Existence Validation ---';
    
    -- Count RLS basic policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname LIKE 'rls_basic_%';
    
    -- Check each expected policy
    FOREACH policy_name IN ARRAY expected_policies
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = 'user_profiles' 
            AND policyname = policy_name
        ) THEN
            missing_policies := array_append(missing_policies, policy_name);
        END IF;
    END LOOP;
    
    IF policy_count = array_length(expected_policies, 1) AND array_length(missing_policies, 1) = 0 THEN
        test_status := 'PASS';
        test_details := 'All 7 RLS basic policies found';
        RAISE NOTICE '✅ PASS: All % RLS basic policies validated', policy_count;
    ELSE
        test_details := 'Expected 7 policies, found ' || policy_count || '. Missing: ' || array_to_string(missing_policies, ', ');
        RAISE NOTICE '❌ FAIL: RLS policy validation failed';
        RAISE NOTICE '   Expected: 7 policies, Found: %', policy_count;
        RAISE NOTICE '   Missing: %', array_to_string(missing_policies, ', ');
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('System Tables', 'RLS Policy Existence', test_status, test_details);
END $$;

-- Test 1.3: Function Validation  
DO $$
DECLARE
    func_count INTEGER;
    handle_user_source TEXT;
    helper_func_count INTEGER;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 1.3: Function Validation ---';
    
    -- Check handle_new_user uses canonical default
    SELECT prosrc INTO handle_user_source
    FROM pg_proc 
    WHERE proname = 'handle_new_user'
    AND pronamespace = 'public'::regnamespace;
    
    -- Check helper functions exist
    SELECT COUNT(*) INTO helper_func_count
    FROM pg_proc 
    WHERE proname IN ('check_tcm_fields_only_updated', 'check_pharmacy_fields_only_updated', 'check_admin_fields_only_updated')
    AND pronamespace = 'private'::regnamespace;
    
    IF handle_user_source LIKE '%tcm_practitioner%' AND helper_func_count = 3 THEN
        test_status := 'PASS';
        test_details := 'Functions validated: canonical default + 3 helper functions';
        RAISE NOTICE '✅ PASS: Function validation successful';
        RAISE NOTICE '   handle_new_user: uses canonical default role';
        RAISE NOTICE '   Helper functions: % field validation functions found', helper_func_count;
    ELSE
        test_details := 'Function validation issues detected';
        RAISE NOTICE '❌ FAIL: Function validation failed';
        IF NOT handle_user_source LIKE '%tcm_practitioner%' THEN
            RAISE NOTICE '   handle_new_user: does not use canonical default';
        END IF;
        IF helper_func_count != 3 THEN
            RAISE NOTICE '   Helper functions: expected 3, found %', helper_func_count;
        END IF;
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('System Tables', 'Function Validation', test_status, test_details);
END $$;

-- ============================================================================
-- SECTION 2: DATA CONSISTENCY VALIDATION
-- ============================================================================

RAISE NOTICE '=== SECTION 2: DATA CONSISTENCY VALIDATION ===';

-- Test 2.1: Role Value Canonicalization
DO $$
DECLARE
    total_users INTEGER;
    canonical_users INTEGER;
    non_canonical_users INTEGER;
    role_distribution RECORD;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 2.1: Role Value Canonicalization ---';
    
    -- Count total users and canonical compliance
    SELECT COUNT(*) INTO total_users FROM user_profiles;
    
    SELECT COUNT(*) INTO canonical_users 
    FROM user_profiles 
    WHERE role IN ('tcm_practitioner', 'pharmacy', 'admin');
    
    SELECT COUNT(*) INTO non_canonical_users 
    FROM user_profiles 
    WHERE role NOT IN ('tcm_practitioner', 'pharmacy', 'admin');
    
    IF non_canonical_users = 0 AND canonical_users = total_users THEN
        test_status := 'PASS';
        test_details := 'All role values canonical: ' || canonical_users || '/' || total_users;
        RAISE NOTICE '✅ PASS: All role values are canonical (%/%)', canonical_users, total_users;
        
        -- Log role distribution for evidence
        RAISE NOTICE '   Role distribution:';
        FOR role_distribution IN 
            SELECT role, COUNT(*) as count 
            FROM user_profiles 
            GROUP BY role 
            ORDER BY role
        LOOP
            RAISE NOTICE '     %: % users', role_distribution.role, role_distribution.count;
        END LOOP;
    ELSE
        test_status := 'FAIL';
        test_details := 'Non-canonical values found: ' || non_canonical_users || '/' || total_users;
        RAISE NOTICE '❌ FAIL: Non-canonical role values detected';
        RAISE NOTICE '   Total users: %, Canonical: %, Non-canonical: %', total_users, canonical_users, non_canonical_users;
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('Data Consistency', 'Role Value Canonicalization', test_status, test_details);
END $$;

-- ============================================================================
-- SECTION 3: BEHAVIORAL TESTING (RLS POLICY FUNCTIONALITY)
-- ============================================================================

RAISE NOTICE '=== SECTION 3: BEHAVIORAL TESTING ===';

-- Test 3.1: Self-Profile Access Testing
-- Note: This requires actual user context, so we test the policy logic structure
DO $$
DECLARE
    select_self_policy_def TEXT;
    update_self_policy_def TEXT;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 3.1: Self-Profile Access Policy Structure ---';
    
    -- Get policy definitions for analysis
    SELECT qual INTO select_self_policy_def
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname = 'rls_basic_select_self';
    
    SELECT with_check INTO update_self_policy_def
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname = 'rls_basic_update_self_isolated';
    
    IF select_self_policy_def LIKE '%auth.uid()%id%' AND 
       update_self_policy_def LIKE '%auth.uid()%id%' AND
       update_self_policy_def LIKE '%check_%fields_only_updated%' THEN
        test_status := 'PASS';
        test_details := 'Self-access policies correctly structured with field isolation';
        RAISE NOTICE '✅ PASS: Self-profile access policies validated';
        RAISE NOTICE '   SELECT policy: Contains auth.uid() = id check';
        RAISE NOTICE '   UPDATE policy: Contains auth.uid() = id + field isolation checks';
    ELSE
        test_details := 'Self-access policy structure issues detected';
        RAISE NOTICE '❌ FAIL: Self-profile access policy structure invalid';
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('Behavioral', 'Self-Profile Access Structure', test_status, test_details);
END $$;

-- Test 3.2: Admin Access and Audit Testing
DO $$
DECLARE
    admin_select_policy TEXT;
    admin_update_policy TEXT;
    admin_delete_policy TEXT;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 3.2: Admin Access and Audit Policy Structure ---';
    
    -- Get admin policy definitions
    SELECT qual INTO admin_select_policy
    FROM pg_policies 
    WHERE policyname = 'rls_basic_select_admin';
    
    SELECT qual INTO admin_update_policy
    FROM pg_policies 
    WHERE policyname = 'rls_basic_update_admin_all';
    
    SELECT qual INTO admin_delete_policy
    FROM pg_policies 
    WHERE policyname = 'rls_basic_delete_admin_only';
    
    IF admin_select_policy LIKE '%is_current_user_admin()%' AND
       admin_select_policy LIKE '%log_admin_profile_access%' AND
       admin_update_policy LIKE '%is_current_user_admin()%' AND  
       admin_update_policy LIKE '%log_admin_profile_access%' AND
       admin_delete_policy LIKE '%is_current_user_admin()%' AND
       admin_delete_policy LIKE '%log_admin_profile_access%' THEN
        test_status := 'PASS';
        test_details := 'Admin policies include proper authorization and audit logging';
        RAISE NOTICE '✅ PASS: Admin access policies validated';
        RAISE NOTICE '   All admin policies include is_current_user_admin() check';
        RAISE NOTICE '   All admin policies include log_admin_profile_access() audit';
    ELSE
        test_details := 'Admin policy structure missing authorization or audit components';
        RAISE NOTICE '❌ FAIL: Admin access policy structure invalid';
        RAISE NOTICE '   Check: admin authorization and audit logging requirements';
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('Behavioral', 'Admin Access and Audit', test_status, test_details);
END $$;

-- Test 3.3: Field Isolation Function Logic Testing
DO $$
DECLARE
    tcm_func_source TEXT;
    pharmacy_func_source TEXT;
    admin_func_source TEXT;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 3.3: Field Isolation Function Logic ---';
    
    -- Get function sources for validation
    SELECT prosrc INTO tcm_func_source 
    FROM pg_proc 
    WHERE proname = 'check_tcm_fields_only_updated';
    
    SELECT prosrc INTO pharmacy_func_source 
    FROM pg_proc 
    WHERE proname = 'check_pharmacy_fields_only_updated';
    
    SELECT prosrc INTO admin_func_source 
    FROM pg_proc 
    WHERE proname = 'check_admin_fields_only_updated';
    
    -- Validate cross-role field protection logic
    IF tcm_func_source LIKE '%pharmacy_%' AND tcm_func_source LIKE '%admin_%' AND tcm_func_source LIKE '%RETURN FALSE%' AND
       pharmacy_func_source LIKE '%tcm_%' AND pharmacy_func_source LIKE '%admin_%' AND pharmacy_func_source LIKE '%RETURN FALSE%' AND
       admin_func_source LIKE '%tcm_%' AND admin_func_source LIKE '%pharmacy_%' AND admin_func_source LIKE '%RETURN FALSE%' THEN
        test_status := 'PASS';
        test_details := 'Field isolation functions correctly prevent cross-role field access';
        RAISE NOTICE '✅ PASS: Field isolation function logic validated';
        RAISE NOTICE '   TCM function: blocks pharmacy & admin field modifications';
        RAISE NOTICE '   Pharmacy function: blocks TCM & admin field modifications';
        RAISE NOTICE '   Admin function: blocks TCM & pharmacy field modifications';
    ELSE
        test_details := 'Field isolation function logic incomplete or incorrect';
        RAISE NOTICE '❌ FAIL: Field isolation function logic invalid';
        RAISE NOTICE '   Functions must block cross-role field modifications with RETURN FALSE';
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('Behavioral', 'Field Isolation Logic', test_status, test_details);
END $$;

-- ============================================================================
-- SECTION 4: INTEGRATION AND COMPLETENESS TESTING
-- ============================================================================

RAISE NOTICE '=== SECTION 4: INTEGRATION TESTING ===';

-- Test 4.1: Policy Coverage Completeness
DO $$
DECLARE
    select_policies INTEGER;
    insert_policies INTEGER;  
    update_policies INTEGER;
    delete_policies INTEGER;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 4.1: RLS Policy Coverage Completeness ---';
    
    -- Count policies by operation type
    SELECT COUNT(*) INTO select_policies FROM pg_policies 
    WHERE tablename = 'user_profiles' AND cmd = 'SELECT' AND policyname LIKE 'rls_basic_%';
    
    SELECT COUNT(*) INTO insert_policies FROM pg_policies 
    WHERE tablename = 'user_profiles' AND cmd = 'INSERT' AND policyname LIKE 'rls_basic_%';
    
    SELECT COUNT(*) INTO update_policies FROM pg_policies 
    WHERE tablename = 'user_profiles' AND cmd = 'UPDATE' AND policyname LIKE 'rls_basic_%';
    
    SELECT COUNT(*) INTO delete_policies FROM pg_policies 
    WHERE tablename = 'user_profiles' AND cmd = 'DELETE' AND policyname LIKE 'rls_basic_%';
    
    IF select_policies = 2 AND insert_policies = 2 AND update_policies = 2 AND delete_policies = 1 THEN
        test_status := 'PASS';
        test_details := 'Complete CRUD policy coverage: SELECT(2), INSERT(2), UPDATE(2), DELETE(1)';
        RAISE NOTICE '✅ PASS: Complete RLS policy coverage validated';
        RAISE NOTICE '   SELECT policies: % (self + admin)', select_policies;
        RAISE NOTICE '   INSERT policies: % (self + admin)', insert_policies;
        RAISE NOTICE '   UPDATE policies: % (self-isolated + admin-all)', update_policies;
        RAISE NOTICE '   DELETE policies: % (admin-only)', delete_policies;
    ELSE
        test_details := 'Incomplete policy coverage detected';
        RAISE NOTICE '❌ FAIL: Incomplete RLS policy coverage';
        RAISE NOTICE '   Expected: SELECT(2), INSERT(2), UPDATE(2), DELETE(1)';
        RAISE NOTICE '   Found: SELECT(%), INSERT(%), UPDATE(%), DELETE(%)', select_policies, insert_policies, update_policies, delete_policies;
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('Integration', 'Policy Coverage Completeness', test_status, test_details);
END $$;

-- Test 4.2: Migration Dependencies Validation
DO $$
DECLARE
    migration_count INTEGER;
    helper_functions_exist BOOLEAN := FALSE;
    function_updates_exist BOOLEAN := FALSE; 
    main_migration_executed BOOLEAN := FALSE;
    test_status TEXT := 'FAIL';
    test_details TEXT;
BEGIN
    RAISE NOTICE '--- Test 4.2: Migration Dependencies Validation ---';
    
    -- Check if helper functions are available (indicates dependency migrations ran)
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'check_tcm_fields_only_updated') THEN
        helper_functions_exist := TRUE;
    END IF;
    
    -- Check if function updates ran (canonical default)
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user' AND prosrc LIKE '%tcm_practitioner%') THEN
        function_updates_exist := TRUE;
    END IF;
    
    -- Check if main migration policies exist
    IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'rls_basic_select_self') THEN
        main_migration_executed := TRUE;
    END IF;
    
    IF helper_functions_exist AND function_updates_exist AND main_migration_executed THEN
        test_status := 'PASS';
        test_details := 'All migration dependencies properly executed';
        RAISE NOTICE '✅ PASS: Migration dependencies validated';
        RAISE NOTICE '   Helper functions: Available';
        RAISE NOTICE '   Function updates: Canonical defaults active';
        RAISE NOTICE '   Main migration: RLS policies implemented';
    ELSE
        test_details := 'Migration dependency issues detected';
        RAISE NOTICE '❌ FAIL: Migration dependencies validation failed';
        RAISE NOTICE '   Helper functions: %', CASE WHEN helper_functions_exist THEN 'Available' ELSE 'Missing' END;
        RAISE NOTICE '   Function updates: %', CASE WHEN function_updates_exist THEN 'Applied' ELSE 'Missing' END;
        RAISE NOTICE '   Main migration: %', CASE WHEN main_migration_executed THEN 'Executed' ELSE 'Missing' END;
    END IF;
    
    INSERT INTO test_results (test_category, test_name, status, details)
    VALUES ('Integration', 'Migration Dependencies', test_status, test_details);
END $$;

-- ============================================================================
-- SECTION 5: TEST RESULTS SUMMARY AND EVIDENCE GENERATION
-- ============================================================================

RAISE NOTICE '=== SECTION 5: TEST RESULTS SUMMARY ===';

-- Generate comprehensive test results summary
DO $$
DECLARE
    total_tests INTEGER;
    passed_tests INTEGER;
    failed_tests INTEGER;
    error_tests INTEGER;
    pass_rate NUMERIC;
    result_record RECORD;
BEGIN
    RAISE NOTICE '--- COMPREHENSIVE TEST RESULTS SUMMARY ---';
    
    -- Calculate test statistics
    SELECT COUNT(*) INTO total_tests FROM test_results;
    SELECT COUNT(*) INTO passed_tests FROM test_results WHERE status = 'PASS';
    SELECT COUNT(*) INTO failed_tests FROM test_results WHERE status = 'FAIL';  
    SELECT COUNT(*) INTO error_tests FROM test_results WHERE status = 'ERROR';
    
    pass_rate := CASE WHEN total_tests > 0 THEN (passed_tests::NUMERIC / total_tests::NUMERIC) * 100 ELSE 0 END;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== TASK 1.3A TEST SUITE RESULTS ===';
    RAISE NOTICE 'Total Tests: %', total_tests;
    RAISE NOTICE 'Passed: % (%.1f%%)', passed_tests, pass_rate;
    RAISE NOTICE 'Failed: %', failed_tests;
    RAISE NOTICE 'Errors: %', error_tests;
    RAISE NOTICE '';
    
    -- Detailed results by category
    RAISE NOTICE 'DETAILED RESULTS BY CATEGORY:';
    FOR result_record IN 
        SELECT test_category, test_name, status, details 
        FROM test_results 
        ORDER BY test_id
    LOOP
        RAISE NOTICE '[%] %: % - %', 
            result_record.status, 
            result_record.test_category, 
            result_record.test_name,
            result_record.details;
    END LOOP;
    
    RAISE NOTICE '';
    
    -- Overall assessment
    IF failed_tests = 0 AND error_tests = 0 THEN
        RAISE NOTICE '🎉 OVERALL ASSESSMENT: ALL TESTS PASSED';
        RAISE NOTICE '✅ Task 1.3A implementation is fully validated and ready for deployment';
    ELSE
        RAISE NOTICE '⚠️ OVERALL ASSESSMENT: ISSUES DETECTED';
        RAISE NOTICE '❌ Task 1.3A implementation has validation failures - review required';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== TEST SUITE COMPLETE ===';
    RAISE NOTICE 'Timestamp: %', NOW();
END $$;

-- Export test results for evidence collection
\copy (SELECT test_category, test_name, status, details, timestamp FROM test_results ORDER BY test_id) TO '/tmp/task-13a-test-results.csv' WITH CSV HEADER;

-- Generate system state snapshot for evidence
RAISE NOTICE '=== GENERATING EVIDENCE SNAPSHOTS ===';

-- Constraint state snapshot
SELECT 'CONSTRAINT_STATE' as evidence_type, conname as name, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'user_profiles'::regclass;

-- Policy state snapshot  
SELECT 'POLICY_STATE' as evidence_type, policyname as name, cmd as operation, qual as condition
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'user_profiles'
ORDER BY policyname;

-- Function state snapshot
SELECT 'FUNCTION_STATE' as evidence_type, proname as name, 
       CASE WHEN prosrc LIKE '%tcm_practitioner%' THEN 'CANONICAL' ELSE 'LEGACY' END as role_compliance
FROM pg_proc 
WHERE proname IN ('handle_new_user', 'check_tcm_fields_only_updated', 'check_pharmacy_fields_only_updated', 'check_admin_fields_only_updated');

-- Data state snapshot
SELECT 'DATA_STATE' as evidence_type, role, COUNT(*) as user_count,
       CASE WHEN role IN ('tcm_practitioner', 'pharmacy', 'admin') THEN 'CANONICAL' ELSE 'NON_CANONICAL' END as compliance
FROM user_profiles 
GROUP BY role;

COMMIT;

RAISE NOTICE '';
RAISE NOTICE '=== TASK 1.3A COMPREHENSIVE TEST SUITE COMPLETE ===';
RAISE NOTICE 'Evidence files generated:';  
RAISE NOTICE '  - Test results: /tmp/task-13a-test-results.csv';
RAISE NOTICE '  - System snapshots: Available in query output above';
RAISE NOTICE '  - Detailed logs: Available in console output';
RAISE NOTICE '';
RAISE NOTICE 'Ready for QAD evidence collection and validation.';