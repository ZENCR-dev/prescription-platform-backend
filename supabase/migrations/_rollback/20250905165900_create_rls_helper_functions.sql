-- ============================================================================
-- RLS Helper Functions for Role-Specific Field Validation
-- ============================================================================
-- Creates validation functions needed for Task 1.3A RLS policies
-- Must be executed BEFORE 20250905170000_implement_rls_basic_policies_role_consistency.sql
-- 
-- Functions created:
-- - check_tcm_fields_only_updated(OLD, NEW) -> boolean
-- - check_pharmacy_fields_only_updated(OLD, NEW) -> boolean  
-- - check_admin_fields_only_updated(OLD, NEW) -> boolean
-- - enhanced audit logging function

-- ============================================================================
-- ROLE-SPECIFIC FIELD GROUPS DEFINITION
-- ============================================================================

-- Field groups based on Task 1.2 role-specific profile fields implementation:
-- 
-- BASIC FIELDS (all roles can modify):
-- - id, role, status, business_info, created_at, updated_at
-- 
-- TCM-SPECIFIC FIELDS (only tcm_practitioner can modify):  
-- - tcm_specialty, tcm_practice_years, tcm_certification_level, tcm_clinic_affiliation
-- 
-- PHARMACY-SPECIFIC FIELDS (only pharmacy can modify):
-- - pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit
-- 
-- ADMIN-SPECIFIC FIELDS (only admin can modify):
-- - admin_level, admin_scope, admin_certification_date, admin_supervisor_id

-- ============================================================================
-- TCM FIELD VALIDATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION private.check_tcm_fields_only_updated(
    old_record user_profiles,
    new_record user_profiles  
)
RETURNS BOOLEAN
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- Allow changes to basic fields (always permitted)
    -- Allow changes to TCM-specific fields (role-specific permission)
    -- DENY changes to Pharmacy-specific or Admin-specific fields (cross-role isolation)
    
    -- Check if any Pharmacy-specific fields were modified (FORBIDDEN)
    IF (old_record.pharmacy_type IS DISTINCT FROM new_record.pharmacy_type) OR
       (old_record.pharmacy_license_scope IS DISTINCT FROM new_record.pharmacy_license_scope) OR
       (old_record.pharmacy_location_count IS DISTINCT FROM new_record.pharmacy_location_count) OR
       (old_record.controlled_substance_permit IS DISTINCT FROM new_record.controlled_substance_permit) THEN
        
        RAISE WARNING 'TCM user attempted to modify pharmacy fields - DENIED';
        RETURN FALSE;
    END IF;
    
    -- Check if any Admin-specific fields were modified (FORBIDDEN)
    IF (old_record.admin_level IS DISTINCT FROM new_record.admin_level) OR
       (old_record.admin_scope IS DISTINCT FROM new_record.admin_scope) OR  
       (old_record.admin_certification_date IS DISTINCT FROM new_record.admin_certification_date) OR
       (old_record.admin_supervisor_id IS DISTINCT FROM new_record.admin_supervisor_id) THEN
        
        RAISE WARNING 'TCM user attempted to modify admin fields - DENIED';
        RETURN FALSE;
    END IF;
    
    -- If we reach here, only basic fields and/or TCM fields were modified (ALLOWED)
    RETURN TRUE;
END $$;

-- ============================================================================
-- PHARMACY FIELD VALIDATION FUNCTION  
-- ============================================================================

