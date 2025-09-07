-- ============================================================================
-- IRG TEST SUITE - FIXED WITH JWT CONTEXT AND SEED DATA
-- ============================================================================
-- Comprehensive IRG behavioral testing with proper JWT context

\echo '=== IRG BEHAVIORAL TEST SUITE WITH FIXED JWT CONTEXT ==='

-- ============================================================================
-- EVIDENCE COLLECTION 1: POLICY CATEGORIZATION
-- ============================================================================
\echo '=== EVIDENCE 1: POLICY CATEGORIZATION ==='

\echo 'Baseline Policies (1.3A):'
SELECT 
    'BASELINE_1.3A' as category,
    policyname, 
    cmd,
    tablename
FROM pg_policies 
WHERE tablename = 'user_profiles' 
AND schemaname = 'public'
AND policyname NOT LIKE '%business_relationship%'
ORDER BY policyname;

\echo 'Extension Policies (1.3B - Target: 4 policies):'
SELECT 
    'EXTENSION_1.3B' as category,
    policyname, 
    cmd,
    tablename,
    'CONTAINS_BUSINESS_FUNCTION' as policy_type
FROM pg_policies 
WHERE tablename = 'user_profiles' 
AND schemaname = 'public'
AND (policyname LIKE '%cross_role%' OR policyname LIKE '%admin_comprehensive%' OR policyname LIKE '%public_directory%')
ORDER BY policyname;

\echo 'View Policies (Should be 0):'
SELECT 
    'VIEW_POLICIES' as category,
    COUNT(*) as policy_count,
    'Expected: 0' as expected
FROM pg_policies 
WHERE tablename LIKE 'v_profiles_%';

-- ============================================================================
-- EVIDENCE COLLECTION 2: VIEW SECURITY BARRIERS
-- ============================================================================
\echo '=== EVIDENCE 2: VIEW SECURITY BARRIERS ==='
SELECT 
    'SECURITY_BARRIER_CHECK' as category,
    v.viewname, 
    COALESCE(opts.option_value, 'false') as security_barrier_value,
    'Expected: true' as expected
FROM pg_views v
LEFT JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
LEFT JOIN pg_options_to_table(c.reloptions) opts ON opts.option_name = 'security_barrier'
WHERE v.schemaname = 'public' 
AND v.viewname LIKE 'v_profiles_%'
ORDER BY v.viewname;

-- ============================================================================
-- EVIDENCE COLLECTION 3: HELPER FUNCTION SECURITY  
-- ============================================================================
\echo '=== EVIDENCE 3: HELPER FUNCTION SECURITY ==='
SELECT 
    'HELPER_FUNCTIONS' as category,
    proname, 
    CASE WHEN prosecdef THEN 'SECURITY DEFINER' ELSE 'NO SECURITY DEFINER' END as security_setting,
    CASE WHEN provolatile = 'i' THEN 'IMMUTABLE' WHEN provolatile = 's' THEN 'STABLE' ELSE 'VOLATILE' END as volatility,
    proconfig::text as search_path_config,
    CASE WHEN proconfig::text LIKE '%search_path%' THEN 'FIXED_SEARCH_PATH' ELSE 'NO_FIXED_SEARCH_PATH' END as search_path_status
FROM pg_proc 
WHERE proname IN ('has_prescription_business_relationship', 'has_referral_business_relationship', 'get_current_user_role', 'is_current_user_admin')
AND pronamespace = 'private'::regnamespace
ORDER BY proname;

-- ============================================================================
-- EVIDENCE COLLECTION 4: BEHAVIORAL USE CASES WITH JWT CONTEXT
-- ============================================================================

-- Test the business relationship functions directly to understand their behavior
\echo '=== BUSINESS FUNCTION TESTING ==='
SELECT 
    'FUNCTION_TEST' as test_type,
    private.has_prescription_business_relationship(
        '33333333-3333-3333-3333-333333333333'::uuid, 
        '11111111-1111-1111-1111-111111111111'::uuid
    ) as pharmacy_to_tcm_relationship,
    private.has_referral_business_relationship(
        '11111111-1111-1111-1111-111111111111'::uuid,
        '33333333-3333-3333-3333-333333333333'::uuid  
    ) as tcm_to_pharmacy_relationship;

