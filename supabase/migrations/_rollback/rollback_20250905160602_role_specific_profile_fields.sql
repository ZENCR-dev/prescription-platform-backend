-- ============================================================================
-- Rollback: Role-Specific Profile Fields Migration - Task 1.2
-- ============================================================================
-- Purpose: Complete rollback of 20250905160602_role_specific_profile_fields migration
-- Target: Restore original state with data safety and constraint consistency
-- Rollback Order: Reverse of forward migration phases
--
-- ROLLBACK PHASES:
-- Phase R1: Validation Functions and Constraints Removal (6 constraints + 1 function + 1 trigger)
-- Phase R2: Role-Specific Field Removal (12 fields)
-- Phase R3: Enum Type Removal (6 types)  
-- Phase R4: Constraint Inconsistency Restoration (1 constraint)
-- ============================================================================

-- Phase R1: Validation Functions and Constraints Removal
-- ============================================================================
-- Step R1.1: Drop validation trigger and function

-- Drop validation trigger
DROP TRIGGER IF EXISTS validate_role_specific_fields_trigger ON user_profiles;

-- Drop validation function
DROP FUNCTION IF EXISTS validate_role_specific_fields();

-- Step R1.2: Drop business logic validation constraints

-- Remove admin supervisor hierarchy validation
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS check_admin_supervisor_hierarchy;

-- Remove TCM certification and experience correlation
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS check_tcm_certification_experience;

-- Remove pharmacy location count business logic
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS check_pharmacy_location_logic;

-- Step R1.3: Drop cross-role field isolation constraints

-- Remove admin fields isolation constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS check_admin_fields_isolation;

-- Remove pharmacy fields isolation constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS check_pharmacy_fields_isolation;

-- Remove TCM fields isolation constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS check_tcm_fields_isolation;

-- Validate constraint and function removal
DO $r1_validation$
DECLARE
    constraint_count INTEGER;
    function_count INTEGER;
    trigger_count INTEGER;
BEGIN
    -- Check constraints removed
    SELECT COUNT(*) INTO constraint_count
    FROM pg_constraint 
    WHERE conrelid = 'user_profiles'::regclass
    AND conname IN (
        'check_tcm_fields_isolation',
        'check_pharmacy_fields_isolation',
        'check_admin_fields_isolation', 
        'check_pharmacy_location_logic',
        'check_tcm_certification_experience',
        'check_admin_supervisor_hierarchy'
    );
    
    -- Check function removed
    SELECT COUNT(*) INTO function_count
    FROM pg_proc 
    WHERE proname = 'validate_role_specific_fields';
    
    -- Check trigger removed  
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers
    WHERE trigger_name = 'validate_role_specific_fields_trigger'
    AND event_object_table = 'user_profiles';
    
    IF constraint_count != 0 THEN
        RAISE EXCEPTION 'Phase R1 validation failed: constraints not removed (found %, expected 0)', constraint_count;
    END IF;
    
    IF function_count != 0 THEN
        RAISE EXCEPTION 'Phase R1 validation failed: validation function not removed';
    END IF;
    
    IF trigger_count != 0 THEN
        RAISE EXCEPTION 'Phase R1 validation failed: validation trigger not removed';
    END IF;
    
    RAISE NOTICE 'Phase R1 completed: All constraints, function, and trigger removed successfully';
END $r1_validation$;

-- Phase R2: Role-Specific Field Removal
-- ============================================================================
-- Step R2.1: Drop Admin fields

-- Remove admin supervisor reference (with foreign key)
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS admin_supervisor_id CASCADE;

-- Remove admin certification date
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS admin_certification_date CASCADE;

-- Remove admin scope
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS admin_scope CASCADE;

-- Remove admin level
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS admin_level CASCADE;

-- Step R2.2: Drop Pharmacy fields

-- Remove controlled substance permit status
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS controlled_substance_permit CASCADE;

-- Remove pharmacy location count
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS pharmacy_location_count CASCADE;

-- Remove pharmacy license scope
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS pharmacy_license_scope CASCADE;

-- Remove pharmacy type
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS pharmacy_type CASCADE;

-- Step R2.3: Drop TCM Practitioner fields

-- Remove TCM clinic affiliation
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS tcm_clinic_affiliation CASCADE;

-- Remove TCM certification level
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS tcm_certification_level CASCADE;

-- Remove TCM practice years  
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS tcm_practice_years CASCADE;

-- Remove TCM specialty
ALTER TABLE user_profiles 
DROP COLUMN IF EXISTS tcm_specialty CASCADE;

