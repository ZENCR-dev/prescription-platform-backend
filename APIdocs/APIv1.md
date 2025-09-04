# APIv1.md - B2B2C TCM Prescription Fulfillment Platform API Specification

## **API Documentation Constitutional Authority**

This document serves as the **Single Source of Truth (SSoT)** for all API specifications within the B2B2C Traditional Chinese Medicine Prescription Fulfillment Platform, as mandated by SOP.md Section 103-125.

### **Backend Lead Authority Declaration**  
- **Development Authority**: Backend Lead exclusive modification rights per SOP.md Section 137-141
- **Implementation Synchronization**: API specifications updated real-time with Supabase schema development
- **Quality Control**: Direct validation against live backend functionality
- **Change Coordination**: Backend Lead → Global Architect review workflow established

### **Document Authority Declaration**
- **Constitutional Authority**: Backend Lead exclusive control per SOP.md Section 137-141
- **Single Source Principle**: NO API specifications permitted in other documents
- **Cross-Reference Rule**: Other documents may reference endpoints but MUST NOT redefine specifications
- **Version Control**: Semantic versioning with complete change tracking in APIv1_log.md
- **Last Updated**: 2025-08-30
- **Current API Version**: v1.0.0-beta
- **Authority Transition**: Global → Backend Lead per PRP-M1.9-API-Authority-Establishment
- **Production Deployment**: 2025-08-30 - Successfully deployed to Supabase Cloud

## **🎯 API Architecture Overview**

### **Supabase-First Architecture Implementation**

```yaml
API_Foundation:
  Database_First_Design:
    - All API endpoints derive from Supabase PostgreSQL schema
    - Row Level Security (RLS) policies define access control
    - Direct client-side database integration via @supabase/ssr
    - No custom backend API layer (except Edge Functions)
    
  Authentication_Model:
    - Supabase GoTrue Auth for user authentication
    - JWT-based session management via supabase-ssr (recommended)
    - Bearer token authentication for backward compatibility
    - Role-based access control through database RLS policies
    - Multi-factor authentication for sensitive operations
    - Claims validation via supabase.auth.getClaims() (primary method)
    
  Edge_Function_Scope:
    - Complex business logic beyond database capabilities
    - Financial calculations requiring precision
    - Third-party service integrations
    - Prescription validation workflows
```

## **🌐 Production Environment Details**

### **Remote Supabase Instance**
```yaml
Production_Environment:
  Project_URL: https://dosbevgbkxrtixemfjfl.supabase.co
  Project_Reference_ID: dosbevgbkxrtixemfjfl
  API_Endpoint: https://dosbevgbkxrtixemfjfl.supabase.co/rest/v1
  Auth_Endpoint: https://dosbevgbkxrtixemfjfl.supabase.co/auth/v1
  Realtime_Endpoint: wss://dosbevgbkxrtixemfjfl.supabase.co/realtime/v1
  Storage_Endpoint: https://dosbevgbkxrtixemfjfl.supabase.co/storage/v1
  
  Deployed_Components:
    Database_Migrations: 
      - 20250822041103_create_user_profiles_table.sql
      - 20250828000000_update_user_roles_enum.sql
      - 20250829124010_enhance_user_profiles_rls.sql  
      - 20250829129000_create_base_tables.sql
      - 20250829129500_add_pharmacy_id_to_user_profiles.sql
      - 20250829130000_create_pharmacy_rls.sql
    
    Edge_Functions:
      - custom-access-token: "JWT claims enrichment for role-based access"
      - auth-email-template-selector: "Dynamic email template selection"
    
    Security_Features:
      - Row Level Security: "Fully enforced on all tables"
      - HIPAA_Compliance: "Zero-PII architecture validated"
      - Performance: "All queries <1ms (target: <150ms P95)"
```

## **📋 Milestone Scope & Planning References**

**Current Documentation Scope: M1 Only**
```yaml
M1_Core_Authentication_User_Management:
  Included_in_this_document:
    - Supabase Auth integration (signup, login, logout, sessions)
    - User profile management and credential verification
    - Role-based access control with RLS policies
    - License verification and business validation workflows
    - Multi-factor authentication and session security
    - Administrative user management and approval processes
    
  Document_Authority: "Full API contracts defined for immediate M1 development"
  Backend_First_Compliance: "All M1 endpoints align with implemented/planned backend functionality"
```

**M2-M7 Planning References**
```yaml
Future_Milestones:
  M2_Prescription_QR_System: "Prescription creation, QR code generation, patient access portals"
  M3_Payment_Processing: "Patient payments, escrow management, transaction processing"
  M4_Pharmacy_Fulfillment: "Order management, fulfillment tracking, quality assurance"
  M5_Financial_Settlement: "Automated settlements, differential pricing, revenue model"
  M6_Advanced_Features: "Enhanced dashboards, integrations, mobile optimization"
  M7_Analytics_Market_Ready: "Business intelligence, performance optimization, market expansion"
  
Planning_Reference: "Complete M2-M7 API expansion strategy documented in API_Analysis_Report.md"
Activation_Process: "Milestone-specific API contracts added to this document when backend development commences"
Rolling_Wave_Compliance: "Detailed API planning only for immediate next milestone per SOP.md"
```

### **Zero-PII Architecture Compliance**

```yaml
Privacy_By_Design:
  Data_Model:
    - NO patient personally identifiable information stored
    - Prescription data contains ONLY clinical information
    - Anonymous prescription tracking via secure tokens
    - Complete separation of clinical and personal data
    
  API_Endpoints:
    - NO endpoints accept patient PII parameters
    - NO endpoints return patient personal information
    - All prescription data anonymized at API level
    - Audit trails exclude patient identifiers
```

## **🔐 Authentication & Authorization**

### **Supabase Auth Integration**

