# Task 1.3B: IRG Critical Defects Report

**IRG Status**: ❌ **FAILED**  
**QA Lead**: Architecture Review & Integration Testing  
**Test Date**: 2025-09-05  
**Severity**: CRITICAL - Implementation blocked, requires architectural redesign

---

## 🚨 CRITICAL DEFECT #1: RLS on Views Not Supported

**Severity**: CRITICAL  
**Category**: Architectural Design Flaw  
**Impact**: Complete security model failure  

### Problem Description
The Task 1.3B implementation attempts to apply Row Level Security (RLS) policies directly to PostgreSQL views, which is not supported by PostgreSQL.

### Error Evidence
```sql
-- This fails in PostgreSQL
ALTER VIEW v_profiles_pharmacy_context ENABLE ROW LEVEL SECURITY;

-- Error: ALTER action ENABLE ROW SECURITY cannot be performed on relation "v_profiles_pharmacy_context"  
-- DETAIL: This operation is not supported for views.
```

### Technical Root Cause
PostgreSQL RLS can only be applied to **tables**, not **views**. The implementation fundamentally misunderstands PostgreSQL's security model.

### Current Implementation Status
- ✅ Views created: `v_profiles_pharmacy_context`, `v_profiles_tcm_context`, `v_profiles_public`
- ❌ RLS policies: 0/6 created (all failed)
- ⚠️ Security: Views currently have NO access control

### Required Fix - Choose ONE approach:

**Option A: RLS on Base Table (Recommended)**
```sql
-- Apply RLS policies to user_profiles table
-- Let views inherit security through base table
CREATE POLICY "cross_role_business_access" ON user_profiles
FOR SELECT USING (
    -- Your existing boolean logic
    private.has_prescription_business_relationship(auth.uid(), id) OR
    private.has_referral_business_relationship(auth.uid(), id) OR
    private.is_current_user_admin()
);
```

**Option B: SECURITY DEFINER Functions (Alternative)**
```sql
-- Replace views with SECURITY DEFINER functions
CREATE OR REPLACE FUNCTION get_pharmacy_context_for_user(target_id UUID)
RETURNS TABLE(...) SECURITY DEFINER AS $$
BEGIN
    -- Implement authorization logic inside function
    -- Return controlled row set
END $$;
```

### Reproduction Script
```bash
# Apply migrations up to controlled views creation
psql -f supabase/migrations/20250905180500_create_rls_ext_helpers.sql
psql -f supabase/migrations/20250905180600_create_controlled_views.sql

# This will fail:
psql -f supabase/migrations/20250905180700_rls_ext_policies_on_views.sql
# Error: RLS not supported on views
```

---

## 🚨 CRITICAL DEFECT #2: Missing Migration Dependency

**Severity**: HIGH  
**Category**: Dependency Management  
**Impact**: Implementation blocked without manual intervention  

### Problem Description
Task 1.3B migrations assume columns `tcm_specialty` and `pharmacy_type` exist in `user_profiles` table, but these are created by a separate migration that's not in the dependency chain.

### Missing Dependency
**Required Migration**: `20250905160602_role_specific_profile_fields.sql`  
**Current State**: Must be manually applied before Task 1.3B migrations

### Error Evidence
```sql
-- This fails without the dependency migration:
CREATE VIEW v_profiles_pharmacy_context AS 
SELECT id, role, business_name, pharmacy_type, ...  -- pharmacy_type doesn't exist
FROM user_profiles;

-- Error: column "pharmacy_type" does not exist
```

### Required Fix
1. Add explicit dependency documentation to Task 1.3B migrations
2. OR include role-specific fields in the Task 1.3B migration chain
3. OR use migration ordering to ensure dependency is applied first

### Verification Command
```sql
-- Before fix - this will return 0 rows:
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND column_name IN ('tcm_specialty', 'pharmacy_type');

-- After fix - should return 2 rows
```

---

## ⚠️ MEDIUM DEFECT #3: Validation Script Pattern Mismatch

**Severity**: MEDIUM  
**Category**: Testing/Validation  
**Impact**: False negatives in migration validation  

### Problem Description
Validation scripts search for `'search_path=public,pg_temp,private'` (no spaces) but actual PostgreSQL configuration stores `'search_path=public, pg_temp, private'` (with spaces).

### Error Evidence
```sql
-- Validation script looks for:
WHERE 'search_path=public,pg_temp,private' = ANY(proconfig)

-- But actual configuration is:
{"search_path=public, pg_temp, private"}  -- Note the spaces
```

### Impact
- Functions are correctly configured but validation reports failure
- Causes misleading error messages during migration execution

### Required Fix
```sql
-- Update validation pattern to handle spaces:
WHERE proconfig::text LIKE '%search_path=public%pg_temp%private%'
-- OR normalize before comparison
```

---

## 📊 IRG Summary Report

### Test Results
| Component | Expected | Actual | Status |
|-----------|----------|--------|--------|
| Controlled Views | 3 | 3 | ✅ PASS |
| RLS Policies | 6 | 0 | ❌ CRITICAL FAIL |  
| Helper Functions | 2 | 2 | ✅ PASS |
| Zero-PII Compliance | 100% | 100% | ✅ PASS |
| Dependency Resolution | Auto | Manual | ⚠️ FAIL |

### What Works
- ✅ Controlled views with proper column projections
- ✅ SECURITY DEFINER helper functions with correct configuration
- ✅ Zero-PII compliance across all views  
- ✅ Business logic functions execute correctly
- ✅ Field isolation and business semantics alignment

### What's Broken
- ❌ Complete RLS security model (0/6 policies created)
- ❌ Automatic migration dependency resolution  
- ⚠️ Migration validation accuracy

---

## 🛠️ Remediation Path for Backend Lead

### Immediate Actions Required
1. **Choose architectural approach** (RLS on table vs SECURITY DEFINER functions)
2. **Fix migration dependencies** (ensure role-specific fields migration runs first)  
3. **Update validation scripts** (fix pattern matching for search_path)
4. **Test complete workflow** end-to-end with actual user scenarios

### Validation Criteria for Next IRG
- ✅ All 6 RLS policies created successfully OR equivalent SECURITY DEFINER functions
- ✅ Migration dependency chain works without manual intervention
- ✅ Complete positive/negative behavioral test suite passes
- ✅ Validation scripts report accurate status

### Estimated Remediation Time
**2-4 hours** depending on chosen architectural approach

---

## 🎯 IRG Decision

**Result**: ❌ **IMPLEMENTATION BLOCKED**

**Rationale**: Critical architectural defect makes security model non-functional. While controlled views and helper functions work correctly, the complete absence of access control makes this unsuitable for production.

**Next Steps**: Backend Lead must choose and implement a working security architecture before IRG can pass.

**No merge operations permitted until defects resolved and IRG passes.**

---

**Generated**: 2025-09-05  
**QA Lead**: Architecture Review Complete  
**Status**: BLOCKED - Awaiting Backend Lead remediation