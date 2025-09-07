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

## 紧急修复记录 - 2025-09-07

### M1.3B 联调环境视图缺失修复
**问题**: 前端IRG测试被"后端视图未部署"阻断  
**根因**: 联调环境缺失三个受控视图（v_profiles_tcm_context, v_profiles_pharmacy_context, v_profiles_public）  
**修复**: 创建完整部署脚本和验证工具链  

### 部署文件创建
| 文件 | 目的 | 状态 |
|------|------|------|
| deploy_views_to_integration.sql | 完整视图部署（含Helper函数+security_barrier+权限） | ✅ 已创建 |
| verify_integration_views.sql | 架构师要求的七类验证查询 | ✅ 已创建 |
| integration_behavioral_test.sql | 四用例行为测试（正例>0/负例=0） | ✅ 已创建 |
| INTEGRATION_DEPLOYMENT_INSTRUCTIONS.md | 完整部署指令和故障排除 | ✅ 已创建 |

### 架构师质量门
- **存在性**: 三视图在public schema ⏳ 待部署验证
- **安全屏障**: security_barrier=true ⏳ 待部署验证  
- **列集**: 17个非PII字段（6+6+5） ⏳ 待部署验证
- **Helper安全**: SECURITY DEFINER + STABLE + 固定search_path ⏳ 待部署验证
- **权限**: authenticated角色SELECT权限 ⏳ 待部署验证
- **行为**: 四用例通过（正>0/负=0/公=2） ⏳ 待部署验证

### 待执行操作
1. **部署脚本到联调实例**: 执行deploy_views_to_integration.sql
2. **运行验证和测试**: 收集integration_evidence.txt
3. **前端IRG重启通知**: "联调实例三视图已部署并通过四用例，证据已追加"
4. **Git合并**: 2025-09-05 → M1.3（架构师PASS后执行）

### 证据链接
- **技术证据**: test-evidence/Dev-Step-3-Behavioral-Evidence.md（已追加联调修复记录）
- **部署脚本**: 根目录deploy_*.sql文件
- **IRG基线**: 四用例模式与正负例验证标准

### 部署成功记录 - 2025-09-07 02:08-02:09
**执行状态**: ✅ **DEPLOYED** - 联调环境三视图部署完成并通过验证  
**质量门**: ✅ 所有架构师要求的7项质量门全部通过  
**行为测试**: ✅ 四用例测试结果符合预期（正例=2, 负例=0, 公共=2）  

### 架构师验证摘要 (Integration Environment Evidence)
```
VIEW_EXISTENCE: 3 views in public schema ✅
SECURITY_BARRIERS: security_barrier=true on all views ✅  
COLUMN_SETS: 17 non-PII fields (6+6+5) ✅
HELPER_SECURITY: SECURITY DEFINER + STABLE + fixed search_path ✅
PERMISSIONS: authenticated SELECT on all views ✅
BEHAVIORAL_TESTS: 
- Pharmacy→TCM Positive: COUNT=2 (>0) ✅
- Non-existent→TCM Negative: COUNT=0 (=0) ✅  
- TCM→Pharmacy Positive: COUNT=2 (>0) ✅
- Non-existent→Pharmacy Negative: COUNT=0 (=0) ✅
- Public Directory: COUNT=2 (=2, is_public_profile=true only) ✅
```

**前端IRG重启就绪**: ✅ 联调实例三视图已部署并通过四用例，证据已追加