**Authentication Endpoints** (Native Supabase):
```yaml
POST /auth/v1/signup:
  Description: User registration for TCM practitioners, pharmacies, administrators
  Authentication: Public endpoint
  Request_Body:
    email: string (required)
    password: string (required, min 8 chars)
    user_metadata:
      role: enum ["tcm_practitioner", "pharmacy", "admin"] (required)
      license_number: string (required for practitioners/pharmacies)
      business_name: string (required)
  Response_Success:
    status: 200
    data:
      user:
        id: uuid
        email: string
        user_metadata: object
        email_confirmed_at: null
  Response_Error:
    status: 422
    error:
      message: string
      details: string[]
  HIPAA_Compliance: "Email only, no patient PII processed"

POST /auth/v1/token:
  Description: User authentication and session establishment
  Authentication: Public endpoint
  Request_Body:
    email: string (required)
    password: string (required)
  Response_Success:
    status: 200
    data:
      access_token: string (JWT)
      refresh_token: string
      expires_in: integer
      user:
        id: uuid
        email: string
        user_metadata: object
  Response_Error:
    status: 400
    error:
      message: "Invalid login credentials"
  HIPAA_Compliance: "Authentication only, no patient data involved"

POST /auth/v1/logout:
  Description: User session termination
  Authentication: Bearer token required
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Response_Success:
    status: 204
  Response_Error:
    status: 401
    error:
      message: "Invalid or expired token"

## Session Management (Client-Side Methods)

**Important**: Session management in Supabase is handled through client-side methods, not HTTP endpoints.

### supabase.auth.getSession()
  Description: Client-side method to retrieve current session from local storage
  Usage: Frontend applications use this method to check authentication status
  Returns:
    data:
      session:
        access_token: string (JWT)
        refresh_token: string
        expires_in: integer
        expires_at: timestamp
        token_type: "bearer"
        user:
          id: uuid
          email: string
          user_metadata: object
          role: string (from JWT claims)
          created_at: timestamp
          last_sign_in_at: timestamp
      user: User object or null
    error: null or AuthError
  
### supabase.auth.getUser()  
  Description: Client-side method to get user info from JWT token
  Usage: Validates current JWT token and returns user information
  Returns:
    data:
      user: User object with current JWT claims
    error: null or AuthError
  
  Frontend_Integration: "Use these methods for client-side session management and authentication state"

GET /auth/v1/user:
  Description: Get current authenticated user information with enhanced role claims
  Authentication: Bearer token required
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Response_Success:
    status: 200
    data:
      id: uuid
      email: string
      user_metadata:
        role: enum ["tcm_practitioner", "pharmacy", "admin"]
        license_number: string
        business_name: string
      app_metadata: object
      role: string
      created_at: timestamp
      updated_at: timestamp
      last_sign_in_at: timestamp
      email_confirmed_at: timestamp
  Response_Error:
    status: 401
    error:
      message: "User not authenticated"
  Frontend_Integration: "Use supabase.auth.getUser() for client-side user data"
```

### **JWT Claims Structure**

**Enhanced JWT Payload Structure** (Custom Access Token Hook):
```yaml
JWT_Claims_Structure:
  Standard_Claims:
    iss: "https://your-project.supabase.co/auth/v1"  # Issuer
    sub: "user-uuid"                                  # Subject (user ID)
    aud: "authenticated"                              # Audience
    exp: timestamp                                    # Expiration time
    iat: timestamp                                    # Issued at
    jti: "token-uuid"                                 # JWT ID
    
  Supabase_Claims:
    email: "user@example.com"
    phone: null
    email_verified: boolean
    phone_verified: boolean
    
  Custom_Claims_Enhanced:
    role: enum ["tcm_practitioner", "pharmacy", "admin"]
    user_role: string                                 # Same as role (backward compatibility)
    profile_status: enum ["active", "pending_verification", "suspended", "inactive"]
    business_info:
      business_name: string
      license_number: string
      verification_status: string
      contact_info: object
    aal: enum ["aal1", "aal2"]                      # Authentication Assurance Level
    amr: array                                       # Authentication Method Reference
    session_id: "session-uuid"
    
JWT_Validation_Examples:
  Frontend_Access_Pattern:
    - "const { data: { session } } = await supabase.auth.getSession()"
    - "const userRole = session?.user?.role || session?.user?.user_metadata?.role"
    - "const profileStatus = session?.user?.profile_status"
    
  RLS_Policy_Usage:
    - "auth.jwt() ->> 'role' = 'admin'"
    - "auth.jwt() ->> 'profile_status' = 'active'"
    - "auth.jwt() ->> 'aal' = 'aal2'"  # For MFA-required operations
    
Custom_Access_Token_Implementation:
  Edge_Function_Path: "/functions/v1/custom-access-token"
  Database_Query: "SELECT role, profile_status, business_name FROM user_profiles WHERE user_id = auth.uid()"
  Performance: "<100ms response time with optimized database index"
  Error_Handling: "Graceful fallback to default claims on failure"
```

### **Role-Based Access Control (RLS Policies)**

```yaml
Authentication_Methods:
  Primary_Method:
    - "supabase.auth.getClaims() for JWT validation"
    - "Automatic session management via @supabase/ssr"
    - "onAuthStateChange listeners for real-time state updates"
  
  Legacy_Support:
    - "Bearer token authentication for backward compatibility"
    - "Manual JWT parsing where getClaims() unavailable"

RLS_Policy_Examples:
  Standard_User_Isolation:
    CREATE POLICY "users_own_data" ON profiles
    FOR ALL TO authenticated
    USING (auth.uid() = user_id);
    
  Role_Based_Access:
    CREATE POLICY "admin_full_access" ON user_profiles  
    FOR ALL TO authenticated
    USING (auth.jwt()->>'role' = 'admin');
    
  MFA_Required_Operations:
    CREATE POLICY "mfa_required" ON sensitive_operations
    FOR ALL TO authenticated  
    USING ((auth.jwt()->>'aal') = 'aal2');

User_Roles:
  tcm_practitioner:
    Permissions:
      - Manage own user profile and credentials (M1)
      - Submit license verification documents (M1)
      - Access role-specific features when verified (M1)
    RLS_Policies:
      - "TO authenticated USING (auth.uid() = user_id)"
      - "Cannot access other practitioners' data"
      - "Profile access restricted by user ownership"
      
  pharmacy:
    Permissions:
      - Manage pharmacy profile and operator credentials (M1)
      - Submit pharmacy license and business registration (M1)  
      - Access pharmacy-specific platform features when verified (M1)
    RLS_Policies:
      - "TO authenticated USING (auth.uid() = user_id)"
      - "Cannot access other pharmacies' data"
      - "Business verification workflow access only"
      
  admin:
    Permissions:
      - Review and approve user verification submissions (M1)
      - Manage platform user accounts and roles (M1)
      - Access administrative dashboards and user management (M1)
    RLS_Policies:
      - "TO authenticated USING (auth.jwt()->>'role' = 'admin')"
      - "Full read access to business verification data"
      - "Cannot access user authentication credentials"
```

