# CLAUDE.md - 后端执行规则手册

**文档角色**: 本文仅定义"如何做"的执行规则与门控，不复述战略或API细节。

## 文档读取顺序 (执行阶段强制)

执行阶段读取顺序：
1. **当前PRP** (含Requirements Snapshot)
2. **APIdocs/APIv1.md** (唯一API真源；变更见APIv1_log.md)
3. **PLANNING.md** (战略参考)
4. **INITIAL.md** (冻结底本，仅溯源与再生成时查看)

## 阶段白名单 (源自后端开发流程)

| 阶段 | 允许能力 | 禁止事项 |
|---|---|---|
| RESEARCH | 代码检索、上下文收集、架构分析 | 生成PRP、修改代码 |
| INNOVATE | 方案对比、技术选型、澄清问题 | 修改代码、落地实现 |
| PLAN | 生成PRP、任务树拆分、检查清单 | 执行代码变更 |
| EXECUTE | 按PRP实现、测试、修复、部署 | 脱离PRP自行发挥 |
| REVIEW | 验收与总结、输出报告、状态更新 | 修改实现或PRP |

**越权阻断**: 任何越权能力调用一律中止并回退到正确阶段。

## 🚨 API文档中心化强制规范

**APIv1.md单一数据源原则** (不可违背)：
- **📄 唯一权威文档**: `APIdocs/APIv1.md` - 项目API文档的唯一真实来源
- **📋 版本控制中心**: `APIdocs/APIv1_log.md` - 所有API变更的完整记录
- **🔒 集中管理策略**: 所有API端点、参数、响应格式、错误码在此统一定义
- **⚠️ 禁止分散文档**: 严禁在其他文件中重复定义API规范，避免不一致

**API文档修改工作流** (强制执行)：
```
🎯 需求分析 → 🏗️ 后端功能设计 → 🗄️ Supabase数据库设计 → 📄 APIv1.md更新 → 🔄 前端对接
```

**关键原则**：
- ✅ **数据库驱动API设计**: API接口必须基于Supabase数据库字段和RLS策略设计
- ✅ **后端优先原则**: API文档变更必须跟随后端功能实现，而非反向推动
- ❌ **禁止逆向修改**: 不得因API文档要求去修改已设计的数据库结构
- ❌ **禁止脱离实现**: API文档不得包含未在后端实现的功能规范

## PRP与上下文引用规则

### PRP生成与执行
- **生成阶段**: 仅在PLAN阶段生成PRP；执行以"当前PRP"为唯一载体
- **内嵌要求**: PRP必须内嵌Requirements Snapshot:
  - 从INITIAL.md拷贝: Feature/约束(NFR/合规/安全)/成功标准/非目标(OOS)摘要
  - 元信息: source: INITIAL.md@<commit>, api_source: APIdocs/APIv1.md@<version>, planning_ref: PLANNING.md@<commit>

### 上下文引用验证
- **可验证原则**: 上下文引用需可验证：必须提供文件/路径/行号/链接；严禁凭空杜撰
- **变更追踪**: 
  - INITIAL.md为冻结底本：PRP生成后不得改动
  - 需求变更：新建PRP版本(PRPs/<feature>_vN.md)，在Delta段描述变化与影响
  - API变更：仅在APIdocs/APIv1.md修改，并同步记录于APIdocs/APIv1_log.md

---

## 🏗️ Layer 3: TDD-Todos自主执行协议 {#layer3-execution-protocol}

### Agent执行触发机制

当AI Agent接到Layer 2任务(来自`PRPs/TASK0X.md`中的atomic task)时，自动启动Layer 3执行协议：

**触发条件**:
1. 接收到来自Layer 2的具体atomic task assignment  
2. 确认Layer 1(PLANNING.md)约束和Layer 2(INITIAL.md + PRPs/TASK0X.md)验收标准
3. 创建对应的`PRPs/TASK0X_LOG.md`开发操作日志文档
4. 开始使用Claude Code内置`TodoWrite`工具生成临时TDD-Todos

