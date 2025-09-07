# MR 校验清单 - M1.3B 文档修订与状态更新

**提交日期**: 2025-09-07  
**任务范围**: APIv1.md MVP瘦身 + PRP-M1.3 状态更新  
**架构师指令**: 严格边界内执行，仅限文档裁剪与状态标注

---

## ✅ 架构师质量门 (MEM) 验证

### 1) 受控视图合同 ✅
- **v_profiles_tcm_context**: 列集=6个非PII字段，业务过滤=prescription_business_relationship，单角色约束=tcm_practitioner
- **v_profiles_pharmacy_context**: 列集=6个非PII字段，业务过滤=referral_business_relationship，单角色约束=pharmacy  
- **v_profiles_public**: 列集=5个非PII字段，公共过滤=is_public_profile=true
- **security_barrier**: 三视图均声明 `security_barrier=true`
- **17个非PII字段总计**: pharmacy_context(6) + tcm_context(6) + public(5) = 17

### 2) RLS摘要 ✅
- **基表策略**: 11基线策略 (1.3A基础)
- **扩展策略**: 4扩展策略 (1.3B业务函数绑定)
  - admin_comprehensive_select (含业务函数)
  - cross_role_pharmacy_select (含业务函数)
  - cross_role_tcm_select (含业务函数)
  - public_directory_select (含业务函数)
- **视图策略**: 0策略 (业务逻辑在视图WHERE子句)

### 3) JWT合同 ✅
- **claims结构**: {sub, role, aud, exp, user_role, profile_status}
- **auth.uid()裁决一致性**: 基于JWT.sub字段
- **失效边界**: 无时间化表述，仅状态性描述
- **自定义声明**: 通过custom-access-token Edge Function增强

### 4) 错误码总表 ✅
- **代码/语义/HTTP映射**: VALIDATION_ERROR(400), EXPIRED_LICENSE(400), STATE_ERROR(400), NOT_FOUND(404), UNAUTHORIZED(401), FORBIDDEN(403)
- **前端提示锚点**: 标准化错误响应格式用于前端显示

### 5) 环境配置 ✅
- **变量名**: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, LOCAL_ANON_KEY
- **加载顺序**: 环境变量 → 客户端配置 → 认证初始化
- **无明文**: 所有真实URL/key已替换为${变量名}占位符
- **单一事实源链接**: 引用环境配置文档，不重复复制

### 6) IRG基线 ✅
- **四用例模式**: 
  - Pharmacy→TCM Positive: COUNT=2 (正>0 ✅)
  - 不存在用户→TCM Negative: COUNT=0 (负=0 ✅)
  - TCM→Pharmacy Positive: COUNT=2 (正>0 ✅)  
  - 不存在用户→Pharmacy Negative: COUNT=0 (负=0 ✅)
- **公目录验证**: COUNT=2 的验证模式
- **证据md锚点**: `test-evidence/Dev-Step-3-Behavioral-Evidence.md`

### 7) 安全属性 ✅
- **Helper函数合规**: has_prescription_business_relationship, has_referral_business_relationship, is_current_user_admin, get_current_user_role
- **SECURITY DEFINER**: ✅ 所有函数
- **STABLE**: ✅ 已从VOLATILE纠正为STABLE
- **固定search_path**: ✅ {"search_path=public, pg_temp, private"}

---

## ✅ MR 校验清单验证

### 受控视图合同与列集清单 ✅
```yaml
v_profiles_tcm_context: [id, role, business_name, tcm_specialty, verification_status, created_at]
v_profiles_pharmacy_context: [id, role, business_name, pharmacy_type, verification_status, created_at]  
v_profiles_public: [id, role, business_name, verification_status, created_at]
```

### security_barrier=true 说明 ✅
三个受控视图均配置 `security_barrier=true` 防止查询计划泄露信息

### RLS策略分类表 ✅
```yaml
基线策略 (11): [Admin can update verification status, Admin can view all profiles for verification, Profile creation with role validation, Users can update their own profile with restrictions, enhanced_delete_admin_only, enhanced_insert_admin_profiles, enhanced_insert_own_profile, enhanced_select_admin_all_profiles, enhanced_select_own_profile, enhanced_update_admin_profiles, enhanced_update_own_profile]

扩展策略 (4): [admin_comprehensive_select, cross_role_pharmacy_select, cross_role_tcm_select, public_directory_select]
```

### JWT claims 与错误码总表 ✅
- **JWT结构**: 标准+自定义声明完整定义
- **错误码**: 统一错误响应格式与HTTP状态码映射

### 环境参数占位与单一事实源链接 ✅
- **占位符**: 所有敏感信息替换为${变量名}
- **无真实密钥/URL**: 已清理所有明文配置
- **事实源链接**: 指向环境配置文档

