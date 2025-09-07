# 联调环境三视图紧急部署指令

**日期**: 2025-09-07  
**目标**: 修复前端IRG测试被"后端视图未部署"阻断的问题  
**架构师指令**: 以联调同一实例为唯一判据，完成"视图存在性 + 安全属性 + 授权"三件套

## 🚨 问题背景

前端IRG测试失败，报告显示联调环境缺少以下三个关键视图：
- ❌ `v_profiles_tcm_context`
- ❌ `v_profiles_pharmacy_context`  
- ❌ `v_profiles_public`

## 📋 部署文件清单

本次创建的部署文件：
1. **`deploy_views_to_integration.sql`** - 完整视图部署脚本
2. **`verify_integration_views.sql`** - 架构师要求的验证查询
3. **`integration_behavioral_test.sql`** - 四用例行为测试
4. **`complete_seed_solution.sql`** - 测试数据种子脚本（已存在）

## 🔧 部署步骤

### 第一步：环境确认
```bash
# 确认目标联调实例URL
echo $NEXT_PUBLIC_SUPABASE_URL
# 应该与前端使用的实例一致
```

### 第二步：执行部署脚本
```bash
# 方式1：使用Supabase CLI
supabase db push

# 方式2：使用psql直连
psql "${DATABASE_URL}" -f deploy_views_to_integration.sql

# 方式3：使用Supabase Dashboard SQL Editor
# 复制deploy_views_to_integration.sql内容到SQL Editor执行
```

### 第三步：种子数据准备（若需要）
```bash
# 检查是否已有测试数据
psql "${DATABASE_URL}" -c "SELECT COUNT(*) FROM user_profiles WHERE id::text LIKE '11111111-%' OR id::text LIKE '33333333-%';"

# 如果无测试数据，执行种子脚本
psql "${DATABASE_URL}" -f test-evidence/complete_seed_solution.sql
```

### 第四步：执行验证和行为测试
```bash
# 执行架构师要求的验证查询
psql "${DATABASE_URL}" -f verify_integration_views.sql > integration_evidence.txt

# 执行四用例行为测试
psql "${DATABASE_URL}" -f integration_behavioral_test.sql >> integration_evidence.txt
```

### 第五步：证据收集
收集的证据文件 `integration_evidence.txt` 应包含：
- ✅ 视图存在性验证
- ✅ 安全屏障配置确认
- ✅ 17个非PII字段列集验证
- ✅ Helper函数安全属性验证
- ✅ 权限授权验证
- ✅ 四用例行为测试结果

## ✅ 预期测试结果

### 架构师质量门验证
- **视图存在**: 3个视图在public schema
- **安全屏障**: `security_barrier=true` 在所有视图
- **列集完整**: 17个非PII字段（pharmacy_context=6, tcm_context=6, public=5）
- **Helper安全**: SECURITY DEFINER + STABLE + 固定search_path
- **权限配置**: authenticated角色有SELECT权限

### 四用例行为测试结果
```
✅ Pharmacy→TCM Positive: COUNT > 0 (预期=2)
✅ Non-existent→TCM Negative: COUNT = 0  
✅ TCM→Pharmacy Positive: COUNT > 0 (预期=2)
✅ Non-existent→Pharmacy Negative: COUNT = 0
✅ Public Directory: COUNT = 2 (仅is_public_profile=true)
```

## 📊 故障排除

### 常见问题1：视图创建失败
```sql
-- 检查base table是否存在
SELECT table_name FROM information_schema.tables WHERE table_name = 'user_profiles';

-- 检查必要字段是否存在
SELECT column_name FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name IN ('pharmacy_type', 'tcm_specialty', 'is_public_profile');
```

### 常见问题2：Helper函数报错
```sql
-- 检查private schema是否存在
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'private';

-- 检查auth.uid()函数可用性
SELECT auth.uid();
```

### 常见问题3：权限问题
```sql
-- 检查authenticated角色权限
SELECT * FROM information_schema.role_table_grants WHERE grantee = 'authenticated' AND table_name LIKE 'v_profiles_%';
```

## 🎯 完成标志

部署成功的标志：
1. **三个视图存在**: `SELECT count(*) FROM pg_views WHERE viewname LIKE 'v_profiles_%';` 返回 3
2. **安全屏障启用**: 所有视图reloptions包含`security_barrier=true`
3. **行为测试通过**: 正例>0, 负例=0, 公共名录=2
4. **前端可访问**: PostgREST API endpoints响应正常

## 📨 通知前端

部署成功后，发出简短通知：
> "联调实例三视图已部署并通过四用例，证据已追加"

前端收到通知后可重新运行IRG测试：
```bash
cd prescription-platform-frontend
NEXT_PUBLIC_USE_REAL_VIEWS=true NEXT_PUBLIC_IRG_VALIDATION=true npx ts-node scripts/irg-test.ts
```

## 📋 Git操作节点

部署验证通过后的Git操作（由用户执行）：
```bash
# 提交部署脚本
git add deploy_views_to_integration.sql verify_integration_views.sql integration_behavioral_test.sql INTEGRATION_DEPLOYMENT_INSTRUCTIONS.md

git commit -m "feat(M1.3B): 联调环境三视图紧急部署

- 创建完整视图部署脚本（含business relationship filtering）
- 添加架构师要求的验证查询集
- 包含四用例行为测试和种子数据支持  
- 修复前端IRG被视图缺失阻断问题
- 证据链: test-evidence/Dev-Step-3-Behavioral-Evidence.md"

# 架构师PASS后合并: 2025-09-05 → M1.3 (严禁触达main)
```

---

**状态**: 📋 **部署脚本已创建** | ⏳ **等待执行部署** | 🎯 **准备证据收集**