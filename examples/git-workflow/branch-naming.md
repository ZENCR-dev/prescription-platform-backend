# Git Branch Naming Standards - v6.0 Date Branch Strategy

Based on CLAUDE.md Lines 475-518 (分支命名规范)

## 分支层级映射

### Layer 1: 主分支
```bash
main                    # 生产主分支
develop                 # 开发集成分支(可选)
```

### Layer 2: TASK分支 (月度周期管理)
```bash
TASK01-2025-01-auth     # 认证系统Phase (2025年1月)
TASK02-2025-01-api      # 处方API Phase (2025年1月)
TASK03-2025-02-ui       # 患者界面Phase (2025年2月)
```

### Layer 3: 日期分支 (自动生成，AI Agent使用)
```bash
2025-01-17-1530-auth-middleware         # 2025年1月17日15:30 认证中间件
2025-01-17-1630-login-validation        # 2025年1月17日16:30 登录验证
2025-01-18-0900-prescription-api        # 2025年1月18日09:00 处方API
```

### 修复分支 (轻量级验证失败时创建)
```bash
2025-01-17-1800-fix-auth-security       # 2025年1月17日18:00 安全修复
2025-01-18-1000-fix-performance         # 2025年1月18日10:00 性能修复
hotfix-2025-01-17-critical-auth         # 紧急修复
```

## 日期分支命名规则

### 格式规范
```yaml
格式: YYYY-MM-DD-HHMM-<task-identifier>
  YYYY-MM-DD: 开发日期
  HHMM: 24小时制时间，避免命名冲突
  task-identifier: 简洁任务标识，kebab-case格式
```

### 自动化规则
```yaml
创建: AI Agent执行3+1步骤时自动生成
命名: 基于开始时间和任务描述自动命名
冲突处理: 时间戳+随机后缀避免冲突
```

### 清理策略
```yaml
自动删除: 合并到TASK分支后24小时自动清理
保护期: 安全相关分支48小时保护期
强制清理: 超过11个分支时清理最旧分支
```

### 医疗合规标识
```yaml
hipaa-: HIPAA合规相关功能
fda-: FDA规范相关功能
security-: 安全敏感功能
示例: 2025-01-17-1530-hipaa-patient-data
```

## 分支控制策略

### 分支数量控制
- **最大活跃分支**: 11个
- **监控触发**: >9个分支时预警
- **自动清理**: =11个分支时清理最旧分支
- **保护策略**: 安全分支延迟清理

### 生命周期管理
```yaml
Layer 3 分支:
  创建: 原子任务开始时
  合并: 3+1步骤完成后合并到TASK分支
  清理: 24小时后自动删除
  
Layer 2 分支:
  创建: Phase开始时
  合并: Phase完成后合并到main
  保留: 30天用于问题追溯
  
Layer 1 分支:
  main: 永久保留
  标签: 发布时自动创建版本标签
```

## 命名示例

### 前端任务分支
```bash
2025-01-17-0900-ui-login-form
2025-01-17-1000-component-prescription-list
2025-01-17-1100-frontend-payment-integration
```

### 后端任务分支
```bash
2025-01-17-1400-api-user-authentication
2025-01-17-1500-backend-prescription-service
2025-01-17-1600-database-migration-users
```

### 架构任务分支
```bash
2025-01-17-1700-arch-supabase-setup
2025-01-17-1800-system-security-design
2025-01-17-1900-integration-payment-flow
```

### 医疗合规分支
```bash
2025-01-17-2000-hipaa-patient-data-encryption
2025-01-17-2100-fda-prescription-validation
2025-01-17-2200-security-audit-logging
```

## 使用指南

### Agent自动命名流程
1. 获取当前时间戳 (YYYY-MM-DD-HHMM)
2. 解析atomic task描述提取关键词
3. 生成kebab-case格式的task-identifier
4. 检查命名冲突，如有冲突添加随机后缀
5. 创建分支并开始3+1步骤执行

### 手动命名最佳实践
1. 使用当前时间避免冲突
2. task-identifier简洁但描述性强
3. 遵循kebab-case命名约定
4. 特殊功能添加适当前缀
5. 确保团队成员理解命名含义

### 分支保护规则
```yaml
安全分支: hipaa-, fda-, security-前缀
保护措施:
  - 强制代码审查 (至少2人)
  - 延长保护期 (48小时)
  - 额外安全扫描和合规验证
紧急响应: 安全问题发现时自动暂停合并
```