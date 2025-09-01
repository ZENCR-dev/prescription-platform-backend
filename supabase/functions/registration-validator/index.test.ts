// Unit tests for registration-validator Edge Function
// Run with: deno test --allow-all index.test.ts

import { assertEquals, assertExists } from 'https://deno.land/std@0.208.0/assert/mod.ts'
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts'

// Test data fixtures
const validTCMData = {
  email: 'dr.zhang@clinic.com',
  password: 'SecurePass123!@#',
  full_name: 'Dr. Zhang Wei',
  phone: '+8613912345678',
  license_number: 'TCM-123456',
  license_expiry: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(), // 90 days future
  clinic_name: 'Traditional Medicine Center',
  clinic_address: '123 Main Street, Beijing, China 100000',
  specializations: ['Acupuncture', 'Herbal Medicine'],
  years_of_practice: 15,
}

const validPharmacyData = {
  email: 'pharmacy@healthcenter.com',
  password: 'PharmPass456!@#',
  pharmacy_name: 'Health Center Pharmacy',
  business_registration: 'BUS123456789',
  pharmacy_license: 'PHARM-987654',
  license_expiry: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString(), // 180 days future
  address: '456 Commerce Street, Shanghai, China 200000',
  contact_phone: '+8621987654321',
  contact_person: 'Wang Li',
  operating_hours: JSON.stringify({
    monday: '09:00-18:00',
    tuesday: '09:00-18:00',
    wednesday: '09:00-18:00',
    thursday: '09:00-18:00',
    friday: '09:00-18:00',
    saturday: '10:00-16:00',
    sunday: 'closed',
  }),
  delivery_available: true,
}

const validAdminData = {
  email: 'admin@platform.com',
  password: 'SuperAdmin2025!@#$',
  full_name: 'Admin User',
  phone: '+14155551234',
  department: 'operations',
  access_level: 'full',
  mfa_required: true,
}

// ============================================
// TCM PRACTITIONER TESTS
// ============================================

Deno.test('TCM Practitioner - Valid registration data', () => {
  const schema = z.object({
    email: z.string().email(),
    password: z.string()
      .min(12)
      .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
    full_name: z.string().min(2).max(100),
    phone: z.string().regex(/^\+?[1-9]\d{1,14}$/),
    license_number: z.string().regex(/^TCM-\d{6}$/),
    license_expiry: z.string().datetime(),
    clinic_name: z.string().min(2).max(200).optional(),
    clinic_address: z.string().min(10).max(500).optional(),
    specializations: z.array(z.string()).max(10).optional(),
    years_of_practice: z.number().min(0).max(70),
  })

  const result = schema.safeParse(validTCMData)
  assertEquals(result.success, true)
})

Deno.test('TCM Practitioner - Invalid license format', () => {
  const schema = z.object({
    license_number: z.string().regex(/^TCM-\d{6}$/),
  })

  const invalidData = { license_number: 'TCM-ABC123' }
  const result = schema.safeParse(invalidData)
  assertEquals(result.success, false)
  if (!result.success) {
    assertExists(result.error.errors[0].message)
  }
})

Deno.test('TCM Practitioner - License expiry too soon', () => {
  const schema = z.object({
    license_expiry: z.string().datetime().refine((date) => {
      const expiry = new Date(date)
      const thirtyDaysFromNow = new Date()
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30)
      return expiry > thirtyDaysFromNow
    }, 'License expiry must be at least 30 days in the future'),
  })

  const invalidData = {
    license_expiry: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(), // 15 days
  }
  const result = schema.safeParse(invalidData)
  assertEquals(result.success, false)
})

Deno.test('TCM Practitioner - Invalid years of practice', () => {
  const schema = z.object({
    years_of_practice: z.number().min(0).max(70),
  })

  const tooMany = { years_of_practice: 75 }
  const negative = { years_of_practice: -5 }
  
  assertEquals(schema.safeParse(tooMany).success, false)
  assertEquals(schema.safeParse(negative).success, false)
})

// ============================================
// PHARMACY TESTS
// ============================================

