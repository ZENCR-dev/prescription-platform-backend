-- ============================================================================
-- Rollback: Task 1.3B RLS Extension Policies on Base Table (CORRECTED)
-- ============================================================================
-- Complete rollback of 20250905180700_rls_ext_policies_on_base_table migration
-- Target: Remove RLS policies from user_profiles base table safely
-- Scope: Clean removal of cross-role business access policies
-- ============================================================================

-- ============================================================================
-- ROLLBACK VALIDATION: PRE-REMOVAL STATUS CHECK
-- ============================================================================

DO $$
DECLARE
    policy_count INTEGER;
    existing_policies TEXT[] := '{}';
    policy_name TEXT;
    target_policies TEXT[] := ARRAY[
        'cross_role_pharmacy_select',
        'cross_role_tcm_select', 
        'public_directory_select',
        'admin_comprehensive_select'
    ];
BEGIN
    RAISE NOTICE '=== ROLLBACK VALIDATION: PRE-REMOVAL STATUS ===';
    
    -- Check which target policies currently exist
    FOREACH policy_name IN ARRAY target_policies
    LOOP
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles'
        AND policyname = policy_name;
        
        IF policy_count > 0 THEN
            existing_policies := array_append(existing_policies, policy_name);
            RAISE NOTICE '🎯 Target policy found: %', policy_name;
        ELSE
            RAISE NOTICE '⚠️ Policy not found: % (may have been manually removed)', policy_name;
        END IF;
    END LOOP;
    
    -- Summary of rollback scope
    IF array_length(existing_policies, 1) > 0 THEN
        RAISE NOTICE '✅ Rollback scope: % policies will be removed', array_length(existing_policies, 1);
        RAISE NOTICE 'Policies to remove: %', array_to_string(existing_policies, ', ');
    ELSE
        RAISE NOTICE '⚠️ No target policies found - rollback may be unnecessary';
    END IF;
END $$;

-- ============================================================================
-- POLICY REMOVAL: SAFE CASCADING REMOVAL
-- ============================================================================

-- Remove Policy 4: Admin Comprehensive Select
DROP POLICY IF EXISTS "admin_comprehensive_select" ON user_profiles;

-- Remove Policy 3: Public Directory Select  
DROP POLICY IF EXISTS "public_directory_select" ON user_profiles;

-- Remove Policy 2: Cross-Role TCM Select
DROP POLICY IF EXISTS "cross_role_tcm_select" ON user_profiles;

-- Remove Policy 1: Cross-Role Pharmacy Select  
DROP POLICY IF EXISTS "cross_role_pharmacy_select" ON user_profiles;

-- ============================================================================
-- ROLLBACK VERIFICATION: POST-REMOVAL STATUS CHECK
-- ============================================================================

DO $$
DECLARE
    remaining_policy_count INTEGER;
    total_policies_on_table INTEGER;
    policy_name TEXT;
    remaining_policies TEXT[] := '{}';
    target_policies TEXT[] := ARRAY[
        'cross_role_pharmacy_select',
        'cross_role_tcm_select', 
        'public_directory_select',
        'admin_comprehensive_select'
    ];
BEGIN
    RAISE NOTICE '=== ROLLBACK VERIFICATION: POST-REMOVAL STATUS ===';
    
    -- Check if any target policies still exist
    FOREACH policy_name IN ARRAY target_policies
    LOOP
        IF EXISTS (
            SELECT FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = 'user_profiles'
            AND policyname = policy_name
        ) THEN
            remaining_policies := array_append(remaining_policies, policy_name);
        END IF;
    END LOOP;
    
    -- Count remaining target policies
    remaining_policy_count := array_length(remaining_policies, 1);
    IF remaining_policy_count IS NULL THEN
        remaining_policy_count := 0;
    END IF;
    
    -- Count total policies still on user_profiles table
    SELECT COUNT(*) INTO total_policies_on_table
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles';
    
    -- Validation results
    IF remaining_policy_count = 0 THEN
        RAISE NOTICE '✅ ROLLBACK SUCCESSFUL: All target policies removed';
        RAISE NOTICE '📊 Remaining policies on user_profiles table: %', total_policies_on_table;
    ELSE
        RAISE EXCEPTION 'ROLLBACK FAILED: % target policies still exist: %', 
            remaining_policy_count, array_to_string(remaining_policies, ', ');
    END IF;
    
    -- Note about controlled views
    RAISE NOTICE '🔍 IMPORTANT: Controlled views (v_profiles_*) remain unchanged';
    RAISE NOTICE '🔍 Views will no longer have inherited RLS security from base table';
    RAISE NOTICE '🔍 Views now rely on their own access patterns (if any)';
