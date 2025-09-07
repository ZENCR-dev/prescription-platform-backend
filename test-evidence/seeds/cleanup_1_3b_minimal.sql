-- M1.3B Dev-Step 3: Cleanup Script for Behavioral Testing  
-- Purpose: Remove all test data and tables created by seed script
-- Ensures clean environment after testing

-- Remove test relationship data
DELETE FROM prescription_relationships WHERE 
    tcm_practitioner_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

DELETE FROM referral_relationships WHERE
    referring_tcm_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

-- Remove test user profiles
DELETE FROM user_profiles WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222', 
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444'
);

-- Drop relationship tables (since they were created for testing only)
DROP TABLE IF EXISTS prescription_relationships;
DROP TABLE IF EXISTS referral_relationships;

-- Remove auth users
DELETE FROM auth.users WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333', 
    '44444444-4444-4444-4444-444444444444'
);

-- Verify cleanup completed
SELECT 'Cleanup script completed' as status;