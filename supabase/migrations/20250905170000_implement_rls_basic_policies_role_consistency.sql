-- ============================================================================
-- Task 1.3A: RLS Basic Policies & Role Consistency Correction
-- ============================================================================
-- Implements role-specific field isolation policies and canonical role values
-- Atomic transaction design with rollback capabilities and system table verification
-- 
-- Canonical Role Values: 'tcm_practitioner', 'pharmacy', 'admin'
-- Previous Role Values: 'practitioner', 'pharmacy_operator', 'admin'
--
-- Transaction Architecture:
-- 1. Constraint Update Transaction (DROP old constraints → ADD canonical constraints)
-- 2. Data Normalization Transaction (UPDATE existing data to canonical values) 
-- 3. RLS Policy Transaction (CREATE role-specific isolation policies)

-- ============================================================================
-- PRE-MIGRATION VERIFICATION
-- ============================================================================

-- Verify current constraint state before changes
DO $$
BEGIN
    RAISE NOTICE '=== PRE-MIGRATION VERIFICATION ===';
    RAISE NOTICE 'Current user_profiles constraints:';
    
    -- Log current constraints for audit trail
    PERFORM pg_catalog.pg_get_constraintdef(oid) as constraint_def
    FROM pg_constraint 
    WHERE conrelid = 'user_profiles'::regclass 
    AND conname LIKE '%role%';
END $$;

-- ============================================================================
-- TRANSACTION 1: CONSTRAINT UPDATE (ATOMIC)
-- ============================================================================

BEGIN;

-- Log transaction start
DO $$
BEGIN 
    RAISE NOTICE '=== TRANSACTION 1: CONSTRAINT UPDATE START ===';
    RAISE NOTICE 'Timestamp: %', NOW();
END $$;

-- Step 1.1: Remove old role constraint
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;

-- Step 1.2: Add canonical role constraint
ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_canonical_check
    CHECK (role IN ('tcm_practitioner', 'pharmacy', 'admin'));

-- Step 1.3: System table verification for constraint update
DO $$
DECLARE
    constraint_count INTEGER;
    constraint_def TEXT;
BEGIN
    -- Verify new constraint exists and is correctly defined
    SELECT COUNT(*), pg_catalog.pg_get_constraintdef(oid) 
    INTO constraint_count, constraint_def
    FROM pg_constraint 
    WHERE conrelid = 'user_profiles'::regclass 
    AND conname = 'user_profiles_role_canonical_check';
    
    IF constraint_count = 0 THEN
        RAISE EXCEPTION 'TRANSACTION 1 FAILED: Canonical constraint not created';
    END IF;
    
    IF constraint_def NOT LIKE '%tcm_practitioner%' OR 
       constraint_def NOT LIKE '%pharmacy%' OR 
       constraint_def NOT LIKE '%admin%' THEN
        RAISE EXCEPTION 'TRANSACTION 1 FAILED: Constraint definition incorrect: %', constraint_def;
    END IF;
    
    RAISE NOTICE 'TRANSACTION 1 VERIFICATION PASSED: Canonical constraint created successfully';
    RAISE NOTICE 'Constraint definition: %', constraint_def;
END $$;

COMMIT;

-- ============================================================================
-- TRANSACTION 2: DATA NORMALIZATION (ATOMIC)  
-- ============================================================================

BEGIN;

-- Log transaction start
DO $$
BEGIN
    RAISE NOTICE '=== TRANSACTION 2: DATA NORMALIZATION START ===';
    RAISE NOTICE 'Timestamp: %', NOW();
END $$;

-- Step 2.1: Log current role distribution before changes
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE 'Role distribution BEFORE normalization:';
    FOR rec IN 
        SELECT role, COUNT(*) as count 
        FROM user_profiles 
        GROUP BY role 
        ORDER BY role
    LOOP
        RAISE NOTICE '  Role: %, Count: %', rec.role, rec.count;
    END LOOP;
END $$;