## **👤 User Profile Management API (M1.3)**

### **User Profile Operations**

```yaml
GET /rest/v1/profiles/me:
  Description: Retrieve current user's profile information
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Response_Success:
    status: 200
    data:
      id: uuid
      user_id: uuid
      role: enum ["tcm_practitioner", "pharmacy", "admin"]
      business_name: string
      license_number: string
      contact_info:
        email: string
        phone: string
        address: object
      verification_status: enum ["pending", "verified", "rejected"]
      profile_completion: number (percentage)
      created_at: timestamp
      updated_at: timestamp
  Response_Error:
    status: 404
    error:
      message: "Profile not found"
  RLS_Enforcement: "user_id = auth.uid()"
  Zero_PII: "Business user profiles only, no patient personal information"

PUT /rest/v1/profiles/{id}:
  Description: Update user profile information
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "application/json"
  Path_Parameters:
    id: uuid (profile ID)
  Request_Body:
    business_name: string (optional)
    contact_info: object (optional)
      phone: string
      address: object
    professional_details: object (optional)
      specialization: string
      years_experience: integer
      certifications: array
  Response_Success:
    status: 200
    data: object (updated profile)
  Response_Error:
    status: 403
    error:
      message: "Access denied"
    status: 422
    error:
      message: "Validation failed"
      details: array
  RLS_Enforcement: "user_id = auth.uid()"
  Zero_PII: "Business information only"

POST /rest/v1/profiles/avatar:
  Description: Upload user profile avatar
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "multipart/form-data"
  Request_Body:
    avatar: file (required, max 5MB, jpg/png only)
  Response_Success:
    status: 201
    data:
      avatar_url: string
      updated_at: timestamp
  Response_Error:
    status: 413
    error:
      message: "File too large"
    status: 415
    error:
      message: "Unsupported file type"
  RLS_Enforcement: "user_id = auth.uid()"
  Storage_Policy: "User-specific folder structure in Supabase Storage"
```

## **🛡️ License Verification API (M1.1)**

### **Professional License Verification Workflow (Edge Function Implementation)**

```yaml
POST /functions/v1/license-verification:
  Description: Submit professional license for verification via Edge Function workflow
  Authentication: Bearer token (tcm_practitioner or pharmacy role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "application/json"
  Request_Body:
    type: enum ["tcm_practitioner", "pharmacy"] (required)
    license_number: string (required, format: TCM-XXXXXX or PHARM-XXXXXX)
    license_expiry: string (required, ISO 8601 date, min 30 days future)
    # user_id field removed - extracted from JWT for security
    additional_info: object (optional)
      practitioner_name: string (optional)
      clinic_name: string (optional)
      pharmacy_name: string (optional)
      business_registration: string (optional)
  Response_Success:
    status: 200
    success: true
    data:
      verification_id: string (format: ver_timestamp_random)
      type: string
      license_number: string
      status: enum ["pending", "verifying", "verified", "rejected"]
      submitted_at: timestamp
      verified_at: timestamp (if verified)
      rejected_at: timestamp (if rejected)
      rejection_reason: string (if rejected)
    timestamp: timestamp
  Response_Error:
    status: 400
    success: false
    error:
      code: enum ["VALIDATION_ERROR", "EXPIRED_LICENSE", "INVALID_LICENSE_FORMAT", "STATE_ERROR", "INTERNAL_ERROR"]
      message: string
      field: string (optional, field that failed validation)
    timestamp: timestamp
  State_Machine: "pending → verifying → verified/rejected"
  Mock_Verification_Rules:
    TCM_Approved: "TCM-1XXXXX range"
    TCM_Rejected: "TCM-9XXXXX range"
    Pharmacy_Approved: "PHARM-2XXXXX range"
    Pharmacy_Rejected: "PHARM-8XXXXX range"
  Security_Rules:
    User_ID_Source: "Extracted from JWT auth.uid(), never from request body"
    Access_Control: "RLS enforced via anon key + Authorization header forwarding"
    POST_Access: "User ID from JWT prevents impersonation attacks"
    Service_Role: "Used only for internal state transitions after authentication"
  RLS_Enforcement: "Service role only for writes, users can SELECT own records"
  HIPAA_Compliance: "Zero PII in logs, professional credentials only"

GET /functions/v1/license-verification?verification_id={id}:
  Description: Check verification status by ID
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Response_Success:
    status: 200
    success: true
    data:
      verification_id: string
      type: string
      license_number: string
      status: enum ["pending", "verifying", "verified", "rejected"]
      submitted_at: timestamp
      verified_at: timestamp (if applicable)
      rejected_at: timestamp (if applicable)
      rejection_reason: string (if rejected)
    timestamp: timestamp
  Response_Error:
    status: 404
    success: false
    error:
      code: "NOT_FOUND"
      message: "Verification record not found"
    timestamp: timestamp
  Security_Rules:
    Authentication: "Bearer token required (access_token from auth)"
    Authorization: "RLS enforced + explicit ownership validation"
    GET_Access: "Only record owner can view (RLS + explicit ownership check)"
    Access_Denied: "Returns 404 for unauthorized access (no information leakage)"
  RLS_Enforcement: "Users can only view their own records via RLS policies"
  Privacy_Compliance: "Professional verification only, no patient data"

# Legacy REST Endpoints (Planned, Not Currently Implemented)
# Note: The following endpoints are planned for future REST API implementation
# but are NOT currently available. Use the Edge Function endpoints above.

POST /rest/v1/verification/license: "(Planned - Not Implemented)"
GET /rest/v1/verification/status: "(Planned - Not Implemented)"
```

