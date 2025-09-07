-- ============================================================================
-- VIEW PERMISSIONS SECURITY FIX - IMMEDIATE EXECUTION REQUIRED
-- ============================================================================
-- Purpose: Fix excessive permissions on controlled views
-- Issue: authenticated role has ALL permissions (INSERT/UPDATE/DELETE/TRIGGER/TRUNCATE/REFERENCES)
-- Solution: REVOKE ALL + GRANT SELECT only (principle of least privilege)
-- Target: Supabase Cloud instance (dosbevgbkxrtixemfjfl)
-- Date: 2025-09-07
-- ============================================================================

-- STEP 1: REVOKE ALL EXCESSIVE PERMISSIONS
REVOKE ALL ON public.v_profiles_tcm_context FROM authenticated;
REVOKE ALL ON public.v_profiles_pharmacy_context FROM authenticated;
REVOKE ALL ON public.v_profiles_public FROM authenticated;

-- STEP 2: GRANT ONLY SELECT PERMISSIONS (READ-ONLY ACCESS)
GRANT SELECT ON public.v_profiles_tcm_context TO authenticated;
GRANT SELECT ON public.v_profiles_pharmacy_context TO authenticated;
GRANT SELECT ON public.v_profiles_public TO authenticated;

-- STEP 3: VERIFICATION QUERY - SHOULD SHOW ONLY SELECT PERMISSIONS
SELECT 'VIEW_PERMISSIONS_CORRECTED' AS category, table_schema, table_name, privilege_type, grantee
FROM information_schema.role_table_grants
WHERE table_schema='public'
  AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
  AND grantee='authenticated'
ORDER BY table_name, privilege_type;

-- STEP 4: CONFIRM SECURITY COMPLIANCE
SELECT 'SECURITY_COMPLIANCE_CHECK' AS category,
       table_name,
       COUNT(*) AS permission_count,
       STRING_AGG(privilege_type, ', ' ORDER BY privilege_type) AS permissions
FROM information_schema.role_table_grants
WHERE table_schema='public'
  AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
  AND grantee='authenticated'
GROUP BY table_name
ORDER BY table_name;

-- Expected result: Each view should have permission_count=1 and permissions='SELECT'