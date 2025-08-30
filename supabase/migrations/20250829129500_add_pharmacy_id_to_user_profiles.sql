-- ============================================================================
-- Add pharmacy_id to user_profiles for pharmacy operators
-- ============================================================================
-- This migration adds pharmacy_id column to user_profiles table
-- Required for pharmacy RLS policies to properly isolate data
-- ============================================================================

-- Add pharmacy_id column to user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS pharmacy_id UUID REFERENCES public.pharmacies(id);

-- Create index for efficient querying
CREATE INDEX IF NOT EXISTS idx_user_profiles_pharmacy_id 
ON public.user_profiles(pharmacy_id);

-- Update constraint to ensure pharmacy operators have pharmacy_id
ALTER TABLE public.user_profiles 
ADD CONSTRAINT pharmacy_operator_must_have_pharmacy_id 
CHECK (
  (role != 'pharmacy' AND role != 'pharmacy_operator') 
  OR 
  (pharmacy_id IS NOT NULL)
);

-- Add comment
COMMENT ON COLUMN public.user_profiles.pharmacy_id IS 'Reference to pharmacy for pharmacy operators';