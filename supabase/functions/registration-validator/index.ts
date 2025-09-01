/// <reference no-default-lib="true" />
/// <reference lib="deno.ns" />
/// <reference lib="deno.unstable" />

// Registration Validator Edge Function
// Validates role-specific registration requirements before account creation

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts';

// CORS headers for browser requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// ============================================
// TYPE DEFINITIONS
// ============================================

type UserRole = 'tcm_practitioner' | 'pharmacy' | 'admin';

interface ValidationRequest {
  role: UserRole;
  data: Record<string, unknown>;
}

interface ValidationError {
  success: false;
  error: {
    code: string;
    message: string;
    field?: string;
    details?: {
      requirement: string;
      received: string;
    };
  };
  timestamp: string;
}

interface SuccessResponse {
  success: true;
  data: {
    validated: true;
    role: string;
    message: string;
  };
  timestamp: string;
}

type ValidationResponse = ValidationError | SuccessResponse;

// ============================================
// VALIDATION SCHEMAS
// ============================================

// Common validation patterns
const emailSchema = z.string().email('Invalid email format');
const phoneSchema = z.string().regex(/^\+?[1-9]\d{1,14}$/, 'Invalid phone number format');
const passwordSchema = z
  .string()
  .min(12, 'Password must be at least 12 characters')
  .regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
    'Password must contain uppercase, lowercase, number and special character'
  );

// Admin password has stricter requirements
const adminPasswordSchema = z
  .string()
  .min(16, 'Admin password must be at least 16 characters')
  .regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
    'Password must contain uppercase, lowercase, number and special character'
  );

// TCM Practitioner validation schema
const tcmPractitionerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  full_name: z.string().min(2).max(100),
  phone: phoneSchema,
  license_number: z.string().regex(/^TCM-\d{6}$/, 'License must be in format TCM-XXXXXX'),
  license_expiry: z
    .string()
    .datetime()
    .refine((date: string) => {
      const expiry = new Date(date);
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      return expiry > thirtyDaysFromNow;
    }, 'License expiry must be at least 30 days in the future'),
  clinic_name: z.string().min(2).max(200).optional(),
  clinic_address: z.string().min(10).max(500).optional(),
  specializations: z.array(z.string()).max(10).optional(),
  years_of_practice: z.number().min(0).max(70),
});

// Pharmacy operator validation schema
const pharmacySchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  pharmacy_name: z.string().min(2).max(200),
  business_registration: z.string().min(5).max(50),
  pharmacy_license: z.string().regex(/^PHARM-\d{6}$/, 'License must be in format PHARM-XXXXXX'),
  license_expiry: z
    .string()
    .datetime()
    .refine((date: string) => {
      const expiry = new Date(date);
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      return expiry > thirtyDaysFromNow;
    }, 'License expiry must be at least 30 days in the future'),
  address: z.string().min(10).max(500),
  contact_phone: phoneSchema,
  contact_person: z.string().min(2).max(100),
  operating_hours: z.string().optional(),
  delivery_available: z.boolean().optional(),
});

// Admin validation schema
const adminSchema = z
  .object({
    email: z
      .string()
      .email()
      .refine(
        (email: string) => email.endsWith('@platform.com'),
        'Admin email must be from @platform.com domain'
      ),
    password: adminPasswordSchema,
    full_name: z.string().min(2).max(100),
    phone: phoneSchema,
    department: z.enum(['operations', 'finance', 'support', 'compliance']),
    access_level: z.enum(['full', 'limited', 'readonly']),
    mfa_required: z.literal(true, {
      errorMap: () => ({ message: 'MFA is required for admin accounts' }),
    }),
    supervisor_email: z.string().email().optional(),
  })
  .refine(
    (data: any) => {
      // Supervisor email required for non-full access
      if (data.access_level !== 'full' && !data.supervisor_email) {
        return false;
      }
      return true;
    },
    {
      message: 'Supervisor email is required for limited or readonly access',
      path: ['supervisor_email'],
    }
  );

// ============================================
// HELPER FUNCTIONS
// ============================================

function createErrorResponse(
  code: string,
  message: string,
  field?: string,
  details?: { requirement: string; received: string }
): ValidationError {
  return {
    success: false,
    error: {
      code,
      message,
      ...(field && { field }),
      ...(details && { details }),
    },
    timestamp: new Date().toISOString(),
  };
}

function createSuccessResponse(role: string): SuccessResponse {
  return {
    success: true,
    data: {
      validated: true,
      role,
      message: 'Registration data validated successfully',
    },
    timestamp: new Date().toISOString(),
  };
}

async function checkEmailExists(
  supabase: ReturnType<typeof createClient>,
  email: string
): Promise<boolean> {
  const { data, error } = await supabase
    .from('user_profiles')
    .select('id')
    .eq('email', email)
    .maybeSingle();

  if (error) {
    console.error('Error checking email existence:', error);
    throw error;
  }

  return !!data;
}

// ============================================
// VALIDATION FUNCTIONS
// ============================================

