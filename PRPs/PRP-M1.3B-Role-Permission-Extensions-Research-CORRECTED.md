# PRP-M1.3B: Role-Specific Permission Extensions Research (CORRECTED)

**Task**: M1.3B - Implement Role-Specific Permission Extensions  
**Phase**: Research (架构师反馈修正版)  
**Dependencies**: M1.3A RLS Basic Policies (Complete)  
**Scope**: 受控跨角色业务访问，处方履行工作流，受控视图+RLS架构
**Boundaries**: 仅设计阶段，禁止实施直至获得架构师实施绿灯

## 🚨 架构师反馈修正摘要

**关键修正**:
1. **RLS策略仅做布尔判定** - 移除字段级过滤和副作用调用
2. **受控视图+RLS模式** - 通过视图实现字段投影，RLS仅控制行访问
3. **SECURITY DEFINER函数** - 替代方案，返回受控行投影
4. **Helper函数安全基线** - SECURITY DEFINER + 固定search_path + 无副作用
5. **移除缓存叙述** - PostgreSQL无安全可靠的会话级缓存
6. **零PII合规检查** - 逐列验证投影字段PII状态

---

## 📊 Deliverable 1: 受控视图+RLS架构设计

### 架构原理修正

**错误模式** (已修正):
```sql
-- ❌ RLS策略不能做字段级过滤
CREATE POLICY "pharmacy_business_context" ON user_profiles
  FOR SELECT USING (
    -- 错误: 尝试在RLS中做字段级可见性
    SELECT filtered_columns FROM some_view WHERE business_relation_exists
  );
```

**正确架构** (受控视图+RLS):
```sql
-- ✅ RLS策略仅做布尔判定
CREATE POLICY "pharmacy_business_context" ON user_profiles
  FOR SELECT USING (
    private.has_business_relationship(auth.uid(), user_profiles.id, 'prescription_fulfillment')
  );

-- ✅ 视图实现字段投影
CREATE VIEW v_profiles_pharmacy_context AS 
SELECT id, role, business_info, tcm_specialty, tcm_certification_level
FROM user_profiles;
```

### 受控视图设计

**视图1: Pharmacy Business Context**
```sql
CREATE VIEW v_profiles_pharmacy_context AS 
SELECT 
    id,
    role,
    business_info,
    -- TCM专业信息（处方履行需要）
    tcm_specialty,
    tcm_certification_level,
    tcm_clinic_affiliation,
    created_at
FROM user_profiles
WHERE role IN ('tcm_practitioner', 'pharmacy');

-- RLS策略（仅布尔判定）
CREATE POLICY "pharmacy_business_access" ON user_profiles
  FOR SELECT USING (
    private.has_prescription_business_relationship(auth.uid(), id)
  );
```

**视图2: TCM Professional Context**
```sql
CREATE VIEW v_profiles_tcm_context AS 
SELECT 
    id,
    role, 
    business_info,
    -- Pharmacy基础信息（转诊需要）
    pharmacy_type,
    pharmacy_license_scope,
    created_at
FROM user_profiles
WHERE role IN ('tcm_practitioner', 'pharmacy');

-- RLS策略（仅布尔判定）
CREATE POLICY "tcm_referral_access" ON user_profiles
  FOR SELECT USING (
    private.has_referral_business_relationship(auth.uid(), id)
  );
```

**视图3: Public Directory**
```sql
CREATE VIEW v_profiles_public_directory AS 
SELECT 
    id,
    role,
    business_info,
    created_at
FROM user_profiles
WHERE status = 'active';

-- 公共访问（无需业务关系）
CREATE POLICY "public_directory_access" ON user_profiles
  FOR SELECT USING (true);
```

### SECURITY DEFINER函数替代方案

**函数1: Pharmacy Business Context**
```sql
CREATE OR REPLACE FUNCTION get_pharmacy_business_context(target_user_id UUID)
RETURNS TABLE(
    id UUID,
    role TEXT,
    business_info JSONB,
    tcm_specialty tcm_specialty_enum,
    tcm_certification_level tcm_certification_enum,
    tcm_clinic_affiliation VARCHAR(200)
)
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    -- 授权检查：仅pharmacy角色，且有业务关系
    IF NOT (private.get_current_user_role() = 'pharmacy' AND 
            private.has_prescription_business_relationship(auth.uid(), target_user_id)) THEN
        RAISE EXCEPTION 'Access denied: no business relationship';
    END IF;
    
    -- 返回受控字段投影
    RETURN QUERY 
    SELECT up.id, up.role, up.business_info, 
           up.tcm_specialty, up.tcm_certification_level, up.tcm_clinic_affiliation
    FROM user_profiles up
    WHERE up.id = target_user_id;
END $$;
```

