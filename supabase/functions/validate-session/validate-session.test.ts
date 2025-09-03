// Test Suite for validate-session Edge Function
// Tests MFA enforcement for different operation types and user scenarios

import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const supabaseUrl = Deno.env.get('SUPABASE_URL') || 'http://localhost:54321'
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || ''
const functionUrl = `${supabaseUrl}/functions/v1/validate-session`

// Test user tokens with different AAL levels (these would be real in production)
const mockTokens = {
  aal1_no_mfa: 'mock_token_aal1_no_mfa',      // User without MFA, AAL1
  aal1_with_mfa: 'mock_token_aal1_with_mfa',  // User with MFA enrolled but only AAL1 session
  aal2: 'mock_token_aal2',                    // User with AAL2 (passed MFA)
  admin_aal1: 'mock_token_admin_aal1',        // Admin with AAL1
  admin_aal2: 'mock_token_admin_aal2',        // Admin with AAL2
  invalid: 'invalid_token'                    // Invalid token
}

// Test scenarios
Deno.test('validate-session: Read-only operation with AAL1 should succeed', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal1_no_mfa}`
    },
    body: JSON.stringify({
      operation_type: 'read_only',
      resource_id: 'test-resource-1'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 200)
  assertEquals(data.valid, true)
  assertEquals(data.aal_level, 'aal1')
  assertExists(data.user_id)
})

Deno.test('validate-session: Profile update without MFA enrolled should succeed', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal1_no_mfa}`
    },
    body: JSON.stringify({
      operation_type: 'profile_update'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 200)
  assertEquals(data.valid, true)
})

Deno.test('validate-session: Profile update with MFA enrolled but AAL1 should fail', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal1_with_mfa}`
    },
    body: JSON.stringify({
      operation_type: 'profile_update'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 428) // Precondition Required
  assertEquals(data.valid, false)
  assertEquals(data.error, 'mfa_required')
  assertExists(data.details)
})

Deno.test('validate-session: Profile update with AAL2 should succeed', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal2}`
    },
    body: JSON.stringify({
      operation_type: 'profile_update'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 200)
  assertEquals(data.valid, true)
  assertEquals(data.aal_level, 'aal2')
})

Deno.test('validate-session: Financial operation without MFA enrolled should require enrollment', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal1_no_mfa}`
    },
    body: JSON.stringify({
      operation_type: 'financial',
      resource_id: 'payment-123'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 428)
  assertEquals(data.valid, false)
  assertEquals(data.error, 'mfa_enrollment_required')
})

Deno.test('validate-session: Financial operation with MFA but AAL1 should require verification', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal1_with_mfa}`
    },
    body: JSON.stringify({
      operation_type: 'financial'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 428)
  assertEquals(data.valid, false)
  assertEquals(data.error, 'mfa_required')
})

Deno.test('validate-session: Financial operation with AAL2 should succeed', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal2}`
    },
    body: JSON.stringify({
      operation_type: 'financial'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 200)
  assertEquals(data.valid, true)
  assertEquals(data.aal_level, 'aal2')
})

Deno.test('validate-session: Medical operation requires AAL2 for HIPAA compliance', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal1_with_mfa}`
    },
    body: JSON.stringify({
      operation_type: 'medical',
      resource_id: 'prescription-456'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 428)
  assertEquals(data.valid, false)
  assertEquals(data.error, 'mfa_required')
})

Deno.test('validate-session: Admin operation with non-admin user should fail', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.aal2}` // Regular user with AAL2
    },
    body: JSON.stringify({
      operation_type: 'admin'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 403) // Forbidden
  assertEquals(data.valid, false)
  assertEquals(data.error, 'insufficient_privileges')
})

Deno.test('validate-session: Admin operation with admin AAL1 should require MFA', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.admin_aal1}`
    },
    body: JSON.stringify({
      operation_type: 'admin'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 428)
  assertEquals(data.valid, false)
  assertEquals(data.error, 'mfa_required')
})

Deno.test('validate-session: Admin operation with admin AAL2 should succeed', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.admin_aal2}`
    },
    body: JSON.stringify({
      operation_type: 'admin'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 200)
  assertEquals(data.valid, true)
  assertEquals(data.aal_level, 'aal2')
})

Deno.test('validate-session: Invalid token should return 401', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${mockTokens.invalid}`
    },
    body: JSON.stringify({
      operation_type: 'read_only'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 401)
  assertEquals(data.valid, false)
  assertEquals(data.error, 'invalid_token')
})

Deno.test('validate-session: Missing Authorization header should return 401', async () => {
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      operation_type: 'read_only'
    })
  })

  const data = await response.json()
  
  assertEquals(response.status, 401)
  assertEquals(data.valid, false)
  assertEquals(data.error, 'invalid_token')
})

Deno.test('validate-session: CORS preflight should succeed', async () => {
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
})

// Performance test
Deno.test('validate-session: Performance should be under 50ms', async () => {
  const iterations = 10
  const times: number[] = []

  for (let i = 0; i < iterations; i++) {
    const start = performance.now()
    
    await fetch(functionUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${mockTokens.aal1_no_mfa}`
      },
      body: JSON.stringify({
        operation_type: 'read_only'
      })
    })
    
    const end = performance.now()
    times.push(end - start)
  }

  const avgTime = times.reduce((a, b) => a + b, 0) / times.length
  const p95Time = times.sort((a, b) => a - b)[Math.floor(times.length * 0.95)]

  console.log(`Average response time: ${avgTime.toFixed(2)}ms`)
  console.log(`P95 response time: ${p95Time.toFixed(2)}ms`)

  // Assert P95 is under 50ms
  assertEquals(p95Time < 50, true, `P95 response time ${p95Time}ms exceeds 50ms target`)
})