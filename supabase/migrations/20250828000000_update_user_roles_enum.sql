-- Update user roles enum to match API specification
-- Aligns user_profiles.role values with APIv1.md specification

-- Add new role values to the check constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT user_profiles_role_check;

ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_role_check 
CHECK (role IN ('tcm_practitioner', 'pharmacy', 'admin', 'practitioner', 'pharmacy_operator'));

-- Update existing data to use new role values
UPDATE user_profiles 
SET role = 'tcm_practitioner' 
WHERE role = 'practitioner';

UPDATE user_profiles 
SET role = 'pharmacy' 
WHERE role = 'pharmacy_operator';

-- Remove old role values from constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT user_profiles_role_check;

ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_role_check 
CHECK (role IN ('tcm_practitioner', 'pharmacy', 'admin'));

-- Update the handle_new_user function to use correct default role
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, role, status, business_info)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'tcm_practitioner'), -- Updated default role
    'pending_verification',
    COALESCE(NEW.raw_user_meta_data->'business_info', '{}')
  );
  RETURN NEW;
END;
$$ language plpgsql security definer;

-- Update table comment to reflect new role values  
COMMENT ON COLUMN user_profiles.role IS 'User role: tcm_practitioner (TCM practitioner), pharmacy (pharmacy operator), admin (administrator)';

-- Create index for efficient role-based queries (used by JWT hook)
CREATE INDEX IF NOT EXISTS idx_user_profiles_role_status ON user_profiles(role, status);

-- Grant necessary permissions for Edge Function access
GRANT SELECT ON user_profiles TO anon, authenticated;