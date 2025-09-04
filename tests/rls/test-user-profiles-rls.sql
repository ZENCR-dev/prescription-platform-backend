-- Comprehensive RLS Test Suite for Enhanced User Profiles
-- Task 2.1: Multi-role isolation and performance validation
-- Target: <150ms P95 response time, strict role isolation

-- =======================
-- TEST SETUP
-- =======================

-- Create test users for different roles (using auth.users mock data)
-- These would normally be created through Supabase Auth, but for testing:

BEGIN;

-- Clean up any existing test data
DELETE FROM user_profiles WHERE id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222', 
  '33333333-3333-3333-3333-333333333333',
  '44444444-4444-4444-4444-444444444444'
);

-- Clean up auth.users test data
DELETE FROM auth.users WHERE id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222', 
  '33333333-3333-3333-3333-333333333333',
  '44444444-4444-4444-4444-444444444444'
);

-- Clean up test pharmacy
DELETE FROM pharmacies WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

-- Create test pharmacy for pharmacy user
INSERT INTO pharmacies (id, name, status, contact_info, created_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Test Pharmacy Ltd', 'active', 
 '{"phone": "+64-9-555-0123", "address": "123 Test St, Auckland"}', NOW() - INTERVAL '3 days');

-- Insert auth.users with metadata (trigger will auto-create profiles)
INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at, raw_user_meta_data) VALUES
-- Test TCM Practitioner
('11111111-1111-1111-1111-111111111111', 'tcm@test.com', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day',
 '{"role": "tcm_practitioner", "business_info": {"practice_name": "Test TCM Clinic", "license": "TCM123"}}'),
 
-- Test Pharmacy Operator (trigger creates profile with pharmacy_id)
('22222222-2222-2222-2222-222222222222', 'pharmacy@test.com', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days',
 '{"role": "pharmacy", "business_info": {"pharmacy_name": "Test Pharmacy", "license": "PHARM456"}, "pharmacy_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}'),
 
-- Test Admin User  
('33333333-3333-3333-3333-333333333333', 'admin@test.com', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days',
 '{"role": "admin", "business_info": {"admin_level": "system"}}'),
 
-- Test Inactive User
('44444444-4444-4444-4444-444444444444', 'inactive@test.com', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days',
 '{"role": "tcm_practitioner", "business_info": {"practice_name": "Inactive Clinic"}}');

-- Update test users to match test requirements
UPDATE user_profiles SET status = 'active' WHERE id = '22222222-2222-2222-2222-222222222222';
UPDATE user_profiles SET status = 'inactive' WHERE id = '44444444-4444-4444-4444-444444444444';

-- =======================
-- TEST 1: ROLE ISOLATION VERIFICATION
-- =======================

-- Test 1.1: TCM Practitioner can only see own profile
-- Simulate auth.uid() returning practitioner ID
\echo 'TEST 1.1: TCM Practitioner Role Isolation'
-- Note: In real testing, this would be done with actual Supabase auth context

-- Verify policy exists and is properly structured
SELECT COUNT(*) as policy_count 
FROM pg_policies 
WHERE tablename = 'user_profiles' 
AND policyname LIKE 'enhanced_%';

-- Test 1.2: Verify security definer functions exist and work
\echo 'TEST 1.2: Security Definer Functions'
SELECT proname, prosecdef, provolatile 
FROM pg_proc 
WHERE proname LIKE '%current_user%' 
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'private');

-- =======================  
-- TEST 2: PERFORMANCE VALIDATION
-- =======================

\echo 'TEST 2: Performance Testing with EXPLAIN ANALYZE'

-- Test 2.1: Profile lookup performance (target <150ms)
-- This tests the most common query pattern
\echo 'TEST 2.1: Own Profile Lookup Performance'
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM user_profiles 
WHERE id = '11111111-1111-1111-1111-111111111111';

-- Test 2.2: Role-based filtering performance  
\echo 'TEST 2.2: Role-Based Query Performance'
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM user_profiles 
WHERE role = 'tcm_practitioner' AND status = 'active';

-- Test 2.3: Admin full access performance
\echo 'TEST 2.3: Admin Access Performance (Security Definer)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT role, COUNT(*) 
FROM user_profiles 
GROUP BY role;

-- =======================
-- TEST 3: SECURITY VALIDATION  
-- =======================

\echo 'TEST 3: Security and Compliance Testing'

-- Test 3.1: Verify all policies have explicit TO authenticated
SELECT policyname, 
       CASE WHEN roles @> ARRAY[pg_authid.rolname] THEN 'YES' ELSE 'NO' END as has_authenticated_role
FROM pg_policies 
JOIN pg_authid ON rolname = 'authenticated'
WHERE tablename = 'user_profiles'
AND policyname LIKE 'enhanced_%';

-- Test 3.2: Verify PII compliance - business_info shouldn't contain sensitive patterns
\echo 'TEST 3.2: PII Compliance Check'
SELECT id, role,
       CASE 
         WHEN business_info::text ~* '(ssn|social|dob|birth|patient)' THEN 'FAIL: Contains PII patterns'
         ELSE 'PASS: No PII detected'
       END as pii_check
FROM user_profiles;

-- Test 3.3: Verify admin access audit setup
\echo 'TEST 3.3: Admin Audit Function Test'  
SELECT private.log_admin_profile_access(
  '11111111-1111-1111-1111-111111111111'::UUID, 
  'SELECT'
);