## **🔐 Multi-Factor Authentication API (M1.6)**

### **MFA Enrollment and Management**

```yaml
POST /rest/v1/auth/mfa/enroll:
  Description: Enroll user in multi-factor authentication
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "application/json"
  Request_Body:
    factor_type: enum ["totp", "sms"] (required)
    phone: string (required if factor_type = "sms")
  Response_Success:
    status: 201
    data:
      factor_id: uuid
      factor_type: string
      qr_code: string (if TOTP)
      secret: string (if TOTP)
      backup_codes: array (recovery codes)
  Response_Error:
    status: 409
    error:
      message: "MFA already enrolled"
  Security: "supabase.auth.getClaims() validation required"
  Session_Management: "supabase-ssr session handling"

POST /rest/v1/auth/mfa/challenge:
  Description: Create MFA challenge for authentication
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Response_Success:
    status: 200
    data:
      challenge_id: uuid
      expires_at: timestamp
  Response_Error:
    status: 404
    error:
      message: "No MFA factors enrolled"
  Security: "Challenge expires in 5 minutes"

POST /rest/v1/auth/mfa/verify:
  Description: Verify MFA challenge with code
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "application/json"
  Request_Body:
    challenge_id: uuid (required)
    code: string (required)
  Response_Success:
    status: 200
    data:
      verified: true
      aal: "aal2"
      session_expires_at: timestamp
  Response_Error:
    status: 401
    error:
      message: "Invalid verification code"
    status: 410
    error:
      message: "Challenge expired"
  Security: "Successful verification upgrades AAL to aal2"

DELETE /rest/v1/auth/mfa/factor/{factor_id}:
  Description: Remove MFA factor (requires current verification)
  Authentication: Bearer token (authenticated role required, aal2 required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Path_Parameters:
    factor_id: uuid
  Response_Success:
    status: 204
  Response_Error:
    status: 403
    error:
      message: "AAL2 verification required"
    status: 404
    error:
      message: "Factor not found"
  Security: "Requires AAL2 (MFA verified) session"
```

## **⚡ Edge Functions Integration**

### **Session Validation with MFA (Task 3.3)**

```yaml
POST /functions/v1/validate-session:
  Description: Validate user session with MFA requirements for sensitive operations
  Authentication: Bearer token (any authenticated role)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "application/json"
  Request_Body:
    operation_type: enum ["read_only", "profile_update", "financial", "medical", "admin"] (required)
    resource_id: string (optional - specific resource being accessed)
  Response_Success:
    status: 200
    data:
      valid: true
      aal_level: enum ["aal1", "aal2"]
      user_id: uuid
  Response_MFA_Required:
    status: 428 (Precondition Required)
    data:
      valid: false
      error: "mfa_required"
      aal_level: "aal1"
      details: "MFA verification required for this operation"
  Response_MFA_Enrollment_Required:
    status: 428
    data:
      valid: false
      error: "mfa_enrollment_required"
      details: "MFA enrollment required for this operation"
  Response_Insufficient_Privileges:
    status: 403
    data:
      valid: false
      error: "insufficient_privileges"
      details: "User role insufficient for this operation"
  Response_Invalid_Token:
    status: 401
    data:
      valid: false
      error: "invalid_token"
      details: "Missing or invalid Authorization header"
  Security_Rules:
    read_only: "AAL1 sufficient"
    profile_update: "AAL2 required if MFA enrolled"
    financial: "AAL2 always required"
    medical: "AAL2 always required (HIPAA compliance)"
    admin: "AAL2 mandatory + admin role required"
  Audit_Trail: "All validation attempts logged to auth_audit_logs table"
  Performance: "Target P95 < 50ms response time"
```

### **Authentication Hooks & Custom Logic**

