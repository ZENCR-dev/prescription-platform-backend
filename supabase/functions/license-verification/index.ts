/// <reference no-default-lib="true" />
/// <reference lib="deno.ns" />
/// <reference lib="deno.unstable" />

// License Verification Workflow Edge Function
// Handles TCM practitioner and pharmacy license verification with state management
// Security: Enforces RLS through anon key + Authorization header forwarding

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
  // user_id removed - will be extracted from JWT
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

// License verification request schema (user_id removed from validation)
const verificationRequestSchema = z
  .object({
    type: z.enum(['tcm_practitioner', 'pharmacy']),
    license_number: z.string(),
    license_expiry: z.string().datetime(),
    // user_id field removed - security fix
    additional_info: z
      .object({
        practitioner_name: z.string().min(2).max(100).optional(),
        clinic_name: z.string().min(2).max(200).optional(),
        pharmacy_name: z.string().min(2).max(200).optional(),
        business_registration: z.string().min(5).max(50).optional(),
      })
      .optional(),
  })
  .superRefine((data, ctx) => {
    // Validate license format based on type
    if (data.type === 'tcm_practitioner') {
      const result = tcmLicenseSchema.safeParse(data.license_number);
      if (!result.success) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: result.error.errors[0].message,
          path: ['license_number'],
        });
      }
    } else if (data.type === 'pharmacy') {
      const result = pharmacyLicenseSchema.safeParse(data.license_number);
      if (!result.success) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: result.error.errors[0].message,
          path: ['license_number'],
        });
      }
    }
  });

// ============================================
// UTILITY FUNCTIONS
// ============================================

function generateVerificationId(): string {
  const timestamp = Date.now().toString(36);
  const randomPart = Math.random().toString(36).substr(2, 9);
  return `ver_${timestamp}_${randomPart}`;
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
// AUTHENTICATION HELPER
// ============================================

async function getAuthenticatedUser(
  authHeader: string | null,
  supabaseUrl: string,
  supabaseAnonKey: string
) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { user: null, error: 'Missing or invalid Authorization header' };
  }

  // Create client with anon key and forward the Authorization header
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  // Get the authenticated user from the JWT
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return { user: null, error: 'Invalid or expired token' };
  }

  return { user, error: null };
}

// ============================================
// STATE MANAGEMENT FUNCTIONS
// ============================================

async function initializeVerification(
  request: LicenseVerificationRequest,
  userId: string, // Now passed separately after JWT extraction
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

  // Store initial state in database with authenticated user's ID
  const { error } = await supabase.from('license_verifications').insert({
    id: verificationId,
    user_id: userId, // Use authenticated user's ID from JWT
    license_type: request.type,
    license_number: request.license_number,
    status: 'pending',
    verification_details: initialState.verification_details,
    additional_info: request.additional_info,
    created_at: initialState.submitted_at,
  });

  if (error) {
    console.error('Failed to store verification state:', error);
    throw new Error('Failed to initialize verification');
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
    status: 'verifying',
    submitted_at: data.created_at,
    verification_details: data.verification_details,
  };
}

