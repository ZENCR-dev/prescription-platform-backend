-- ============================================================================
-- Migration Execution Evidence Collection Script
-- ============================================================================
-- Purpose: Document migration deployment state and rollback capability
-- Migration: 20250104_extend_user_profiles_business_fields
-- Evidence Collection Date: $(date)

\echo '=== MIGRATION EXECUTION EVIDENCE COLLECTION ==='
\echo 'Migration: 20250104_extend_user_profiles_business_fields'
\echo 'Evidence Collection Date:' $(date)
\echo 'Environment: Supabase Local Development'
\echo ''

-- Migration Application Status
\echo '1. MIGRATION APPLICATION STATUS'
SELECT 
    version,
    inserted_at,
    'APPLIED' as status
FROM supabase_migrations.schema_migrations 
WHERE version LIKE '20250104%'
ORDER BY version;
\echo ''

-- Current Database Schema Validation
\echo '2. POST-MIGRATION SCHEMA VALIDATION'
\echo 'Field Count Verification:'
SELECT COUNT(*) as total_columns_added
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND column_name IN (
    'license_number', 'license_type', 'license_status', 'license_expiry_date', 'license_verification_id',
    'business_name', 'business_registration_number', 'tax_identification', 'business_address', 'business_phone', 'business_email',
    'identity_verified', 'business_verified', 'professional_verified',
    'verification_documents', 'verification_notes', 'verified_by', 'verified_at', 'compliance_flags'
);
\echo ''

\echo 'Constraint Count Verification:'
SELECT COUNT(*) as business_constraints_added
FROM pg_constraint 
WHERE conrelid = 'user_profiles'::regclass 
AND contype = 'c'
AND conname LIKE 'check_%';
\echo ''

\echo 'Index Count Verification:'
SELECT COUNT(*) as business_indexes_added
FROM pg_indexes 
WHERE tablename = 'user_profiles' 
AND indexname LIKE 'idx_user_profiles_%'
AND indexname NOT IN (
    'idx_user_profiles_role', 'idx_user_profiles_status', 'idx_user_profiles_created_at',
    'idx_user_profiles_role_status', 'idx_user_profiles_pk_performance', 
    'idx_user_profiles_role_status_performance', 'idx_user_profiles_created_at_admin',
    'idx_user_profiles_pharmacy_id'
);
\echo ''

-- Data Integrity Verification
\echo '3. DATA INTEGRITY VERIFICATION'
\echo 'User Profiles Record Count:'
SELECT COUNT(*) as total_user_profiles FROM user_profiles;
\echo ''

\echo 'New Fields Default State:'
SELECT 
    COUNT(CASE WHEN license_status IS NULL THEN 1 END) as license_status_null_count,
    COUNT(CASE WHEN identity_verified = false THEN 1 END) as identity_unverified_count,
    COUNT(CASE WHEN compliance_flags = '{}' THEN 1 END) as compliance_flags_empty_count
FROM user_profiles;
\echo ''

-- Rollback Capability Verification
\echo '4. ROLLBACK CAPABILITY VERIFICATION'
\echo 'Rollback Script Availability Check:'
\i tests/evidence/check-rollback-script.sql
\echo ''

-- System Performance Impact
\echo '5. SYSTEM PERFORMANCE IMPACT ASSESSMENT'
\echo 'Table Size Analysis:'
SELECT pg_size_pretty(pg_total_relation_size('user_profiles')) as total_table_size;
\echo ''

\echo 'Index Storage Impact:'
SELECT 
    'Business Field Indexes' as index_category,
    pg_size_pretty(SUM(pg_relation_size(indexname::regclass))) as total_size
FROM pg_indexes 
WHERE tablename = 'user_profiles' 
AND indexname LIKE 'idx_user_profiles_%'
AND indexname NOT IN (
    'idx_user_profiles_role', 'idx_user_profiles_status', 'idx_user_profiles_created_at',
    'idx_user_profiles_role_status', 'idx_user_profiles_pk_performance',
    'idx_user_profiles_role_status_performance', 'idx_user_profiles_created_at_admin',
    'idx_user_profiles_pharmacy_id'
);
\echo ''

-- Migration Completeness Verification
\echo '6. MIGRATION COMPLETENESS VERIFICATION'
\echo 'Function and Trigger Installation:'
SELECT 
    routine_name,
    routine_type,
    'INSTALLED' as status
FROM information_schema.routines
WHERE routine_name = 'sync_license_verification_status'
UNION ALL
SELECT 
    trigger_name,
    'TRIGGER' as routine_type,
    'INSTALLED' as status
FROM information_schema.triggers 
WHERE trigger_name = 'sync_license_verification_on_update'
AND event_object_table = 'user_profiles';
\echo ''

\echo '=== MIGRATION EXECUTION EVIDENCE COMPLETE ==='
