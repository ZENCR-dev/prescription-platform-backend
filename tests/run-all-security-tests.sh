#!/bin/bash

# Comprehensive Security Test Suite Runner
# Executes all security tests for Task 1.3 Step 3 validation

set -e

echo "🛡️ COMPREHENSIVE SECURITY TEST SUITE"
echo "========================================="
echo "Task 1.3 Step 3: Enhanced Security Testing & Optimization"
echo "Medical Platform Authentication Security Validation"
echo ""

# Colors for output (if terminal supports them)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TOTAL_TEST_SUITES=6
PASSED_TEST_SUITES=0
FAILED_TEST_SUITES=0

# Test suite execution function
run_test_suite() {
    local test_script="$1"
    local test_name="$2"
    local test_description="$3"
    
    echo ""
    echo "🔍 EXECUTING: $test_name"
    echo "📋 Description: $test_description"
    echo "🚀 Running: $test_script"
    echo ""
    
    if [ -f "$test_script" ]; then
        chmod +x "$test_script"
        if "$test_script"; then
            echo ""
            echo "✅ $test_name: PASSED"
            ((PASSED_TEST_SUITES++))
        else
            echo ""
            echo "❌ $test_name: FAILED"
            ((FAILED_TEST_SUITES++))
        fi
    else
        echo "⚠️  Test script not found: $test_script"
        ((FAILED_TEST_SUITES++))
    fi
    
    echo ""
    echo "----------------------------------------"
}

# Pre-test validation
echo "📋 Pre-Test Validation..."
echo "🔍 Checking Supabase configuration..."

if [ ! -f "supabase/config.toml" ]; then
    echo "❌ CRITICAL: supabase/config.toml not found"
    echo "🔧 Please ensure Supabase configuration is properly set up"
    exit 1
fi

echo "✅ Supabase configuration found"
echo "🔍 Checking security test directory..."

if [ ! -d "tests/security" ]; then
    echo "❌ CRITICAL: tests/security directory not found"
    echo "🔧 Please ensure security tests are properly installed"
    exit 1
fi

echo "✅ Security tests directory found"
echo ""

# Execute all security test suites
echo "🚀 STARTING COMPREHENSIVE SECURITY TEST EXECUTION"
echo "========================================="

# 1. Basic Security Policies Validation
run_test_suite "tests/test-auth-security-policies.sh" \
               "BASIC SECURITY POLICIES" \
               "Validate basic authentication security policy configuration"

# 2. Role Boundaries Testing
run_test_suite "tests/security/test-role-boundaries.sh" \
               "ROLE BOUNDARIES & ISOLATION" \
               "Verify role-based access control and data isolation"

# 3. Password Policies Testing
run_test_suite "tests/security/test-password-policies.sh" \
               "ENHANCED PASSWORD SECURITY" \
               "Validate password strength and security policies"

# 4. Rate Limiting Testing
run_test_suite "tests/security/test-rate-limiting.sh" \
               "RATE LIMITING & DDOS PROTECTION" \
               "Verify rate limiting and attack protection measures"

# 5. Session Management Testing
run_test_suite "tests/security/test-session-management.sh" \
               "SESSION MANAGEMENT SECURITY" \
               "Validate session timeout and JWT security policies"

# 6. MFA Workflows Testing
run_test_suite "tests/security/test-mfa-workflows.sh" \
               "MULTI-FACTOR AUTHENTICATION" \
               "Verify MFA configuration and security workflows"

# 7. Medical Platform Compliance Testing
run_test_suite "tests/security/test-medical-compliance.sh" \
               "MEDICAL PLATFORM COMPLIANCE" \
               "Validate HIPAA and medical platform specific requirements"

echo ""
echo "========================================="
echo "🛡️ COMPREHENSIVE SECURITY TEST RESULTS"
echo "========================================="

if [ $FAILED_TEST_SUITES -eq 0 ]; then
    echo "🎉 ALL SECURITY TEST SUITES PASSED!"
    echo "✅ $PASSED_TEST_SUITES/$TOTAL_TEST_SUITES test suites completed successfully"
    echo ""
    echo "🏥 MEDICAL PLATFORM AUTHENTICATION SECURITY STATUS"
    echo "========================================="
    echo "✅ Basic Security Policies: CONFIGURED"
    echo "✅ Role-Based Access Control: IMPLEMENTED"
    echo "✅ Enhanced Password Security: ENFORCED"
    echo "✅ Rate Limiting Protection: ACTIVE"
    echo "✅ Session Management: SECURE"
    echo "✅ Multi-Factor Authentication: READY"
    echo "✅ Medical Compliance: HIPAA COMPLIANT"
    echo ""
    echo "🔒 SECURITY ARCHITECTURE STATUS"
    echo "========================================="
    echo "• Password Policy: 12+ chars with symbols required"
    echo "• Rate Limiting: Enhanced protection against attacks"
    echo "• Session Security: 8h max, 2h inactivity timeout"
    echo "• JWT Security: 30-minute expiry with token rotation"
    echo "• MFA Support: TOTP enabled for admin accounts"
    echo "• Role Isolation: Practitioner/Pharmacy/Admin separated"
    echo "• HIPAA Compliance: Zero-PII architecture enforced"
    echo ""
    echo "🚀 TASK 1.3 STEP 3: READY FOR COMMIT"
    echo "🎯 Next Action: Execute Step 4 - Quality Gates & Commit"
    echo ""
    echo "Git Commands Ready:"
    echo "git add tests/security/ tests/run-all-security-tests.sh"
    echo "git commit -m \"feat(M1.1): Task 1.3 Step 3 - Comprehensive security testing suite\""
    exit 0
else
    echo "❌ SECURITY TEST FAILURES DETECTED!"
    echo "❌ $PASSED_TEST_SUITES/$TOTAL_TEST_SUITES test suites passed"
    echo "❌ $FAILED_TEST_SUITES test suites failed"
    echo ""
    echo "🚨 CRITICAL SECURITY ISSUES"
    echo "========================================="
    echo "Security vulnerabilities have been detected in the authentication"
    echo "infrastructure. These must be resolved before proceeding."
    echo ""
    echo "🔧 REQUIRED ACTIONS:"
    echo "1. Review failed test output above"
    echo "2. Fix security configuration issues"
    echo "3. Re-run security tests: ./tests/run-all-security-tests.sh"
    echo "4. Only proceed to commit when all tests pass"
    echo ""
    echo "⚠️  DO NOT DEPLOY TO PRODUCTION WITH SECURITY FAILURES"
    exit 1
fi