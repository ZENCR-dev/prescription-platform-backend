-- =====================================================
-- TCM Practitioner RLS Policies for M1.1 Scope Only
-- =====================================================
-- Purpose: Create basic practitioner security functions for M1.1
-- Scope: Limited to user_profiles table only
-- =====================================================

-- =====================================================
-- 1. CREATE SECURITY DEFINER FUNCTIONS
-- =====================================================

-- Function to get current practitioner ID (optimized)
CREATE OR REPLACE FUNCTION private.get_current_practitioner_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = private, public
AS $$
  SELECT id 
  FROM public.user_profiles 
  WHERE id = auth.uid() 
    AND role = 'tcm_practitioner'
    AND status = 'active'
  LIMIT 1;
$$;

-- Function to check if current user is a TCM practitioner
CREATE OR REPLACE FUNCTION private.is_current_user_practitioner()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = private, public
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM public.user_profiles 
    WHERE id = auth.uid() 
      AND role = 'tcm_practitioner'
      AND status = 'active'
    LIMIT 1
  );
$$;

-- =====================================================
-- 2. GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.get_current_practitioner_id() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_current_user_practitioner() TO authenticated;

-- =====================================================
-- 3. COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION private.get_current_practitioner_id() IS 'Optimized function to verify active TCM practitioner';
COMMENT ON FUNCTION private.is_current_user_practitioner() IS 'Check if current user is an active TCM practitioner';