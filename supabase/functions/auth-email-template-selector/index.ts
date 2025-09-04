/// <reference no-default-lib="true" />
/// <reference lib="deno.ns" />
/// <reference lib="deno.unstable" />

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

interface EmailTemplateRequest {
  user: {
    id: string;
    email: string;
    user_metadata?: {
      role?: 'tcm_practitioner' | 'pharmacy' | 'admin';
    };
    app_metadata?: {
      role?: 'tcm_practitioner' | 'pharmacy' | 'admin';
    };
  };
  email_data: {
    token: string;
    token_hash: string;
    redirect_to?: string;
    email_action_type: 'signup' | 'recovery' | 'invite' | 'magic_link' | 'email_change';
    site_url: string;
  };
}

interface EmailTemplateConfig {
  subject: string;
  content: string;
}

// Role-specific email templates
const EMAIL_TEMPLATES: Record<string, Record<string, EmailTemplateConfig>> = {
  tcm_practitioner: {
    signup: {
      subject: 'Confirm Your TCM Practitioner Account',
      content: `
        <h2>🌿 Welcome, TCM Practitioner!</h2>
        <p>Your practitioner account registration is almost complete. Please confirm your email to activate your professional account.</p>
        <p><strong>Professional Verification Required:</strong> As a licensed TCM practitioner, your account will be subject to professional license verification.</p>
        <p><a href="{{ .ConfirmationURL }}" style="background-color: #2d5a27; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Confirm Practitioner Account</a></p>
        <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
        <p><small>Privacy & Security: Your account maintains HIPAA compliance standards. No patient personal information is stored.</small></p>
      `,
    },
    recovery: {
      subject: 'Reset Your TCM Practitioner Password',
      content: `
        <h2>🌿 TCM Practitioner Password Reset</h2>
        <p>We received a request to reset the password for your practitioner account: <strong>{{ .Email }}</strong></p>
        <p><strong>Security Notice:</strong> This link is valid for 1 hour and can only be used once.</p>
        <p><a href="{{ .ConfirmationURL }}" style="background-color: #2d5a27; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Reset Practitioner Password</a></p>
        <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
        <p><small>If you didn't request this reset, please ignore this email.</small></p>
      `,
    },
  },
  pharmacy: {
    signup: {
      subject: 'Confirm Your Pharmacy Partner Account',
      content: `
        <h2>💊 Welcome, Pharmacy Partner!</h2>
        <p>Thank you for joining our TCM prescription fulfillment network. Your pharmacy partner account registration is almost complete.</p>
        <p><strong>Business Verification Required:</strong> Your pharmacy license and business credentials will be verified.</p>
        <p><a href="{{ .ConfirmationURL }}" style="background-color: #1f4e79; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Confirm Pharmacy Account</a></p>
        <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
        <p><strong>Benefits:</strong> QR Code fulfillment, inventory management, bulk settlement, analytics dashboard</p>
      `,
    },
    recovery: {
      subject: 'Reset Your Pharmacy Partner Password',
      content: `
        <h2>💊 Pharmacy Partner Password Reset</h2>
        <p>Password reset request for your pharmacy partner account: <strong>{{ .Email }}</strong></p>
        <p><strong>Business Security Notice:</strong> Valid for 1 hour. Ensure account access is limited to authorized staff only.</p>
        <p><a href="{{ .ConfirmationURL }}" style="background-color: #1f4e79; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Reset Pharmacy Password</a></p>
        <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
        <p><small>All account activities are logged for compliance and audit purposes.</small></p>
      `,
    },
  },
  admin: {
    signup: {
      subject: '🚨 Administrator Account Confirmation Required',
      content: `
        <h2>⚖️ Platform Administrator Access</h2>
        <p><strong>ADMINISTRATIVE ACCESS SECURITY ALERT</strong></p>
        <p>Administrator account created for: <strong>{{ .Email }}</strong></p>
        <p><strong>Warning:</strong> This account provides full platform access including user management, compliance oversight, and system configuration.</p>
        <p><a href="{{ .ConfirmationURL }}" style="background-color: #8b2635; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Confirm Administrator Account</a></p>
        <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
        <p><strong>Requirements:</strong> MFA must be enabled, regular security reviews required.</p>
      `,
    },
    recovery: {
      subject: '🚨 CRITICAL: Administrator Password Reset',
      content: `
        <h2>⚖️ ADMINISTRATOR PASSWORD RESET</h2>
        <p><strong>CRITICAL SECURITY ALERT</strong></p>
        <p>Administrator password reset requested for: <strong>{{ .Email }}</strong></p>
        <p><strong>Enhanced Security Protocol:</strong> This link expires in 30 minutes (shorter than standard accounts).</p>
        <p><a href="{{ .ConfirmationURL }}" style="background-color: #8b2635; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Reset Administrator Password</a></p>
        <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
        <p><strong>SECURITY WARNING:</strong> If you did NOT request this, contact security-emergency@tcm-platform.com immediately.</p>
      `,
    },
  },
};

