# PRP-M1.3A: RLS Basic Policies Research & Role Consistency Correction

**Task**: M1.3A - Implement RLS Basic Policies for Role-Specific Profile Fields  
**Phase**: Research  
**Dependencies**: M1.2 Role-Specific Fields (Complete)  
**Scope**: RLS基础策略，角色一致性修正，迁移蓝图 (Basic RLS policies, role consistency fixes, migration blueprint)  
**Boundaries**: 仅基础RLS策略，禁止角色扩展(1.3B)、API/Edge Function变更

## 🎯 Research Objectives

根据架构师指令，输出三个核心交付物：
1. **RLS基础策略设计** - 覆盖最小读/写路径、隔离与授权矩阵
2. **角色一致性修正方案** - canonical取值集与兼容映射，原子迁移蓝图  
3. **迁移/验证蓝图** - 事务边界、失败回滚、系统表验证点

---

## 📊 Deliverable 1: RLS基础策略设计

### 当前RLS状态分析

**已有策略** (from 20250822041103_create_user_profiles_table.sql):
```sql
-- 基础访问策略（已存在）
"Users can view their own profile" - SELECT (auth.uid() = id)  
"Users can update their own profile" - UPDATE (auth.uid() = id)
"Admin can insert user profiles" - INSERT (admin role check)
"Only admin can delete user profiles" - DELETE (admin role check)
```

**缺失策略** (Task 1.3A目标):
- 角色专属字段访问控制 (Role-specific field access control)
- 跨角色字段隔离强制执行 (Cross-role field isolation enforcement)  
- 角色级数据写入验证 (Role-level data write validation)

### 最小读/写路径设计

**读取路径优先级**:
1. **自身档案读取** - 用户可读取自己的完整档案（包括角色专属字段）
2. **管理员全量读取** - 管理员可读取所有用户档案和专属字段
3. **跨角色基础信息** - 有限的跨角色基础信息读取（不含专属字段）

**写入路径控制**:
1. **角色字段隔离** - 用户只能写入自己角色对应的专属字段
2. **跨角色写入禁止** - 严格禁止向其他角色的专属字段写入数据
3. **管理员特权写入** - 管理员可编辑所有角色字段（审计记录）

### 隔离与授权矩阵

| 用户角色 | TCM字段访问 | Pharmacy字段访问 | Admin字段访问 | 基础字段访问 | 审计要求 |
|---------|------------|----------------|--------------|------------|---------|
| **tcm_practitioner** | ✅ Full R/W | ❌ Read-Only ID | ❌ No Access | ✅ Full R/W | Standard |
| **pharmacy** | ❌ Read-Only ID | ✅ Full R/W | ❌ No Access | ✅ Full R/W | Standard |
| **admin** | ✅ Full R/W | ✅ Full R/W | ✅ Full R/W | ✅ Full R/W | **Enhanced** |

**字段分组定义**:
```sql
-- TCM字段组
tcm_specialty, tcm_practice_years, tcm_certification_level, tcm_clinic_affiliation

-- Pharmacy字段组  
pharmacy_type, pharmacy_license_scope, pharmacy_location_count, controlled_substance_permit

-- Admin字段组
admin_level, admin_scope, admin_certification_date, admin_supervisor_id

-- 基础字段组
id, role, status, business_info, created_at, updated_at
```

### RLS策略技术设计

**策略1: 角色专属字段读取控制**
```sql
CREATE POLICY "tcm_practitioners_can_read_tcm_fields" ON user_profiles
  FOR SELECT USING (
    auth.uid() = id OR 
    private.is_current_user_admin() OR
    (private.get_current_user_role() = 'tcm_practitioner' AND 
     -- 限制读取范围到TCM字段和基础字段
     pg_column_privileges('user_profiles') IN ('tcm_specialty', 'tcm_practice_years', ...))
  );
```

