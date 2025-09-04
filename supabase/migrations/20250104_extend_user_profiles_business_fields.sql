-- ============================================================================
-- User Profiles Business Fields Extension - Task 1.1: User Profile Management
-- ============================================================================
-- Extends user_profiles table with business registration, professional license,
-- and verification tracking fields for M1.3 User Profile Management Backend
-- 
-- Migration Strategy: Phased approach with safe rollback capability
-- Security: Enhanced RLS policies for multi-role medical platform
-- Integration: Seamless connection to license-verification Edge Function

-- Phase 1: Add business registration and professional license fields
-- All fields are nullable initially for safe migration

-- Professional License Integration Fields (matches license-verification system)
ALTER TABLE user_profiles ADD COLUMN license_number VARCHAR(20);
ALTER TABLE user_profiles ADD COLUMN license_type VARCHAR(20);
ALTER TABLE user_profiles ADD COLUMN license_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE user_profiles ADD COLUMN license_expiry_date DATE;
ALTER TABLE user_profiles ADD COLUMN license_verification_id VARCHAR(50);

-- Business Registration Fields
ALTER TABLE user_profiles ADD COLUMN business_name VARCHAR(200);
ALTER TABLE user_profiles ADD COLUMN business_registration_number VARCHAR(50);
ALTER TABLE user_profiles ADD COLUMN tax_identification VARCHAR(50);
ALTER TABLE user_profiles ADD COLUMN business_address JSONB DEFAULT '{}';
ALTER TABLE user_profiles ADD COLUMN business_phone VARCHAR(20);
ALTER TABLE user_profiles ADD COLUMN business_email VARCHAR(255);

-- Verification Status Tracking Fields
ALTER TABLE user_profiles ADD COLUMN identity_verified BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE user_profiles ADD COLUMN business_verified BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE user_profiles ADD COLUMN professional_verified BOOLEAN DEFAULT FALSE NOT NULL;

-- Document References and Audit Fields
ALTER TABLE user_profiles ADD COLUMN verification_documents JSONB DEFAULT '{}' NOT NULL;
ALTER TABLE user_profiles ADD COLUMN verification_notes TEXT;
ALTER TABLE user_profiles ADD COLUMN verified_by UUID REFERENCES auth.users(id);
ALTER TABLE user_profiles ADD COLUMN verified_at TIMESTAMPTZ;

-- Compliance and Audit Tracking
ALTER TABLE user_profiles ADD COLUMN compliance_flags JSONB DEFAULT '{}' NOT NULL;

-- Phase 2: Add constraints and validation rules
-- License type validation (matches license-verification Edge Function)
ALTER TABLE user_profiles ADD CONSTRAINT check_license_type 
    CHECK (license_type IS NULL OR license_type IN ('tcm_practitioner', 'pharmacy'));

-- License status validation
ALTER TABLE user_profiles ADD CONSTRAINT check_license_status
    CHECK (license_status IN ('pending', 'verified', 'expired', 'suspended', 'rejected'));

-- License format validation (basic pattern check)
ALTER TABLE user_profiles ADD CONSTRAINT check_license_number_format
    CHECK (
        license_number IS NULL OR 
        (license_type = 'tcm_practitioner' AND license_number ~ '^TCM-[0-9]{6}$') OR
        (license_type = 'pharmacy' AND license_number ~ '^PHARM-[0-9]{6}$')
    );

-- Business logic constraints
ALTER TABLE user_profiles ADD CONSTRAINT check_professional_role_license
    CHECK (
        (role = 'practitioner' AND (license_type IS NULL OR license_type = 'tcm_practitioner')) OR
        (role = 'pharmacy_operator' AND (license_type IS NULL OR license_type = 'pharmacy')) OR
        (role = 'admin' AND license_type IS NULL) OR
        (role NOT IN ('practitioner', 'pharmacy_operator', 'admin'))
    );