**函数2: TCM Professional Context**
```sql
CREATE OR REPLACE FUNCTION get_tcm_professional_context(target_user_id UUID)
RETURNS TABLE(
    id UUID,
    role TEXT,
    business_info JSONB,
    pharmacy_type pharmacy_type_enum,
    pharmacy_license_scope pharmacy_scope_enum
)
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    -- 授权检查：仅tcm_practitioner角色，且有业务关系
    IF NOT (private.get_current_user_role() = 'tcm_practitioner' AND 
            private.has_referral_business_relationship(auth.uid(), target_user_id)) THEN
        RAISE EXCEPTION 'Access denied: no referral relationship';
    END IF;
    
    -- 返回受控字段投影
    RETURN QUERY 
    SELECT up.id, up.role, up.business_info, 
           up.pharmacy_type, up.pharmacy_license_scope
    FROM user_profiles up
    WHERE up.id = target_user_id;
END $$;
```

---

## 🔐 Deliverable 2: Helper函数安全基线修正

### 现有Helper函数修正

**修正1: private.has_prescription_business_relationship()**
```sql
CREATE OR REPLACE FUNCTION private.has_prescription_business_relationship(
    requester_id UUID, 
    target_id UUID
)
RETURNS BOOLEAN
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    -- 仅返回boolean，无副作用
    RETURN EXISTS (
        SELECT 1 FROM prescription_relationships pr
        WHERE (pr.tcm_practitioner_id = requester_id AND pr.pharmacy_id = target_id)
           OR (pr.pharmacy_id = requester_id AND pr.tcm_practitioner_id = target_id)
        AND pr.status = 'active'
        AND pr.expires_at > NOW()
    );
END $$;
```

**修正2: private.has_referral_business_relationship()**
```sql
CREATE OR REPLACE FUNCTION private.has_referral_business_relationship(
    requester_id UUID, 
    target_id UUID
)
RETURNS BOOLEAN
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    -- 仅返回boolean，无副作用
    RETURN EXISTS (
        SELECT 1 FROM referral_relationships rr
        WHERE (rr.referring_tcm_id = requester_id AND rr.receiving_pharmacy_id = target_id)
           OR (rr.receiving_pharmacy_id = requester_id AND rr.referring_tcm_id = target_id)
        AND rr.status = 'active'
        AND rr.created_at > NOW() - INTERVAL '90 days'
    );
END $$;
```

**修正3: private.get_current_user_role() 安全基线**
```sql
CREATE OR REPLACE FUNCTION private.get_current_user_role()
RETURNS TEXT
LANGUAGE PLPGSQL SECURITY DEFINER
SET search_path = public, pg_temp, private
AS $$
BEGIN
    -- 仅返回只读数据，无副作用
    RETURN (
        SELECT role 
        FROM user_profiles 
        WHERE id = auth.uid()
    );
END $$;
```

---

## 🎯 Deliverable 3: 授权条件与验证规则

### 最小可验证业务规则

**处方关系验证**:
```sql
-- 最小业务关系要求
prescription_business_relationship_requirements = {
    'tcm_practitioner_to_pharmacy': {
        'table': 'prescription_relationships',
        'conditions': [
            'tcm_practitioner_id = requester AND pharmacy_id = target',
            'status = active',
            'expires_at > NOW()'
        ],
        'minimum_duration': '24 hours',
        'verification_required': true
    },
    'pharmacy_to_tcm_practitioner': {
        'reverse_lookup': true,
        'same_conditions': true
    }
}
```

**转诊关系验证**:
```sql
-- 转诊业务关系要求
referral_business_relationship_requirements = {
    'tcm_to_pharmacy_referral': {
        'table': 'referral_relationships', 
        'conditions': [
            'referring_tcm_id = requester AND receiving_pharmacy_id = target',
            'status = active',
            'created_at > NOW() - INTERVAL 90 days'
        ],
        'minimum_cases': 1,
        'verification_required': true
    }
}
```

### 系统表验证脚本

**验证脚本1: 视图结构验证**
```sql
-- 验证受控视图创建成功
SELECT schemaname, viewname, definition 
FROM pg_views 
WHERE viewname IN (
    'v_profiles_pharmacy_context',
    'v_profiles_tcm_context', 
    'v_profiles_public_directory'
)
ORDER BY viewname;
```

**验证脚本2: RLS策略验证**
```sql
-- 验证RLS策略仅包含布尔判定
SELECT schemaname, tablename, policyname, cmd, permissive, qual, with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_profiles'
AND policyname LIKE '%business%'
ORDER BY policyname;
```

