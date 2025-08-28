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
- **Last Updated**: 2025-08-26
- **Current API Version**: v1.0.0-alpha
- **Authority Transition**: Global → Backend Lead per PRP-M1.9-API-Authority-Establishment

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

## **🛡️ License Verification API (M1.5)**

### **Professional License Verification Workflow**

```yaml
POST /rest/v1/verification/license:
  Description: Submit professional license and business verification documents
  Authentication: Bearer token (tcm_practitioner or pharmacy role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
    Content-Type: "multipart/form-data"
  Request_Body:
    license_number: string (required)
    license_type: enum ["tcm_practitioner", "pharmacy_license"] (required)
    license_document: file (required, PDF/JPG/PNG, max 10MB)
    business_registration: file (optional, PDF/JPG/PNG, max 10MB)
    additional_certifications: array (optional)
      - file: file
      - description: string
  Response_Success:
    status: 201
    data:
      verification_id: uuid
      status: "pending"
      submitted_at: timestamp
      expected_review_time: string
  Response_Error:
    status: 422
    error:
      message: "Document validation failed"
      details: array
  RLS_Enforcement: "user_id = auth.uid()"
  Zero_PII: "Professional credentials only, no patient data"

GET /rest/v1/verification/status:
  Description: Check current user's verification status
  Authentication: Bearer token (authenticated role required)
  Request_Headers:
    Authorization: "Bearer {access_token}"
  Response_Success:
    status: 200
    data:
      verification_id: uuid
      status: enum ["pending", "under_review", "verified", "rejected", "requires_additional_info"]
      submitted_at: timestamp
      reviewed_at: timestamp (if applicable)
      verification_notes: string (if rejected or requires info)
      verified_credentials:
        license_number: string
        license_type: string
        verification_date: timestamp
  Response_Error:
    status: 404
    error:
      message: "No verification record found"
  RLS_Enforcement: "user_id = auth.uid()"
  Privacy_Compliance: "Professional verification only"
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