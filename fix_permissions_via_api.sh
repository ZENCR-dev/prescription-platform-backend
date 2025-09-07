#!/bin/bash
# ============================================================================
# VIEW PERMISSIONS SECURITY FIX - API METHOD
# ============================================================================
# Purpose: Fix excessive permissions using Supabase service role API
# Method: Direct SQL execution via Supabase API
# ============================================================================

echo "Executing permissions fix via Supabase API..."

# Get service role key from frontend .env.local
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvc2Jldmdia3hydGl4ZW1mamZsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDIwNzAyMSwiZXhwIjoyMDY5NzgzMDIxfQ.YP5G83U-qVWqqCuAcEHUxFCE7f7mAyxR4T2cA3fQe_Y"

# Execute REVOKE statements
curl -X POST "https://dosbevgbkxrtixemfjfl.supabase.co/rest/v1/rpc/exec_sql" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "REVOKE ALL ON public.v_profiles_tcm_context FROM authenticated; REVOKE ALL ON public.v_profiles_pharmacy_context FROM authenticated; REVOKE ALL ON public.v_profiles_public FROM authenticated;"
  }'

echo "Revoking permissions..."

# Execute GRANT statements  
curl -X POST "https://dosbevgbkxrtixemfjfl.supabase.co/rest/v1/rpc/exec_sql" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "GRANT SELECT ON public.v_profiles_tcm_context TO authenticated; GRANT SELECT ON public.v_profiles_pharmacy_context TO authenticated; GRANT SELECT ON public.v_profiles_public TO authenticated;"
  }'

echo "Granting SELECT-only permissions..."

# Verify permissions
curl -X POST "https://dosbevgbkxrtixemfjfl.supabase.co/rest/v1/rpc/exec_sql" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "SELECT table_name, privilege_type, grantee FROM information_schema.role_table_grants WHERE table_schema='\''public'\'' AND table_name IN ('\''v_profiles_tcm_context'\'','\''v_profiles_pharmacy_context'\'','\''v_profiles_public'\'') AND grantee='\''authenticated'\'' ORDER BY table_name, privilege_type;"
  }'

echo "Permissions fix completed."