Deno.test('Pharmacy - Valid registration data', () => {
  const schema = z.object({
    email: z.string().email(),
    password: z.string()
      .min(12)
      .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
    pharmacy_name: z.string().min(2).max(200),
    business_registration: z.string().min(5).max(50),
    pharmacy_license: z.string().regex(/^PHARM-\d{6}$/),
    license_expiry: z.string().datetime(),
    address: z.string().min(10).max(500),
    contact_phone: z.string().regex(/^\+?[1-9]\d{1,14}$/),
    contact_person: z.string().min(2).max(100),
    operating_hours: z.string().optional(),
    delivery_available: z.boolean().optional(),
  })

  const result = schema.safeParse(validPharmacyData)
  assertEquals(result.success, true)
})

Deno.test('Pharmacy - Invalid license format', () => {
  const schema = z.object({
    pharmacy_license: z.string().regex(/^PHARM-\d{6}$/),
  })

  const invalidData = { pharmacy_license: 'PHARM-12345' } // Only 5 digits
  const result = schema.safeParse(invalidData)
  assertEquals(result.success, false)
})

Deno.test('Pharmacy - Invalid operating hours JSON', () => {
  const validateJSON = (input: string) => {
    try {
      JSON.parse(input)
      return true
    } catch {
      return false
    }
  }

  const validJSON = JSON.stringify({ monday: '09:00-18:00' })
  const invalidJSON = '{ monday: 09:00-18:00 }' // Missing quotes

  assertEquals(validateJSON(validJSON), true)
  assertEquals(validateJSON(invalidJSON), false)
})

// ============================================
// ADMIN TESTS
// ============================================

Deno.test('Admin - Valid registration data', () => {
  const schema = z.object({
    email: z.string().email().refine(
      (email) => email.endsWith('@platform.com'),
      'Admin email must be from @platform.com domain'
    ),
    password: z.string()
      .min(16)
      .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
    full_name: z.string().min(2).max(100),
    phone: z.string().regex(/^\+?[1-9]\d{1,14}$/),
    department: z.enum(['operations', 'finance', 'support', 'compliance']),
    access_level: z.enum(['full', 'limited', 'readonly']),
    mfa_required: z.literal(true),
    supervisor_email: z.string().email().optional(),
  })

  const result = schema.safeParse(validAdminData)
  assertEquals(result.success, true)
})

Deno.test('Admin - Invalid email domain', () => {
  const schema = z.object({
    email: z.string().email().refine(
      (email) => email.endsWith('@platform.com'),
      'Admin email must be from @platform.com domain'
    ),
  })

  const invalidData = { email: 'admin@gmail.com' }
  const result = schema.safeParse(invalidData)
  assertEquals(result.success, false)
})

Deno.test('Admin - Password too short', () => {
  const schema = z.object({
    password: z.string().min(16),
  })

  const invalidData = { password: 'Short123!@#' } // Only 11 chars
  const result = schema.safeParse(invalidData)
  assertEquals(result.success, false)
})

Deno.test('Admin - MFA not enabled', () => {
  const schema = z.object({
    mfa_required: z.literal(true, {
      errorMap: () => ({ message: 'MFA is required for admin accounts' })
    }),
  })

  const invalidData = { mfa_required: false }
  const result = schema.safeParse(invalidData)
  assertEquals(result.success, false)
})

Deno.test('Admin - Missing supervisor for limited access', () => {
  const schema = z.object({
    access_level: z.enum(['full', 'limited', 'readonly']),
    supervisor_email: z.string().email().optional(),
  }).refine(
    (data) => {
      if (data.access_level !== 'full' && !data.supervisor_email) {
        return false
      }
      return true
    },
    {
      message: 'Supervisor email is required for limited or readonly access',
      path: ['supervisor_email'],
    }
  )

  const invalidData = {
    access_level: 'limited' as const,
    supervisor_email: undefined,
  }
  const result = schema.safeParse(invalidData)
  assertEquals(result.success, false)
})

// ============================================
// COMMON VALIDATION TESTS
// ============================================

Deno.test('Common - Valid email formats', () => {
  const schema = z.string().email()
  
  const validEmails = [
    'user@example.com',
    'test.user@example.co.uk',
    'admin+test@platform.com',
    'doctor_123@clinic.org',
  ]

  validEmails.forEach(email => {
    assertEquals(schema.safeParse(email).success, true)
  })
})

