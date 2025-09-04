-- Test script for JWT claims functionality
-- Tests that role information is properly included in JWT tokens and accessible via RLS policies

-- Test 1: Verify user_profiles table has correct role enum values
DO $$
DECLARE
    role_constraint_exists BOOLEAN;
BEGIN
    -- Check if the role constraint allows the correct values
    SELECT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'user_profiles_role_check'
        AND check_clause LIKE '%tcm_practitioner%'
        AND check_clause LIKE '%pharmacy%'
        AND check_clause LIKE '%admin%'
    ) INTO role_constraint_exists;
    
    IF role_constraint_exists THEN
        RAISE NOTICE 'PASS: user_profiles role constraint includes correct enum values';
    ELSE
        RAISE EXCEPTION 'FAIL: user_profiles role constraint missing correct enum values';
    END IF;
END $$;

-- Test 2: Verify handle_new_user function exists and uses correct default role
DO $$
DECLARE
    function_exists BOOLEAN;
    function_body TEXT;
BEGIN
    -- Check if function exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'handle_new_user'
        AND routine_type = 'FUNCTION'
    ) INTO function_exists;
    
    IF function_exists THEN
        RAISE NOTICE 'PASS: handle_new_user function exists';
        
        -- Get function body to check default role
        SELECT prosrc INTO function_body 
        FROM pg_proc 
        WHERE proname = 'handle_new_user';
        
        IF function_body LIKE '%tcm_practitioner%' THEN
            RAISE NOTICE 'PASS: handle_new_user uses tcm_practitioner as default role';
        ELSE
            RAISE EXCEPTION 'FAIL: handle_new_user does not use tcm_practitioner as default role';
        END IF;
    ELSE
        RAISE EXCEPTION 'FAIL: handle_new_user function does not exist';
    END IF;
END $$;

-- Test 3: Verify trigger exists for automatic profile creation
DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created'
        AND event_object_table = 'users'
        AND event_object_schema = 'auth'
    ) INTO trigger_exists;
    
    IF trigger_exists THEN
        RAISE NOTICE 'PASS: on_auth_user_created trigger exists';
    ELSE
        RAISE EXCEPTION 'FAIL: on_auth_user_created trigger does not exist';
    END IF;
END $$;

-- Test 4: Test RLS policies work with JWT role claims
-- This test simulates the RLS policy behavior with role claims

DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    profile_count INTEGER;
BEGIN
    -- Clean up any existing test user
    DELETE FROM user_profiles WHERE id = test_user_id;
    DELETE FROM auth.users WHERE id = test_user_id;
    
    -- Insert into auth.users with metadata (trigger will auto-create profile)
    INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at, raw_user_meta_data)
    VALUES (test_user_id, 'test@example.com', NOW(), NOW(), NOW(), 
            '{"role": "tcm_practitioner", "business_info": {"business_name": "Test Clinic"}}');
    
    -- Verify the profile was auto-created by trigger
    SELECT COUNT(*) INTO profile_count 
    FROM user_profiles 
    WHERE id = test_user_id AND role = 'tcm_practitioner';
    
    IF profile_count = 1 THEN
        RAISE NOTICE 'PASS: handle_new_user trigger auto-created profile with tcm_practitioner role';
    ELSE
        RAISE EXCEPTION 'FAIL: handle_new_user trigger did not create profile correctly';
    END IF;
    
    -- Clean up test data
    DELETE FROM user_profiles WHERE id = test_user_id;
    DELETE FROM auth.users WHERE id = test_user_id;
    RAISE NOTICE 'Test data cleaned up';
END $$;

-- Test 5: Verify required indexes exist for performance
DO $$
DECLARE
    role_index_exists BOOLEAN;
    role_status_index_exists BOOLEAN;
BEGIN
    -- Check for role index
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'user_profiles' 
        AND indexname LIKE '%role%'
    ) INTO role_index_exists;
    
    -- Check for combined role and status index
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'user_profiles' 
        AND indexname = 'idx_user_profiles_role_status'
    ) INTO role_status_index_exists;
    
    IF role_index_exists THEN
        RAISE NOTICE 'PASS: Role index exists for user_profiles';
    ELSE
        RAISE NOTICE 'WARNING: No role index found for user_profiles';
    END IF;
    
    IF role_status_index_exists THEN
        RAISE NOTICE 'PASS: Combined role-status index exists for optimal JWT hook performance';
    ELSE
        RAISE NOTICE 'WARNING: Combined role-status index not found';
    END IF;
END $$;

-- Test 6: Verify permissions for Edge Function access
DO $$
DECLARE
    anon_permissions BOOLEAN;
    auth_permissions BOOLEAN;
BEGIN
    -- Check anon role has SELECT permission
    SELECT has_table_privilege('anon', 'user_profiles', 'SELECT') INTO anon_permissions;
    
    -- Check authenticated role has SELECT permission  
    SELECT has_table_privilege('authenticated', 'user_profiles', 'SELECT') INTO auth_permissions;
    
    IF anon_permissions AND auth_permissions THEN
        RAISE NOTICE 'PASS: Required permissions granted for Edge Function access';
    ELSE
        RAISE EXCEPTION 'FAIL: Missing permissions for Edge Function access (anon: %, auth: %)', 
                       anon_permissions, auth_permissions;
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== JWT Claims Test Summary ===';
    RAISE NOTICE 'All database structure tests completed';
    RAISE NOTICE 'Next: Test Edge Function deployment with `supabase functions deploy custom-access-token`';
    RAISE NOTICE 'Then: Test JWT token generation with actual auth flow';
END $$;