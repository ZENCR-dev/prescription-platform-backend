-- ============================================================================
-- VIEW PERMISSIONS SECURITY FIX - IMMEDIATE EXECUTION REQUIRED
-- ============================================================================
-- Purpose: Fix excessive permissions on controlled views
-- Issue: authenticated role has ALL permissions (INSERT/UPDATE/DELETE/TRIGGER/TRUNCATE/REFERENCES)
-- Solution: REVOKE ALL + GRANT SELECT only (principle of least privilege)
-- Target: Supabase Cloud instance (dosbevgbkxrtixemfjfl)
-- Date: 2025-09-07 03:00:00
-- ============================================================================

-- STEP 1: REVOKE ALL EXCESSIVE PERMISSIONS
REVOKE ALL ON public.v_profiles_tcm_context FROM authenticated;
REVOKE ALL ON public.v_profiles_pharmacy_context FROM authenticated;
REVOKE ALL ON public.v_profiles_public FROM authenticated;

-- STEP 2: GRANT ONLY SELECT PERMISSIONS (READ-ONLY ACCESS)
GRANT SELECT ON public.v_profiles_tcm_context TO authenticated;
GRANT SELECT ON public.v_profiles_pharmacy_context TO authenticated;
GRANT SELECT ON public.v_profiles_public TO authenticated;

-- STEP 3: Add comments for audit trail
COMMENT ON VIEW public.v_profiles_tcm_context IS 'TCM practitioners visible to pharmacy users - SELECT-only access for authenticated role';
COMMENT ON VIEW public.v_profiles_pharmacy_context IS 'Pharmacies visible to TCM practitioners - SELECT-only access for authenticated role';
COMMENT ON VIEW public.v_profiles_public IS 'Public directory of practitioners and pharmacies - SELECT-only access for authenticated role';