# Git质量门控与工作流集成
# Based on INITIAL.md Lines 302-315 (Git工作流规范)

## v6.0三层分支策略集成

### 质量门控触发机制
```yaml
Layer3触发 (原子任务级):
  触发条件: "3+1步骤循环完成 + 基础质量检查通过"
  Git动作: "自动commit到日期分支 → 创建PR到TASK分支 → 自动合并"
  验证内容:
    - "单元测试覆盖率 >80%"
    - "ESLint代码规范检查"
    - "TypeScript类型验证"
    - "功能基础验证"
  执行时间: "<3分钟"
  失败处理: "阻止合并，显示具体错误，人工修复后重试"

Layer2触发 (Phase级):
  触发条件: "Phase内所有原子任务完成"
  Git动作: "自动触发轻量级验证 → 创建PR到main分支"
  验证内容:
    - "集成测试完整性"
    - "API接口兼容性验证"
    - "医疗合规基础检查 (HIPAA/FDA)"
    - "安全漏洞扫描"
    - "性能基准测试"
  执行时间: "<5分钟"
  失败处理: "人工分析问题，创建针对性修复任务"
```

### 分支保护与提交规范
```yaml
提交粒度规范:
  原子任务级: "每完成3+1步骤循环的一个步骤就提交一次"
  Phase级: "Phase完成并通过智能质量门控后"
  Feature级: "整个Feature完成后"

提交信息格式:
  功能提交: "feat(task01-01): implement JWT authentication middleware"
  测试提交: "test(task01-01): add unit tests for JWT validation"
  修复提交: "fix(task01-01): resolve token expiration edge case"
  文档提交: "docs(task01-01): update authentication flow documentation"

医疗合规集成:
  HIPAA检查: "触发层级: Layer 2, Layer 3 (患者数据相关)"
  FDA规范: "触发层级: Layer 2 (处方相关功能)"
  安全审计: "高风险分支标识: hipaa-, fda-, security-前缀"
```

### 自动化流程
```yaml
CI/CD Pipeline集成:
  日期分支: "Layer 3基础验证流水线 (<3分钟)"
  TASK分支: "Layer 2 Phase验证流水线 (<5分钟)"
  Main分支: "Layer 1 Feature验证 + 生产部署流水线"

分支数量控制:
  监控触发: "当活跃分支 >9个时触发预警"
  自动清理: "当活跃分支 =11个时自动清理最旧分支"
  保护策略: "安全相关分支 (hipaa-, fda-, security-) 延迟清理"
```

## 医疗平台特殊工作流

### 合规检查集成
```yaml
HIPAA合规失败:
  - "立即暂停所有相关分支合并"
  - "触发安全团队告警"  
  - "要求强制安全审查后才能继续"

FDA规范失败:
  - "阻止处方相关功能发布"
  - "要求医疗专家审查"
  - "必须通过合规验证才能继续"
```

### 紧急响应机制
```yaml
安全事件响应:
  - "自动创建hotfix分支"
  - "绕过常规审查流程"
  - "直接部署到生产环境"
  - "事后完整审计和文档更新"

合规问题处理:
  - "即时停止相关功能部署"
  - "启动合规专家review"
  - "生成合规问题报告"
  - "制定系统性修复计划"
```