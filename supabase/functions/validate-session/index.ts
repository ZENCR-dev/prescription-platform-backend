/// <reference no-default-lib="true" />
/// <reference lib="deno.ns" />
/// <reference lib="deno.unstable" />

// validate-session Edge Function
// Purpose: Validate user sessions with MFA requirements for sensitive operations
// Security: Enforces AAL2 for financial and medical operations
// Performance: Optimized for <200ms response time

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts';

// CORS headers for frontend integration
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// ============================================
// TYPE DEFINITIONS
// ============================================

// Operation security levels
enum SecurityLevel {
  READ_ONLY = 'read_only', // AAL1 sufficient
  PROFILE_UPDATE = 'profile_update', // AAL2 if MFA enrolled
  FINANCIAL = 'financial', // AAL2 required
  MEDICAL = 'medical', // AAL2 required (prescriptions, patient data)
  ADMIN = 'admin', // AAL2 mandatory
}

// Request validation schema
const validationRequestSchema = z.object({
  security_level: z.enum(['read_only', 'profile_update', 'financial', 'medical', 'admin']),
  resource_id: z.string().optional(),
});

type ValidationRequest = z.infer<typeof validationRequestSchema>;

// Response types
interface ValidationResponse {
  valid: boolean;
  aal_level?: 'aal1' | 'aal2';
  user_id?: string;
  session_id?: string;
  error?: {
    code: string;
    message: string;
  };
  timestamp: string;
}

// ============================================
// PERFORMANCE OPTIMIZATIONS
// ============================================

// Cache Supabase client creation
let supabaseClient: ReturnType<typeof createClient> | null = null;

function getSupabaseClient(): ReturnType<typeof createClient> {
  if (!supabaseClient) {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing Supabase environment variables');
    }

    supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
  }

  return supabaseClient;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

function createErrorResponse(code: string, message: string, status: number): Response {
  return new Response(
    JSON.stringify({
      valid: false,
      error: {
        code,
        message,
      },
      timestamp: new Date().toISOString(),
    }),
    {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

async function getAuthenticatedUser(authHeader: string | null) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { user: null, error: 'Missing or invalid Authorization header' };
  }

  const token = authHeader.replace('Bearer ', '');

  // Use Supabase client to verify JWT properly
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');

  if (!supabaseUrl || !supabaseAnonKey) {
    return { user: null, error: 'Server configuration error' };
  }

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

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return { user: null, error: 'Invalid or expired token' };
  }

  // Extract AAL from JWT claims
  const sessionData = await supabase.auth.getSession();
  const aal = sessionData.data?.session?.aal || 'aal1';

  return {
    user: {
      ...user,
      aal,
      session_id: sessionData.data?.session?.access_token?.split('.')[2]?.substring(0, 8),
    },
    error: null,
  };
}

// Optimized MFA check with single query
async function checkMFAStatus(userId: string): Promise<boolean> {
  const supabase = getSupabaseClient();

  const { count, error } = await supabase
    .from('mfa_factors')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('status', 'verified');

  if (error && error.code !== 'PGRST116') {
    console.error('MFA check error:', error);
    return false; // Default to no MFA on error
  }

  return (count || 0) > 0;
}

// Determine if operation is allowed based on security level
function validateSecurityLevel(
  securityLevel: SecurityLevel,
  aalLevel: string,
  hasMFA: boolean,
  userRole?: string
): { valid: boolean; reason?: string } {
  switch (securityLevel) {
    case SecurityLevel.READ_ONLY:
      return { valid: true };

    case SecurityLevel.PROFILE_UPDATE:
      if (hasMFA && aalLevel !== 'aal2') {
        return { valid: false, reason: 'mfa_required' };
      }
      return { valid: true };

    case SecurityLevel.FINANCIAL:
    case SecurityLevel.MEDICAL:
      if (!hasMFA) {
        return { valid: false, reason: 'mfa_enrollment_required' };
      }
      if (aalLevel !== 'aal2') {
        return { valid: false, reason: 'mfa_required' };
      }
      return { valid: true };

    case SecurityLevel.ADMIN:
      if (userRole !== 'admin') {
        return { valid: false, reason: 'insufficient_privileges' };
      }
      if (!hasMFA) {
        return { valid: false, reason: 'mfa_enrollment_required' };
      }
      if (aalLevel !== 'aal2') {
        return { valid: false, reason: 'mfa_required' };
      }
      return { valid: true };

    default:
      return { valid: false, reason: 'invalid_security_level' };
  }
}

