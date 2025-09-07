-- Create license_verifications table for tracking license verification workflows
-- Supports both TCM practitioner and pharmacy license verification

-- Create enum for license types
CREATE TYPE license_type AS ENUM ('tcm_practitioner', 'pharmacy');

-- Create enum for verification status
CREATE TYPE verification_status AS ENUM ('pending', 'verifying', 'verified', 'rejected');

-- Create license_verifications table
CREATE TABLE IF NOT EXISTS public.license_verifications (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  license_type license_type NOT NULL,
  license_number TEXT NOT NULL,
  status verification_status NOT NULL DEFAULT 'pending',
  verification_details JSONB,
  additional_info JSONB,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  verified_at TIMESTAMPTZ
);

-- Create indexes for performance
CREATE INDEX idx_license_verifications_user_id ON public.license_verifications(user_id);
CREATE INDEX idx_license_verifications_status ON public.license_verifications(status);
CREATE INDEX idx_license_verifications_license_number ON public.license_verifications(license_number);
CREATE INDEX idx_license_verifications_created_at ON public.license_verifications(created_at DESC);

-- Add unique constraint to prevent duplicate active verifications
CREATE UNIQUE INDEX idx_unique_active_license_verification 
ON public.license_verifications(license_number, license_type) 
WHERE status IN ('pending', 'verifying');

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_license_verifications_updated_at
  BEFORE UPDATE ON public.license_verifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS)
ALTER TABLE public.license_verifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own verifications
CREATE POLICY "Users can view own verifications" ON public.license_verifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Service role can manage all verifications
CREATE POLICY "Service role full access" ON public.license_verifications
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- Policy: Admins can view all verifications
CREATE POLICY "Admins can view all verifications" ON public.license_verifications
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- Grant permissions
GRANT ALL ON public.license_verifications TO service_role;
GRANT SELECT, INSERT ON public.license_verifications TO authenticated;

-- Comment on table
COMMENT ON TABLE public.license_verifications IS 'Tracks license verification workflows for TCM practitioners and pharmacies';
COMMENT ON COLUMN public.license_verifications.id IS 'Unique verification ID in format ver_timestamp_random';
COMMENT ON COLUMN public.license_verifications.user_id IS 'Reference to the user requesting verification';
COMMENT ON COLUMN public.license_verifications.license_type IS 'Type of license being verified';
COMMENT ON COLUMN public.license_verifications.license_number IS 'License number in format TCM-XXXXXX or PHARM-XXXXXX';
COMMENT ON COLUMN public.license_verifications.status IS 'Current verification status';
COMMENT ON COLUMN public.license_verifications.verification_details IS 'JSON object containing verification metadata';
COMMENT ON COLUMN public.license_verifications.additional_info IS 'JSON object containing additional user-provided information';
COMMENT ON COLUMN public.license_verifications.rejection_reason IS 'Reason for rejection if status is rejected';
COMMENT ON COLUMN public.license_verifications.verified_at IS 'Timestamp when verification was completed (verified or rejected)';