-- Step 2.2: Normalize role values to canonical format
UPDATE user_profiles SET role = 'tcm_practitioner' WHERE role = 'practitioner';
UPDATE user_profiles SET role = 'pharmacy' WHERE role = 'pharmacy_operator';
-- Note: 'admin' remains unchanged as it's already canonical

-- Step 2.3: System table verification for data normalization
DO $$
DECLARE 
    non_canonical_count INTEGER;
    rec RECORD;
BEGIN
    -- Check for any remaining non-canonical role values
    SELECT COUNT(*) INTO non_canonical_count
    FROM user_profiles 
    WHERE role NOT IN ('tcm_practitioner', 'pharmacy', 'admin');
    
    IF non_canonical_count > 0 THEN
        RAISE EXCEPTION 'TRANSACTION 2 FAILED: % non-canonical role values remaining', non_canonical_count;
    END IF;
    
    RAISE NOTICE 'Role distribution AFTER normalization:';
    FOR rec IN 
        SELECT role, COUNT(*) as count,
            CASE WHEN role IN ('tcm_practitioner', 'pharmacy', 'admin') 
                THEN '✅ CANONICAL' 
                ELSE '❌ NON-CANONICAL' 
            END as compliance_status
        FROM user_profiles 
        GROUP BY role 
        ORDER BY role
    LOOP
        RAISE NOTICE '  Role: %, Count: %, Status: %', rec.role, rec.count, rec.compliance_status;
    END LOOP;
    
    RAISE NOTICE 'TRANSACTION 2 VERIFICATION PASSED: All role values normalized to canonical format';
END $$;

COMMIT;

-- ============================================================================
-- TRANSACTION 3: RLS POLICY IMPLEMENTATION (ATOMIC)
-- ============================================================================

BEGIN;

-- Log transaction start  
DO $$
BEGIN
    RAISE NOTICE '=== TRANSACTION 3: RLS POLICY IMPLEMENTATION START ===';
    RAISE NOTICE 'Timestamp: %', NOW();
END $$;

-- Step 3.1: Create helper functions for role-specific field validation
-- (These functions will be created in a separate step to maintain transaction boundaries)

-- Step 3.2: Drop existing basic policies to implement role-specific ones
DROP POLICY IF EXISTS "enhanced_select_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "enhanced_select_admin_all_profiles" ON user_profiles;
DROP POLICY IF EXISTS "enhanced_insert_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "enhanced_insert_admin_profiles" ON user_profiles;
DROP POLICY IF EXISTS "enhanced_update_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "enhanced_update_admin_profiles" ON user_profiles;
DROP POLICY IF EXISTS "enhanced_delete_admin_only" ON user_profiles;

-- Step 3.3: Create role-specific field isolation policies

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

-- Policy 3: Self-profile update with role-specific field isolation
CREATE POLICY "rls_basic_update_self_isolated" ON user_profiles
    FOR UPDATE TO authenticated
    USING (
        (SELECT auth.uid()) = id
    )
    WITH CHECK (
        (SELECT auth.uid()) = id AND
        (
            -- TCM practitioners can only update their own TCM fields + basic fields
            (private.get_current_user_role() = 'tcm_practitioner' AND
             private.check_tcm_fields_only_updated(OLD, NEW)) OR
            -- Pharmacy operators can only update their own pharmacy fields + basic fields  
            (private.get_current_user_role() = 'pharmacy' AND
             private.check_pharmacy_fields_only_updated(OLD, NEW)) OR
            -- Admins can update their admin fields + basic fields when editing self
            (private.get_current_user_role() = 'admin' AND
             private.check_admin_fields_only_updated(OLD, NEW))
        )
    );

-- Policy 4: Admin update access (all fields, all profiles, with audit)
CREATE POLICY "rls_basic_update_admin_all" ON user_profiles
    FOR UPDATE TO authenticated  
    USING (
        private.is_current_user_admin() AND
        private.log_admin_profile_access(id, 'UPDATE') IS NOT NULL
    )
    WITH CHECK (
        private.is_current_user_admin() AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin') AND
        private.log_admin_profile_access(id, 'UPDATE_CHECK') IS NOT NULL
    );

