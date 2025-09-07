-- ============================================================================
-- FIXED SEED DATA WITH ROLE FIELD ISOLATION CONSTRAINTS
-- ============================================================================
-- Creates proper seed data respecting role-specific field constraints
-- Addresses architect feedback for IRG recovery

\echo '=== STARTING SEED DATA CREATION WITH CONSTRAINT COMPLIANCE ==='

-- Step 1: Clean up any existing test data
DELETE FROM user_profiles WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';
DELETE FROM auth.users WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';
DELETE FROM pharmacies WHERE id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';

-- Step 2: Temporarily disable RLS to allow seed insertion
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
\echo '✅ RLS disabled for seed data insertion';

-- Step 3: Create pharmacies FIRST (for FK constraints)
INSERT INTO pharmacies (id, name, contact_info, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'City Community Pharmacy', '{"type": "retail"}', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Metro Health Dispensary', '{"type": "hospital"}', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 4: Disable auth.users triggers to prevent automatic profile creation
ALTER TABLE auth.users DISABLE TRIGGER handle_new_user;
\echo '✅ auth.users triggers disabled';

-- Step 5: Insert auth.users records without triggering profile creation
INSERT INTO auth.users (id, email, phone, created_at, updated_at, email_confirmed_at, confirmation_token, recovery_token)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm1@test.com', '+1234567890', NOW(), NOW(), NOW(), '', ''),
    ('22222222-2222-2222-2222-222222222222', 'tcm2@test.com', '+1234567891', NOW(), NOW(), NOW(), '', ''),
    ('33333333-3333-3333-3333-333333333333', 'pharmacy1@test.com', '+1234567892', NOW(), NOW(), NOW(), '', ''),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy2@test.com', '+1234567893', NOW(), NOW(), NOW(), '', '')
ON CONFLICT (id) DO NOTHING;

-- Step 6: Create TCM practitioner profiles with EXPLICIT NULL pharmacy fields
INSERT INTO user_profiles (
    id, role, status, business_info, 
    -- TCM fields (allowed for tcm_practitioner role)
    tcm_specialty, tcm_practice_years, tcm_certification_level, tcm_clinic_affiliation,
    -- Pharmacy fields (MUST be NULL for tcm_practitioner role)
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit, pharmacy_id,
    -- Admin fields (MUST be NULL for non-admin role)
    admin_level, admin_scope, admin_certification_date, admin_supervisor_id,
    -- License fields (can be NULL)
    license_type, license_number, license_status, license_expiry_date,
    -- Other fields
    created_at, updated_at, is_public_profile
) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm_practitioner', 'active', 
     '{"business_name": "East Wellness Center"}', 
     -- TCM fields
     'acupuncture', 5, 'licensed', NULL,
     -- Pharmacy fields (explicitly NULL)
     NULL, NULL, NULL, NULL, NULL,
     -- Admin fields (explicitly NULL)
     NULL, NULL, NULL, NULL,
     -- License fields
     'tcm_practitioner', 'TCM-123456', 'verified', NOW() + INTERVAL '1 year',
     -- Other fields
     NOW(), NOW(), false),
    ('22222222-2222-2222-2222-222222222222', 'tcm_practitioner', 'active', 
     '{"business_name": "West Herbal Clinic"}', 
     -- TCM fields
     'herbal_medicine', 3, 'licensed', NULL,
     -- Pharmacy fields (explicitly NULL)
     NULL, NULL, NULL, NULL, NULL,
     -- Admin fields (explicitly NULL)  
     NULL, NULL, NULL, NULL,
     -- License fields
     'tcm_practitioner', 'TCM-123457', 'verified', NOW() + INTERVAL '1 year',
     -- Other fields
     NOW(), NOW(), true)  -- This one is public
ON CONFLICT (id) DO NOTHING;

-- Step 7: Create pharmacy profiles with EXPLICIT NULL TCM fields
INSERT INTO user_profiles (
    id, role, status, business_info,
    -- Pharmacy fields (allowed for pharmacy role)
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit, pharmacy_id,
    -- TCM fields (MUST be NULL for pharmacy role)
    tcm_specialty, tcm_practice_years, tcm_certification_level, tcm_clinic_affiliation,
    -- Admin fields (MUST be NULL for non-admin role)
    admin_level, admin_scope, admin_certification_date, admin_supervisor_id,
    -- License fields
    license_type, license_number, license_status, license_expiry_date,
    -- Other fields
    created_at, updated_at, is_public_profile
) VALUES 
    ('33333333-3333-3333-3333-333333333333', 'pharmacy', 'active', 
     '{"business_name": "City Community Pharmacy"}', 
     -- Pharmacy fields
     'retail_pharmacy', 'basic_dispensing', 1, false, '33333333-3333-3333-3333-333333333333',
     -- TCM fields (explicitly NULL)
     NULL, NULL, NULL, NULL,
     -- Admin fields (explicitly NULL)
     NULL, NULL, NULL, NULL,
     -- License fields
     'pharmacy', 'PHARM-654321', 'verified', NOW() + INTERVAL '1 year',
     -- Other fields
     NOW(), NOW(), true),  -- This one is public
    ('44444444-4444-4444-4444-444444444444', 'pharmacy', 'active', 
     '{"business_name": "Metro Health Dispensary"}', 
     -- Pharmacy fields
     'hospital_pharmacy', 'controlled_substances', 3, true, '44444444-4444-4444-4444-444444444444',
     -- TCM fields (explicitly NULL)
     NULL, NULL, NULL, NULL,
     -- Admin fields (explicitly NULL)
     NULL, NULL, NULL, NULL,
     -- License fields
     'pharmacy', 'PHARM-654322', 'verified', NOW() + INTERVAL '1 year',
     -- Other fields
     NOW(), NOW(), false)
ON CONFLICT (id) DO NOTHING;

-- Step 8: Re-enable triggers
ALTER TABLE auth.users ENABLE TRIGGER handle_new_user;
\echo '✅ auth.users triggers re-enabled';

-- Step 9: Re-enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
\echo '✅ RLS re-enabled';

-- Step 10: Verification - check that data was created correctly
\echo '=== SEED DATA VERIFICATION ==='
SELECT 
    'VERIFICATION' as category,
    id, 
    role, 
    status, 
    business_info IS NOT NULL as has_business_info,
    is_public_profile,
    CASE 
        WHEN role = 'tcm_practitioner' THEN COALESCE(tcm_specialty::text, 'NULL')
        WHEN role = 'pharmacy' THEN COALESCE(pharmacy_type::text, 'NULL')
        ELSE 'N/A'
    END as role_specific_field,
    CASE
        WHEN role = 'tcm_practitioner' THEN 
            CASE WHEN pharmacy_type IS NULL AND pharmacy_license_scope IS NULL 
                      AND pharmacy_location_count IS NULL AND controlled_substance_permit IS NULL 
                 THEN 'PHARMACY_FIELDS_NULL' ELSE 'CONSTRAINT_VIOLATION' END
        WHEN role = 'pharmacy' THEN
            CASE WHEN tcm_specialty IS NULL AND tcm_practice_years IS NULL 
                      AND tcm_certification_level IS NULL 
                 THEN 'TCM_FIELDS_NULL' ELSE 'CONSTRAINT_VIOLATION' END
        ELSE 'N/A'
    END as constraint_compliance
FROM user_profiles 
WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%'
ORDER BY role, id;

\echo '=== SEED DATA CREATION COMPLETE ==='
\echo 'Expected: 2 TCM practitioners, 2 pharmacies, 2 public profiles';
\echo 'All profiles should have constraint_compliance showing proper field isolation';