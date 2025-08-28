#!/bin/bash

# Simplified Auth Security Validation for Task 1.3 Step 3
# Focus on core security configurations validation

set -e
echo "🔒 Validating Auth Security Configuration..."

TESTS_PASSED=0
TESTS_TOTAL=0

validate_setting() {
    local setting_name="$1"
    local pattern="$2"
    local description="$3"
    ((TESTS_TOTAL++))
    
    if grep -q "$pattern" supabase/config.toml; then
        echo "✅ PASS: $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $description"
        return 1
    fi
}

echo ""
echo "🔐 Core Security Settings Validation..."

# Password Security
validate_setting "password_length" "minimum_password_length = 12" "Password minimum length (12 characters)"
validate_setting "password_complexity" "password_requirements.*symbols" "Password complexity (requires symbols)"

# Rate Limiting  
validate_setting "email_rate_limit" "email_sent = 10" "Email rate limiting (10/hour)"
validate_setting "login_rate_limit" "sign_in_sign_ups = 15" "Login rate limiting (15/5min)"
validate_setting "token_rate_limit" "token_verifications = 20" "Token verification limiting (20/5min)"

# Session Management
validate_setting "session_timebox" "timebox.*8h" "Session maximum duration (8 hours)"
validate_setting "session_inactivity" "inactivity_timeout.*2h" "Session inactivity timeout (2 hours)"

# JWT Security
validate_setting "jwt_expiry" "jwt_expiry = 1800" "JWT token expiry (30 minutes)"
validate_setting "token_rotation" "enable_refresh_token_rotation = true" "Refresh token rotation"

# MFA Configuration
validate_setting "mfa_factors" "max_enrolled_factors = 3" "MFA maximum factors (3)"
validate_setting "totp_enroll" "enroll_enabled = true" "TOTP enrollment enabled"
validate_setting "totp_verify" "verify_enabled = true" "TOTP verification enabled"

# Email Security
validate_setting "email_confirmation" "enable_confirmations = true" "Email confirmation required"
validate_setting "secure_password_change" "secure_password_change = true" "Secure password change"

echo ""
echo "========================================="
echo "🔒 SECURITY VALIDATION RESULTS"
echo "========================================="

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo "🎉 ALL SECURITY VALIDATIONS PASSED!"
    echo "✅ $TESTS_PASSED/$TESTS_TOTAL security settings validated"
    echo ""
    echo "🔐 Security Configuration Summary:"
    echo "   • Strong password policies (12+ chars, symbols required)"
    echo "   • Rate limiting protections (email, login, token verification)"
    echo "   • Secure session management (8h max, 2h inactivity)"
    echo "   • Enhanced JWT security (30min expiry, token rotation)"
    echo "   • MFA support ready (TOTP enabled, up to 3 factors)"
    echo "   • Email security enforced (confirmation required)"
    echo ""
    echo "🏥 Medical Platform Security: CONFIGURED ✅"
    exit 0
else
    echo "❌ SECURITY VALIDATION FAILED!"
    echo "❌ $TESTS_PASSED/$TESTS_TOTAL settings validated"
    echo "❌ $((TESTS_TOTAL - TESTS_PASSED)) security issues detected"
    echo ""
    echo "🚨 Security configuration needs review"
    exit 1
fi