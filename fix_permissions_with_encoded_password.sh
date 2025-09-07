#!/bin/bash
# ============================================================================
# VIEW PERMISSIONS SECURITY FIX - URL ENCODED PASSWORD VERSION
# ============================================================================
# Purpose: Fix excessive permissions on controlled views with proper password encoding
# Issue: Password contains '@' character causing connection string parsing errors
# Solution: URL encode the password and use proper connection format
# ============================================================================

# URL encode '@' as '%40' in password
# If password is "abc@def", use "abc%40def" in connection string

echo "Executing permissions fix with URL-encoded password..."

# Method 1: Using PGPASSWORD environment variable (recommended)
export PGPASSWORD="your_actual_password_here"
psql -h db.dosbevgbkxrtixemfjfl.supabase.co -p 5432 -U postgres -d postgres -f fix_view_permissions.sql

# Method 2: URL-encoded connection string (if needed)
# Replace @ with %40 in the password
# psql "postgresql://postgres:your_password_with_%40_instead_of_@/db.dosbevgbkxrtixemfjfl.supabase.co:5432/postgres" -f fix_view_permissions.sql

echo "Permissions fix completed. Verifying results..."

# Verification query
export PGPASSWORD="your_actual_password_here"
psql -h db.dosbevgbkxrtixemfjfl.supabase.co -p 5432 -U postgres -d postgres -c "
SELECT 'VERIFICATION_RESULT' AS category, table_name, privilege_type, grantee
FROM information_schema.role_table_grants
WHERE table_schema='public'
  AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
  AND grantee='authenticated'
ORDER BY table_name, privilege_type;
"