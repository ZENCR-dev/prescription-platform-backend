# Task 1.2 Research Phase - Migration Blueprint

## Purpose
Document step-by-step migration and rollback plans for role-specific profile fields implementation (planning phase only, no code implementation).

**Evidence Standard**: Complete operational blueprint with atomic steps and failure recovery paths.

---

## Forward Migration Blueprint

### Phase 1: Constraint Inconsistency Resolution

**Step 1.1**: Fix `check_professional_role_license` constraint definition
- **Operation**: DROP CONSTRAINT + ADD CONSTRAINT  
- **Target**: Update role references from ('practitioner', 'pharmacy_operator') to ('tcm_practitioner', 'pharmacy')
- **Atomicity**: Single ALTER TABLE transaction
- **Validation**: Query pg_constraint to verify updated definition

**Step 1.2**: Validate constraint consistency
- **Operation**: Execute test queries with all role values
- **Target**: Confirm both constraints accept identical role value set
- **Atomicity**: Read-only validation queries
- **Validation**: Both constraints pass with 'tcm_practitioner', 'pharmacy', 'admin'

### Phase 2: Enum Type Creation

**Step 2.1**: Create TCM-related enum types
- **Operation**: CREATE TYPE statements for `tcm_specialty_enum`, `tcm_certification_enum`
- **Target**: Establish TCM practitioner specialization and certification enums
- **Atomicity**: Individual CREATE TYPE transactions
- **Validation**: Query pg_type to confirm enum existence and values

**Step 2.2**: Create Pharmacy-related enum types  
- **Operation**: CREATE TYPE statements for `pharmacy_type_enum`, `pharmacy_scope_enum`
- **Target**: Establish pharmacy business type and operational scope enums
- **Atomicity**: Individual CREATE TYPE transactions
- **Validation**: Query pg_type to confirm enum existence and values

**Step 2.3**: Create Admin-related enum types
- **Operation**: CREATE TYPE statements for `admin_level_enum`, `admin_scope_enum`  
- **Target**: Establish administrative hierarchy and jurisdiction enums
- **Atomicity**: Individual CREATE TYPE transactions
- **Validation**: Query pg_type to confirm enum existence and values

### Phase 3: Role-Specific Field Addition

**Step 3.1**: Add TCM Practitioner fields
- **Operation**: ALTER TABLE ADD COLUMN statements (4 fields)
- **Target**: tcm_specialty, tcm_practice_years, tcm_certification_level, tcm_clinic_affiliation
- **Atomicity**: Single ALTER TABLE transaction with multiple column additions
- **Validation**: Query information_schema.columns to verify field addition

**Step 3.2**: Add Pharmacy fields
- **Operation**: ALTER TABLE ADD COLUMN statements (4 fields)
- **Target**: pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit
- **Atomicity**: Single ALTER TABLE transaction with multiple column additions
- **Validation**: Query information_schema.columns to verify field addition

**Step 3.3**: Add Admin fields
- **Operation**: ALTER TABLE ADD COLUMN statements (4 fields)
- **Target**: admin_level, admin_scope, admin_certification_date, admin_supervisor_id  
- **Atomicity**: Single ALTER TABLE transaction with multiple column additions
- **Validation**: Query information_schema.columns to verify field addition

### Phase 4: Validation Functions and Constraints

**Step 4.1**: Create cross-role field isolation constraints
- **Operation**: ALTER TABLE ADD CONSTRAINT statements (3 constraints)
- **Target**: Ensure role-specific fields are NULL for inappropriate roles
- **Atomicity**: Individual constraint addition transactions
- **Validation**: Attempt constraint violation to confirm enforcement

**Step 4.2**: Create business logic validation constraints
- **Operation**: ALTER TABLE ADD CONSTRAINT statements (3 business rules)
- **Target**: Admin hierarchy, pharmacy location, TCM certification correlation
- **Atomicity**: Individual constraint addition transactions  
- **Validation**: Test business rule enforcement with sample data

**Step 4.3**: Create validation trigger function
- **Operation**: CREATE FUNCTION + CREATE TRIGGER statements
- **Target**: Dynamic validation for role-specific field requirements
- **Atomicity**: Function and trigger creation in single transaction
- **Validation**: INSERT/UPDATE operations trigger validation correctly

### Phase 5: Performance Optimization

