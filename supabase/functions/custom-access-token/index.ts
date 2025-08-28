// Custom Access Token Hook - Add role claims to JWT
// This Edge Function is called by Supabase Auth to add custom claims to JWT tokens

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface AuthUser {
  id: string;
  aud: string;
  role?: string;
  email?: string;
  email_confirmed_at?: string;
  phone?: string;
  phone_confirmed_at?: string;
  confirmation_sent_at?: string;
  recovery_sent_at?: string;
  email_change_sent_at?: string;
  new_email?: string;
  new_phone?: string;
  invited_at?: string;
  action_link?: string;
  created_at: string;
  updated_at: string;
  is_anonymous?: boolean;
  user_metadata?: Record<string, any>;
  app_metadata?: Record<string, any>;
}

interface UserProfile {
  id: string;
  role: 'tcm_practitioner' | 'pharmacy' | 'admin';
  status: 'active' | 'inactive' | 'suspended' | 'pending_verification';
  business_info?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

interface WebhookPayload {
  user: AuthUser;
  claims: Record<string, any>;
  authentication_method: string;
}

interface CustomClaims {
  role?: string;
  user_role?: string;
  profile_status?: string;
  business_info?: Record<string, any>;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse the webhook payload from Supabase Auth
    const payload: WebhookPayload = await req.json()
    console.log('Custom Access Token Hook called for user:', payload.user.id)

    // Initialize Supabase client with service role key to access user_profiles
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Fetch user profile to get role information
    const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .select('role, status, business_info')
      .eq('id', payload.user.id)
      .single()

    if (profileError) {
      console.error('Error fetching user profile:', profileError)
      // Return original claims if profile lookup fails
      return new Response(
        JSON.stringify({ claims: payload.claims }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )
    }

    const userProfile = profile as UserProfile

    // Create custom claims to add to the JWT
    const customClaims: CustomClaims = {
      // Add role claim for RLS policies
      role: userProfile.role,
      // Add user role with more descriptive name
      user_role: userProfile.role,
      // Add profile status for additional access control
      profile_status: userProfile.status,
      // Add business info for frontend display (if not sensitive)
      business_info: userProfile.business_info || {}
    }

    // Merge custom claims with existing claims
    const enhancedClaims = {
      ...payload.claims,
      ...customClaims
    }

    console.log('Added custom claims for user:', payload.user.id, 'role:', userProfile.role)

    // Return the enhanced claims
    return new Response(
      JSON.stringify({ claims: enhancedClaims }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error in custom access token hook:', error)
    
    // Return a 500 error which will cause Auth to use default claims
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        message: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

/* Edge Function Configuration:
 * 
 * This function is called by Supabase Auth before issuing a JWT token.
 * It receives the user object and existing claims, then returns enhanced claims.
 * 
 * Expected Claims Added:
 * - role: User's role from user_profiles table (tcm_practitioner|pharmacy|admin)
 * - user_role: Same as role, for backward compatibility
 * - profile_status: User's verification status (active|pending_verification|etc)
 * - business_info: Business metadata for frontend consumption
 * 
 * Usage in RLS Policies:
 * - auth.jwt() ->> 'role' = 'admin' (for admin access)
 * - auth.jwt() ->> 'role' = 'tcm_practitioner' (for practitioner access)
 * - auth.jwt() ->> 'profile_status' = 'active' (for active users only)
 * 
 * Performance Considerations:
 * - This function is called on every token issuance (login, refresh)
 * - Database query is optimized with single() to get one record
 * - Error handling ensures Auth continues with default claims if function fails
 */