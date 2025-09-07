-- ============================================================================
-- INTEGRATION ENVIRONMENT VERIFICATION SCRIPT
-- ============================================================================
-- Purpose: Execute architect-required verification queries for controlled views
-- Date: 2025-09-07
-- Target: Frontend integration environment
-- Evidence: Collection of original SQL output for architect review
-- ============================================================================

\echo '=== INTEGRATION ENVIRONMENT VERIFICATION SCRIPT ==='

-- ============================================================================
-- EVIDENCE 1: VIEW EXISTENCE VERIFICATION
-- ============================================================================
\echo '=== EVIDENCE 1: VIEW EXISTENCE VERIFICATION ==='

-- Architect required query: View existence check
SELECT 
    'VIEW_EXISTENCE_CHECK' as category,
    table_schema,
    table_name 
FROM information_schema.views 
WHERE table_schema='public' 
AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
ORDER BY table_name;

-- ============================================================================
-- EVIDENCE 2: SECURITY BARRIER AND RELOPTIONS VERIFICATION
-- ============================================================================
\echo '=== EVIDENCE 2: SECURITY BARRIER VERIFICATION ==='

-- Architect required query: Security barrier check
SELECT 
    'SECURITY_BARRIER_CHECK' as category,
    relname,
    reloptions 
FROM pg_class 
WHERE relkind='v' 
AND relname IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
ORDER BY relname;

-- ============================================================================
-- EVIDENCE 3: COLUMN SET VERIFICATION (17 NON-PII FIELDS)
-- ============================================================================
\echo '=== EVIDENCE 3: COLUMN SET VERIFICATION ==='

-- Architect required query: Column enumeration
SELECT 
    'COLUMN_SET_CHECK' as category,
    table_name,
    column_name 
FROM information_schema.columns 
WHERE table_schema='public' 
AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public') 
ORDER BY table_name,column_name;

-- Count verification for 17 non-PII fields (6+6+5)
SELECT 
    'COLUMN_COUNT_VERIFICATION' as category,
    table_name,
    COUNT(*) as column_count,
    CASE 
        WHEN table_name = 'v_profiles_pharmacy_context' THEN 'Expected: 6'
        WHEN table_name = 'v_profiles_tcm_context' THEN 'Expected: 6'
        WHEN table_name = 'v_profiles_public' THEN 'Expected: 5'
        ELSE 'Unexpected view'
    END as expected_count
FROM information_schema.columns 
WHERE table_schema='public' 
AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
GROUP BY table_name
ORDER BY table_name;

-- ============================================================================
-- EVIDENCE 4: HELPER FUNCTION SECURITY VERIFICATION
-- ============================================================================
\echo '=== EVIDENCE 4: HELPER FUNCTION SECURITY VERIFICATION ==='

-- Architect required query: Helper function security properties
SELECT 
    'HELPER_FUNCTIONS_SECURITY' as category,
    proname,
    prosecdef as security_definer,
    provolatile as volatility,
    proconfig as search_path_config
FROM pg_proc 
WHERE proname IN ('get_current_user_id','has_prescription_business_relationship','has_referral_business_relationship')
ORDER BY proname;

-- Extended function verification including all helper functions
SELECT 
    'HELPER_FUNCTIONS_EXTENDED' as category,
    proname,
    CASE 
        WHEN prosecdef THEN 'SECURITY DEFINER' 
        ELSE 'SECURITY INVOKER' 
    END as security_setting,
    CASE 
        WHEN provolatile = 'i' THEN 'IMMUTABLE'
        WHEN provolatile = 's' THEN 'STABLE'
        WHEN provolatile = 'v' THEN 'VOLATILE'
        ELSE 'UNKNOWN'
    END as volatility_setting,
    proconfig as search_path_config
FROM pg_proc 
WHERE proname IN ('get_current_user_id','has_prescription_business_relationship','has_referral_business_relationship','get_current_user_role','is_current_user_admin')
ORDER BY proname;

-- ============================================================================
-- EVIDENCE 5: VIEW DEFINITION VERIFICATION
-- ============================================================================
\echo '=== EVIDENCE 5: VIEW DEFINITION VERIFICATION ==='

-- Show actual view definitions to verify business relationship filtering
SELECT 
    'VIEW_DEFINITIONS' as category,
    schemaname,
    viewname,
    LEFT(definition, 200) || '...' as definition_preview
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
ORDER BY viewname;

-- Detailed view definition check for business functions
SELECT 
    'BUSINESS_FUNCTION_CHECK' as category,
    viewname,
    CASE 
        WHEN definition LIKE '%has_prescription_business_relationship%' THEN 'Contains prescription business function'
        WHEN definition LIKE '%has_referral_business_relationship%' THEN 'Contains referral business function'
        WHEN definition LIKE '%is_public_profile = true%' THEN 'Contains public profile filtering'
        ELSE 'No business filtering detected'
    END as business_filtering_check
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
ORDER BY viewname;

-- ============================================================================
-- EVIDENCE 6: PERMISSIONS VERIFICATION
-- ============================================================================
\echo '=== EVIDENCE 6: PERMISSIONS VERIFICATION ==='

-- Check table privileges for authenticated role
SELECT 
    'VIEW_PERMISSIONS' as category,
    table_schema,
    table_name,
    privilege_type,
    grantee
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
AND grantee = 'authenticated'
ORDER BY table_name, privilege_type;

-- Check function execution privileges
SELECT 
    'FUNCTION_PERMISSIONS' as category,
    routine_schema,
    routine_name,
    privilege_type,
    grantee
FROM information_schema.role_routine_grants 
WHERE routine_schema = 'private' 
AND routine_name IN ('get_current_user_id','has_prescription_business_relationship','has_referral_business_relationship','get_current_user_role','is_current_user_admin')
AND grantee = 'authenticated'
ORDER BY routine_name, privilege_type;

-- ============================================================================
-- EVIDENCE 7: ENVIRONMENT AND CONNECTION VERIFICATION
-- ============================================================================
\echo '=== EVIDENCE 7: ENVIRONMENT VERIFICATION ==='

-- Current database and connection info
SELECT 
    'ENVIRONMENT_INFO' as category,
    current_database() as database_name,
    current_user as connection_user,
    inet_server_addr() as server_address,
    version() as postgresql_version;

-- Current timestamp for evidence logging
SELECT 
    'VERIFICATION_TIMESTAMP' as category,
    NOW() as verification_time,
    'Integration Environment Views Verification' as verification_target;

-- Check if we're connected to the right instance by checking some basic system info
SELECT 
    'SYSTEM_VERIFICATION' as category,
    count(*) as total_tables,
    count(*) FILTER (WHERE table_name LIKE 'v_profiles_%') as view_count
FROM information_schema.tables 
WHERE table_schema = 'public';

\echo '=== INTEGRATION ENVIRONMENT VERIFICATION COMPLETE ===';

-- Note for evidence collection
\echo 'NOTE: Save this output to integration_evidence.txt for architect review';
\echo 'FORMAT: All original SQL outputs ready for appending to evidence documents';