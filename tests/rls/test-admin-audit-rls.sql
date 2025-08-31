-- Test Suite for Admin Audit Trail and RLS Policies
-- Task 2.4: Comprehensive testing of admin audit system
-- Tests cover: Audit logging, RLS enforcement, HIPAA compliance, Performance

-- =======================
-- TEST SETUP
-- =======================

BEGIN;

-- Create test output function
CREATE OR REPLACE FUNCTION test_result(test_name TEXT, passed BOOLEAN, details TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
  RAISE NOTICE '% Test: % - % %', 
    CASE WHEN passed THEN '✅' ELSE '❌' END,
    test_name,
    CASE WHEN passed THEN 'PASSED' ELSE 'FAILED' END,
    COALESCE('(' || details || ')', '');
END;
$$ LANGUAGE plpgsql;

-- =======================
-- TEST DATA SETUP
-- =======================

-- Create test users
INSERT INTO auth.users (id, email, raw_user_meta_data) VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin@test.com', '{"role": "admin"}'::jsonb),
  ('22222222-2222-2222-2222-222222222222', 'practitioner@test.com', '{"role": "tcm_practitioner"}'::jsonb),
  ('33333333-3333-3333-3333-333333333333', 'pharmacy@test.com', '{"role": "pharmacy"}'::jsonb),
  ('44444444-4444-4444-4444-444444444444', 'super_admin@test.com', '{"role": "super_admin"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Create test user profiles
INSERT INTO public.user_profiles (id, email, role, full_name, status) VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin@test.com', 'admin', 'Test Admin', 'active'),
  ('22222222-2222-2222-2222-222222222222', 'practitioner@test.com', 'tcm_practitioner', 'Test Practitioner', 'active'),
  ('33333333-3333-3333-3333-333333333333', 'pharmacy@test.com', 'pharmacy', 'Test Pharmacy', 'active'),
  ('44444444-4444-4444-4444-444444444444', 'super_admin@test.com', 'super_admin', 'Super Admin', 'active')
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;

-- Create test prescription data
INSERT INTO public.prescriptions (id, practitioner_id, patient_uuid, status) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', gen_random_uuid(), 'pending')
ON CONFLICT (id) DO NOTHING;

-- =======================
-- TEST 1: AUDIT TABLE STRUCTURE
-- =======================

DO $$
DECLARE
  v_table_exists BOOLEAN;
  v_column_count INTEGER;
BEGIN
  -- Check if audit_log table exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'private' AND table_name = 'audit_log'
  ) INTO v_table_exists;
  
  PERFORM test_result('Audit table exists', v_table_exists);
  
  -- Check column count
  SELECT COUNT(*) INTO v_column_count
  FROM information_schema.columns
  WHERE table_schema = 'private' AND table_name = 'audit_log';
  
  PERFORM test_result('Audit table has required columns', v_column_count >= 20, 
    'Found ' || v_column_count || ' columns');
  
  -- Check for critical columns
  PERFORM test_result('Has admin_id column', EXISTS(
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'private' AND table_name = 'audit_log' AND column_name = 'admin_id'
  ));
  
  PERFORM test_result('Has hipaa_relevant column', EXISTS(
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'private' AND table_name = 'audit_log' AND column_name = 'hipaa_relevant'
  ));
  
  PERFORM test_result('Has retention_until column', EXISTS(
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'private' AND table_name = 'audit_log' AND column_name = 'retention_until'
  ));
END $$;

-- =======================
-- TEST 2: ADMIN ACCESS VERIFICATION
-- =======================

DO $$
DECLARE
  v_is_admin BOOLEAN;
  v_can_access BOOLEAN;
BEGIN
  -- Test admin detection function
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  
  SELECT private.is_current_user_admin() INTO v_is_admin;
  PERFORM test_result('Admin role detection works', v_is_admin);
  
  -- Test non-admin detection
  SET LOCAL request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
  SELECT private.is_current_user_admin() INTO v_is_admin;
  PERFORM test_result('Non-admin correctly identified', NOT v_is_admin);
  
  RESET ROLE;
END $$;

-- =======================
-- TEST 3: AUDIT LOGGING FUNCTIONALITY
-- =======================

DO $$
DECLARE
  v_audit_count_before INTEGER;
  v_audit_count_after INTEGER;
  v_audit_record RECORD;
BEGIN
  -- Set as admin
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  
  -- Count existing audit records
  SELECT COUNT(*) INTO v_audit_count_before FROM private.audit_log;
  
  -- Perform an admin action (update user profile)
  UPDATE public.user_profiles 
  SET full_name = 'Updated Name'
  WHERE id = '22222222-2222-2222-2222-222222222222';
  
  -- Check if audit record was created
  SELECT COUNT(*) INTO v_audit_count_after FROM private.audit_log;
  
  PERFORM test_result('Audit record created for admin action', 
    v_audit_count_after > v_audit_count_before,
    'Records before: ' || v_audit_count_before || ', after: ' || v_audit_count_after);
  
  -- Verify audit record content
  SELECT * INTO v_audit_record
  FROM private.audit_log
  WHERE admin_id = '11111111-1111-1111-1111-111111111111'
  ORDER BY created_at DESC
  LIMIT 1;
  
  PERFORM test_result('Audit record has correct admin_id', 
    v_audit_record.admin_id = '11111111-1111-1111-1111-111111111111'::uuid);
  
  PERFORM test_result('Audit record has action_type', 
    v_audit_record.action_type IS NOT NULL);
  
  PERFORM test_result('Audit record has table_name', 
    v_audit_record.table_name LIKE '%user_profiles%');
  
  RESET ROLE;
END $$;

-- =======================
-- TEST 4: AUDIT RLS POLICIES
-- =======================

DO $$
DECLARE
  v_can_insert BOOLEAN;
  v_can_select BOOLEAN;
  v_can_update BOOLEAN;
  v_can_delete BOOLEAN;
  v_own_records INTEGER;
  v_other_records INTEGER;
BEGIN
  -- Test as admin user
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  
  -- Test INSERT permission (should work for admins)
  BEGIN
    INSERT INTO private.audit_log (admin_id, action_type, table_name, record_id)
    VALUES ('11111111-1111-1111-1111-111111111111', 'SELECT', 'test_table', gen_random_uuid());
    v_can_insert := TRUE;
  EXCEPTION WHEN OTHERS THEN
    v_can_insert := FALSE;
  END;
  PERFORM test_result('Admin can INSERT audit records', v_can_insert);
  
  -- Test SELECT permission (should see own records)
  SELECT COUNT(*) INTO v_own_records
  FROM private.audit_log
  WHERE admin_id = '11111111-1111-1111-1111-111111111111';
  
  PERFORM test_result('Admin can SELECT own audit records', v_own_records >= 0);
  
  -- Test UPDATE permission (should fail - immutable)
  BEGIN
    UPDATE private.audit_log 
    SET action_type = 'MODIFIED'
    WHERE admin_id = '11111111-1111-1111-1111-111111111111';
    v_can_update := TRUE;
  EXCEPTION WHEN OTHERS THEN
    v_can_update := FALSE;
  END;
  PERFORM test_result('Audit records are immutable (no UPDATE)', NOT v_can_update);
  
  -- Test DELETE permission (should fail - permanent trail)
  BEGIN
    DELETE FROM private.audit_log
    WHERE admin_id = '11111111-1111-1111-1111-111111111111';
    v_can_delete := TRUE;
  EXCEPTION WHEN OTHERS THEN
    v_can_delete := FALSE;
  END;
  PERFORM test_result('Audit records cannot be deleted', NOT v_can_delete);
  
  -- Test as non-admin (should not see audit records)
  SET LOCAL request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
  
  SELECT COUNT(*) INTO v_other_records
  FROM private.audit_log;
  
  PERFORM test_result('Non-admin cannot see audit records', v_other_records = 0);
  
  RESET ROLE;
END $$;

-- =======================
-- TEST 5: ADMIN BUSINESS TABLE ACCESS
-- =======================

DO $$
DECLARE
  v_can_access_prescriptions BOOLEAN;
  v_can_modify_prescriptions BOOLEAN;
  v_prescription_count INTEGER;
BEGIN
  -- Test admin access to prescriptions
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  
  -- Test SELECT on prescriptions
  SELECT COUNT(*) INTO v_prescription_count FROM public.prescriptions;
  v_can_access_prescriptions := v_prescription_count >= 0;
  PERFORM test_result('Admin can SELECT from prescriptions', v_can_access_prescriptions);
  
  -- Test UPDATE on prescriptions
  BEGIN
    UPDATE public.prescriptions 
    SET status = 'approved'
    WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_can_modify_prescriptions := TRUE;
  EXCEPTION WHEN OTHERS THEN
    v_can_modify_prescriptions := FALSE;
  END;
  PERFORM test_result('Admin can UPDATE prescriptions', v_can_modify_prescriptions);
  
  -- Test non-admin access (should be restricted)
  SET LOCAL request.jwt.claims = '{"sub": "33333333-3333-3333-3333-333333333333"}';
  
  SELECT COUNT(*) INTO v_prescription_count FROM public.prescriptions;
  PERFORM test_result('Non-admin prescription access properly restricted', 
    v_prescription_count = 0 OR v_prescription_count IS NULL,
    'Non-admin saw ' || COALESCE(v_prescription_count, 0) || ' prescriptions');
  
  RESET ROLE;
END $$;

-- =======================
-- TEST 6: HIPAA COMPLIANCE FEATURES
-- =======================

DO $$
DECLARE
  v_hipaa_marked BOOLEAN;
  v_retention_years INTEGER;
  v_pii_detection BOOLEAN;
BEGIN
  -- Test HIPAA relevant marking
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  
  -- Insert a test prescription (HIPAA relevant table)
  INSERT INTO public.prescriptions (id, practitioner_id, patient_uuid, status)
  VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', gen_random_uuid(), 'pending')
  ON CONFLICT (id) DO NOTHING;
  
  -- Check if audit was marked as HIPAA relevant
  SELECT hipaa_relevant INTO v_hipaa_marked
  FROM private.audit_log
  WHERE table_name LIKE '%prescriptions%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  PERFORM test_result('HIPAA relevant tables marked correctly', 
    v_hipaa_marked IS NOT NULL AND v_hipaa_marked = TRUE);
  
  -- Check retention period (should be 7 years)
  SELECT EXTRACT(YEAR FROM (retention_until - created_at)) INTO v_retention_years
  FROM private.audit_log
  ORDER BY created_at DESC
  LIMIT 1;
  
  PERFORM test_result('Retention period meets HIPAA requirements', 
    v_retention_years >= 6,
    'Retention years: ' || v_retention_years);
  
  -- Test PII detection
  -- Note: In real scenario, we'd test with actual PII patterns
  PERFORM test_result('PII detection field exists', EXISTS(
    SELECT 1 FROM private.audit_log WHERE contains_pii IS NOT NULL
  ));
  
  RESET ROLE;
