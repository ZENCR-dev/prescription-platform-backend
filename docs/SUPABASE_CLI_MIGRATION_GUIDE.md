# Supabase CLI Modern Migration Guide (v2.39.2+)

## 概述

本文档详细说明从旧版 Supabase CLI 工作流程迁移到 v2.39.2+ 现代化开发流程的完整指南。

## 🚨 重大变更摘要

### 已移除的命令 (v2.39.2+)

```bash
# ❌ 已移除命令 - 不再可用
supabase db psql                    # 命令已删除
supabase db shell                   # 命令已删除
supabase db connect                 # 命令已删除

# ✅ 新标准替代方案
psql postgresql://postgres:postgres@localhost:54322/postgres
psql postgresql://postgres:postgres@localhost:54322/postgres -f script.sql
psql postgresql://postgres:postgres@localhost:54322/postgres -c "SELECT * FROM users;"
```

### 新增的必要依赖

```bash
# v2.39.2+ 要求独立安装 PostgreSQL 客户端工具
brew install libpq

# 必须手动配置 PATH
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 验证安装
psql --version
```

## 📋 命令对照表

### 数据库连接操作

| 旧版命令 (已移除) | 新版替代方案 | 说明 |
|-----------------|-------------|------|
| `supabase db psql` | `psql postgresql://postgres:postgres@localhost:54322/postgres` | 需要独立安装 libpq |
| `supabase db psql < script.sql` | `psql postgresql://postgres:postgres@localhost:54322/postgres -f script.sql` | 文件执行方式 |
| `supabase db shell` | `psql postgresql://postgres:postgres@localhost:54322/postgres` | 交互式连接 |

### 环境管理操作

| 操作类型 | 旧版方式 | 新版标准 | 改进点 |
|---------|---------|---------|--------|
| 启动本地环境 | `supabase start` | `supabase start` | ✅ 无变化 |
| 重置数据库 | `supabase db reset` | `supabase db reset` | ✅ 无变化 |
| 检查服务状态 | `supabase status` | `supabase status` | ✅ 无变化 |
| 停止服务 | `supabase stop` | `supabase stop` | ✅ 无变化 |

### 开发工作流操作

| 功能 | 旧版流程 | 新版流程 | 主要差异 |
|-----|---------|---------|---------|
| 模式变更检查 | `supabase db diff` | `supabase db diff` | ✅ 无变化 |
| 迁移管理 | `supabase migration new <name>` | `supabase migration new <name>` | ✅ 无变化 |
| 类型生成 | `supabase gen types typescript` | `supabase gen types typescript --local` | 🔄 建议加 --local 标志 |

## 🔧 迁移步骤指南

### 1. 环境准备 (必须执行)

```bash
# Step 1: 安装 PostgreSQL 客户端工具
brew install libpq

# Step 2: 配置 PATH 环境变量
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Step 3: 验证安装成功
psql --version
# 期望输出: psql (PostgreSQL) 14.x
```

### 2. 更新开发脚本

#### 测试脚本更新示例

```bash
# 旧版测试脚本 (package.json)
{
  "scripts": {
    "test:db": "supabase db psql < tests/test-suite.sql"    # ❌ 不再工作
  }
}

# 新版测试脚本
{
  "scripts": {
    "test:db": "psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/test-suite.sql"
  }
}
```

#### RLS 测试脚本更新

```bash
# 旧版 RLS 测试
#!/bin/bash
supabase db psql < tests/rls/test-pharmacy-rls.sql         # ❌ 已失效

# 新版 RLS 测试
#!/bin/bash
psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/rls/test-pharmacy-rls.sql
```

### 3. IDE 集成更新

#### VS Code 任务配置

```json
// 旧版 .vscode/tasks.json (不再工作)
{
    "label": "Run DB Test",
    "type": "shell",
    "command": "supabase db psql < ${file}"     // ❌ 命令已移除
}

// 新版 .vscode/tasks.json
{
    "label": "Run DB Test", 
    "type": "shell",
    "command": "psql postgresql://postgres:postgres@localhost:54322/postgres -f ${file}"
}
```

### 4. Docker 使用说明更新

```yaml
# Docker 在新版 Supabase 中的角色定义
Docker_Usage_Clarification:
  ✅ Legitimate_Usage:
    - "Docker Desktop 必须运行作为 supabase start 的基础设施"
    - "supabase start 使用 Docker 容器提供本地开发栈"
    - "完全由 Supabase CLI 管理，开发者无需直接操作 Docker"
    
  ❌ Invalid_Usage:
    - "不得手动创建或管理 Docker 容器"
    - "不得绕过 supabase start 直接使用 Docker"
    - "生产环境不使用 Docker，仅限本地开发"
```

## 🛠️ 故障排除指南

### 常见迁移问题

#### 问题 1: psql 命令未找到