**执行原则**:
- **临时性**: Layer 3 TDD-Todos由Agent临时生成，**不创建持久化文档**
- **自主性**: Agent根据atomic task复杂度自主决定具体步骤数量和内容
- **3+1步骤**: 基于简化的3+1步骤执行模式（一个主实现角色 + 一个验证角色）
- **质量门控**: 深度检查上移至Layer 2智能质量门控，原子任务仅做基础验证
- **操作记录**: 所有开发操作必须实时记录到对应的TASK0X_LOG.md文档

### 3+1步骤执行模式 (简化的原子任务开发流程)

Agent执行Layer 2 atomic task时，使用`TodoWrite`工具生成标准的**3+1步骤**执行流程：

#### 1. 需求分析与设计 (主实现角色负责)
```bash
# SuperClaude命令 (根据任务类型选择)
/sc:analyze [atomic-task] --persona-[frontend|backend|architect]

# Agent行为
- 主实现角色分析atomic task的需求和技术方案
- 设计实现路径和技术架构
- 识别依赖关系和潜在风险
- 确定验证标准和成功指标
```

#### 2. 实现与自测 (主实现角色负责)
```bash
# SuperClaude命令
/sc:implement [feature] --persona-[frontend|backend|architect]
/sc:test --type unit --basic

# Agent行为
- 同一主实现角色完成功能实现
- 编写基础单元测试确保功能正确
- 执行代码格式化和基础lint检查
- 满足Layer 2定义的验收标准
```

#### 3. 集成准备 (主实现角色负责)
```bash
# SuperClaude命令
/sc:test --type integration --prepare
/sc:validate --dependencies

# Agent行为
- 同一主实现角色准备集成环境
- 验证与其他模块的接口兼容性
- 准备集成所需的配置和文档
- 确保代码符合项目约定和规范
```

#### 4. 质量验证与提交 (qa persona负责)
```bash
# SuperClaude命令
/sc:test --type basic --validate
/sc:git --validate --commit

# Agent行为
- qa persona执行基础质量检查
- 运行单元测试和代码规范检查
- 验证功能完整性和集成准备状态
- 提交代码并更新任务状态
```

### v6.0专业检查简化

以下检查步骤已从原子任务级别移除，现在通过简化机制处理：

- **安全合规检查**: 整合到backend persona基础安全验证中
- **性能基准测试**: 整合到实现角色的基础性能考虑中  
- **代码质量分析**: 整合到qa persona的基础质量检查中
- **集成测试验证**: 整合到轻量级Phase验证中

这些检查通过统一的Phase验证机制执行，失败时人工识别问题并创建简单修复任务。

### v6.0简化AI Agent估算体系

**简化估算维度** (4个直观指标):
```yaml
步骤数量: 直接数字计数 (范围: 3-15步)
  - 预期的3+1步骤循环中具体操作数量
  - 示例: "6步" (无需复杂分类)

代码文件: 文件数量预估 (范围: 1-10个文件)  
  - 预期修改或创建的文件数量
  - 示例: "3个文件" (无需精确行数)

迭代轮次: 简单轮次预期 (范围: 1-3轮)
  - 预期的开发-测试-修复循环次数
  - 示例: "2轮" (大多数任务1-2轮)

复杂度: 三级简单标记
  - 低: 独立功能，无复杂依赖
  - 中: 跨模块集成，适度依赖  
  - 高: 系统级影响，复杂依赖
  - 示例: "中" (直观易懂)
```

**估算模板格式**:
```yaml
AI Agent估算:
  步骤数量: X步
  代码文件: X个文件
  迭代轮次: X轮
  复杂度: 低/中/高
```

**实际使用示例**:
```yaml
用户登录组件:
  步骤数量: 4步
  代码文件: 2个文件
  迭代轮次: 1轮
  复杂度: 低

处方API实现:
  步骤数量: 8步
  代码文件: 5个文件
  迭代轮次: 2轮
  复杂度: 中

认证系统重构:
  步骤数量: 12步
  代码文件: 8个文件
  迭代轮次: 3轮
  复杂度: 高
```