async function completeVerification(
  verificationId: string,
  finalStatus: 'verified' | 'rejected',
  supabase: ReturnType<typeof createClient>,
  rejectionReason?: string
): Promise<VerificationState | null> {
  const updateData: any = {
    status: finalStatus,
    updated_at: new Date().toISOString(),
  };

  if (finalStatus === 'verified') {
    updateData.verified_at = new Date().toISOString();
    updateData.verification_details = {
      ...updateData.verification_details,
      verification_method: 'automated',
      issuing_authority: 'TCM Board',
    };
  } else if (finalStatus === 'rejected' && rejectionReason) {
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
): Promise<{ isValid: boolean; reason?: string; errorCode?: string }> {
  // Simulate verification delay
  await new Promise((resolve) => setTimeout(resolve, 500));

  // Check license expiry first
  const expiryDate = new Date(request.license_expiry);
  const now = new Date();
  
  if (expiryDate < now) {
    return { 
      isValid: false, 
      reason: 'License has expired', 
      errorCode: 'EXPIRED_LICENSE' 
    };
  }

  // Mock verification logic based on license number patterns
  if (request.type === 'tcm_practitioner') {
    if (request.license_number.startsWith('TCM-1')) {
      return { isValid: true };
    } else if (request.license_number.startsWith('TCM-9')) {
      return { isValid: false, reason: 'License suspended or revoked' };
    }
  } else if (request.type === 'pharmacy') {
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

  // Get environment variables
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
    return new Response(
      JSON.stringify(createErrorResponse('INTERNAL_ERROR', 'Server configuration error')),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  // Extract Authorization header
  const authHeader = req.headers.get('Authorization');

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

    // Authenticate user
    const { user, error: authError } = await getAuthenticatedUser(
      authHeader,
      supabaseUrl,
      supabaseAnonKey
    );

    if (authError || !user) {
      return new Response(
        JSON.stringify(createErrorResponse('UNAUTHORIZED', authError || 'Authentication required')),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Create client with anon key and forwarded auth header for RLS
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader!,
        },
      },
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Fetch verification status with RLS enforcement
    const { data, error } = await supabase
      .from('license_verifications')
      .select('*')
      .eq('id', verificationId)
      .single();

    if (error || !data) {
      // Could be not found or access denied due to RLS
      return new Response(
        JSON.stringify(createErrorResponse('NOT_FOUND', 'Verification not found or access denied')),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Additional ownership check (belt and suspenders)
    // Return 404 for non-owners to avoid leaking existence information
    if (data.user_id !== user.id) {
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
    // Authenticate user for POST requests
    const { user, error: authError } = await getAuthenticatedUser(
      authHeader,
      supabaseUrl,
      supabaseAnonKey
    );

    if (authError || !user) {
      return new Response(
        JSON.stringify(createErrorResponse('UNAUTHORIZED', authError || 'Authentication required')),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Parse request body
    const body = await req.json();

    // Remove any user_id from the body (security fix)
    if ('user_id' in body) {
      delete body.user_id;
      console.warn('Attempted to pass user_id in request body - ignored for security');
    }

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

    // Create service role client for state transitions
    // Note: Service role is only used AFTER user authentication and for internal state management
    const supabaseService = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Initialize verification with authenticated user's ID
    const initialState = await initializeVerification(request, user.id, supabaseService);

    // Transition to verifying status
    const verifyingState = await transitionToVerifying(
      initialState.verification_id,
      supabaseService
    );

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

    // Handle EXPIRED_LICENSE error specifically
    if (verificationResult.errorCode === 'EXPIRED_LICENSE') {
      return new Response(
        JSON.stringify(
          createErrorResponse('EXPIRED_LICENSE', verificationResult.reason || 'License has expired')
        ),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Complete verification with final status
    const finalState = await completeVerification(
      initialState.verification_id,
      verificationResult.isValid ? 'verified' : 'rejected',
      supabaseService,
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
      // Note: Never log license_number or other PII
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

/* Edge Function Security Notes:
 *
 * Security Model:
 * - Authentication: Bearer token required (access_token from Supabase Auth)
 * - Authorization: RLS enforced through anon key + Authorization header forwarding
 * - User ID: Extracted from JWT, never accepted from request body
 * - GET Access: Only owner can view their own verifications (RLS + explicit check)
 * - POST Access: User ID from JWT used for new verifications
 * - Service Role: Only used for internal state transitions after authentication
 *
 * This function handles license verification for:
 * 1. TCM Practitioners - Medical license format TCM-XXXXXX
 * 2. Pharmacies - Business license format PHARM-XXXXXX
 *
 * State transitions: pending → verifying → verified/rejected
 *
 * Performance target: < 500ms P95 response time
 * Security: HIPAA compliant, no PII in logs, JWT-based authentication
 *
 * Deploy with: supabase functions deploy license-verification
 *
 * Frontend integration:
 * - POST /functions/v1/license-verification - Submit new verification (Bearer token required)
 * - GET /functions/v1/license-verification?verification_id=xxx - Check status (Bearer token required)
 */