```bash
# 错误信息
bash: psql: command not found

# 解决方案
brew install libpq
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 验证修复
psql --version
```

#### 问题 2: 连接被拒绝

```bash
# 错误信息
psql: error: connection to server at "localhost" (127.0.0.1), port 54322 failed: Connection refused

# 解决方案 1: 检查 Supabase 服务状态
supabase status

# 解决方案 2: 重启 Supabase 服务
supabase stop
supabase start

# 解决方案 3: 检查 Docker 状态
docker ps
```

#### 问题 3: 迁移文件执行失败

```bash
# 错误信息
psql: error: script.sql: No such file or directory

# 解决方案: 使用绝对路径或确认文件位置
pwd
ls -la tests/rls/test-pharmacy-rls.sql
psql postgresql://postgres:postgres@localhost:54322/postgres -f ./tests/rls/test-pharmacy-rls.sql
```

#### 问题 4: Docker 端口冲突

```bash
# 错误信息
Error: Port 54322 is already in use

# 解决方案
# 检查端口占用
lsof -i :54322

# 强制重启 Supabase
supabase stop
supabase start
```

### 环境验证清单

```bash
# 完整环境验证脚本
#!/bin/bash

echo "🔍 验证 Supabase CLI 迁移环境..."

# 1. Docker 检查
echo "1. Docker 状态检查"
docker --version || echo "❌ Docker 未安装或未运行"
docker ps > /dev/null 2>&1 && echo "✅ Docker 运行正常" || echo "❌ Docker 服务异常"

# 2. Supabase CLI 检查
echo "2. Supabase CLI 版本检查"
SUPABASE_VERSION=$(supabase --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
if [[ "$SUPABASE_VERSION" > "2.39.2" ]] || [[ "$SUPABASE_VERSION" == "2.39.2" ]]; then
    echo "✅ Supabase CLI v$SUPABASE_VERSION (支持现代命令)"
else
    echo "❌ Supabase CLI 版本过低: v$SUPABASE_VERSION (需要 ≥2.39.2)"
fi

# 3. PostgreSQL 客户端检查
echo "3. PostgreSQL 客户端检查"
psql --version > /dev/null 2>&1 && echo "✅ psql 客户端可用" || echo "❌ psql 客户端未安装"

# 4. Supabase 服务检查
echo "4. Supabase 本地服务检查"
supabase status > /dev/null 2>&1 && echo "✅ Supabase 服务运行中" || echo "⚠️ Supabase 服务未启动"

# 5. 数据库连接检查
echo "5. 数据库连接测试"
psql postgresql://postgres:postgres@localhost:54322/postgres -c "SELECT 1;" > /dev/null 2>&1 && echo "✅ 数据库连接成功" || echo "❌ 数据库连接失败"

echo "✨ 环境验证完成"
```

## 📚 新版最佳实践

### 1. 开发工作流标准化

```bash
# 标准开发启动流程
supabase start                    # 启动本地环境
supabase status                   # 验证服务状态
supabase db reset                 # 重置并应用迁移

# 开发过程中的常用操作
supabase db diff                  # 检查模式变更
supabase db lint                  # 验证 SQL 语法
supabase gen types typescript --local > types/database.types.ts
```

### 2. 测试执行标准

```bash
# RLS 测试执行
psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/rls/test-pharmacy-rls.sql

# 迁移测试
psql postgresql://postgres:postgres@localhost:54322/postgres -f supabase/migrations/20240101000000_initial_schema.sql

# 交互式调试
psql postgresql://postgres:postgres@localhost:54322/postgres
```

### 3. 脚本自动化建议

```bash
# 创建便捷脚本 (scripts/db-connect.sh)
#!/bin/bash
psql postgresql://postgres:postgres@localhost:54322/postgres "$@"

# 使用示例
./scripts/db-connect.sh -f tests/test-file.sql
./scripts/db-connect.sh -c "SELECT * FROM users LIMIT 5;"
```

## 🚀 迁移后的优势

### 1. 更好的控制和透明度
- 直接使用标准 PostgreSQL 工具
- 更灵活的连接字符串配置
- 更好的脚本集成能力

### 2. 标准化的数据库操作
- 与 PostgreSQL 生态系统完全兼容
- 更容易与 CI/CD 集成
- 支持更多高级 psql 功能

### 3. 简化的依赖管理
- 清晰的依赖关系 (libpq)
- 独立的工具链管理
- 更好的版本控制

## 📖 参考链接

- [Supabase CLI v2.39.2 发布说明](https://github.com/supabase/cli/releases)
- [PostgreSQL libpq 文档](https://www.postgresql.org/docs/current/libpq.html)
- [Supabase 本地开发指南](https://supabase.com/docs/guides/cli/local-development)

---

**文档状态**: ✅ **完整迁移指南** | 🔄 **适用版本**: v2.39.2+ | 📋 **涵盖范围**: 命令迁移+故障排除+最佳实践