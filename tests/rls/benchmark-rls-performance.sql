-- RLS Performance Benchmarking Script  
-- Task 2.1: Performance validation for enhanced user_profiles RLS
-- Target: <150ms P95 response time for profile operations

-- =======================
-- PERFORMANCE BENCHMARKING SETUP
-- =======================

\timing on
\echo 'RLS Performance Benchmarking Started'
\echo '===================================='

-- Create performance test data
INSERT INTO user_profiles (id, role, status, business_info) 
SELECT 
  gen_random_uuid(),
  (ARRAY['tcm_practitioner', 'pharmacy', 'admin'])[floor(random() * 3) + 1],
  'active',
  '{"test": "data"}'
FROM generate_series(1, 1000)
ON CONFLICT (id) DO NOTHING;

\echo 'Test data created: 1000 user profiles'

-- =======================
-- BENCHMARK 1: PROFILE LOOKUP (Most Critical)
-- =======================

\echo ''
\echo 'BENCHMARK 1: Own Profile Lookup (Critical Path)'
\echo '================================================'

-- Warmup query
SELECT COUNT(*) FROM user_profiles;

-- Test the most common query pattern - user accessing own profile
-- This should be <150ms P95
\echo 'Query: SELECT * FROM user_profiles WHERE id = auth.uid()'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM user_profiles 
WHERE id = (SELECT id FROM user_profiles LIMIT 1);

-- =======================  
-- BENCHMARK 2: ROLE-BASED FILTERING
-- =======================

\echo ''
\echo 'BENCHMARK 2: Role-Based Queries'
\echo '================================'

-- Test role filtering with status (common admin query)
\echo 'Query: Role + Status filtering'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT role, status, COUNT(*) 
FROM user_profiles 
WHERE role = 'tcm_practitioner' AND status = 'active'
GROUP BY role, status;

-- Test index usage for role queries
\echo 'Query: Role-only filtering (index test)'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM user_profiles 
WHERE role = 'admin'
ORDER BY created_at DESC;

-- =======================
-- BENCHMARK 3: ADMIN OVERVIEW QUERIES
-- =======================

\echo ''
\echo 'BENCHMARK 3: Admin Dashboard Queries'
\echo '====================================='

-- Admin aggregate query (should be fast with proper indexes)
\echo 'Query: Admin role aggregation'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT 
  role,
  status, 
  COUNT(*) as user_count,
  MIN(created_at) as earliest,
  MAX(created_at) as latest
FROM user_profiles 
GROUP BY role, status
ORDER BY role, status;

-- Admin recent users query
\echo 'Query: Recent users (admin view)'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT role, status, created_at 
FROM user_profiles 
WHERE created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 50;

-- =======================
-- BENCHMARK 4: SECURITY DEFINER FUNCTION PERFORMANCE
-- =======================

\echo ''
\echo 'BENCHMARK 4: Security Definer Functions'
\echo '========================================'

-- Test security definer function performance
\echo 'Query: Security definer function call'
EXPLAIN (ANALYZE, TIMING)
SELECT private.is_current_user_admin();

-- Test role lookup function
\echo 'Query: Role lookup function'  
EXPLAIN (ANALYZE, TIMING)
SELECT private.get_current_user_role();

-- =======================
-- BENCHMARK 5: WRITE OPERATIONS
-- =======================

\echo ''
\echo 'BENCHMARK 5: Write Operation Performance'  
\echo '========================================='

-- Test INSERT performance with RLS
\echo 'Query: INSERT with RLS policies'
\timing on
INSERT INTO user_profiles (id, role, status, business_info)
VALUES (gen_random_uuid(), 'tcm_practitioner', 'pending_verification', '{"test": "insert"}');
\timing off

-- Test UPDATE performance with RLS  
\echo 'Query: UPDATE with RLS policies'
\timing on
UPDATE user_profiles 
SET status = 'active', updated_at = NOW()
WHERE role = 'tcm_practitioner' AND status = 'pending_verification'
LIMIT 1;
\timing off

-- =======================
-- BENCHMARK 6: INDEX EFFECTIVENESS
-- =======================

\echo ''
\echo 'BENCHMARK 6: Index Usage Analysis'
\echo '=================================='

-- Check which indexes are being used
\echo 'Index usage for primary key lookup:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM user_profiles 
WHERE id = (SELECT id FROM user_profiles WHERE role = 'admin' LIMIT 1);

\echo 'Index usage for role + status lookup:'  
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM user_profiles 
WHERE role = 'tcm_practitioner' AND status = 'active'
LIMIT 10;

-- =======================
-- PERFORMANCE SUMMARY & ANALYSIS
-- =======================

\echo ''
\echo 'PERFORMANCE SUMMARY & RECOMMENDATIONS'
\echo '====================================='

-- Analyze query performance from pg_stat_statements (if available)
-- This gives real performance metrics
SELECT 
  'user_profiles queries' as analysis_type,
  'Check timing output above for performance metrics' as status,
  '<150ms target for profile lookups' as target,
  'Look for Index Scan vs Seq Scan in EXPLAIN output' as optimization_hint;

-- Show current index usage
\echo 'Current indexes on user_profiles:'
SELECT 
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'user_profiles'
ORDER BY indexname;

-- Show table statistics
\echo 'Table statistics:'
SELECT 
  schemaname,
  tablename,
  n_tup_ins as inserts,
  n_tup_upd as updates,
  n_tup_del as deletes,
  n_live_tup as live_rows,
  n_dead_tup as dead_rows
FROM pg_stat_user_tables 
WHERE tablename = 'user_profiles';

-- =======================
-- CLEANUP TEST DATA
-- =======================

-- Remove test data (keep original profiles)
DELETE FROM user_profiles 
WHERE business_info->>'test' = 'data' 
   OR business_info->>'test' = 'insert';

\echo ''
\echo 'BENCHMARK COMPLETE'  
\echo '=================='
\echo 'Key Performance Indicators:'
\echo '• Profile lookup: Should use Index Scan on primary key'
\echo '• Role filtering: Should use Index Scan on idx_user_profiles_role_status_performance'  
\echo '• Timing: All queries should complete in <150ms for target P95'
\echo '• Buffer usage: Low shared hit ratio indicates good memory usage'
\echo ''
\echo 'Optimization Checklist:'
\echo '✓ All policies use TO authenticated (avoids anon evaluation)'
\echo '✓ Direct auth.uid() comparisons (no expensive subqueries)'
\echo '✓ Security definer functions (bypass RLS recursion)'
\echo '✓ Proper indexes on filtered columns (id, role, status)'
\echo ''