**策略2: 角色专属字段写入控制**  
```sql
CREATE POLICY "role_specific_field_write_isolation" ON user_profiles
  FOR UPDATE USING (
    auth.uid() = id AND (
      (private.get_current_user_role() = 'tcm_practitioner' AND 
       -- TCM用户只能更新TCM字段和基础字段
       check_tcm_fields_only_updated(OLD, NEW)) OR
      (private.get_current_user_role() = 'pharmacy' AND 
       check_pharmacy_fields_only_updated(OLD, NEW)) OR
      (private.get_current_user_role() = 'admin' AND 
       check_admin_fields_only_updated(OLD, NEW)) OR
      private.is_current_user_admin() -- 管理员特权
    )
  );
```

**策略3: 管理员审计增强**
```sql  
CREATE POLICY "admin_access_with_audit" ON user_profiles
  FOR ALL USING (
    private.is_current_user_admin() AND
    private.log_admin_profile_access(id, TG_OP) IS NOT NULL
  );
```

---

## 🔄 Deliverable 2: 角色一致性修正方案

### 角色不一致现状分析

**发现的不一致模式**:
```sql
-- 格式A (旧): 'practitioner', 'pharmacy_operator', 'admin'  
-- 使用位置: 基础表定义, 旧迁移, 回滚脚本

-- 格式B (新): 'tcm_practitioner', 'pharmacy', 'admin'
-- 使用位置: Task 1.2约束, 新RLS策略, enum系统
```

**具体不一致位置**:
1. **基础表约束**: `CHECK (role IN ('practitioner', 'pharmacy_operator', 'admin'))`  
2. **Task 1.2约束**: `CHECK (role IN ('tcm_practitioner', 'pharmacy', 'admin'))`
3. **RLS策略混用**: 部分使用旧值，部分使用新值  
4. **函数默认值**: handle_new_user()默认'practitioner'，应为'tcm_practitioner'

### Canonical取值集与兼容映射

**确立Canonical取值集** (权威标准):
```sql
-- 权威角色值定义 (Task 1.2已确立)
CANONICAL_ROLES = ['tcm_practitioner', 'pharmacy', 'admin']
```

**兼容映射表**:
```sql
-- 迁移期兼容读取映射
ROLE_COMPATIBILITY_MAP = {
  'practitioner' → 'tcm_practitioner',      -- 老值映射到新值
  'pharmacy_operator' → 'pharmacy',         -- 老值映射到新值  
  'admin' → 'admin'                         -- 保持不变
}
```

**兼容策略**:
1. **读取兼容**: 读取时两种格式都能识别和处理
2. **写入规范**: 新写入只使用canonical值  
3. **渐进迁移**: 现有数据逐步转换为canonical格式
4. **验证强化**: 确保所有约束使用canonical值

### 原子迁移蓝图

**阶段1: 基础表约束更新**
```sql
-- 移除旧约束
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;

-- 添加canonical约束 
ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_canonical_check
CHECK (role IN ('tcm_practitioner', 'pharmacy', 'admin'));
```

**阶段2: 现有数据规范化**
```sql
-- 数据值标准化 (原子操作)
BEGIN;
  UPDATE user_profiles SET role = 'tcm_practitioner' WHERE role = 'practitioner';
  UPDATE user_profiles SET role = 'pharmacy' WHERE role = 'pharmacy_operator';  
  -- admin保持不变
COMMIT;
```

**阶段3: 函数和默认值更新**  
```sql
-- 更新handle_new_user函数默认值
CREATE OR REPLACE FUNCTION handle_new_user() ... 
  VALUES (NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'role', 'tcm_practitioner'), -- 更新默认值
    ...)
```

**阶段4: RLS策略统一**
```sql  
-- 更新所有RLS策略使用canonical值
-- 确保private.get_current_user_role()等函数返回canonical值
```

---

## 🛡️ Deliverable 3: 迁移/验证蓝图

### 事务边界设计

**原子事务单元**:
```sql
-- 事务1: 约束更新 (原子)
BEGIN;
  ALTER TABLE user_profiles DROP CONSTRAINT user_profiles_role_check;
  ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_canonical_check 
    CHECK (role IN ('tcm_practitioner', 'pharmacy', 'admin'));
COMMIT;

-- 事务2: 数据规范化 (原子)  
BEGIN;
  UPDATE user_profiles SET role = 'tcm_practitioner' WHERE role = 'practitioner';
  UPDATE user_profiles SET role = 'pharmacy' WHERE role = 'pharmacy_operator';
COMMIT;

-- 事务3: RLS策略更新 (原子)
BEGIN;
  -- 批量策略更新
  CREATE POLICY ... ;
  CREATE POLICY ... ;  
COMMIT;
```