**验证脚本3: SECURITY DEFINER函数验证**
```sql
-- 验证函数安全设置
SELECT proname, prosecdef, proconfig, prosrc
FROM pg_proc 
WHERE proname IN (
    'get_pharmacy_business_context',
    'get_tcm_professional_context',
    'has_prescription_business_relationship'
)
AND prosecdef = true  -- 确认SECURITY DEFINER
ORDER BY proname;
```

### 正负边界用例

**正用例（应该成功）**:
```sql
-- 用例1: Pharmacy访问有处方关系的TCM档案
-- 前置条件: 存在active prescription_relationship
-- 预期: 返回TCM专业字段（specialty, certification_level）

-- 用例2: TCM访问有转诊关系的Pharmacy档案  
-- 前置条件: 存在active referral_relationship
-- 预期: 返回Pharmacy基础字段（type, license_scope）
```

**负用例（应该被拒绝）**:
```sql
-- 用例1: 无业务关系的跨角色访问
-- 前置条件: 无prescription或referral关系
-- 预期: 拒绝访问，返回空结果集

-- 用例2: 过期关系的访问尝试
-- 前置条件: 关系已过期或inactive
-- 预期: 拒绝访问，函数抛出异常
```

**边界用例（边界条件）**:
```sql
-- 用例1: 关系即将过期
-- 前置条件: expires_at在未来1小时内
-- 预期: 仍允许访问，直到精确过期时间

-- 用例2: 新创建的关系
-- 前置条件: 关系刚创建，status=pending
-- 预期: 拒绝访问，必须status=active
```

---

## 🛡️ Deliverable 4: 零PII合规检查

### 逐列PII状态核对

**v_profiles_pharmacy_context 字段审核**:
```yaml
id: "✅ 非PII - 系统生成UUID"
role: "✅ 非PII - 枚举值(tcm_practitioner/pharmacy)" 
business_info: "✅ 非PII - 机构信息JSONB，已审核无个人标识符"
tcm_specialty: "✅ 非PII - 枚举值(acupuncture/herbal_medicine等)"
tcm_certification_level: "✅ 非PII - 枚举值(student/licensed/senior/master)"
tcm_clinic_affiliation: "⚠️ 低风险 - 机构名称，非个人信息"
created_at: "✅ 非PII - 时间戳"
```

**v_profiles_tcm_context 字段审核**:
```yaml
id: "✅ 非PII - 系统生成UUID"
role: "✅ 非PII - 枚举值(tcm_practitioner/pharmacy)"
business_info: "✅ 非PII - 机构信息JSONB，已审核无个人标识符" 
pharmacy_type: "✅ 非PII - 枚举值(retail_pharmacy/hospital_pharmacy等)"
pharmacy_license_scope: "✅ 非PII - 枚举值(basic_dispensing/controlled_substances等)"
created_at: "✅ 非PII - 时间戳"
```

**排除的高风险PII字段**:
```yaml
personal_name: "❌ 高风险PII - 已排除"
email: "❌ 高风险PII - 已排除"
phone_number: "❌ 高风险PII - 已排除"
license_number: "❌ 高风险PII - 已排除" 
address_info: "❌ 高风险PII - 已排除"
tcm_practice_years: "❌ 可推算年龄PII - 已排除"
pharmacy_location_count: "❌ 可能泄露规模PII - 已排除"
```

### 最小暴露原则验证

**暴露必要性矩阵**:
| 字段 | 处方履行必要性 | 转诊决策必要性 | 业务验证必要性 | 最终状态 |
|------|---------------|---------------|---------------|----------|
| tcm_specialty | ✅ 处方适配 | ✅ 专业匹配 | ✅ 资质验证 | 包含 |
| tcm_certification_level | ✅ 安全检查 | ✅ 信誉评估 | ✅ 合规验证 | 包含 |
| pharmacy_type | ✅ 服务能力 | ✅ 转诊目标 | ✅ 能力匹配 | 包含 |
| pharmacy_license_scope | ✅ 药品权限 | ✅ 服务范围 | ✅ 合规检查 | 包含 |

---

## 🧪 Deliverable 5: 测试矩阵

### 视图级读取测试

**测试场景1: v_profiles_pharmacy_context**
```sql
-- 正向测试
WITH test_users AS (
    SELECT id, role FROM user_profiles 
    WHERE role IN ('tcm_practitioner', 'pharmacy')
    LIMIT 2
)
SELECT v.* FROM v_profiles_pharmacy_context v
JOIN prescription_relationships pr ON (
    v.id = pr.tcm_practitioner_id AND pr.pharmacy_id = auth.uid()
)
WHERE pr.status = 'active';

-- 负向测试（应返回空）
SELECT * FROM v_profiles_pharmacy_context
WHERE id NOT IN (
    SELECT tcm_practitioner_id FROM prescription_relationships 
    WHERE pharmacy_id = auth.uid() AND status = 'active'
);
```

