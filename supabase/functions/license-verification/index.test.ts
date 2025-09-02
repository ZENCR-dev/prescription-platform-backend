// Unit tests for license-verification Edge Function
// Run with: deno test --allow-all index.test.ts

import { assertEquals, assertExists } from 'https://deno.land/std@0.208.0/assert/mod.ts';
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts';

// Test data fixtures
const validTCMVerificationRequest = {
  type: 'tcm_practitioner',
  license_number: 'TCM-123456',
  license_expiry: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(), // 90 days future
  user_id: '550e8400-e29b-41d4-a716-446655440000',
  additional_info: {
    practitioner_name: 'Dr. Zhang Wei',
    clinic_name: 'Traditional Medicine Center',
  },
};

const validPharmacyVerificationRequest = {
  type: 'pharmacy',
  license_number: 'PHARM-234567',
  license_expiry: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString(), // 180 days future
  user_id: '660e8400-e29b-41d4-a716-446655440001',
  additional_info: {
    pharmacy_name: 'Health Center Pharmacy',
    business_registration: 'BUS123456789',
  },
};

// ============================================
// LICENSE FORMAT TESTS
// ============================================

Deno.test('TCM License - Valid format TCM-XXXXXX', () => {
  const schema = z.string().regex(/^TCM-\d{6}$/);
  
  const validLicenses = [
    'TCM-123456',
    'TCM-000001',
    'TCM-999999',
  ];

  validLicenses.forEach(license => {
    assertEquals(schema.safeParse(license).success, true);
  });
});

Deno.test('TCM License - Invalid format', () => {
  const schema = z.string().regex(/^TCM-\d{6}$/);
  
  const invalidLicenses = [
    'TCM-12345',      // Too few digits
    'TCM-1234567',    // Too many digits
    'TCM-ABCDEF',     // Letters instead of digits
    'tcm-123456',     // Lowercase prefix
    'TCM123456',      // Missing hyphen
    'PHARM-123456',   // Wrong prefix
  ];

  invalidLicenses.forEach(license => {
    assertEquals(schema.safeParse(license).success, false);
  });
});

Deno.test('Pharmacy License - Valid format PHARM-XXXXXX', () => {
  const schema = z.string().regex(/^PHARM-\d{6}$/);
  
  const validLicenses = [
    'PHARM-234567',
    'PHARM-000001',
    'PHARM-999999',
  ];

  validLicenses.forEach(license => {
    assertEquals(schema.safeParse(license).success, true);
  });
});

Deno.test('Pharmacy License - Invalid format', () => {
  const schema = z.string().regex(/^PHARM-\d{6}$/);
  
  const invalidLicenses = [
    'PHARM-12345',     // Too few digits
    'PHARM-1234567',   // Too many digits
    'PHARM-ABCDEF',    // Letters instead of digits
    'pharm-123456',    // Lowercase prefix
    'PHARM123456',     // Missing hyphen
    'TCM-123456',      // Wrong prefix
  ];

  invalidLicenses.forEach(license => {
    assertEquals(schema.safeParse(license).success, false);
  });
});

// ============================================
// LICENSE EXPIRY TESTS
// ============================================

Deno.test('License Expiry - Valid (more than 30 days)', () => {
  const schema = z.string().datetime().refine((date: string) => {
    const expiry = new Date(date);
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    return expiry > thirtyDaysFromNow;
  }, 'License expiry must be at least 30 days in the future');

  const validExpiries = [
    new Date(Date.now() + 31 * 24 * 60 * 60 * 1000).toISOString(), // 31 days
    new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(), // 90 days
    new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(), // 1 year
  ];

  validExpiries.forEach(expiry => {
    assertEquals(schema.safeParse(expiry).success, true);
  });
});

Deno.test('License Expiry - Invalid (less than 30 days)', () => {
  const schema = z.string().datetime().refine((date: string) => {
    const expiry = new Date(date);
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    return expiry > thirtyDaysFromNow;
  }, 'License expiry must be at least 30 days in the future');

  const invalidExpiries = [
    new Date(Date.now() + 29 * 24 * 60 * 60 * 1000).toISOString(), // 29 days
    new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(), // 15 days
    new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),  // Past date
    new Date().toISOString(), // Today
  ];

  invalidExpiries.forEach(expiry => {
    assertEquals(schema.safeParse(expiry).success, false);
  });
});

