# 🚨 URGENT MANUAL PERMISSIONS FIX REQUIRED

## 问题状态
- CLI 连接失败 (Connection refused + SASL auth error)
- 直接 psql 连接失败 (密码认证问题)
- 需要立即手动修复权限配置

## 手动修复步骤

### 步骤1: 访问 Supabase Dashboard SQL Editor
1. 打开 https://supabase.com/dashboard/project/dosbevgbkxrtixemfjfl/sql
2. 登录到项目 Dashboard

### 步骤2: 在 SQL Editor 中执行以下命令

```sql
-- STEP 1: REVOKE ALL EXCESSIVE PERMISSIONS
REVOKE ALL ON public.v_profiles_tcm_context FROM authenticated;
REVOKE ALL ON public.v_profiles_pharmacy_context FROM authenticated; 
REVOKE ALL ON public.v_profiles_public FROM authenticated;

-- STEP 2: GRANT ONLY SELECT PERMISSIONS
GRANT SELECT ON public.v_profiles_tcm_context TO authenticated;
GRANT SELECT ON public.v_profiles_pharmacy_context TO authenticated;
GRANT SELECT ON public.v_profiles_public TO authenticated;
```

### 步骤3: 验证修复结果

```sql
-- 验证权限 - 应该只显示 SELECT 权限
SELECT 'CORRECTED_PERMISSIONS' AS status, 
       table_name, 
       privilege_type, 
       grantee
FROM information_schema.role_table_grants
WHERE table_schema='public'
  AND table_name IN ('v_profiles_tcm_context','v_profiles_pharmacy_context','v_profiles_public')
  AND grantee='authenticated'
ORDER BY table_name, privilege_type;
```

### 步骤4: 预期结果
应该看到 9 行结果，每个视图仅有 SELECT 权限：
```
status               | table_name                  | privilege_type | grantee
CORRECTED_PERMISSIONS | v_profiles_pharmacy_context | SELECT         | authenticated
CORRECTED_PERMISSIONS | v_profiles_public           | SELECT         | authenticated  
CORRECTED_PERMISSIONS | v_profiles_tcm_context      | SELECT         | authenticated
```

## 修复完成后
1. 复制验证查询的输出结果
2. 反馈给后端 Lead 确认
3. 准备前端 IRG 重启测试

**请立即在 Dashboard SQL Editor 中执行上述权限修复！**