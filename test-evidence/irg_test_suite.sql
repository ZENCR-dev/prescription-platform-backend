-- ============================================================================
-- IRG Test Suite: M1.3B Role-Specific Permission Extensions
-- ============================================================================
-- Comprehensive validation of RLS architecture post-migration

-- Step 1: Create minimal test data
-- Skip auth.users insert as it triggers handle_new_user() which creates user_profiles with constraints

-- Create pharmacies for FK constraint (use correct column name 'name' not 'business_name')
INSERT INTO pharmacies (id, name, contact_info, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'City Community Pharmacy', '{"type": "retail"}', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Metro Health Dispensary', '{"type": "hospital"}', NOW(), NOW());

-- Insert test user profiles directly (respecting role-specific field constraints)
INSERT INTO user_profiles (id, role, status, business_info, tcm_specialty, created_at, updated_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm_practitioner', 'active', '{"business_name": "East Wellness Center"}', 'acupuncture', NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'tcm_practitioner', 'active', '{"business_name": "West Herbal Clinic"}', 'herbal_medicine', NOW(), NOW());

INSERT INTO user_profiles (id, role, status, business_info, pharmacy_type, pharmacy_id, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'pharmacy', 'active', '{"business_name": "City Community Pharmacy"}', 'retail_pharmacy', '33333333-3333-3333-3333-333333333333', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy', 'active', '{"business_name": "Metro Health Dispensary"}', 'hospital_pharmacy', '44444444-4444-4444-4444-444444444444', NOW(), NOW());

-- Additional test user without relationships
INSERT INTO user_profiles (id, role, status, business_info, created_at, updated_at)
VALUES 
    ('99999999-9999-9999-9999-999999999999', 'tcm_practitioner', 'active', '{"business_name": "Isolated Test Clinic"}', NOW(), NOW());

-- Set public profiles for public directory testing
UPDATE user_profiles SET is_public_profile = true WHERE id IN ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- Note: Business relationship validation now uses basic business_info check
-- The helper functions check for active status and business_info presence
-- No additional relationship tables needed for basic testing

-- ============================================================================
-- IRG Test 1: View Definitions
-- ============================================================================

\echo '=== VIEWDEF tcm ==='
SELECT pg_get_viewdef('public.v_profiles_tcm_context', true);

\echo '=== VIEWDEF pharmacy ==='
SELECT pg_get_viewdef('public.v_profiles_pharmacy_context', true);

\echo '=== VIEWDEF public ==='
SELECT pg_get_viewdef('public.v_profiles_public', true);

-- ============================================================================
-- IRG Test 2: SECURITY BARRIER
-- ============================================================================

SELECT viewname, reloptions 
FROM pg_views v
JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
WHERE v.schemaname = 'public' AND v.viewname LIKE 'v_profiles_%'
ORDER BY v.viewname;

-- ============================================================================
-- IRG Test 3: Base Table RLS Policies
-- ============================================================================

SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'user_profiles' 
AND schemaname = 'public'
ORDER BY policyname;

-- Verify no policies on views
SELECT COUNT(*) as policies_on_views
FROM pg_policies 
WHERE tablename LIKE 'v_profiles_%';

-- ============================================================================
-- IRG Test 4: Helper Function Security
-- ============================================================================

SELECT proname, prosecdef, provolatile, proconfig
FROM pg_proc 
WHERE proname IN ('has_prescription_business_relationship', 'has_referral_business_relationship', 'get_current_user_id')
AND pronamespace = 'private'::regnamespace
ORDER BY proname;

-- ============================================================================
-- IRG Test 5: Behavioral Tests
-- ============================================================================

-- Test 1: Pharmacy→TCM Positive Case (pharmacy user viewing TCM profiles)
-- User 33333333... (pharmacy) should see TCM practitioners because:
-- 1. Both have business_info, 2. Both active, 3. Roles are complementary
\\echo '=== TEST 1: Pharmacy→TCM Positive Case ==='
SELECT set_config('request.jwt.claims', '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);
SELECT COUNT(*) as count_positive_1 FROM v_profiles_tcm_context;
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 3;

-- Test 2: Non-existent User→TCM Negative Case (no business relationship possible)
\\echo '=== TEST 2: Non-existent User→TCM Negative Case ==='
SELECT set_config('request.jwt.claims', '{"sub": "88888888-8888-8888-8888-888888888888", "role": "authenticated"}', true);
SELECT COUNT(*) as count_negative_1 FROM v_profiles_tcm_context;
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 1;

-- Test 3: TCM→Pharmacy Positive Case (TCM user viewing pharmacy profiles)
-- User 11111111... (tcm_practitioner) should see pharmacies because:
-- 1. Both have business_info, 2. Both active, 3. Roles are complementary
\\echo '=== TEST 3: TCM→Pharmacy Positive Case ==='
SELECT set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
SELECT COUNT(*) as count_positive_2 FROM v_profiles_pharmacy_context;
SELECT id, role, business_name, pharmacy_type FROM v_profiles_pharmacy_context LIMIT 3;

-- Test 4: Non-existent User→Pharmacy Negative Case (no business relationship possible)
\\echo '=== TEST 4: Non-existent User→Pharmacy Negative Case ==='
SELECT set_config('request.jwt.claims', '{"sub": "77777777-7777-7777-7777-777777777777", "role": "authenticated"}', true);
SELECT COUNT(*) as count_negative_2 FROM v_profiles_pharmacy_context;
SELECT id, role, business_name, pharmacy_type FROM v_profiles_pharmacy_context LIMIT 1;

-- Test 5: Public Directory Access
SELECT set_config('request.jwt.claims', '{"sub": "99999999-9999-9999-9999-999999999999", "role": "authenticated"}', true);
SELECT COUNT(*) as count_public FROM v_profiles_public;
SELECT id, role, business_name FROM v_profiles_public LIMIT 2;

-- ============================================================================
-- IRG Test 6: Zero-PII Compliance
-- ============================================================================

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