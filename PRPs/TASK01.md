# TASK01: Supabase Starter Kit集成和认证验证

**文档版本**: v3.0 (v6.0框架适配)  
**创建日期**: 2025-01-16  
**依赖任务**: TASK00 (文档体系升级)  
**后续任务**: TASK02 (API日志系统)

**Task Category**: Frontend & Backend Infrastructure  
**Phase**: Week 1 - Foundation Setup  
**Priority**: Critical (项目基础设施)

## 🚨 开发前置要求检查

**⚠️ 重要提醒**: 执行TASK01之前，必须完成以下准备工作。所有标记为"必需"的项目都必须配置完成，否则开发将无法进行。

### 📋 必需账户准备

**👤 用户手动填写区域 - 请完成以下信息后才开始开发**:

```
🔹 GitHub Account Information:
   Username: ZENCR-dev
   Email: info@zencr.org
   SSH Key: [已配置] ☐ [未配置] ☐
   
🔹 Supabase Account Information:  
   Email: info@zencr.org
   Dashboard Access: [已验证] ☐ [未验证] ☐ 
   URL: https://supabase.com/dashboard
   
🔹 Vercel Account Information:
   Email: [请输入Vercel账户邮箱] 
   GitHub Integration: [已关联] ☐ [未关联] ☐
   URL: https://vercel.com/dashboard
   
🔹 本地开发环境:
   Node.js Version: [请输入版本号，如 v18.17.0]
   Package Manager: [npm] ☐ [yarn] ☐ [pnpm] ☐
   Operating System: [macOS] ☐ [Windows] ☐ [Linux] ☐
```

**验收标准**:
- [ ] **GitHub Account**: 代码仓库管理，已创建并验证
- [ ] **Supabase Account**: 已注册并能够访问Dashboard  
- [ ] **Vercel Account**: 已注册并关联GitHub账户
- [ ] **开发工具**: Node.js 18+, npm/yarn/pnpm 已安装并验证版本

### 🔧 开发工具CLI准备

**⚙️ 用户手动验证区域 - 请执行并记录结果**:

```
🔹 CLI工具安装验证:

1. Supabase CLI安装:
   命令: npm install -g supabase@latest
   版本验证: supabase --version
   结果: [请输入显示的版本号，如 1.100.x]
   状态: [已安装] ☐ [未安装] ☐

2. Vercel CLI安装:  
   命令: npm install -g vercel@latest
   版本验证: vercel --version
   结果: [请输入显示的版本号，如 32.x.x]
   状态: [已安装] ☐ [未安装] ☐

3. Git配置验证:
   用户名: git config user.name
   结果: [请输入显示的用户名]
   邮箱: git config user.email  
   结果: [请输入显示的邮箱]
   SSH密钥: [已添加到GitHub] ☐ [未添加] ☐
```

**验收标准**:
- [ ] **Supabase CLI**: `npm install -g supabase@latest` + `supabase --version` 验证
- [ ] **Vercel CLI**: `npm install -g vercel@latest` + `vercel --version` 验证
- [ ] **Git配置**: 用户名和邮箱已配置，SSH密钥已添加到GitHub

### 🌐 本地开发端口确认
根据INITIAL.md规范，确认以下端口可用：
- [ ] **前端端口**: `localhost:3000-3009` 范围内至少一个端口可用
- [ ] **Supabase本地端口**: `54321-54323` 端口未被占用
- [ ] **后端服务端口**: `localhost:4000` 可用 (未来TASK使用)

### ⚡ 执行前自检清单

**🔍 开始TASK01前必须验证**:
```bash
# 1. 验证Node.js版本
node --version  # 应显示 >= 18.0.0

# 2. 验证包管理器
npm --version   # 或 yarn --version

# 3. 验证Git配置
git config user.name && git config user.email

# 4. 验证CLI工具
supabase --version
vercel --version

# 5. 检查端口可用性
lsof -i :3000 :3001 :54321 :54322 :54323  # 应显示无进程占用
```

**⚠️ 如有任何项目未完成，请先完成准备工作再开始开发**

## 📋 阶段目标

**总体目标**: 基于Supabase官方starter kit快速启动项目，验证认证功能正常工作，确保用户注册/登录记录能在Supabase数据库中查看，为后续业务开发奠定稳固基础。

