#!/bin/bash

# Email Template Configuration Test Script
# Tests Supabase email template configuration and role-based template selection
# Usage: ./tests/test-email-template-config.sh

set -e

echo "🧪 Testing Email Template Configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_TOTAL=0

# Helper function for test assertions
assert_file_exists() {
    local file="$1"
    local description="$2"
    ((TESTS_TOTAL++))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $description - File not found: $file"
    fi
}

assert_content_contains() {
    local file="$1"
    local content="$2"
    local description="$3"
    ((TESTS_TOTAL++))
    
    if [ -f "$file" ] && grep -q "$content" "$file"; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $description - Content not found in $file"
    fi
}

assert_valid_html() {
    local file="$1"
    local description="$2"
    ((TESTS_TOTAL++))
    
    if [ -f "$file" ]; then
        # Basic HTML structure validation
        if grep -q "<!DOCTYPE html>" "$file" && 
           grep -q "<html" "$file" && 
           grep -q "</html>" "$file" &&
           grep -q "<head>" "$file" &&
           grep -q "</head>" "$file" &&
           grep -q "<body>" "$file" &&
           grep -q "</body>" "$file"; then
            echo -e "${GREEN}✅ PASS${NC}: $description"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ FAIL${NC}: $description - Invalid HTML structure in $file"
        fi
    else
        echo -e "${RED}❌ FAIL${NC}: $description - File not found: $file"
    fi
}

echo -e "${BLUE}📁 Testing template directory structure...${NC}"

# Test 1: Template directory exists
assert_file_exists "supabase/templates" "Template directory exists"

# Test 2: Configuration file exists
assert_file_exists "supabase/config.toml" "Supabase configuration file exists"

echo -e "\n${BLUE}📧 Testing individual role templates...${NC}"

# Test 3-5: Individual role templates exist
assert_file_exists "supabase/templates/practitioner-signup-confirmation.html" "Practitioner signup template exists"
assert_file_exists "supabase/templates/pharmacy-signup-confirmation.html" "Pharmacy signup template exists" 
assert_file_exists "supabase/templates/admin-signup-confirmation.html" "Admin signup template exists"

# Test 6-8: Password recovery templates exist
assert_file_exists "supabase/templates/practitioner-password-recovery.html" "Practitioner recovery template exists"
assert_file_exists "supabase/templates/pharmacy-password-recovery.html" "Pharmacy recovery template exists"
assert_file_exists "supabase/templates/admin-password-recovery.html" "Admin recovery template exists"

# Test 9: Unified role-based template exists
assert_file_exists "supabase/templates/role-based-confirmation.html" "Unified role-based template exists"

echo -e "\n${BLUE}🔧 Testing Edge Function...${NC}"

# Test 10: Edge function exists
assert_file_exists "supabase/functions/auth-email-template-selector/index.ts" "Email template selector Edge Function exists"

echo -e "\n${BLUE}📝 Testing template content...${NC}"

# Test 11-13: Template content validation - Practitioner theme
assert_content_contains "supabase/templates/practitioner-signup-confirmation.html" "🌿 TCM Prescription Platform" "Practitioner template contains brand icon"
assert_content_contains "supabase/templates/practitioner-signup-confirmation.html" "Professional Verification Required" "Practitioner template mentions verification"
assert_content_contains "supabase/templates/practitioner-signup-confirmation.html" "HIPAA compliance" "Practitioner template mentions HIPAA"

# Test 14-16: Template content validation - Pharmacy theme  
assert_content_contains "supabase/templates/pharmacy-signup-confirmation.html" "💊 TCM Prescription Platform" "Pharmacy template contains brand icon"
assert_content_contains "supabase/templates/pharmacy-signup-confirmation.html" "QR Code Fulfillment System" "Pharmacy template mentions QR fulfillment"
assert_content_contains "supabase/templates/pharmacy-signup-confirmation.html" "Business Verification Required" "Pharmacy template mentions business verification"

# Test 17-19: Template content validation - Admin theme
assert_content_contains "supabase/templates/admin-signup-confirmation.html" "⚖️ TCM Platform Administration" "Admin template contains admin icon"
assert_content_contains "supabase/templates/admin-signup-confirmation.html" "Administrative Access Security" "Admin template mentions security"
assert_content_contains "supabase/templates/admin-signup-confirmation.html" "multi-factor authentication" "Admin template mentions MFA"

