-- ============================================================================
-- Task 1.3B: Final RLS Views Business Relationship Filtering Fix
-- ============================================================================
-- Addresses architect feedback to prevent public directory policy leakage
-- Root cause: Views only filtered by role, allowing public_directory_select policy
--             to leak public profiles into negative test cases  
-- Solution: Add business relationship validation to view WHERE clauses
-- ============================================================================

-- ============================================================================
-- STEP 1: UPDATE TCM CONTEXT VIEW - BUSINESS RELATIONSHIP FILTER
-- ============================================================================
-- Update v_profiles_tcm_context to require business relationship validation
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
WHERE role = 'tcm_practitioner' 
AND status = 'active' 
AND private.has_prescription_business_relationship(auth.uid(), id);

-- ============================================================================
-- STEP 2: UPDATE PHARMACY CONTEXT VIEW - BUSINESS RELATIONSHIP FILTER  
-- ============================================================================
-- Update v_profiles_pharmacy_context to require business relationship validation
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
WHERE role = 'pharmacy' 
AND status = 'active' 
AND private.has_referral_business_relationship(auth.uid(), id);

-- NOTE: v_profiles_public view unchanged - continues to handle public directory access

-- ============================================================================
-- STEP 3: VALIDATION - VERIFY BUSINESS RELATIONSHIP FILTERING
-- ============================================================================

DO $$
DECLARE
    tcm_view_def TEXT;
    pharmacy_view_def TEXT;
    security_barrier_count INTEGER;
BEGIN
    RAISE NOTICE '=== VIEW BUSINESS RELATIONSHIP FILTERING VALIDATION ===';
    
    -- Check TCM view includes business relationship validation
    SELECT definition INTO tcm_view_def
    FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'v_profiles_tcm_context';
    
    IF tcm_view_def NOT LIKE '%has_prescription_business_relationship%' THEN
        RAISE EXCEPTION 'VALIDATION FAILED: TCM view missing business relationship validation';
    END IF;
    RAISE NOTICE '✅ TCM view includes has_prescription_business_relationship filter';
    
    -- Check Pharmacy view includes business relationship validation
    SELECT definition INTO pharmacy_view_def
    FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'v_profiles_pharmacy_context';
    
    IF pharmacy_view_def NOT LIKE '%has_referral_business_relationship%' THEN
        RAISE EXCEPTION 'VALIDATION FAILED: Pharmacy view missing business relationship validation';
    END IF;
    RAISE NOTICE '✅ Pharmacy view includes has_referral_business_relationship filter';
    
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
    
    RAISE NOTICE '✅ ALL BUSINESS RELATIONSHIP VALIDATIONS PASSED - Public directory leakage blocked';
END $$;

-- ============================================================================
-- MIGRATION COMPLETION LOG
-- ============================================================================
SELECT NOW() as fix_completed,
       'Task 1.3B Final Fix: Business Relationship Filtering for RLS Views' as task,
       'PUBLIC DIRECTORY LEAKAGE BLOCKED - READY FOR FINAL RLS RETEST' as status;

-- Business relationship filtering complete
DO $$
BEGIN
    RAISE NOTICE '=== TASK 1.3B FINAL VIEW CORRECTION COMPLETE ===';
    RAISE NOTICE 'ARCHITECT REQUIREMENTS ADDRESSED:';
    RAISE NOTICE '✅ v_profiles_tcm_context: Single role + prescription business relationship validation';
    RAISE NOTICE '✅ v_profiles_pharmacy_context: Single role + referral business relationship validation';
    RAISE NOTICE '✅ v_profiles_public: Unchanged - continues to handle public directory';
    RAISE NOTICE '✅ SECURITY BARRIER maintained on all views';  
    RAISE NOTICE '✅ Column sets unchanged (Zero-PII compliance maintained)';
    RAISE NOTICE '✅ Base table RLS policies unchanged';
    RAISE NOTICE 'Ready for final RLS behavioral testing - negative cases should now return COUNT=0';
END $$;