### User Stories Served
- **US01**: 开发者需要快速启动项目以验证Supabase集成可行性
- **US02**: 系统管理员需要项目基础设施配置用于后续开发
- **US03**: 测试用户需要基础认证功能验证注册登录流程
- **US04**: 部署管理员需要生产环境配置模板和验证流程

## 🤖 AI Agent估算 (v6.0简化版)

```yaml
步骤数量: 9步
代码文件: 5个文件
迭代轮次: 2轮
复杂度: 中
```

**验收标准**:
- [ ] Supabase项目创建和API密钥配置
- [ ] 使用官方starter kit创建Next.js项目
- [ ] 用户能够成功注册和登录
- [ ] 在Supabase Dashboard中能看到用户记录
- [ ] 认证状态在前端正确显示
- [ ] 项目部署到Vercel成功

---

## 📋 原子任务分解 (3+1步骤模式)

### 统一3+1工作流模板

**所有原子任务通用步骤**:
```yaml
步骤1 - 需求分析与设计 (主实现角色):
  - 分析任务需求和技术方案
  - 设计实现路径和基础架构
  - 识别依赖关系和风险
  - 确定验证标准和成功指标

步骤2 - 实现与自测 (同一主实现角色):
  - 完成功能实现
  - 编写基础单元测试
  - 执行代码格式化和基础检查
  - 满足基础质量要求

步骤3 - 集成准备 (同一主实现角色):
  - 验证接口兼容性
  - 准备集成文档
  - 确保代码符合项目规范
  - 准备Phase验证所需材料

步骤4 - 质量验证与提交 (qa persona):
  - 执行基础质量检查
  - 运行测试验证
  - 验证功能完整性
  - 提交代码并更新状态
```

---

## 🎯 最小单位任务列表

### 原子任务 01.1: Supabase项目配置

**AI Agent估算**:
```yaml
步骤数量: 4步
代码文件: 2个文件
迭代轮次: 1轮
复杂度: 低
```

**SuperClaude命令**: `/sc:implement --persona-backend --type infrastructure`

**3+1执行步骤** (TDD标准流程):
1. **测试设计阶段【TDD红灯】** (backend persona)
   - 编写Supabase连接、API密钥验证、项目配置失败测试用例

2. **最小实现阶段【TDD绿灯】** (backend) 
   - 实现最小代码使连接和配置测试通过

3. **重构优化阶段【TDD重构】** (backend)
   - 优化配置结构，提升代码可读性，保持测试绿色

4. **验证提交阶段【质量门控】** (qa)
   - 运行完整测试套件，验证配置完整性，提交到日期分支

**SuperClaude Commands**:
```bash
/sc:design "Supabase project setup" --persona-backend --type infrastructure
/sc:implement supabase-configuration --persona-backend --safe-mode
/sc:test project-connectivity --type validation
```

**⚡ Phase A执行前验证**:
- [ ] Supabase账户已登录，能够访问Dashboard
- [ ] 确认项目名称和区域选择（推荐：Asia Pacific - Singapore）
- [ ] 准备记录项目URL和API密钥的安全位置

**📋 Phase A用户记录区域 - 请在执行过程中填写**:
```
🔹 Supabase项目创建记录:

项目基本信息:
- 项目名称: [请输入，如 prescription-platform-backend]
- 组织: [请输入，如 personal/company-name]
- 区域: [请输入，推荐 Asia Pacific (ap-singapore-1)]
- 数据库密码: [请输入并安全保存]

项目URLs和密钥:
- 项目URL: [从Settings > API获取]
  格式: https://[project-id].supabase.co
- API匿名密钥: [从Settings > API获取]
  格式: eyJhbGciOiJIUzI1NiIsInR5cCI6...
- Service Role密钥: [从Settings > API获取，TASK02需要]
  格式: eyJhbGciOiJIUzI1NiIsInR5cCI6...

配置验证:
- [ ] 项目创建成功，可访问Dashboard
- [ ] Auth服务已启用
- [ ] Database可以访问
- [ ] Site URL配置为 http://localhost:3000
```

- **A1**: 在Supabase Dashboard创建新项目
- **A2**: 获取项目URL和匿名密钥
- **A3**: 验证数据库连接和Auth服务可用性  
- **A4**: 配置项目安全设置和域名

