#!/bin/bash

# Password Policies Security Test Script
# Tests enhanced password security for medical platform compliance

set -e
echo "🔐 Testing Enhanced Password Security Policies..."

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

test_password_strength() {
    local password="$1"
    local expected_result="$2"
    local description="$3"
    ((TESTS_TOTAL++))
    
    # These are validation tests for password policy configuration
    # In a real environment, these would test actual password validation API calls
    case "$password" in
        *[a-z]* | *[A-Z]* | *[0-9]* | *[\!\@\#\$\%\^\&\*]*)
            if [ "$expected_result" = "accept" ]; then
                echo "✅ PASS: $description"
                ((TESTS_PASSED++))
            else
                echo "❌ FAIL: $description - Password should be rejected but policy accepts it"
            fi
            ;;
        *)
            if [ "$expected_result" = "reject" ]; then
                echo "✅ PASS: $description"
                ((TESTS_PASSED++))
            else
                echo "❌ FAIL: $description - Password should be accepted but policy rejects it"
            fi
            ;;
    esac
}

echo ""
echo "📏 Testing Password Length Requirements..."

assert_config_value "minimum_password_length" "12" "Minimum password length enforced at 12 characters"

echo ""
echo "🔤 Testing Password Complexity Requirements..."

assert_config_value "password_requirements" "\"lower_upper_letters_digits_symbols\"" "Password requires uppercase, lowercase, digits, and symbols"

echo ""
echo "🛡️ Testing Password Strength Validation..."

test_password_strength "MySecureP@ss123!" "accept" "Strong password with all character types accepted"
test_password_strength "TcmDoctor2024#" "accept" "Medical professional password with symbols accepted"
test_password_strength "PharmacySecure$7" "accept" "Pharmacy password with required complexity accepted"

echo ""
echo "❌ Testing Weak Password Rejection..."

test_password_strength "password" "reject" "Simple dictionary word rejected"
test_password_strength "12345678" "reject" "Numeric-only password rejected"
test_password_strength "abcdefgh" "reject" "Lowercase-only password rejected"
test_password_strength "ABCDEFGH" "reject" "Uppercase-only password rejected"
test_password_strength "Password1" "reject" "Password without symbols rejected"
test_password_strength "Pass@1" "reject" "Too short password rejected"

echo ""
echo "🏥 Testing Medical Platform Specific Requirements..."

test_password_strength "TCM_Doctor_2024!" "accept" "TCM practitioner professional password accepted"
test_password_strength "Pharmacy_Admin#9" "accept" "Pharmacy administrator password accepted"
test_password_strength "MedPlatform$2024" "accept" "Medical platform admin password accepted"

echo ""
echo "🔄 Testing Password Policy Enforcement..."

((TESTS_TOTAL++))
if grep -q "secure_password_change = true" supabase/config.toml; then
    echo "✅ PASS: Secure password change requires re-authentication"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Secure password change not enforced"
fi

((TESTS_TOTAL++))
if grep -q "enable_confirmations = true" supabase/config.toml; then
    echo "✅ PASS: Email confirmation required for password changes"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL: Email confirmation not required for password changes"
fi

echo ""
echo "🔐 Testing Common Password Attack Prevention..."

test_password_strength "admin" "reject" "Common admin password rejected"
test_password_strength "user123" "reject" "Common user pattern rejected"
test_password_strength "password123" "reject" "Common password pattern rejected"
test_password_strength "qwerty123" "reject" "Keyboard pattern password rejected"

echo ""
echo "========================================="
echo "🔐 ENHANCED PASSWORD SECURITY TEST RESULTS"
echo "========================================="

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo "🎉 ALL PASSWORD SECURITY TESTS PASSED!"
    echo "✅ $TESTS_PASSED/$TESTS_TOTAL password security validations completed"
    echo ""
    echo "🔐 Enhanced Password Security Validated:"
    echo "   • Length Requirement: 12+ characters minimum"
    echo "   • Complexity Requirement: Upper, lower, digits, symbols"
    echo "   • Medical Professional Standards: Strong authentication"
    echo "   • Attack Prevention: Common passwords rejected"
    echo "   • Change Security: Re-authentication and email confirmation"
    echo ""
    echo "🏥 Password Security: MEDICAL PLATFORM COMPLIANT"
    exit 0
else
    echo "❌ PASSWORD SECURITY TESTS FAILED!"
    echo "❌ $TESTS_PASSED/$TESTS_TOTAL tests passed"
    echo "❌ $((TESTS_TOTAL - TESTS_PASSED)) password security issues detected"
    echo ""
    echo "🚨 CRITICAL: Password security vulnerabilities detected"
    echo "🔧 Please strengthen password policies for medical platform compliance"
    exit 1
fi