### 失败回滚机制

**回滚策略分层**:
```sql
-- Level 1: 事务级自动回滚
-- PostgreSQL自动处理事务内失败

-- Level 2: 迁移级手动回滚  
CREATE OR REPLACE FUNCTION rollback_role_consistency_fix()
RETURNS VOID AS $$
BEGIN
  -- 恢复旧约束定义
  ALTER TABLE user_profiles DROP CONSTRAINT user_profiles_role_canonical_check;
  ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check
    CHECK (role IN ('practitioner', 'pharmacy_operator', 'admin'));
  
  -- 恢复旧数据值
  UPDATE user_profiles SET role = 'practitioner' WHERE role = 'tcm_practitioner';  
  UPDATE user_profiles SET role = 'pharmacy_operator' WHERE role = 'pharmacy';
  
  -- 恢复旧RLS策略
  -- ... (详细回滚步骤)
END;
$$ LANGUAGE plpgsql;
```

**回滚验证点**:
1. 约束回滚后验证表结构完整性
2. 数据回滚后验证无数据丢失  
3. 策略回滚后验证RLS功能正常

### 系统表验证点

**验证脚本设计** (pg_catalog/information_schema):
```sql
-- 验证1: 约束一致性检查
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'user_profiles'::regclass 
AND conname LIKE '%role%';

-- 验证2: 数据值规范性检查
SELECT role, COUNT(*) as count,
  CASE WHEN role IN ('tcm_practitioner', 'pharmacy', 'admin') 
    THEN '✅ CANONICAL' 
    ELSE '❌ NON-CANONICAL' 
  END as compliance_status
FROM user_profiles 
GROUP BY role;

-- 验证3: RLS策略完整性检查  
SELECT schemaname, tablename, policyname, cmd, roles
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'user_profiles'
ORDER BY policyname;

-- 验证4: 函数定义一致性检查
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname IN ('handle_new_user', 'get_current_user_role', 'is_current_user_admin')
AND prosrc LIKE '%tcm_practitioner%';
```

**关键验证指标**:
- ✅ 约束定义使用canonical角色值  
- ✅ 数据值100%符合canonical格式
- ✅ RLS策略引用canonical角色值
- ✅ 函数默认值使用canonical角色值  
- ✅ 无数据丢失或损坏

### 迁移执行时序

**Pre-Migration检查**:
1. 备份当前角色数据分布统计
2. 验证无活跃事务锁定user_profiles
3. 确认RLS策略依赖关系完整

**Migration执行**:
1. 执行事务1 → 验证约束更新成功  
2. 执行事务2 → 验证数据规范化完成
3. 执行事务3 → 验证RLS策略更新完成

**Post-Migration验证**:
1. 运行完整验证脚本确认一致性
2. 执行功能测试验证RLS策略工作  
3. 生成迁移成功证据报告

---

## 🎯 Task 1.3A Implementation Readiness

### 边界确认
- ✅ **仅基础RLS策略**: 不包含角色扩展(1.3B)功能  
- ✅ **无API/Edge Function变更**: 专注于数据库层RLS实现
- ✅ **无索引创建**: 索引留待后续性能优化节点

### 架构师交付物确认  
1. ✅ **RLS基础策略设计**: 最小读写路径 + 授权矩阵 + 技术设计
2. ✅ **角色一致性修正方案**: canonical映射 + 兼容策略 + 原子蓝图  
3. ✅ **迁移/验证蓝图**: 事务边界 + 回滚机制 + 系统表验证

### 下一阶段准备
- **Task 1.3A Implement**: 基于此研究创建实际迁移脚本和RLS策略
- **严格边界维护**: 继续遵循架构师边界约束
- **QAD循环**: 每个原子任务完成后提交至日期分支，等待IRG实测

---
**Research Phase Complete**: 3个核心交付物已完成，为Task 1.3A Implement phase提供完整蓝图指导