### 原子任务 01.2: Starter Kit项目创建

**AI Agent估算**:
```yaml
步骤数量: 6步
代码文件: 4个文件
迭代轮次: 2轮
复杂度: 中
```

**3+1执行步骤** (TDD标准流程):
1. **测试设计阶段【TDD红灯】** (frontend persona)
   - 编写Next.js启动、Supabase集成、认证组件加载失败测试用例

2. **最小实现阶段【TDD绿灯】** (frontend)
   - 实现最小代码使项目启动和认证组件测试通过

3. **重构优化阶段【TDD重构】** (frontend)
   - 优化组件结构和路由配置，保持测试绿色

4. **验证提交阶段【质量门控】** (qa)
   - 运行完整测试套件，验证项目功能完整性，提交到日期分支

**SuperClaude Commands**:
```bash
/sc:implement "Next.js starter kit" --persona-frontend --type project-creation
/sc:integrate supabase-auth --persona-frontend --with-ui
/sc:test starter-kit-functionality --type component
```

**⚡ Phase B执行前验证**:
- [ ] Phase A已完成，Supabase项目URL和匿名密钥已获取
- [ ] GitHub仓库已创建并准备就绪
- [ ] 本地开发目录已选择，端口3000-3009可用
- [ ] 准备创建.env.local文件并配置环境变量

**📋 Phase B用户记录区域 - 请在执行过程中填写**:
```
🔹 项目创建和配置记录:

GitHub仓库信息:
- 仓库名称: prescription-platform-backend
- 仓库URL: https://github.com/ZENCR-dev/prescription-platform-backend
- 本地克隆路径: ~/Users/renjie/dev/prescription-platform-backend
- 默认分支: main

Next.js项目配置:
- 创建命令使用: [请输入使用的命令]
  选项: npx create-next-app --example with-supabase [项目名]
- 项目目录: ~/Users/renjie/dev/prescription-platform-frontend
- 开发端口: [请输入使用的端口，3000-3009范围内]
- 包管理器: [npm] ☐ [yarn] ☐ [pnpm] ☐

环境变量配置:
- [ ] .env.local文件已创建
- [ ] NEXT_PUBLIC_SUPABASE_URL已配置
- [ ] NEXT_PUBLIC_SUPABASE_ANON_KEY已配置  
- [ ] 项目启动成功，可访问认证页面
- 本地访问URL: http://localhost:[端口号]
```

- **B1**: 使用官方starter kit创建Next.js项目
- **B2**: 配置环境变量连接Supabase项目
- **B3**: 验证starter kit的认证UI正常显示
- **B4**: 测试项目启动和基础功能

### Atomic Task 01.3: 认证功能测试

**AI Agent Estimation**:
```yaml
Step Count: 4 (Simple)
Code Generation: Light (1-2 files, ~100 lines)
Iteration Cycles: 2 (Straightforward)
Context Complexity: Integrated
SuperClaude Commands: 2-3
```

**3+1执行步骤** (TDD标准流程):
1. **测试设计阶段【TDD红灯】** (qa)
   - 编写用户注册、登录、会话管理失败测试用例

2. **最小实现阶段【TDD绿灯】** (qa)
   - 执行最小测试使认证流程测试通过

3. **重构优化阶段【TDD重构】** (qa)
   - 优化测试用例结构，增强可读性，保持测试绿色

4. **验证提交阶段【质量门控】** (qa)
   - 运行完整测试套件，确认认证功能完整性，提交到日期分支

**SuperClaude Commands**:
```bash
/sc:test "authentication flow" --persona-qa --type end-to-end
/sc:validate user-registration --persona-security --comprehensive
/sc:verify dashboard-integration --type data-sync
```
- **C1**: 测试用户注册功能
- **C2**: 测试用户登录功能
- **C3**: 验证用户会话状态管理
- **C4**: 确认用户数据在Supabase Dashboard中可见

### Atomic Task 01.4: 部署和验证

**AI Agent Estimation**:
```yaml
Step Count: 4 (Simple)
Code Generation: Light (1-2 files, ~50 lines)
Iteration Cycles: 2 (Straightforward)
Context Complexity: Integrated
SuperClaude Commands: 2-3
```

