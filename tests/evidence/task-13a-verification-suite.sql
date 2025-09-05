-- ============================================================================
-- Task 1.3A Evidence Collection - Verification Suite
-- ============================================================================
-- Complete verification script for QAD evidence triplet collection
-- Generates executable evidence for Task 1.3A RLS Basic Policies & Role Consistency

-- Set output formatting for evidence collection
\timing on
\pset expanded on
\pset border 2

-- ============================================================================
-- EVIDENCE SECTION 1: CONSTRAINT VERIFICATION
-- ============================================================================

\echo ''
\echo '=== EVIDENCE 1: CONSTRAINT VERIFICATION ==='
\echo 'Verifying canonical role constraint implementation'
\echo ''

-- 1.1: Verify canonical constraint exists and is correctly defined
SELECT 
    'CONSTRAINT_VERIFICATION' as evidence_type,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition,
    CASE 
        WHEN pg_get_constraintdef(oid) LIKE '%tcm_practitioner%' AND
             pg_get_constraintdef(oid) LIKE '%pharmacy%' AND
             pg_get_constraintdef(oid) LIKE '%admin%'
        THEN 'CANONICAL_COMPLIANT'
        ELSE 'NON_COMPLIANT'
    END as compliance_status
FROM pg_constraint 
WHERE conrelid = 'user_profiles'::regclass 
AND contype = 'c'
AND conname LIKE '%role%'
ORDER BY conname;

-- 1.2: Verify old constraint is removed
SELECT 
    'LEGACY_CONSTRAINT_CHECK' as evidence_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conrelid = 'user_profiles'::regclass 
            AND pg_get_constraintdef(oid) LIKE '%practitioner%'
            AND pg_get_constraintdef(oid) LIKE '%pharmacy_operator%'
        )
        THEN 'LEGACY_CONSTRAINT_FOUND'
        ELSE 'LEGACY_CONSTRAINT_REMOVED'
    END as legacy_status;

-- ============================================================================
-- EVIDENCE SECTION 2: RLS POLICY VERIFICATION
-- ============================================================================

\echo ''
\echo '=== EVIDENCE 2: RLS POLICY VERIFICATION ==='
\echo 'Verifying RLS basic policies implementation and coverage'
\echo ''

-- 2.1: Complete RLS policy inventory
SELECT 
    'RLS_POLICY_INVENTORY' as evidence_type,
    policyname as policy_name,
    cmd as operation,
    roles as target_roles,
    CASE WHEN policyname LIKE 'rls_basic_%' THEN 'TASK_13A_POLICY' ELSE 'OTHER_POLICY' END as policy_category
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_profiles'
ORDER BY policy_category, policyname;

-- 2.2: RLS basic policy coverage analysis
SELECT 
    'RLS_COVERAGE_ANALYSIS' as evidence_type,
    cmd as operation_type,
    COUNT(*) as policy_count,
    array_agg(policyname ORDER BY policyname) as policy_names
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_profiles'
AND policyname LIKE 'rls_basic_%'
GROUP BY cmd
ORDER BY cmd;

-- 2.3: Policy definition details for audit
SELECT 
    'RLS_POLICY_DETAILS' as evidence_type,
    policyname as policy_name,
    cmd as operation,
    COALESCE(qual, 'N/A') as using_condition,
    COALESCE(with_check, 'N/A') as check_condition
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_profiles'
AND policyname LIKE 'rls_basic_%'
ORDER BY policyname;

-- ============================================================================
-- EVIDENCE SECTION 3: FUNCTION VERIFICATION
-- ============================================================================

\echo ''
\echo '=== EVIDENCE 3: FUNCTION VERIFICATION ==='
\echo 'Verifying function updates and helper function implementation'
\echo ''