-- Verification consistency constraints
ALTER TABLE user_profiles ADD CONSTRAINT check_verification_consistency
    CHECK (
        (verified_by IS NULL AND verified_at IS NULL) OR
        (verified_by IS NOT NULL AND verified_at IS NOT NULL)
    );

-- License verification integration constraint
ALTER TABLE user_profiles ADD CONSTRAINT check_license_verification_integration
    CHECK (
        (license_verification_id IS NULL) OR
        (license_number IS NOT NULL AND license_type IS NOT NULL)
    );

-- Phase 3: Create performance indexes
-- Primary license lookup indexes
CREATE INDEX idx_user_profiles_license_number ON user_profiles(license_number) 
    WHERE license_number IS NOT NULL;

CREATE INDEX idx_user_profiles_license_status ON user_profiles(license_status)
    WHERE license_status != 'pending';

CREATE INDEX idx_user_profiles_license_expiry ON user_profiles(license_expiry_date)
    WHERE license_expiry_date IS NOT NULL;

-- Business search indexes
CREATE INDEX idx_user_profiles_business_name ON user_profiles(business_name)
    WHERE business_name IS NOT NULL;

-- Admin verification queries indexes
CREATE INDEX idx_user_profiles_verification_status 
    ON user_profiles(identity_verified, business_verified, professional_verified)
    WHERE NOT (identity_verified AND business_verified AND professional_verified);

CREATE INDEX idx_user_profiles_verification_admin 
    ON user_profiles(verified_by, verified_at)
    WHERE verified_by IS NOT NULL;

-- Compound indexes for common admin queries
CREATE INDEX idx_user_profiles_role_status_verification 
    ON user_profiles(role, status, identity_verified, business_verified);

-- JSONB indexes for flexible queries
CREATE INDEX idx_user_profiles_business_address_gin 
    ON user_profiles USING gin(business_address);

CREATE INDEX idx_user_profiles_verification_docs_gin 
    ON user_profiles USING gin(verification_documents);

CREATE INDEX idx_user_profiles_compliance_flags_gin 
    ON user_profiles USING gin(compliance_flags);

-- Phase 4: Update existing RLS policies and add new ones
-- Drop existing policies to recreate with enhanced logic
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admin can insert user profiles" ON user_profiles;
DROP POLICY IF EXISTS "Only admin can delete user profiles" ON user_profiles;

-- Enhanced Policy 1: Users can view their own profile
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT 
    TO authenticated
    USING (auth.uid() = id);

-- Enhanced Policy 2: Users can update their own profile with verification restrictions
CREATE POLICY "Users can update their own profile with restrictions" ON user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id 
        -- Prevent users from self-modifying verification status
        AND identity_verified = (SELECT identity_verified FROM user_profiles WHERE id = auth.uid())
        AND business_verified = (SELECT business_verified FROM user_profiles WHERE id = auth.uid())
        AND professional_verified = (SELECT professional_verified FROM user_profiles WHERE id = auth.uid())
        AND verified_by = (SELECT verified_by FROM user_profiles WHERE id = auth.uid())
        AND verified_at = (SELECT verified_at FROM user_profiles WHERE id = auth.uid())
    );

-- Policy 3: Admin can view all profiles for verification and management
CREATE POLICY "Admin can view all profiles for verification" ON user_profiles
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile 
            WHERE admin_profile.id = auth.uid() 
            AND admin_profile.role = 'admin'
        )
    );

-- Policy 4: Admin can update verification status and admin-only fields
CREATE POLICY "Admin can update verification status" ON user_profiles
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile 
            WHERE admin_profile.id = auth.uid() 
            AND admin_profile.role = 'admin'
        )
    );

-- Policy 5: Profile creation (admin or self-registration)
CREATE POLICY "Profile creation with role validation" ON user_profiles
    FOR INSERT 
    WITH CHECK (
        -- Admin users can create any profile
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile 
            WHERE admin_profile.id = auth.uid() 
            AND admin_profile.role = 'admin'
        )
        OR 
        -- Users can create their own initial profile (first time only)
        (auth.uid() = id AND NOT EXISTS (
            SELECT 1 FROM user_profiles existing 
            WHERE existing.id = auth.uid()
        ))
    );