**Step 5.1**: Create role-specific partial indexes
- **Operation**: CREATE INDEX statements with WHERE clauses
- **Target**: Optimize queries filtering by role and role-specific fields
- **Atomicity**: Individual index creation transactions
- **Validation**: EXPLAIN ANALYZE confirms index utilization

**Step 5.2**: Create composite indexes for common query patterns  
- **Operation**: CREATE INDEX statements on field combinations
- **Target**: Admin hierarchy queries, pharmacy search patterns, TCM specialty lookups
- **Atomicity**: Individual index creation transactions
- **Validation**: Query plan analysis confirms optimization

### Phase 6: Migration Audit and Documentation

**Step 6.1**: Insert migration completion audit record
- **Operation**: INSERT into audit log with migration metadata
- **Target**: Document successful completion with field counts and performance metrics
- **Atomicity**: Single INSERT transaction
- **Validation**: Query audit log to confirm record insertion

---

## Rollback Migration Blueprint

### Phase R1: Performance Optimization Removal

**Step R1.1**: Drop composite indexes
- **Operation**: DROP INDEX statements for composite indexes
- **Target**: Remove optimization indexes created in Phase 5.2
- **Atomicity**: Individual DROP INDEX transactions  
- **Validation**: Query pg_indexes to confirm index removal

**Step R1.2**: Drop role-specific partial indexes
- **Operation**: DROP INDEX statements for partial indexes
- **Target**: Remove role-specific optimization indexes from Phase 5.1
- **Atomicity**: Individual DROP INDEX transactions
- **Validation**: Query pg_indexes to confirm index removal

### Phase R2: Validation Functions and Constraints Removal

**Step R2.1**: Drop validation trigger and function
- **Operation**: DROP TRIGGER + DROP FUNCTION statements
- **Target**: Remove dynamic validation mechanisms from Phase 4.3
- **Atomicity**: Trigger and function removal in single transaction
- **Validation**: Attempt function call to confirm removal

**Step R2.2**: Drop business logic validation constraints
- **Operation**: ALTER TABLE DROP CONSTRAINT statements (3 constraints)
- **Target**: Remove business rule constraints from Phase 4.2
- **Atomicity**: Individual constraint removal transactions
- **Validation**: Query pg_constraint to confirm constraint removal

**Step R2.3**: Drop cross-role field isolation constraints  
- **Operation**: ALTER TABLE DROP CONSTRAINT statements (3 constraints)
- **Target**: Remove role isolation constraints from Phase 4.1
- **Atomicity**: Individual constraint removal transactions
- **Validation**: Query pg_constraint to confirm constraint removal

### Phase R3: Role-Specific Field Removal

**Step R3.1**: Drop Admin fields
- **Operation**: ALTER TABLE DROP COLUMN statements (4 fields)
- **Target**: Remove admin_level, admin_scope, admin_certification_date, admin_supervisor_id
- **Atomicity**: Single ALTER TABLE transaction with multiple column drops
- **Validation**: Query information_schema.columns to verify field removal

**Step R3.2**: Drop Pharmacy fields
- **Operation**: ALTER TABLE DROP COLUMN statements (4 fields)  
- **Target**: Remove pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit
- **Atomicity**: Single ALTER TABLE transaction with multiple column drops
- **Validation**: Query information_schema.columns to verify field removal

**Step R3.3**: Drop TCM Practitioner fields
- **Operation**: ALTER TABLE DROP COLUMN statements (4 fields)
- **Target**: Remove tcm_specialty, tcm_practice_years, tcm_certification_level, tcm_clinic_affiliation  
- **Atomicity**: Single ALTER TABLE transaction with multiple column drops
- **Validation**: Query information_schema.columns to verify field removal

### Phase R4: Enum Type Removal

**Step R4.1**: Drop Admin-related enum types
- **Operation**: DROP TYPE statements for admin_level_enum, admin_scope_enum
- **Target**: Remove administrative enum types from Phase 2.3
- **Atomicity**: Individual DROP TYPE transactions
- **Validation**: Query pg_type to confirm enum removal

**Step R4.2**: Drop Pharmacy-related enum types
- **Operation**: DROP TYPE statements for pharmacy_type_enum, pharmacy_scope_enum
- **Target**: Remove pharmacy enum types from Phase 2.2  
- **Atomicity**: Individual DROP TYPE transactions
- **Validation**: Query pg_type to confirm enum removal