END $$;

-- ============================================================================
-- SYSTEM STATE VERIFICATION: ARCHITECTURE STATUS
-- ============================================================================

-- Verify the overall system state after rollback
DO $$
DECLARE
    helper_function_count INTEGER;
    controlled_view_count INTEGER;
    base_table_policy_count INTEGER;
BEGIN
    RAISE NOTICE '=== SYSTEM STATE AFTER ROLLBACK ===';
    
    -- Helper functions should remain (they weren't created by this migration)
    SELECT COUNT(*) INTO helper_function_count
    FROM pg_proc 
    WHERE proname IN (
        'has_prescription_business_relationship',
        'has_referral_business_relationship'
    )
    AND pronamespace = 'private'::regnamespace
    AND prosecdef = true;
    
    -- Controlled views should remain (they weren't created by this migration)
    SELECT COUNT(*) INTO controlled_view_count
    FROM pg_views 
    WHERE schemaname = 'public' 
    AND viewname IN (
        'v_profiles_pharmacy_context',
        'v_profiles_tcm_context',
        'v_profiles_public'
    );
    
    -- Base table policies from our migration should be gone
    SELECT COUNT(*) INTO base_table_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
    AND policyname IN (
        'cross_role_pharmacy_select',
        'cross_role_tcm_select',
        'public_directory_select',
        'admin_comprehensive_select'
    );
    
    -- Report system state
    RAISE NOTICE 'Component Status After Rollback:';
    RAISE NOTICE '  - Helper Functions: % (unchanged - not managed by this migration)', helper_function_count;
    RAISE NOTICE '  - Controlled Views: % (unchanged - not managed by this migration)', controlled_view_count;
    RAISE NOTICE '  - Target Base Table Policies: % (should be 0)', base_table_policy_count;
    
    -- Final validation
    IF base_table_policy_count = 0 THEN
        RAISE NOTICE '✅ ARCHITECTURE ROLLBACK COMPLETE: Base table RLS policies removed successfully';
    ELSE
        RAISE EXCEPTION 'ARCHITECTURE ROLLBACK INCOMPLETE: % base table policies still exist', base_table_policy_count;
    END IF;
END $$;

-- ============================================================================
-- ROLLBACK COMPLETION LOG  
-- ============================================================================

-- Log successful rollback completion
SELECT NOW() as rollback_completed,
       'Task 1.3B Rollback: RLS Policies Removed from Base Table' as task,
       'BASE TABLE RLS POLICIES SUCCESSFULLY REMOVED - CONTROLLED VIEWS UNAFFECTED' as status;

-- Add audit record for rollback completion
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    gen_random_uuid(),
    jsonb_build_object(
        'event', 'task_1_3b_base_table_rls_rollback',
        'migration_file', 'rollback_20250905180700_rls_ext_policies_on_base_table.sql',
        'description', 'Rolled back RLS policies from user_profiles base table',
        'policies_removed', ARRAY[
            'cross_role_pharmacy_select',
            'cross_role_tcm_select', 
            'public_directory_select',
            'admin_comprehensive_select'
        ],
        'rollback_scope', 'base_table_policies_only',
        'controlled_views_status', 'unchanged',
        'helper_functions_status', 'unchanged'
    ),
    NOW()
);

-- Rollback completion summary
DO $$
BEGIN
    RAISE NOTICE '==================================================================';
    RAISE NOTICE 'ROLLBACK COMPLETED: 20250905180700_rls_ext_policies_on_base_table';  
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '✅ All 4 RLS policies removed from user_profiles base table';
    RAISE NOTICE '✅ Controlled views remain unchanged (v_profiles_*)';
    RAISE NOTICE '✅ Helper functions remain unchanged (private schema)';
    RAISE NOTICE '✅ System restored to pre-migration state';
    RAISE NOTICE 'Architecture Impact: Views no longer inherit RLS from base table';
    RAISE NOTICE 'Next Steps: Can safely re-apply migration or implement alternative approach';
    RAISE NOTICE '==================================================================';
END $$;