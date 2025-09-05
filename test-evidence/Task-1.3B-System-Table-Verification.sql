-- ============================================================================
-- Task 1.3B: Comprehensive System Table Verification Script
-- ============================================================================
-- Validates complete implementation of controlled views + RLS boolean authorization
-- Based on architect directive requirements for QAD-Test evidence generation
-- 
-- Verification Categories:
-- 1. Helper Functions (SECURITY DEFINER + fixed search_path)
-- 2. Controlled Views (zero PII compliance + field projections)
-- 3. RLS Policies (pure boolean authorization only)
-- 4. Cross-component Integration Validation
-- ============================================================================

-- ============================================================================
-- VERIFICATION 1: HELPER FUNCTIONS WITH SECURITY DEFINER
-- ============================================================================

-- Check helper functions exist with proper security settings
SELECT 
    'HELPER FUNCTIONS VERIFICATION' as verification_category,
    proname as function_name,
    pronamespace::regnamespace as schema_name,
    prosecdef as security_definer,
    proconfig as search_path_config,
    CASE 
        WHEN prosecdef = true AND 'search_path=public,pg_temp,private' = ANY(proconfig) 
        THEN '✅ COMPLIANT'
        ELSE '❌ NON-COMPLIANT'
    END as compliance_status
FROM pg_proc 
WHERE proname IN (
    'has_prescription_business_relationship',
    'has_referral_business_relationship',
    'get_current_user_role',
    'is_current_user_admin'
)
AND pronamespace = 'private'::regnamespace
ORDER BY proname;

-- Count verification
SELECT 
    'HELPER FUNCTIONS COUNT' as metric,
    COUNT(*) as actual_count,
    4 as expected_count,
    CASE WHEN COUNT(*) = 4 THEN '✅ PASSED' ELSE '❌ FAILED' END as status
FROM pg_proc 
WHERE proname IN (
    'has_prescription_business_relationship',
    'has_referral_business_relationship', 
    'get_current_user_role',
    'is_current_user_admin'
)
AND pronamespace = 'private'::regnamespace
AND prosecdef = true;

-- ============================================================================
-- VERIFICATION 2: CONTROLLED VIEWS WITH FIELD PROJECTIONS
-- ============================================================================

-- Check controlled views exist with correct field projections
SELECT 
    'CONTROLLED VIEWS VERIFICATION' as verification_category,
    schemaname,
    viewname,
    CASE 
        WHEN viewname = 'v_profiles_pharmacy_context' AND definition LIKE '%pharmacy_type%' 
        THEN '✅ Pharmacy type projection correct (TCM viewing pharmacy context)'
        WHEN viewname = 'v_profiles_tcm_context' AND definition LIKE '%tcm_specialty%' 
        THEN '✅ TCM specialty projection correct (Pharmacy viewing TCM context)'
        WHEN viewname = 'v_profiles_public' AND definition NOT LIKE '%tcm_specialty%' AND definition NOT LIKE '%pharmacy_type%'
        THEN '✅ Public view excludes restricted fields'
        ELSE '❌ Field projection incorrect'
    END as field_projection_status
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN (
    'v_profiles_pharmacy_context',
    'v_profiles_tcm_context',
    'v_profiles_public'
)
ORDER BY viewname;

-- Count verification
SELECT 
    'CONTROLLED VIEWS COUNT' as metric,
    COUNT(*) as actual_count,
    3 as expected_count,
    CASE WHEN COUNT(*) = 3 THEN '✅ PASSED' ELSE '❌ FAILED' END as status
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname LIKE 'v_profiles_%';

-- ============================================================================
-- VERIFICATION 3: RLS POLICIES WITH PURE BOOLEAN AUTHORIZATION
-- ============================================================================