echo -e "\n${BLUE}🔒 Testing security compliance...${NC}"

# Test 20-22: Security content validation - No PII exposure
template_files=("supabase/templates/practitioner-signup-confirmation.html" 
                "supabase/templates/pharmacy-signup-confirmation.html" 
                "supabase/templates/admin-signup-confirmation.html")

for template_file in "${template_files[@]}"; do
    ((TESTS_TOTAL++))
    if [ -f "$template_file" ]; then
        # Check that templates don't contain prohibited patient information patterns
        if ! grep -i -E "(patient|medical_record|diagnosis|treatment_plan|health_condition)" "$template_file" >/dev/null; then
            echo -e "${GREEN}✅ PASS${NC}: $(basename $template_file) - No PII patterns found"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ FAIL${NC}: $(basename $template_file) - Contains potentially sensitive medical patterns"
        fi
    else
        echo -e "${RED}❌ FAIL${NC}: $(basename $template_file) - File not found"
    fi
done

echo -e "\n${BLUE}📐 Testing HTML structure validation...${NC}"

# Test 23-25: HTML structure validation
assert_valid_html "supabase/templates/practitioner-signup-confirmation.html" "Practitioner template has valid HTML"
assert_valid_html "supabase/templates/pharmacy-signup-confirmation.html" "Pharmacy template has valid HTML"
assert_valid_html "supabase/templates/admin-signup-confirmation.html" "Admin template has valid HTML"

echo -e "\n${BLUE}⚙️ Testing configuration...${NC}"

# Test 26-28: Configuration validation
assert_content_contains "supabase/config.toml" "[auth.email.template.confirmation]" "Config contains confirmation template"
assert_content_contains "supabase/config.toml" "[auth.hook.send_email]" "Config contains email hook"
assert_content_contains "supabase/config.toml" "auth-email-template-selector" "Config references template selector function"

echo -e "\n${BLUE}🧪 Testing Edge Function content...${NC}"

# Test 29-31: Edge Function validation
assert_content_contains "supabase/functions/auth-email-template-selector/index.ts" "tcm_practitioner" "Edge Function handles practitioner role"
assert_content_contains "supabase/functions/auth-email-template-selector/index.ts" "pharmacy" "Edge Function handles pharmacy role"
assert_content_contains "supabase/functions/auth-email-template-selector/index.ts" "admin" "Edge Function handles admin role"

echo -e "\n${BLUE}📊 Testing TypeScript test file...${NC}"

# Test 32: TypeScript test file exists and is valid
assert_file_exists "tests/email-templates.test.ts" "Email template TypeScript tests exist"

if [ -f "tests/email-templates.test.ts" ]; then
    ((TESTS_TOTAL++))
    # Basic TypeScript syntax check
    if grep -q "Deno.test" "tests/email-templates.test.ts" && 
       grep -q "assertEquals" "tests/email-templates.test.ts"; then
        echo -e "${GREEN}✅ PASS${NC}: TypeScript tests contain proper Deno test structure"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: TypeScript tests missing proper Deno test structure"
    fi
fi

# Final results
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}📊 EMAIL TEMPLATE TEST RESULTS${NC}"
echo -e "${YELLOW}========================================${NC}"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}✅ $TESTS_PASSED/$TESTS_TOTAL tests completed successfully${NC}"
    echo -e "\n${GREEN}📧 Role-specific email templates are properly configured${NC}"
    echo -e "${GREEN}🔒 Security compliance validated${NC}"
    echo -e "${GREEN}⚙️ Supabase configuration ready for deployment${NC}"
    exit 0
else
    echo -e "${RED}❌ TESTS FAILED!${NC}"
    echo -e "${RED}❌ $TESTS_PASSED/$TESTS_TOTAL tests passed${NC}"
    echo -e "${RED}❌ $((TESTS_TOTAL - TESTS_PASSED)) tests failed${NC}"
    echo -e "\n${YELLOW}🔧 Please fix the failing tests before proceeding${NC}"
    exit 1
fi