```yaml
Edge_Functions_Auth_Integration:
  Custom_Access_Token_Hook:
    Purpose: "Enhance JWT tokens with custom claims from user_profiles table"
    Endpoint: "/functions/v1/custom-access-token"
    Trigger: "Before token issuance (signup, signin, refresh)"
    Implementation:
      Database_Query: |
        SELECT 
          role,
          profile_status,
          business_name,
          license_number,
          verification_status
        FROM user_profiles 
        WHERE user_id = $1
      Custom_Claims_Added:
        - role
        - user_role (backward compatibility)
        - profile_status
        - business_info
      Performance_Optimization: "Single query with idx_user_profiles_role_status index"
      Error_Handling: "Graceful fallback to default Supabase claims"
    
  Auth_Email_Template_Selector:
    Purpose: "Select role-appropriate email templates for auth flows"
    Endpoint: "/functions/v1/auth-email-template-selector"
    Trigger: "Before email send (confirmation, recovery, invite)"
    Implementation:
      Template_Logic: |
        if (user.role === 'tcm_practitioner') return 'practitioner-template'
        if (user.role === 'pharmacy') return 'pharmacy-template'
        if (user.role === 'admin') return 'admin-template'
        return 'default-template'
      Templates_Available:
        - role-based-confirmation.html
        - practitioner-recovery.html
        - pharmacy-invitation.html
        - admin-security-alert.html

  License_Verification_Workflow:
    Purpose: "State-managed license verification for TCM practitioners and pharmacies"
    Endpoint: "/functions/v1/license-verification"
    Methods: ["POST", "GET"]
    State_Transitions: "pending → verifying → verified/rejected"
    
    POST_Request:
      Description: "Submit new license verification request"
      Request_Body:
        type: "tcm_practitioner | pharmacy"
        license_number: "TCM-XXXXXX | PHARM-XXXXXX"
        license_expiry: "ISO 8601 datetime (must be >30 days future)"
        user_id?: "UUID (optional)"
        additional_info?:
          practitioner_name?: "string (TCM only)"
          clinic_name?: "string (TCM only)"
          pharmacy_name?: "string (Pharmacy only)"
          business_registration?: "string (Pharmacy only)"
      
      Response_Success:
        success: true
        data:
          verification_id: "ver_timestamp_random"
          type: "tcm_practitioner | pharmacy"
          license_number: "string"
          status: "pending | verifying | verified | rejected"
          submitted_at: "ISO 8601"
          verified_at?: "ISO 8601"
          rejection_reason?: "string"
          verification_details:
            expiry_date: "ISO 8601"
            issuing_authority?: "string"
            verification_method?: "string"
        timestamp: "ISO 8601"
      
      Response_Error:
        success: false
        error:
          code: "VALIDATION_ERROR | INTERNAL_ERROR | STATE_ERROR"
          message: "string"
          field?: "string"
          details?: "object"
        timestamp: "ISO 8601"
    
    GET_Request:
      Description: "Check verification status"
      Query_Parameters:
        verification_id: "string (required)"
      
      Response_Success: "Same as POST Response_Success"
      Response_Error:
        404: "Verification not found"
        400: "Invalid verification_id"
        500: "Internal server error"
    
    Mock_Verification_Rules:
      TCM_Approved: "License numbers starting with TCM-1"
      TCM_Rejected: "License numbers starting with TCM-9"
      Pharmacy_Approved: "License numbers starting with PHARM-2"  
      Pharmacy_Rejected: "License numbers starting with PHARM-8"
    
    Performance_Target: "< 500ms P95 response time"
    Security: "HIPAA compliant, no PII in logs"
    Frontend_Integration: "EdgeFunctionAdapter compatible"

Authentication_Business_Logic:
  User_Registration_Validation:
    Function_Name: "validate-registration"
    Purpose: "Complex role-based validation during user signup"
    Validations:
      TCM_Practitioner:
        - License number format validation
        - Professional certification requirements
        - Business address verification
      Pharmacy:
        - Pharmacy license validation
        - Operator certification requirements
        - Business registration verification
      Admin:
        - Internal authorization required
        - Multi-factor authentication setup mandatory
    Response_Format:
      Success: { "valid": true, "metadata": {...} }
      Error: { "valid": false, "errors": [...], "required_fields": [...] }
      
  Session_Security_Enhancement:
    Function_Name: "enhance-session-security"
    Purpose: "Additional security validation for sensitive operations"
    Security_Checks:
      - Device fingerprinting validation
      - Geographic location verification
      - Session activity anomaly detection
      - MFA requirement enforcement for admin operations
    Risk_Assessment:
      Low: "Standard session validation"
      Medium: "Additional verification prompt"
      High: "Force re-authentication with MFA"

Registration_Validation_Service:
  Function_Name: "registration-validator"
  Endpoint: "/functions/v1/registration-validator"
  Purpose: "Validate role-specific registration requirements before account creation"
  
  Request_Structure:
    Method: POST
    Headers:
      Authorization: "Bearer {anon_key}"
      Content-Type: "application/json"
    Body:
      role: enum ["tcm_practitioner", "pharmacy", "admin"] (required)
      data: object (role-specific fields)
  
  TCM_Practitioner_Validation:
    Required_Fields:
      email: "Valid email format"
      password: "Min 12 chars with uppercase, lowercase, number, symbol"
      full_name: "2-100 characters"
      phone: "International format +[country][number]"
      license_number: "Format: TCM-XXXXXX (6 digits)"
      license_expiry: "ISO datetime, minimum 30 days future"
      years_of_practice: "Number 0-70"
    Optional_Fields:
      clinic_name: "2-200 characters"
      clinic_address: "10-500 characters"
      specializations: "Array, max 10 items"
    
  Pharmacy_Validation:
    Required_Fields:
      email: "Valid email format"
      password: "Min 12 chars with complexity requirements"
      pharmacy_name: "2-200 characters"
      business_registration: "5-50 characters"
      pharmacy_license: "Format: PHARM-XXXXXX (6 digits)"
      license_expiry: "ISO datetime, minimum 30 days future"
      address: "10-500 characters"
      contact_phone: "International format"
      contact_person: "2-100 characters"
    Optional_Fields:
      operating_hours: "Valid JSON string"
      delivery_available: "Boolean"
  
  Admin_Validation:
    Required_Fields:
      email: "Must be @platform.com domain"
      password: "Min 16 chars with enhanced complexity"
      full_name: "2-100 characters"
      phone: "International format with country code"
      department: enum ["operations", "finance", "support", "compliance"]
      access_level: enum ["full", "limited", "readonly"]
      mfa_required: "Must be true"
    Conditional_Fields:
      supervisor_email: "Required for limited/readonly access levels"
  
  Response_Formats:
    Success_Response:
      status: 200
      body:
        success: true
        data:
          validated: true
          role: string
          message: "Registration data validated successfully"
        timestamp: ISO8601
    
    Validation_Error:
      status: 400
      body:
        success: false
        error:
          code: string
          message: string
          field: string (optional)
          details:
            requirement: string
            received: string
        timestamp: ISO8601
    
    Email_Conflict:
      status: 409
      body:
        success: false
        error:
          code: "EMAIL_EXISTS"
          message: "This email is already registered"
          field: "email"
        timestamp: ISO8601
  
  Error_Codes:
    INVALID_EMAIL: "Email format invalid"
    EMAIL_EXISTS: "Email already registered"
    WEAK_PASSWORD: "Password doesn't meet requirements"
    INVALID_LICENSE: "License format or expiry invalid"
    EXPIRED_LICENSE: "License has expired and cannot be verified"
    INVALID_LICENSE_FORMAT: "License number doesn't match required format (TCM-XXXXXX or PHARM-XXXXXX)"
    INVALID_PHONE: "Phone number format invalid"
    INVALID_DOMAIN: "Admin email domain not allowed"
    MISSING_FIELD: "Required field missing"
    INVALID_ROLE: "Role type not recognized"
    VALIDATION_ERROR: "General validation failure"
    STATE_ERROR: "Failed to transition verification state"
    INTERNAL_ERROR: "Server error"
    NOT_FOUND: "Resource not found or access denied"
    UNAUTHORIZED: "Authentication required"
    FORBIDDEN: "Insufficient permissions"
    METHOD_NOT_ALLOWED: "HTTP method not allowed"
  
  Performance_Requirements:
    Response_Time: "< 500ms P95"
    Validation_Time: "< 100ms for schema validation"
    Database_Lookup: "< 200ms for email existence check"
    Total_Processing: "< 400ms including all validations"
  
  Security_Considerations:
    Rate_Limiting: "10 requests per minute per IP"
    Input_Sanitization: "All inputs sanitized before processing"
    SQL_Injection_Prevention: "Parameterized queries only"
    Service_Role_Key: "Never exposed in response or logs"
    Audit_Logging: "All validation attempts logged (anonymized)"
    CORS: "Restricted to allowed origins only"

Edge_Functions_Configuration:
  Local_Development:
    Command: "supabase functions serve"
    URL_Pattern: "http://127.0.0.1:54321/functions/v1/{function-name}"
    Environment_Variables:
      - SUPABASE_URL
      - SUPABASE_ANON_KEY
      - SUPABASE_SERVICE_ROLE_KEY
      
  Production_Deployment:
    Command: "supabase functions deploy {function-name}"
    Environment_Management: "via Supabase Dashboard or CLI"
    Monitoring: "Built-in Supabase Edge Functions analytics"
    
  Security_Configuration:
    CORS_Headers: "Configured for frontend domain access"
    Rate_Limiting: "Applied per Supabase project settings"
    Error_Logging: "Integrated with Supabase logging system"
    Secrets_Management: "Environment variables via Supabase Vault"

Frontend_Integration_Patterns:
  Session_Management_with_SSR:
    Server_Side: |
      import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
      const supabase = createServerComponentClient({ cookies })
      const { data: { session } } = await supabase.auth.getSession()
    
  Client_Side_Auth_State: |
    const { data: { user } } = await supabase.auth.getUser()
    const userRole = user?.role || user?.user_metadata?.role
    const profileStatus = user?.profile_status
    
  Real_Time_Session_Updates: |
    supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN') {
        const customClaims = session?.user
        updateUserInterface(customClaims)
      }
    })

Error_Handling_Integration:
  Edge_Function_Failures:
    Custom_Access_Token_Failure:
      Fallback: "Default Supabase JWT claims used"
      Client_Handling: "Check for missing custom claims and request user profile API"
      Monitoring: "Log custom claim failures for investigation"
      
  Template_Selection_Failures:
    Fallback: "Default email template used"
    User_Impact: "Generic email sent instead of role-specific"
    Recovery: "Manual template assignment via admin interface"
```

