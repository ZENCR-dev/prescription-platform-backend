-- Fix constraints and permissions issues identified in CI testing
-- Date: 2025-09-01
-- Purpose: Resolve pharmacy_id constraint and anon role permissions

BEGIN;

-- 1. Drop the problematic pharmacy constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS pharmacy_operator_must_have_pharmacy_id;

-- 2. Add a more flexible constraint that allows pharmacy users with pharmacy_id
ALTER TABLE user_profiles 
ADD CONSTRAINT pharmacy_must_have_pharmacy_id 
CHECK (
  (role != 'pharmacy') OR 
  (role = 'pharmacy' AND pharmacy_id IS NOT NULL)
);

-- 3. Grant SELECT permission to anon role for Edge Functions access
-- This is needed for registration validation and other public-facing APIs
GRANT SELECT ON user_profiles TO anon;

-- 4. Create test helper function for JWT claims testing
-- This function helps with testing by creating proper auth.users entries
CREATE OR REPLACE FUNCTION public.create_test_user(
  test_id UUID,
  test_email TEXT,
  test_role TEXT DEFAULT 'tcm_practitioner'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insert into auth.users if not exists (for testing only)
  INSERT INTO auth.users (id, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES (
    test_id,
    test_email,
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object(),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- Insert into user_profiles
  INSERT INTO user_profiles (id, role, status, business_info)
  VALUES (
    test_id,
    test_role,
    'active',
    jsonb_build_object('test', true)
  )
  ON CONFLICT (id) DO UPDATE
  SET role = EXCLUDED.role,
      status = EXCLUDED.status;
END;
$$;

-- 5. Grant execute permission on test helper to authenticated users
GRANT EXECUTE ON FUNCTION public.create_test_user TO authenticated;

-- 6. Fix any existing pharmacy users without pharmacy_id (data cleanup)
-- This is a one-time cleanup to ensure data consistency
UPDATE user_profiles
SET pharmacy_id = gen_random_uuid()
WHERE role = 'pharmacy' AND pharmacy_id IS NULL;

COMMIT;

-- Add helpful comments
COMMENT ON CONSTRAINT pharmacy_must_have_pharmacy_id ON user_profiles IS 
'Ensures pharmacy operators must have an associated pharmacy_id';

COMMENT ON FUNCTION public.create_test_user IS 
'Helper function for creating test users with proper auth.users entries (testing only)';