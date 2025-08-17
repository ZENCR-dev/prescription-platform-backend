# Git Commit Message Standards

Based on CLAUDE.md Lines 522-579 (提交粒度规范)

## 三层提交粒度标准

### Layer 3 (原子任务) 提交标准

#### 提交特征
```yaml
提交类型: 功能性提交
提交频率: 每完成3+1步骤循环的一个步骤就提交一次
提交内容要求:
  - 包含完整的功能实现
  - 通过基础质量检查 (linting, 单测, 类型检查)
  - 包含必要的测试用例
  - 更新相关文档
```

#### 提交信息格式
```bash
feat(task01-01): implement JWT authentication middleware
test(task01-01): add unit tests for JWT validation
fix(task01-01): resolve token expiration edge case
docs(task01-01): update authentication flow documentation
```

#### 原子任务提交示例
```bash
# Step 1: 需求分析与设计完成
feat(task05-02): design prescription API data model
docs(task05-02): add API specification for prescription endpoints

# Step 2: 实现与自测完成
feat(task05-02): implement prescription CRUD operations
test(task05-02): add unit tests for prescription service
fix(task05-02): handle validation errors in prescription creation

# Step 3: 集成准备完成
feat(task05-02): integrate prescription API with database
test(task05-02): add integration tests for prescription flow
docs(task05-02): update API documentation with examples

# Step 4: 质量验证与提交完成
test(task05-02): add comprehensive test coverage
fix(task05-02): resolve code review feedback
chore(task05-02): finalize prescription API implementation
```

### Layer 2 (Phase) 提交标准

#### 提交特征
```yaml
提交类型: 里程碑提交
提交频率: Phase完成并通过智能质量门控后
提交内容要求:
  - 集成多个原子任务的功能
  - 通过智能质量门控验证
  - 更新API文档 (如适用)
  - 包含集成测试结果
```

#### 提交信息格式
```bash
feat(TASK01): complete authentication system implementation
- JWT middleware with refresh token support
- Role-based access control (RBAC)
- Password policy enforcement
- Audit logging for security events
- 通过轻量级验证，安全检查得分96%

BREAKING CHANGE: Updated user session structure
```

#### Phase级提交示例
```bash
feat(TASK01): complete authentication system Phase
- Implement Supabase Auth integration
- Add JWT middleware with refresh tokens
- Create role-based access control (RBAC)
- Add password policy enforcement
- Implement audit logging for security events
- Add comprehensive test coverage (95%)
- Update API documentation with auth endpoints

Tests: All authentication tests passing
Security: HIPAA compliance verification complete
Performance: P95 response time < 150ms
```

### Layer 1 (Feature) 提交标准

#### 提交特征
```yaml
提交类型: 发布提交
提交频率: 整个Feature完成后
提交内容要求:
  - 完整的生产就绪功能
  - 通过完整的Feature级验证
  - 更新版本号和变更日志
  - 包含部署指南
```

#### 提交信息格式
```bash
release: v1.2.0 - Prescription Management System
- Complete prescription workflow (TASK01-TASK03)
- HIPAA compliant patient data handling
- Integration with pharmacy systems
- Advanced security and audit features
- Performance optimized for >10k concurrent users

Includes: TASK01 (Auth), TASK02 (Prescription API), TASK03 (Patient UI)
```

## 提交类型规范

### 标准提交类型
```yaml
feat: 新功能实现
fix: 问题修复
docs: 文档更新
style: 代码格式化
refactor: 重构（不改变功能）
test: 测试相关
chore: 构建过程或辅助工具的变动
perf: 性能优化
ci: CI配置文件和脚本的更改
build: 影响构建系统或外部依赖的更改
```

### 医疗平台特殊类型
```yaml
security: 安全相关修改
compliance: 合规性相关修改
hipaa: HIPAA合规相关修改
fda: FDA规范相关修改
audit: 审计日志相关修改
```

## 提交信息最佳实践

### 标题行规范
```bash
# 格式: type(scope): description
# 限制: 不超过50个字符
# 语法: 动词原形开头，首字母小写，结尾不加句号

✅ Good examples:
feat(auth): implement JWT middleware
fix(prescription): resolve validation error
docs(api): update authentication endpoints

❌ Bad examples:
Added JWT middleware functionality
Fixed a bug
Updated documentation
```

### 消息体规范
```bash
# 72字符换行
# 解释"什么"和"为什么"，而不是"怎样"
# 包含相关的issue引用

Example:
feat(prescription): implement medicine interaction checking

Add validation to prevent dangerous medicine combinations
when creating prescriptions. This ensures patient safety
and compliance with FDA guidelines.

- Add interaction database lookup
- Implement warning system for conflicts
- Add audit logging for safety decisions

Closes #123
Refs #124, #125
```

### 医疗平台提交示例

#### 安全敏感功能
```bash
security(auth): implement HIPAA compliant session management

- Add encrypted session storage
- Implement automatic session timeout
- Add audit logging for authentication events
- Ensure zero patient data in session tokens

HIPAA Compliance: Verified data protection measures
Security Review: Passed penetration testing
```

#### 处方相关功能
```bash
feat(prescription): implement FDA compliant prescription validation

- Add drug interaction checking
- Implement dosage validation rules
- Add prescription format validation
- Ensure audit trail for all prescriptions

FDA Compliance: Follows 21 CFR Part 11 requirements
Medical Review: Approved by clinical team
```

#### 合规检查
```bash
compliance(system): update data retention policies

- Implement HIPAA required data retention (6 years)
- Add automated data purging for expired records
- Update privacy policy and user notifications
- Add compliance reporting dashboard

Legal Review: Approved by legal team
Compliance Score: 98% HIPAA compliance achieved
```

## 分支合并策略

### 原子任务合并
```bash
# 创建PR: feature/YYYY-MM-DD-HHMM-task → TASK-branch
git checkout TASK01-auth-system
git merge 2025-01-17-1530-jwt-middleware --no-ff
git commit -m "feat(TASK01): integrate JWT middleware atomic task

- Completed 3+1 step cycle for JWT implementation
- All tests passing with 95% coverage
- Security review completed
- Ready for Phase integration

Atomic Task: 2025-01-17-1530-jwt-middleware
Quality Gates: All passed
Security Check: HIPAA compliant"
```

### Phase级合并
```bash
# 创建PR: TASK-branch → main
git checkout main
git merge TASK01-auth-system --no-ff
git commit -m "feat(TASK01): complete authentication system Phase

Comprehensive authentication system with:
- Supabase Auth integration
- JWT middleware with refresh tokens
- Role-based access control (RBAC)
- HIPAA compliant audit logging
- Complete test coverage

Phase Validation: All checks passed
Security Audit: 96% compliance score
Performance: P95 < 150ms
API Documentation: Updated and validated"
```

## 提交Hook和验证

### Pre-commit验证
```bash
# 自动运行的检查
- ESLint and Prettier formatting
- TypeScript type checking
- Unit test execution
- Commit message format validation
```

### Pre-push验证
```bash
# 推送前检查
- All tests must pass
- Coverage thresholds met
- No security vulnerabilities
- Medical compliance checks (if applicable)
```

### 提交模板
```bash
# .gitmessage template
# type(scope): description (max 50 chars)
#
# Longer explanation of the change (wrap at 72 chars)
# * Bullet points are okay
# 
# Medical Platform Considerations:
# - HIPAA compliance: [Y/N]
# - FDA requirements: [Y/N] 
# - Security review: [Y/N]
#
# Closes #issue-number
```