# TASK01-09批量更新指导 (v5.0框架)

## 📋 更新模式总结

基于已完成的TASK01和TASK03示例，以下是标准化的v5.0框架更新模式：

### 1. 文档头部标准化

**每个TASK文档开头添加**：
```markdown
**文档版本**: v2.0 (v5.0框架适配)  
**创建日期**: 2025-01-16  
**依赖任务**: TASKXX (前置任务)  
**后续任务**: TASKXX (后续任务)

**Component Type**: `[component_type]`  
**Quality Gate**: `[gate_type]`  
**Wave Mode Eligible**: ✅/❌ [Yes/No] ([复杂度说明])  
**Loop Mode Applicable**: ✅/❌ [Yes/No] ([迭代场景说明])
```

### 2. Component Type分类规则

```yaml
项目配置类: project_initialization (TASK01)
监控系统类: backend_monitoring (TASK02)  
认证系统类: auth_system (TASK03) - Comprehensive Gate
数据模型类: data_model (TASK04)
API服务类: backend_api (TASK05)
前端组件类: frontend_component (TASK06-07)
集成测试类: integration_testing (TASK08)
部署运维类: deployment_operations (TASK09)
```

### 3. Quality Gate选择规则

```yaml
Minimal Gate: utils, helpers, constants (风险评分<0.4)
Standard Gate: 大部分常规功能 (风险评分0.4-0.7)
Comprehensive Gate: auth_system, payment_flow, data_migration (风险评分>0.7)
```

### 4. AI Agent估算模板

**在"阶段目标"下添加**：
```yaml
### AI Agent Estimation (总体Layer2评估)
```yaml
Step Count: [数量] ([Simple/Moderate/Complex])
Code Generation: [Light/Medium/Heavy] ([文件数] files, ~[行数] lines)
Iteration Cycles: [数量] ([Straightforward/Standard/Complex])
Context Complexity: [Isolated/Integrated/Systemic]
SuperClaude Commands: [数量范围]
```
```

### 5. Phase → Atomic Task转换

**将所有Phase改为Atomic Task格式**：
```markdown
### Atomic Task XX.Y: [任务名称]

**AI Agent Estimation**:
```yaml
Step Count: [数量] ([级别])
Code Generation: [级别] ([文件数] files, ~[行数] lines)
Iteration Cycles: [数量] ([级别])
Context Complexity: [级别]
SuperClaude Commands: [数量范围]
```

**3+1执行步骤**:
1. **需求分析与设计** ([persona])
   - [具体分析设计任务]

2. **实现与自测** ([persona])
   - [具体实现和测试任务]

3. **集成准备** ([persona])
   - [具体集成准备任务]

4. **质量验证与提交** (qa)
   - [具体验证和提交任务]

**SuperClaude Command**: `/sc:[command] --persona-[role] --[options]`
```

### 6. 智能质量门控配置

**在文档末尾添加**：
```markdown
## 🚪 智能质量门控配置

### Component Type Analysis
```yaml
Component Type: [type]

Risk Assessment:
  Security Sensitivity: [Low/Medium/High] ([说明])
  Performance Criticality: [Low/Medium/High] ([说明])
  User Impact: [Low/Medium/High] ([说明])
  Complexity Score: [0.0-1.0] ([说明])

Selected Gate Type: [Minimal/Standard/Comprehensive] Gate
```

### Smart Quality Gate Standards
```yaml
[Gate]检查项:
  ✓ [检查项1] ([具体说明])
  ✓ [检查项2] ([具体说明])
  ✓ [检查项3] ([具体说明])
  ✓ [检查项4] ([具体说明])
  ✓ [检查项5] ([具体说明])
  ✓ [检查项6] ([具体说明])
```

### Dynamic Fix Todos机制
**如果质量门控失败，自动生成以下Fix Todos**:
```yaml
Fix Todo Templates:
  - "[具体修复模板1] ([检查说明])"
  - "[具体修复模板2] ([检查说明])"
  - "[具体修复模板3] ([检查说明])"
  - "[具体修复模板4] ([检查说明])"
  - "[具体修复模板5] ([检查说明])"
```
```

## 🎯 剩余TASK更新清单

### ✅ 已完成
- [x] TASK01: Supabase Starter Kit集成 (project_initialization, Standard Gate)
- [x] TASK03: Auth集成和角色管理 (auth_system, Comprehensive Gate)

### ⏳ 待更新
- [ ] TASK02: API日志系统 (backend_monitoring, Standard Gate)
- [ ] TASK04: 医疗数据模型 (data_model, Standard Gate)
- [ ] TASK05: 处方API开发 (backend_api, Comprehensive Gate)
- [ ] TASK06: 患者界面开发 (frontend_component, Standard Gate)
- [ ] TASK07: 医生工作台 (frontend_component, Standard Gate)
- [ ] TASK08: 集成测试 (integration_testing, Standard Gate)
- [ ] TASK09: 部署和监控 (deployment_operations, Standard Gate)

### 🔄 Wave模式候选

**建议启用Wave模式的TASK**：
- TASK03: 认证系统 (已完成Wave配置)
- TASK05: 处方API (医疗业务复杂度>0.7)
- TASK04: 医疗数据模型 (数据模型复杂度>0.7)

**Wave模式配置模板**：
```yaml
### 🌊 Wave模式应用场景
```yaml
[任务类型]复杂度评分:
  工作流复杂度: [0.0-1.0] ([说明])
  [特定维度]: [0.0-1.0] ([说明])
  技术复杂度: [0.0-1.0] ([说明])
  [合规/质量要求]: [0.0-1.0] ([说明])
  
总体复杂度: [计算结果] [>/<=] 0.7 [✅/❌] Wave模式[建议启用/不需要]
```
```

## 📊 更新进度跟踪

### 更新统计
- **总任务数**: 9个TASK文档
- **已更新**: 2个 (TASK01, TASK03)
- **进行中**: 1个 (TASK02)
- **待更新**: 6个 (TASK04-09)
- **完成率**: 22%

### 预期工作量
```yaml
剩余更新工作量:
  Step Count: 18 (Complex)
  Code Generation: Heavy (7 files, ~1400 lines)
  Iteration Cycles: 3 (Standard)
  Context Complexity: Systemic
  预计时间: 3-4小时 (批量操作)
```

## 🚀 快速执行建议

1. **并行更新策略**: 可以同时更新多个TASK文档
2. **模板复用**: 使用TASK01/TASK03作为参考模板
3. **重点任务优先**: 先更新TASK04-05（数据模型和处方API）
4. **批量验证**: 更新完成后统一进行格式一致性检查

---

**使用说明**: 参考此指导完成TASK02-09的v5.0框架升级，确保100%符合新的标准化要求。
