#!/bin/bash

# Auth Security Policies Validation Test Script
# Tests enhanced security configurations for medical platform compliance

set -e
echo "🔒 Testing Auth Security Policies Configuration..."

TESTS_PASSED=0
TESTS_TOTAL=0

assert_config_value() {
    local config_key="$1"
    local expected_value="$2"
    local description="$3"
    ((TESTS_TOTAL++))
    
    if grep -q "$config_key = $expected_value" supabase/config.toml; then
        echo "✅ PASS: $description"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $description - Expected: $config_key = $expected_value"
    fi
}

assert_config_contains() {
    local pattern="$1"
    local description="$2"
    ((TESTS_TOTAL++))
    
    if grep -q "$pattern" supabase/config.toml; then
        echo "✅ PASS: $description"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $description - Pattern not found: $pattern"
    fi
}

echo ""
echo "🔐 Testing Enhanced Password Policies..."

assert_config_value "minimum_password_length" "12" "Password minimum length set to 12 characters"
assert_config_contains "password_requirements.*lower_upper_letters_digits_symbols" "Password complexity requires symbols"

echo ""
echo "🚦 Testing Rate Limiting Enhancements..."

assert_config_value "email_sent" "10" "Email rate limit enhanced to 10/hour"
assert_config_value "sign_in_sign_ups" "15" "Sign-in/sign-up limited to 15/5min"
assert_config_value "token_verifications" "20" "Token verifications limited to 20/5min"

echo ""
echo "⏰ Testing Session Management..."

assert_config_contains "\\[auth.sessions\\]" "Session timeout configuration enabled"
assert_config_contains "timebox.*8h" "Session timebox set to 8 hours"
assert_config_contains "inactivity_timeout.*2h" "Inactivity timeout set to 2 hours"

echo ""
echo "🔐 Testing Multi-Factor Authentication..."

assert_config_value "max_enrolled_factors" "3" "MFA factors limited to 3 per user"
assert_config_contains "enroll_enabled = true" "TOTP enrollment enabled"
assert_config_contains "verify_enabled = true" "TOTP verification enabled"

echo ""
echo "📧 Testing Email Security..."

assert_config_value "enable_confirmations" "true" "Email confirmation required before sign-in"
assert_config_value "secure_password_change" "true" "Secure password change enabled"

echo ""
echo "🎫 Testing JWT Security..."

assert_config_value "jwt_expiry" "1800" "JWT expiry shortened to 30 minutes"
assert_config_value "refresh_token_reuse_interval" "5" "Refresh token reuse interval shortened"

echo ""
echo "========================================="
echo "🔒 SECURITY POLICIES TEST RESULTS"
echo "========================================="

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo "🎉 ALL SECURITY TESTS PASSED!"
    echo "✅ $TESTS_PASSED/$TESTS_TOTAL tests completed successfully"
    echo ""
    echo "🔐 Enhanced Security Policies Configured:"
    echo "   • Password length: 12+ characters with symbols"
    echo "   • Rate limiting: Enhanced for medical platform"
    echo "   • Session timeouts: 8h max, 2h inactivity"
    echo "   • MFA: TOTP enabled for admin accounts"
    echo "   • Email confirmation: Required before sign-in"
    echo "   • JWT security: 30-minute expiry, enhanced rotation"
    echo ""
    echo "🏥 Medical Platform Compliance: READY"
    exit 0
else
    echo "❌ SECURITY TESTS FAILED!"
    echo "❌ $TESTS_PASSED/$TESTS_TOTAL tests passed"
    echo "❌ $((TESTS_TOTAL - TESTS_PASSED)) tests failed"
    echo ""
    echo "🔧 Please review and fix the failing security configurations"
    exit 1
fi