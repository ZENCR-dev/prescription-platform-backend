-- ============================================================================
-- Task 1.3B: Fix RLS Views Single Role Filtering
-- ============================================================================
-- Addresses architect feedback to correct RLS behavioral testing failures
-- Root cause: Views included both roles causing negative test cases to return 2 instead of 0
-- Solution: Filter each view to show only its specific role
-- ============================================================================

-- ============================================================================
-- STEP 1: UPDATE TCM CONTEXT VIEW - SINGLE ROLE FILTER
-- ============================================================================
-- Update v_profiles_tcm_context to show only TCM practitioner profiles
CREATE OR REPLACE VIEW v_profiles_tcm_context WITH (security_barrier = true) AS 
SELECT 
    id,
    role,
    COALESCE(
        business_info ->> 'business_name',
        business_info ->> 'organization_name',
        'Business Name Not Available'
    ) AS business_name,
    tcm_specialty,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE role = 'tcm_practitioner' AND status = 'active';

-- ============================================================================
-- STEP 2: UPDATE PHARMACY CONTEXT VIEW - SINGLE ROLE FILTER 
-- ============================================================================
-- Update v_profiles_pharmacy_context to show only pharmacy profiles
CREATE OR REPLACE VIEW v_profiles_pharmacy_context WITH (security_barrier = true) AS 
SELECT 
    id,
    role,
    COALESCE(
        business_info ->> 'business_name',
        business_info ->> 'organization_name',
        'Business Name Not Available'
    ) AS business_name,
    pharmacy_type,
    status AS verification_status,
    created_at
FROM user_profiles
WHERE role = 'pharmacy' AND status = 'active';

-- NOTE: v_profiles_public view unchanged - already has correct filtering with is_public_profile

-- ============================================================================
-- STEP 3: VALIDATION - VERIFY SINGLE ROLE FILTERING
-- ============================================================================

DO $$
DECLARE
    tcm_view_def TEXT;
    pharmacy_view_def TEXT;
    public_view_def TEXT;
    security_barrier_count INTEGER;
BEGIN
    RAISE NOTICE '=== VIEW SINGLE ROLE FILTERING VALIDATION ===';
    
    -- Check TCM view filters for single role
    SELECT definition INTO tcm_view_def
    FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'v_profiles_tcm_context';
    
    IF tcm_view_def NOT LIKE '%tcm_practitioner%' OR tcm_view_def LIKE '%pharmacy%' THEN
        RAISE EXCEPTION 'VALIDATION FAILED: TCM view does not filter for tcm_practitioner only';
    END IF;
    RAISE NOTICE '✅ TCM view filters for tcm_practitioner role only';
    
    -- Check Pharmacy view filters for single role
    SELECT definition INTO pharmacy_view_def
    FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'v_profiles_pharmacy_context';
    
    IF pharmacy_view_def NOT LIKE '%pharmacy%' OR pharmacy_view_def LIKE '%tcm_practitioner%' THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Pharmacy view does not filter for pharmacy role only';
    END IF;
    RAISE NOTICE '✅ Pharmacy view filters for pharmacy role only';
    
    -- Verify SECURITY BARRIER maintained on all views
    SELECT COUNT(*) INTO security_barrier_count
    FROM pg_views v
    JOIN pg_class c ON c.oid = (v.schemaname||'.'||v.viewname)::regclass
    JOIN pg_options_to_table(c.reloptions) opts ON opts.option_name = 'security_barrier'
    WHERE v.schemaname = 'public' 
    AND v.viewname LIKE 'v_profiles_%'
    AND opts.option_value = 'true';
    
    IF security_barrier_count != 3 THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Expected 3 views with SECURITY BARRIER, found %', security_barrier_count;
    END IF;
    RAISE NOTICE '✅ All % controlled views maintain SECURITY BARRIER', security_barrier_count;
    
    RAISE NOTICE '✅ ALL VIEW VALIDATIONS PASSED - Single role filtering implemented';
END $$;

-- ============================================================================
-- MIGRATION COMPLETION LOG
-- ============================================================================
SELECT NOW() as fix_completed,
       'Task 1.3B View Fix: Single Role Filtering for RLS Behavioral Tests' as task,
       'VIEWS CORRECTED - READY FOR RLS BEHAVIORAL RETEST' as status;

-- View correction complete
DO $$
BEGIN
    RAISE NOTICE '=== TASK 1.3B VIEW CORRECTION COMPLETE ===';
    RAISE NOTICE 'ARCHITECT REQUIREMENTS ADDRESSED:';
    RAISE NOTICE '✅ v_profiles_tcm_context: Filters role = tcm_practitioner only';
    RAISE NOTICE '✅ v_profiles_pharmacy_context: Filters role = pharmacy only';
    RAISE NOTICE '✅ SECURITY BARRIER maintained on all views';
    RAISE NOTICE '✅ Column sets unchanged (Zero-PII compliance maintained)';
    RAISE NOTICE 'Ready for RLS behavioral testing - negative cases should now return COUNT=0';
END $$;