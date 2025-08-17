# TASK05: 处方创建和管理系统实施

**文档版本**: v2.0 (v5.0框架适配)  
**创建日期**: 2025-01-16  
**依赖任务**: TASK04 (RLS策略实施)  
**后续任务**: TASK06 (支付集成与Edge Functions)

**Task Category**: Business Logic Implementation  
**Phase**: Week 3 - Core Business Features  
**Priority**: Critical (核心业务逻辑)  
**Component Type**: `prescription_workflow`  
**Quality Gate**: `Comprehensive Gate` (医疗业务高风险)  
**Wave Mode Eligible**: ✅ Yes (处方工作流复杂度>0.7)  
**Loop Mode Applicable**: ✅ Yes (业务逻辑迭代优化)

## 📋 阶段目标

实施完整的处方创建和管理系统，包括医师端处方创建界面、处方状态管理、药品选择和计算引擎、实时数据同步

### User Stories Served
- **US21**: 医师需要处方创建系统管理患者药物治疗方案
- **US22**: 药房需要处方订单系统接收和处理处方请求
- **US23**: 系统需要财务计算引擎确保价格准确性
- **US24**: 患者需要处方状态跟踪了解履约进度

### AI Agent Estimation (总体Layer2评估)
```yaml
Step Count: 18 (Complex)
Code Generation: Heavy (8-12 files, ~1200 lines)
Iteration Cycles: 4 (Complex, 业务逻辑复杂)
Context Complexity: Systemic
SuperClaude Commands: 15-18
```

**验收标准**:
- [ ] 处方创建表单完整实现，支持多药品添加和计算
- [ ] 处方状态机正确实施，状态转换逻辑验证通过
- [ ] 财务计算引擎集成，NZD cents精度保证
- [ ] 实时数据同步，处方状态更新即时反馈
- [ ] 权限控制生效，医师仅能管理自有处方
- [ ] 用户界面响应式设计，移动端适配完成

---

## 🔧 Layer 2工作流模板定义

### Component Template: Prescription Workflow
```yaml
Template Type: prescription_workflow_template
Standard Steps:
  1. 数据模型和API设计实现
  2. 业务逻辑和状态机实现
  3. 用户界面和交互实现
  4. 集成测试和性能优化

Quality Gate: Comprehensive Gate (医疗业务高风险)
  - 数据安全合规性检查 ✓
  - 业务逻辑正确性验证 ✓
  - 财务计算精度测试 ✓
  - 医疗工作流合规检查 ✓
  - 性能和可用性测试 ✓
  - 集成测试全覆盖 ✓

AI Agent Commands:
  - /sc:design --persona-backend --type prescription-workflow
  - /sc:implement --persona-backend --type business-logic
  - /sc:test --persona-qa --type comprehensive
  - /sc:validate --persona-security --type medical-compliance
```

### Template Customization for Medical Platform
```yaml
Inherited from: prescription_workflow_template
Custom Steps Added:
  - 医疗数据隐私保护和匿名化处理
  - HIPAA合规性验证和审计日志
  - 处方状态机和医疗工作流验证
  - 财务计算引擎NZD精度验证

Quality Gate Adjustments:
  - 强化检查: 医疗数据隐私保护
  - 新增检查: 处方工作流合规性验证
  - 升级检查: 财务计算精度和审计
```

---

## 🎯 最小单位任务列表

### Atomic Task 05.1: 处方数据模型和API设计

**AI Agent Estimation**:
```yaml
Step Count: 6 (Moderate)
Code Generation: Medium (4-6 files, ~400 lines)
Iteration Cycles: 2 (Standard)
Context Complexity: Integrated
SuperClaude Commands: 5-6
```

**3+1执行步骤**:
1. **需求分析与设计** (backend)
   - 分析处方数据模型需求，设计API接口契约

2. **实现与自测** (backend)
   - 实现处方Zod模式、TypeScript类型和API路由

3. **集成准备** (backend)
   - 配置数据库关联，准备状态机集成

4. **质量验证与提交** (qa)
   - 验证API接口完整性，测试数据模型

