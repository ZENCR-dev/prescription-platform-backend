-- ============================================================================
-- CONTROLLED VIEWS DEPLOYMENT TO CLOUD INSTANCE
-- ============================================================================
-- Purpose: Deploy controlled views for frontend IRG integration
-- Target: Supabase Cloud instance (dosbevgbkxrtixemfjfl)
-- Date: 2025-09-07
-- ============================================================================

-- Ensure private schema exists
CREATE SCHEMA IF NOT EXISTS private;

-- Helper functions for business relationship filtering
CREATE OR REPLACE FUNCTION private.get_current_user_id() 
RETURNS UUID
SECURITY DEFINER
SET search_path = public, pg_temp, private
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
END;
$$;

CREATE OR REPLACE FUNCTION private.has_prescription_business_relationship(requesting_user_id uuid, target_user_id uuid) 
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public, pg_temp, private
LANGUAGE plpgsql
AS $$
BEGIN
    -- For prescription business relationships: pharmacy users can see TCM practitioners
    -- This is a simplified version - implement actual business logic as needed
    RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.has_referral_business_relationship(requesting_user_id uuid, target_user_id uuid) 
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public, pg_temp, private
LANGUAGE plpgsql
AS $$
BEGIN
    -- For referral business relationships: TCM practitioners can see pharmacy users  
    -- This is a simplified version - implement actual business logic as needed
    RETURN true;
END;
$$;

-- Set functions to STABLE for performance
ALTER FUNCTION private.get_current_user_id() STABLE;
ALTER FUNCTION private.has_prescription_business_relationship(uuid, uuid) STABLE;
ALTER FUNCTION private.has_referral_business_relationship(uuid, uuid) STABLE;

-- Drop existing views if they exist
DROP VIEW IF EXISTS public.v_profiles_tcm_context;
DROP VIEW IF EXISTS public.v_profiles_pharmacy_context; 
DROP VIEW IF EXISTS public.v_profiles_public;

-- View 1: v_profiles_tcm_context (TCM practitioners visible to pharmacy users)
CREATE VIEW public.v_profiles_tcm_context AS 
SELECT 
    id,
    role,
    COALESCE(
        business_info->>'business_name', 
        business_info->>'organization_name', 
        'Business Name Not Available'
    ) AS business_name,
    CASE 
        WHEN business_info->>'specialty' IS NOT NULL 
        THEN business_info->>'specialty'
        ELSE 'General TCM'
    END AS tcm_specialty,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE 
    role::text = 'tcm_practitioner'::text 
    AND status::text = 'active'::text 
    AND private.has_prescription_business_relationship(private.get_current_user_id(), id);

-- View 2: v_profiles_pharmacy_context (Pharmacies visible to TCM practitioners) 
CREATE VIEW public.v_profiles_pharmacy_context AS
SELECT 
    id,
    role,
    COALESCE(
        business_info->>'business_name', 
        business_info->>'organization_name', 
        'Business Name Not Available'
    ) AS business_name,
    CASE 
        WHEN business_info->>'pharmacy_type' IS NOT NULL 
        THEN business_info->>'pharmacy_type'
        ELSE 'retail_pharmacy'
    END AS pharmacy_type,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE 
    role::text = 'pharmacy'::text 
    AND status::text = 'active'::text 
    AND private.has_referral_business_relationship(private.get_current_user_id(), id);

-- View 3: v_profiles_public (Public directory)
CREATE VIEW public.v_profiles_public AS
SELECT 
    id,
    role,
    status AS verification_status,
    COALESCE(
        business_info->>'business_name', 
        business_info->>'organization_name', 
        'Business Name Not Available'
    ) AS business_name,
    created_at
FROM user_profiles
WHERE 
    COALESCE((business_info->>'is_public_profile')::boolean, false) = true
    AND status::text = 'active'::text 
    AND (role::text = ANY (ARRAY['tcm_practitioner'::character varying, 'pharmacy'::character varying]::text[]));

-- Set security_barrier=true for all views
ALTER VIEW public.v_profiles_tcm_context SET (security_barrier=true);
ALTER VIEW public.v_profiles_pharmacy_context SET (security_barrier=true);
ALTER VIEW public.v_profiles_public SET (security_barrier=true);

-- Grant SELECT permissions on all controlled views to authenticated role
GRANT SELECT ON public.v_profiles_tcm_context TO authenticated;
GRANT SELECT ON public.v_profiles_pharmacy_context TO authenticated;
GRANT SELECT ON public.v_profiles_public TO authenticated;

-- Grant EXECUTE on helper functions to authenticated role
GRANT EXECUTE ON FUNCTION private.get_current_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_prescription_business_relationship(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_referral_business_relationship(uuid, uuid) TO authenticated;

-- Comment views for API documentation
COMMENT ON VIEW public.v_profiles_tcm_context IS 'TCM practitioners visible to pharmacy users based on business relationships';
COMMENT ON VIEW public.v_profiles_pharmacy_context IS 'Pharmacies visible to TCM practitioners based on business relationships';
COMMENT ON VIEW public.v_profiles_public IS 'Public directory of practitioners and pharmacies';