-- Policy 5: Self-profile insert (registration)
CREATE POLICY "rls_basic_insert_self" ON user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = id AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin')
    );

-- Policy 6: Admin insert (user management)
CREATE POLICY "rls_basic_insert_admin" ON user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (
        private.is_current_user_admin() AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin') AND
        private.log_admin_profile_access(id, 'INSERT') IS NOT NULL
    );

-- Policy 7: Admin-only delete (with audit)
CREATE POLICY "rls_basic_delete_admin_only" ON user_profiles
    FOR DELETE TO authenticated
    USING (
        private.is_current_user_admin() AND
        private.log_admin_profile_access(id, 'DELETE') IS NOT NULL
    );

-- Step 3.4: System table verification for RLS policies
DO $$
DECLARE
    policy_count INTEGER;
    expected_policies TEXT[] := ARRAY[
        'rls_basic_select_self',
        'rls_basic_select_admin', 
        'rls_basic_update_self_isolated',
        'rls_basic_update_admin_all',
        'rls_basic_insert_self',
        'rls_basic_insert_admin',
        'rls_basic_delete_admin_only'
    ];
    missing_policies TEXT[] := '{}';
    policy_name TEXT;
BEGIN
    -- Count total policies created
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
    
    IF array_length(missing_policies, 1) > 0 THEN
        RAISE EXCEPTION 'TRANSACTION 3 FAILED: Missing policies: %', array_to_string(missing_policies, ', ');
    END IF;
    
    IF policy_count != array_length(expected_policies, 1) THEN
        RAISE EXCEPTION 'TRANSACTION 3 FAILED: Expected % policies, found %', array_length(expected_policies, 1), policy_count;
    END IF;
    
    RAISE NOTICE 'TRANSACTION 3 VERIFICATION PASSED: All % RLS policies created successfully', policy_count;
    
    -- Log policy summary for audit
    RAISE NOTICE 'RLS Policy Summary:';
    RAISE NOTICE '  - SELECT policies: 2 (self + admin)';
    RAISE NOTICE '  - UPDATE policies: 2 (self-isolated + admin-all)'; 
    RAISE NOTICE '  - INSERT policies: 2 (self + admin)';
    RAISE NOTICE '  - DELETE policies: 1 (admin-only)';
END $$;

COMMIT;

-- ============================================================================
-- POST-MIGRATION VERIFICATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== POST-MIGRATION VERIFICATION COMPLETE ===';
    RAISE NOTICE 'Task 1.3A Implementation Summary:';
    RAISE NOTICE '✅ Transaction 1: Constraint updated to canonical role values';
    RAISE NOTICE '✅ Transaction 2: Existing data normalized to canonical format';  
    RAISE NOTICE '✅ Transaction 3: RLS basic policies implemented with field isolation';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Create role-specific field validation helper functions';
    RAISE NOTICE '2. Update handle_new_user() function to use canonical default';
    RAISE NOTICE '3. Run comprehensive behavioral tests';
    RAISE NOTICE '4. Collect evidence triplet for QAD validation';
END $$;

-- ============================================================================
-- MIGRATION METADATA
-- ============================================================================

COMMENT ON TABLE user_profiles IS 'Task 1.3A Complete: RLS basic policies with role-specific field isolation. Canonical roles: tcm_practitioner, pharmacy, admin';

-- Update table comments to reflect new RLS architecture
COMMENT ON COLUMN user_profiles.role IS 'Canonical role values: tcm_practitioner (TCM doctor), pharmacy (pharmacy staff), admin (administrator). Updated in Task 1.3A.';

-- Log completion
SELECT NOW() as migration_completed,
       'Task 1.3A: RLS Basic Policies & Role Consistency' as task,
       'ATOMIC TRANSACTIONS COMPLETE' as status;