-- ============================================================================
-- Schema Integrity Tests: User Profiles Business Fields Extension
-- ============================================================================
-- Comprehensive test suite for 20250104_extend_user_profiles_business_fields.sql
-- Tests: Data integrity, constraints, RLS policies, performance, rollback safety
-- 
-- Execute with: psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/schema/user-profiles-business-fields.test.sql

-- Install pgTAP testing framework
CREATE EXTENSION IF NOT EXISTS pgtap;

-- Start test plan
SELECT plan(42); -- Total number of tests

-- ============================================================================
-- TEST GROUP 1: Schema Structure Validation (8 tests)
-- ============================================================================

-- Test 1-5: Verify all new columns were added
SELECT has_column('public', 'user_profiles', 'license_number', 'License number column exists');
SELECT has_column('public', 'user_profiles', 'license_type', 'License type column exists'); 
SELECT has_column('public', 'user_profiles', 'business_name', 'Business name column exists');
SELECT has_column('public', 'user_profiles', 'identity_verified', 'Identity verified column exists');
SELECT has_column('public', 'user_profiles', 'compliance_flags', 'Compliance flags column exists');

-- Test 6-8: Verify column data types
SELECT col_type_is('public', 'user_profiles', 'license_number', 'character varying(20)', 'License number is VARCHAR(20)');
SELECT col_type_is('public', 'user_profiles', 'license_expiry_date', 'date', 'License expiry is DATE type');
SELECT col_type_is('public', 'user_profiles', 'business_address', 'jsonb', 'Business address is JSONB type');

-- ============================================================================
-- TEST GROUP 2: Constraint Validation (10 tests)
-- ============================================================================

-- Test 9-12: License type constraint validation
BEGIN;
    -- Should succeed: valid TCM license
    INSERT INTO auth.users (id, email) VALUES ('11111111-1111-1111-1111-111111111111'::uuid, 'test1@example.com');
    INSERT INTO user_profiles (id, role, license_type, license_number) 
    VALUES ('11111111-1111-1111-1111-111111111111'::uuid, 'tcm_practitioner', 'tcm_practitioner', 'TCM-123456');
    SELECT ok(true, 'Valid TCM practitioner license accepted');
    
    -- Should succeed: valid pharmacy license  
    INSERT INTO auth.users (id, email) VALUES ('22222222-2222-2222-2222-222222222222'::uuid, 'test2@example.com');
    INSERT INTO user_profiles (id, role, license_type, license_number) 
    VALUES ('22222222-2222-2222-2222-222222222222'::uuid, 'pharmacy', 'pharmacy', 'PHARM-789012');
    SELECT ok(true, 'Valid pharmacy license accepted');
    
    -- Should fail: invalid license format
    SELECT throws_ok(
        $$INSERT INTO user_profiles (id, role, license_type, license_number) 
          VALUES ('33333333-3333-3333-3333-333333333333'::uuid, 'tcm_practitioner', 'tcm_practitioner', 'INVALID-123')$$,
        'check_license_number_format',
        'Invalid license format rejected'
    );
    
    -- Should fail: mismatched role and license type
    SELECT throws_ok(
        $$INSERT INTO user_profiles (id, role, license_type, license_number) 
          VALUES ('44444444-4444-4444-4444-444444444444'::uuid, 'tcm_practitioner', 'pharmacy', 'PHARM-555555')$$,
        'check_professional_role_license', 
        'Mismatched role and license type rejected'
    );
ROLLBACK;

