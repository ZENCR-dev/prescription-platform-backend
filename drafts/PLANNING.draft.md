--- 文件: prescription-platform-backend/drafts/PLANNING.draft.md ---
# PLANNING.draft.md（后端战略总纲·精简版）

## 溯源与对齐（唯一真源关系）
- 需求底本：INITIAL.md（冻结；生成 PRP 后不再改动）
- 执行载体：PRPs/<feature>_vN.md（含 Requirements Snapshot 与 Delta 变更）
- API 真源：APIdocs/APIv1.md（变更记录：APIdocs/APIv1_log.md）
- 原则：本文件不复述 API 或实现细节；统一以链接指向真源与 PRP。

## 业务价值与闭环（B2B2C 差价模型）
- 商业模式：平台收益 = 医师支付净价（netPrice） - 药房成本（PO_total）。
- 三端价值（精要）：
  - 医师：高效处方/账户与结算/可视化收益
  - 药房：扫码履约/凭证上传/PO与提现
  - 平台：差价盈利/质量监管/合规风控
- 核心链路（摘要）：开方→支付→生成QR→药房扫码履约→凭证→审核→结算→对账。

## 开发路线（九阶段框架，里程碑化）
- 仅保留阶段目标与同步点，实施细节在 PRPs：
  - TASK01 环境与工具链（同步点A）
  - TASK02 数据库与RLS（同步点B）
  - TASK03-04 Auth与权限（同步点C）
  - TASK05 处方核心（同步点D）
  - TASK06 支付与财务精度（同步点E）
  - TASK07 QR与履约（同步点F）
  - TASK08 审核工作台（同步点G）
  - TASK09 结算与提现（同步点H）

## Checkpoint 机制（职责提炼）
| 检查点 | 重点评审 | 关键交付 |
|---|---|---|
| CP1 架构/认证 | Schema覆盖、Auth方案、错误/日志策略 | Schema 终稿、Auth/OpenAPI 草案 |
| CP2 数据/账户 | 账户/药品API、审计日志 | Demo/API规范、审计记录样例 |
| CP3 核心支付 | 原子性扣款、并发/幂等、状态流转 | 压测报告、日志与对账证据 |
| CP4 闭环联调 | 端到端链路、文件/通知、P0/P1就绪 | 集成 Demo、OpenAPI 终稿 |

- 评审仅验证“达标与否”，不在此文落实现步骤。

## 质量门槛与 KPI（战略门控）
- 技术门槛（建议）：
  - 性能：API 响应 P95 < 500ms
  - 可用性：≥ 99.9%
  - 测试：单元覆盖率 ≥ 80%，核心业务/事务场景全覆盖
  - 安全：OWASP 基线通过；Secrets/日志脱敏；RLS 覆盖
  - 数据：迁移/回滚安全；类型与客户端一致（types/database.types.ts）
- 业务 KPI（示例）：
  - 订单履约率、药房结算时效、异常重试成功率、对账准确率

## 风险与缓解（执行期关注）
- 合规/隐私：禁止患者 PII；处方匿名化；审计与留痕
- 支付风控：原子性/幂等/补偿；额度与限频；异常对账
- AI 识别（如OCR）：设阈值与人工回退；失败降级不阻断主链路
- 性能与扩展：索引/缓存/负载能力；退化策略与压测基线

## 状态机/退款规则（仅指针）
- 状态/流转/退款等统一在 APIdocs/APIv1.md 定义与维护（变更在 APIv1_log.md）；本文件不复述。

## 链接索引
- INITIAL.md（冻结）
- PRPs/（当前执行 PRP 与历史版本）
- APIdocs/APIv1.md 与 APIdocs/APIv1_log.md（唯一 API 真源）
- examples/（脚手架与模式）
- prd-reverse-engineering/old_docs/（里程碑/门槛/KPI 的历史参考）