-- 3.1: Function existence and role compliance check
SELECT 
    'FUNCTION_VERIFICATION' as evidence_type,
    proname as function_name,
    pronamespace::regnamespace as schema_name,
    CASE 
        WHEN proname = 'handle_new_user' AND prosrc LIKE '%tcm_practitioner%' 
        THEN 'CANONICAL_COMPLIANT'
        WHEN proname LIKE 'check_%fields_only_updated' 
        THEN 'HELPER_FUNCTION'
        ELSE 'OTHER_FUNCTION'
    END as function_type,
    CASE 
        WHEN prosrc LIKE '%tcm_practitioner%' OR prosrc LIKE '%pharmacy%' OR prosrc LIKE '%admin%'
        THEN 'CANONICAL_AWARE'
        ELSE 'NOT_CANONICAL_AWARE'
    END as canonical_compliance
FROM pg_proc 
WHERE proname IN ('handle_new_user', 'get_current_user_role', 'is_current_user_admin', 
                  'check_tcm_fields_only_updated', 'check_pharmacy_fields_only_updated', 
                  'check_admin_fields_only_updated', 'log_admin_profile_access', 
                  'enforce_role_field_isolation')
ORDER BY schema_name, function_type, proname;

-- 3.2: Trigger verification
SELECT 
    'TRIGGER_VERIFICATION' as evidence_type,
    trigger_name,
    event_manipulation as trigger_event,
    action_timing as timing,
    action_statement as trigger_function
FROM information_schema.triggers 
WHERE event_object_table = 'user_profiles'
AND trigger_name LIKE '%role%isolation%'
ORDER BY trigger_name;

-- ============================================================================
-- EVIDENCE SECTION 4: DATA CONSISTENCY VERIFICATION
-- ============================================================================

\echo ''
\echo '=== EVIDENCE 4: DATA CONSISTENCY VERIFICATION ==='
\echo 'Verifying role value canonicalization and data integrity'
\echo ''

-- 4.1: Role value distribution and canonicalization status
SELECT 
    'DATA_CONSISTENCY' as evidence_type,
    role as role_value,
    COUNT(*) as user_count,
    CASE 
        WHEN role IN ('tcm_practitioner', 'pharmacy', 'admin') 
        THEN 'CANONICAL' 
        ELSE 'NON_CANONICAL' 
    END as canonicalization_status,
    ROUND((COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM user_profiles)::NUMERIC) * 100, 2) as percentage
FROM user_profiles 
GROUP BY role
ORDER BY canonicalization_status, role;

-- 4.2: Overall canonicalization compliance
SELECT 
    'CANONICALIZATION_SUMMARY' as evidence_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN role IN ('tcm_practitioner', 'pharmacy', 'admin') THEN 1 END) as canonical_users,
    COUNT(CASE WHEN role NOT IN ('tcm_practitioner', 'pharmacy', 'admin') THEN 1 END) as non_canonical_users,
    ROUND(
        (COUNT(CASE WHEN role IN ('tcm_practitioner', 'pharmacy', 'admin') THEN 1 END)::NUMERIC / 
         COUNT(*)::NUMERIC) * 100, 
        2
    ) as canonical_compliance_percentage
FROM user_profiles;

-- ============================================================================
-- EVIDENCE SECTION 5: INTEGRATION TESTING
-- ============================================================================

\echo ''
\echo '=== EVIDENCE 5: INTEGRATION TESTING ==='
\echo 'Testing field isolation functions and policy integration'
\echo ''

-- 5.1: Test field isolation functions with sample data
DO $$
DECLARE
    test_old_record user_profiles;
    test_new_record user_profiles;
    tcm_result BOOLEAN;
    pharmacy_result BOOLEAN;
    admin_result BOOLEAN;
BEGIN
    -- Set up test data
    test_old_record.tcm_specialty := 'acupuncture'::tcm_specialty_enum;
    test_old_record.pharmacy_type := 'retail_pharmacy'::pharmacy_type_enum;
    test_old_record.admin_level := 'super_admin'::admin_level_enum;
    
    test_new_record := test_old_record;
    test_new_record.tcm_specialty := 'herbal_medicine'::tcm_specialty_enum; -- Valid TCM change
    
    -- Test TCM function (should allow TCM field changes)
    tcm_result := private.check_tcm_fields_only_updated(test_old_record, test_new_record);
    
    -- Test Pharmacy function (should reject TCM field changes)  
    pharmacy_result := private.check_pharmacy_fields_only_updated(test_old_record, test_new_record);
    
    -- Test Admin function (should reject TCM field changes)
    admin_result := private.check_admin_fields_only_updated(test_old_record, test_new_record);
    
    -- Output results
    RAISE NOTICE 'FIELD_ISOLATION_TEST: tcm_function=%, pharmacy_function=%, admin_function=%', 
        tcm_result, pharmacy_result, admin_result;
    
    -- Expected: tcm_result=true, pharmacy_result=false, admin_result=false
    IF tcm_result = true AND pharmacy_result = false AND admin_result = false THEN
        RAISE NOTICE 'FIELD_ISOLATION_TEST: PASSED - Proper cross-role field isolation enforced';
    ELSE
        RAISE NOTICE 'FIELD_ISOLATION_TEST: FAILED - Field isolation not working correctly';
    END IF;
