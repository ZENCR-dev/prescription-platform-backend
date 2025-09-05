# Task 1.2 Performance Baseline Plan

## Purpose
Establish performance baselines for role-specific profile fields before any optimization work. This is evidence collection only - no performance commitments or optimization conclusions.

## Baseline Measurement Approach

### 1. Query Performance Baseline
Measure execution time and resource usage for role-specific field queries without any indexes.

### 2. Constraint Validation Performance
Measure overhead of enum constraints and field isolation constraints during INSERT/UPDATE operations.

### 3. Cross-Role Query Performance
Measure performance of queries that span multiple role types.

## Performance Baseline Scripts

### Script 1: Role-Based Profile Query
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT id, role, created_at,
       CASE 
           WHEN role = 'tcm_practitioner' THEN 
               jsonb_build_object(
                   'specialty', tcm_specialty,
                   'practice_years', tcm_practice_years,
                   'certification_level', tcm_certification_level,
                   'clinic_affiliation', tcm_clinic_affiliation
               )
           WHEN role = 'pharmacy' THEN 
               jsonb_build_object(
                   'type', pharmacy_type,
                   'license_scope', pharmacy_license_scope,
                   'location_count', pharmacy_location_count,
                   'controlled_permit', controlled_substance_permit
               )
           WHEN role = 'admin' THEN 
               jsonb_build_object(
                   'level', admin_level,
                   'scope', admin_scope,
                   'certification_date', admin_certification_date,
                   'supervisor_id', admin_supervisor_id
               )
           ELSE NULL
       END as role_specific_data
FROM user_profiles 
WHERE role IN ('tcm_practitioner', 'pharmacy', 'admin')
LIMIT 10;
```

### Script 2: Enum Constraint Validation Query
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT role, COUNT(*) as count,
       COUNT(CASE WHEN role = 'tcm_practitioner' AND tcm_specialty IS NOT NULL THEN 1 END) as tcm_with_specialty,
       COUNT(CASE WHEN role = 'pharmacy' AND pharmacy_type IS NOT NULL THEN 1 END) as pharmacy_with_type,
       COUNT(CASE WHEN role = 'admin' AND admin_level IS NOT NULL THEN 1 END) as admin_with_level
FROM user_profiles 
GROUP BY role;
```

### Script 3: Cross-Role Field Validation Query
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*) as total_users,
       COUNT(CASE WHEN role = 'tcm_practitioner' AND (tcm_specialty IS NOT NULL OR tcm_practice_years IS NOT NULL) THEN 1 END) as tcm_with_data,
       COUNT(CASE WHEN role = 'pharmacy' AND (pharmacy_type IS NOT NULL OR pharmacy_license_scope IS NOT NULL) THEN 1 END) as pharmacy_with_data,
       COUNT(CASE WHEN role = 'admin' AND (admin_level IS NOT NULL OR admin_scope IS NOT NULL) THEN 1 END) as admin_with_data,
       COUNT(CASE WHEN role NOT IN ('tcm_practitioner', 'pharmacy', 'admin') THEN 1 END) as other_roles
FROM user_profiles;
```

## Execution Instructions

1. Run each script individually and capture complete EXPLAIN ANALYZE output
2. Save raw results to evidence files (no interpretation needed)  
3. Include timing, buffer usage, and query plan details
4. Record baseline for future performance comparison
5. Do not make any performance optimization conclusions

## Evidence Files
- `tests/evidence/task-1.2-performance-baseline-script1.log` - Role-based profile query results
- `tests/evidence/task-1.2-performance-baseline-script2.log` - Enum constraint validation results  
- `tests/evidence/task-1.2-performance-baseline-script3.log` - Cross-role validation results

## Note
This is first-round evidence collection only. No indexes should be created at this stage. Performance optimization will be handled in subsequent performance-focused tasks.