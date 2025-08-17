# TASK01: Supabase Starter Kit集成和认证验证

## 📋 阶段目标

基于Supabase官方starter kit快速启动项目，验证认证功能正常工作，确保用户注册/登录记录能在Supabase数据库中查看，为后续业务开发奠定稳固基础。

**验收标准**:
- [ ] Supabase项目创建和API密钥配置
- [ ] 使用官方starter kit创建Next.js项目
- [ ] 用户能够成功注册和登录
- [ ] 在Supabase Dashboard中能看到用户记录
- [ ] 认证状态在前端正确显示
- [ ] 项目部署到Vercel成功

## 🎯 最小单位任务列表

### Phase A: Supabase项目配置 (2小时) 🔄
**前后端对齐节点**: 数据库和认证服务就绪
**SuperClaude工具建议**: `/sc:implement --persona-backend --seq --c7` (项目配置和Supabase文档查询)
- **A1**: 在Supabase Dashboard创建新项目
- **A2**: 获取项目URL和匿名密钥
- **A3**: 验证数据库连接和Auth服务可用性
- **A4**: 配置项目安全设置和域名

### Phase B: Starter Kit项目创建 (2小时) 🔄  
**前后端对齐节点**: 前端项目结构和认证集成建立
**SuperClaude工具建议**: `/sc:build --persona-backend --c7` (项目构建和Next.js文档参考)
- **B1**: 使用官方starter kit创建Next.js项目
- **B2**: 配置环境变量连接Supabase项目
- **B3**: 验证starter kit的认证UI正常显示
- **B4**: 测试项目启动和基础功能

### Phase C: 认证功能测试 (1小时) 🔄
**前后端对齐节点**: 用户认证流程验证
**SuperClaude工具建议**: `/sc:test --persona-security --seq --play` (认证测试和用户流程验证)
- **C1**: 测试用户注册功能
- **C2**: 测试用户登录功能
- **C3**: 验证用户会话状态管理
- **C4**: 确认用户数据在Supabase Dashboard中可见

### Phase D: 部署和验证 (1小时)
**前后端对齐节点**: 生产环境部署验证
**SuperClaude工具建议**: `/sc:build --persona-backend --seq` (部署流程和生产环境配置)
- **D1**: 部署项目到Vercel
- **D2**: 配置生产环境变量
- **D3**: 测试生产环境认证功能
- **D4**: 验证整体功能完整性

## 🔧 所需工具和实施步骤

### Supabase项目创建步骤
```bash
# 1. 访问 https://database.new 创建Supabase项目
# 2. 记录项目信息
echo "Project URL: https://dosbevgbkxrtixemfjfl.supabase.co"
echo "Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvc2Jldmdia3hydGl4ZW1mamZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMDcwMjEsImV4cCI6MjA2OTc4MzAyMX0.xDbE8E8Fg84109qRQi9SFbi4PPUtCTBL1-Jj2R80lmI"

# 3. 验证项目连接
curl -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvc2Jldmdia3hydGl4ZW1mamZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMDcwMjEsImV4cCI6MjA2OTc4MzAyMX0.xDbE8E8Fg84109qRQi9SFbi4PPUtCTBL1-Jj2R80lmI" \
  https://dosbevgbkxrtixemfjfl.supabase.co/rest/v1/
```

### Starter Kit项目创建
```bash
# 1. 创建项目 (选择合适的包管理器)
npx create-next-app --example with-supabase prescription-platform
# 或者
yarn create next-app --example with-supabase prescription-platform  
# 或者
pnpm create next-app --example with-supabase prescription-platform

# 2. 进入项目目录
cd prescription-platform
```

### 环境配置和启动
```bash
# 3. 配置环境变量
cp .env.example .env.local

# 4. 编辑 .env.local 文件
NEXT_PUBLIC_SUPABASE_URL=https://dosbevgbkxrtixemfjfl.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvc2Jldmdia3hydGl4ZW1mamZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMDcwMjEsImV4cCI6MjA2OTc4MzAyMX0.xDbE8E8Fg84109qRQi9SFbi4PPUtCTBL1-Jj2R80lmI

# 5. 启动开发服务器
npm run dev
# 访问 http://localhost:3000

# 6. 验证认证功能
# - 访问登录页面
# - 注册新用户
# - 登录现有用户
# - 检查Supabase Dashboard用户记录
```

## ✅ 完成检查清单

### 🔍 Supabase项目验证
- [ ] **项目创建**: Supabase项目创建成功，获得项目URL和API密钥
- [ ] **数据库连接**: 能够访问项目数据库，Auth服务已启用
- [ ] **域名配置**: 项目域名设置正确，CORS配置允许localhost
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
- [ ] **Vercel部署**: 项目成功部署到Vercel
- [ ] **生产认证**: 生产环境认证功能正常工作
- [ ] **性能检查**: 页面加载速度符合预期

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

### 常见问题和解决方案

#### 🚨 Supabase项目连接问题
**症状**: 无法连接到Supabase项目或认证失败
**解决方案**:
```bash
# 检查环境变量配置
cat .env.local

# 验证API密钥和URL
curl -H "apikey: $NEXT_PUBLIC_SUPABASE_ANON_KEY" \
  "$NEXT_PUBLIC_SUPABASE_URL/rest/v1/"

# 检查项目状态
# 访问 https://dashboard.supabase.com/projects
```

#### 🚨 认证功能异常
**症状**: 用户无法注册或登录
**解决方案**:
```bash
# 检查Auth配置
# 1. 访问Supabase Dashboard > Authentication > Settings
# 2. 确认"Enable email confirmations"设置
# 3. 检查"Site URL"配置为 http://localhost:3000

# 检查网络请求
# 打开浏览器开发者工具 > Network标签
# 查看auth相关请求是否成功
```

#### 🚨 Vercel部署失败
**症状**: 部署过程中出现环境变量或构建错误
**解决方案**:
```bash
# 检查环境变量
# 1. 在Vercel Dashboard中添加环境变量
# 2. 确保NEXT_PUBLIC_SUPABASE_URL和NEXT_PUBLIC_SUPABASE_ANON_KEY正确

# 本地构建测试
npm run build

# 检查构建日志
# 在Vercel Dashboard查看详细构建日志
```

### 下一阶段衔接要求

**TASK02前置条件确认**:
- [ ] Supabase项目创建成功，Auth服务正常运行
- [ ] Next.js项目基于starter kit创建，认证功能验证通过
- [ ] 用户注册/登录流程完整，数据库记录可见
- [ ] 项目部署成功，生产环境认证功能正常

**交付物检查清单**:
- [ ] 基于starter kit的完整Next.js项目
- [ ] 配置好的.env.local文件（不包含实际密钥）
- [ ] 工作正常的认证系统（注册/登录/会话管理）
- [ ] Vercel部署链接和生产环境验证
- [ ] Supabase项目配置文档

**下一步优化规划**:
- [ ] 集成API日志记录系统（TASK02）
- [ ] 添加用户profile扩展功能
- [ ] 实现更完善的错误处理
- [ ] 优化用户体验和界面设计

---

**🎯 TASK01完成标识**: Supabase starter kit集成完成，用户认证功能验证通过，能够在数据库中查看注册/登录记录，项目成功部署，具备开始TASK02 API日志系统实施的完整条件。