### TodoWrite工具使用最佳实践

**Agent使用TodoWrite的核心原则**:
1. **实时更新**: 每完成一个步骤立即更新todo状态
2. **单一活跃**: 同时只有一个todo处于in_progress状态  
3. **验证驱动**: 每个todo完成必须有明确的验证标准
4. **上下文链接**: 每个todo包含对Layer 2 atomic task的引用
5. **日志记录**: 每个todo执行时必须记录到对应的TASK0X_LOG.md

**TodoWrite数据结构示例**:
```javascript  
// Agent生成的临时TodoWrite示例 (3+1步骤模式)
TodoWrite([
  {
    id: "task0x-step1",
    content: "【backend persona】需求分析与设计 - 分析组件需求，设计技术方案", 
    status: "completed",
    priority: "high"
  },
  {
    id: "task0x-step2",
    content: "【backend persona】实现与自测 - 完成组件开发和基础单元测试", 
    status: "in_progress",
    priority: "high"
  },
  {
    id: "task0x-step3", 
    content: "【backend persona】集成准备 - 验证接口兼容性，准备集成文档",
    status: "pending",
    priority: "medium"
  },
  {
    id: "task0x-step4",
    content: "【qa persona】质量验证与提交 - 运行测试，代码审查，提交代码",  
    status: "pending",
    priority: "high"
  }
])
```

### 开发操作日志记录规范

**日志文档**: 每个TASK执行时创建对应的`PRPs/TASK0X_LOG.md`文档

**记录原则**:
- **纯操作记录**: 只记录实际执行的开发动作，不做评价或预测
- **倒序排列**: 最新操作在顶部，格式：`[时间戳] 阶段标识 操作描述`
- **技术语言**: 简洁准确的技术描述，避免主观性语言
- **阶段标注**: 使用3+1步骤的阶段标识 (📋 分析设计、🚀 实现自测、🔧 集成准备、✅ 质量提交)
- **Git独行**: commit信息独立section，包含完整commit hash和不超过一行字的标题式message

**记录格式模板**:
```markdown
### [YYYY-MM-DD HH:MM:SS] 🚀 实现自测 - Task X.Y
- 创建组件文件: `src/components/auth/AuthUI.tsx`
- 编写单元测试: `__tests__/auth/AuthUI.test.tsx`
- 执行基础lint检查，修复格式问题

### [YYYY-MM-DD HH:MM:SS] 📋 分析设计 - Task X.Y
- 分析Supabase Auth集成需求
- 设计组件接口和状态管理方案
- 确定测试策略和验证标准
```

**日志维护责任**:
- Agent在每个开发循环阶段完成时立即更新日志
- 记录所有文件修改、配置变更、命令执行
- Git commit信息单独记录，便于版本追踪
- 不记录进度评估、性能预测或改进建议

---
## 📋 Layer 2: 统一工作流模板定义 (v6.0敏捷版)

### Layer 2 职责简化

**v6.0新职责**: 统一工作流模板定义 + 验收标准制定 + 原子任务分解

**核心简化**: 移除复杂的Component分类，采用统一的3+1步骤工作流模板，专注敏捷开发和功能交付。

### 统一3+1工作流模板

**所有任务通用的标准步骤**:
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

### 角色选择指导

**主实现角色选择** (负责步骤1-3):
```yaml
前端任务: frontend persona
  - UI组件开发
  - 用户界面实现
  - 前端交互逻辑

后端任务: backend persona  
  - API实现
  - 业务逻辑处理
  - 数据库操作
  - 基础安全验证

系统任务: architect persona
  - 架构设计
  - 技术选型
  - 系统集成
  - 复杂重构
```

**验证角色** (负责步骤4):
```yaml
qa persona (所有任务):
  - 基础质量检查
  - 功能验证
  - 代码审查
  - 提交管理
```

