/// <reference no-default-lib="true" />
/// <reference lib="deno.ns" />
/// <reference lib="deno.unstable" />

// License Verification Workflow Edge Function
// Handles TCM practitioner and pharmacy license verification with state management

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts';

// CORS headers for browser requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};

// ============================================
// TYPE DEFINITIONS
// ============================================

type LicenseType = 'tcm_practitioner' | 'pharmacy';
type VerificationStatus = 'pending' | 'verifying' | 'verified' | 'rejected';

interface LicenseVerificationRequest {
  type: LicenseType;
  license_number: string;
  license_expiry: string;
  user_id?: string;
  additional_info?: {
    practitioner_name?: string;
    clinic_name?: string;
    pharmacy_name?: string;
    business_registration?: string;
  };
}

interface VerificationState {
  verification_id: string;
  type: LicenseType;
  license_number: string;
  status: VerificationStatus;
  submitted_at: string;
  verified_at?: string;
  rejection_reason?: string;
  verification_details?: {
    expiry_date: string;
    issuing_authority?: string;
    verification_method?: string;
  };
}

interface VerificationError {
  success: false;
  error: {
    code: string;
    message: string;
    field?: string;
    details?: Record<string, any>;
  };
  timestamp: string;
}

interface SuccessResponse {
  success: true;
  data: VerificationState;
  timestamp: string;
}

type VerificationResponse = VerificationError | SuccessResponse;

// ============================================
// VALIDATION SCHEMAS
// ============================================

// TCM License format: TCM-XXXXXX (6 digits)
const tcmLicenseSchema = z
  .string()
  .regex(/^TCM-\d{6}$/, 'TCM license must be in format TCM-XXXXXX');

// Pharmacy License format: PHARM-XXXXXX (6 digits)
const pharmacyLicenseSchema = z
  .string()
  .regex(/^PHARM-\d{6}$/, 'Pharmacy license must be in format PHARM-XXXXXX');

// License verification request schema
const verificationRequestSchema = z
  .object({
    type: z.enum(['tcm_practitioner', 'pharmacy']),
    license_number: z.string(),
    license_expiry: z.string().datetime(),
    user_id: z.string().uuid().optional(),
    additional_info: z
      .object({
        practitioner_name: z.string().min(2).max(100).optional(),
        clinic_name: z.string().min(2).max(200).optional(),
        pharmacy_name: z.string().min(2).max(200).optional(),
        business_registration: z.string().min(5).max(50).optional(),
      })
      .optional(),
  })
  .refine(
    (data) => {
      // Validate license format based on type
      if (data.type === 'tcm_practitioner') {
        return tcmLicenseSchema.safeParse(data.license_number).success;
      } else if (data.type === 'pharmacy') {
        return pharmacyLicenseSchema.safeParse(data.license_number).success;
      }
      return false;
    },
    {
      message: 'Invalid license number format for the specified type',
      path: ['license_number'],
    }
  )
  .refine(
    (data) => {
      // Validate license expiry is at least 30 days in the future
      const expiry = new Date(data.license_expiry);
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      return expiry > thirtyDaysFromNow;
    },
    {
      message: 'License expiry must be at least 30 days in the future',
      path: ['license_expiry'],
    }
  );

// ============================================
// HELPER FUNCTIONS
// ============================================

