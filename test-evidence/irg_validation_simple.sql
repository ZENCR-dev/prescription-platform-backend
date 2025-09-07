-- ============================================================================
-- IRG Simple Business Logic Validation Test
-- ============================================================================
-- Test business relationship functions directly without creating user records
-- This avoids auth.users trigger complications

\echo '=== IRG BUSINESS LOGIC VALIDATION ==='

-- Test 1: Business relationship function validation with existing data
\echo '=== Testing business relationship functions ==='

-- Check what users currently exist
SELECT id, role, status, business_info IS NOT NULL as has_business_info
FROM user_profiles 
WHERE role IN ('tcm_practitioner', 'pharmacy') 
ORDER BY role, id;

-- Test has_prescription_business_relationship function directly
\echo '=== Testing has_prescription_business_relationship ==='
SELECT 
    'Valid pharmacy→tcm test' as test_case,
    private.has_prescription_business_relationship(
        (SELECT id FROM user_profiles WHERE role = 'pharmacy' LIMIT 1),
        (SELECT id FROM user_profiles WHERE role = 'tcm_practitioner' LIMIT 1)
    ) as result;

-- Test has_referral_business_relationship function directly  
\echo '=== Testing has_referral_business_relationship ==='
SELECT 
    'Valid tcm→pharmacy test' as test_case,
    private.has_referral_business_relationship(
        (SELECT id FROM user_profiles WHERE role = 'tcm_practitioner' LIMIT 1),
        (SELECT id FROM user_profiles WHERE role = 'pharmacy' LIMIT 1)
    ) as result;

-- Test views with admin user (should bypass business relationship checks)
\echo '=== Testing view access with admin context ==='
SELECT set_config('request.jwt.claims', '{"sub": "' || id || '", "role": "authenticated"}', true)
FROM user_profiles WHERE role = 'admin' LIMIT 1;

SELECT COUNT(*) as tcm_count_admin FROM v_profiles_tcm_context;
SELECT COUNT(*) as pharmacy_count_admin FROM v_profiles_pharmacy_context;
SELECT COUNT(*) as public_count_admin FROM v_profiles_public;

-- Test views with regular user context (should apply business relationship filters)
\echo '=== Testing view access with regular user context ==='
SELECT set_config('request.jwt.claims', '{"sub": "' || id || '", "role": "authenticated"}', true)
FROM user_profiles WHERE role = 'tcm_practitioner' LIMIT 1;

SELECT COUNT(*) as tcm_count_regular FROM v_profiles_tcm_context;
SELECT COUNT(*) as pharmacy_count_regular FROM v_profiles_pharmacy_context;

-- Check view definitions to understand filtering
\echo '=== Current view definitions ==='
\echo 'TCM Context View:'
SELECT pg_get_viewdef('v_profiles_tcm_context', true);

\echo 'Pharmacy Context View:'  
SELECT pg_get_viewdef('v_profiles_pharmacy_context', true);

\echo 'Public View:'
SELECT pg_get_viewdef('v_profiles_public', true);

-- Test security barrier presence
\echo '=== Security barrier validation ==='
SELECT viewname, reloptions 
FROM pg_views v
JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
WHERE v.schemaname = 'public' AND v.viewname LIKE 'v_profiles_%'
ORDER BY v.viewname;

-- Column compliance check
\echo '=== Zero-PII column compliance ==='
SELECT 'pharmacy' as src, column_name 
FROM information_schema.columns 
WHERE table_name = 'v_profiles_pharmacy_context' AND table_schema = 'public'
UNION ALL
SELECT 'tcm' as src, column_name 
FROM information_schema.columns 
WHERE table_name = 'v_profiles_tcm_context' AND table_schema = 'public'
UNION ALL
SELECT 'public' as src, column_name 
FROM information_schema.columns 
WHERE table_name = 'v_profiles_public' AND table_schema = 'public'
ORDER BY src, column_name;

\echo '=== IRG VALIDATION COMPLETE ==='