## **🔧 Administrative User Management API (M1 Scope Only)**

### **User Verification Administration**

```yaml
GET /rest/v1/admin/users:
  Description: List users with verification status (M1 admin functions only)
  Authentication: Bearer token (admin role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Query_Parameters:
    role: enum ["tcm_practitioner", "pharmacy", "admin"] (optional)
    verification_status: enum ["pending", "verified", "rejected"] (optional)
    limit: integer (default 50, max 500) (optional)
  Response_Success:
    status: 200
    data: array
      - id: uuid
        email: string
        role: string
        verification_status: string
        business_name: string
        license_number: string
        created_at: timestamp
        last_login: timestamp
  Response_Error:
    status: 403
    error:
      message: "Admin access required"
  RLS_Enforcement: "auth.jwt()->>'role' = 'admin'"
  Zero_PII: "Business information only, no personal data"

PUT /rest/v1/admin/verification/{verification_id}/approve:
  Description: Approve or reject user verification submission
  Authentication: Bearer token (admin role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "application/json"
  Path_Parameters:
    verification_id: uuid
  Request_Body:
    action: enum ["approve", "reject", "request_additional_info"] (required)
    notes: string (optional, required if reject or request_additional_info)
    verified_credentials: object (required if approve)
      license_number: string
      license_type: string
      expiry_date: date
  Response_Success:
    status: 200
    data:
      verification_id: uuid
      status: string
      reviewed_at: timestamp
      reviewer_id: uuid
  Response_Error:
    status: 422
    error:
      message: "Invalid verification action"
  RLS_Enforcement: "admin role verification"
  Audit_Trail: "Complete verification decision logging"
```

## **🌐 Frontend Integration Guide**

### **@supabase/ssr Integration Patterns**