async function validateTCMPractitioner(
  data: unknown,
  supabase: ReturnType<typeof createClient>
): Promise<ValidationResponse> {
  try {
    // Validate schema
    const validated = tcmPractitionerSchema.parse(data);

    // Check if email already exists
    const emailExists = await checkEmailExists(supabase, validated.email);
    if (emailExists) {
      return createErrorResponse('EMAIL_EXISTS', 'This email is already registered', 'email');
    }

    return createSuccessResponse('tcm_practitioner');
  } catch (error) {
    if (error instanceof z.ZodError) {
      const firstError = error.errors[0];
      return createErrorResponse(
        'VALIDATION_ERROR',
        firstError.message,
        firstError.path.join('.'),
        {
          requirement: firstError.message,
          received: String(firstError.input || 'invalid'),
        }
      );
    }
    throw error;
  }
}

async function validatePharmacy(
  data: unknown,
  supabase: ReturnType<typeof createClient>
): Promise<ValidationResponse> {
  try {
    // Validate schema
    const validated = pharmacySchema.parse(data);

    // Validate operating hours JSON if provided
    if (validated.operating_hours) {
      try {
        JSON.parse(validated.operating_hours);
      } catch {
        return createErrorResponse(
          'INVALID_FORMAT',
          'Operating hours must be valid JSON',
          'operating_hours'
        );
      }
    }

    // Check if email already exists
    const emailExists = await checkEmailExists(supabase, validated.email);
    if (emailExists) {
      return createErrorResponse('EMAIL_EXISTS', 'This email is already registered', 'email');
    }

    return createSuccessResponse('pharmacy');
  } catch (error) {
    if (error instanceof z.ZodError) {
      const firstError = error.errors[0];
      return createErrorResponse(
        'VALIDATION_ERROR',
        firstError.message,
        firstError.path.join('.'),
        {
          requirement: firstError.message,
          received: String(firstError.input || 'invalid'),
        }
      );
    }
    throw error;
  }
}

async function validateAdmin(
  data: unknown,
  supabase: ReturnType<typeof createClient>
): Promise<ValidationResponse> {
  try {
    // Validate schema
    const validated = adminSchema.parse(data);

    // Check if email already exists
    const emailExists = await checkEmailExists(supabase, validated.email);
    if (emailExists) {
      return createErrorResponse('EMAIL_EXISTS', 'This email is already registered', 'email');
    }

    // Validate supervisor email exists if provided
    if (validated.supervisor_email) {
      const supervisorExists = await checkEmailExists(supabase, validated.supervisor_email);
      if (!supervisorExists) {
        return createErrorResponse(
          'SUPERVISOR_NOT_FOUND',
          'Supervisor email not found in the system',
          'supervisor_email'
        );
      }
    }

    return createSuccessResponse('admin');
  } catch (error) {
    if (error instanceof z.ZodError) {
      const firstError = error.errors[0];
      return createErrorResponse(
        'VALIDATION_ERROR',
        firstError.message,
        firstError.path.join('.'),
        {
          requirement: firstError.message,
          received: String(firstError.input || 'invalid'),
        }
      );
    }
    throw error;
  }
}

// ============================================
// MAIN HANDLER
// ============================================

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Only accept POST requests
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify(createErrorResponse('METHOD_NOT_ALLOWED', 'Only POST method is allowed')),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  try {
    // Parse request body
    const body = (await req.json()) as ValidationRequest;

    // Validate request structure
    if (!body.role || !body.data) {
      return new Response(
        JSON.stringify(
          createErrorResponse('INVALID_REQUEST', 'Request must include role and data fields')
        ),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Initialize Supabase client with service role for database access
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('Missing Supabase environment variables');
      return new Response(
        JSON.stringify(createErrorResponse('INTERNAL_ERROR', 'Server configuration error')),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Route to appropriate validator based on role
    let response: ValidationResponse;

    switch (body.role) {
      case 'tcm_practitioner':
        response = await validateTCMPractitioner(body.data, supabase);
        break;
      case 'pharmacy':
        response = await validatePharmacy(body.data, supabase);
        break;
      case 'admin':
        response = await validateAdmin(body.data, supabase);
        break;
      default:
        response = createErrorResponse(
          'INVALID_ROLE',
          `Invalid role: ${body.role}. Must be tcm_practitioner, pharmacy, or admin`
        );
    }

    // Log validation attempt (anonymized for HIPAA compliance)
    console.log('Registration validation attempt:', {
      role: body.role,
      success: response.success,
      timestamp: response.timestamp,
      ...(response.success === false && { errorCode: response.error.code }),
    });

    // Return appropriate status code
    const statusCode = response.success
      ? 200
      : response.error.code === 'EMAIL_EXISTS'
        ? 409
        : response.error.code === 'INVALID_DOMAIN'
          ? 403
          : response.error.code === 'INTERNAL_ERROR'
            ? 500
            : 400;

    return new Response(JSON.stringify(response), {
      status: statusCode,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Unexpected error in registration validator:', error);

    return new Response(
      JSON.stringify(
        createErrorResponse('INTERNAL_ERROR', 'An unexpected error occurred during validation')
      ),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});

/* Edge Function Notes:
 *
 * This function validates registration data for three roles:
 * 1. TCM Practitioner - Medical license and practice validation
 * 2. Pharmacy - Business and pharmacy license validation
 * 3. Admin - Platform admin with enhanced security requirements
 *
 * Performance target: < 500ms P95 response time
 * Security: HIPAA compliant, no PII in logs, service role key protected
 *
 * Deploy with: supabase functions deploy registration-validator
 */