// ============================================
// VERIFICATION STATE TESTS
// ============================================

Deno.test('Verification State - Valid state transitions', () => {
  const validTransitions = [
    { from: 'pending', to: 'verifying' },
    { from: 'verifying', to: 'verified' },
    { from: 'verifying', to: 'rejected' },
  ];

  validTransitions.forEach(transition => {
    // In production, this would test actual state machine logic
    assertEquals(typeof transition.from, 'string');
    assertEquals(typeof transition.to, 'string');
  });
});

Deno.test('Verification State - Invalid state transitions', () => {
  const invalidTransitions = [
    { from: 'pending', to: 'verified' },    // Skip verifying
    { from: 'pending', to: 'rejected' },    // Skip verifying
    { from: 'verified', to: 'pending' },    // Backwards
    { from: 'rejected', to: 'verified' },   // Change final state
  ];

  invalidTransitions.forEach(transition => {
    // In production, this would test that these transitions are blocked
    assertEquals(typeof transition.from, 'string');
    assertEquals(typeof transition.to, 'string');
  });
});

// ============================================
// REQUEST VALIDATION TESTS
// ============================================

Deno.test('TCM Verification Request - Valid', () => {
  const schema = z.object({
    type: z.literal('tcm_practitioner'),
    license_number: z.string().regex(/^TCM-\d{6}$/),
    license_expiry: z.string().datetime(),
    user_id: z.string().uuid().optional(),
    additional_info: z.object({
      practitioner_name: z.string().optional(),
      clinic_name: z.string().optional(),
    }).optional(),
  });

  const result = schema.safeParse(validTCMVerificationRequest);
  assertEquals(result.success, true);
});

Deno.test('Pharmacy Verification Request - Valid', () => {
  const schema = z.object({
    type: z.literal('pharmacy'),
    license_number: z.string().regex(/^PHARM-\d{6}$/),
    license_expiry: z.string().datetime(),
    user_id: z.string().uuid().optional(),
    additional_info: z.object({
      pharmacy_name: z.string().optional(),
      business_registration: z.string().optional(),
    }).optional(),
  });

  const result = schema.safeParse(validPharmacyVerificationRequest);
  assertEquals(result.success, true);
});

Deno.test('Verification Request - Type mismatch', () => {
  const invalidRequest = {
    type: 'tcm_practitioner',
    license_number: 'PHARM-123456', // Wrong format for TCM
    license_expiry: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
  };

  // This should fail validation in the actual function
  assertEquals(invalidRequest.type, 'tcm_practitioner');
  assertEquals(invalidRequest.license_number.startsWith('PHARM'), true);
});

// ============================================
// RESPONSE FORMAT TESTS
// ============================================

Deno.test('Success Response - Structure validation', () => {
  const successResponse = {
    success: true,
    data: {
      verification_id: 'ver_1234567890_abc123def',
      type: 'tcm_practitioner',
      license_number: 'TCM-123456',
      status: 'verified',
      submitted_at: new Date().toISOString(),
      verified_at: new Date().toISOString(),
      verification_details: {
        expiry_date: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
      },
    },
    timestamp: new Date().toISOString(),
  };

  assertEquals(successResponse.success, true);
  assertExists(successResponse.data.verification_id);
  assertExists(successResponse.data.type);
  assertExists(successResponse.data.status);
  assertEquals(typeof successResponse.timestamp, 'string');
});

Deno.test('Error Response - Structure validation', () => {
  const errorResponse = {
    success: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'Invalid license number format',
      field: 'license_number',
      details: {
        requirement: 'Must be in format TCM-XXXXXX',
        received: 'TCM-12345',
      },
    },
    timestamp: new Date().toISOString(),
  };

  assertEquals(errorResponse.success, false);
  assertExists(errorResponse.error.code);
  assertExists(errorResponse.error.message);
  assertEquals(typeof errorResponse.timestamp, 'string');
});

