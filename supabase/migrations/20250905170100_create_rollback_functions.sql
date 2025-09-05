-- ============================================================================
-- Rollback Functions for Task 1.3A Implementation
-- ============================================================================
-- Creates comprehensive rollback capabilities for all Task 1.3A changes
-- Can be executed independently or as part of emergency recovery procedures
--
-- Rollback Coverage:
-- 1. Constraint rollback (canonical -> legacy constraint)
-- 2. Data rollback (canonical -> legacy role values)  
-- 3. RLS policy rollback (role-specific -> basic policies)
-- 4. Function rollback (canonical defaults -> legacy defaults)

-- ============================================================================
-- ROLLBACK FUNCTION 1: CONSTRAINT ROLLBACK
-- ============================================================================

CREATE OR REPLACE FUNCTION private.rollback_constraint_changes()
RETURNS VOID
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RAISE NOTICE '=== CONSTRAINT ROLLBACK START ===';
    
    -- Remove canonical constraint
    BEGIN
        ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_canonical_check;
        RAISE NOTICE '✅ Canonical constraint removed';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '⚠️ Failed to remove canonical constraint: %', SQLERRM;
    END;
    
    -- Restore legacy constraint
    BEGIN
        ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check
            CHECK (role IN ('practitioner', 'pharmacy_operator', 'admin'));
        RAISE NOTICE '✅ Legacy constraint restored';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '⚠️ Failed to restore legacy constraint: %', SQLERRM;
        -- If this fails, we might have data incompatibility
        RAISE NOTICE 'Data may need to be rolled back first before constraint rollback';
    END;
    
    -- Verify rollback success
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'user_profiles'::regclass 
        AND conname = 'user_profiles_role_check'
        AND pg_catalog.pg_get_constraintdef(oid) LIKE '%practitioner%'
    ) THEN
        RAISE NOTICE '✅ CONSTRAINT ROLLBACK SUCCESSFUL - Legacy constraint active';
    ELSE
        RAISE WARNING '❌ CONSTRAINT ROLLBACK VERIFICATION FAILED';
    END IF;
    
    RAISE NOTICE '=== CONSTRAINT ROLLBACK COMPLETE ===';
END $$;

-- ============================================================================
-- ROLLBACK FUNCTION 2: DATA ROLLBACK  
-- ============================================================================

CREATE OR REPLACE FUNCTION private.rollback_data_normalization()
RETURNS VOID
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    affected_rows INTEGER := 0;
    tcm_count INTEGER;
    pharmacy_count INTEGER;
BEGIN
    RAISE NOTICE '=== DATA ROLLBACK START ===';
    
    -- Log current role distribution before rollback
    SELECT COUNT(*) INTO tcm_count FROM user_profiles WHERE role = 'tcm_practitioner';
    SELECT COUNT(*) INTO pharmacy_count FROM user_profiles WHERE role = 'pharmacy';
    
    RAISE NOTICE 'Current role distribution:';
    RAISE NOTICE '  tcm_practitioner: %', tcm_count;
    RAISE NOTICE '  pharmacy: %', pharmacy_count;
    
    -- Rollback canonical values to legacy values
    BEGIN
        -- Roll back tcm_practitioner -> practitioner
        UPDATE user_profiles SET role = 'practitioner' WHERE role = 'tcm_practitioner';
        GET DIAGNOSTICS affected_rows = ROW_COUNT;
        RAISE NOTICE '✅ Rolled back % tcm_practitioner -> practitioner', affected_rows;
        
        -- Roll back pharmacy -> pharmacy_operator
        UPDATE user_profiles SET role = 'pharmacy_operator' WHERE role = 'pharmacy';  
        GET DIAGNOSTICS affected_rows = ROW_COUNT;
        RAISE NOTICE '✅ Rolled back % pharmacy -> pharmacy_operator', affected_rows;
        
        -- admin stays the same (no rollback needed)
        RAISE NOTICE '✅ Admin roles unchanged (already correct)';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '❌ Data rollback failed: %', SQLERRM;
        RAISE EXCEPTION 'DATA ROLLBACK FAILED - manual intervention may be required';
    END;
    
    -- Verify rollback success
    DECLARE
        non_legacy_count INTEGER;
        rec RECORD;
    BEGIN
        SELECT COUNT(*) INTO non_legacy_count
        FROM user_profiles 
        WHERE role NOT IN ('practitioner', 'pharmacy_operator', 'admin');
        
        IF non_legacy_count = 0 THEN
            RAISE NOTICE '✅ DATA ROLLBACK SUCCESSFUL - All role values restored to legacy format';
            
            -- Log final distribution
            RAISE NOTICE 'Final role distribution after rollback:';
            FOR rec IN 
                SELECT role, COUNT(*) as count 
                FROM user_profiles 
                GROUP BY role 
                ORDER BY role
            LOOP
                RAISE NOTICE '  %: %', rec.role, rec.count;
            END LOOP;
        ELSE
            RAISE WARNING '❌ DATA ROLLBACK VERIFICATION FAILED - % non-legacy values remain', non_legacy_count;
        END IF;
    END;
    
    RAISE NOTICE '=== DATA ROLLBACK COMPLETE ===';