function generateVerificationId(): string {
  return `ver_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

function createErrorResponse(
  code: string,
  message: string,
  field?: string,
  details?: Record<string, any>
): VerificationError {
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

function createSuccessResponse(state: VerificationState): SuccessResponse {
  return {
    success: true,
    data: state,
    timestamp: new Date().toISOString(),
  };
}

// ============================================
// STATE MANAGEMENT FUNCTIONS
// ============================================

async function initializeVerification(
  request: LicenseVerificationRequest,
  supabase: ReturnType<typeof createClient>
): Promise<VerificationState> {
  const verificationId = generateVerificationId();

  const initialState: VerificationState = {
    verification_id: verificationId,
    type: request.type,
    license_number: request.license_number,
    status: 'pending',
    submitted_at: new Date().toISOString(),
    verification_details: {
      expiry_date: request.license_expiry,
    },
  };

  // Store initial state in database
  const { error } = await supabase.from('license_verifications').insert({
    id: verificationId,
    user_id: request.user_id,
    license_type: request.type,
    license_number: request.license_number,
    status: 'pending',
    verification_details: initialState.verification_details,
    additional_info: request.additional_info,
    created_at: initialState.submitted_at,
  });

  if (error) {
    console.error('Failed to store verification state:', error);
    throw new Error('Failed to initialize verification process');
  }

  return initialState;
}

async function transitionToVerifying(
  verificationId: string,
  supabase: ReturnType<typeof createClient>
): Promise<VerificationState | null> {
  const { data, error } = await supabase
    .from('license_verifications')
    .update({
      status: 'verifying',
      updated_at: new Date().toISOString(),
    })
    .eq('id', verificationId)
    .eq('status', 'pending')
    .select()
    .single();

  if (error || !data) {
    console.error('Failed to transition to verifying:', error);
    return null;
  }

  return {
    verification_id: data.id,
    type: data.license_type as LicenseType,
    license_number: data.license_number,
    status: 'verifying' as VerificationStatus,
    submitted_at: data.created_at,
    verification_details: data.verification_details,
  };
}

async function completeVerification(
  verificationId: string,
  status: 'verified' | 'rejected',
  supabase: ReturnType<typeof createClient>,
  rejectionReason?: string
): Promise<VerificationState | null> {
  const updateData: any = {
    status,
    updated_at: new Date().toISOString(),
    verified_at: new Date().toISOString(),
  };

  if (status === 'rejected' && rejectionReason) {
    updateData.rejection_reason = rejectionReason;
  }

  const { data, error } = await supabase
    .from('license_verifications')
    .update(updateData)
    .eq('id', verificationId)
    .eq('status', 'verifying')
    .select()
    .single();

  if (error || !data) {
    console.error('Failed to complete verification:', error);
    return null;
  }

  return {
    verification_id: data.id,
    type: data.license_type as LicenseType,
    license_number: data.license_number,
    status: data.status as VerificationStatus,
    submitted_at: data.created_at,
    verified_at: data.verified_at,
    rejection_reason: data.rejection_reason,
    verification_details: data.verification_details,
  };
}

// ============================================
// MOCK VERIFICATION LOGIC
// ============================================

async function performLicenseVerification(
  request: LicenseVerificationRequest
): Promise<{ isValid: boolean; reason?: string }> {
  // Mock verification logic - in production, this would call external APIs
  // or check against official license databases

  // Simulate processing time
  await new Promise((resolve) => setTimeout(resolve, 100));

  // Mock validation rules
  if (request.type === 'tcm_practitioner') {
    // Check if license number starts with TCM-1 (mock approved range)
    if (request.license_number.startsWith('TCM-1')) {
      return { isValid: true };
    } else if (request.license_number.startsWith('TCM-9')) {
      return { isValid: false, reason: 'License revoked or suspended' };
    }
  } else if (request.type === 'pharmacy') {
    // Check if license number starts with PHARM-2 (mock approved range)
    if (request.license_number.startsWith('PHARM-2')) {
      return { isValid: true };
    } else if (request.license_number.startsWith('PHARM-8')) {
      return { isValid: false, reason: 'License expired or invalid' };
    }
  }

  // Default to valid for demo purposes
  return { isValid: true };
}

// ============================================
// MAIN HANDLER
// ============================================

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Handle GET requests for status checks
  if (req.method === 'GET') {
    const url = new URL(req.url);
    const verificationId = url.searchParams.get('verification_id');

    if (!verificationId) {
      return new Response(
        JSON.stringify(createErrorResponse('INVALID_REQUEST', 'Verification ID is required')),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
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

    // Fetch verification status
    const { data, error } = await supabase
      .from('license_verifications')
      .select('*')
      .eq('id', verificationId)
      .single();

    if (error || !data) {
      return new Response(
        JSON.stringify(createErrorResponse('NOT_FOUND', 'Verification not found')),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const state: VerificationState = {
      verification_id: data.id,
      type: data.license_type as LicenseType,
      license_number: data.license_number,
      status: data.status as VerificationStatus,
      submitted_at: data.created_at,
      verified_at: data.verified_at,
      rejection_reason: data.rejection_reason,
      verification_details: data.verification_details,
    };

    return new Response(JSON.stringify(createSuccessResponse(state)), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Only accept POST requests for new verifications
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify(
        createErrorResponse('METHOD_NOT_ALLOWED', 'Only POST and GET methods are allowed')
      ),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  try {
    // Parse request body
    const body = await req.json();

    // Validate request
    const validationResult = verificationRequestSchema.safeParse(body);

    if (!validationResult.success) {
      const firstError = validationResult.error.errors[0];
      return new Response(
        JSON.stringify(
          createErrorResponse('VALIDATION_ERROR', firstError.message, firstError.path.join('.'), {
            requirement: firstError.message,
          })
        ),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const request = validationResult.data;

    // Initialize Supabase client
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

    // Initialize verification with pending status
    const initialState = await initializeVerification(request, supabase);

    // Transition to verifying status
    const verifyingState = await transitionToVerifying(initialState.verification_id, supabase);

    if (!verifyingState) {
      return new Response(
        JSON.stringify(createErrorResponse('STATE_ERROR', 'Failed to start verification process')),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Perform actual verification (mock for now)
    const verificationResult = await performLicenseVerification(request);

    // Complete verification with final status
    const finalState = await completeVerification(
      initialState.verification_id,
      verificationResult.isValid ? 'verified' : 'rejected',
      supabase,
      verificationResult.reason
    );

    if (!finalState) {
      return new Response(
        JSON.stringify(
          createErrorResponse('STATE_ERROR', 'Failed to complete verification process')
        ),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Log verification attempt (anonymized for HIPAA compliance)
    console.log('License verification completed:', {
      type: request.type,
      status: finalState.status,
      verification_id: finalState.verification_id,
      timestamp: new Date().toISOString(),
    });

    return new Response(JSON.stringify(createSuccessResponse(finalState)), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Unexpected error in license verification:', error);

    return new Response(
      JSON.stringify(
        createErrorResponse('INTERNAL_ERROR', 'An unexpected error occurred during verification')
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
 * This function handles license verification for:
 * 1. TCM Practitioners - Medical license format TCM-XXXXXX
 * 2. Pharmacies - Business license format PHARM-XXXXXX
 *
 * State transitions: pending → verifying → verified/rejected
 *
 * Performance target: < 500ms P95 response time
 * Security: HIPAA compliant, no PII in logs, service role key protected
 *
 * Deploy with: supabase functions deploy license-verification
 *
 * Frontend integration:
 * - POST /functions/v1/license-verification - Submit new verification
 * - GET /functions/v1/license-verification?verification_id=xxx - Check status
 */
