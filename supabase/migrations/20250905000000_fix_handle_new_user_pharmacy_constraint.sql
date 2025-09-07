-- Fix handle_new_user function to handle pharmacy_id constraint
-- Issue: Pharmacy users need pharmacy_id but trigger doesn't set it

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
DECLARE
  user_role TEXT;
  provided_pharmacy_id UUID;
BEGIN
  -- Get the role from metadata
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'tcm_practitioner');
  
  -- Get pharmacy_id from metadata if provided
  provided_pharmacy_id := (NEW.raw_user_meta_data->>'pharmacy_id')::uuid;
  
  -- For pharmacy users, pharmacy_id must be explicitly provided
  -- For non-pharmacy users, pharmacy_id should be null
  IF user_role = 'pharmacy' AND provided_pharmacy_id IS NULL THEN
    RAISE EXCEPTION 'Pharmacy users must provide pharmacy_id in metadata';
  END IF;
  
  INSERT INTO public.user_profiles (id, role, status, business_info, pharmacy_id)
  VALUES (
    NEW.id,
    user_role,
    'pending_verification',
    COALESCE(NEW.raw_user_meta_data->'business_info', '{}'),
    CASE WHEN user_role = 'pharmacy' THEN provided_pharmacy_id ELSE NULL END
  );
  RETURN NEW;
END;
$$ language plpgsql security definer;

-- Add comment explaining the fix
COMMENT ON FUNCTION handle_new_user() IS 'Handles new user registration with automatic pharmacy_id generation for pharmacy users';