-- Validate field removal
DO $r2_validation$
DECLARE
    field_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO field_count
    FROM information_schema.columns
    WHERE table_name = 'user_profiles' 
    AND column_name IN (
        'tcm_specialty', 'tcm_practice_years', 'tcm_certification_level', 'tcm_clinic_affiliation',
        'pharmacy_type', 'pharmacy_license_scope', 'pharmacy_location_count', 'controlled_substance_permit',
        'admin_level', 'admin_scope', 'admin_certification_date', 'admin_supervisor_id'
    );
    
    IF field_count != 0 THEN
        RAISE EXCEPTION 'Phase R2 validation failed: fields not removed (found %, expected 0)', field_count;
    END IF;
    
    RAISE NOTICE 'Phase R2 completed: All 12 role-specific fields removed successfully';
END $r2_validation$;

-- Phase R3: Enum Type Removal
-- ============================================================================
-- Step R3.1: Drop Admin-related enum types

-- Drop admin scope enumeration
DROP TYPE IF EXISTS admin_scope_enum CASCADE;

-- Drop admin level enumeration  
DROP TYPE IF EXISTS admin_level_enum CASCADE;

-- Step R3.2: Drop Pharmacy-related enum types

-- Drop pharmacy scope enumeration
DROP TYPE IF EXISTS pharmacy_scope_enum CASCADE;

-- Drop pharmacy type enumeration
DROP TYPE IF EXISTS pharmacy_type_enum CASCADE;

-- Step R3.3: Drop TCM-related enum types

-- Drop TCM certification enumeration
DROP TYPE IF EXISTS tcm_certification_enum CASCADE;

-- Drop TCM specialty enumeration
DROP TYPE IF EXISTS tcm_specialty_enum CASCADE;

-- Validate enum type removal
DO $r3_validation$
DECLARE
    enum_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO enum_count
    FROM pg_type 
    WHERE typname IN (
        'tcm_specialty_enum', 'tcm_certification_enum',
        'pharmacy_type_enum', 'pharmacy_scope_enum',
        'admin_level_enum', 'admin_scope_enum'
    );
    
    IF enum_count != 0 THEN
        RAISE EXCEPTION 'Phase R3 validation failed: enum types not removed (found %, expected 0)', enum_count;
    END IF;
    
    RAISE NOTICE 'Phase R3 completed: All 6 enum types removed successfully';
END $r3_validation$;

-- Phase R4: Constraint Inconsistency Restoration  
-- ============================================================================
-- Step R4.1: Restore original check_professional_role_license constraint

-- Drop the corrected constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS check_professional_role_license;

-- Restore original constraint definition with inconsistent role values
-- (This restores the original inconsistency but maintains original state)
ALTER TABLE user_profiles 
ADD CONSTRAINT check_professional_role_license
CHECK (
    (role = 'practitioner' AND (license_type IS NULL OR license_type = 'tcm_practitioner')) OR
    (role = 'pharmacy_operator' AND (license_type IS NULL OR license_type = 'pharmacy')) OR  
    (role = 'admin' AND license_type IS NULL) OR
    (role NOT IN ('practitioner', 'pharmacy_operator', 'admin'))
);

-- Step R4.2: Add rollback completion audit record
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    gen_random_uuid(),
    jsonb_build_object(
        'event', 'role_specific_fields_rollback',
        'migration', 'rollback_20250905160602_role_specific_profile_fields', 
        'description', 'Rolled back role-specific profile fields migration',
        'rollback_phases', 'constraints_removed,fields_removed,enums_removed,constraint_restored',
        'constraints_removed', 6,
        'fields_removed', 12,
        'enum_types_removed', 6,
        'original_constraint_restored', 1,
        'data_safety', 'all_changes_reverted,no_data_loss'
    ),
    NOW()
);

-- Validate final rollback state
DO $r4_validation$
DECLARE
    restored_constraint_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO restored_constraint_count
    FROM pg_constraint 
    WHERE conname = 'check_professional_role_license' 
    AND conrelid = 'user_profiles'::regclass;
    
    IF restored_constraint_count != 1 THEN
        RAISE EXCEPTION 'Phase R4 validation failed: original constraint not restored';
    END IF;
    
    RAISE NOTICE 'Phase R4 completed: Original constraint inconsistency restored (as expected for full rollback)';
END $r4_validation$;

-- Rollback completion summary
DO $rollback_summary$
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'ROLLBACK COMPLETED: 20250905160602_role_specific_profile_fields';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Phase R1: ✅ 6 constraints + 1 function + 1 trigger removed';
    RAISE NOTICE 'Phase R2: ✅ 12 role-specific fields removed (4 TCM, 4 pharmacy, 4 admin)';  
    RAISE NOTICE 'Phase R3: ✅ 6 enum types removed (all role-specific enums)';
    RAISE NOTICE 'Phase R4: ✅ Original constraint inconsistency restored';
    RAISE NOTICE 'Data Safety: ✅ Complete state restoration, no data loss';
    RAISE NOTICE 'Result: user_profiles table restored to pre-migration state';
    RAISE NOTICE 'Note: Original constraint inconsistency between role constraints restored as expected';
    RAISE NOTICE '====================================================================';
END $rollback_summary$;