### IRG四用例测试基线引用 ✅
- **证据链**: 指向 `test-evidence/Dev-Step-3-Behavioral-Evidence.md`
- **原始输出锚点**: 完整SQL执行结果与JWT上下文

### Zero-PII 承诺与字段清单一致性 ✅
- **17字段一致性**: pharmacy(6) + tcm(6) + public(5) = 17
- **无PII字段**: 仅business_name, role, specialty, verification_status等业务字段

---

## ✅ 文档瘦身完成确认

### 已删减内容
- **Edge Functions实现细节**: 详细实现逻辑简化为核心配置
- **冗长前端集成样例**: 复杂代码示例简化为模式说明
- **M2-M7里程碑引用**: 未来规划简化为滚动波次说明
- **冗长错误示例**: 详细错误场景简化为核心错误码
- **非MVP高级MFA细节**: 复杂MFA流程简化为基础功能

### 保留内容
- **受控视图合同**: 完整保留 (架构师要求)
- **核心认证与JWT结构**: 完整保留
- **用户档案管理**: 完整保留
- **执照校验**: 完整保留
- **错误码总表**: 完整保留
- **安全基线**: 完整保留
- **IRG测试基线**: 完整保留

---

## ✅ 纠偏确认

### 密钥安全 ✅
- **无真实anon key**: 已替换为 ${NEXT_PUBLIC_SUPABASE_ANON_KEY}
- **无真实URL**: 已替换为 ${NEXT_PUBLIC_SUPABASE_URL}
- **占位符使用**: 所有敏感信息使用环境变量占位符

### 视图合同完整性 ✅
- **无PII新增**: 未改变列语义或新增PII字段
- **无RLS绕过**: 无暗示跳过RLS/安全屏障的实现

---

## ✅ PRP-M1.3 状态更新确认

### Task 1.3B 完成标记 ✅
- **状态**: [x] COMPLETED 2025-09-07
- **IRG成功**: 所有行为用例通过验证
- **架构师合规**: Helper函数VOLATILE→STABLE纠正完成
- **证据链**: 指向完整IRG证据文档

### 进度记录 ✅
- **完成任务**: 1.3B 角色特定权限扩展
- **交付物**: 受控视图合同已入APIv1.md
- **证据沉淀**: IRG证据链已建立

---

## 🎯 Git 节点提示

**架构师指令**: 完成质量门验证并获得PASS后，用户执行以下Git操作

### 当前状态
- [x] APIv1.md MVP瘦身完成
- [x] PRP-M1.3 状态更新完成  
- [x] MEM质量门验证通过
- [x] MR校验清单完成

### 推荐Git操作 (用户执行)
1. **提交变更**: `git add APIdocs/APIv1.md PRPs/PRP-M1.3-User-Profile-Management-Backend.md MR_CHECKLIST.md`
2. **创建提交**: `git commit -m "feat(M1.3B): API文档MVP瘦身 + PRP状态更新 - 受控视图交付完成"`
3. **合并至M1.3分支**: 等待架构师PASS后执行 `2025-09-07` → `M1.3` 合并

---

## ✅ 架构师阻断项修正完成 - 2025-09-07

### 修正项目
1. **前端环境变量违规修正** ✅
   - **问题**: 前端环境变量段包含 `SUPABASE_SERVICE_ROLE_KEY=your-service-role-key`
   - **修正**: 已删除该行，仅保留 `NEXT_PUBLIC_SUPABASE_URL` 和 `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **安全声明**: 保持 "Service role key should never be exposed to frontend" 警告
   
2. **公共名录认证口径统一** ✅
   - **问题**: `v_profiles_public` Description说 "no authentication required"，与 Authentication "Bearer token required" 矛盾
   - **修正**: Description更改为 "authenticated access to public profiles"
   - **一致性**: 所有视图均需 authenticated role 访问

### 架构师质量门验证
- **受控视图合同**: 17个非PII列集、security_barrier=true、单角色过滤、业务函数引用 ✅
- **Helper函数安全**: SECURITY DEFINER + STABLE + 固定search_path ✅
- **环境参数**: 仅占位符，前端无Service Role Key与真实URL/Key ✅
- **认证一致性**: 所有视图均需authenticated role ✅

### Git 节点提示（用户执行）
```bash
# 当前修正已完成，推荐操作：
git add APIdocs/APIv1.md
git commit -m "fix(M1.3B): 修正APIv1.md架构师阻断项 - 前端环境变量与认证口径

- 删除前端环境变量中的SERVICE_ROLE_KEY（违反安全原则）
- 统一v_profiles_public认证要求（需authenticated访问）
- 保持受控视图合同完整性（17非PII字段、security_barrier=true）
- 链接证据: test-evidence/Dev-Step-3-Behavioral-Evidence.md"

# 架构师PASS后合并：2025-09-05 → M1.3
```

---

**状态**: ✅ **阻断项修正完成** | 📋 **等待架构师PASS** | 🚀 **准备前端IRG联调**