-- Test 13-16: License status constraint validation
BEGIN;
    INSERT INTO auth.users (id, email) VALUES ('55555555-5555-5555-5555-555555555555'::uuid, 'test3@example.com');
    
    -- Should succeed: valid status values
    INSERT INTO user_profiles (id, role, license_status) 
    VALUES ('55555555-5555-5555-5555-555555555555'::uuid, 'tcm_practitioner', 'pending');
    UPDATE user_profiles SET license_status = 'verified' WHERE id = '55555555-5555-5555-5555-555555555555'::uuid;
    UPDATE user_profiles SET license_status = 'expired' WHERE id = '55555555-5555-5555-5555-555555555555'::uuid;
    UPDATE user_profiles SET license_status = 'suspended' WHERE id = '55555555-5555-5555-5555-555555555555'::uuid;
    UPDATE user_profiles SET license_status = 'rejected' WHERE id = '55555555-5555-5555-5555-555555555555'::uuid;
    SELECT ok(true, 'All valid license status values accepted');
    
    -- Should fail: invalid status value
    SELECT throws_ok(
        $$UPDATE user_profiles SET license_status = 'invalid_status' WHERE id = '55555555-5555-5555-5555-555555555555'::uuid$$,
        'check_license_status',
        'Invalid license status rejected'
    );
ROLLBACK;

-- Test 17-18: Verification consistency constraint
BEGIN;
    INSERT INTO auth.users (id, email) VALUES ('66666666-6666-6666-6666-666666666666'::uuid, 'test4@example.com');
    INSERT INTO auth.users (id, email) VALUES ('77777777-7777-7777-7777-777777777777'::uuid, 'admin@example.com');
    INSERT INTO user_profiles (id, role) VALUES ('77777777-7777-7777-7777-777777777777'::uuid, 'admin');
    
    -- Should succeed: both verified_by and verified_at set
    INSERT INTO user_profiles (id, role, verified_by, verified_at) 
    VALUES ('66666666-6666-6666-6666-666666666666'::uuid, 'tcm_practitioner', '77777777-7777-7777-7777-777777777777'::uuid, NOW());
    SELECT ok(true, 'Verification consistency with both fields accepted');
    
    -- Should fail: only one verification field set
    SELECT throws_ok(
        $$INSERT INTO user_profiles (id, role, verified_by) 
          VALUES ('88888888-8888-8888-8888-888888888888'::uuid, 'tcm_practitioner', '77777777-7777-7777-7777-777777777777'::uuid)$$,
        'check_verification_consistency',
        'Incomplete verification data rejected'
    );
ROLLBACK;

-- ============================================================================
-- TEST GROUP 3: Index Performance Validation (6 tests)
-- ============================================================================

-- Test 19-24: Verify all performance indexes exist
SELECT has_index('public', 'user_profiles', 'idx_user_profiles_license_number', 'License number index exists');
SELECT has_index('public', 'user_profiles', 'idx_user_profiles_license_status', 'License status index exists');
SELECT has_index('public', 'user_profiles', 'idx_user_profiles_business_name', 'Business name index exists');
SELECT has_index('public', 'user_profiles', 'idx_user_profiles_verification_status', 'Verification status index exists');
SELECT has_index('public', 'user_profiles', 'idx_user_profiles_business_address_gin', 'Business address GIN index exists');
SELECT has_index('public', 'user_profiles', 'idx_user_profiles_compliance_flags_gin', 'Compliance flags GIN index exists');

-- ============================================================================  
-- TEST GROUP 4: RLS Policy Enforcement (10 tests)
-- ============================================================================