-- USE CASE 1: Pharmacy→TCM Positive Case (Should return COUNT > 0)
\echo '=== USE CASE 1: Pharmacy→TCM Positive Case ==='

-- Set JWT context with SET command (more persistent)
SET request.jwt.claims = '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'auth.uid() result:'
SELECT auth.uid() as auth_uid_result;

\echo 'Query result:'
SELECT COUNT(*) as count_positive_case_1 FROM v_profiles_tcm_context;

\echo 'Sample row (limit 1):'
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 1;

\echo 'Direct business relationship check from current context:'
SELECT 
    auth.uid() as current_user,
    '11111111-1111-1111-1111-111111111111'::uuid as target_tcm,
    private.has_prescription_business_relationship(auth.uid(), '11111111-1111-1111-1111-111111111111'::uuid) as has_relationship;

-- USE CASE 2: Non-existent User→TCM Negative Case (Should return COUNT = 0) 
\echo '=== USE CASE 2: Non-existent User→TCM Negative Case ==='

SET request.jwt.claims = '{"sub": "88888888-8888-8888-8888-888888888888", "role": "authenticated"}';

\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'Query result:'
SELECT COUNT(*) as count_negative_case_1 FROM v_profiles_tcm_context;

\echo 'Sample row (should be empty):'
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 1;

-- USE CASE 3: TCM→Pharmacy Positive Case (Should return COUNT > 0)
\echo '=== USE CASE 3: TCM→Pharmacy Positive Case ==='  

SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'Query result:'
SELECT COUNT(*) as count_positive_case_2 FROM v_profiles_pharmacy_context;

\echo 'Sample row (limit 1):'
SELECT id, role, business_name, pharmacy_type FROM v_profiles_pharmacy_context LIMIT 1;

-- USE CASE 4: Non-existent User→Pharmacy Negative Case (Should return COUNT = 0)
\echo '=== USE CASE 4: Non-existent User→Pharmacy Negative Case ==='

SET request.jwt.claims = '{"sub": "77777777-7777-7777-7777-777777777777", "role": "authenticated"}';

\echo 'Current JWT context:'  
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'Query result:'
SELECT COUNT(*) as count_negative_case_2 FROM v_profiles_pharmacy_context;

\echo 'Sample row (should be empty):'
SELECT id, role, business_name, pharmacy_type FROM v_profiles_pharmacy_context LIMIT 1;

-- ============================================================================
-- EVIDENCE COLLECTION 5: PUBLIC DIRECTORY & ZERO-PII COMPLIANCE
-- ============================================================================
\echo '=== EVIDENCE 5: PUBLIC DIRECTORY & ZERO-PII COMPLIANCE ==='

\echo 'Public directory access test (reset to valid user context):'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';
SELECT COUNT(*) as public_directory_count FROM v_profiles_public;
SELECT id, role, business_name FROM v_profiles_public LIMIT 3;

\echo 'Zero-PII column compliance check:'
SELECT 'v_profiles_pharmacy_context' as view_name, column_name 
FROM information_schema.columns 
WHERE table_name = 'v_profiles_pharmacy_context' AND table_schema = 'public'
UNION ALL
SELECT 'v_profiles_tcm_context' as view_name, column_name 
FROM information_schema.columns 
WHERE table_name = 'v_profiles_tcm_context' AND table_schema = 'public'
UNION ALL
SELECT 'v_profiles_public' as view_name, column_name 
FROM information_schema.columns 
WHERE table_name = 'v_profiles_public' AND table_schema = 'public'
ORDER BY view_name, column_name;

-- ============================================================================
-- SEED DATA VERIFICATION
-- ============================================================================
\echo '=== SEED DATA VERIFICATION ==='
SELECT 
    'SEED_DATA_CHECK' as category,
    COUNT(*) as total_profiles,
    COUNT(*) FILTER (WHERE role = 'tcm_practitioner') as tcm_count,
    COUNT(*) FILTER (WHERE role = 'pharmacy') as pharmacy_count,
    COUNT(*) FILTER (WHERE is_public_profile = true) as public_profiles
FROM user_profiles;

SELECT 
    'PROFILE_DETAILS' as category,
    id,
    role,
    status, 
    business_info->>'business_name' as business_name,
    is_public_profile
FROM user_profiles 
ORDER BY role, id;

\echo '=== IRG TEST SUITE COMPLETE ===';