END $$;

-- ============================================================================
-- ROLLBACK FUNCTION 3: RLS POLICY ROLLBACK
-- ============================================================================

CREATE OR REPLACE FUNCTION private.rollback_rls_policies()
RETURNS VOID  
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RAISE NOTICE '=== RLS POLICY ROLLBACK START ===';
    
    -- Drop Task 1.3A role-specific policies
    RAISE NOTICE 'Dropping Task 1.3A role-specific policies...';
    DROP POLICY IF EXISTS "rls_basic_select_self" ON user_profiles;
    DROP POLICY IF EXISTS "rls_basic_select_admin" ON user_profiles;
    DROP POLICY IF EXISTS "rls_basic_update_self_isolated" ON user_profiles;
    DROP POLICY IF EXISTS "rls_basic_update_admin_all" ON user_profiles;
    DROP POLICY IF EXISTS "rls_basic_insert_self" ON user_profiles;
    DROP POLICY IF EXISTS "rls_basic_insert_admin" ON user_profiles;
    DROP POLICY IF EXISTS "rls_basic_delete_admin_only" ON user_profiles;
    
    RAISE NOTICE '✅ Task 1.3A policies removed';
    
    -- Restore enhanced policies (from 20250829124010_enhance_user_profiles_rls.sql)
    RAISE NOTICE 'Restoring previous enhanced policies...';
    
    -- Restore enhanced SELECT policies
    CREATE POLICY "enhanced_select_own_profile" 
    ON user_profiles
    FOR SELECT 
    TO authenticated
    USING (
        (SELECT auth.uid()) = id
    );
    
    CREATE POLICY "enhanced_select_admin_all_profiles"
    ON user_profiles  
    FOR SELECT
    TO authenticated
    USING (
        private.is_current_user_admin()
    );
    
    -- Restore enhanced INSERT policies
    CREATE POLICY "enhanced_insert_own_profile"
    ON user_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = id
        AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin') -- Note: This will need constraint rollback first
    );
    
    CREATE POLICY "enhanced_insert_admin_profiles"
    ON user_profiles
    FOR INSERT  
    TO authenticated
    WITH CHECK (
        private.is_current_user_admin()
        AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin')
    );
    
    -- Restore enhanced UPDATE policies
    CREATE POLICY "enhanced_update_own_profile"
    ON user_profiles
    FOR UPDATE
    TO authenticated  
    USING (
        (SELECT auth.uid()) = id
    )
    WITH CHECK (
        (SELECT auth.uid()) = id
        AND
        (private.is_current_user_admin() OR role IN ('tcm_practitioner', 'pharmacy', 'admin'))
        AND
        (business_info IS NULL OR NOT (business_info::text ~* '(ssn|social|dob|birth|patient)'))
    );
    
    CREATE POLICY "enhanced_update_admin_profiles"  
    ON user_profiles
    FOR UPDATE
    TO authenticated
    USING (
        private.is_current_user_admin()
    )
    WITH CHECK (
        private.is_current_user_admin()
        AND
        role IN ('tcm_practitioner', 'pharmacy', 'admin')
        AND
        (business_info IS NULL OR NOT (business_info::text ~* '(ssn|social|dob|birth|patient)'))
    );
    
    -- Restore enhanced DELETE policy
    CREATE POLICY "enhanced_delete_admin_only"
    ON user_profiles
    FOR DELETE
    TO authenticated  
    USING (
        private.is_current_user_admin()
    );
    
    RAISE NOTICE '✅ Enhanced policies restored';
    
    -- Verify policy rollback
    DECLARE
        policy_count INTEGER;
        expected_policies TEXT[] := ARRAY[
            'enhanced_select_own_profile',
            'enhanced_select_admin_all_profiles',
            'enhanced_insert_own_profile', 
            'enhanced_insert_admin_profiles',
            'enhanced_update_own_profile',
            'enhanced_update_admin_profiles',
            'enhanced_delete_admin_only'
        ];
    BEGIN
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles'
        AND policyname LIKE 'enhanced_%';
        
        IF policy_count = array_length(expected_policies, 1) THEN
            RAISE NOTICE '✅ RLS POLICY ROLLBACK SUCCESSFUL - % enhanced policies restored', policy_count;
        ELSE
            RAISE WARNING '❌ RLS POLICY ROLLBACK VERIFICATION FAILED - Expected %, found %', array_length(expected_policies, 1), policy_count;
        END IF;
    END;
    
    RAISE NOTICE '=== RLS POLICY ROLLBACK COMPLETE ===';