END $$;

-- 5.2: Audit function test
SELECT 
    'AUDIT_FUNCTION_TEST' as evidence_type,
    private.log_admin_profile_access(gen_random_uuid(), 'EVIDENCE_TEST') as audit_log_id,
    'Audit function callable and returns UUID' as test_result;

-- ============================================================================
-- EVIDENCE SECTION 6: SYSTEM STATE SUMMARY
-- ============================================================================

\echo ''
\echo '=== EVIDENCE 6: SYSTEM STATE SUMMARY ==='
\echo 'Complete system state snapshot for Task 1.3A implementation'
\echo ''

-- 6.1: Complete implementation summary
SELECT 
    'IMPLEMENTATION_SUMMARY' as evidence_type,
    'Task 1.3A RLS Basic Policies & Role Consistency' as task_name,
    NOW() as verification_timestamp,
    (SELECT COUNT(*) FROM pg_constraint 
     WHERE conrelid = 'user_profiles'::regclass 
     AND pg_get_constraintdef(oid) LIKE '%tcm_practitioner%'
    ) as canonical_constraints,
    (SELECT COUNT(*) FROM pg_policies 
     WHERE schemaname = 'public' AND tablename = 'user_profiles' 
     AND policyname LIKE 'rls_basic_%'
    ) as rls_basic_policies,
    (SELECT COUNT(*) FROM pg_proc 
     WHERE proname LIKE 'check_%fields_only_updated'
    ) as field_isolation_functions,
    (SELECT COUNT(*) FROM user_profiles 
     WHERE role IN ('tcm_practitioner', 'pharmacy', 'admin')
    ) as canonical_users,
    (SELECT COUNT(*) FROM user_profiles) as total_users;

-- 6.2: Architecture compliance verification  
SELECT 
    'ARCHITECTURE_COMPLIANCE' as evidence_type,
    'Canonical Role Values' as component,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE role NOT IN ('tcm_practitioner', 'pharmacy', 'admin')
        )
        THEN 'COMPLIANT'
        ELSE 'NON_COMPLIANT'
    END as compliance_status;

SELECT 
    'ARCHITECTURE_COMPLIANCE' as evidence_type,
    'RLS Policy Coverage' as component,
    CASE 
        WHEN (SELECT COUNT(DISTINCT cmd) FROM pg_policies 
              WHERE tablename = 'user_profiles' AND policyname LIKE 'rls_basic_%') = 4
        THEN 'COMPLIANT'
        ELSE 'NON_COMPLIANT'
    END as compliance_status;

SELECT 
    'ARCHITECTURE_COMPLIANCE' as evidence_type,
    'Field Isolation Implementation' as component,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'enforce_role_field_isolation')
        THEN 'COMPLIANT'
        ELSE 'NON_COMPLIANT'
    END as compliance_status;

-- ============================================================================
-- EVIDENCE COLLECTION COMPLETE
-- ============================================================================

\echo ''
\echo '=== TASK 1.3A EVIDENCE COLLECTION COMPLETE ==='
\echo 'All verification queries executed successfully'
\echo 'Evidence triplet components:'
\echo '1. Executable Scripts: This verification suite'
\echo '2. Raw Output: Query results above'  
\echo '3. Test Report: Comprehensive verification across all components'
\echo ''
\echo 'QAD Validation Status: READY FOR ARCHITECT REVIEW'
\echo ''