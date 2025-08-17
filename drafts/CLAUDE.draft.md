--- 文件: prescription-platform-backend/drafts/CLAUDE.draft.md ---
# CLAUDE.draft.md（后端执行规则手册·精简版）

## 文档角色与读取顺序
- 本文仅定义“如何做”的执行规则与门控，不复述战略或API细节。
- 读取顺序（执行阶段强制）：
  1) 当前 PRP（含 Requirements Snapshot）
  2) APIdocs/APIv1.md（唯一 API 真源；变更见 APIv1_log.md）
  3) PLANNING.md（战略参考）
  4) INITIAL.md（冻结底本，仅溯源与再生成时查看）

## 阶段白名单（源自 old_docs/ 极简化）
| 阶段 | 允许能力（示例） | 禁止事项 |
|---|---|---|
| RESEARCH | 代码检索、上下文收集、/scan | 生成PRP、改代码 |
| INNOVATE | 方案对比、澄清问题 | 改代码、落地实现 |
| PLAN | /generate-prp、任务树拆分、Checklist | 执行代码变更 |
| EXECUTE | 按PRP实现、测试、修复 | 脱离PRP自行发挥 |
| REVIEW | 验收与总结、输出报告 | 修改实现或PRP |

- 任何越权能力调用一律中止并回退到正确阶段。

## PRP 与上下文引用规则
- 仅在 PLAN 阶段生成 PRP；执行以“当前 PRP”为唯一载体。
- PRP 必须内嵌 Requirements Snapshot：
  - 从 INITIAL.md 拷贝：Feature/约束(NFR/合规/安全)/成功标准/非目标(OOS) 摘要。
  - 元信息：source: INITIAL.md@<commit>，api_source: APIdocs/APIv1.md@<version>，planning_ref: PLANNING.md@<commit>。
- 上下文引用需可验证：必须提供文件/路径/行号/链接；严禁凭空杜撰。

## 任务树与进度持久化
- 最小执行单元：4–8 小时/粒度，TDD → 实现 → 重构 → 验证。
- 持久化要求：
  - 任务拆分与完成勾选写入 PRPs/<feature>_vN.md（或 progress.md）。
  - 每次执行完一个原子任务，更新状态与验证结果。

## 质量门槛与校验门（执行前置）
- 必跑校验（失败则停止继续）：
  - 类型检查：npm run type-check
  - Lint：npm run lint
  - 单测：npm run test（覆盖率门槛见 PLANNING）
  - 迁移/类型：supabase migration up（或 dry-run）、supabase gen types typescript > types/database.types.ts
  - Edge Functions 构建/本地验证：supabase functions serve（或等价流程）
- 验证失败：按 PRP 的“Validation Loop”修复后重试；禁止跳过。

## 变更流程与追溯
- INITIAL.md 为冻结底本：PRP 生成后不得改动。
- 需求变更：新建 PRP 版本（PRPs/<feature>_vN.md），在 Delta 段描述变化与影响。
- API 变更：仅在 APIdocs/APIv1.md 修改，并同步记录于 APIdocs/APIv1_log.md。
- CLAUDE/PLANNING 不落实现细节或 API 文本，统一以链接指向真源。

## 安全与合规底线（执行期）
- 不写入/处理患者个人身份信息；处方数据匿名化（见 PLANNING）。
- 严格遵循 RLS 策略与角色权限；资金操作须具备事务一致性与可审计性。
- Secrets 管理与日志脱敏；禁将密钥写入代码或提交历史。

## 链接索引（只做指针，不复制内容）
- INITIAL.md（冻结底本）
- PLANNING.md（战略/路线/门槛/风险）
- APIdocs/APIv1.md 与 APIdocs/APIv1_log.md（唯一 API 真源）
- PRPs/（当前执行 PRP、历史版本）
- examples/（示例与脚手架）
- prd-reverse-engineering/old_docs/（阶段白名单/NFR/KPI/Checkpoint 的历史参考）