```yaml
Frontend_Integration_Complete_Guide:
  Installation_Requirements:
    Dependencies:
      - "@supabase/supabase-js": "^2.38.0"
      - "@supabase/ssr": "^0.1.0"  
      - "@supabase/auth-helpers-nextjs": "^0.8.7" (Next.js projects)
      
  Server_Side_Authentication_Setup:
    Middleware_Configuration: |
      import { createServerClient } from '@supabase/ssr'
      import { NextResponse } from 'next/server'
      
      export async function middleware(request) {
        let response = NextResponse.next()
        const supabase = createServerClient(
          process.env.NEXT_PUBLIC_SUPABASE_URL,
          process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
          {
            cookies: {
              get(name) { return request.cookies.get(name)?.value },
              set(name, value, options) {
                response.cookies.set({ name, value, ...options })
              },
              remove(name, options) {
                response.cookies.set({ name, value: '', ...options })
              },
            },
          }
        )
        
        const { data: { session } } = await supabase.auth.getSession()
        const userRole = session?.user?.role
        const profileStatus = session?.user?.profile_status
        
        return response
      }
      
  Authentication_Flow_Implementation:
    User_Registration_with_Role: |
      const handleRoleBasedSignup = async (email, password, role, metadata) => {
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              role: role, // 'tcm_practitioner', 'pharmacy', 'admin'
              license_number: metadata.license_number,
              business_name: metadata.business_name,
            },
          },
        })
        
        if (error) throw error
        
        // JWT will automatically include custom claims via custom-access-token hook
        const userRole = data.user?.role || data.user?.user_metadata?.role
        return { user: data.user, role: userRole }
      }
      
    Session_Management_with_Custom_Claims: |
      const SessionProvider = ({ children }) => {
        const [session, setSession] = useState(null)
        const [userRole, setUserRole] = useState(null)
        const [profileStatus, setProfileStatus] = useState(null)
        
        useEffect(() => {
          supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session)
            if (session?.user) {
              setUserRole(session.user.role || session.user.user_metadata?.role)
              setProfileStatus(session.user.profile_status)
            }
          })
          
          const { data: { subscription } } = supabase.auth.onAuthStateChange(
            async (event, session) => {
              setSession(session)
              if (session?.user) {
                setUserRole(session.user.role || session.user.user_metadata?.role)
                setProfileStatus(session.user.profile_status)
              } else {
                setUserRole(null)
                setProfileStatus(null)
              }
            }
          )
          
          return () => subscription?.unsubscribe()
        }, [])
        
        return (
          <AuthContext.Provider value={{ 
            session, 
            userRole, 
            profileStatus,
            isAdmin: userRole === 'admin',
            isPractitioner: userRole === 'tcm_practitioner',
            isPharmacy: userRole === 'pharmacy',
            isActive: profileStatus === 'active'
          }}>
            {children}
          </AuthContext.Provider>
        )
      }
      
  Role_Based_UI_Rendering: |
    const RoleBasedComponent = () => {
      const { userRole, profileStatus, isActive } = useAuth()
      
      if (!isActive) {
        return <VerificationPending />
      }
      
      return (
        <>
          {userRole === 'tcm_practitioner' && (
            <PractitionerDashboard />
          )}
          {userRole === 'pharmacy' && (
            <PharmacyDashboard />
          )}
          {userRole === 'admin' && (
            <AdminDashboard />
          )}
        </>
      )
    }
    
  Protected_Route_Implementation: |
    const ProtectedRoute = ({ children, requiredRole, requiresActive = true }) => {
      const { session, userRole, profileStatus } = useAuth()
      const router = useRouter()
      
      useEffect(() => {
        if (!session) {
          router.push('/auth/signin')
          return
        }
        
        if (requiredRole && userRole !== requiredRole) {
          router.push('/unauthorized')
          return
        }
        
        if (requiresActive && profileStatus !== 'active') {
          router.push('/profile/verification-pending')
          return
        }
      }, [session, userRole, profileStatus, requiredRole, requiresActive])
      
      if (!session || (requiredRole && userRole !== requiredRole)) {
        return <LoadingSpinner />
      }
      
      return children
    }

  API_Integration_Patterns:
    Authenticated_API_Calls: |
      const makeAuthenticatedRequest = async (endpoint, options = {}) => {
        const { data: { session } } = await supabase.auth.getSession()
        
        if (!session) {
          throw new Error('No active session')
        }
        
        const response = await fetch(`/api/${endpoint}`, {
          ...options,
          headers: {
            ...options.headers,
            'Authorization': `Bearer ${session.access_token}`,
            'Content-Type': 'application/json',
          },
        })
        
        if (!response.ok) {
          const error = await response.json()
          throw new Error(error.message || 'Request failed')
        }
        
        return response.json()
      }
      
    Direct_Supabase_Database_Queries: |
      const fetchUserProfile = async () => {
        const { data, error } = await supabase
          .from('user_profiles')
          .select('*')
          .single()
        
        if (error) throw error
        return data
      }
      
      const updateUserProfile = async (updates) => {
        const { data, error } = await supabase
          .from('user_profiles')
          .update(updates)
          .single()
        
        if (error) throw error
        return data
      }

  Error_Handling_Best_Practices: |
    const AuthErrorHandler = ({ error, onRetry }) => {
      const getErrorMessage = (error) => {
        switch (error.message) {
          case 'Invalid login credentials':
            return 'Please check your email and password'
          case 'Email not confirmed':
            return 'Please check your email and click the confirmation link'
          case 'User not found':
            return 'No account found with this email address'
          default:
            return error.message || 'An unexpected error occurred'
        }
      }
      
      return (
        <div className="error-container">
          <p>{getErrorMessage(error)}</p>
          {onRetry && (
            <button onClick={onRetry}>
              Try Again
            </button>
          )}
        </div>
      )
    }

  MFA_Integration_Frontend: |
    const MFASetup = () => {
      const handleEnrollMFA = async () => {
        const { data, error } = await supabase.auth.mfa.enroll({
          factorType: 'totp',
        })
        
        if (error) throw error
        
        // Display QR code for user to scan
        setQRCode(data.totp.qr_code)
        setSecret(data.totp.secret)
      }
      
      const handleVerifyMFA = async (token) => {
        const { data, error } = await supabase.auth.mfa.verify({
          factorId: mfaFactor.id,
          challengeId: challenge.id,
          code: token,
        })
        
        if (error) throw error
        
        // User now has AAL2 session
        setIsAAL2(true)
      }
    }

Development_Environment_Setup:
  Environment_Variables: |
    NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
    NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
    SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
    
  Local_Development_Commands:
    Backend_Start: "supabase start"
    Frontend_Start: "npm run dev"
    Database_Studio: "open http://127.0.0.1:54323"
    
  Testing_Integration:
    Test_Users: |
      // Create test users for each role during development
      const createTestUsers = async () => {
        await supabase.auth.signUp({
          email: 'practitioner@test.com',
          password: 'testpass123',
          options: { data: { role: 'tcm_practitioner' } }
        })
        
        await supabase.auth.signUp({
          email: 'pharmacy@test.com', 
          password: 'testpass123',
          options: { data: { role: 'pharmacy' } }
        })
      }
```

## **🔗 Future Milestone Planning References**

