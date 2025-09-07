-- ============================================================================
-- INTEGRATION ENVIRONMENT BEHAVIORAL TEST SCRIPT
-- ============================================================================
-- Purpose: Execute four use case behavioral tests for IRG validation
-- Date: 2025-09-07
-- Target: Frontend integration environment
-- Evidence: Four use case pattern (Positive/Negative x 2) for architect review
-- ============================================================================

\echo '=== INTEGRATION ENVIRONMENT BEHAVIORAL TEST SCRIPT ==='

-- ============================================================================
-- SEED DATA SETUP (if needed)
-- ============================================================================

\echo '=== SEED DATA SETUP ==='

-- Check if test data exists
SELECT 
    'SEED_DATA_CHECK' as category,
    COUNT(*) as total_profiles,
    COUNT(*) FILTER (WHERE role = 'tcm_practitioner') as tcm_count,
    COUNT(*) FILTER (WHERE role = 'pharmacy') as pharmacy_count,
    COUNT(*) FILTER (WHERE is_public_profile = true) as public_profiles
FROM user_profiles
WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';

-- If no test data, insert minimal seed data for testing
-- (This would normally be executed conditionally)
\echo 'NOTE: If no test data found above, run complete_seed_solution.sql first';

-- ============================================================================
-- BUSINESS FUNCTION DIRECT TEST
-- ============================================================================

\echo '=== BUSINESS FUNCTION DIRECT TEST ==='

-- Test business relationship functions directly
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

-- ============================================================================
-- USE CASE 1: Pharmacy→TCM Positive Case (Should return COUNT > 0)
-- ============================================================================

\echo '=== USE CASE 1: Pharmacy→TCM Positive Case ==='

-- Set JWT context for pharmacy user
SET request.jwt.claims = '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'auth.uid() result:'
SELECT auth.uid() as auth_uid_result;

\echo 'Query result:'
SELECT COUNT(*) as pharmacy_to_tcm_positive FROM v_profiles_tcm_context;

\echo 'Sample row (limit 1):'
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 1;

\echo 'Direct business relationship check:'
SELECT 
    'DIRECT_CHECK' as check_type,
    auth.uid() as current_user,
    '11111111-1111-1111-1111-111111111111'::uuid as target_tcm,
    private.has_prescription_business_relationship(auth.uid(), '11111111-1111-1111-1111-111111111111'::uuid) as has_relationship;

-- ============================================================================
-- USE CASE 2: Non-existent User→TCM Negative Case (Should return COUNT = 0)
-- ============================================================================

\echo '=== USE CASE 2: Non-existent User→TCM Negative Case ==='

-- Set JWT context for non-existent user
SET request.jwt.claims = '{"sub": "88888888-8888-8888-8888-888888888888", "role": "authenticated"}';

\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'Query result:'
SELECT COUNT(*) as nonexistent_to_tcm_negative FROM v_profiles_tcm_context;

\echo 'Sample row (should be empty):'
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 1;

-- ============================================================================
-- USE CASE 3: TCM→Pharmacy Positive Case (Should return COUNT > 0)
-- ============================================================================

\echo '=== USE CASE 3: TCM→Pharmacy Positive Case ==='

-- Set JWT context for TCM user
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'Query result:'
SELECT COUNT(*) as tcm_to_pharmacy_positive FROM v_profiles_pharmacy_context;

\echo 'Sample row (limit 1):'
SELECT id, role, business_name, pharmacy_type FROM v_profiles_pharmacy_context LIMIT 1;

-- ============================================================================
-- USE CASE 4: Non-existent User→Pharmacy Negative Case (Should return COUNT = 0)
-- ============================================================================

\echo '=== USE CASE 4: Non-existent User→Pharmacy Negative Case ==='

-- Set JWT context for non-existent user
SET request.jwt.claims = '{"sub": "77777777-7777-7777-7777-777777777777", "role": "authenticated"}';

\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;

\echo 'Query result:'
SELECT COUNT(*) as nonexistent_to_pharmacy_negative FROM v_profiles_pharmacy_context;

\echo 'Sample row (should be empty):'
SELECT id, role, business_name, pharmacy_type FROM v_profiles_pharmacy_context LIMIT 1;

-- ============================================================================
-- USE CASE 5: PUBLIC DIRECTORY TEST
-- ============================================================================

\echo '=== USE CASE 5: PUBLIC DIRECTORY TEST ==='

-- Reset to valid user context for public directory test
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

\echo 'Public directory access test:'
SELECT COUNT(*) as count_public FROM v_profiles_public;

\echo 'Public directory sample (limit 3):'
SELECT id, role, business_name FROM v_profiles_public ORDER BY business_name LIMIT 3;

-- ============================================================================
-- BEHAVIORAL TEST SUMMARY
-- ============================================================================

\echo '=== BEHAVIORAL TEST SUMMARY ==='

-- Reset context for summary
SET request.jwt.claims = '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';
SELECT COUNT(*) as pharmacy_to_tcm_positive FROM v_profiles_tcm_context;

SET request.jwt.claims = '{"sub": "88888888-8888-8888-8888-888888888888", "role": "authenticated"}';
SELECT COUNT(*) as nonexistent_to_tcm_negative FROM v_profiles_tcm_context;

SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';
SELECT COUNT(*) as tcm_to_pharmacy_positive FROM v_profiles_pharmacy_context;

SET request.jwt.claims = '{"sub": "77777777-7777-7777-7777-777777777777", "role": "authenticated"}';
SELECT COUNT(*) as nonexistent_to_pharmacy_negative FROM v_profiles_pharmacy_context;

-- Public directory (any authenticated user)
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';
SELECT COUNT(*) as public_directory_count FROM v_profiles_public;

-- Final result summary
SELECT 
    'BEHAVIORAL_TEST_RESULTS' as category,
    'Expected: Positive cases > 0, Negative cases = 0, Public = 2' as expectation,
    NOW() as test_timestamp;

\echo '=== INTEGRATION ENVIRONMENT BEHAVIORAL TEST COMPLETE ===';

-- Note for evidence collection
\echo 'NOTE: Expected results for architect validation:';
\echo '  - Pharmacy→TCM Positive: COUNT > 0 (should be 2)';
\echo '  - Non-existent→TCM Negative: COUNT = 0';  
\echo '  - TCM→Pharmacy Positive: COUNT > 0 (should be 2)';
\echo '  - Non-existent→Pharmacy Negative: COUNT = 0';
\echo '  - Public Directory: COUNT = 2 (only is_public_profile=true)';
\echo 'Save complete output for evidence documentation';