END $$;

-- ============================================================================
-- ROLLBACK FUNCTION 4: FUNCTION ROLLBACK
-- ============================================================================

CREATE OR REPLACE FUNCTION private.rollback_function_updates()
RETURNS VOID
LANGUAGE PLPGSQL SECURITY DEFINER  
SET search_path = ''
AS $$
BEGIN
    RAISE NOTICE '=== FUNCTION ROLLBACK START ===';
    
    -- Restore handle_new_user() to use legacy default role
    CREATE OR REPLACE FUNCTION handle_new_user()
    RETURNS trigger AS $func$
    BEGIN
      INSERT INTO public.user_profiles (id, role, status, business_info)
      VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'role', 'practitioner'), -- Restored legacy default
        'pending_verification',
        COALESCE(NEW.raw_user_meta_data->'business_info', '{}')
      );
      RETURN NEW;
    END;
    $func$ language plpgsql security definer;
    
    RAISE NOTICE '✅ handle_new_user() function restored to use legacy default role';
    
    -- Remove temporary compatibility function
    DROP FUNCTION IF EXISTS private.normalize_role_value(TEXT);
    RAISE NOTICE '✅ Temporary compatibility function removed';
    
    -- Verify function rollback
    DECLARE
        func_source TEXT;
    BEGIN
        SELECT prosrc INTO func_source
        FROM pg_proc 
        WHERE proname = 'handle_new_user'
        AND pronamespace = 'public'::regnamespace;
        
        IF func_source LIKE '%practitioner%' AND NOT func_source LIKE '%tcm_practitioner%' THEN
            RAISE NOTICE '✅ FUNCTION ROLLBACK SUCCESSFUL - Legacy default role restored';
        ELSE
            RAISE WARNING '❌ FUNCTION ROLLBACK VERIFICATION FAILED';
        END IF;
    END;
    
    RAISE NOTICE '=== FUNCTION ROLLBACK COMPLETE ===';
END $$;

-- ============================================================================
-- MASTER ROLLBACK FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION private.rollback_task_13a_complete()
RETURNS VOID
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RAISE NOTICE '=== TASK 1.3A COMPLETE ROLLBACK START ===';
    RAISE NOTICE 'Rolling back all Task 1.3A changes in reverse order...';
    
    -- Step 1: Rollback RLS policies (must be first to avoid constraint conflicts)
    BEGIN
        PERFORM private.rollback_rls_policies();
        RAISE NOTICE '✅ Step 1: RLS policies rolled back';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '⚠️ Step 1 failed: %', SQLERRM;
    END;
    
    -- Step 2: Rollback data normalization (before constraint changes)
    BEGIN
        PERFORM private.rollback_data_normalization();
        RAISE NOTICE '✅ Step 2: Data normalization rolled back';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '⚠️ Step 2 failed: %', SQLERRM;
    END;
    
    -- Step 3: Rollback constraint changes (after data is compatible)
    BEGIN
        PERFORM private.rollback_constraint_changes();
        RAISE NOTICE '✅ Step 3: Constraint changes rolled back';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '⚠️ Step 3 failed: %', SQLERRM;
    END;
    
    -- Step 4: Rollback function updates
    BEGIN
        PERFORM private.rollback_function_updates();
        RAISE NOTICE '✅ Step 4: Function updates rolled back';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '⚠️ Step 4 failed: %', SQLERRM;
    END;
    
    RAISE NOTICE '=== TASK 1.3A COMPLETE ROLLBACK FINISHED ===';
    RAISE NOTICE 'System should now be restored to pre-Task 1.3A state';
    RAISE NOTICE 'Recommendation: Run verification queries to confirm rollback success';