// Non-blocking audit log
function logAudit(
  userId: string,
  sessionId: string | undefined,
  operationType: string,
  resourceId: string | undefined,
  aalLevel: string,
  hasMFA: boolean,
  validationResult: boolean
): void {
  const supabase = getSupabaseClient();

  // Fire and forget - don't await
  supabase
    .from('auth_audit_logs')
    .insert({
      user_id: userId,
      session_id: sessionId,
      operation_type: operationType,
      resource_id: resourceId,
      aal_level: aalLevel,
      mfa_enrolled: hasMFA,
      validation_result: validationResult,
      timestamp: new Date().toISOString(),
    })
    .then(() => {
      // Success - no action needed
    })
    .catch((err) => {
      console.error('Audit log failed:', err);
      // Continue - audit failure shouldn't block the request
    });
}

// ============================================
// MAIN HANDLER
// ============================================

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Only accept POST
  if (req.method !== 'POST') {
    return createErrorResponse('METHOD_NOT_ALLOWED', 'Only POST method is allowed', 405);
  }

  try {
    // Parse and validate request body first (fail fast)
    let body: any;
    try {
      body = await req.json();
    } catch {
      return createErrorResponse('INVALID_REQUEST', 'Invalid JSON body', 400);
    }

    const validationResult = validationRequestSchema.safeParse(body);
    if (!validationResult.success) {
      const firstError = validationResult.error.errors[0];
      return createErrorResponse(
        'VALIDATION_ERROR',
        `Invalid ${firstError.path.join('.')}: ${firstError.message}`,
        400
      );
    }

    const { security_level, resource_id } = validationResult.data;

    // Authenticate user
    const authHeader = req.headers.get('Authorization');
    const { user, error: authError } = await getAuthenticatedUser(authHeader);

    if (authError || !user) {
      return createErrorResponse('UNAUTHENTICATED', authError || 'Authentication required', 401);
    }

    // Check MFA status (optimized query)
    const hasMFA = await checkMFAStatus(user.id);

    // Validate security level
    const validation = validateSecurityLevel(
      security_level as SecurityLevel,
      user.aal,
      hasMFA,
      user.role
    );

    // Log audit (non-blocking)
    logAudit(
      user.id,
      user.session_id,
      security_level,
      resource_id,
      user.aal,
      hasMFA,
      validation.valid
    );

    // Prepare response
    const response: ValidationResponse = {
      valid: validation.valid,
      aal_level: user.aal as 'aal1' | 'aal2',
      user_id: user.id,
      session_id: user.session_id,
      timestamp: new Date().toISOString(),
    };

    // Add error details if validation failed
    if (!validation.valid && validation.reason) {
      const errorMessages: Record<string, string> = {
        mfa_required: 'MFA verification required for this operation',
        mfa_enrollment_required: 'MFA enrollment required for this operation',
        insufficient_privileges: 'Insufficient privileges for this operation',
        invalid_security_level: 'Invalid security level specified',
      };

      response.error = {
        code: validation.reason.toUpperCase(),
        message: errorMessages[validation.reason] || 'Validation failed',
      };
    }

    // Determine appropriate status code
    const statusCode = validation.valid
      ? 200
      : validation.reason === 'insufficient_privileges'
        ? 403
        : validation.reason === 'mfa_required'
          ? 428 // Precondition Required
          : validation.reason === 'mfa_enrollment_required'
            ? 428
            : 400;

    return new Response(JSON.stringify(response), {
      status: statusCode,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Session validation error:', error);
    return createErrorResponse('INTERNAL_ERROR', 'Session validation failed', 500);
  }
});

/* Edge Function Performance Notes:
 *
 * Optimizations Applied:
 * - Request body validation before authentication (fail fast)
 * - Cached Supabase client creation
 * - Optimized MFA check with count query (no data transfer)
 * - Non-blocking audit logging
 * - Proper JWT verification through Supabase Auth
 * - Structured error responses with consistent format
 *
 * Performance Targets:
 * - Average response time: < 200ms
 * - P95 response time: < 500ms
 * - Concurrent requests: 100+ RPS
 *
 * Security Model:
 * - AAL1: Basic authentication (password only)
 * - AAL2: Multi-factor authentication required
 * - Medical/Financial: Always require AAL2 (compliance)
 * - Admin: AAL2 mandatory + role check
 *
 * HIPAA Compliance:
 * - Medical operations require AAL2
 * - All attempts logged for audit trail
 * - No PII in error messages
 * - Secure session validation
 *
 * Deploy with: supabase functions deploy validate-session
 *
 * Frontend integration:
 * POST /functions/v1/validate-session
 * Body: { security_level: string, resource_id?: string }
 * Headers: Authorization: Bearer <access_token>
 */