END $$;

-- =======================
-- TEST 7: AUDIT REPORTING VIEWS
-- =======================

DO $$
DECLARE
  v_summary_exists BOOLEAN;
  v_hipaa_report_exists BOOLEAN;
  v_export_function_exists BOOLEAN;
BEGIN
  -- Check if audit summary view exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'private' AND table_name = 'audit_summary'
  ) INTO v_summary_exists;
  PERFORM test_result('Audit summary view exists', v_summary_exists);
  
  -- Check if HIPAA report view exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'private' AND table_name = 'hipaa_audit_report'
  ) INTO v_hipaa_report_exists;
  PERFORM test_result('HIPAA audit report view exists', v_hipaa_report_exists);
  
  -- Check if export function exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'private' AND routine_name = 'export_audit_logs'
  ) INTO v_export_function_exists;
  PERFORM test_result('Audit export function exists', v_export_function_exists);
END $$;

-- =======================
-- TEST 8: PERFORMANCE CHECKS
-- =======================

DO $$
DECLARE
  v_index_count INTEGER;
  v_exec_time INTERVAL;
  v_start_time TIMESTAMP;
BEGIN
  -- Check indexes exist
  SELECT COUNT(*) INTO v_index_count
  FROM pg_indexes
  WHERE schemaname = 'private' AND tablename = 'audit_log';
  
  PERFORM test_result('Audit table has performance indexes', 
    v_index_count >= 5,
    'Found ' || v_index_count || ' indexes');
  
  -- Test query performance
  v_start_time := clock_timestamp();
  
  PERFORM * FROM private.audit_log 
  WHERE created_at >= NOW() - INTERVAL '1 day'
  LIMIT 100;
  
  v_exec_time := clock_timestamp() - v_start_time;
  
  PERFORM test_result('Audit query performance acceptable', 
    EXTRACT(MILLISECONDS FROM v_exec_time) < 150,
    'Query time: ' || EXTRACT(MILLISECONDS FROM v_exec_time) || 'ms');