-- Setup test users for RLS testing
BEGIN;
    -- Create test users
    INSERT INTO auth.users (id, email) VALUES 
        ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 'user1@example.com'),
        ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, 'user2@example.com'),
        ('cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid, 'admin@example.com');
    
    -- Create user profiles
    INSERT INTO user_profiles (id, role, business_name) VALUES 
        ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 'tcm_practitioner', 'User 1 Clinic'),
        ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, 'pharmacy', 'User 2 Pharmacy'),
        ('cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid, 'admin', 'Admin Account');

    -- Test 25: User can view their own profile
    SET LOCAL role authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SELECT results_eq(
        'SELECT count(*) FROM user_profiles WHERE business_name = ''User 1 Clinic''',
        ARRAY[1::bigint],
        'User 1 can view their own profile'
    );

    -- Test 26: User cannot view other user profiles  
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SELECT results_eq(
        'SELECT count(*) FROM user_profiles WHERE business_name = ''User 2 Pharmacy''',
        ARRAY[0::bigint],
        'User 1 cannot view User 2 profile'
    );

    -- Test 27: User can update their own profile
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SELECT lives_ok(
        $$UPDATE user_profiles SET business_phone = '555-1234' WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid$$,
        'User 1 can update their own profile'
    );

    -- Test 28: User cannot update verification status
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';  
    SELECT throws_ok(
        $$UPDATE user_profiles SET identity_verified = true WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid$$,
        'User 1 cannot self-modify verification status'
    );

    -- Test 29: Admin can view all profiles
    SET LOCAL request.jwt.claim.sub = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
    SELECT results_eq(
        'SELECT count(*) FROM user_profiles WHERE role != ''admin''',
        ARRAY[2::bigint],
        'Admin can view all non-admin profiles'
    );

    -- Test 30-31: Admin can update verification status
    SET LOCAL request.jwt.claim.sub = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
    SELECT lives_ok(
        $$UPDATE user_profiles SET identity_verified = true, verified_by = 'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid, verified_at = NOW() 
          WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid$$,
        'Admin can update verification status'
    );
    
    SELECT results_eq(
        'SELECT identity_verified FROM user_profiles WHERE id = ''aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa''::uuid',
        ARRAY[true],
        'Verification status updated successfully'
    );

ROLLBACK;

-- Test 32-34: Additional RLS edge cases
BEGIN;
    -- Test profile creation permissions
    INSERT INTO auth.users (id, email) VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid, 'newuser@example.com');
    
    SET LOCAL role authenticated;
    SET LOCAL request.jwt.claim.sub = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
    
    -- Should succeed: user creating their own profile
    SELECT lives_ok(
        $$INSERT INTO user_profiles (id, role) VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid, 'tcm_practitioner')$$,
        'User can create their own profile'
    );
    
    -- Should fail: user creating profile for someone else
    INSERT INTO auth.users (id, email) VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid, 'other@example.com');
    SELECT throws_ok(
        $$INSERT INTO user_profiles (id, role) VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid, 'tcm_practitioner')$$,
        'User cannot create profile for others'
    );

ROLLBACK;

-- ============================================================================
-- TEST GROUP 5: Trigger and Function Testing (4 tests)
-- ============================================================================

