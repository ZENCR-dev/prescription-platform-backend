# User Profiles Business Fields Extension Migration

## Overview
Migration `20250104_extend_user_profiles_business_fields.sql` extends the `user_profiles` table with comprehensive business registration, professional license tracking, and verification management fields for M1.3 User Profile Management Backend.

## Architecture Integration

### License Verification System Integration
- **Seamless Connection**: New fields integrate with existing `license-verification` Edge Function
- **Status Synchronization**: `license_status` and `professional_verified` sync automatically 
- **Format Validation**: License number format validation matches Edge Function patterns
- **Audit Trail**: `license_verification_id` links to `license_verifications` table

### Medical Platform Compliance
- **HIPAA Compliance**: Document references only (no actual files), secure audit logging
- **Role-Based Access**: Enhanced RLS policies for practitioner/pharmacy/admin roles
- **Zero-PII Architecture**: Sensitive data properly constrained and indexed
- **Audit Requirements**: Complete verification tracking with admin attribution

## Schema Changes

### New Fields Added (16 total)
```sql
-- Professional License Integration
license_number VARCHAR(20)              -- TCM-XXXXXX, PHARM-XXXXXX format
license_type VARCHAR(20)                -- 'tcm_practitioner', 'pharmacy'
license_status VARCHAR(20)              -- 'pending', 'verified', 'expired', 'suspended', 'rejected'
license_expiry_date DATE                -- Compliance tracking
license_verification_id VARCHAR(50)     -- Links to license_verifications table

-- Business Registration
business_name VARCHAR(200)              -- Official business name
business_registration_number VARCHAR(50) -- Government registration
tax_identification VARCHAR(50)          -- Tax ID
business_address JSONB                  -- Structured address data
business_phone VARCHAR(20)              -- Business contact
business_email VARCHAR(255)             -- Business email

-- Verification Status Tracking
identity_verified BOOLEAN               -- Personal ID verification
business_verified BOOLEAN               -- Business registration verification  
professional_verified BOOLEAN          -- License verification status

-- Audit and Compliance
verification_documents JSONB            -- Document metadata references
verification_notes TEXT                 -- Admin verification notes
verified_by UUID                       -- Admin who verified
verified_at TIMESTAMPTZ                -- Verification timestamp
compliance_flags JSONB                 -- Flexible compliance tracking
```

### Performance Indexes (9 total)
- **License Lookups**: `license_number`, `license_status`, `license_expiry_date`
- **Business Queries**: `business_name` 
- **Admin Management**: Multi-column verification status indexes
- **JSONB Optimization**: GIN indexes for `business_address`, `verification_documents`, `compliance_flags`

### Security Enhancements
- **Enhanced RLS Policies**: 6 policies covering user self-access and admin management
- **Verification Restrictions**: Users cannot modify their own verification status
- **Admin Oversight**: Full admin access for verification management
- **Audit Compliance**: Complete verification tracking and attribution

### Business Logic Constraints
- **License Format Validation**: Automatic format checking based on license type
- **Role Consistency**: Professional license types must match user roles
- **Verification Integrity**: Verification timestamp and admin attribution consistency
- **Integration Validation**: License verification ID requires corresponding license data

## Deployment Strategy

### Phase 1: Column Addition
- All fields added as nullable for safe migration
- No data loss during deployment
- Backward compatibility maintained

### Phase 2: Constraint Application  
- Business logic constraints applied after column creation
- Format validation enforced
- Role consistency checks enabled

### Phase 3: Performance Optimization
- Strategic indexes created for common query patterns
- JSONB optimization for flexible data
- Admin dashboard query optimization

### Phase 4: Security Enhancement
- Original RLS policies replaced with enhanced versions
- User self-modification restrictions
- Admin verification workflow support

### Phase 5: Integration Setup
- License verification sync trigger
- Automatic `professional_verified` status updates
- Audit logging integration

## Rollback Safety

### Complete Rollback Support
- **Full Reversion**: `rollback_20250104_extend_user_profiles_business_fields.sql`
- **Data Safety**: All changes completely reversible
- **Original State**: Returns table to exact pre-migration state
- **Verification Queries**: Included rollback verification steps

### Rollback Process
1. Remove triggers and functions
2. Drop enhanced RLS policies  
3. Remove performance indexes
4. Drop business logic constraints
5. Remove all added columns
6. Restore original RLS policies
7. Log rollback completion

## Testing Requirements

### Schema Integrity Tests
- Column constraints validation
- Data type verification  
- Business logic constraint testing
- RLS policy enforcement validation

### Performance Validation
- Index effectiveness verification
- Query performance benchmarking
- JSONB query optimization testing
- Admin dashboard response time validation

### Integration Testing
- License verification Edge Function compatibility
- Status synchronization validation
- Audit trail completeness verification
- Role-based access control testing

## Maintenance Notes

### Regular Monitoring
- **License Expiry Tracking**: Monitor `license_expiry_date` for compliance
- **Verification Status**: Track unverified users for admin follow-up
- **Index Performance**: Monitor query performance on new indexes
- **Compliance Flags**: Regular review of `compliance_flags` data

### Future Enhancements
- Additional business registration types
- Enhanced compliance tracking fields
- Integration with external verification services
- Advanced audit reporting capabilities

## Files Created
- `supabase/migrations/20250104_extend_user_profiles_business_fields.sql` - Main migration
- `supabase/migrations/rollback_20250104_extend_user_profiles_business_fields.sql` - Rollback script  
- `docs/migrations/20250104_user_profiles_business_fields_README.md` - This documentation