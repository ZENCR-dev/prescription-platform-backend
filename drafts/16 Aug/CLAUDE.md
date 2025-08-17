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

## 任务树与进度持久化

### 最小执行单元
- **粒度要求**: 4-8小时可完成的原子任务
- **开发循环**: TDD → 实现 → 重构 → 验证

### 持久化要求
- **任务拆分**: 写入PRPs/<feature>_vN.md或progress.md
- **状态更新**: 每次执行完一个原子任务，更新状态与验证结果

## 🤖 Layer3: Agent自主执行TDD-Todos循环 (最少9步)

当Agent接收到Layer2文档中的Phase任务时，自动启动以下循环：

### 标准9+步开发循环

1. **任务理解分析** → TodoWrite(任务拆解) + /analyze --persona-analyzer --seq
2. **执行计划制定** → TodoWrite(步骤规划) + /design --persona-architect
3. **测试用例编写** → TodoWrite(测试清单) + /test --mode=write --persona-qa
4. **最小可行实现** → TodoWrite(核心代码) + /build --mode=minimal
5. **完整功能实现** → TodoWrite(业务逻辑) + /implement
6. **安全合规检查** → TodoWrite(安全验证) + /scan --security --persona-security
7. **性能优化调试** → TodoWrite(优化任务) + /improve --performance
8. **代码重构清理** → TodoWrite(重构计划) + /cleanup --persona-refactorer
9. **最终验证提交** → TodoWrite(验证清单) + /git --validate --persona-mentor
10+. **扩展步骤**: 根据任务复杂度可增加集成测试、文档更新、部署验证等

### Agent执行原则

- **TodoWrite驱动**: 每步开始前使用TodoWrite工具制定具体执行计划
- **状态同步**: 实时更新到对应Layer2 Phase的执行状态
- **质量门控**: 每步完成后必须通过CLAUDE.md中定义的验证标准
- **自主决策**: Agent可根据任务特点调整步骤顺序或增加额外步骤

## 质量门槛与校验门 (执行前置)

### 必跑校验 (失败则停止继续)
- **类型检查**: npm run type-check
- **Lint**: npm run lint  
- **单测**: npm run test (覆盖率门槛见PLANNING)
- **迁移/类型**: supabase migration up (或dry-run)、supabase gen types typescript > types/database.types.ts
- **Edge Functions**: supabase functions serve (或等价流程)

### 验证失败处理
按PRP的"Validation Loop"修复后重试；禁止跳过。

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

---

**SuperClaude执行规则手册状态**: ✅ **精简完成** | 📊 **职责**: 执行规则与门控 | 🔗 **指向模式**: 链接指向唯一真源 | 🚀 **执行模式**: 阶段白名单+质量门控

*采用SuperClaude精简化执行规则模式 - 专注"如何做"，避免重复内容*