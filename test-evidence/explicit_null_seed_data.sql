-- ============================================================================
-- EXPLICIT NULL SEED DATA - All Constraint Fields Explicitly Set
-- ============================================================================
-- Creates seed data with ALL constraint fields explicitly set to NULL

\echo '=== EXPLICIT NULL SEED DATA CREATION ==='

-- Step 1: Clean up existing data
DELETE FROM user_profiles WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%';

-- Step 2: Temporarily disable RLS for insertion
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Step 3: Create pharmacies for FK constraints  
INSERT INTO pharmacies (id, name, contact_info, created_at, updated_at)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'City Community Pharmacy', '{"type": "retail"}', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Metro Health Dispensary', '{"type": "hospital"}', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 4: TCM practitioners with ALL pharmacy fields explicitly NULL
INSERT INTO user_profiles (
    id, role, status, business_info, 
    -- TCM fields
    tcm_specialty, tcm_practice_years, tcm_certification_level,
    -- Pharmacy fields (ALL must be NULL for TCM role)
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit,
    created_at, updated_at, is_public_profile
) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm_practitioner', 'active', 
     '{"business_name": "East Wellness Center"}', 
     'acupuncture', 5, 'licensed',
     NULL, NULL, NULL, NULL,  -- All pharmacy fields NULL
     NOW(), NOW(), false),
    ('22222222-2222-2222-2222-222222222222', 'tcm_practitioner', 'active', 
     '{"business_name": "West Herbal Clinic"}', 
     'herbal_medicine', 3, 'licensed',
     NULL, NULL, NULL, NULL,  -- All pharmacy fields NULL
     NOW(), NOW(), true)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Pharmacies with ALL TCM fields explicitly NULL
INSERT INTO user_profiles (
    id, role, status, business_info,
    -- Pharmacy fields 
    pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit, pharmacy_id,
    -- TCM fields (ALL must be NULL for pharmacy role)  
    tcm_specialty, tcm_practice_years, tcm_certification_level,
    created_at, updated_at, is_public_profile
) VALUES 
    ('33333333-3333-3333-3333-333333333333', 'pharmacy', 'active', 
     '{"business_name": "City Community Pharmacy"}', 
     'retail_pharmacy', 'basic_dispensing', 1, false, '33333333-3333-3333-3333-333333333333',
     NULL, NULL, NULL,  -- All TCM fields NULL
     NOW(), NOW(), true),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy', 'active', 
     '{"business_name": "Metro Health Dispensary"}', 
     'hospital_pharmacy', 'controlled_substances', 3, true, '44444444-4444-4444-4444-444444444444',
     NULL, NULL, NULL,  -- All TCM fields NULL  
     NOW(), NOW(), false)
ON CONFLICT (id) DO NOTHING;

-- Step 6: Re-enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 7: Verification
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

\echo '=== EXPLICIT NULL SEED DATA COMPLETE ===';