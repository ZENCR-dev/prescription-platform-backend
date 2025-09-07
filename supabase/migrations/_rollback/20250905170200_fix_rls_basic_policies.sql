-- ============================================================================
-- Fix RLS Basic Policies - Task 1.3A Policy Creation Fix
-- ============================================================================
-- Corrects RLS policy creation issues from main migration
-- Fixes OLD/NEW references which don't exist in RLS policy context

-- ============================================================================
-- CLEAN UP FAILED POLICIES AND CREATE CORRECT ONES
-- ============================================================================

BEGIN;

RAISE NOTICE '=== FIX RLS BASIC POLICIES START ===';

-- Step 1: Drop any partially created policies from failed migration
DROP POLICY IF EXISTS "rls_basic_select_self" ON user_profiles;
DROP POLICY IF EXISTS "rls_basic_select_admin" ON user_profiles;
DROP POLICY IF EXISTS "rls_basic_update_self_isolated" ON user_profiles;
DROP POLICY IF EXISTS "rls_basic_update_admin_all" ON user_profiles;
DROP POLICY IF EXISTS "rls_basic_insert_self" ON user_profiles;
DROP POLICY IF EXISTS "rls_basic_insert_admin" ON user_profiles;
DROP POLICY IF EXISTS "rls_basic_delete_admin_only" ON user_profiles;

-- Step 2: Create corrected RLS basic policies

-- Policy 1: Self-profile read access (all fields for own profile)
CREATE POLICY "rls_basic_select_self" ON user_profiles
    FOR SELECT TO authenticated
    USING (
        (SELECT auth.uid()) = id
    );

-- Policy 2: Admin read access (all profiles with audit)
CREATE POLICY "rls_basic_select_admin" ON user_profiles  
    FOR SELECT TO authenticated
    USING (
        private.is_current_user_admin() AND
        private.log_admin_profile_access(id, 'SELECT') IS NOT NULL
    );

-- Policy 3: Self-profile insert (registration)
CREATE POLICY "rls_basic_insert_self" ON user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = id AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin')
    );

-- Policy 4: Admin insert (user management)
CREATE POLICY "rls_basic_insert_admin" ON user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (
        private.is_current_user_admin() AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin') AND
        private.log_admin_profile_access(id, 'INSERT') IS NOT NULL
    );

-- Policy 5: Self-profile update - basic version (without field isolation for now)
-- Note: Field isolation will be implemented via application logic or triggers
CREATE POLICY "rls_basic_update_self" ON user_profiles
    FOR UPDATE TO authenticated
    USING (
        (SELECT auth.uid()) = id
    )
    WITH CHECK (
        (SELECT auth.uid()) = id AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin')
    );

-- Policy 6: Admin update access (all fields, all profiles, with audit)
CREATE POLICY "rls_basic_update_admin_all" ON user_profiles
    FOR UPDATE TO authenticated  
    USING (
        private.is_current_user_admin() AND
        private.log_admin_profile_access(id, 'UPDATE') IS NOT NULL
    )
    WITH CHECK (
        private.is_current_user_admin() AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin')
    );

-- Policy 7: Admin-only delete (with audit)
CREATE POLICY "rls_basic_delete_admin_only" ON user_profiles
    FOR DELETE TO authenticated
    USING (
        private.is_current_user_admin() AND
        private.log_admin_profile_access(id, 'DELETE') IS NOT NULL
    );

-- Step 3: Verify all policies were created successfully
DO $$
DECLARE
    policy_count INTEGER;
    expected_policies TEXT[] := ARRAY[
        'rls_basic_select_self',
        'rls_basic_select_admin',
        'rls_basic_insert_self',
        'rls_basic_insert_admin',
        'rls_basic_update_self',
        'rls_basic_update_admin_all',
        'rls_basic_delete_admin_only'
    ];
    missing_policies TEXT[] := '{}';
    policy_name TEXT;