### 医疗平台特殊考虑

**安全敏感功能增强** (患者数据、认证、处方):
```yaml
步骤1增强:
  - 基础安全架构考虑
  - HIPAA/FDA合规规划

步骤2增强:
  - 基础安全验证实现
  - 患者数据加密处理
  - 审计日志记录

步骤3增强:
  - 安全接口验证
  - 合规性自检

步骤4增强:
  - 医疗合规验证
  - 安全检查强化
```

### Layer 2 简化接口

**输入接口** (从Layer 1接收):
- Feature级别的用户故事和业务价值
- 基础技术约束和安全合规要求

**输出接口** (向Layer 3提供):
- 具体的原子任务分解
- 简化的验收标准
- 基础的执行指导

**质量接口** (与Phase验证集成):
- 统一的完成标准定义
- 简化的验证要求

## 🚪 轻量级Phase验证体系 (v6.0敏捷版)

### 设计原则

**核心理念**: 敏捷优先、够用即可、人工灵活

- **敏捷优先**: 快速验证，不阻碍开发节奏
- **够用即可**: 保留核心质量要求，移除过度检查  
- **人工灵活**: 失败时人工处理，避免过度自动化

### 统一Phase完成验证

**基础验证标准** (所有Phase通用):
```yaml
自动检查:
  - [ ] 所有原子任务状态 = completed
  - [ ] npm run test 通过 (单元测试覆盖率>80%)
  - [ ] npm run lint 通过 (ESLint代码规范)
  - [ ] npm run type-check 通过 (TypeScript类型验证)
  
功能验证:
  - [ ] 功能手动验证通过
  - [ ] API接口响应正常 (如适用)
  - [ ] 界面显示正确 (如适用)
```

**医疗平台特殊要求** (仅安全敏感功能):
```yaml
安全验证:
  - [ ] 基础HIPAA合规检查 (患者数据加密、访问控制)
  - [ ] SQL注入防护验证 (参数化查询检查)
  - [ ] 基础审计日志检查 (关键操作记录)
  
合规验证:
  - [ ] 处方数据完整性验证 (处方功能)
  - [ ] 药物相互作用检查 (处方功能)
  - [ ] FDA规范基础符合性 (处方功能)
```

### 执行机制

**触发时机**: Phase内所有原子任务完成时自动触发

**执行时间**: <5分钟 (快速验证)

**失败处理**: 
- **检查通过**: 继续下一Phase，记录通过日志
- **检查失败**: 人工识别具体问题，创建简单修复任务

**修复流程**:
```bash
1. 自动显示具体错误信息
2. 开发者分析问题原因
3. 创建针对性修复任务
4. 修复完成后重新触发验证
```

## 质量门槛与校验门 (执行前置)

### 必跑校验 (失败则停止继续)
- **类型检查**: npm run type-check
- **Lint**: npm run lint  
- **单测**: npm run test (覆盖率门槛见PLANNING)
- **迁移/类型**: supabase migration up (或dry-run)、supabase gen types typescript > types/database.types.ts
- **Edge Functions**: supabase functions serve (或等价流程)

### 验证失败处理
按PRP的"Validation Loop"修复后重试；禁止跳过。

## 🌳 三层Git分支管理策略 (v6.0敏捷版)

### Git分支与任务树映射关系

**核心原则**: Git分支结构与三层任务树形成一一对应关系，实现清晰的版本管理路径。

#### 分支层级映射
```yaml
Layer 1 (Feature Level):
  分支: main/master
  作用: 生产就绪的完整功能集合
  生命周期: 长期存在，持续演进
  合并条件: 整个Feature完成并通过Feature级验证

Layer 2 (Phase Level):  
  分支: TASK branches (TASK01, TASK02, etc.)
  作用: Phase级功能集成和质量验证
  生命周期: Phase开始创建，Phase完成后合并到main
  合并条件: Phase内所有原子任务完成并通过轻量级Phase验证

Layer 3 (Atomic Task Level):
  分支: 日期分支 (YYYY-MM-DD-HHMM-<task-identifier>)
  作用: 原子任务的功能实现和基础验证
  生命周期: 原子任务开始创建，完成后合并到对应TASK分支，24小时后自动清理
  合并条件: 原子任务完成3+1步骤循环并通过基础质量检查
  分支控制: 最多11个活跃分支，自动清理机制保证开发效率
```

