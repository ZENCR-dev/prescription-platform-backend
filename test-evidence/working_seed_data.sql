-- ============================================================================
-- WORKING SEED DATA - Uses Trigger then Updates
-- ============================================================================
-- Creates auth.users (triggering profile creation) then updates the profiles

\echo '=== WORKING SEED DATA CREATION ==='

-- Step 1: Clean up existing data
DELETE FROM user_profiles WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';
DELETE FROM auth.users WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';

-- Step 2: Create pharmacies for FK constraints  
INSERT INTO pharmacies (id, name, contact_info, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'City Community Pharmacy', '{"type": "retail"}', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Metro Health Dispensary', '{"type": "hospital"}', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 3: Temporarily disable RLS for updates
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Step 4: Create auth.users which will trigger profile creation with default values
INSERT INTO auth.users (id, email, phone, created_at, updated_at, email_confirmed_at, raw_user_meta_data)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm1@test.com', '+1234567890', NOW(), NOW(), NOW(), '{"role": "tcm_practitioner"}'),
    ('22222222-2222-2222-2222-222222222222', 'tcm2@test.com', '+1234567891', NOW(), NOW(), NOW(), '{"role": "tcm_practitioner"}'),
    ('33333333-3333-3333-3333-333333333333', 'pharmacy1@test.com', '+1234567892', NOW(), NOW(), NOW(), '{"role": "pharmacy"}'),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy2@test.com', '+1234567893', NOW(), NOW(), NOW(), '{"role": "pharmacy"}')
ON CONFLICT (id) DO NOTHING;

-- Step 5: Update TCM profiles to proper values with NULL pharmacy fields
UPDATE user_profiles SET
    status = 'active',
    business_info = '{"business_name": "East Wellness Center"}',
    tcm_specialty = 'acupuncture',
    tcm_practice_years = 5,
    tcm_certification_level = 'licensed',
    -- Explicitly set ALL pharmacy fields to NULL
    pharmacy_type = NULL,
    pharmacy_license_scope = NULL,
    pharmacy_location_count = NULL,
    controlled_substance_permit = NULL,
    pharmacy_id = NULL,
    is_public_profile = false
WHERE id = '11111111-1111-1111-1111-111111111111';

UPDATE user_profiles SET
    status = 'active',
    business_info = '{"business_name": "West Herbal Clinic"}',
    tcm_specialty = 'herbal_medicine',
    tcm_practice_years = 3,
    tcm_certification_level = 'licensed',
    -- Explicitly set ALL pharmacy fields to NULL
    pharmacy_type = NULL,
    pharmacy_license_scope = NULL,
    pharmacy_location_count = NULL,
    controlled_substance_permit = NULL,
    pharmacy_id = NULL,
    is_public_profile = true
WHERE id = '22222222-2222-2222-2222-222222222222';

-- Step 6: Update pharmacy profiles to proper values with NULL TCM fields
UPDATE user_profiles SET
    status = 'active',
    business_info = '{"business_name": "City Community Pharmacy"}',
    pharmacy_type = 'retail_pharmacy',
    pharmacy_license_scope = 'basic_dispensing',
    pharmacy_location_count = 1,
    controlled_substance_permit = false,
    pharmacy_id = '33333333-3333-3333-3333-333333333333',
    -- Explicitly set ALL TCM fields to NULL
    tcm_specialty = NULL,
    tcm_practice_years = NULL,
    tcm_certification_level = NULL,
    tcm_clinic_affiliation = NULL,
    is_public_profile = true
WHERE id = '33333333-3333-3333-3333-333333333333';

UPDATE user_profiles SET
    status = 'active',
    business_info = '{"business_name": "Metro Health Dispensary"}',
    pharmacy_type = 'hospital_pharmacy',
    pharmacy_license_scope = 'controlled_substances',
    pharmacy_location_count = 3,
    controlled_substance_permit = true,
    pharmacy_id = '44444444-4444-4444-4444-444444444444',
    -- Explicitly set ALL TCM fields to NULL
    tcm_specialty = NULL,
    tcm_practice_years = NULL,
    tcm_certification_level = NULL,
    tcm_clinic_affiliation = NULL,
    is_public_profile = false
WHERE id = '44444444-4444-4444-4444-444444444444';

-- Step 7: Re-enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 8: Verification
\echo '=== VERIFICATION ==='
SELECT 
    id, 
    role, 
    status, 
    business_info IS NOT NULL as has_business_info,
    is_public_profile,
    CASE 
        WHEN role = 'tcm_practitioner' THEN tcm_specialty::text
        WHEN role = 'pharmacy' THEN pharmacy_type::text
        ELSE 'N/A'
    END as specialty_type,
    -- Check constraint compliance
    CASE 
        WHEN role = 'tcm_practitioner' THEN 
            CASE WHEN pharmacy_type IS NULL AND pharmacy_license_scope IS NULL 
                      AND pharmacy_location_count IS NULL AND controlled_substance_permit IS NULL 
                 THEN 'PHARMACY_FIELDS_OK' ELSE 'CONSTRAINT_VIOLATION' END
        WHEN role = 'pharmacy' THEN
            CASE WHEN tcm_specialty IS NULL AND tcm_practice_years IS NULL 
                      AND tcm_certification_level IS NULL 
                 THEN 'TCM_FIELDS_OK' ELSE 'CONSTRAINT_VIOLATION' END
        ELSE 'N/A'
    END as constraint_status
FROM user_profiles 
WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%'
ORDER BY role, id;

\echo '=== WORKING SEED DATA COMPLETE ==='
\echo 'Expected: 2 TCM practitioners, 2 pharmacies, 2 public profiles, all with proper constraint compliance';