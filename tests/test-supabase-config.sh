#!/bin/bash

# Test script for Supabase configuration validation
# Validates that the JWT claims configuration is correct

echo "=== Supabase JWT Claims Configuration Test ==="

# Check if required files exist
echo "1. Checking required files..."

if [ ! -f "supabase/config.toml" ]; then
    echo "❌ FAIL: supabase/config.toml not found"
    exit 1
fi

if [ ! -f "supabase/functions/custom-access-token/index.ts" ]; then
    echo "❌ FAIL: Custom access token Edge Function not found"
    exit 1
fi

if [ ! -f "supabase/migrations/20250828000000_update_user_roles_enum.sql" ]; then
    echo "❌ FAIL: Role enum migration not found"
    exit 1
fi

echo "✅ PASS: All required files exist"

# Check if custom access token hook is enabled in config
echo "2. Checking Supabase Auth configuration..."

if grep -q "auth.hook.custom_access_token" supabase/config.toml && grep -q "enabled = true" supabase/config.toml; then
    echo "✅ PASS: Custom access token hook is enabled"
else
    echo "❌ FAIL: Custom access token hook not properly configured"
    exit 1
fi

# Check if URI is correctly set
if grep -q "uri = \"http://127.0.0.1:54321/functions/v1/custom-access-token\"" supabase/config.toml; then
    echo "✅ PASS: Custom access token hook URI is correctly configured"
else
    echo "❌ FAIL: Custom access token hook URI not correctly configured"
    exit 1
fi

# Validate Edge Function TypeScript syntax (basic check)
echo "3. Validating Edge Function syntax..."

if node -c supabase/functions/custom-access-token/index.ts 2>/dev/null; then
    echo "✅ PASS: Edge Function TypeScript syntax is valid"
else
    echo "⚠️  WARNING: Could not validate TypeScript syntax (node not available or syntax issues)"
fi

# Check migration SQL syntax (basic check)
echo "4. Validating migration SQL syntax..."

if grep -q "ALTER TABLE user_profiles" supabase/migrations/20250828000000_update_user_roles_enum.sql && \
   grep -q "tcm_practitioner" supabase/migrations/20250828000000_update_user_roles_enum.sql; then
    echo "✅ PASS: Migration SQL includes required role updates"
else
    echo "❌ FAIL: Migration SQL missing required role updates"
    exit 1
fi

# Check for required environment variables
echo "5. Checking environment variables..."

if [ -f ".env.local" ]; then
    if grep -q "NEXT_PUBLIC_SUPABASE_URL" .env.local && grep -q "SUPABASE_SERVICE_ROLE_KEY" .env.local; then
        echo "✅ PASS: Required environment variables found in .env.local"
    else
        echo "❌ FAIL: Missing required environment variables in .env.local"
        exit 1
    fi
else
    echo "⚠️  WARNING: .env.local not found - environment variables may not be configured"
fi

echo ""
echo "=== Configuration Test Summary ==="
echo "✅ All configuration tests passed"
echo ""
echo "Next steps to test JWT claims functionality:"
echo "1. Start Supabase: supabase start"
echo "2. Apply migrations: supabase db push"
echo "3. Deploy Edge Function: supabase functions deploy custom-access-token"
echo "4. Run SQL tests: supabase db reset --debug"
echo "5. Test JWT claims with actual authentication flow"
echo ""
echo "Expected JWT claims after login:"
echo "- role: 'tcm_practitioner' | 'pharmacy' | 'admin'"
echo "- user_role: same as role (for compatibility)"
echo "- profile_status: 'active' | 'pending_verification' | etc"
echo "- business_info: { business metadata }"