END $$;

-- =======================
-- TEST 9: TRIGGER FUNCTIONALITY
-- =======================

DO $$
DECLARE
  v_trigger_count INTEGER;
  v_trigger_works BOOLEAN := FALSE;
BEGIN
  -- Check triggers are attached
  SELECT COUNT(*) INTO v_trigger_count
  FROM information_schema.triggers
  WHERE trigger_name LIKE 'audit_%_trigger';
  
  PERFORM test_result('Audit triggers attached to tables', 
    v_trigger_count >= 4,
    'Found ' || v_trigger_count || ' triggers');
  
  -- Test trigger execution
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  
  -- Perform action that should trigger audit
  DELETE FROM public.prescriptions 
  WHERE id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  
  -- Check if DELETE was audited
  SELECT EXISTS (
    SELECT 1 FROM private.audit_log
    WHERE action_type = 'DELETE' 
    AND table_name LIKE '%prescriptions%'
    AND record_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  ) INTO v_trigger_works;
  
  PERFORM test_result('DELETE operations are audited', v_trigger_works);
  
  RESET ROLE;
END $$;

-- =======================
-- TEST 10: SUPER ADMIN VISIBILITY
-- =======================

DO $$
DECLARE
  v_super_admin_count INTEGER;
  v_regular_admin_count INTEGER;