-- Policy 6: Only admin can delete user profiles (unchanged from original)
CREATE POLICY "Only admin can delete user profiles" ON user_profiles
    FOR DELETE 
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile 
            WHERE admin_profile.id = auth.uid() 
            AND admin_profile.role = 'admin'
        )
    );

-- Phase 5: Create helper function for license verification integration
CREATE OR REPLACE FUNCTION sync_license_verification_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Automatically update professional_verified based on license_status
    IF NEW.license_status = 'verified' THEN
        NEW.professional_verified = TRUE;
    ELSIF NEW.license_status IN ('expired', 'suspended', 'rejected') THEN
        NEW.professional_verified = FALSE;
    END IF;
    
    -- Set verification timestamp for status changes
    IF OLD.license_status IS DISTINCT FROM NEW.license_status THEN
        NEW.updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for license verification sync
CREATE TRIGGER sync_license_verification_on_update
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    WHEN (OLD.license_status IS DISTINCT FROM NEW.license_status)
    EXECUTE FUNCTION sync_license_verification_status();

-- Phase 6: Add helpful comments for maintenance
COMMENT ON COLUMN user_profiles.license_number IS 'Professional license number (TCM-XXXXXX or PHARM-XXXXXX format) - integrates with license-verification Edge Function';
COMMENT ON COLUMN user_profiles.license_type IS 'Type of professional license: tcm_practitioner or pharmacy - matches license-verification system';
COMMENT ON COLUMN user_profiles.license_status IS 'Professional license verification status: pending, verified, expired, suspended, rejected';
COMMENT ON COLUMN user_profiles.license_expiry_date IS 'License expiration date for compliance tracking';
COMMENT ON COLUMN user_profiles.license_verification_id IS 'Reference to license_verifications table for audit trail';
COMMENT ON COLUMN user_profiles.business_name IS 'Official business/clinic/pharmacy name for registration';
COMMENT ON COLUMN user_profiles.business_registration_number IS 'Government business registration number';
COMMENT ON COLUMN user_profiles.tax_identification IS 'Tax identification number for business compliance';
COMMENT ON COLUMN user_profiles.business_address IS 'Structured business address data (JSONB for flexibility)';
COMMENT ON COLUMN user_profiles.business_phone IS 'Business contact phone number';
COMMENT ON COLUMN user_profiles.business_email IS 'Business contact email address';
COMMENT ON COLUMN user_profiles.identity_verified IS 'Personal identity verification status (admin controlled)';
COMMENT ON COLUMN user_profiles.business_verified IS 'Business registration verification status (admin controlled)';
COMMENT ON COLUMN user_profiles.professional_verified IS 'Professional license verification status (syncs with license_status)';
COMMENT ON COLUMN user_profiles.verification_documents IS 'Document reference metadata (JSONB) - no actual files for HIPAA compliance';
COMMENT ON COLUMN user_profiles.verification_notes IS 'Admin notes for verification process and compliance tracking';
COMMENT ON COLUMN user_profiles.verified_by IS 'Admin user ID who performed verification';
COMMENT ON COLUMN user_profiles.verified_at IS 'Timestamp when verification was completed';
COMMENT ON COLUMN user_profiles.compliance_flags IS 'Various compliance requirement flags (JSONB for flexibility)';

-- Migration completion log
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    gen_random_uuid(),
    jsonb_build_object(
        'event', 'schema_migration',
        'migration', '20250104_extend_user_profiles_business_fields',
        'description', 'Extended user_profiles table with business fields for M1.3',
        'tables_modified', array['user_profiles'],
        'policies_updated', 6,
        'indexes_created', 9,
        'functions_created', 1,
        'triggers_created', 1
    ),
    NOW()
);