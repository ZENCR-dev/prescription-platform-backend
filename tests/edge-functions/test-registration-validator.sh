#!/bin/bash

# Test script for registration-validator Edge Function
# This script tests the Edge Function both locally and remotely

set -e

echo "=========================================="
echo "Registration Validator Edge Function Tests"
echo "=========================================="

# Check if running locally or against production
if [ "$1" = "production" ]; then
    FUNCTION_URL="https://dosbevgbkxrtixemfjfl.supabase.co/functions/v1/registration-validator"
    ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    echo "Testing against PRODUCTION environment"
else
    FUNCTION_URL="http://localhost:54321/functions/v1/registration-validator"
    ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    echo "Testing against LOCAL environment"
fi

echo ""
echo "Function URL: $FUNCTION_URL"
echo ""

# Helper function to make requests and measure time
test_request() {
    local test_name="$1"
    local payload="$2"
    local expected_status="$3"
    
    echo "----------------------------------------"
    echo "Test: $test_name"
    echo "Payload: $payload"
    
    start_time=$(date +%s%N)
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$FUNCTION_URL" \
        -H "Authorization: Bearer $ANON_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    end_time=$(date +%s%N)
    elapsed=$((($end_time - $start_time) / 1000000))
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    echo "Response: $body"
    echo "Status Code: $http_code (expected: $expected_status)"
    echo "Response Time: ${elapsed}ms"
    
    if [ "$http_code" = "$expected_status" ]; then
        echo "✅ Test PASSED"
    else
        echo "❌ Test FAILED - Wrong status code"
        exit 1
    fi
    
    if [ $elapsed -gt 500 ]; then
        echo "⚠️  WARNING: Response time exceeds 500ms target"
    fi
    
    echo ""
}

# Test 1: Valid TCM Practitioner Registration
echo "=== TEST 1: Valid TCM Practitioner ==="
FUTURE_DATE=$(date -u -v+90d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+90 days" +"%Y-%m-%dT%H:%M:%SZ")
test_request "Valid TCM Practitioner" '{
  "role": "tcm_practitioner",
  "data": {
    "email": "dr.test'$(date +%s)'@clinic.com",
    "password": "SecurePass123!@#",
    "full_name": "Dr. Test Zhang",
    "phone": "+8613912345678",
    "license_number": "TCM-123456",
    "license_expiry": "'$FUTURE_DATE'",
    "clinic_name": "Test Clinic",
    "clinic_address": "123 Test Street, Beijing, China",
    "years_of_practice": 10
  }
}' "200"

# Test 2: Invalid TCM License Format
echo "=== TEST 2: Invalid TCM License ==="
test_request "Invalid TCM License Format" '{
  "role": "tcm_practitioner",
  "data": {
    "email": "invalid.license@clinic.com",
    "password": "SecurePass123!@#",
    "full_name": "Dr. Invalid",
    "phone": "+8613912345678",
    "license_number": "TCM-ABC123",
    "license_expiry": "'$FUTURE_DATE'",
    "years_of_practice": 5
  }
}' "400"

# Test 3: Valid Pharmacy Registration
echo "=== TEST 3: Valid Pharmacy ==="
test_request "Valid Pharmacy" '{
  "role": "pharmacy",
  "data": {
    "email": "pharmacy'$(date +%s)'@health.com",
    "password": "PharmPass456!@#",
    "pharmacy_name": "Test Pharmacy",
    "business_registration": "BUS123456",
    "pharmacy_license": "PHARM-987654",
    "license_expiry": "'$FUTURE_DATE'",
    "address": "456 Pharmacy Street, Shanghai, China",
    "contact_phone": "+8621987654321",
    "contact_person": "Test Manager",
    "delivery_available": true
  }
}' "200"

# Test 4: Invalid Pharmacy License
echo "=== TEST 4: Invalid Pharmacy License ==="
test_request "Invalid Pharmacy License" '{
  "role": "pharmacy",
  "data": {
    "email": "badpharm@health.com",
    "password": "PharmPass456!@#",
    "pharmacy_name": "Bad Pharmacy",
    "business_registration": "BUS123456",
    "pharmacy_license": "INVALID",
    "license_expiry": "'$FUTURE_DATE'",
    "address": "456 Bad Street, Shanghai",
    "contact_phone": "+8621987654321",
    "contact_person": "Bad Manager"
  }
}' "400"

# Test 5: Valid Admin Registration
echo "=== TEST 5: Valid Admin ==="
test_request "Valid Admin" '{
  "role": "admin",
  "data": {
    "email": "admin'$(date +%s)'@platform.com",
    "password": "SuperAdmin2025!@#$",
    "full_name": "Admin Test User",
    "phone": "+14155551234",
    "department": "operations",
    "access_level": "full",
    "mfa_required": true
  }
}' "200"

# Test 6: Admin with Wrong Domain
echo "=== TEST 6: Admin Wrong Domain ==="
test_request "Admin Wrong Domain" '{
  "role": "admin",
  "data": {
    "email": "admin@wrongdomain.com",
    "password": "SuperAdmin2025!@#$",
    "full_name": "Wrong Admin",
    "phone": "+14155551234",
    "department": "operations",
    "access_level": "full",
    "mfa_required": true
  }
}' "400"

# Test 7: Weak Password
echo "=== TEST 7: Weak Password ==="
test_request "Weak Password" '{
  "role": "tcm_practitioner",
  "data": {
    "email": "weak@clinic.com",
    "password": "weak",
    "full_name": "Dr. Weak",
    "phone": "+8613912345678",
    "license_number": "TCM-123456",
    "license_expiry": "'$FUTURE_DATE'",
    "years_of_practice": 5
  }
}' "400"

# Test 8: Missing Required Fields
echo "=== TEST 8: Missing Required Fields ==="
test_request "Missing Fields" '{
  "role": "tcm_practitioner",
  "data": {
    "email": "missing@clinic.com"
  }
}' "400"

# Test 9: Invalid Role
echo "=== TEST 9: Invalid Role ==="
test_request "Invalid Role" '{
  "role": "invalid_role",
  "data": {
    "email": "test@example.com"
  }
}' "400"

# Test 10: No Data Provided
echo "=== TEST 10: No Data ==="
test_request "No Data" '{}' "400"

# Performance Test: Run 10 concurrent requests
echo "=========================================="
echo "Performance Test: 10 Concurrent Requests"
echo "=========================================="

for i in {1..10}; do
    {
        start=$(date +%s%N)
        curl -s -X POST "$FUNCTION_URL" \
            -H "Authorization: Bearer $ANON_KEY" \
            -H "Content-Type: application/json" \
            -d '{
                "role": "tcm_practitioner",
                "data": {
                    "email": "perf'$i'@test.com",
                    "password": "PerfTest123!@#",
                    "full_name": "Perf Test",
                    "phone": "+8613912345678",
                    "license_number": "TCM-123456",
                    "license_expiry": "'$FUTURE_DATE'",
                    "years_of_practice": 5
                }
            }' > /dev/null
        end=$(date +%s%N)
        elapsed=$((($end - $start) / 1000000))
        echo "Request $i: ${elapsed}ms"
    } &
done

wait

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="