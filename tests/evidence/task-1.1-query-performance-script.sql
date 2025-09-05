-- ============================================================================
-- Query Performance Evidence Collection: User Profiles Business Fields
-- ============================================================================
-- EXPLAIN ANALYZE tests for all 9 new indexes created by migration
-- Execution Date: $(date)
-- Purpose: Capture actual execution plans, timing, and index usage patterns

\echo '=== INDEX PERFORMANCE ANALYSIS EVIDENCE ==='
\echo 'Migration: 20250104_extend_user_profiles_business_fields'
\echo 'Test Date:' $(date)
\echo 'Environment: Supabase Local Development'
\echo ''

-- Test 1: License Number Index Performance
\echo '1. LICENSE NUMBER INDEX (idx_user_profiles_license_number)'
\echo 'Query: Exact license number lookup'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM user_profiles WHERE license_number = 'TCM-123456';
\echo ''

-- Test 2: License Status Index Performance
\echo '2. LICENSE STATUS INDEX (idx_user_profiles_license_status)'
\echo 'Query: License status filtering'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM user_profiles WHERE license_status = 'pending';
\echo ''

-- Test 3: License Expiry Index Performance  
\echo '3. LICENSE EXPIRY INDEX (idx_user_profiles_license_expiry)'
\echo 'Query: License expiry monitoring'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM user_profiles WHERE license_expiry_date < CURRENT_DATE + INTERVAL '30 days';
\echo ''

-- Test 4: Business Name Index Performance
\echo '4. BUSINESS NAME INDEX (idx_user_profiles_business_name)'
\echo 'Query: Business name text search'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM user_profiles WHERE business_name ILIKE '%clinic%';
\echo ''

-- Test 5: Verification Status Compound Index Performance
\echo '5. VERIFICATION STATUS INDEX (idx_user_profiles_verification_status)'  
\echo 'Query: Multi-field verification status query'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM user_profiles WHERE identity_verified = false AND business_verified = false;
\echo ''

-- Test 6: Admin Management Compound Index Performance
\echo '6. VERIFICATION ADMIN INDEX (idx_user_profiles_verification_admin)'
\echo 'Query: Admin verification management'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM user_profiles WHERE verified_by IS NOT NULL AND verified_at IS NOT NULL;
\echo ''

-- Test 7: Role-Status-Verification Compound Index Performance
\echo '7. ROLE STATUS VERIFICATION INDEX (idx_user_profiles_role_status_verification)'
\echo 'Query: Complex admin dashboard query' 
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM user_profiles WHERE role = 'tcm_practitioner' AND status = 'active' AND identity_verified = false;
\echo ''

-- Test 8: Business Address JSONB GIN Index Performance
\echo '8. BUSINESS ADDRESS GIN INDEX (idx_user_profiles_business_address_gin)'
\echo 'Query: JSONB address key existence check'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM user_profiles WHERE business_address ? 'city';
\echo ''

-- Test 9: Compliance Flags JSONB GIN Index Performance  
\echo '9. COMPLIANCE FLAGS GIN INDEX (idx_user_profiles_compliance_flags_gin)'
\echo 'Query: JSONB compliance flags query'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM user_profiles WHERE compliance_flags ? 'hipaa_compliant';
\echo ''

-- Performance Summary
\echo '=== PERFORMANCE ANALYSIS SUMMARY ==='
SELECT 
    schemaname,
    tablename, 
    indexname,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE tablename = 'user_profiles'
AND indexname LIKE 'idx_user_profiles_%'
ORDER BY indexname;
\echo ''

\echo '=== INDEX SIZE ANALYSIS ==='
SELECT 
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as size
FROM pg_indexes 
WHERE tablename = 'user_profiles' 
AND indexname LIKE 'idx_user_profiles_%'
ORDER BY pg_relation_size(indexname::regclass) DESC;

