-- ============================================================================
-- COMPLETE SEED DATA SOLUTION
-- ============================================================================
-- Creates auth.users first, then profiles with constraint bypass

\echo '=== COMPLETE SEED DATA SOLUTION ==='

-- Step 1: Clean up existing data
DELETE FROM user_profiles WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';
DELETE FROM auth.users WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';

-- Step 2: Create pharmacies for FK constraints  
INSERT INTO pharmacies (id, name, contact_info, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'City Community Pharmacy', '{"type": "retail"}', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Metro Health Dispensary', '{"type": "hospital"}', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 3: Create auth.users records first (minimal data to avoid trigger issues)
INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm1@test.com', NOW(), NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'tcm2@test.com', NOW(), NOW(), NOW()),
    ('33333333-3333-3333-3333-333333333333', 'pharmacy1@test.com', NOW(), NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy2@test.com', NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 4: Check if trigger created any profiles and remove them
DELETE FROM user_profiles WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444'
);

-- Step 5: Temporarily drop constraints and disable RLS
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_pharmacy_fields_isolation;
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_tcm_fields_isolation;
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Step 6: Insert profiles directly with proper data
INSERT INTO user_profiles (
    id, role, status, business_info, 
    tcm_specialty, tcm_practice_years, tcm_certification_level,
    created_at, updated_at, is_public_profile
) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm_practitioner', 'active', 
     '{"business_name": "East Wellness Center"}', 
     'acupuncture', 5, 'licensed',
     NOW(), NOW(), false),
    ('22222222-2222-2222-2222-222222222222', 'tcm_practitioner', 'active', 
     '{"business_name": "West Herbal Clinic"}', 
     'herbal_medicine', 3, 'licensed',
     NOW(), NOW(), true);

INSERT INTO user_profiles (
    id, role, status, business_info,
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit, pharmacy_id,
    created_at, updated_at, is_public_profile
) VALUES 
    ('33333333-3333-3333-3333-333333333333', 'pharmacy', 'active', 
     '{"business_name": "City Community Pharmacy"}', 
     'retail_pharmacy', 'basic_dispensing', 1, false, '33333333-3333-3333-3333-333333333333',
     NOW(), NOW(), true),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy', 'active', 
     '{"business_name": "Metro Health Dispensary"}', 
     'hospital_pharmacy', 'controlled_substances', 3, true, '44444444-4444-4444-4444-444444444444',
     NOW(), NOW(), false);

-- Step 7: Clean up cross-role fields
UPDATE user_profiles SET
    pharmacy_type = NULL,
    pharmacy_license_scope = NULL, 
    pharmacy_location_count = NULL,
    controlled_substance_permit = NULL,
    pharmacy_id = NULL
WHERE role = 'tcm_practitioner';

UPDATE user_profiles SET
    tcm_specialty = NULL,
    tcm_practice_years = NULL,
    tcm_certification_level = NULL,
    tcm_clinic_affiliation = NULL
WHERE role = 'pharmacy';

-- Step 8: Re-add constraints
ALTER TABLE user_profiles ADD CONSTRAINT check_pharmacy_fields_isolation 
    CHECK ((role::text = 'pharmacy'::text) OR (pharmacy_type IS NULL AND pharmacy_license_scope IS NULL AND pharmacy_location_count IS NULL AND controlled_substance_permit IS NULL));

ALTER TABLE user_profiles ADD CONSTRAINT check_tcm_fields_isolation 
    CHECK ((role::text = 'tcm_practitioner'::text) OR (tcm_specialty IS NULL AND tcm_practice_years IS NULL AND tcm_certification_level IS NULL AND tcm_clinic_affiliation IS NULL));

-- Step 9: Re-enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 10: Verification
\echo '=== VERIFICATION ==='
SELECT 
    'FINAL_CHECK' as category,
    id, 
    role, 
    status, 
    business_info IS NOT NULL as has_business_info,
    is_public_profile,
    CASE 
        WHEN role = 'tcm_practitioner' THEN COALESCE(tcm_specialty::text, 'NULL')
        WHEN role = 'pharmacy' THEN COALESCE(pharmacy_type::text, 'NULL')
        ELSE 'N/A'
    END as specialty_type
FROM user_profiles 
WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%'
ORDER BY role, id;

\echo '=== COMPLETE SEED DATA SOLUTION SUCCESS ===';