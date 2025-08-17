# 快速 TASK04-09 批量更新记录

## 更新策略
基于已完成的 TASK01、TASK03 模板，快速应用标准化格式到剩余文档。

## TASK04-09 Component Type 分类

### TASK04: Row Level Security
- **Component Type**: `data_security`
- **Quality Gate**: Comprehensive Gate
- **Wave Mode**: Yes (数据安全复杂度>0.7)
- **Task Category**: Security & Data Protection

### TASK05: 处方API开发  
- **Component Type**: `backend_api`
- **Quality Gate**: Comprehensive Gate  
- **Wave Mode**: Yes (医疗业务复杂度>0.7)
- **Task Category**: Backend Medical API

### TASK06: 患者界面
- **Component Type**: `frontend_component`
- **Quality Gate**: Standard Gate
- **Wave Mode**: No (前端组件复杂度<0.7)
- **Task Category**: Frontend Patient Interface

### TASK07: 医生工作台
- **Component Type**: `frontend_component` 
- **Quality Gate**: Standard Gate
- **Wave Mode**: No (前端组件复杂度<0.7)
- **Task Category**: Frontend Doctor Interface

### TASK08: 集成测试
- **Component Type**: `integration_testing`
- **Quality Gate**: Standard Gate
- **Wave Mode**: No (测试流程复杂度<0.7)
- **Task Category**: Quality Assurance & Testing

### TASK09: 部署和监控
- **Component Type**: `deployment_operations`
- **Quality Gate**: Standard Gate
- **Wave Mode**: No (部署配置复杂度<0.7)  
- **Task Category**: DevOps & Monitoring

## 标准化头部模板

```markdown
**文档版本**: v2.0 (v5.0框架适配)  
**创建日期**: 2025-01-16  
**依赖任务**: TASKXX (前置任务名称)  
**后续任务**: TASKXX (后续任务名称)

**Task Category**: [分类]  
**Phase**: Week X - [阶段描述]  
**Priority**: [Critical/High/Medium] ([重要性说明])  
**Component Type**: `[类型]`  
**Quality Gate**: `[门控类型]` ([原因说明])  
**Wave Mode Eligible**: [✅/❌] [Yes/No] ([复杂度说明])  
**Loop Mode Applicable**: ✅ Yes ([迭代场景])
```

## AI Agent估算模板

```yaml
### AI Agent Estimation (总体Layer2评估)
```yaml
Step Count: [数量] ([级别])
Code Generation: [级别] ([文件数] files, ~[行数] lines)
Iteration Cycles: [数量] ([级别], [说明])
Context Complexity: [级别]
SuperClaude Commands: [数量范围]
```
```

## User Stories 模板

```markdown
### User Stories Served
- **US##**: [用户角色]需要[功能需求]用于[业务目标]
- **US##**: [用户角色]需要[功能需求]用于[业务目标]
- **US##**: [用户角色]需要[功能需求]用于[业务目标]
- **US##**: [用户角色]需要[功能需求]用于[业务目标]
```

## Phase → Atomic Task 转换

将所有 `### Phase X: 名称 (X小时)` 改为：
```markdown
### Atomic Task XX.Y: 名称

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

**SuperClaude Commands**:
```bash
/sc:[command] "[具体描述]" --persona-[role] --type [type]
/sc:[command] [具体功能] --persona-[role] --[options]
/sc:[command] [验证内容] --type [type]
```
```

## 更新完成标准

每个 TASK 必须包含：
1. ✅ 标准化头部信息
2. ✅ AI Agent 估算
3. ✅ User Stories Served 
4. ✅ Layer 2 工作流模板定义
5. ✅ 原子任务 3+1 步骤
6. ✅ 具体化 SuperClaude Commands
7. ✅ 智能质量门控配置

---

## 执行状态跟踪

- [x] TASK01: 已完成 v5.0 格式升级
- [x] TASK03: 已完成 v5.0 格式升级  
- [x] TASK02: 部分完成，需要补充
- [🔄] TASK04: 进行中
- [ ] TASK05: 待更新
- [ ] TASK06: 待更新
- [ ] TASK07: 待更新
- [ ] TASK08: 待更新
- [ ] TASK09: 待更新