CREATE OR REPLACE FUNCTION private.check_pharmacy_fields_only_updated(
    old_record user_profiles,
    new_record user_profiles
)
RETURNS BOOLEAN  
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- Allow changes to basic fields (always permitted)
    -- Allow changes to Pharmacy-specific fields (role-specific permission)
    -- DENY changes to TCM-specific or Admin-specific fields (cross-role isolation)
    
    -- Check if any TCM-specific fields were modified (FORBIDDEN)
    IF (old_record.tcm_specialty IS DISTINCT FROM new_record.tcm_specialty) OR
       (old_record.tcm_practice_years IS DISTINCT FROM new_record.tcm_practice_years) OR
       (old_record.tcm_certification_level IS DISTINCT FROM new_record.tcm_certification_level) OR
       (old_record.tcm_clinic_affiliation IS DISTINCT FROM new_record.tcm_clinic_affiliation) THEN
        
        RAISE WARNING 'Pharmacy user attempted to modify TCM fields - DENIED';
        RETURN FALSE;
    END IF;
    
    -- Check if any Admin-specific fields were modified (FORBIDDEN)
    IF (old_record.admin_level IS DISTINCT FROM new_record.admin_level) OR
       (old_record.admin_scope IS DISTINCT FROM new_record.admin_scope) OR
       (old_record.admin_certification_date IS DISTINCT FROM new_record.admin_certification_date) OR
       (old_record.admin_supervisor_id IS DISTINCT FROM new_record.admin_supervisor_id) THEN
        
        RAISE WARNING 'Pharmacy user attempted to modify admin fields - DENIED';  
        RETURN FALSE;
    END IF;
    
    -- If we reach here, only basic fields and/or Pharmacy fields were modified (ALLOWED)
    RETURN TRUE;
END $$;

