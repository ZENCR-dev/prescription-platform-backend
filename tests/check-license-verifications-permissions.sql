-- Check current permissions on license_verifications table
-- This script verifies the RLS permissions state

-- Check table privileges for authenticated role
SELECT 
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE 
    grantee = 'authenticated' 
    AND table_schema = 'public' 
    AND table_name = 'license_verifications'
ORDER BY privilege_type;

-- Check if the table exists
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'license_verifications'
) as table_exists;

-- Check RLS policies
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'license_verifications';