END $$;

-- ============================================================================
-- ROLLBACK VERIFICATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION private.verify_rollback_success()
RETURNS TABLE (
    component TEXT,
    status TEXT,
    details TEXT
)
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RAISE NOTICE '=== ROLLBACK VERIFICATION ===';
    
    -- Check constraints
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'user_profiles'::regclass 
        AND conname = 'user_profiles_role_check'
    ) THEN
        RETURN QUERY SELECT 'Constraints'::TEXT, '✅ SUCCESS'::TEXT, 'Legacy constraint active'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Constraints'::TEXT, '❌ FAILED'::TEXT, 'Legacy constraint missing'::TEXT;
    END IF;
    
    -- Check data values
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE role IN ('tcm_practitioner', 'pharmacy')
    ) THEN
        RETURN QUERY SELECT 'Data Values'::TEXT, '✅ SUCCESS'::TEXT, 'All canonical values rolled back'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Data Values'::TEXT, '❌ FAILED'::TEXT, 'Some canonical values remain'::TEXT;
    END IF;
    
    -- Check RLS policies  
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' 
        AND policyname LIKE 'enhanced_%'
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' 
        AND policyname LIKE 'rls_basic_%'
    ) THEN
        RETURN QUERY SELECT 'RLS Policies'::TEXT, '✅ SUCCESS'::TEXT, 'Enhanced policies restored'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS Policies'::TEXT, '❌ FAILED'::TEXT, 'Policy state incorrect'::TEXT;
    END IF;
    
    -- Check functions
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'handle_new_user'
        AND prosrc LIKE '%practitioner%'
        AND prosrc NOT LIKE '%tcm_practitioner%'
    ) THEN
        RETURN QUERY SELECT 'Functions'::TEXT, '✅ SUCCESS'::TEXT, 'Legacy default role restored'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Functions'::TEXT, '❌ FAILED'::TEXT, 'Function not rolled back properly'::TEXT;
    END IF;
END $$;

-- ============================================================================
-- ROLLBACK FUNCTION METADATA
-- ============================================================================

COMMENT ON FUNCTION private.rollback_constraint_changes() IS 
    'Rollback Task 1.3A constraint changes: canonical -> legacy role constraint';

COMMENT ON FUNCTION private.rollback_data_normalization() IS 
    'Rollback Task 1.3A data changes: canonical -> legacy role values'; 

COMMENT ON FUNCTION private.rollback_rls_policies() IS 
    'Rollback Task 1.3A RLS policies: role-specific -> enhanced policies';

COMMENT ON FUNCTION private.rollback_function_updates() IS 
    'Rollback Task 1.3A function changes: canonical -> legacy defaults';

COMMENT ON FUNCTION private.rollback_task_13a_complete() IS 
    'Complete rollback of all Task 1.3A changes in correct order';

COMMENT ON FUNCTION private.verify_rollback_success() IS 
    'Verify successful rollback of Task 1.3A changes across all components';

-- Usage Examples:
--
-- Rollback individual components:
-- SELECT private.rollback_constraint_changes();
-- SELECT private.rollback_data_normalization(); 
-- SELECT private.rollback_rls_policies();
-- SELECT private.rollback_function_updates();
--
-- Complete rollback:
-- SELECT private.rollback_task_13a_complete();
--
-- Verify rollback:
-- SELECT * FROM private.verify_rollback_success();

-- Log completion
SELECT NOW() as rollback_functions_created,
       'Rollback Functions' as component,
       'EMERGENCY RECOVERY READY' as status;