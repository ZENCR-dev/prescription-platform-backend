# CLAUDE.md - 后端执行规则手册

**文档角色**: 本文仅定义"如何做"的执行规则与门控，不复述战略或API细节。

## 🔒 核心文档保护规范 (AI Agent强制遵守)

**文档修改权限控制**：
除非用户在提示词中**明确声明**要对文档进行修订，否则AI Agent不得直接对以下核心配置文档执行任何修改、删除或编辑操作：

**受保护文档清单**：
- **@CLAUDE.md** - 执行规则手册 (本文件)
- **@INITIAL.md** - 项目需求底本 (冻结状态)
- **@PLANNING.md** - 战略规划文档
- **@PRPs/TASK0X.md** - 所有PRP任务文档

**保护机制**：
- ✅ **允许操作**: 读取、分析、引用、解释文档内容
- ❌ **禁止操作**: 直接编辑、修改、删除、重写上述文档
- ⚠️ **例外情况**: 仅当用户明确使用"修改"、"更新"、"编辑"等关键词并指定具体文档时方可执行
- 🚨 **违规处理**: 任何未经授权的修改尝试将被立即中止并报告

**用户授权示例**：
```
✅ 明确授权: "请修改CLAUDE.md，添加新的验证规则"
✅ 明确授权: "更新TASK01.md的估算部分"
❌ 隐含修改: "优化项目配置" (未明确指定文档修改)
❌ 自主修改: Agent主动建议并执行文档修改
```

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

### 🚨 强制执行前验证 (架构合规性检查)

**⚠️ 违规阻断**: 以下检查未通过时必须停止执行并报错

#### 三层分支管理策略验证
```bash
# 1. 验证分支结构存在性
current_task=$(echo "$TASK" | grep -o 'TASK[0-9]\+')
git branch -a | grep "$current_task" || exit 1              # Layer 2存在
git branch -a | grep "$current_task-atomic-" || exit 1      # Layer 3存在

# 2. 验证当前分支正确性
current_branch=$(git branch --show-current)
[[ "$current_branch" =~ ^TASK[0-9]+-atomic-[0-9]+$ ]] || exit 1  # 必须在原子任务分支工作
```

#### 时间戳准确性验证
```bash
# 1. 禁用虚构时间，强制使用机器真实时间
real_time=$(date '+%Y-%m-%d %H:%M:%S')
log_time_pattern="[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"

# 2. 验证日志文件时间戳合规性
if [[ -f "PRPs/TASK*_LOG.md" ]]; then
  grep -E "2025-01-|2025-02-|2025-03-" PRPs/TASK*_LOG.md && {
    echo "❌ 错误：检测到虚构时间戳，必须使用真实机器时间"
    exit 1
  }
fi
```

#### 强制时间戳标准化机制
**Agent必须使用的时间戳生成方法**:
```bash
# 标准时间戳函数 (Agent必须调用)
get_real_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

# 原子任务分支命名函数 (Agent必须调用)
get_atomic_branch_name() {
  local task_num="$1"
  local atomic_num="$2"
  echo "TASK${task_num}-atomic-${atomic_num}"
}

# 验证时间戳真实性 (质量门控调用)
validate_timestamp_accuracy() {
  local timestamp="$1"
  local current_date=$(date '+%Y-%m-%d')
  
  # 检查时间戳是否为当前机器日期
  if [[ "$timestamp" == *"$current_date"* ]]; then
    echo "✅ 时间戳验证通过: $timestamp"
    return 0
  else
    echo "❌ 时间戳验证失败: $timestamp (当前日期: $current_date)"
    return 1
  fi
}
```

### Agent执行触发机制

当AI Agent接到Layer 2任务(来自`PRPs/TASK0X.md`中的atomic task)时，自动启动Layer 3执行协议：

**触发条件**:
1. 接收到来自Layer 2的具体atomic task assignment  
2. 确认Layer 1(PLANNING.md)约束和Layer 2(INITIAL.md + PRPs/TASK0X.md)验收标准
3. 创建对应的`PRPs/TASK0X_LOG.md`开发操作日志文档
4. 开始使用Claude Code内置`TodoWrite`工具生成临时TDD-Todos

