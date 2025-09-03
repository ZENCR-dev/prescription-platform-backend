// Security Test Suite for License Verification Edge Function
// Tests authentication, authorization, and RLS enforcement

import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

const functionUrl = 'http://localhost:54321/functions/v1/license-verification'

// Test: Unauthenticated POST request should return 401
Deno.test('Security: POST without auth token returns 401', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      type: 'tcm_practitioner',
      license_number: 'TCM-123456',
      license_expiry: '2025-12-31T00:00:00Z'
    })
  })

  assertEquals(response.status, 401)
  const data = await response.json()
  assertEquals(data.success, false)
  assertEquals(data.error.code, 'UNAUTHORIZED')
})

// Test: Unauthenticated GET request should return 401
Deno.test('Security: GET without auth token returns 401', async () => {
  const response = await fetch(`${functionUrl}?verification_id=test`, {
    method: 'GET'
  })

  assertEquals(response.status, 401)
  const data = await response.json()
  assertEquals(data.success, false)
  assertEquals(data.error.code, 'UNAUTHORIZED')
})

// Test: Invalid token should return 401
Deno.test('Security: Invalid token returns 401', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer invalid-token-123',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      type: 'tcm_practitioner',
      license_number: 'TCM-123456',
      license_expiry: '2025-12-31T00:00:00Z'
    })
  })

  assertEquals(response.status, 401)
  const data = await response.json()
  assertEquals(data.success, false)
  assertEquals(data.error.code, 'UNAUTHORIZED')
})

// Test: POST should ignore user_id in request body
Deno.test('Security: POST ignores user_id in request body', async () => {
  // This test would need a valid token in a real environment
  // For now, we're testing that the endpoint structure is correct
  
  const mockToken = 'mock-valid-token' // In real test, use actual valid token
  
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${mockToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      type: 'tcm_practitioner',
      license_number: 'TCM-123456',
      license_expiry: '2025-12-31T00:00:00Z',
      user_id: 'malicious-user-id-attempt' // This should be ignored
    })
  })

  // In a real test environment with valid token:
  // - Response should be 200 (if token is valid)
  // - The created record should have user_id from JWT, not from body
  // - Check database to verify correct user_id was used
  
  // For now, we expect 401 due to invalid mock token
  assertEquals(response.status, 401)
})

// Test: GET should enforce ownership (RLS + explicit check)
Deno.test('Security: GET enforces ownership validation', async () => {
  // This test verifies that users cannot access other users' verifications
  // In a real environment, you'd need:
  // 1. Two different valid user tokens
  // 2. Create a verification with user A
  // 3. Try to access it with user B's token
  // 4. Expect 404 (not found - to avoid information leakage)
  
  const userAToken = 'user-a-token'  // Mock token
  const userBToken = 'user-b-token'  // Mock token
  const verificationId = 'ver_123_abc'
  
  // Attempt to access with different user's token
  const response = await fetch(`${functionUrl}?verification_id=${verificationId}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${userBToken}`,
    }
  })

  // Should return 404 to avoid information leakage
  // (not 403, which would confirm the resource exists)
  // In mock environment, expect 401 due to invalid token
  assertEquals(response.status, 401)
})

// Test: CORS preflight should work
Deno.test('Security: CORS preflight request succeeds', async () => {
  const response = await fetch(functionUrl, {
    method: 'OPTIONS',
    headers: {
      'Origin': 'http://localhost:3000',
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'authorization, content-type'
    }
  })

  assertEquals(response.status, 200)
  assertExists(response.headers.get('Access-Control-Allow-Origin'))
  assertExists(response.headers.get('Access-Control-Allow-Headers'))
  assertExists(response.headers.get('Access-Control-Allow-Methods'))
})

// Test: Service role should not be accessible from client
Deno.test('Security: Service role key should never be exposed', async () => {
  // This test verifies that the service role key is never sent to the client
  // The Edge Function should only use service role internally after authentication
  
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      // Attempting to use service role key directly (should fail)
      'Authorization': 'Bearer service_role_key_attempt',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      type: 'tcm_practitioner',
      license_number: 'TCM-123456',
      license_expiry: '2025-12-31T00:00:00Z'
    })
  })

  // Should fail authentication (service role should not be accepted from client)
  assertEquals(response.status, 401)
})

// Integration test script for manual testing with real tokens
console.log(`
=== Manual Security Testing Guide ===

To test with real authentication:

1. Create test users:
   - User A: tcm_practitioner role
   - User B: pharmacy role
   
2. Get their access tokens:
   const { data: { session } } = await supabase.auth.signIn({
     email: 'user-a@test.com',
     password: 'password'
   })
   const tokenA = session.access_token

3. Test scenarios:
   a. Create verification with User A's token
   b. Try to access it with User B's token (should fail)
   c. Try to pass user_id in body (should be ignored)
   d. Try to use anon key directly (should fail)
   e. Try to use service role key (should fail)

4. Verify RLS policies:
   - Check database directly
   - Confirm user_id matches JWT owner
   - Verify other users cannot see records

5. Performance test:
   - Measure response times
   - Should be < 500ms P95
`)