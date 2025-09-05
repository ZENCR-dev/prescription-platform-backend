# 系统性问题监控清单 - Systemic Issues Monitoring

**状态**: 监控级别，非交付阻塞  
**性质**: 基础设施债务管理  
**影响范围**: 不影响Task 1.2成功或Task 1.3开始，属于增量质量改进范畴

## 🔍 已识别基础设施债务

### 问题1: 迁移时间戳顺序问题

**现状描述**:
```
20250104_extend_user_profiles_business_fields.sql (尝试ALTER table)
  ↓ 执行顺序先于  
20250822041103_create_user_profiles_table.sql (CREATE table)
  ↓ 导致结果
supabase db reset --local 失败 (table does not exist)
```

**根本原因**: 迁移文件时间戳不反映依赖关系，导致执行顺序错误

**影响评估**:
- ✅ **生产环境**: 无影响 (渐进部署，依赖关系已解决)
- ❌ **本地开发**: `supabase db reset --local` 流程失败
- ❌ **新环境部署**: 从零开始的环境部署失败
- ⚠️ **CI/CD流程**: 可能影响测试环境重建

**监控策略**:
- 跟踪本地开发者报告的reset失败次数
- 监控CI/CD环境重建成功率
- 记录新开发者环境配置阻塞时间

### 问题2: 性能测试数据缺失

**现状描述**:
```sql  
-- 性能测试查询 (from custom test suite)
EXPLAIN ANALYZE SELECT * FROM public.orders WHERE assigned_pharmacy_id = '<uuid>' LIMIT 10;
  ↓ 预期结果
Execution Time: X.XXX ms (with meaningful data)
  ↓ 实际结果  
No matching data OR table not fully initialized
```

**根本原因**: 测试环境缺乏足够的种子数据用于性能基准测试

**影响评估**:
- ⚠️ **性能基准**: 无法建立性能baseline和回归检测
- ⚠️ **性能优化**: 缺乏数据支持的优化决策
- ✅ **功能测试**: 不影响功能验证和交付
- ✅ **业务逻辑**: 不影响核心业务逻辑正确性

**监控策略**:
- 跟踪性能测试套件执行结果
- 监控数据量增长和性能基准建立进度
- 记录性能优化需求和数据支撑缺口

### 问题3: RLS覆盖度缺口

**现状描述**:
```
RLS策略预期覆盖: user_profiles, orders, fulfillment_credentials, po_settlements, inventory_tracking
实际RLS状态: 部分表策略缺失或未完全生效
测试结果: RLS合规检查显示"部分项缺失"
```

**根本原因**: 
- 迁移顺序问题影响RLS策略应用
- 前置对象(表、函数)不存在导致策略创建失败
- RLS策略依赖关系复杂，部分环节缺失

**影响评估**:
- 🔒 **安全合规**: 数据访问控制可能不完整
- ⚠️ **审计要求**: 可能影响医疗平台合规审计
- ✅ **基础功能**: 不影响基础CRUD功能
- 🎯 **Task 1.3**: 为Task 1.3 RLS实施提供改进机会

**监控策略**:
- 定期运行RLS覆盖度检查脚本
- 跟踪各表RLS策略应用状态
- 监控安全审计和合规检查结果

## 📊 CI"Bootstrap/Compat策略"选项清单

### 选项A: 不改历史迁移 (保守方案)

**方案1: 本地Reset顺序映射**
```bash
# 创建本地开发bootstrap脚本
# scripts/dev-bootstrap.sh
#!/bin/bash
echo "=== 本地开发环境Bootstrap ==="

# 1. 手动处理依赖顺序
supabase db reset --local --no-migrations
supabase migration repair 20250822041103  # 先创建表
supabase migration repair 20250104        # 再修改表  
supabase migration repair --all           # 应用其他迁移

echo "✅ 本地环境Bootstrap完成"
```

**方案2: 最小Bootstrap迁移**
```sql
-- 创建 20240101_bootstrap_base_tables.sql
-- 仅包含最基础的表创建，解决依赖关系
CREATE TABLE IF NOT EXISTS user_profiles (...基础结构...);
-- 后续迁移可以安全地ALTER这个表
```

**优势**: 
- ✅ 不破坏生产部署历史
- ✅ 保持迁移记录完整性  
- ✅ 风险最小化

**劣势**:
- ⚠️ 需要维护特殊的本地开发脚本
- ⚠️ 新开发者需要额外培训

### 选项B: 改历史迁移 (积极方案)

**限制范围**: 仅在可控范围内重命名dev-only迁移

**方案**: 重新组织迁移时间戳
```
20240101_create_base_tables.sql        (新建，包含基础表)
20250104_extend_user_profiles_business_fields.sql -> 20250105_...
20250822041103_create_user_profiles_table.sql     (删除，合并到base)
```

**执行策略**:
1. 仅在开发环境执行重组  
2. 生产环境保持现有迁移历史
3. 通过配置区分开发/生产迁移策略

**优势**:
- ✅ 彻底解决依赖关系问题
- ✅ 简化本地开发流程

**劣势**: 
- ⚠️ 可能影响生产部署一致性
- ⚠️ 需要仔细管理环境差异

### 推荐方案: 选项A-方案1

基于风险评估，推荐使用**本地Reset顺序映射**方案：
- 最小风险，不影响生产
- 可控的本地开发复杂性
- 为后续重构保留选项

## 🎯 监控执行计划

### 短期监控 (1-4 weeks)

**监控指标**:
```yaml
migration_order_issues:
  metric: "local_reset_failure_count"  
  target: "< 5 failures/week"
  action: "执行bootstrap脚本优化"

performance_data_gaps:
  metric: "performance_test_coverage"
  target: "> 60% test cases with data"
  action: "补充种子数据"

rls_coverage_gaps:
  metric: "rls_policy_coverage"
  target: "> 80% table coverage"  
  action: "纳入Task 1.3/后续RLS实施"
```

### 长期改进 (2-6 months)

**改进计划**:
1. **Q1**: 建立性能数据集和基准测试
2. **Q2**: 完善RLS策略覆盖度  
3. **Q3**: 评估迁移重构的投入产出比
4. **Q4**: 实施选择的长期解决方案

### 监控报告频率

**周报**: 基础指标监控，异常事件记录  
**月报**: 趋势分析，改进进度评估  
**季报**: 债务影响评估，解决方案ROI分析

## 🔄 与主要任务的关系

### Task 1.2/1.3 非阻塞确认

**Task 1.2**: 
- ✅ Task 1.2 migration自身无依赖问题
- ✅ Task 1.2成功不受这些问题影响

**Task 1.3**:  
- ✅ RLS实施可以独立进行
- 💡 RLS覆盖度改进可在Task 1.3中一并解决

### 并行改进机会

**Task 1.3A RLS实施时机**:
- 可以一并修复现有RLS覆盖度缺口
- 统一RLS策略实施质量标准
- 建立完整的RLS测试和验证框架

**API治理修复协调**:
- 与API治理修复并行进行
- 共享质量改进的最佳实践
- 协调资源分配避免冲突

---
**监控状态**: 🔄 **监控体系建立完成** - 持续跟踪，增量改进，不阻塞主线任务交付