### 分支命名规范 (v6.0日期分支策略)

#### 命名格式标准
```bash
# Layer 1: 主分支
main                    # 生产主分支
develop                 # 开发集成分支(可选)

# Layer 2: TASK分支 (月度周期管理)
TASK01-2025-01-auth     # 认证系统Phase (2025年1月)
TASK02-2025-01-api      # 处方API Phase (2025年1月)
TASK03-2025-02-ui       # 患者界面Phase (2025年2月)

# Layer 3: 日期分支 (自动生成，AI Agent使用)
2025-01-17-1530-auth-middleware         # 2025年1月17日15:30 认证中间件
2025-01-17-1630-login-validation        # 2025年1月17日16:30 登录验证
2025-01-18-0900-prescription-api        # 2025年1月18日09:00 处方API

# 修复分支 (轻量级验证失败时创建)
2025-01-17-1800-fix-auth-security       # 2025年1月17日18:00 安全修复
2025-01-18-1000-fix-performance         # 2025年1月18日10:00 性能修复
hotfix-2025-01-17-critical-auth         # 紧急修复
```

#### 日期分支命名规则
```yaml
格式: YYYY-MM-DD-HHMM-<task-identifier>
  YYYY-MM-DD: 开发日期
  HHMM: 24小时制时间，避免命名冲突
  task-identifier: 简洁任务标识，kebab-case格式

自动化规则:
  创建: AI Agent执行3+1步骤时自动生成
  命名: 基于开始时间和任务描述自动命名
  冲突处理: 时间戳+随机后缀避免冲突
  
清理策略:
  自动删除: 合并到TASK分支后24小时自动清理
  保护期: 安全相关分支48小时保护期
  强制清理: 超过11个分支时清理最旧分支

医疗合规标识:
  hipaa-: HIPAA合规相关功能
  fda-: FDA规范相关功能
  security-: 安全敏感功能
  示例: 2025-01-17-1530-hipaa-patient-data
```

### 提交粒度规范

#### Layer 3 (原子任务) 提交标准
```yaml
提交类型: 功能性提交
提交频率: 每完成3+1步骤循环的一个步骤就提交一次
提交内容要求:
  - 包含完整的功能实现
  - 通过基础质量检查 (linting, 单测, 类型检查)
  - 包含必要的测试用例
  - 更新相关文档

提交信息格式:
feat(task01-01): implement JWT authentication middleware
test(task01-01): add unit tests for JWT validation
fix(task01-01): resolve token expiration edge case
docs(task01-01): update authentication flow documentation
```

#### Layer 2 (Phase) 提交标准
```yaml
提交类型: 里程碑提交
提交频率: Phase完成并通过智能质量门控后
提交内容要求:
  - 集成多个原子任务的功能
  - 通过智能质量门控验证
  - 更新API文档 (如适用)
  - 包含集成测试结果

提交信息格式:
feat(TASK01): complete authentication system implementation
- JWT middleware with refresh token support
- Role-based access control (RBAC)
- Password policy enforcement
- Audit logging for security events
- 通过轻量级验证，安全检查得分96%

BREAKING CHANGE: Updated user session structure
```

#### Layer 1 (Feature) 提交标准
```yaml
提交类型: 发布提交
提交频率: 整个Feature完成后
提交内容要求:
  - 完整的生产就绪功能
  - 通过完整的Feature级验证
  - 更新版本号和变更日志
  - 包含部署指南

提交信息格式:
release: v1.2.0 - Prescription Management System
- Complete prescription workflow (TASK01-TASK03)
- HIPAA compliant patient data handling
- Integration with pharmacy systems
- Advanced security and audit features
- Performance optimized for >10k concurrent users

Includes: TASK01 (Auth), TASK02 (Prescription API), TASK03 (Patient UI)
```

