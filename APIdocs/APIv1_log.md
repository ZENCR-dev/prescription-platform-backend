# APIv1_log.md - Backend Development API Implementation Log (索引版)

## 执行摘要（固定6项）
- 运行版本: v1.0.0-beta-secfix
- 实施阶段: M1 核心认证与用户管理
- 状态: 生产运行中（Supabase Cloud）
- 安全断言: 认证链、Zero-PII、会话同步 全部通过
- 性能阈值: license-verification P95 ≤ 400ms（监控生效）
- 运行冻结: license-verification v2、validate-session v2 已冻结

## 快速链接
- 规范单一来源: APIdocs/APIv1.md
- 归档详文: APIdocs/APIv1_log/2025-09/M1.1-archive.md
- 监控仪表盘: https://supabase.com/dashboard/project/dosbevgbkxrtixemfjfl/functions/license-verification/metrics

## 里程碑速览（近30天）
| 日期 | 组件 | 变更要点 | 影响 |
|---|---|---|---|
| 2025-09-04 | UAT/冻结 | 三断言通过、运行冻结、阈值启用 | 解锁 M1.2 前端集成 |
| 2025-09-03 | 安全修复 | JWT身份链、RLS转发、去除body.user_id | 关闭越权/假冒风险 |
| 2025-09-02 | 执行与部署 | license-verification 上线、性能基线 | 达成医用P95门槛 |
| 2025-08-30 | 首次上线 | 迁移+函数+RLS 生产部署 | 生产可用 |

更多细节请见归档详文。

## 证据锚点（代码定位）
| 文件 | 定位 | 目的/断言 |
|---|---|---|
| supabase/functions/license-verification/index.ts | RLS查询(433-437)、所有权校验(452-460) | 仅资源所有者可见 |
| supabase/functions/license-verification/index.ts | JWT门禁(494-508)、Service role创建(541-546) | 鉴权后内部状态流转 |
| supabase/functions/license-verification/index.ts | 去除body.user_id(514-517)、零PII日志(604-610) | 防注入与合规 |

## 运维基线（统一定义）
- 阈值: P95 ≤ 400ms；P99 ≤ 500ms 警戒
- 报警: 连续3个5分钟窗口超阈触发
- 区域: ap-southeast-2（生产）；区域/配置变动见归档

## 变更记录（三行体精简版）
- 2025-09-04 bfd214b M1.1 收尾与冻结 → 监控阈值激活
- 2025-09-03 secfix 强化鉴权/授权链 → 消除越权面
- 2025-09-02 deploy 上线与性能基线 → 满足医用阈值

— 本文件为执行索引。完整过程记录、长 YAML、示例与评估数据已迁移至归档文件，确保可追溯且不丢信息。