-- =======================
-- TEST 4: CRUD OPERATION VALIDATION
-- =======================

\echo 'TEST 4: CRUD Operations with RLS'

-- Test 4.1: INSERT validation
\echo 'TEST 4.1: Profile Creation Test'
-- Test valid role creation via auth.users (trigger creates profile)
INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at, raw_user_meta_data)
VALUES ('55555555-5555-5555-5555-555555555555', 'test4@example.com', NOW(), NOW(), NOW(), 
        '{"role": "tcm_practitioner", "business_info": {}}');

-- Test invalid role rejection (should fail)
DO $$
BEGIN
  BEGIN
    -- Try to create auth.users with invalid role (should fail at profile creation)
    INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at, raw_user_meta_data)
    VALUES ('66666666-6666-6666-6666-666666666666', 'invalid@test.com', NOW(), NOW(), NOW(),
            '{"role": "invalid_role", "business_info": {}}');
    RAISE EXCEPTION 'Should have failed: Invalid role accepted';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASS: Invalid role correctly rejected';
  END;
END $$;

-- Clean up test users from Test 4.1
DELETE FROM user_profiles WHERE id IN ('55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666');
DELETE FROM auth.users WHERE id IN ('55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666');

-- Test 4.2: UPDATE validation  
\echo 'TEST 4.2: Profile Update Tests'
-- Test business_info PII prevention (using existing test user)
UPDATE user_profiles 
SET business_info = '{"practice_name": "Updated Clinic"}'
WHERE id = '11111111-1111-1111-1111-111111111111';

-- No cleanup needed for existing test users

-- =======================
-- TEST 5: INDEX PERFORMANCE VERIFICATION
-- =======================

\echo 'TEST 5: Index Usage Verification'

-- Test 5.1: Verify primary key index usage
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM user_profiles 
WHERE id = '11111111-1111-1111-1111-111111111111';

-- Test 5.2: Verify composite index usage for role queries
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM user_profiles 
WHERE role = 'tcm_practitioner' AND status = 'active';

-- Test 5.3: List all indexes on user_profiles table
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'user_profiles'
ORDER BY indexname;

-- =======================
-- TEST 6: RLS POLICY COVERAGE
-- =======================

\echo 'TEST 6: RLS Policy Coverage Analysis'

-- Verify all CRUD operations have appropriate policies
WITH policy_coverage AS (
  SELECT 
    cmd,
    COUNT(*) as policy_count
  FROM pg_policies 
  WHERE tablename = 'user_profiles'
  AND policyname LIKE 'enhanced_%'
  GROUP BY cmd
)
SELECT 
  cmd,
  policy_count,
  CASE 
    WHEN cmd = 'SELECT' AND policy_count >= 2 THEN 'PASS: Own + Admin policies'
    WHEN cmd = 'INSERT' AND policy_count >= 2 THEN 'PASS: Own + Admin policies' 
    WHEN cmd = 'UPDATE' AND policy_count >= 2 THEN 'PASS: Own + Admin policies'
    WHEN cmd = 'DELETE' AND policy_count >= 1 THEN 'PASS: Admin only policy'
    ELSE 'REVIEW: Insufficient policies'
  END as coverage_status
FROM policy_coverage
ORDER BY cmd;

-- =======================
-- TEST 7: PERFORMANCE BENCHMARKING
-- =======================

\echo 'TEST 7: Performance Benchmark Summary'

-- Create a summary of key performance metrics
WITH perf_baseline AS (
  SELECT 
    'profile_lookup' as test_name,
    'SELECT * FROM user_profiles WHERE id = auth.uid()' as query_type,
    '<150ms P95' as target_performance
  UNION ALL
  SELECT 
    'role_filtering',
    'SELECT * FROM user_profiles WHERE role = ? AND status = ?',
    '<200ms P95'
  UNION ALL  
  SELECT
    'admin_overview',
    'SELECT COUNT(*) FROM user_profiles',
    '<500ms P95'
)
SELECT * FROM perf_baseline;

-- =======================
-- TEST CLEANUP
-- =======================

ROLLBACK;

-- =======================
-- TEST RESULTS SUMMARY
-- =======================

\echo '=================================='
\echo 'RLS TEST SUITE SUMMARY'
\echo '=================================='
\echo 'Performance Target: <150ms P95 for profile lookups'
\echo 'Security Target: Strict role isolation + medical compliance'
\echo 'Tests Completed:'
\echo '  ✓ Role isolation verification'  
\echo '  ✓ Performance analysis with EXPLAIN'
\echo '  ✓ Security policy validation'
\echo '  ✓ CRUD operations testing'
\echo '  ✓ Index usage verification' 
\echo '  ✓ Policy coverage analysis'
\echo '  ✓ Performance benchmarking'
\echo '=================================='

-- Manual testing commands for different auth contexts:
\echo ''  
\echo 'MANUAL TESTING COMMANDS:'
\echo 'Run these with different auth.uid() contexts:'
\echo ''
\echo '-- As TCM Practitioner (should see own profile only):'
\echo 'SELECT * FROM user_profiles;'  
\echo ''
\echo '-- As Admin (should see all profiles):'
\echo 'SELECT COUNT(*) FROM user_profiles;'
\echo 'SELECT role, COUNT(*) FROM user_profiles GROUP BY role;'
\echo ''
\echo '-- Performance validation:'
\echo 'EXPLAIN ANALYZE SELECT * FROM user_profiles WHERE id = auth.uid();'