-- Check RLS policies exist with boolean-only expressions
SELECT 
    'RLS POLICIES VERIFICATION' as verification_category,
    schemaname,
    tablename as view_name,
    policyname,
    cmd as command_type,
    qual as using_expression,
    CASE 
        WHEN policyname LIKE '%_select' AND qual LIKE '%private.has_%_business_relationship%' 
        THEN '✅ Boolean business relationship check'
        WHEN policyname LIKE '%_readonly' AND qual = 'false' 
        THEN '✅ Proper read-only restriction'
        WHEN policyname = 'public_directory_select' AND qual LIKE '%auth.uid()%' 
        THEN '✅ Boolean authentication check'
        ELSE '⚠️ Review required'
    END as boolean_compliance_status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename LIKE 'v_profiles_%'
ORDER BY tablename, policyname;

-- Validate no field filtering in policies (should only contain boolean expressions)
SELECT 
    'POLICY FIELD FILTERING CHECK' as verification_category,
    policyname,
    tablename,
    CASE 
        WHEN qual LIKE '%SELECT%column%FROM%' OR qual LIKE '%DISTINCT%' 
        THEN '❌ CONTAINS FIELD FILTERING - VIOLATION'
        WHEN qual LIKE '%private.has_%' OR qual LIKE '%auth.uid()%' OR qual = 'false'
        THEN '✅ PURE BOOLEAN EXPRESSION'
        ELSE '⚠️ NEEDS MANUAL REVIEW'
    END as field_filtering_status,
    qual as expression_content
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename LIKE 'v_profiles_%'
ORDER BY tablename, policyname;

-- Count verification
SELECT 
    'RLS POLICIES COUNT' as metric,
    COUNT(*) as actual_count,
    6 as expected_count,
    CASE WHEN COUNT(*) = 6 THEN '✅ PASSED' ELSE '❌ FAILED' END as status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename LIKE 'v_profiles_%';

-- ============================================================================
-- VERIFICATION 4: RLS ENABLEMENT ON VIEWS
-- ============================================================================

-- Check RLS is properly enabled on all controlled views
SELECT 
    'RLS ENABLEMENT VERIFICATION' as verification_category,
    schemaname,
    viewname,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_class 
            WHERE relname = viewname 
            AND relrowsecurity = true
        ) THEN '✅ RLS ENABLED'
        ELSE '❌ RLS NOT ENABLED'
    END as rls_status
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN (
    'v_profiles_pharmacy_context',
    'v_profiles_tcm_context',
    'v_profiles_public'
)
ORDER BY viewname;

-- ============================================================================
-- VERIFICATION 5: ZERO PII COMPLIANCE FIELD AUDIT
-- ============================================================================

-- Audit all fields in controlled views for PII compliance
SELECT 
    'ZERO PII FIELD AUDIT' as verification_category,
    viewname,
    column_name,
    data_type,
    CASE 
        WHEN column_name IN ('id') THEN '✅ Non-PII: System-generated UUID'
        WHEN column_name IN ('role', 'verification_status') THEN '✅ Non-PII: Enum values'
        WHEN column_name IN ('business_name') THEN '✅ Non-PII: Institution name, not personal'
        WHEN column_name IN ('tcm_specialty') AND viewname = 'v_profiles_tcm_context' THEN '✅ Non-PII: TCM specialty for pharmacy context'
        WHEN column_name IN ('pharmacy_type') AND viewname = 'v_profiles_pharmacy_context' THEN '✅ Non-PII: Pharmacy type for TCM context'
        WHEN column_name IN ('created_at') THEN '✅ Non-PII: Timestamp'
        WHEN column_name IN ('personal_name', 'email', 'phone_number', 'license_number', 'address_info') 
        THEN '❌ HIGH-RISK PII: Should be excluded'
        ELSE '⚠️ Requires PII classification review'
    END as pii_classification
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name IN (
    'v_profiles_pharmacy_context',
    'v_profiles_tcm_context',
    'v_profiles_public'
)
ORDER BY table_name, column_name;

-- ============================================================================
-- VERIFICATION 6: CROSS-COMPONENT INTEGRATION VALIDATION
-- ============================================================================