**TDD核心原则** (不可违背):
- ⚠️ **串行执行**: 一次只处理一个原子任务，完成全部3+1步骤才能开始下一任务
- ⚠️ **TDD强制**: 必须先写测试，后写实现（红灯→绿灯→重构循环）
- ⚠️ **完整周期**: 一个原子任务 = 一组3+1 TDD todos = 一个完整测试驱动开发周期

**执行原则**:
- **临时性**: Layer 3 TDD-Todos由Agent临时生成，**不创建持久化文档**
- **自主性**: Agent根据atomic task复杂度自主决定具体步骤数量和内容
- **3+1步骤**: 基于TDD红灯→绿灯→重构→验证的标准测试驱动开发模式
- **质量门控**: 深度检查上移至Layer 2智能质量门控，原子任务仅做基础验证
- **操作记录**: 所有开发操作必须实时记录到对应的TASK0X_LOG.md文档

### 执行边界规则 (严格执行)

**原子任务边界定义**:
- **执行单元**: 一个原子任务 = 一组3+1 TDD todos = 一个完整测试驱动开发周期
- **串行约束**: 所有步骤必须串行完成，禁止并行执行多个原子任务
- **完成标准**: 必须完成当前原子任务的全部4个步骤才能开始下一个原子任务

**Git分支时机与提交规则**:
- **分支创建**: 开始第一个原子任务时创建日期分支 (YYYY-MM-DD-HHMM)
- **中间提交**: 禁止在3+1步骤中间提交，保持原子性
- **完成提交**: 第4步验证通过后立即commit，包含完整功能和测试
- **分支合并**: 所有原子任务完成后合并到TASK分支

**依赖关系处理**:
- **顺序执行**: 有依赖的原子任务必须等待前置任务完全完成
- **数据共享**: 通过完成的代码和测试传递状态，不通过内存共享
- **状态检查**: 每个原子任务开始前验证前置条件是否满足

### 3+1步骤执行模式 (简化的原子任务开发流程)

Agent执行Layer 2 atomic task时，使用`TodoWrite`工具生成标准的**3+1步骤**执行流程：

#### 1. 测试设计阶段【TDD红灯】(主实现角色负责)
```bash
# SuperClaude命令 (根据任务类型选择)
/sc:test --write-failing-tests --persona-[backend|architect]
/sc:design test-cases --atomic-task [task-name]

# Agent行为
- 分析原子任务需求，理解期望的功能行为
- 编写应该失败的测试用例（因为功能还未实现）
- 定义清晰的验收标准和断言条件
- 运行测试确认RED状态（测试失败）
```

#### 2. 最小实现阶段【TDD绿灯】(同一主实现角色负责)
```bash
# SuperClaude命令
/sc:implement --minimal-passing --persona-[backend|architect]
/sc:test --run-until-green

# Agent行为
- 编写最少代码使测试通过（避免过度设计）
- 专注功能实现，不做性能优化或复杂设计
- 运行测试确认GREEN状态（所有测试通过）
- 不添加测试未覆盖的功能
```

#### 3. 重构优化阶段【TDD重构】(同一主实现角色负责)
```bash
# SuperClaude命令
/sc:refactor --improve-design --persona-[backend|architect]
/sc:test --continuous-validation

# Agent行为
- 改进代码结构和性能，但保持测试持续通过
- 消除重复代码，提升可读性和可维护性
- 添加必要的文档和注释
- 确保重构后所有测试仍然通过（保持GREEN状态）
```

