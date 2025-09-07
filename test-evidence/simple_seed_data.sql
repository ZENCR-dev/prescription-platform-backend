-- ============================================================================
-- SIMPLE SEED DATA - Working Around Trigger Limitations
-- ============================================================================
-- Creates seed data by working with existing system constraints

\echo '=== SIMPLE SEED DATA CREATION ==='

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

-- Step 4: Create user_profiles directly with proper constraint compliance
-- TCM practitioners (all pharmacy fields NULL)
INSERT INTO user_profiles (
    id, role, status, business_info, 
    -- TCM fields only
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
     NOW(), NOW(), true)
ON CONFLICT (id) DO NOTHING;

-- Pharmacies (all TCM fields NULL by default)
INSERT INTO user_profiles (
    id, role, status, business_info,
    -- Pharmacy fields only
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
     NOW(), NOW(), false)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Re-enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 6: Verification
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
    END as specialty_type
FROM user_profiles 
WHERE id::text LIKE '11111111-%' OR id::text LIKE '22222222-%' OR id::text LIKE '33333333-%' OR id::text LIKE '44444444-%'
ORDER BY role, id;

\echo '=== SEED DATA COMPLETE ===';