### 质量门控与Git集成机制 (v6.0敏捷版)

#### 三层质量门控触发体系
```yaml
Layer 3 触发机制 (原子任务完成):
  触发条件: 3+1步骤循环完成 + 基础质量检查通过
  Git动作: 自动commit到日期分支 → 创建PR到TASK分支 → 自动合并
  验证内容:
    - 单元测试覆盖率 >80%
    - ESLint代码规范检查
    - TypeScript类型验证
    - 功能基础验证
  执行时间: <3分钟
  失败处理: 阻止合并，显示具体错误，人工修复后重试

Layer 2 触发机制 (Phase完成):
  触发条件: Phase内所有原子任务完成
  Git动作: 自动触发轻量级验证 → 创建PR到main分支
  验证内容:
    - 集成测试完整性
    - API接口兼容性验证
    - 医疗合规基础检查 (HIPAA/FDA)
    - 安全漏洞扫描
    - 性能基准测试
  执行时间: <5分钟
  失败处理: 人工分析问题，创建针对性修复任务

Layer 1 触发机制 (Feature完成):
  触发条件: 整个TASK功能完成
  Git动作: 版本标记 → 发布准备 → 生产部署验证
  验证内容:
    - 完整功能测试
    - 端到端业务流程验证
    - 生产环境安全审计
    - 性能压测和稳定性测试
  执行时间: 根据Feature复杂度而定
  失败处理: 回滚到稳定版本，制定修复计划
```

#### 日期分支与质量门控集成
```yaml
分支创建时机:
  时点: AI Agent开始执行3+1步骤时
  命名: 自动生成 YYYY-MM-DD-HHMM-<task-identifier>
  初始检查: 分支创建前验证TASK分支存在

质量检查节点:
  节点1 (步骤1完成): 设计方案合理性检查
  节点2 (步骤2完成): 代码实现质量检查
  节点3 (步骤3完成): 集成准备完整性检查
  节点4 (步骤4完成): 最终质量验证 + Git合并触发

自动化流程:
  1. 日期分支创建 → 初始化质量检查环境
  2. 每步骤完成 → 增量质量验证
  3. 步骤4完成 → 全面质量门控 + 自动合并
  4. 合并成功 → 24小时后自动清理分支
```

#### 医疗合规与Git工作流集成
```yaml
HIPAA合规检查集成:
  触发层级: Layer 2, Layer 3 (患者数据相关)
  检查内容:
    - 患者数据加密验证
    - 访问控制权限检查
    - 审计日志完整性验证
  自动化程度: 80% (基础检查自动化)

FDA规范检查集成:
  触发层级: Layer 2 (处方相关功能)
  检查内容:
    - 处方数据格式规范性
    - 药物相互作用检查覆盖
    - 处方生命周期合规性
  自动化程度: 70% (业务规则自动化)

安全审计与分支保护:
  高风险分支标识: hipaa-, fda-, security-前缀
  保护措施:
    - 强制代码审查 (至少2人)
    - 延长分支保护期 (48小时)
    - 额外安全扫描和合规验证
  紧急响应: 安全问题发现时自动暂停合并
```

### 轻量级验证与Git集成

