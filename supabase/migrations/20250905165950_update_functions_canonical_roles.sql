-- ============================================================================
-- Update Functions to Use Canonical Role Values  
-- ============================================================================
-- Updates handle_new_user() function to use canonical default role
-- Must be executed BEFORE 20250905170000_implement_rls_basic_policies_role_consistency.sql
--
-- Changes:
-- - handle_new_user() default role: 'practitioner' -> 'tcm_practitioner'
-- - Ensures compatibility with canonical role constraint
-- - get_current_user_role() already returns canonical values from database

-- ============================================================================
-- UPDATE HANDLE_NEW_USER FUNCTION
-- ============================================================================

-- Replace the existing handle_new_user function with canonical default role
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, role, status, business_info)
  VALUES (
    NEW.id,
    -- Updated to use canonical default role
    COALESCE(NEW.raw_user_meta_data->>'role', 'tcm_practitioner'), -- Default role: tcm_practitioner (canonical)
    'pending_verification', -- New users need verification
    COALESCE(NEW.raw_user_meta_data->'business_info', '{}')
  );
  RETURN NEW;
END;
$$ language plpgsql security definer;

-- ============================================================================
-- VERIFICATION OF FUNCTION UPDATES
-- ============================================================================

-- Verify the function was updated correctly
DO $$
DECLARE
    func_source TEXT;
BEGIN
    RAISE NOTICE '=== FUNCTION UPDATE VERIFICATION ===';
    
    -- Get the function source to verify it contains canonical role
    SELECT prosrc INTO func_source
    FROM pg_proc 
    WHERE proname = 'handle_new_user'
    AND pronamespace = 'public'::regnamespace;
    
    -- Check if the function contains the canonical default role
    IF func_source LIKE '%tcm_practitioner%' THEN
        RAISE NOTICE '✅ handle_new_user() function updated successfully - uses canonical default role';
        RAISE NOTICE '   Default role changed: ''practitioner'' -> ''tcm_practitioner''';
    ELSE
        RAISE WARNING '❌ handle_new_user() function may not be updated correctly';
        RAISE WARNING '   Function source: %', func_source;
    END IF;
    
    -- Verify get_current_user_role() exists and is ready (doesn't need updating)
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_current_user_role'
        AND pronamespace = 'private'::regnamespace
    ) THEN
        RAISE NOTICE '✅ private.get_current_user_role() function exists - returns canonical values from database';
    ELSE
        RAISE WARNING '❌ private.get_current_user_role() function not found';
    END IF;
    
    RAISE NOTICE '=== FUNCTION UPDATE VERIFICATION COMPLETE ===';
END $$;

-- ============================================================================
-- COMPATIBILITY MAPPING FUNCTION (TEMPORARY)
-- ============================================================================

-- Create a temporary compatibility function to handle role mapping during transition
-- This function can help with any legacy code that might still use old role values
CREATE OR REPLACE FUNCTION private.normalize_role_value(input_role TEXT)
RETURNS TEXT
LANGUAGE SQL IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE 
    WHEN input_role = 'practitioner' THEN 'tcm_practitioner'
    WHEN input_role = 'pharmacy_operator' THEN 'pharmacy'  
    WHEN input_role = 'admin' THEN 'admin'
    WHEN input_role IN ('tcm_practitioner', 'pharmacy') THEN input_role  -- Already canonical
    ELSE 'tcm_practitioner'  -- Default fallback to canonical default
  END;
$$;

-- Add function comment
COMMENT ON FUNCTION private.normalize_role_value(TEXT) IS 
    'Temporary compatibility function to normalize legacy role values to canonical format. Used during migration transition period.';

-- ============================================================================
-- FUNCTION UPDATE METADATA
-- ============================================================================

-- Update function comments to reflect canonical role usage
COMMENT ON FUNCTION handle_new_user() IS 
    'Automatically creates user profile on registration. Updated in Task 1.3A to use canonical default role: tcm_practitioner';

COMMENT ON FUNCTION private.get_current_user_role() IS 
    'Returns current user role from database. Compatible with canonical role values after Task 1.3A data normalization';

-- Log completion
SELECT NOW() as functions_updated,
       'Function Updates' as component,
       'CANONICAL ROLES IMPLEMENTED' as status;