**Step R4.3**: Drop TCM-related enum types
- **Operation**: DROP TYPE statements for tcm_specialty_enum, tcm_certification_enum
- **Target**: Remove TCM enum types from Phase 2.1
- **Atomicity**: Individual DROP TYPE transactions
- **Validation**: Query pg_type to confirm enum removal

### Phase R5: Constraint Inconsistency Restoration

**Step R5.1**: Restore original `check_professional_role_license` constraint
- **Operation**: DROP CONSTRAINT + ADD CONSTRAINT with original definition
- **Target**: Restore role references to ('practitioner', 'pharmacy_operator', 'admin')  
- **Atomicity**: Single ALTER TABLE transaction
- **Validation**: Query pg_constraint to verify original definition restoration

**Step R5.2**: Remove rollback completion audit record
- **Operation**: INSERT into audit log with rollback metadata
- **Target**: Document successful rollback completion
- **Atomicity**: Single INSERT transaction
- **Validation**: Query audit log to confirm rollback record

---

## Failure Recovery Paths

### Forward Migration Failure Points

**Phase 1 Failure (Constraint Fix)**:
- **Failure Condition**: Constraint update fails due to existing data violations
- **Recovery Action**: Execute immediate rollback to Phase R5.1 (restore original constraint)
- **Data Safety**: No data loss, constraint definitions restored to original state
- **Retry Strategy**: Analyze constraint violations, fix data, retry constraint update

**Phase 2 Failure (Enum Creation)**:
- **Failure Condition**: CREATE TYPE fails due to naming conflicts or syntax errors
- **Recovery Action**: DROP any successfully created enums, rollback to Phase R4
- **Data Safety**: No data schema changes, no data loss risk
- **Retry Strategy**: Fix enum definitions, verify naming uniqueness, retry creation

**Phase 3 Failure (Field Addition)**:
- **Failure Condition**: ALTER TABLE ADD COLUMN fails due to name conflicts or type errors
- **Recovery Action**: DROP any successfully added columns, rollback to Phase R3
- **Data Safety**: Column additions are safe, DROP COLUMN removes added fields cleanly
- **Retry Strategy**: Fix column definitions, verify name uniqueness, retry addition

**Phase 4 Failure (Validation Logic)**:
- **Failure Condition**: Constraint or function creation fails due to logic errors
- **Recovery Action**: DROP any successfully created constraints/functions, rollback to Phase R2
- **Data Safety**: Validation logic changes don't affect existing data
- **Retry Strategy**: Fix validation logic, test constraint definitions, retry creation

**Phase 5 Failure (Index Creation)**:
- **Failure Condition**: CREATE INDEX fails due to resource constraints or naming conflicts
- **Recovery Action**: DROP any successfully created indexes, rollback to Phase R1  
- **Data Safety**: Index operations don't affect data, only query performance
- **Retry Strategy**: Fix index definitions, ensure sufficient disk space, retry creation

### Rollback Migration Failure Points

**Critical Rollback Failure**:
- **Failure Condition**: Rollback step fails and cannot complete cleanup
- **Recovery Action**: Manual intervention with database administrator support
- **Data Safety**: Implement partial rollback completion, document remaining steps
- **Emergency Protocol**: Create manual cleanup scripts for incomplete rollback states

### Atomic Operation Guarantees

**Transaction Boundaries**:
- Each phase operates within explicit transaction boundaries
- ROLLBACK on failure ensures no partial state persistence
- COMMIT only occurs after complete phase success and validation

**State Consistency**:
- Each validation step confirms expected database state before proceeding
- Failure at any validation step triggers immediate rollback of current phase
- Cross-phase dependencies verified before phase progression

---

## Migration Blueprint Verification

**✅ Forward Migration**: 6 phases, 14 steps, complete validation per step
**✅ Rollback Migration**: 5 phases, 13 steps, complete state restoration  
**✅ Failure Recovery**: Comprehensive recovery paths for all failure points
**✅ Atomicity Guarantee**: Transaction boundaries and rollback mechanisms defined
**✅ Validation Protocol**: Verification steps for each operation confirm success

**Migration Readiness**: Blueprint complete for Implement phase execution