**SuperClaude Commands**:
```bash
/sc:design "prescription data model" --persona-backend --type business-logic
/sc:implement prescription-api --persona-backend --with-validation
/sc:test api-contracts --type integration
```

### Atomic Task 05.2: 药品管理和选择器

**AI Agent Estimation**:
```yaml
Step Count: 5 (Simple-Moderate)
Code Generation: Medium (3-5 files, ~350 lines)
Iteration Cycles: 2 (Standard)
Context Complexity: Integrated
SuperClaude Commands: 4-5
```

**3+1执行步骤**:
1. **需求分析与设计** (backend)
   - 分析药品管理需求，设计搜索和选择器接口

2. **实现与自测** (backend)
   - 实现药品API查询、搜索功能和价格计算

3. **集成准备** (backend)
   - 配置药品选择器集成，准备前端组件对接

4. **质量验证与提交** (qa)
   - 验证药品查询性能，测试选择器功能

**SuperClaude Commands**:
```bash
/sc:implement medicine-management --persona-backend --type data-access
/sc:integrate price-calculation --persona-backend --with-validation
/sc:test medicine-selector --type component
```

### Atomic Task 05.3: 处方创建界面

**AI Agent Estimation**:
```yaml
Step Count: 6 (Moderate)
Code Generation: Medium (4-6 files, ~450 lines)
Iteration Cycles: 3 (Standard, UI迭代)
Context Complexity: Integrated
SuperClaude Commands: 6-7
```

**3+1执行步骤**:
1. **需求分析与设计** (frontend)
   - 分析处方创建UI需求，设计表单交互流程

2. **实现与自测** (frontend)
   - 实现处方创建页面、多药品表单和实时计算

3. **集成准备** (frontend)
   - 配置表单验证，准备API集成和状态管理

4. **质量验证与提交** (qa)
   - 验证UI交互完整性，测试表单验证逻辑

**SuperClaude Commands**:
```bash
/sc:design prescription-ui --persona-frontend --type interface
/sc:implement prescription-form --persona-frontend --with-validation
/sc:test form-interactions --type user-experience
```

### Atomic Task 05.4: 处方管理功能

**AI Agent Estimation**:
```yaml
Step Count: 5 (Simple-Moderate)
Code Generation: Medium (3-5 files, ~300 lines)
Iteration Cycles: 2 (Standard)
Context Complexity: Integrated
SuperClaude Commands: 4-5
```

**3+1执行步骤**:
1. **需求分析与设计** (backend)
   - 分析处方管理需求，设计状态机和权限控制

2. **实现与自测** (backend)
   - 实现处方列表、状态更新和权限验证

3. **集成准备** (backend)
   - 配置实时同步，准备通知和审计集成

4. **质量验证与提交** (qa)
   - 验证权限控制，测试状态机逻辑

**SuperClaude Commands**:
```bash
/sc:implement prescription-management --persona-backend --type business-logic
/sc:validate permissions --persona-security --comprehensive
/sc:test state-machine --type workflow
```
**前后端对齐节点**: 处方列表管理和详情查看
**SuperClaude工具建议**: `/implement --persona-frontend --persona-backend --seq`

- **D1**: 处方列表页面，支持分页和筛选
- **D2**: 处方详情查看和编辑功能
- **D3**: 处方状态实时同步和通知
- **D4**: 处方删除和草稿管理

## 🚪 智能质量门控配置

### Component Type Analysis
```yaml
Component Type: prescription_workflow

Risk Assessment:
  Security Sensitivity: High (医疗数据处理)
  Performance Criticality: High (核心业务功能)
  User Impact: Critical (医师和药房核心工作流)
  Complexity Score: 0.8 (复杂业务逻辑和状态机)

Selected Gate Type: Comprehensive Gate
```

### Smart Quality Gate Standards
```yaml
Comprehensive Gate检查项:
  ✓ 医疗数据隐私保护验证 (处方数据匿名化)
  ✓ 业务逻辑正确性测试 (处方状态机验证)
  ✓ 财务计算精度验证 (NZD cents精度)
  ✓ 集成测试全覆盖 (API和UI端到端)
  ✓ 性能基准测试 (处方创建响应时间<2秒)
  ✓ 安全合规检查 (RLS策略和权限控制)
  ✓ 医疗工作流合规验证 (处方流程符合标准)
```