BEGIN
    RAISE NOTICE '=== POLICY CREATION VERIFICATION ===';
    
    -- Count RLS basic policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname LIKE 'rls_basic_%';
    
    -- Check each expected policy exists
    FOREACH policy_name IN ARRAY expected_policies
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = 'user_profiles' 
            AND policyname = policy_name
        ) THEN
            missing_policies := array_append(missing_policies, policy_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_policies, 1) = 0 THEN
        RAISE NOTICE '✅ SUCCESS: All % RLS basic policies created successfully', policy_count;
        RAISE NOTICE '   Policies: %', array_to_string(expected_policies, ', ');
    ELSE
        RAISE EXCEPTION 'POLICY CREATION FAILED: Missing policies: %', array_to_string(missing_policies, ', ');
    END IF;
END $$;

-- Step 4: Create field isolation trigger as alternative to policy-level field checking
CREATE OR REPLACE FUNCTION private.enforce_role_field_isolation()
RETURNS TRIGGER
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- Only check for UPDATE operations
    IF TG_OP = 'UPDATE' THEN
        
        -- Get current user role
        DECLARE
            current_user_role TEXT;
        BEGIN
            current_user_role := private.get_current_user_role();
            
            -- Allow admin to modify any fields
            IF private.is_current_user_admin() THEN
                RETURN NEW;
            END IF;
            
            -- Apply role-specific field isolation
            CASE current_user_role
                WHEN 'tcm_practitioner' THEN
                    IF NOT private.check_tcm_fields_only_updated(OLD, NEW) THEN
                        RAISE EXCEPTION 'TCM practitioners can only modify TCM-specific fields and basic fields';
                    END IF;
                    
                WHEN 'pharmacy' THEN
                    IF NOT private.check_pharmacy_fields_only_updated(OLD, NEW) THEN
                        RAISE EXCEPTION 'Pharmacy users can only modify pharmacy-specific fields and basic fields';
                    END IF;
                    
                WHEN 'admin' THEN
                    IF NOT private.check_admin_fields_only_updated(OLD, NEW) THEN
                        RAISE EXCEPTION 'Admin users can only modify admin-specific fields and basic fields when editing own profile';
                    END IF;
                    
                ELSE
                    RAISE EXCEPTION 'Unknown role: %', current_user_role;
            END CASE;
        END;
    END IF;
    
    RETURN NEW;
END $$;

-- Create the trigger
DROP TRIGGER IF EXISTS enforce_role_field_isolation_trigger ON user_profiles;
CREATE TRIGGER enforce_role_field_isolation_trigger
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION private.enforce_role_field_isolation();

RAISE NOTICE '✅ Field isolation trigger created successfully';

-- Step 5: Update policy comments
COMMENT ON POLICY "rls_basic_select_self" ON user_profiles IS 
    'Task 1.3A: Users can view only their own profile with all role-specific fields';

COMMENT ON POLICY "rls_basic_select_admin" ON user_profiles IS 
    'Task 1.3A: Admins can view all profiles with audit logging';

COMMENT ON POLICY "rls_basic_insert_self" ON user_profiles IS 
    'Task 1.3A: Users can create their own profile during registration';

COMMENT ON POLICY "rls_basic_insert_admin" ON user_profiles IS 
    'Task 1.3A: Admins can create profiles with audit logging';

COMMENT ON POLICY "rls_basic_update_self" ON user_profiles IS 
    'Task 1.3A: Users can update own profile with trigger-enforced field isolation';

COMMENT ON POLICY "rls_basic_update_admin_all" ON user_profiles IS 
    'Task 1.3A: Admins can update any profile with audit logging';

COMMENT ON POLICY "rls_basic_delete_admin_only" ON user_profiles IS 
    'Task 1.3A: Only admins can delete profiles with audit logging';

COMMIT;

RAISE NOTICE '=== RLS BASIC POLICIES FIX COMPLETE ===';
RAISE NOTICE 'Task 1.3A RLS implementation now ready for testing';

-- Log completion
SELECT NOW() as policies_fixed,
       'RLS Basic Policies' as component,
       'FIELD ISOLATION VIA TRIGGER' as implementation;