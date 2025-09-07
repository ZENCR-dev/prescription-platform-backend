-- Debug business relationship functions to understand why they return false

-- First, let's see what user data we actually have
\echo '=== Current user_profiles data ==='
SELECT id, role, status, business_info IS NOT NULL as has_business_info 
FROM user_profiles 
WHERE role IN ('tcm_practitioner', 'pharmacy') 
ORDER BY role, id;

-- Test the business relationship functions directly with existing users
\echo '=== Direct function tests ==='
SELECT 
    'pharmacy->tcm test' as test_name,
    private.has_prescription_business_relationship(
        (SELECT id FROM user_profiles WHERE role = 'pharmacy' AND status = 'active' LIMIT 1),
        (SELECT id FROM user_profiles WHERE role = 'tcm_practitioner' AND status = 'active' LIMIT 1)
    ) as result;

SELECT 
    'tcm->pharmacy test' as test_name,
    private.has_referral_business_relationship(
        (SELECT id FROM user_profiles WHERE role = 'tcm_practitioner' AND status = 'active' LIMIT 1),
        (SELECT id FROM user_profiles WHERE role = 'pharmacy' AND status = 'active' LIMIT 1)
    ) as result;

-- Check if we have any active users with business_info
\echo '=== Active users with business_info ==='
SELECT COUNT(*) as active_tcm_with_business 
FROM user_profiles 
WHERE role = 'tcm_practitioner' AND status = 'active' AND business_info IS NOT NULL;

SELECT COUNT(*) as active_pharmacy_with_business 
FROM user_profiles 
WHERE role = 'pharmacy' AND status = 'active' AND business_info IS NOT NULL;

-- Test the auth.uid() function that the views use
\echo '=== Current auth.uid() context ==='
SELECT auth.uid() as current_auth_uid;

-- Debug view WHERE clauses by checking what the views actually see
\echo '=== View filter debugging ==='
SELECT 
    id,
    role,
    status,
    business_info IS NOT NULL as has_business_info,
    private.has_prescription_business_relationship(auth.uid(), id) as has_prescription_rel,
    private.has_referral_business_relationship(auth.uid(), id) as has_referral_rel
FROM user_profiles 
WHERE role IN ('tcm_practitioner', 'pharmacy')
ORDER BY role, id;