#### 4. 验证提交阶段【质量门控】(qa persona负责)
```bash
# SuperClaude命令
/sc:test --comprehensive --validate-all
/sc:git --tdd-commit --atomic-task

# Agent行为
- 运行完整测试套件，确保所有测试通过
- 执行lint、build、type-check等质量检查
- 验证TDD周期完整性：测试覆盖率、代码质量
- Git commit到日期分支，包含功能代码和测试代码
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

**TodoWrite数据结构示例** (TDD标准实践):
```javascript  
// 单个原子任务的正确3+1 TDD todos示例
TodoWrite([
  {
    id: "task01-1-step1",
    content: "【backend】TDD红灯：编写Supabase连接、认证验证、环境配置失败测试用例",
    status: "completed",
    priority: "high"
  },
  {
    id: "task01-1-step2",
    content: "【backend】TDD绿灯：实现最小代码使所有测试通过，确认连接成功", 
    status: "in_progress",
    priority: "high"
  },
  {
    id: "task01-1-step3", 
    content: "【backend】TDD重构：优化连接配置，提升代码可读性，保持测试绿色",
    status: "pending",
    priority: "medium"
  },
  {
    id: "task01-1-step4",
    content: "【qa】质量门控：完整测试套件+lint+build+commit到日期分支",  
    status: "pending",
    priority: "high"
  }
])

// 错误示例：批量创建多个原子任务的todos (违反串行执行原则)
// ❌ 不要这样做 - Agent应该只为当前原子任务创建todos
// TodoWrite([...task01-1, ...task01-2, ...task01-3]) // 错误！

// 正确示例：完成当前原子任务后，再为下一个原子任务创建新的todos
// ✅ 当task01-1完成后，才创建task01-2的todos
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
后端任务: backend persona  
  - API实现
  - 业务逻辑处理
  - 数据库操作
  - 基础安全验证

系统任务: architect persona
  - 后端架构设计
  - 技术选型
  - 系统集成
  - 后端重构
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

### 前后端协作边界

**职责分工原则**:
- **后端职责**: API设计与实现、业务逻辑、数据库、安全合规
- **前端职责**: UI实现、用户体验、前端交互(由前端团队在前端项目完成)
- **协作界面**: APIdocs/APIv1.md为唯一接口规范

**前端任务处理流程**:
1. 后端完成API实现并更新APIv1.md
2. 前端团队基于API规范独立开发UI
3. 通过API接口进行集成测试
4. 问题反馈通过API文档版本控制处理

**医疗合规协作机制**:
- **后端负责**: HIPAA数据加密、审计日志、安全架构
- **前端负责**: 用户隐私界面、合规提示、数据展示脱敏(由前端团队完成)
- **协作机制**: 通过安全API接口确保合规性传递

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
  - [ ] API接口响应正常
  - [ ] 数据库操作正确
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

```yaml
Layer 1 (Feature): main/master → 生产就绪功能集合
Layer 2 (Phase): TASK branches → Phase级功能集成和质量验证  
Layer 3 (Atomic): TASK-atomic-NN分支 → 原子任务功能实现和基础验证

分支命名规范:
  Layer 3: {TASK}-atomic-{序号} (如: TASK01-atomic-01, TASK01-atomic-02)
  优势: 语义明确、避免时间戳分支泛滥、Git commit提供时间追踪

分支生命周期:
  Layer 3: 原子任务开始创建，完成后合并到TASK分支，24小时后自动清理
  Layer 2: Phase开始创建，完成后合并到main
  Layer 1: 长期存在，持续演进
```

### 质量门控触发机制

```yaml
Layer 3: 3+1步骤完成 + 基础质量检查 (<3分钟)
Layer 2: Phase内所有原子任务完成 + 轻量级验证 (<5分钟)
Layer 1: Feature完成 + 完整验证 (时间视复杂度)

失败处理:
  Layer3: 阻止合并+错误显示 → 人工修复后重试
  Layer2: 人工分析+修复任务 → 新日期分支开发 
  Layer1: 回滚+系统修复 → 制定修复计划
```

### 医疗合规集成

```yaml
HIPAA失败: 暂停合并+安全审查 → 强制安全团队review
FDA失败: 阻止发布+专家审查 → 医疗专家validation
安全分支: hipaa-, fda-, security-前缀 → 延长保护期48小时
```

### 详细操作规范

**详细规范参考**:
- 分支命名规范: [examples/git-workflow/branch-naming.md](examples/git-workflow/branch-naming.md)
- 提交信息标准: [examples/git-workflow/commit-messages.md](examples/git-workflow/commit-messages.md)  
- 质量门控集成: [examples/git-workflow/quality-control-integration.md](examples/git-workflow/quality-control-integration.md)

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
