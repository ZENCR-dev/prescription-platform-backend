-- ============================================================================
-- ROLLBACK SCRIPT: User Profiles Business Fields Extension
-- ============================================================================
-- Safe rollback for 20250104_extend_user_profiles_business_fields.sql
-- Execute this script to completely remove all changes made by the migration
-- 
-- WARNING: This will permanently delete all data in the added columns
-- BACKUP RECOMMENDATION: Export user_profiles table data before rollback

-- Phase 1: Remove triggers and functions
DROP TRIGGER IF EXISTS sync_license_verification_on_update ON user_profiles;
DROP FUNCTION IF EXISTS sync_license_verification_status();

-- Phase 2: Remove all new RLS policies
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile with restrictions" ON user_profiles;
DROP POLICY IF EXISTS "Admin can view all profiles for verification" ON user_profiles;
DROP POLICY IF EXISTS "Admin can update verification status" ON user_profiles;
DROP POLICY IF EXISTS "Profile creation with role validation" ON user_profiles;
DROP POLICY IF EXISTS "Only admin can delete user profiles" ON user_profiles;

-- Phase 3: Remove all performance indexes
DROP INDEX IF EXISTS idx_user_profiles_compliance_flags_gin;
DROP INDEX IF EXISTS idx_user_profiles_verification_docs_gin;
DROP INDEX IF EXISTS idx_user_profiles_business_address_gin;
DROP INDEX IF EXISTS idx_user_profiles_role_status_verification;
DROP INDEX IF EXISTS idx_user_profiles_verification_admin;
DROP INDEX IF EXISTS idx_user_profiles_verification_status;
DROP INDEX IF EXISTS idx_user_profiles_business_name;
DROP INDEX IF EXISTS idx_user_profiles_license_expiry;
DROP INDEX IF EXISTS idx_user_profiles_license_status;
DROP INDEX IF EXISTS idx_user_profiles_license_number;

-- Phase 4: Remove all constraints (in reverse dependency order)
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_license_verification_integration;
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_verification_consistency;
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_professional_role_license;
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_license_number_format;
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_license_status;
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS check_license_type;

-- Phase 5: Remove all added columns
-- Compliance and audit fields
ALTER TABLE user_profiles DROP COLUMN IF EXISTS compliance_flags;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS verified_at;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS verified_by;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS verification_notes;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS verification_documents;

-- Verification status fields
ALTER TABLE user_profiles DROP COLUMN IF EXISTS professional_verified;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS business_verified;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS identity_verified;

-- Business registration fields
ALTER TABLE user_profiles DROP COLUMN IF EXISTS business_email;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS business_phone;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS business_address;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS tax_identification;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS business_registration_number;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS business_name;

-- Professional license fields
ALTER TABLE user_profiles DROP COLUMN IF EXISTS license_verification_id;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS license_expiry_date;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS license_status;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS license_type;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS license_number;

-- Phase 6: Restore original RLS policies
-- Original Policy: Users can view their own profile
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

-- Original Policy: Users can update their own profile
CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Original Policy: Admin can insert user profiles or users can create their own
CREATE POLICY "Admin can insert user profiles" ON user_profiles
    FOR INSERT WITH CHECK (
        -- Admin users can create any profile
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
        OR 
        -- Users can create their own initial profile (first time only)
        auth.uid() = id
    );

-- Original Policy: Only admin can delete user profiles
CREATE POLICY "Only admin can delete user profiles" ON user_profiles
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Phase 7: Log rollback completion
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    gen_random_uuid(),
    jsonb_build_object(
        'event', 'schema_rollback',
        'migration_rolled_back', '20250104_extend_user_profiles_business_fields',
        'description', 'Rolled back user_profiles business fields extension',
        'columns_removed', 16,
        'policies_restored', 4,
        'indexes_removed', 9,
        'constraints_removed', 6,
        'functions_removed', 1,
        'triggers_removed', 1
    ),
    NOW()
);

-- Rollback verification queries (run manually to verify rollback success)
-- 
-- -- Check that all new columns have been removed:
-- SELECT column_name 
-- FROM information_schema.columns 
-- WHERE table_name = 'user_profiles' 
-- AND table_schema = 'public'
-- AND column_name IN (
--     'license_number', 'license_type', 'license_status', 'license_expiry_date',
--     'license_verification_id', 'business_name', 'business_registration_number',
--     'tax_identification', 'business_address', 'business_phone', 'business_email',
--     'identity_verified', 'business_verified', 'professional_verified',
--     'verification_documents', 'verification_notes', 'verified_by', 'verified_at',
--     'compliance_flags'
-- );
-- -- Expected result: 0 rows (all columns should be gone)
--
-- -- Check that original policies are restored:
-- SELECT policyname 
-- FROM pg_policies 
-- WHERE tablename = 'user_profiles' 
-- AND schemaname = 'public';
-- -- Expected result: 4 policies matching original names
--
-- -- Check that all new indexes are removed:
-- SELECT indexname 
-- FROM pg_indexes 
-- WHERE tablename = 'user_profiles' 
-- AND schemaname = 'public'
-- AND indexname LIKE 'idx_user_profiles_%';
-- -- Expected result: Only original indexes (not the new business field indexes)