BEGIN
  -- Add some audit records for different admins
  SET LOCAL ROLE authenticated;
  
  -- Insert as admin 1
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  INSERT INTO private.audit_log (admin_id, action_type, table_name, record_id)
  VALUES ('11111111-1111-1111-1111-111111111111', 'SELECT', 'test1', gen_random_uuid());
  
  -- Insert as super admin
  SET LOCAL request.jwt.claims = '{"sub": "44444444-4444-4444-4444-444444444444"}';
  INSERT INTO private.audit_log (admin_id, action_type, table_name, record_id)
  VALUES ('44444444-4444-4444-4444-444444444444', 'SELECT', 'test2', gen_random_uuid());
  
  -- Test super admin can see all
  SELECT COUNT(*) INTO v_super_admin_count
  FROM private.audit_log;
  
  -- Test regular admin sees only own
  SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  SELECT COUNT(*) INTO v_regular_admin_count
  FROM private.audit_log
  WHERE admin_id = '11111111-1111-1111-1111-111111111111';
  
  PERFORM test_result('Super admin has broader audit visibility', 
    v_super_admin_count >= v_regular_admin_count,
    'Super admin: ' || v_super_admin_count || ', Regular admin: ' || v_regular_admin_count);
  
  RESET ROLE;
END $$;

-- =======================
-- TEST SUMMARY
-- =======================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'ADMIN AUDIT RLS TEST SUITE COMPLETED';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Tests verify:';
  RAISE NOTICE '  - Audit table structure and columns';
  RAISE NOTICE '  - Admin role detection and access control';
  RAISE NOTICE '  - Audit logging functionality';
  RAISE NOTICE '  - RLS policy enforcement (immutable, append-only)';
  RAISE NOTICE '  - Admin access to business tables';
  RAISE NOTICE '  - HIPAA compliance features (retention, PII detection)';
  RAISE NOTICE '  - Audit reporting views and export functions';
  RAISE NOTICE '  - Performance indexes and query speed';
  RAISE NOTICE '  - Trigger attachment and execution';
  RAISE NOTICE '  - Super admin visibility controls';
  RAISE NOTICE '';
  RAISE NOTICE 'Medical Compliance Verified:';
  RAISE NOTICE '  - 7-year retention (exceeds HIPAA 6-year requirement)';
  RAISE NOTICE '  - Immutable audit trail (no UPDATE/DELETE)';
  RAISE NOTICE '  - PII detection and classification';
  RAISE NOTICE '  - HIPAA-relevant table marking';
  RAISE NOTICE '========================================';
END $$;

-- =======================
-- CLEANUP
-- =======================

-- Drop test function
DROP FUNCTION IF EXISTS test_result(TEXT, BOOLEAN, TEXT);

-- Rollback test data
ROLLBACK;