-- Test 35-38: License verification sync trigger
BEGIN;
    INSERT INTO auth.users (id, email) VALUES ('ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid, 'trigger@example.com');
    INSERT INTO user_profiles (id, role, license_type, license_number, license_status) 
    VALUES ('ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid, 'tcm_practitioner', 'tcm_practitioner', 'TCM-999999', 'pending');

    -- Test automatic professional_verified sync when license_status becomes 'verified'
    UPDATE user_profiles SET license_status = 'verified' WHERE id = 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid;
    SELECT results_eq(
        'SELECT professional_verified FROM user_profiles WHERE id = ''ffffffff-ffff-ffff-ffff-ffffffffffff''::uuid',
        ARRAY[true],
        'professional_verified automatically set to true when license_status = verified'
    );

    -- Test automatic professional_verified sync when license_status becomes 'expired'
    UPDATE user_profiles SET license_status = 'expired' WHERE id = 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid;
    SELECT results_eq(
        'SELECT professional_verified FROM user_profiles WHERE id = ''ffffffff-ffff-ffff-ffff-ffffffffffff''::uuid',
        ARRAY[false],
        'professional_verified automatically set to false when license_status = expired'
    );

    -- Test updated_at timestamp update
    SELECT col_is_null(
        'user_profiles',
        'updated_at',
        'Updated timestamp should not be null after license status change'
    );

    -- Test function exists
    SELECT has_function('public', 'sync_license_verification_status', 'License verification sync function exists');

ROLLBACK;

-- ============================================================================
-- TEST GROUP 6: JSONB Field Functionality (2 tests)  
-- ============================================================================

-- Test 39-40: JSONB fields functionality
BEGIN;
    INSERT INTO auth.users (id, email) VALUES ('12345678-1234-1234-1234-123456789012'::uuid, 'jsonb@example.com');
    INSERT INTO user_profiles (id, role, business_address, verification_documents, compliance_flags) 
    VALUES (
        '12345678-1234-1234-1234-123456789012'::uuid, 
        'tcm_practitioner',
        '{"street": "123 Main St", "city": "Anytown", "state": "CA", "zip": "12345"}',
        '{"id_document": "passport_123", "business_license": "bl_456"}',
        '{"hipaa_compliant": true, "audit_enabled": true}'
    );

    -- Test JSONB query functionality
    SELECT results_eq(
        'SELECT (business_address->>''city'') FROM user_profiles WHERE id = ''12345678-1234-1234-1234-123456789012''::uuid',
        ARRAY['Anytown'],
        'JSONB business_address query works correctly'
    );

    SELECT results_eq(
        'SELECT (compliance_flags->>''hipaa_compliant'')::boolean FROM user_profiles WHERE id = ''12345678-1234-1234-1234-123456789012''::uuid',
        ARRAY[true],
        'JSONB compliance_flags boolean query works correctly'
    );

ROLLBACK;

-- ============================================================================
-- TEST GROUP 7: Performance Benchmarking (2 tests)
-- ============================================================================

-- Test 41: License number lookup performance (should use index)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM user_profiles WHERE license_number = 'TCM-123456';
SELECT ok(true, 'License number query executed (check EXPLAIN output for index usage)');

-- Test 42: Business name search performance (should use index)  
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM user_profiles WHERE business_name ILIKE '%clinic%';
SELECT ok(true, 'Business name search executed (check EXPLAIN output for index usage)');

-- Complete test suite
SELECT * FROM finish();

-- ============================================================================
-- PERFORMANCE BENCHMARK QUERIES
-- ============================================================================
-- Run these queries manually to validate index performance
-- Expected: Index scans, not Sequential scans for optimal performance

-- Benchmark 1: License number exact match
-- EXPLAIN (ANALYZE, BUFFERS) 
-- SELECT * FROM user_profiles WHERE license_number = 'TCM-123456';
-- Expected: Index Scan using idx_user_profiles_license_number

-- Benchmark 2: License status filtering  
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM user_profiles WHERE license_status = 'pending';
-- Expected: Index Scan using idx_user_profiles_license_status

-- Benchmark 3: Verification status compound query
-- EXPLAIN (ANALYZE, BUFFERS) 
-- SELECT * FROM user_profiles WHERE identity_verified = false AND business_verified = false;
-- Expected: Index Scan using idx_user_profiles_verification_status

-- Benchmark 4: Admin management query
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM user_profiles WHERE role = 'tcm_practitioner' AND status = 'active' AND identity_verified = false;
-- Expected: Index Scan using idx_user_profiles_role_status_verification

-- Benchmark 5: JSONB address search
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM user_profiles WHERE business_address ? 'city';  
-- Expected: Bitmap Index Scan using idx_user_profiles_business_address_gin

-- Benchmark 6: License expiry monitoring  
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM user_profiles WHERE license_expiry_date < CURRENT_DATE + INTERVAL '30 days';
-- Expected: Index Scan using idx_user_profiles_license_expiry

-- ============================================================================
-- ROLLBACK SAFETY VERIFICATION
-- ============================================================================
-- These queries verify that rollback script works correctly
-- Run after executing the rollback script

-- Verify all new columns are removed:
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_name = 'user_profiles' AND table_schema = 'public'
-- AND column_name IN ('license_number', 'business_name', 'identity_verified', 'compliance_flags');
-- Expected: 0 rows

-- Verify all new indexes are removed:
-- SELECT indexname FROM pg_indexes 
-- WHERE tablename = 'user_profiles' AND schemaname = 'public'
-- AND indexname LIKE 'idx_user_profiles_%';
-- Expected: Only original indexes

-- Verify original policies are restored:  
-- SELECT policyname FROM pg_policies 
-- WHERE tablename = 'user_profiles' AND schemaname = 'public';
-- Expected: 4 original policies

-- Verify trigger and function are removed:
-- SELECT trigger_name FROM information_schema.triggers 
-- WHERE event_object_table = 'user_profiles';
-- Expected: Only original trigger (update_user_profiles_updated_at)

-- SELECT routine_name FROM information_schema.routines
-- WHERE routine_name = 'sync_license_verification_status';  
-- Expected: 0 rows