-- ============================================================================
-- ADMIN FIELD VALIDATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION private.check_admin_fields_only_updated(
    old_record user_profiles,
    new_record user_profiles
)
RETURNS BOOLEAN
LANGUAGE PLPGSQL SECURITY DEFINER  
SET search_path = ''
AS $$
BEGIN
    -- Admin users editing their OWN profile should follow same isolation rules
    -- (Admin special privileges are handled at the policy level, not function level)
    -- This function is only called when admin is editing their own profile as regular user
    
    -- When admin edits their own profile, they should only modify basic + admin fields
    -- Check if any TCM-specific fields were modified (FORBIDDEN for admin's own profile)
    IF (old_record.tcm_specialty IS DISTINCT FROM new_record.tcm_specialty) OR
       (old_record.tcm_practice_years IS DISTINCT FROM new_record.tcm_practice_years) OR
       (old_record.tcm_certification_level IS DISTINCT FROM new_record.tcm_certification_level) OR
       (old_record.tcm_clinic_affiliation IS DISTINCT FROM new_record.tcm_clinic_affiliation) THEN
        
        RAISE WARNING 'Admin user attempted to modify TCM fields on own profile - DENIED';
        RETURN FALSE;
    END IF;
    
    -- Check if any Pharmacy-specific fields were modified (FORBIDDEN for admin's own profile)
    IF (old_record.pharmacy_type IS DISTINCT FROM new_record.pharmacy_type) OR
       (old_record.pharmacy_license_scope IS DISTINCT FROM new_record.pharmacy_license_scope) OR
       (old_record.pharmacy_location_count IS DISTINCT FROM new_record.pharmacy_location_count) OR
       (old_record.controlled_substance_permit IS DISTINCT FROM new_record.controlled_substance_permit) THEN
        
        RAISE WARNING 'Admin user attempted to modify pharmacy fields on own profile - DENIED';
        RETURN FALSE;
    END IF;
    
    -- If we reach here, only basic fields and/or Admin fields were modified (ALLOWED)
    RETURN TRUE;
END $$;

-- ============================================================================
-- ENHANCED AUDIT LOGGING FUNCTION (UPDATED)
-- ============================================================================

-- Update the existing audit function to support new operations and role consistency
CREATE OR REPLACE FUNCTION private.log_admin_profile_access(
    accessed_user_id UUID,
    operation_type TEXT
)
RETURNS UUID  -- Return a UUID to satisfy IS NOT NULL checks in policies
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    admin_user_id UUID;
    log_entry_id UUID;
BEGIN
    -- Get current admin user ID
    admin_user_id := auth.uid();
    
    -- Generate log entry ID for tracking
    log_entry_id := gen_random_uuid();
    
    -- Enhanced logging with more details
    RAISE NOTICE 'AUDIT LOG [%]: Admin Access - Admin ID: %, Target User: %, Operation: %, Timestamp: %',
        log_entry_id,
        admin_user_id, 
        accessed_user_id, 
        operation_type, 
        NOW();
    
    -- TODO: In production, write to audit_logs table:
    -- INSERT INTO audit_logs (id, admin_user_id, target_user_id, operation_type, timestamp)
    -- VALUES (log_entry_id, admin_user_id, accessed_user_id, operation_type, NOW());
    
    -- Return the log entry ID to satisfy IS NOT NULL policy checks
    RETURN log_entry_id;
END $$;

-- ============================================================================
-- FUNCTION VALIDATION AND TESTING
-- ============================================================================

-- Test that all functions are created and callable
DO $$
DECLARE
    test_old_record user_profiles;
    test_new_record user_profiles;
    result BOOLEAN;
    audit_result UUID;
BEGIN
    RAISE NOTICE '=== FUNCTION VALIDATION TESTS ===';
    
    -- Initialize test records with default values
    test_old_record.tcm_specialty := 'acupuncture'::tcm_specialty_enum;
    test_old_record.pharmacy_type := 'retail_pharmacy'::pharmacy_type_enum;
    test_old_record.admin_level := 'super_admin'::admin_level_enum;
    
    test_new_record := test_old_record;
    test_new_record.tcm_specialty := 'herbal_medicine'::tcm_specialty_enum; -- TCM field change
    
    -- Test 1: TCM validation function
    BEGIN
        result := private.check_tcm_fields_only_updated(test_old_record, test_new_record);
        RAISE NOTICE '✅ check_tcm_fields_only_updated() - callable, result: %', result;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ check_tcm_fields_only_updated() - error: %', SQLERRM;
    END;
    
    -- Test 2: Pharmacy validation function  
    BEGIN
        result := private.check_pharmacy_fields_only_updated(test_old_record, test_new_record);
        RAISE NOTICE '✅ check_pharmacy_fields_only_updated() - callable, result: %', result;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ check_pharmacy_fields_only_updated() - error: %', SQLERRM;
    END;
    
    -- Test 3: Admin validation function
    BEGIN  
        result := private.check_admin_fields_only_updated(test_old_record, test_new_record);
        RAISE NOTICE '✅ check_admin_fields_only_updated() - callable, result: %', result;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ check_admin_fields_only_updated() - error: %', SQLERRM;
    END;
    
    -- Test 4: Audit logging function
    BEGIN
        audit_result := private.log_admin_profile_access(gen_random_uuid(), 'TEST');
        RAISE NOTICE '✅ log_admin_profile_access() - callable, result: %', audit_result;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ log_admin_profile_access() - error: %', SQLERRM;
    END;
    
    RAISE NOTICE '=== FUNCTION VALIDATION COMPLETE ===';
END $$;

-- ============================================================================
-- FUNCTION METADATA AND DOCUMENTATION
-- ============================================================================

-- Add function comments for documentation
COMMENT ON FUNCTION private.check_tcm_fields_only_updated(user_profiles, user_profiles) IS 
    'Validates that TCM practitioners can only modify basic fields and TCM-specific fields, not pharmacy or admin fields';

COMMENT ON FUNCTION private.check_pharmacy_fields_only_updated(user_profiles, user_profiles) IS 
    'Validates that pharmacy users can only modify basic fields and pharmacy-specific fields, not TCM or admin fields';

COMMENT ON FUNCTION private.check_admin_fields_only_updated(user_profiles, user_profiles) IS 
    'Validates that admin users editing their own profile can only modify basic fields and admin-specific fields';

COMMENT ON FUNCTION private.log_admin_profile_access(UUID, TEXT) IS 
    'Enhanced audit logging for admin profile access with operation tracking and unique log entry IDs';

-- Log completion
SELECT NOW() as helper_functions_created,
       'RLS Helper Functions' as component,
       'READY FOR MAIN MIGRATION' as status;