#### 自动触发机制 (与质量门控集成)
```yaml
Git Hook集成 (增强版):
  pre-commit (日期分支): 
    - 代码格式化检查 (ESLint, Prettier)
    - 基础类型检查 (TypeScript)
    - 3+1步骤完成状态验证
    
  pre-push (日期分支 → TASK分支):
    - Layer 3质量门控自动触发
    - 单元测试执行 + 覆盖率验证 (>80%)
    - 原子任务完成度验证
    - 医疗合规基础检查 (如适用)
    
  pre-merge (TASK分支 → main):
    - Layer 2轻量级Phase验证自动触发
    - 集成测试 + API兼容性验证
    - HIPAA/FDA合规检查 (安全敏感功能)
    - 所有功能统一验证标准

CI/CD Pipeline集成 (多层触发):
  日期分支: Layer 3基础验证流水线 (<3分钟)
    - 快速反馈，保证开发效率
    - 基础质量检查，防止低级错误
    
  TASK分支: Layer 2 Phase验证流水线 (<5分钟)
    - 功能完整性验证
    - 医疗合规检查
    - 性能基准验证
    
  Main分支: Layer 1 Feature验证 + 生产部署流水线
    - 完整功能测试
    - 安全审计和渗透测试
    - 生产环境部署验证

分支数量控制集成:
  监控触发: 当活跃分支 >9个时触发预警
  自动清理: 当活跃分支 =11个时自动清理最旧分支
  保护策略: 安全相关分支 (hipaa-, fda-, security-) 延迟清理
```

#### 智能失败处理 (v6.0敏捷版)
```yaml
分层失败处理策略:
  Layer 3失败 (原子任务级):
    1. 立即阻止合并到TASK分支
    2. 提供具体错误信息和修复建议
    3. AI Agent自动分析错误类型和修复方案
    4. 人工修复后重新触发Layer 3验证
    
  Layer 2失败 (Phase级):
    1. 阻止合并到main分支
    2. 创建详细的失败分析报告
    3. 人工review问题，创建针对性修复任务
    4. 修复任务使用新的日期分支进行开发
    
  Layer 1失败 (Feature级):
    1. 阻止生产部署
    2. 启动紧急修复流程
    3. 回滚到稳定版本
    4. 制定系统性修复计划

医疗合规失败特殊处理:
  HIPAA合规失败:
    - 立即暂停所有相关分支合并
    - 触发安全团队告警
    - 要求强制安全审查后才能继续
    
  FDA规范失败:
    - 阻止处方相关功能发布
    - 要求医疗专家审查
    - 必须通过合规验证才能继续

自动化恢复机制:
  轻微失败: 自动重试 (最多3次)
  中等失败: 提供修复建议 + 人工确认后重试
  严重失败: 强制人工介入 + 完整修复流程

失败通知:
  - Slack/邮件通知相关开发者
  - 包含具体错误信息和修复建议
```

### 分支保护规则

#### Main分支保护 (Layer 1)
```yaml
保护设置:
  - 禁止直接推送
  - 要求Pull Request审查 (至少2人)
  - 要求所有CI检查通过
  - 要求分支为最新状态

合并要求:
  - TASK分支的Feature级验证通过
  - 轻量级Phase验证检查通过
  - API文档更新完成 (如适用)
  - 部署就绪验证
```

#### TASK分支保护 (Layer 2)
```yaml
保护设置:
  - 禁止直接推送
  - 要求基础验证通过
  - 要求集成测试通过
  - 自动删除已合并的feature分支

合并要求:
  - 所有原子任务feature分支已合并
  - 基础验证检查通过 (<3分钟)
  - Phase级集成测试通过
  - API文档更新 (如适用)
```

#### Feature分支保护 (Layer 3)
```yaml
保护设置:
  - 允许force push (开发过程中)
  - 要求基础质量检查通过
  - 自动运行单元测试

合并要求:
  - 3+1步骤循环完成
  - 单元测试覆盖率达标
  - 代码规范检查通过
  - 功能验证完成
```

### 版本管理与发布流程

#### 语义化版本控制
```yaml
版本格式: MAJOR.MINOR.PATCH
  MAJOR: 不兼容的API更改 (Layer 1完成)
  MINOR: 向后兼容的功能添加 (Phase完成)
  PATCH: 向后兼容的错误修复 (原子任务修复)

医疗平台版本策略:
  v1.0.0: 基础处方系统
  v1.1.0: 添加药物相互作用检查 (TASK功能)
  v1.1.1: 修复处方数据验证bug (原子任务修复)
  v2.0.0: 引入新的HIPAA合规架构 (Breaking change)
```