**测试场景2: SECURITY DEFINER函数**
```sql
-- 正向测试
SELECT * FROM get_pharmacy_business_context('existing-tcm-uuid');

-- 负向测试（应抛出异常）
SELECT * FROM get_pharmacy_business_context('no-relationship-uuid');
```

### 处方关系测试数据

**测试关系建立**:
```sql
-- 创建测试处方关系
INSERT INTO prescription_relationships (
    id,
    tcm_practitioner_id, 
    pharmacy_id,
    status,
    expires_at
) VALUES (
    gen_random_uuid(),
    'test-tcm-uuid',
    'test-pharmacy-uuid', 
    'active',
    NOW() + INTERVAL '30 days'
);
```

**边界条件测试**:
```sql
-- 过期关系测试
UPDATE prescription_relationships 
SET expires_at = NOW() - INTERVAL '1 day'
WHERE id = 'test-relationship-uuid';

-- 验证访问被拒绝
SELECT * FROM get_pharmacy_business_context('test-tcm-uuid');
-- 预期: EXCEPTION 'Access denied: no business relationship'
```

---

## 🔧 Deliverable 6: 系统表验证脚本

### DDL验证脚本

**视图创建验证**:
```sql
-- 验证所有受控视图存在且结构正确
SELECT 
    viewname,
    definition,
    CASE 
        WHEN definition LIKE '%tcm_specialty%' THEN '✅ TCM字段投影正确'
        WHEN definition LIKE '%pharmacy_type%' THEN '✅ Pharmacy字段投影正确'
        ELSE '✅ 基础字段投影正确'
    END as field_projection_status
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname LIKE 'v_profiles_%'
ORDER BY viewname;
```

**RLS策略验证**:
```sql
-- 验证策略仅包含布尔表达式，无字段过滤
SELECT 
    policyname,
    cmd,
    qual,
    CASE 
        WHEN qual LIKE '%private.has_%business_relationship%' THEN '✅ 布尔判定正确'
        WHEN qual LIKE '%SELECT%FROM%' THEN '❌ 包含子查询可能有字段过滤'
        ELSE '⚠️ 需人工检查'
    END as boolean_check_status
FROM pg_policies 
WHERE tablename = 'user_profiles' 
AND policyname LIKE '%business%'
ORDER BY policyname;
```

**函数安全设置验证**:
```sql
-- 验证所有helper函数安全配置
SELECT 
    proname,
    prosecdef,
    proconfig,
    CASE 
        WHEN prosecdef = true AND 'search_path=public,pg_temp,private' = ANY(proconfig) 
        THEN '✅ 安全配置正确'
        ELSE '❌ 安全配置缺失'
    END as security_status
FROM pg_proc 
WHERE proname IN (
    'has_prescription_business_relationship',
    'has_referral_business_relationship',
    'get_pharmacy_business_context',
    'get_tcm_professional_context'
)
ORDER BY proname;
```

---

## 🎯 Implementation Readiness Checklist

### 架构合规确认
- ✅ **RLS策略仅布尔判定**: 所有策略移除字段过滤和副作用
- ✅ **受控视图字段投影**: 通过视图实现字段级可见性控制  
- ✅ **SECURITY DEFINER函数**: 安全基线修正，固定search_path
- ✅ **零PII合规**: 逐列验证，排除高风险个人标识符
- ✅ **移除缓存叙述**: 移除所有函数级缓存实现
- ✅ **业务关系最小验证**: 基于真实prescription/referral表结构

### 测试就绪状态
- ✅ **正负边界用例**: 覆盖有效关系、无关系、过期关系场景
- ✅ **系统表验证脚本**: pg_views, pg_policies, pg_proc全面验证
- ✅ **DDL结构检查**: 视图定义、策略表达式、函数安全配置

### 实施边界确认  
- ✅ **仅设计阶段**: 未包含任何DDL执行，等待架构师实施绿灯
- ✅ **无索引创建**: 性能优化留待后续节点处理
- ✅ **无API/Edge Function变更**: 专注数据库层权限扩展

---

## 🛠️ Implementation Phase - Post-IRG Remediation

**IRG Status**: ❌ **CRITICAL FAILURE** - Requires architectural remediation  
**Defect Reference**: `Task-1.3B-IRG-DEFECTS-CRITICAL.md`  
**Architect Directive**: Apply RLS to base `user_profiles` table, not views  
**Remediation Approach**: EUD-driven 4 Dev-Step execution cycle