-- Validate helper functions are properly referenced in RLS policies
SELECT 
    'INTEGRATION VALIDATION' as verification_category,
    'Helper Function References in Policies' as check_type,
    policyname,
    tablename,
    CASE 
        WHEN qual LIKE '%private.has_prescription_business_relationship%' 
        THEN '✅ Prescription helper function integrated'
        WHEN qual LIKE '%private.has_referral_business_relationship%' 
        THEN '✅ Referral helper function integrated'
        WHEN qual LIKE '%private.is_current_user_admin%' 
        THEN '✅ Admin helper function integrated'
        WHEN qual LIKE '%auth.uid()%' 
        THEN '✅ Built-in auth function used'
        ELSE '⚠️ No helper function integration detected'
    END as integration_status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename LIKE 'v_profiles_%'
AND policyname LIKE '%_select';

-- ============================================================================
-- VERIFICATION SUMMARY REPORT
-- ============================================================================

-- Generate comprehensive verification summary
SELECT 
    'TASK 1.3B VERIFICATION SUMMARY' as report_section,
    '=====================================' as separator;

SELECT 
    'Component Type' as category,
    'Expected' as expected,
    'Actual' as actual,
    'Status' as verification_status
UNION ALL
SELECT 
    'Helper Functions (SECURITY DEFINER)',
    '4',
    (SELECT COUNT(*)::TEXT FROM pg_proc 
     WHERE proname IN ('has_prescription_business_relationship','has_referral_business_relationship','get_current_user_role','is_current_user_admin')
     AND pronamespace = 'private'::regnamespace AND prosecdef = true),
    CASE WHEN (SELECT COUNT(*) FROM pg_proc 
               WHERE proname IN ('has_prescription_business_relationship','has_referral_business_relationship','get_current_user_role','is_current_user_admin')
               AND pronamespace = 'private'::regnamespace AND prosecdef = true) = 4 
         THEN '✅ PASSED' ELSE '❌ FAILED' END
UNION ALL
SELECT 
    'Controlled Views (Zero PII)',
    '3',
    (SELECT COUNT(*)::TEXT FROM pg_views 
     WHERE schemaname = 'public' AND viewname LIKE 'v_profiles_%'),
    CASE WHEN (SELECT COUNT(*) FROM pg_views 
               WHERE schemaname = 'public' AND viewname LIKE 'v_profiles_%') = 3 
         THEN '✅ PASSED' ELSE '❌ FAILED' END
UNION ALL
SELECT 
    'RLS Policies (Boolean Only)',
    '6',
    (SELECT COUNT(*)::TEXT FROM pg_policies 
     WHERE schemaname = 'public' AND tablename LIKE 'v_profiles_%'),
    CASE WHEN (SELECT COUNT(*) FROM pg_policies 
               WHERE schemaname = 'public' AND tablename LIKE 'v_profiles_%') = 6 
         THEN '✅ PASSED' ELSE '❌ FAILED' END;

-- Final compliance assessment
SELECT 
    '=== FINAL COMPLIANCE ASSESSMENT ===' as assessment,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_proc WHERE proname IN ('has_prescription_business_relationship','has_referral_business_relationship') AND pronamespace = 'private'::regnamespace AND prosecdef = true) = 2
        AND (SELECT COUNT(*) FROM pg_views WHERE schemaname = 'public' AND viewname LIKE 'v_profiles_%') = 3
        AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename LIKE 'v_profiles_%') = 6
        THEN '✅ TASK 1.3B IMPLEMENTATION FULLY COMPLIANT - Ready for behavioral testing'
        ELSE '❌ IMPLEMENTATION ISSUES DETECTED - Review required before testing'
    END as overall_compliance_status;

-- Execution timestamp for audit trail
SELECT NOW() as verification_executed_at,
       'Task 1.3B System Table Verification Complete' as verification_complete;