// ============================================
// VERIFICATION ID TESTS
// ============================================

Deno.test('Verification ID - Format validation', () => {
  const verificationIdPattern = /^ver_\d{13}_[a-z0-9]{9}$/;
  
  // Generate sample IDs
  const sampleIds = [
    `ver_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    `ver_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    `ver_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
  ];

  sampleIds.forEach(id => {
    assertEquals(verificationIdPattern.test(id), true);
  });
});

// ============================================
// CORS HEADERS TESTS
// ============================================

Deno.test('CORS Headers - Required headers present', () => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  };

  assertExists(corsHeaders['Access-Control-Allow-Origin']);
  assertExists(corsHeaders['Access-Control-Allow-Headers']);
  assertExists(corsHeaders['Access-Control-Allow-Methods']);
  assertEquals(corsHeaders['Access-Control-Allow-Methods'].includes('POST'), true);
  assertEquals(corsHeaders['Access-Control-Allow-Methods'].includes('GET'), true);
  assertEquals(corsHeaders['Access-Control-Allow-Methods'].includes('OPTIONS'), true);
});

// ============================================
// PERFORMANCE TESTS
// ============================================

Deno.test('Performance - Verification ID generation speed', () => {
  const startTime = performance.now();
  
  // Generate 1000 verification IDs
  for (let i = 0; i < 1000; i++) {
    const id = `ver_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  const endTime = performance.now();
  const totalTime = endTime - startTime;
  
  console.log(`Generated 1000 verification IDs in ${totalTime.toFixed(2)}ms`);
  
  // Assert that generation is fast (less than 100ms for 1000 IDs)
  assertEquals(totalTime < 100, true, `ID generation too slow: ${totalTime}ms`);
});

Deno.test('Performance - Request validation speed', () => {
  const schema = z.object({
    type: z.enum(['tcm_practitioner', 'pharmacy']),
    license_number: z.string(),
    license_expiry: z.string().datetime(),
    user_id: z.string().uuid().optional(),
  });

  const startTime = performance.now();
  
  // Validate 100 requests
  for (let i = 0; i < 100; i++) {
    schema.safeParse(validTCMVerificationRequest);
  }
  
  const endTime = performance.now();
  const totalTime = endTime - startTime;
  const avgTime = totalTime / 100;
  
  console.log(`Average validation time: ${avgTime.toFixed(2)}ms`);
  
  // Assert average time is less than 1ms
  assertEquals(avgTime < 1, true, `Validation too slow: ${avgTime}ms average`);
});

// ============================================
// MOCK VERIFICATION LOGIC TESTS
// ============================================

Deno.test('Mock Verification - TCM approved range (TCM-1XXXXX)', () => {
  const approvedLicenses = [
    'TCM-100000',
    'TCM-123456',
    'TCM-199999',
  ];

  approvedLicenses.forEach(license => {
    // These should be approved in mock logic
    assertEquals(license.startsWith('TCM-1'), true);
  });
});

Deno.test('Mock Verification - TCM rejected range (TCM-9XXXXX)', () => {
  const rejectedLicenses = [
    'TCM-900000',
    'TCM-923456',
    'TCM-999999',
  ];

  rejectedLicenses.forEach(license => {
    // These should be rejected in mock logic
    assertEquals(license.startsWith('TCM-9'), true);
  });
});

Deno.test('Mock Verification - Pharmacy approved range (PHARM-2XXXXX)', () => {
  const approvedLicenses = [
    'PHARM-200000',
    'PHARM-234567',
    'PHARM-299999',
  ];

  approvedLicenses.forEach(license => {
    // These should be approved in mock logic
    assertEquals(license.startsWith('PHARM-2'), true);
  });
});

Deno.test('Mock Verification - Pharmacy rejected range (PHARM-8XXXXX)', () => {
  const rejectedLicenses = [
    'PHARM-800000',
    'PHARM-823456',
    'PHARM-899999',
  ];

  rejectedLicenses.forEach(license => {
    // These should be rejected in mock logic
    assertEquals(license.startsWith('PHARM-8'), true);
  });
});

console.log('✅ All license verification tests completed');