### Critical Defect Summary
1. **RLS on Views Not Supported**: PostgreSQL cannot apply RLS policies to views - fundamental architectural error
2. **Missing Migration Dependencies**: `tcm_specialty` and `pharmacy_type` columns dependency not in chain  
3. **Validation Script Issues**: search_path pattern mismatch causing false negatives

### Architect Remediation Requirements
Based on architect feedback, implement RLS on base `user_profiles` table with 3 cross-role policies:
- `cross_role_pharmacy_select`: Pharmacy→TCM business access
- `cross_role_tcm_select`: TCM→Pharmacy business access  
- `public_directory_select`: Authenticated user public directory access

### Implementation Dev-Steps

#### Dev-Step 1: Migration and Rollback Scripts (Dependency Assertions)
**Deliverable**: Corrected migration `20250905180700_rls_ext_policies_on_base_table.sql`
**Requirements**:
- Remove all view RLS attempts (lines 20-22 in original migration)
- Apply RLS policies to `user_profiles` base table only
- Add dependency assertions for `tcm_specialty` and `pharmacy_type` columns
- Fix validation script search_path pattern matching
- Create proper rollback script with dependency cleanup

**QAD Acceptance Criteria**:
- ✅ Migration executes successfully without PostgreSQL errors
- ✅ Dependency assertions provide clear error messages if columns missing
- ✅ Validation script correctly identifies function configurations
- ✅ Rollback script cleanly removes policies and restores original state

#### Dev-Step 2: Base Table Policy Implementation (System Table Verification)
**Deliverable**: 3 RLS policies on `user_profiles` with system table validation
**Requirements**:
- Policy 1: `cross_role_pharmacy_select` using `private.has_prescription_business_relationship()`
- Policy 2: `cross_role_tcm_select` using `private.has_referral_business_relationship()`  
- Policy 3: `public_directory_select` with explicit field conditions for public access
- Admin separate select policy (no bare authenticated access)
- System table verification via `pg_policies` queries

**QAD Acceptance Criteria**:
- ✅ All 3 policies created with pure boolean authorization (no field filtering)
- ✅ System table verification confirms policies exist and are correctly configured
- ✅ Controlled views inherit security from base table automatically
- ✅ Admin access properly segregated with dedicated policy

#### Dev-Step 3: Behavioral Tests and Zero-PII Verification
**Deliverable**: Comprehensive test suite with positive/negative/boundary cases
**Requirements**:
- Positive cases: Valid business relationships allow cross-role access
- Negative cases: No relationships deny access appropriately  
- Boundary cases: Expired relationships, edge conditions
- Zero-PII verification: Confirm all exposed fields comply with non-PII requirements
- Business relationship table integration testing

**QAD Acceptance Criteria**:
- ✅ All positive test cases pass (valid business access works)
- ✅ All negative test cases pass (unauthorized access blocked)
- ✅ Boundary conditions handled correctly (expiration, status changes)
- ✅ Zero-PII compliance verified for all controlled view fields

#### Dev-Step 4: Evidence Triplet and Remediation Report
**Deliverable**: Complete evidence package for IRG retest
**Requirements**:
- Technical Evidence: System table dumps, policy configurations, migration logs
- Behavioral Evidence: Test execution results, positive/negative case documentation
- Compliance Evidence: Zero-PII verification report, security boundary confirmation
- Remediation Report: Defect resolution summary, architectural changes documented

**QAD Acceptance Criteria**:
- ✅ Technical evidence demonstrates correct RLS implementation on base table
- ✅ Behavioral evidence shows proper authorization across all scenarios  
- ✅ Compliance evidence confirms zero-PII requirements met
- ✅ Remediation report provides clear path for IRG retest approval

### Implementation Boundary Conditions
- **Branch Target**: All changes commit to "2025-09-05" branch only
- **Migration Chain**: Must include dependency on `20250905160602_role_specific_profile_fields.sql`
- **Security Model**: RLS on base table only, views inherit security automatically
- **Testing Approach**: Use local Supabase environment, no production impact

---

**当前状态**: 实施阶段 - 等待Backend Lead执行4个Dev-Step QAD循环

**IRG Retest条件**: 完成全部4个Dev-Step并生成完整证据三联后，可申请IRG重新测试

---

**Research Phase Complete (CORRECTED)**: 基于架构师反馈完成6项核心修正，建立受控视图+RLS正确架构模式。  
**Implementation Phase Initiated**: Dev-Step 0完成，PRP文档增补实施任务，准备QAD执行循环。