**3+1执行步骤** (TDD标准流程):
1. **测试设计阶段【TDD红灯】** (backend)
   - 编写Vercel部署、环境变量、生产访问失败测试用例

2. **最小实现阶段【TDD绿灯】** (backend)
   - 实现最小部署配置使部署测试通过

3. **重构优化阶段【TDD重构】** (backend)
   - 优化部署配置和环境管理，保持测试绿色

4. **验证提交阶段【质量门控】** (qa)
   - 运行完整测试套件，验证生产部署功能，提交到日期分支

**SuperClaude Commands**:
```bash
/sc:deploy "Vercel production" --persona-backend --type deployment
/sc:configure environment-variables --persona-backend --secure
/sc:validate production-deployment --type smoke-test
```

**⚡ Phase D执行前验证**:
- [ ] Phase B-C已完成，本地认证功能正常工作
- [ ] Vercel账户已登录，关联GitHub账户
- [ ] 项目代码已推送到GitHub仓库
- [ ] 生产环境变量已准备（与本地.env.local相同内容）

**📋 Phase D用户记录区域 - 请在执行过程中填写**:
```
🔹 部署配置和验证记录:

Vercel部署信息:
- Vercel项目名称: [请输入Vercel中的项目名称]
- 关联的GitHub仓库: [确认关联正确的仓库]
- 部署分支: [通常为 main]
- 构建命令: [通常为 npm run build]
- 输出目录: [通常为 .next]

生产环境URLs:
- 生产环境URL: [请输入Vercel生成的URL]
  格式: https://[project-name]-[hash].vercel.app
- 自定义域名 (如有): [请输入自定义域名]

环境变量配置 (生产环境):
- [ ] NEXT_PUBLIC_SUPABASE_URL已在Vercel中配置
- [ ] NEXT_PUBLIC_SUPABASE_ANON_KEY已在Vercel中配置
- [ ] Supabase Site URL已更新包含生产URL

功能验证记录:
- [ ] 生产环境可以正常访问
- [ ] 用户注册功能正常
- [ ] 用户登录功能正常  
- [ ] 数据可以在Supabase Dashboard中查看
- 测试用户邮箱: [请输入用于测试的邮箱]
- 验证时间: [请输入验证完成时间]
```

- **D1**: 部署项目到Vercel
- **D2**: 配置生产环境变量
- **D3**: 测试生产环境认证功能
- **D4**: 验证整体功能完整性

## 🔧 实施要点

### 关键技术决策
- **项目架构**: Next.js 14 + Supabase Auth + TypeScript
- **认证方案**: Supabase官方starter kit + 邮箱验证
- **部署平台**: Vercel + Supabase云服务
- **开发环境**: 本地开发 + 生产验证

### 依赖和前置条件

**⚠️ 硬性要求** (必须完成才能开始开发):
- **工具要求**: Node.js 18+, npm/yarn/pnpm, Git 已配置
- **账户准备**: GitHub、Supabase、Vercel账户已创建并验证  
- **CLI工具**: supabase-cli, vercel-cli 已安装
- **网络要求**: 能够访问Supabase、Vercel、GitHub服务
- **端口要求**: localhost:3000-3009、54321-54323端口可用

**📝 用户环境变量配置区域 - Phase A完成后填写**:

```env
# =====================================================
# 🔹 用户手动填写区域 (.env.local文件内容)
# =====================================================

# Supabase配置 (请在Phase A完成后填写)
NEXT_PUBLIC_SUPABASE_URL=https://dosbevgbkxrtixemfjfl.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvc2Jldmdia3hydGl4ZW1mamZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMDcwMjEsImV4cCI6MjA2OTc4MzAyMX0.xDbE8E8Fg84109qRQi9SFbi4PPUtCTBL1-Jj2R80lmI

# 项目信息记录
PROJECT_NAME=prescription-platform
SUPABASE_PROJECT_ID=dosbevgbkxrtixemfjfl
CREATED_DATE=2025-08-01

# 部署信息 (Phase D完成后填写)  
VERCEL_PROJECT_URL=[请填写Vercel部署后的生产URL]
VERCEL_PROJECT_NAME=[请填写Vercel项目名称]

# 可选配置 (后续TASK使用，暂时保持注释)
# STRIPE_PUBLISHABLE_KEY=pk_test_[YOUR_STRIPE_PUBLISHABLE_KEY_HERE]
# STRIPE_SECRET_KEY=sk_test_[YOUR_STRIPE_SECRET_KEY_HERE]
# STRIPE_WEBHOOK_SECRET=whsec_xxx (TASK06需要)

# =====================================================
# 配置完成确认 (请勾选)
# =====================================================
# [ ] Supabase配置已填写
# [ ] 项目信息已记录
# [ ] .env.local文件已创建并配置
# [ ] 环境变量已在Vercel中配置 (生产环境)
```