#### 发布分支策略
```yaml
Release分支:
  创建时机: 准备发布新版本时
  命名: release/v1.2.0
  作用: 发布准备、bug修复、版本号更新
  合并: 同时合并到main和develop

Hotfix分支:
  创建时机: 生产环境紧急修复
  命名: hotfix/v1.1.1-critical-auth-fix
  作用: 紧急问题修复
  合并: 直接合并到main，同步到develop
```

### 分支清理策略

#### 自动清理规则
```yaml
Feature分支清理:
  - 合并到TASK分支后自动删除
  - 保留期: 7天 (可配置)
  - 例外: 包含重要实验性代码的分支需手动标记保留

TASK分支清理:
  - 合并到main后保留30天
  - 用于问题追溯和回滚参考
  - 重要里程碑分支永久保留并打标签

Fix分支清理:
  - 修复完成后立即删除
  - 保留修复记录在commit历史中
```

#### 标签管理
```yaml
标签类型:
  v1.0.0: 正式发布版本
  v1.0.0-beta.1: 测试版本
  v1.0.0-rc.1: 候选发布版本
  milestone-task01: 重要里程碑
  security-audit-2024-12: 安全审计点

自动标签:
  - 每次发布自动创建版本标签
  - Phase完成自动创建里程碑标签
  - 安全审计通过自动创建审计标签
```

### Git工作流最佳实践

#### 开发者工作流
```bash
# 1. 创建新的原子任务分支
git checkout -b feature/task01-01-login-component

# 2. 开发过程中定期提交
git add .
git commit -m "feat(task01-01): implement login form validation"

# 3. 完成原子任务，推送并创建PR
git push origin feature/task01-01-login-component
# 创建PR: feature/task01-01-login-component → TASK01-auth-system

# 4. 代码审查和质量检查通过后合并
# 自动触发基础质量检查

# 5. Phase完成时，TASK分支自动触发轻量级验证
# 通过后自动合并到main分支
```

#### 轻量级验证集成工作流
```bash
# 轻量级验证触发
git push origin TASK01-auth-system
# → 自动触发统一Phase验证 (<5分钟)
# → 执行基础质量检查、安全验证、功能验证

# 如果检查失败
# → 显示具体错误信息
# → 开发者人工分析问题
# → 手动创建修复任务

# 修复完成后
git checkout fix/task01-security-vulnerability
# 完成修复
git push origin fix/task01-security-vulnerability
# → 重新触发轻量级验证
# → 通过后允许合并
```

## 变更流程与追溯

- **INITIAL.md**: 冻结底本，PRP生成后不得改动
- **需求变更**: 新建PRP版本(PRPs/<feature>_vN.md)，在Delta段描述变化与影响
- **API变更**: 仅在APIdocs/APIv1.md修改，并同步记录于APIdocs/APIv1_log.md
- **CLAUDE/PLANNING**: 不落实现细节或API文本，统一以链接指向真源

## 安全与合规底线 (执行期)

- **隐私红线**: 不写入/处理患者个人身份信息；处方数据匿名化
- **权限安全**: 严格遵循RLS策略与角色权限；资金操作须具备事务一致性与可审计性
- **密钥管理**: Secrets管理与日志脱敏；禁将密钥写入代码或提交历史

## 链接索引 (只做指针，不复制内容)

- **INITIAL.md** (冻结底本)
- **PLANNING.md** (战略/路线/门槛/风险)
- **APIdocs/APIv1.md** 与 **APIdocs/APIv1_log.md** (唯一API真源)
- **PRPs/** (当前执行PRP、历史版本)
- **examples/** (示例与脚手架)
- **prd-reverse-engineering/old_docs/** (阶段白名单/NFR/KPI/Checkpoint的历史参考)
