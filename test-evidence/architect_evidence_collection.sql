-- ============================================================================
-- ARCHITECT EVIDENCE COLLECTION - M1.3 IRG Final Validation
-- ============================================================================
-- Comprehensive evidence collection with minimal seed data and behavioral tests
-- Addresses architect feedback on evidence completeness and contradictions

-- Clean start - ensure fresh environment
DELETE FROM user_profiles WHERE id LIKE '11111111-%' OR id LIKE '22222222-%' OR id LIKE '33333333-%' OR id LIKE '44444444-%' OR id LIKE '99999999-%';

-- Step 1: Create minimal seed data with proper FK constraints
INSERT INTO auth.users (id, email, phone, created_at, updated_at, email_confirmed_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm1@test.com', '+1234567890', NOW(), NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'tcm2@test.com', '+1234567891', NOW(), NOW(), NOW()),
    ('33333333-3333-3333-3333-333333333333', 'pharmacy1@test.com', '+1234567892', NOW(), NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy2@test.com', '+1234567893', NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Create pharmacies for FK constraint
INSERT INTO pharmacies (id, name, contact_info, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'City Community Pharmacy', '{"type": "retail"}', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Metro Health Dispensary', '{"type": "hospital"}', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert TCM practitioners (only TCM-specific fields)
INSERT INTO user_profiles (
    id, role, status, business_info, 
    tcm_specialty, tcm_practice_years, tcm_certification_level, 
    created_at, updated_at
) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm_practitioner', 'active', 
     '{"business_name": "East Wellness Center"}', 'acupuncture', 5, 'licensed', NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'tcm_practitioner', 'active', 
     '{"business_name": "West Herbal Clinic"}', 'herbal_medicine', 3, 'licensed', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert pharmacies (only pharmacy-specific fields)  
INSERT INTO user_profiles (
    id, role, status, business_info, 
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit, pharmacy_id,
    created_at, updated_at
) VALUES 
    ('33333333-3333-3333-3333-333333333333', 'pharmacy', 'active', 
     '{"business_name": "City Community Pharmacy"}', 'retail_pharmacy', 'basic_dispensing', 1, false,
     '33333333-3333-3333-3333-333333333333', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy', 'active', 
     '{"business_name": "Metro Health Dispensary"}', 'hospital_pharmacy', 'controlled_substances', 3, true,
     '44444444-4444-4444-4444-444444444444', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Set public profiles for public directory testing
UPDATE user_profiles SET is_public_profile = true 
WHERE id IN ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- ============================================================================
-- EVIDENCE COLLECTION 1: POLICY ANALYSIS (BASELINE vs EXTENSION)
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
    tablename
FROM pg_policies 
WHERE tablename = 'user_profiles' 
AND schemaname = 'public'
AND policyname LIKE '%business_relationship%'
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

-- USE CASE 1: Pharmacy→TCM Positive Case (Should return COUNT > 0)
\echo '=== USE CASE 1: Pharmacy→TCM Positive Case ==='
\echo 'Setting JWT context for pharmacy user:'
SELECT set_config('request.jwt.claims', '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true) as jwt_set;
\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;
\echo 'Query result:'
SELECT COUNT(*) as count_positive_case_1 FROM v_profiles_tcm_context;
\echo 'Sample row (limit 1):'
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 1;

-- USE CASE 2: Non-existent User→TCM Negative Case (Should return COUNT = 0) 
\echo '=== USE CASE 2: Non-existent User→TCM Negative Case ==='
\echo 'Setting JWT context for non-existent user:'
SELECT set_config('request.jwt.claims', '{"sub": "88888888-8888-8888-8888-888888888888", "role": "authenticated"}', true) as jwt_set;
\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;
\echo 'Query result:'
SELECT COUNT(*) as count_negative_case_1 FROM v_profiles_tcm_context;
\echo 'Sample row (should be empty):'
SELECT id, role, business_name, tcm_specialty FROM v_profiles_tcm_context LIMIT 1;

-- USE CASE 3: TCM→Pharmacy Positive Case (Should return COUNT > 0)
\echo '=== USE CASE 3: TCM→Pharmacy Positive Case ==='  
\echo 'Setting JWT context for TCM user:'
SELECT set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true) as jwt_set;
\echo 'Current JWT context:'
SELECT current_setting('request.jwt.claims', true) as current_jwt_context;
\echo 'Query result:'
SELECT COUNT(*) as count_positive_case_2 FROM v_profiles_pharmacy_context;
\echo 'Sample row (limit 1):'
SELECT id, role, business_name, pharmacy_type FROM v_profiles_pharmacy_context LIMIT 1;

-- USE CASE 4: Non-existent User→Pharmacy Negative Case (Should return COUNT = 0)
\echo '=== USE CASE 4: Non-existent User→Pharmacy Negative Case ==='
\echo 'Setting JWT context for non-existent user:'
SELECT set_config('request.jwt.claims', '{"sub": "77777777-7777-7777-7777-777777777777", "role": "authenticated"}', true) as jwt_set;
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
\echo 'Public directory access test:'
SELECT set_config('request.jwt.claims', '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true) as jwt_set;
SELECT COUNT(*) as public_directory_count FROM v_profiles_public;
SELECT id, role, business_name FROM v_profiles_public LIMIT 2;

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

\echo '=== ARCHITECT EVIDENCE COLLECTION COMPLETE ==='