**环境变量安全提醒**:
⚠️ 确保.env.local在.gitignore中，绝不提交到Git仓库
⚠️ 生产环境变量在Vercel Dashboard中单独配置

### 实施要点
- **项目创建**: 使用Supabase官方with-supabase模板
- **环境配置**: 正确配置.env.local文件
- **认证验证**: 完整的注册/登录流程测试
- **部署验证**: 生产环境认证功能正常

## ✅ 完成检查清单

**🚨 最终验证**: 所有检查项必须完成并验证通过，才能标记TASK01为完成状态

### 🔍 Supabase项目验证
- [ ] **项目创建**: Supabase项目创建成功，获得项目URL和API密钥并已记录
- [ ] **数据库连接**: 能够访问项目数据库，Auth服务已启用
- [ ] **域名配置**: 项目域名设置正确，CORS配置允许localhost:3000-3009
- [ ] **安全设置**: RLS启用，匿名注册配置符合需求

### 🗄️ Starter Kit集成验证
- [ ] **项目创建**: 使用官方starter kit成功创建项目
- [ ] **依赖安装**: 所有依赖包安装成功，无版本冲突
- [ ] **环境变量**: .env.local配置正确，连接Supabase项目成功
- [ ] **开发服务器**: 项目启动正常，认证页面正确显示

### 🔒 认证功能验证
- [ ] **用户注册**: 新用户能够成功注册账户
- [ ] **用户登录**: 现有用户能够成功登录
- [ ] **会话管理**: 用户会话状态在页面刷新后保持
- [ ] **数据库记录**: 用户信息在Supabase Dashboard中可见

### 🧪 部署和生产验证
- [ ] **本地构建**: Next.js本地构建成功，无构建错误
- [ ] **Vercel部署**: 项目成功部署到Vercel，获得生产URL
- [ ] **生产认证**: 生产环境认证功能正常工作  
- [ ] **性能检查**: 页面加载速度符合预期 (<3秒)
- [ ] **环境一致性**: 本地和生产环境功能一致

### 🔐 环境变量安全确认
- [ ] **密钥安全**: API密钥未提交到Git仓库
- [ ] **环境配置**: .env.local在.gitignore中，Vercel环境变量已配置  
- [ ] **访问验证**: 生产环境可以正常访问，认证流程无异常

## 🔄 进度追踪和问题解决

### Phase A-D执行记录
```markdown
## Phase A: Supabase项目配置
- [ ] A1: 在dashboard.supabase.com创建新项目
- [ ] A2: 获取项目URL和匿名密钥
- [ ] A3: 验证数据库连接和Auth服务
- [ ] A4: 配置项目域名和CORS设置
**Target Duration**: 2小时

## Phase B: Starter Kit项目创建  
- [ ] B1: 使用with-supabase模板创建项目
- [ ] B2: 配置.env.local环境变量
- [ ] B3: 验证项目启动和认证UI
- [ ] B4: 测试基础功能运行正常
**Target Duration**: 2小时

## Phase C: 认证功能测试
- [ ] C1: 测试用户注册流程
- [ ] C2: 测试用户登录流程
- [ ] C3: 验证会话状态管理
- [ ] C4: 确认Supabase Dashboard中的用户记录
**Target Duration**: 1小时

## Phase D: 部署和验证
- [ ] D1: 部署到Vercel平台
- [ ] D2: 配置生产环境变量
- [ ] D3: 测试生产环境认证
- [ ] D4: 验证整体功能完整性
**Target Duration**: 1小时
```

### 风险和缓解

- **连接风险**: Supabase项目连接失败 → 验证API密钥和URL配置
- **认证风险**: 用户注册登录异常 → 检查Auth设置和Site URL配置
- **部署风险**: Vercel部署失败 → 验证环境变量和构建过程
- **兼容风险**: 版本冲突问题 → 使用推荐的Node.js和依赖版本

