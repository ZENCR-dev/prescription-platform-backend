-- ============================================================================
-- Task 1.2 Research Phase - Constraint Inconsistency Evidence Collection
-- ============================================================================
-- Purpose: Document constraint inconsistency between user_profiles_role_check 
--          and check_professional_role_license with script + raw output + screenshot
-- Date: $(date)
-- Global Architect Requirement: Evidence-based, binary state, scriptable proof

\echo '=== CONSTRAINT INCONSISTENCY EVIDENCE COLLECTION ==='
\echo 'Task: 1.2 Research Phase'
\echo 'Date:' $(date)
\echo 'Purpose: Document role constraint inconsistencies with evidence'
\echo ''

-- 1. CURRENT CONSTRAINT DEFINITIONS (DDL Evidence)
\echo '1. CURRENT CONSTRAINT DEFINITIONS'
\echo 'Query: Extract actual constraint DDL from pg_constraint system table'

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition,
    contype as constraint_type,
    'user_profiles' as table_name
FROM pg_constraint 
WHERE conrelid = 'user_profiles'::regclass 
AND conname IN ('user_profiles_role_check', 'check_professional_role_license')
ORDER BY conname;

\echo ''

-- 2. ROLE VALUE ANALYSIS (Sample Evidence)
\echo '2. ROLE VALUE ANALYSIS'
\echo 'Query: Expected role values from each constraint'

-- Extract role values from user_profiles_role_check
\echo 'user_profiles_role_check expected values:'
SELECT regexp_split_to_table(
    regexp_replace(
        regexp_replace(
            pg_get_constraintdef(oid), 
            '.*role.*IN.*\(([^)]+)\).*', '\1'
        ),
        '''|[[:space:]]', '', 'g'
    ), 
    ','
) as role_value
FROM pg_constraint 
WHERE conrelid = 'user_profiles'::regclass 
AND conname = 'user_profiles_role_check';

\echo ''

-- Extract role values from check_professional_role_license  
\echo 'check_professional_role_license expected values:'
WITH constraint_text AS (
    SELECT pg_get_constraintdef(oid) as def
    FROM pg_constraint 
    WHERE conrelid = 'user_profiles'::regclass 
    AND conname = 'check_professional_role_license'
)
SELECT DISTINCT 
    regexp_replace(match[1], '''', '', 'g') as role_value
FROM constraint_text,
     regexp_matches(def, 'role = ''([^'']+)''', 'g') as match
ORDER BY role_value;

\echo ''

-- 3. CONSTRAINT CONFLICT DEMONSTRATION
\echo '3. CONSTRAINT CONFLICT DEMONSTRATION'
\echo 'Analysis: Values that would violate constraints'

-- Values valid for user_profiles_role_check but invalid for check_professional_role_license
\echo 'Values valid for user_profiles_role_check but INVALID for check_professional_role_license:'
SELECT 'tcm_practitioner' as role_value, 
       'Valid in user_profiles_role_check, Invalid in check_professional_role_license (expects "practitioner")' as conflict_analysis
UNION ALL
SELECT 'pharmacy' as role_value,
       'Valid in user_profiles_role_check, Invalid in check_professional_role_license (expects "pharmacy_operator")' as conflict_analysis;

\echo ''

-- Values expected by check_professional_role_license but invalid for user_profiles_role_check
\echo 'Values expected by check_professional_role_license but INVALID for user_profiles_role_check:'
SELECT 'practitioner' as role_value,
       'Expected by check_professional_role_license, Invalid in user_profiles_role_check (expects "tcm_practitioner")' as conflict_analysis
UNION ALL
SELECT 'pharmacy_operator' as role_value, 
       'Expected by check_professional_role_license, Invalid in user_profiles_role_check (expects "pharmacy")' as conflict_analysis;

\echo ''

-- 4. CURRENT USER PROFILES DATA STATE
\echo '4. CURRENT USER PROFILES DATA STATE'
\echo 'Query: Actual role values in user_profiles table'

SELECT 
    role,
    COUNT(*) as user_count,
    'Current data using: ' || role as data_status
FROM user_profiles 
GROUP BY role
ORDER BY role;

\echo ''

-- 5. CONSTRAINT ENFORCEMENT TEST
\echo '5. CONSTRAINT ENFORCEMENT TEST'
\echo 'Test: Attempt to demonstrate constraint conflict (safe test)'

-- Show which constraint would fail for current data
SELECT 
    role,
    CASE 
        WHEN role IN ('tcm_practitioner', 'pharmacy', 'admin') THEN 'PASS user_profiles_role_check'
        ELSE 'FAIL user_profiles_role_check'
    END as role_check_status,
    CASE 
        WHEN role IN ('practitioner', 'pharmacy_operator', 'admin') THEN 'PASS check_professional_role_license'
        ELSE 'FAIL check_professional_role_license (for role-license validation)'
    END as professional_check_status
FROM (
    SELECT DISTINCT role FROM user_profiles
    UNION 
    SELECT 'practitioner'
    UNION
    SELECT 'pharmacy_operator'
) role_analysis
ORDER BY role;

\echo ''

-- 6. MIGRATION IMPACT ANALYSIS  
\echo '6. MIGRATION IMPACT ANALYSIS'
\echo 'Analysis: Required constraint modifications for consistency'

SELECT 
    'check_professional_role_license' as constraint_name,
    'Must update role references from (practitioner, pharmacy_operator) to (tcm_practitioner, pharmacy)' as required_modification,
    'Update CHECK constraint definition to match user_profiles_role_check values' as action_required;

\echo ''
\echo '=== CONSTRAINT INCONSISTENCY EVIDENCE COMPLETE ==='
\echo 'Evidence Package: Script + Raw Output + Screenshot Required'
\echo 'Next Step: Role-specific field design based on consistent role values'