### Dynamic Fix Todos机制
**如果质量门控失败，自动生成以下Fix Todos**:
```yaml
Fix Todo Templates:
  - "修复处方数据隐私泄露问题 (检测到PII信息暴露)"
  - "优化财务计算精度错误 (NZD cents计算偏差)"
  - "解决处方状态机逻辑错误 (状态转换验证失败)"
  - "修复权限控制漏洞 (医师数据访问越权)"
  - "优化处方创建性能问题 (响应时间超过2秒)"
  - "完善医疗工作流合规性 (缺少必要验证步骤)"
```

---

## ✅ 完成检查清单

### 数据模型验证
- [ ] 处方数据结构设计，字段定义完整准确
- [ ] TypeScript类型定义，与数据库Schema一致
- [ ] Zod验证模式，数据验证规则完整
- [ ] 状态机设计，状态转换逻辑正确

### API功能验证
- [ ] 处方创建API，数据验证和存储正确
- [ ] 处方查询API，权限控制和数据过滤
- [ ] 药品搜索API，查询性能和结果准确
- [ ] 计算引擎API，价格计算精度验证

### 用户界面验证
- [ ] 处方创建表单，用户体验流畅直观
- [ ] 药品选择器，搜索和选择功能完整
- [ ] 实时价格计算，计算结果准确显示
- [ ] 响应式设计，移动端适配良好

### 系统集成验证
- [ ] 处方状态同步，实时更新正确
- [ ] 权限控制测试，数据访问安全
- [ ] 性能测试，页面响应速度满足要求
- [ ] 异常处理，错误提示和恢复机制

## 🔧 实施要点

### 关键技术决策
- **数据架构**: PostgreSQL + Zod验证 + TypeScript类型安全
- **状态管理**: 处方状态机 + 实时同步 + 乐观更新
- **计算引擎**: NZD cents精度 + Decimal.js计算 + 缓存优化
- **用户体验**: 响应式设计 + 实时反馈 + 错误处理

### 依赖和前置条件
- **前置任务**: TASK04必须完成(RLS权限控制)
- **技术依赖**: Supabase实时订阅、财务计算引擎
- **API文档**: 参考 APIdocs/APIv1.md 处方管理章节
- **数据契约**: 处方数据结构、状态枚举、计算精度要求

### 风险和缓解
- **复杂度风险**: 多药品处方管理复杂 → 渐进开发 + 充分测试
- **计算风险**: 价格计算精度问题 → 专用计算引擎 + 精度验证
- **性能风险**: 实时计算影响响应 → 缓存策略 + 异步处理
- **用户体验风险**: 表单复杂度高 → 用户测试 + 界面优化

## 📊 成功指标

### 功能指标
- **处方创建成功率**: >99%处方提交成功
- **计算准确性**: 100%价格计算准确，无精度误差
- **状态同步及时性**: 状态更新延迟<3秒

### 性能指标
- **页面加载速度**: 处方页面加载<2秒
- **计算响应时间**: 价格计算响应<500ms
- **实时同步延迟**: 状态同步延迟<5秒

### 用户体验指标
- **操作流畅度**: 用户完成处方创建<5分钟
- **错误率**: 用户操作错误率<5%
- **满意度**: 医师用户满意度>4.0/5

---

**🔄 前端同步点D**: 处方数据接口确认和实时状态同步
- **数据契约**: 处方数据结构、状态枚举、药品信息格式
- **接口规范**: 参考 APIdocs/APIv1.md 处方管理章节
- **实时订阅**: 处方状态变更、计算结果更新的WebSocket推送
- **用户体验**: 表单交互、状态显示、错误处理的统一设计

**前置条件**: TASK04完成(RLS策略) | **后续任务**: TASK06支付集成系统

---

**📋 技术实现说明**: 具体的Edge Function代码、React组件实现、状态管理逻辑等技术实例已移至 `examples/task05/` 目录供开发时参考，本文档专注于任务分解和执行指导。