// Default template for unrecognized roles
const DEFAULT_TEMPLATE: Record<string, EmailTemplateConfig> = {
  signup: {
    subject: 'Confirm Your Account',
    content: `
      <h2>Confirm Your Account</h2>
      <p>Please confirm your email address to activate your account.</p>
      <p><a href="{{ .ConfirmationURL }}" style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Confirm Account</a></p>
      <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
    `,
  },
  recovery: {
    subject: 'Reset Your Password',
    content: `
      <h2>Reset Your Password</h2>
      <p>Click the link below to reset your password.</p>
      <p><a href="{{ .ConfirmationURL }}" style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">Reset Password</a></p>
      <p>Alternative verification code: <strong>{{ .Token }}</strong></p>
    `,
  },
};

function getUserRole(user: EmailTemplateRequest['user']): string {
  // Check user_metadata first, then app_metadata
  const role = user.user_metadata?.role || user.app_metadata?.role;

  // Validate role is one of our supported types
  if (role && ['tcm_practitioner', 'pharmacy', 'admin'].includes(role)) {
    return role;
  }

  return 'default';
}

function getEmailTemplate(userRole: string, emailActionType: string): EmailTemplateConfig {
  const roleTemplates = EMAIL_TEMPLATES[userRole];

  if (roleTemplates?.[emailActionType]) {
    return roleTemplates[emailActionType];
  }

  // Fallback to default template
  return DEFAULT_TEMPLATE[emailActionType] || DEFAULT_TEMPLATE.signup;
}

function populateTemplate(template: string, data: EmailTemplateRequest): string {
  // Replace template variables with actual values
  return template
    .replace(
      /\{\{\s*\.ConfirmationURL\s*\}\}/g,
      `${data.email_data.site_url}/auth/confirm?token_hash=${data.email_data.token_hash}&type=${data.email_data.email_action_type}&redirect_to=${data.email_data.redirect_to || data.email_data.site_url}`
    )
    .replace(/\{\{\s*\.Token\s*\}\}/g, data.email_data.token)
    .replace(/\{\{\s*\.Email\s*\}\}/g, data.user.email)
    .replace(/\{\{\s*\.SiteURL\s*\}\}/g, data.email_data.site_url)
    .replace(/\{\{\s*\.TokenHash\s*\}\}/g, data.email_data.token_hash);
}

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    const requestData = (await req.json()) as EmailTemplateRequest;

    console.log('Email template selector triggered for:', {
      email: requestData.user.email,
      actionType: requestData.email_data.email_action_type,
      role: getUserRole(requestData.user),
    });

    // Determine user role
    const userRole = getUserRole(requestData.user);

    // Get appropriate email template
    const template = getEmailTemplate(userRole, requestData.email_data.email_action_type);

    // Populate template with actual data
    const populatedContent = populateTemplate(template.content, requestData);

    // Log template selection for monitoring
    console.log(`Email template selected: ${userRole}/${requestData.email_data.email_action_type}`);

    // Return the customized email template
    return new Response(
      JSON.stringify({
        subject: template.subject,
        content: populatedContent,
        role: userRole,
        action_type: requestData.email_data.email_action_type,
      }),
      {
        headers: {
          'Content-Type': 'application/json',
        },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Email template selector error:', error);

    return new Response(
      JSON.stringify({
        error: 'Failed to process email template',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        headers: {
          'Content-Type': 'application/json',
        },
        status: 500,
      }
    );
  }
});

/* Edge Function Usage:
 * This function should be configured as an Auth Hook in Supabase
 * It intercepts email sending events and returns role-appropriate templates
 * Configuration in supabase/config.toml:
 *
 * [auth.hook.send_email]
 * enabled = true
 * uri = "https://your-project.supabase.co/functions/v1/auth-email-template-selector"
 */
