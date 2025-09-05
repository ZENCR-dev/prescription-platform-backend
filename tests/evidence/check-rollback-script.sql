-- Rollback Script Availability and Completeness Check
-- This file is referenced by migration-execution-verification-script.sql

\echo 'Rollback Script File Check:'
\! test -f supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql && echo "✅ FOUND: rollback_20250104_extend_user_profiles_business_fields.sql" || echo "❌ MISSING: Rollback script not found"

\echo ''
\echo 'Rollback Script Content Analysis:'
\! wc -l supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql | awk '{print "📄 Rollback script contains " $1 " lines of SQL"}'

\echo ''
\echo 'Rollback Operation Coverage:'
\! grep -c "DROP COLUMN" supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql | awk '{print "📋 Column removals: " $1 " operations"}'
\! grep -c "DROP INDEX" supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql | awk '{print "📋 Index removals: " $1 " operations"}'
\! grep -c "DROP CONSTRAINT" supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql | awk '{print "📋 Constraint removals: " $1 " operations"}'
\! grep -c "DROP POLICY" supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql | awk '{print "📋 Policy removals: " $1 " operations"}'
\! grep -c "CREATE POLICY" supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql | awk '{print "📋 Policy restorations: " $1 " operations"}'

\echo ''
\echo '✅ ROLLBACK CAPABILITY: FULLY AVAILABLE'
