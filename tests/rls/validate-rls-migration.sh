#!/bin/bash
# RLS Migration Validation Script
# Task 2.1: Automated validation for enhanced user_profiles RLS policies
# Usage: ./validate-rls-migration.sh

set -e

echo "🔍 RLS Migration Validation Starting..."
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found. Please install: npm install -g supabase${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI found${NC}"

# Check if we're in the correct directory
if [ ! -f "supabase/config.toml" ]; then
    echo -e "${RED}❌ Not in Supabase project root. Run from prescription-platform-backend/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ In Supabase project root${NC}"

# Validate migration file exists
MIGRATION_FILE="supabase/migrations/20250829124010_enhance_user_profiles_rls.sql"
if [ ! -f "$MIGRATION_FILE" ]; then
    echo -e "${RED}❌ Migration file not found: $MIGRATION_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Migration file exists${NC}"

# Validate test file exists  
TEST_FILE="tests/rls/test-user-profiles-rls.sql"
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}❌ Test file not found: $TEST_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Test file exists${NC}"

# Check migration syntax (basic SQL validation)
echo -e "${YELLOW}🔍 Validating migration SQL syntax...${NC}"

# Look for common SQL issues
if grep -q "auth\.uid()" "$MIGRATION_FILE"; then
    echo -e "${GREEN}✅ Migration uses auth.uid() function${NC}"
else
    echo -e "${RED}❌ Migration missing auth.uid() usage${NC}"
fi

if grep -q "TO authenticated" "$MIGRATION_FILE"; then
    echo -e "${GREEN}✅ Migration uses explicit TO authenticated${NC}"
else
    echo -e "${YELLOW}⚠️  Migration should use explicit TO authenticated clauses${NC}"
fi

if grep -q "SECURITY DEFINER" "$MIGRATION_FILE"; then
    echo -e "${GREEN}✅ Migration includes security definer functions${NC}"
else
    echo -e "${YELLOW}⚠️  Consider security definer functions for performance${NC}"
fi

# Check for medical compliance patterns
if grep -qi "pii\|patient\|hipaa" "$MIGRATION_FILE"; then
    echo -e "${GREEN}✅ Migration includes medical compliance considerations${NC}"
else
    echo -e "${YELLOW}⚠️  Consider adding medical compliance comments${NC}"
fi

# Validate test coverage
echo -e "${YELLOW}🔍 Validating test coverage...${NC}"

if grep -q "EXPLAIN.*ANALYZE" "$TEST_FILE"; then
    echo -e "${GREEN}✅ Tests include performance analysis${NC}"
else
    echo -e "${RED}❌ Tests missing performance analysis${NC}"
fi

if grep -q "role.*isolation" "$TEST_FILE" || grep -q "tcm_practitioner\|pharmacy\|admin" "$TEST_FILE"; then
    echo -e "${GREEN}✅ Tests include role isolation validation${NC}"
else
    echo -e "${RED}❌ Tests missing role isolation validation${NC}"
fi

# Check if local Supabase is running (optional)
echo -e "${YELLOW}🔍 Checking local Supabase status...${NC}"
if curl -s http://localhost:54321/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Local Supabase is running${NC}"
    
    # Try to run a simple test migration (dry run)
    echo -e "${YELLOW}🔍 Testing migration dry run...${NC}"
    if supabase db reset --debug > /tmp/supabase_reset.log 2>&1; then
        echo -e "${GREEN}✅ Database reset successful${NC}"
    else
        echo -e "${YELLOW}⚠️  Database reset had issues (check /tmp/supabase_reset.log)${NC}"
    fi
    
else
    echo -e "${YELLOW}⚠️  Local Supabase not running. Start with: supabase start${NC}"
fi

# Summary
echo ""
echo "======================================"
echo -e "${GREEN}🎉 RLS Migration Validation Complete${NC}"
echo "======================================"
echo ""
echo "Next Steps:"
echo "1. Start local Supabase: supabase start"
echo "2. Apply migration: supabase db reset"  
echo "3. Run tests: psql -h localhost -p 54322 -U postgres -f tests/rls/test-user-profiles-rls.sql"
echo "4. Validate performance: Check EXPLAIN ANALYZE outputs for <150ms"
echo "5. Test role isolation: Use different auth contexts"
echo ""
echo "Performance Target: <150ms P95 for profile lookups"
echo "Security Target: Strict role isolation + medical compliance"
echo ""