-- M1.3B Dev-Step 3: Minimal Seed Script for Behavioral Testing
-- Purpose: Create minimal test data for cross-role RLS policy testing
-- Zero-PII Compliance: All data uses generic business identifiers only

-- Temporarily bypass RLS for data seeding
SET row_security = OFF;

-- Create relationship tables required for testing
CREATE TABLE IF NOT EXISTS prescription_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tcm_practitioner_id UUID NOT NULL,
    pharmacy_id UUID NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '30 days',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referral_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referring_tcm_id UUID NOT NULL,
    receiving_pharmacy_id UUID NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Temporarily disable foreign key constraint to allow direct user_profiles insertion
ALTER TABLE user_profiles DROP CONSTRAINT user_profiles_id_fkey;

-- Insert test users with minimal business data (no PII)
INSERT INTO user_profiles (id, role, status, business_info, tcm_specialty, tcm_certification_level, is_public_profile)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'tcm_practitioner', 'active', 
     '{"clinic_name": "East Wellness Center", "business_type": "traditional_medicine"}',
     'acupuncture', 'licensed', true),
    ('22222222-2222-2222-2222-222222222222', 'tcm_practitioner', 'active',
     '{"clinic_name": "Mountain Herbs Practice", "business_type": "traditional_medicine"}', 
     'herbal_medicine', 'senior', false)
ON CONFLICT (id) DO NOTHING;

-- Insert pharmacy users with role-specific fields
INSERT INTO user_profiles (id, role, status, business_info, pharmacy_type, pharmacy_license_scope, is_public_profile)
VALUES 
    ('33333333-3333-3333-3333-333333333333', 'pharmacy', 'active',
     '{"business_name": "City Community Pharmacy", "business_type": "retail_pharmacy"}',
     'retail_pharmacy', 'basic_dispensing', true),
    ('44444444-4444-4444-4444-444444444444', 'pharmacy', 'active',
     '{"business_name": "Metro Health Dispensary", "business_type": "hospital_pharmacy"}',
     'hospital_pharmacy', 'controlled_substances', false)
ON CONFLICT (id) DO NOTHING;

-- Re-enable foreign key constraint
ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create business relationships for testing
INSERT INTO prescription_relationships (tcm_practitioner_id, pharmacy_id, status, expires_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'active', NOW() + INTERVAL '30 days'),
    ('22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', 'expired', NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;

INSERT INTO referral_relationships (referring_tcm_id, receiving_pharmacy_id, status, created_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'active', NOW() - INTERVAL '10 days'),
    ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'active', NOW() - INTERVAL '5 days')
ON CONFLICT DO NOTHING;

-- Re-enable RLS
SET row_security = ON;

-- Verify seed data loaded
SELECT 'Seed script completed' as status;