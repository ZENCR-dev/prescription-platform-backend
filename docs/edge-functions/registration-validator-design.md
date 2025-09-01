# Registration Validator Edge Function Design

## Task 3.1: Role-Based Registration Validation

### Architecture Overview

**Purpose**: Validate role-specific registration requirements before creating user accounts in Supabase Auth.

**Technology Stack**:
- **Runtime**: Deno 1.45+ (Supabase Edge Functions)
- **Language**: TypeScript
- **Validation Library**: Zod (TypeScript-first schema validation)
- **Authentication**: Supabase Admin API with service role key
- **Response Format**: JSON with standardized error messages

### Function Architecture

```typescript
registration-validator/
├── index.ts          # Main function handler
├── validators/       # Role-specific validators
│   ├── tcm.ts      # TCM Practitioner validation
│   ├── pharmacy.ts  # Pharmacy operator validation
│   └── admin.ts     # Admin validation
├── schemas/         # Zod validation schemas
│   └── registration.ts
└── utils/
    ├── errors.ts    # Standardized error responses
    └── types.ts     # TypeScript interfaces
```

### Validation Requirements by Role

#### 1. TCM Practitioner Registration
```typescript
interface TCMPractitionerRegistration {
  email: string;              // Valid email format
  password: string;           // Min 12 chars, uppercase, lowercase, number, symbol
  full_name: string;          // 2-100 chars
  phone: string;              // Valid phone format
  license_number: string;     // TCM-XXXXXX format
  license_expiry: string;     // ISO date, must be future date
  clinic_name?: string;       // Optional, 2-200 chars
  clinic_address?: string;    // Optional, 10-500 chars
  specializations?: string[]; // Optional, max 10 items
  years_of_practice: number;  // 0-70
}
```

**Validation Rules**:
- License number must match TCM-XXXXXX pattern
- License expiry must be at least 30 days in the future
- Email must not already exist in the system
- Years of practice must be reasonable (0-70)

#### 2. Pharmacy Operator Registration
```typescript
interface PharmacyRegistration {
  email: string;               // Valid email format
  password: string;            // Min 12 chars, complexity requirements
  pharmacy_name: string;       // 2-200 chars
  business_registration: string; // Business reg number format
  pharmacy_license: string;    // PHARM-XXXXXX format
  license_expiry: string;      // ISO date, future date
  address: string;             // 10-500 chars
  contact_phone: string;       // Valid phone
  contact_person: string;      // 2-100 chars
  operating_hours?: string;    // Optional JSON structure
  delivery_available?: boolean; // Optional
}
```

**Validation Rules**:
- Pharmacy license must match PHARM-XXXXXX pattern
- Business registration must be valid format
- License expiry must be at least 30 days in the future
- Operating hours must be valid JSON if provided

#### 3. Admin Registration
```typescript
interface AdminRegistration {
  email: string;          // Valid email, must be @platform.com domain
  password: string;       // Min 16 chars, enhanced complexity
  full_name: string;      // 2-100 chars
  phone: string;          // Valid phone with country code
  department: string;     // Enum: 'operations', 'finance', 'support', 'compliance'
  access_level: string;   // Enum: 'full', 'limited', 'readonly'
  mfa_required: boolean;  // Must be true for admin
  supervisor_email?: string; // Required for limited/readonly access
}
```

**Validation Rules**:
- Email must be from approved domain (@platform.com)
- Password must be at least 16 characters for admin
- MFA must be enabled (mfa_required = true)
- Supervisor email required for non-full access levels

### Error Response Structure

```typescript
interface ValidationError {
  success: false;
  error: {
    code: string;           // Error code for frontend handling
    message: string;        // User-friendly message
    field?: string;         // Specific field that failed
    details?: {
      requirement: string;  // What was expected
      received: string;     // What was provided
    };
  };
  timestamp: string;        // ISO timestamp
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
```

### Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `INVALID_EMAIL` | Email format invalid | 400 |
| `EMAIL_EXISTS` | Email already registered | 409 |
| `WEAK_PASSWORD` | Password doesn't meet requirements | 400 |
| `INVALID_LICENSE` | License format/expiry invalid | 400 |
| `INVALID_PHONE` | Phone number format invalid | 400 |
| `INVALID_DOMAIN` | Admin email domain not allowed | 403 |
| `MISSING_FIELD` | Required field missing | 400 |
| `INVALID_ROLE` | Role type not recognized | 400 |
| `VALIDATION_ERROR` | General validation failure | 400 |
| `INTERNAL_ERROR` | Server error | 500 |

### API Endpoint Design

**Endpoint**: `/registration-validator`
**Method**: POST
**Headers**:
```
Content-Type: application/json
Authorization: Bearer <anon-key>
```

**Request Body**:
```json
{
  "role": "tcm_practitioner|pharmacy|admin",
  "data": {
    // Role-specific fields
  }
}
```

**Response Examples**:

Success:
```json
{
  "success": true,
  "data": {
    "validated": true,
    "role": "tcm_practitioner",
    "message": "Registration data validated successfully"
  },
  "timestamp": "2025-09-01T10:00:00Z"
}
```

Error:
```json
{
  "success": false,
  "error": {
    "code": "INVALID_LICENSE",
    "message": "TCM license number format is invalid",
    "field": "license_number",
    "details": {
      "requirement": "Format: TCM-XXXXXX where X is a digit",
      "received": "TCM-ABC123"
    }
  },
  "timestamp": "2025-09-01T10:00:00Z"
}
```

### Performance Requirements

- **Response Time**: < 500ms P95
- **Validation Time**: < 100ms for schema validation
- **Database Lookup**: < 200ms for email existence check
- **Total Processing**: < 400ms including all validations

### Security Considerations

1. **Rate Limiting**: Implement rate limiting (10 requests per minute per IP)
2. **Input Sanitization**: All inputs sanitized before processing
3. **SQL Injection Prevention**: Use parameterized queries
4. **Service Role Key**: Never expose in response or logs
5. **Audit Logging**: Log all validation attempts with anonymized data
6. **CORS**: Restrict to allowed origins only

### Testing Strategy

1. **Unit Tests**: Test each validator independently
2. **Integration Tests**: Test with Supabase Admin API
3. **Load Tests**: Verify < 500ms response under load
4. **Security Tests**: Test injection attempts and edge cases
5. **Role-Specific Tests**: Comprehensive tests for each role

### Implementation Notes

1. Use Zod for runtime type validation with TypeScript inference
2. Implement early returns for validation failures
3. Use async/await for Supabase API calls
4. Cache regex patterns for performance
5. Implement proper error boundaries
6. Use structured logging for debugging

### Medical Compliance (HIPAA)

- No patient data collected during registration
- Audit log anonymization for failed attempts
- Secure credential handling
- No PII in error messages or logs

### Dependencies

```json
{
  "imports": {
    "supabase": "https://esm.sh/@supabase/supabase-js@2.45.0",
    "zod": "https://deno.land/x/zod@v3.22.4/mod.ts"
  }
}
```

### Deployment Configuration

```toml
[functions.registration-validator]
verify_jwt = false  # We handle auth internally
import_map = "./import_map.json"
```

### Monitoring & Observability

- Log validation attempts with role and result (success/failure)
- Track response times for performance monitoring
- Alert on repeated validation failures (possible attack)
- Monitor error rates by error code

### Future Enhancements

1. Add captcha verification for repeated failures
2. Implement progressive delay for multiple attempts
3. Add email verification step
4. Support bulk validation for admin imports
5. Add license verification with external APIs

---

**Status**: Design Complete ✅
**Next Step**: Implementation (Task 3.1 Step 2)