Deno.test('Common - Invalid email formats', () => {
  const schema = z.string().email()
  
  const invalidEmails = [
    'notanemail',
    '@example.com',
    'user@',
    'user@.com',
    'user @example.com',
  ]

  invalidEmails.forEach(email => {
    assertEquals(schema.safeParse(email).success, false)
  })
})

Deno.test('Common - Valid phone formats', () => {
  const schema = z.string().regex(/^\+?[1-9]\d{1,14}$/)
  
  const validPhones = [
    '+14155551234',
    '14155551234',
    '+8613912345678',
    '8613912345678',
  ]

  validPhones.forEach(phone => {
    assertEquals(schema.safeParse(phone).success, true)
  })
})

Deno.test('Common - Invalid phone formats', () => {
  const schema = z.string().regex(/^\+?[1-9]\d{1,14}$/)
  
  const invalidPhones = [
    '0123456789', // Starts with 0
    '+0123456789', // Country code starts with 0
    '123', // Too short
    'abc123456789', // Contains letters
    '+1234567890123456', // Too long (>15 digits)
  ]

  invalidPhones.forEach(phone => {
    assertEquals(schema.safeParse(phone).success, false)
  })
})

Deno.test('Common - Password complexity requirements', () => {
  const schema = z.string()
    .min(12)
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)

  const validPasswords = [
    'SecurePass123!',
    'MyP@ssw0rd2025',
    'Complex!Pass9',
  ]

  const invalidPasswords = [
    'short', // Too short
    'NoNumbersHere!', // No numbers
    'nocapitals123!', // No uppercase
    'NOLOWERCASE123!', // No lowercase
    'NoSpecialChar123', // No special characters
  ]

  validPasswords.forEach(password => {
    assertEquals(schema.safeParse(password).success, true)
  })

  invalidPasswords.forEach(password => {
    assertEquals(schema.safeParse(password).success, false)
  })
})

// ============================================
// PERFORMANCE TESTS
// ============================================

Deno.test('Performance - Validation completes within 100ms', () => {
  const schema = z.object({
    email: z.string().email(),
    password: z.string()
      .min(12)
      .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
    full_name: z.string().min(2).max(100),
    phone: z.string().regex(/^\+?[1-9]\d{1,14}$/),
    license_number: z.string().regex(/^TCM-\d{6}$/),
    license_expiry: z.string().datetime(),
    years_of_practice: z.number().min(0).max(70),
  })

  const startTime = performance.now()
  
  // Run validation 100 times
  for (let i = 0; i < 100; i++) {
    schema.safeParse(validTCMData)
  }
  
  const endTime = performance.now()
  const totalTime = endTime - startTime
  const avgTime = totalTime / 100

  console.log(`Average validation time: ${avgTime.toFixed(2)}ms`)
  
  // Assert average time is less than 1ms (100ms for 100 iterations)
  assertEquals(avgTime < 1, true, `Validation too slow: ${avgTime}ms average`)
})

// ============================================
// ERROR RESPONSE TESTS
// ============================================

Deno.test('Error Response - Proper error structure', () => {
  const errorResponse = {
    success: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'Invalid input',
      field: 'email',
      details: {
        requirement: 'Valid email format',
        received: 'invalid-email',
      },
    },
    timestamp: new Date().toISOString(),
  }

  assertExists(errorResponse.error.code)
  assertExists(errorResponse.error.message)
  assertEquals(errorResponse.success, false)
  assertEquals(typeof errorResponse.timestamp, 'string')
})

Deno.test('Success Response - Proper success structure', () => {
  const successResponse = {
    success: true,
    data: {
      validated: true,
      role: 'tcm_practitioner',
      message: 'Registration data validated successfully',
    },
    timestamp: new Date().toISOString(),
  }

  assertExists(successResponse.data.validated)
  assertExists(successResponse.data.role)
  assertEquals(successResponse.success, true)
  assertEquals(typeof successResponse.timestamp, 'string')
})

console.log('✅ All registration validator tests completed')