## 🚪 智能质量门控配置

### Component Type Analysis
```yaml
Component Type: project_initialization

Risk Assessment:
  Security Sensitivity: Medium (认证系统基础)
  Performance Criticality: Medium (项目基础性能)
  User Impact: High (影响整个项目启动)
  Complexity Score: 0.5 (中等复杂度配置任务)

Selected Gate Type: Standard Gate
```

### Smart Quality Gate Standards
```yaml
Standard Gate检查项:
  ✓ 项目配置完整性检查 (Supabase项目和API密钥)
  ✓ 认证功能集成测试 (用户注册登录流程)
  ✓ 部署配置验证 (Vercel生产环境)
  ✓ 安全配置检查 (CORS、环境变量)
  ✓ 性能基准测试 (页面加载和响应时间)
  ✓ 文档完整性验证 (项目配置记录)
```

### Dynamic Fix Todos机制
**如果质量门控失败，自动生成以下Fix Todos**:
```yaml
Fix Todo Templates:
  - "修复Supabase API连接配置错误 (检查URL和密钥)"
  - "解决认证流程失败问题 (用户注册/登录异常)"
  - "修复Vercel部署配置错误 (环境变量或构建问题)"
  - "优化页面加载性能超过3秒问题"
  - "完善项目配置文档缺失信息"
```

## 📊 成功指标

### 功能指标
- **认证成功率**: >99%用户注册登录成功
- **部署成功**: 生产环境认证功能正常
- **数据可见性**: Supabase Dashboard中用户记录完整

### 性能指标
- **页面加载**: 认证页面加载时间<3秒
- **响应时间**: 认证操作响应时间<2秒
- **用户体验**: 注册/登录流程<30秒完成

---

**🔄 前端同步点A**: 开发环境统一配置完成
- **环境一致性**: 前后端Supabase项目配置统一
- **认证集成**: 前端认证组件和后端Auth服务对接
- **部署验证**: 前后端生产环境部署和验证

**前置条件**: 无 | **后续任务**: TASK02 API日志系统

---

**🎯 TASK01完成标识**: 
- ✅ Supabase starter kit集成完成
- ✅ 用户认证功能验证通过，能够在数据库中查看注册/登录记录  
- ✅ 项目成功部署到Vercel生产环境，功能完整
- ✅ 所有环境变量安全配置，密钥未泄露
- ✅ 本地和生产环境一致性验证通过

**🔄 后续准备**: 具备开始TASK02 API日志系统实施的完整条件，.env.local文件已配置并可供后续TASK使用。

---

## 🚨 重要提醒

**开始执行前必读**:
1. **完成所有前置要求检查** - 所有账户、CLI工具、环境变量必须准备就绪
2. **逐Phase验证** - 每个Phase开始前必须完成对应的"执行前验证"检查
3. **安全第一** - 确保API密钥等敏感信息不会提交到Git仓库
4. **问题及时反馈** - 遇到问题立即查看"风险和缓解"部分或寻求帮助

**⚠️ 如任何前置条件未满足，请不要开始执行开发任务**

---

## 📝 用户输入完成确认

**🔍 执行前最终检查 - 请确认所有手动输入区域已完成**:

- [ ] **账户信息区域** - GitHub、Supabase、Vercel账户信息已填写
- [ ] **CLI工具验证区域** - 所有工具安装和版本已确认
- [ ] **环境变量配置区域** - .env.local模板已准备，等待Phase A完成后填写
- [ ] **Phase A记录区域** - 准备记录Supabase项目创建信息
- [ ] **Phase B记录区域** - 准备记录GitHub和Next.js项目配置
- [ ] **Phase D记录区域** - 准备记录Vercel部署和生产环境信息

**✅ 所有准备工作完成后，方可开始执行Phase A任务**

---

**🎯 用户配置模板总结**:
```
总共需要用户手动填写的区域: 6个
├── 开发前置准备区域: 3个 (账户、CLI、环境变量)  
├── Phase执行记录区域: 3个 (Phase A、B、D)
└── 最终确认检查: 1个 (执行前检查清单)

预计填写时间: 初次设置约30-60分钟
建议: 准备一个文档记录所有配置信息，便于后续参考
```