```yaml
M2_M7_API_Expansion:
  Status: "Planning phase - contracts will be added when milestone development begins"
  
  M2_Prescription_QR_System:
    Planned_Endpoints:
      - "POST /rest/v1/prescriptions (full CRUD operations)"
      - "POST /functions/v1/generate-qr (secure QR generation)"
      - "POST /functions/v1/verify-qr (QR validation)"
      - "GET /rest/v1/prescriptions/by-token/{token} (patient access)"
    Reference: "API_Analysis_Report.md lines 580-596"
    
  M3_Payment_Processing:
    Planned_Endpoints:
      - "POST /functions/v1/create-payment-intent (Stripe integration)"
      - "POST /functions/v1/webhook/stripe (payment events)"
      - "POST /rest/v1/escrow/* (escrow management)"
    Reference: "API_Analysis_Report.md lines 598-610"
    
  M4_Pharmacy_Fulfillment:
    Planned_Endpoints:
      - "GET /rest/v1/pharmacy/orders (order management)"
      - "POST /rest/v1/pharmacy/orders/{id}/accept (order acceptance)"
      - "PUT /rest/v1/pharmacy/orders/{id}/status (fulfillment tracking)"
    Reference: "API_Analysis_Report.md lines 612-624"
    
  M5_Financial_Settlement:
    Planned_Endpoints:
      - "POST /functions/v1/calculate-settlement (automated settlement)"
      - "GET /rest/v1/pricing/differential-model (pricing management)"
      - "GET /rest/v1/revenue/analytics (revenue tracking)"
    Reference: "API_Analysis_Report.md lines 626-638"
    
  M6_M7_Advanced_Analytics:
    Planned_Endpoints:
      - "GET /rest/v1/analytics/business-intelligence"
      - "POST /rest/v1/integrations/third-party"
      - "GET /rest/v1/marketplace/api-catalog"
    Reference: "API_Analysis_Report.md lines 640-652"

Rolling_Wave_Compliance:
  Current_Focus: "M1 Core Authentication & User Management only"
  Next_Activation: "M2 contracts added when backend development begins"
  Planning_Authority: "Complete expansion strategy in API_Analysis_Report.md#分阶段API文档策略"
```

## **🔒 Error Handling & Security**

### **Standardized API Response Structure**

```yaml
ApiResponse_Format:
  Success_Response:
    success: true
    data: T (actual response data)
    pagination?: object (for paginated responses)
      page: number
      limit: number  
      total: number
      has_more: boolean
    request_id: string (UUID for tracking and support)
    timestamp: string (ISO 8601 timestamp)

  Error_Response:
    success: false
    error:
      message: string (user-friendly error message)
      code: string (internal error code for logging)
      details?: array (detailed validation errors if applicable)
      timestamp: string (ISO 8601 timestamp)
      request_id: string (UUID for tracking and support)

Response_Examples:
  Success_Example:
    success: true
    data:
      id: "123e4567-e89b-12d3-a456-426614174000"
      business_name: "TCM Wellness Clinic"
      verification_status: "verified"
    request_id: "req_789e4567-e89b-12d3-a456-426614174999"
    timestamp: "2025-08-23T10:30:00Z"

  Error_Example:
    success: false
    error:
      message: "Validation failed"
      code: "VALIDATION_ERROR"
      details: ["license_number is required", "invalid email format"]
      timestamp: "2025-08-23T10:30:00Z"
      request_id: "req_789e4567-e89b-12d3-a456-426614174999"

Common_Error_Codes:
  400: "Bad Request - Invalid request format or parameters"
  401: "Unauthorized - Authentication required or invalid token"
  403: "Forbidden - Insufficient permissions for requested resource"
  404: "Not Found - Requested resource does not exist"
  409: "Conflict - Request conflicts with current resource state"
  422: "Unprocessable Entity - Request validation failed"
  429: "Too Many Requests - Rate limit exceeded"
  500: "Internal Server Error - Unexpected server error occurred"
```

### **Rate Limiting & Security**

```yaml
Rate_Limiting:
  Authentication_Endpoints:
    - 5 requests per minute per IP address
    - 20 requests per hour per email address
    - Progressive backoff for failed attempts
    
  API_Endpoints:
    - 100 requests per minute per authenticated user
    - 1000 requests per hour per user
    - Burst allowance of 150 requests
    
  Public_Endpoints:
    - 10 requests per minute per IP address
    - 50 requests per hour per IP address

Security_Headers:
  Required_Headers:
    - "X-Content-Type-Options: nosniff"
    - "X-Frame-Options: DENY"
    - "X-XSS-Protection: 1; mode=block"
    - "Strict-Transport-Security: max-age=31536000; includeSubDomains"
  
  CORS_Policy:
    - Allow specific frontend domains only
    - No wildcard origins in production
    - Credentials required for authenticated requests
```

## **📊 API Versioning & Lifecycle**

### **Versioning Strategy**

```yaml
Versioning_Approach:
  Semantic_Versioning:
    - MAJOR.MINOR.PATCH format
    - Breaking changes increment MAJOR
    - New features increment MINOR
    - Bug fixes increment PATCH
    
  API_Versioning:
    - URL path versioning: /rest/v1/, /rest/v2/
    - Header versioning for minor changes: API-Version: 1.1
    - Backward compatibility maintained for 12 months
    
  Deprecation_Process:
    - 6 months advance notice for breaking changes
    - Migration guide provided for deprecated features
    - Gradual deprecation with clear timeline
```

### **Change Management Process**

```yaml
API_Change_Workflow:
  1_Proposal:
    - Change request submitted via GitHub issue
    - Business justification and impact assessment
    - Technical specification and implementation plan
    
  2_Review:
    - Global Architect review and approval
    - Cross-team impact assessment
    - Security and compliance validation
    
  3_Implementation:
    - Backend implementation and testing
    - API documentation updates
    - Client integration testing
    
  4_Release:
    - Staged rollout with monitoring
    - Team notification and training
    - Performance and stability monitoring
```

---

**Document Status**: ✅ **Backend Lead Authority Established** | 🔐 **Security Framework Complete** | 📊 **M1 API Contracts Defined** | 🚀 **Implementation Ready**

*This APIv1.md serves as the exclusive Backend Lead maintained API specification for the B2B2C Traditional Chinese Medicine Prescription Fulfillment Platform, implementing Supabase-First architecture with zero-PII compliance and comprehensive M1 business workflow support.*