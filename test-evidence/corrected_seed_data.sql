-- ============================================================================
-- CORRECTED SEED DATA CREATION - Handles all constraints properly
-- ============================================================================

-- Step 1: Clean up any existing test data
DELETE FROM user_profiles WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';
DELETE FROM pharmacies WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';
DELETE FROM auth.users WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';

-- Step 2: Create pharmacies FIRST (needed for FK constraint)
INSERT INTO pharmacies (id, name, contact_info, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'City Community Pharmacy', '{"type": "retail"}', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Metro Health Dispensary', '{"type": "hospital"}', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 3: Disable the handle_new_user trigger temporarily to avoid automatic profile creation with wrong constraints
ALTER TABLE auth.users DISABLE TRIGGER ALL;

-- Step 4: Insert auth.users records without triggering profile creation
INSERT INTO auth.users (id, email, phone, created_at, updated_at, email_confirmed_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm1@test.com', '+1234567890', NOW(), NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'tcm2@test.com', '+1234567891', NOW(), NOW(), NOW()),
    ('33333333-3333-3333-3333-333333333333', 'pharmacy1@test.com', '+1234567892', NOW(), NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy2@test.com', '+1234567893', NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 5: Re-enable triggers
ALTER TABLE auth.users ENABLE TRIGGER ALL;

-- Step 6: Manually create user_profiles with proper role-specific field constraints
-- TCM practitioners (only TCM-specific fields, all pharmacy fields NULL)
INSERT INTO user_profiles (
    id, role, status, business_info, 
    tcm_specialty, tcm_practice_years, tcm_certification_level,
    -- Explicitly set all pharmacy fields to NULL to satisfy check constraint
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit, pharmacy_id,
    created_at, updated_at
) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm_practitioner', 'active', 
     '{"business_name": "East Wellness Center"}', 'acupuncture', 5, 'licensed',
     NULL, NULL, NULL, NULL, NULL, NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'tcm_practitioner', 'active', 
     '{"business_name": "West Herbal Clinic"}', 'herbal_medicine', 3, 'licensed',
     NULL, NULL, NULL, NULL, NULL, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Pharmacies (only pharmacy-specific fields, all TCM fields NULL)  
INSERT INTO user_profiles (
    id, role, status, business_info, 
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit, pharmacy_id,
    -- Explicitly set all TCM fields to NULL to satisfy check constraint  
    tcm_specialty, tcm_practice_years, tcm_certification_level,
    created_at, updated_at
) VALUES 
    ('33333333-3333-3333-3333-333333333333', 'pharmacy', 'active', 
     '{"business_name": "City Community Pharmacy"}', 'retail_pharmacy', 'basic_dispensing', 1, false,
     '33333333-3333-3333-3333-333333333333',
     NULL, NULL, NULL, NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy', 'active', 
     '{"business_name": "Metro Health Dispensary"}', 'hospital_pharmacy', 'controlled_substances', 3, true,
     '44444444-4444-4444-4444-444444444444', 
     NULL, NULL, NULL, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 7: Set public profiles for public directory testing
UPDATE user_profiles SET is_public_profile = true 
WHERE id IN ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- Step 8: Verify seed data was created correctly
\echo '=== SEED DATA VERIFICATION ==='
SELECT 
    id, role, status, 
    business_info IS NOT NULL as has_business_info,
    is_public_profile,
    CASE 
        WHEN role = 'tcm_practitioner' THEN tcm_specialty
        WHEN role = 'pharmacy' THEN pharmacy_type
        ELSE 'N/A'
    END as specialty_or_type
FROM user_profiles 
WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%'
ORDER BY role, id;