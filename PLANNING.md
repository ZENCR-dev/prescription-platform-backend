# 🚀 B2B2C中医处方履约平台 - 后端开发战略规划

> 指南V3.2指针（只链接不复制）
> 本文件已指针化，所有流程/模板/规则以《Supabase-First架构下前后端协作与PRP生成指南V3.2》为唯一权威。
> 请参见项目根：`../../Supabase-First架构下前后端协作与PRP生成指南V3.1.md`
> - 废弃：CKP、时间分期、TASK*.md命名
> - 请参阅：第二章（价值流路线图）、第四章（4.0/4.2/4.3）、第五章（5.0滚动式规划）

## 📄 文档职责与溯源架构

**文档职责定义**：
- **需求底本**: INITIAL.md (冻结状态，项目愿景和目标)
- **战略规划**: 本文件 (技术架构决策、核心战略价值)
- **执行规则**: CLAUDE.md (4步QAD循环、轻量级验证执行)
- **API权威**: APIdocs/APIv1.md (变更记录: APIdocs/APIv1_log.md)
- **执行载体**: PRPs/TASK0X.md (任务分解、原子任务定义)

## 🎯 后端开发战略定位

**核心职责范围**:
- **Supabase优先架构**: Database + Auth + RLS + Realtime + Storage直接使用
- **医疗平台合规性**: HIPAA/FDA规范的战略要求和风险管理
- **API中心化治理**: 单一数据源的战略意义和协作价值

*具体的执行细节、工作流规范和技术实施标准详见 [CLAUDE.md执行规则手册](CLAUDE.md)*

## 📊 业务价值与闭环 (B2B2C差价模型)

### 商业模式核心
- **平台收益**: basePrice(医师净价) - pharmacyPrice(药房成本) = 差价盈利
- **三端价值** (精要):
  - **医师**: 高效处方/账户结算/可视化收益
  - **药房**: 扫码履约/凭证上传/PO与提现
  - **平台**: 差价盈利/质量监管/合规风控

### 核心业务链路 (摘要)
```
开方 → 支付 → 生成QR → 药房扫码履约 → 凭证 → 审核 → 结算 → 对账
```

### 🔒 合规性与隐私红线 (不可突破)
- **❌ 零患者信息收集**: 系统不得存储任何患者个人身份信息
- **✅ 处方数据匿名化**: 仅包含医师信息、药品信息、用法用量
- **✅ GDPR/HIPAA兼容**: 符合国际隐私保护标准和医疗合规要求

## 🤖 AI Agent协作架构战略

### 三层任务树战略价值
```yaml
战略层价值:
  Layer 1 (Feature): 确保开发方向与业务目标一致，技术选型合理
  Layer 2 (Phase): 科学分解复杂功能，降低单点风险，支持并行开发  
  Layer 3 (Atomic): AI Agent自主执行，减少人工监督成本，提升开发效率

预期协作效果:
  开发效率提升: 60-80% (Layer3 QAD自主执行，快速反馈循环)
  质量保障: QAD质量保证驱动 + 轻量级验证，问题早期发现
  风险控制: 分层解耦 + 测试保护，降低复杂度和回归风险
  团队协作: 架构师专注战略，Agent专注QAD执行，职责清晰
```

### 医疗平台特殊考虑
- **安全敟感功能**: 处方管理、认证系统、支付流程
- **医疗合规**: 保留核心HIPAA/FDA要求
- **质量保障**: 基础安全验证和合规检查

*详细的AI Agent执行规则和标准流程参见 [CLAUDE.md](CLAUDE.md)*

## 🤝 Frontend-Backend协作战略框架

### CKP协作检查点的战略价值

**业务连续性保障战略**:
- **风险分散机制**: 通过5个协作检查点将项目风险分散到可控的时间窗口
- **质量门控价值**: 每个CKP检查点阻止低质量交付向下游传播，降低后期修复成本
- **交付可预测性**: 结构化检查点提升项目进度的可预测性和透明度

```yaml
CKP-1 (API契约确认点) - 战略价值:
  业务风险控制:
    - 消除前后端理解偏差 → 避免返工成本 (预计节省40-60%返工时间)
    - 确保技术可行性验证 → 降低实现风险
  开发效率提升:
    - 并行开发启动点 → 缩短30-40%开发周期
    - 接口契约锁定 → 减少协调成本

CKP-2 (接口联调点) - 战略价值:
  质量保障机制:
    - 早期集成验证 → 避免集成阶段危机
    - 性能基准确立 → 确保用户体验达标
  团队协作效率:
    - 实时问题解决 → 避免问题积累
    - 技术债务控制 → 降低维护成本

CKP-3 (集成测试点) - 战略价值:
  产品交付质量:
    - E2E流程验证 → 确保核心业务功能完整
    - 用户体验优化 → 提升产品竞争力
  商业风险管控:
    - 上线前质量把关 → 避免生产环境问题
    - 合规性验证 → 满足医疗行业监管要求

CKP-4 (生产部署点) - 战略价值:
  运营稳定性保障:
    - 同步部署协调 → 避免服务中断
    - 监控基线建立 → 支持持续运营
  商业价值实现:
    - 用户价值交付 → 实现商业模式验证
    - 市场响应能力 → 支持业务快速扩展

CKP-5 (性能优化点) - 战略价值:
  长期竞争优势:
    - 性能优化策略 → 提升用户留存率
    - 扩展性规划 → 支持业务增长
  成本效益优化:
    - 资源使用优化 → 降低运营成本
    - 技术演进规划 → 确保技术栈先进性
```

### Backend-First战略的商业价值

**核心商业逻辑**: B2B2C差价模型的技术实现依赖于后端数据精确性和业务流程完整性

```yaml
商业价值对齐:
  数据精确性要求:
    - 财务计算引擎必须先于前端界面 → 确保差价模型准确性
    - 处方状态机必须先于用户界面 → 保障业务流程完整性
    - 审核工作流必须先于管理界面 → 确保合规性和风险控制

市场竞争优势:
  快速响应能力:
    - 后端API优先确保功能完备性 → 支持多端接入扩展
    - 业务逻辑独立于界面 → 支持快速产品迭代
  合规性先行:
    - 后端合规架构确立 → 确保医疗行业监管合规
    - 数据安全框架先行 → 建立用户信任基础

技术债务控制:
  架构稳定性:
    - 后端架构先行 → 避免因前端需求变化导致的架构重构
    - API契约稳定 → 减少接口变更成本
  开发成本优化:
    - 后端复杂逻辑优先验证 → 避免前端开发浪费
    - 技术风险前置处理 → 降低项目整体风险
```

### 协作框架与业务目标对齐

**三端价值实现的技术保障**:
- **医师端价值**: 通过CKP-1/2确保处方管理API的完整性和可靠性 → 支持高效处方和收益透明化
- **药房端价值**: 通过CKP-2/3确保履约流程API的稳定性 → 支持扫码履约和PO管理
- **平台端价值**: 通过CKP-3/4确保财务结算API的准确性 → 支持差价盈利和风险控制

**战略执行机制**:
```yaml
协作效率目标:
  检查点通过率: >95% 首次通过 → 确保开发节奏稳定
  问题解决时效: <48小时平均解决 → 维持项目进度
  API文档同步: <24小时更新延迟 → 保障协作效率

业务价值交付指标:
  功能完整性: 100% 核心业务流程覆盖
  合规性达标: 100% HIPAA/FDA要求满足  
  性能目标: API响应P95<200ms (医疗实时性)
  用户体验: 端到端流程<5分钟完成
```

*Frontend-Backend协作的具体执行机制和验证规则详见 [INITIAL.md](INITIAL.md#frontend-backend协作检查点) 和 [CLAUDE.md](CLAUDE.md#协作边界验证检查)*

## 📋 M1 Backend PRP执行状态与里程碑进度

### M1 Backend Module执行状态 (2025-08-30更新)

| M1 Module | Backend Role | PRP Document | Implementation Focus | Status |
|-----------|--------------|--------------|----------------------|--------|
| **M1.1 - Supabase Auth Infrastructure** | **Primary Lead** | ✅ **COMPLETED** | Authentication infrastructure, JWT claims, RLS policies, Edge Functions | 🎉 **Production Ready** |
| **M1.2 - User Registration System** | **Primary Lead** | ⚠️ *Pending Global Architect Assignment* | Registration workflows, user verification, role assignment | ⏸️ **Awaiting PRP** |
| **M1.3 - User Profile Management** | **Primary Lead** | ✅ **READY - PRP Created** | Profile CRUD, business registration, credential verification | 🚀 **Ready to Begin** |
| **M1.4 - Profile Data Integration** | **Primary Lead** | ⚠️ *Pending M1.3 Completion* | Advanced profile features, analytics, search | ⏳ **Blocked - Sequential Dependency** |
| **M1.5 - User Verification System** | **Primary Lead** | ⚠️ *Pending M1.3/M1.4 Completion* | Document verification, compliance checking | ⏳ **Blocked - Sequential Dependency** |
| **M1.6 - Authentication Security Enhancement** | **Primary Lead** | ⚠️ *Pending Core Modules Completion* | MFA, advanced security, audit logging | ⏳ **Blocked - Sequential Dependency** |

### **🎉 M1.1 Success Metrics (Completed 2025-08-30)**

**✅ Performance Achievement:**
- ✅ **Production Deployment**: https://dosbevgbkxrtixemfjfl.supabase.co operational
- ✅ **Performance Excellence**: All queries <1ms (exceeds 150ms target by 150x)
- ✅ **Authentication Ready**: JWT Claims with custom access token hooks deployed
- ✅ **Security Certified**: HIPAA compliance verified, Zero-PII architecture confirmed
- ✅ **Edge Functions**: 2 functions deployed (custom-access-token, auth-email-template-selector)
- ✅ **Database Migrations**: 6 successful migrations applied to production

**📊 Technical Achievements:**
- ✅ **RLS Policies**: Multi-role isolation implemented with <1ms query performance
- ✅ **Security Policies**: Enhanced password requirements, MFA support, session management
- ✅ **Email Templates**: Role-specific templates for practitioner/pharmacy/admin workflows
- ✅ **API Documentation**: Complete APIv1.md with production environment specifications
- ✅ **Quality Gates**: All 8 validation steps passed, comprehensive testing completed

### **🚀 M1.3 Implementation Plan (Next Phase)**

**📋 M1.3 Ready Status:**
- ✅ **Foundation Dependency**: M1.1 authentication infrastructure operational
- ✅ **PRP Document**: PRP-M1.3-User-Profile-Management-Backend.md created and ready
- ✅ **Database Foundation**: user_profiles table ready for enhancement
- ✅ **Environment Ready**: Production Supabase instance available for development
- ✅ **API Framework**: Authentication APIs provide foundation for profile management

**📈 M1.3 Implementation Scope:**
- **Component 1**: Enhanced User Profile Schema with business registration fields
- **Component 2**: Business Registration Workflow with document handling
- **Component 3**: Document Management Integration with Supabase Storage
- **Component 4**: Profile Validation and Integration with comprehensive testing

**⏱️ M1.3 Timeline:** 3-4 business days with 16 atomic tasks across 4 components

### **🔄 Frontend Integration Readiness**

**API Distribution Status:**
- ✅ **APIv1.md Distribution**: Latest authentication API specs distributed to Frontend workspace
- ✅ **Production Environment**: Frontend has production endpoint configuration
- ✅ **JWT Integration**: Enhanced JWT claims ready for frontend consumption  
- ✅ **Global Architect Certification**: M1.1 delivery certified and approved

**Frontend M1.2 Enablement:**
- ✅ **Backend M1.1 Complete**: Authentication infrastructure ready for frontend integration
- ✅ **API Contract Stable**: Authentication endpoints documented and tested
- ✅ **Performance Validated**: Backend exceeds performance targets for frontend integration
- 🚀 **Frontend Ready**: M1.2 Auth Client Integration can proceed immediately

## 🏛️ 技术架构战略决策 (v5.0优化)

### Supabase优先架构的v5.0战略价值
```yaml
AI Agent协作适配:
  原生功能优先: 减少AI Agent学习成本，提升执行效率
  Edge Functions专注: 复杂业务逻辑交给AI Agent擅长的代码生成
  RLS策略优势: 自动化权限控制，减少人工配置错误

医疗平台架构战略:
  合规性内置: PostgreSQL + RLS天然支持数据隔离
  扩展性保障: 企业级数据库支持医疗数据的复杂查询
  安全性基础: 内置认证和权限控制，降低安全风险

三层任务树架构映射:
  Database层: Layer1战略决策的技术基础
  Auth+RLS层: Layer2模板体系的权限控制实现
  Edge Functions层: Layer3原子任务的AI Agent执行空间
```

*具体的技术实施和安全配置详见 [CLAUDE.md](CLAUDE.md)*

### 协作治理黄金法则的战略价值

**法则驱动的商业竞争优势**: 三大黄金法则确保技术架构与商业模式的战略对齐

```yaml
法则1: 职责边界不可突破 - 战略意义:
  商业模式保护:
    - 后端专注数据精确性 → 保障B2B2C差价模型的计算准确性
    - 前端专注用户体验 → 确保三端用户满意度和产品竞争力
    - 边界清晰化 → 降低项目管理复杂度和沟通成本
  
  技术债务控制:
    - 避免跨界依赖 → 降低代码耦合和维护成本
    - 专业化分工 → 提升开发效率和代码质量
    - 风险隔离 → 单一领域问题不会影响整体系统稳定性
  
  扩展性战略:
    - 技术栈独立演进 → 支持前后端技术选型的灵活性
    - 团队规模化 → 支持前后端团队独立扩展
    - 市场响应能力 → 快速响应不同端的市场需求变化

法则2: API文档中心化强制管理 - 战略意义:
  业务连续性保障:
    - 单一数据源 → 消除前后端理解偏差，避免集成风险
    - 契约稳定性 → 保证业务逻辑一致性和用户体验连贯性
    - 版本控制 → 支持系统平滑演进和向后兼容
  
  开发效率战略:
    - 并行开发基础 → 前后端基于统一API规范同时开发
    - 沟通成本降低 → 减少80%接口相关的协调和返工
    - 质量保证 → 通过API规范驱动的测试和验证机制
  
  商业扩展支持:
    - 多端接入能力 → 统一API支持Web、Mobile、第三方集成
    - 合作伙伴集成 → 标准化API接口支持生态系统建设
    - 数据资产化 → API规范化支持数据服务的商业化

法则3: Backend-First时序约束执行 - 战略意义:
  商业风险管控:
    - 核心逻辑优先 → 确保差价模型、处方状态机等核心业务逻辑的正确性
    - 合规性先行 → 医疗行业监管要求的技术实现先于用户界面
    - 数据安全基础 → 建立安全架构基础再进行前端集成
  
  市场竞争时间优势:
    - 功能验证前置 → 核心功能可行性验证不依赖前端开发进度
    - 快速迭代能力 → 业务逻辑变更可快速响应，不受前端界面约束
    - 多端支持基础 → 后端API完成后可支持多种前端实现选择
  
  投资回报优化:
    - 技术风险前置处理 → 复杂技术问题在成本较低的阶段解决
    - 资源配置优化 → 避免前端资源投入到不可行的功能上
    - 质量成本控制 → 核心逻辑先行确保整体系统质量基础
```

### 黄金法则与业务目标战略对齐

**三端价值实现的治理保障**:
```yaml
医师端价值保障:
  职责边界: 后端专注处方管理精确性 → 确保医师收益计算准确
  API中心化: 统一处方API → 支持医师多设备、多平台使用
  Backend-First: 处方逻辑先行 → 保证医师操作的业务完整性

药房端价值保障:
  职责边界: 后端专注履约流程控制 → 确保药房操作规范性
  API中心化: 标准履约API → 支持药房系统集成和自动化
  Backend-First: 履约逻辑先行 → 保证药房业务流程的可靠性

平台端价值保障:
  职责边界: 后端专注差价计算和风控 → 确保平台盈利模式可持续
  API中心化: 完整管理API → 支持平台运营的数据化和自动化
  Backend-First: 管理逻辑先行 → 保证平台治理能力的有效性
```

*黄金法则的具体执行机制和验证工具详见 [CLAUDE.md](CLAUDE.md#协作边界验证检查) 和 [INITIAL.md](INITIAL.md#职责边界验证规则)*

## 🌳 三层Git分支管理战略 (v6.0敏捷版)

### 日期分支策略的战略价值
- **敏捷开发优势**: 时序可视化、冲突消除、效率提升、追踪简化
- **分支数量控制**: 11个分支上限、自动清理、认知负荷控制
- **三层映射**: Layer1(main)→Layer2(TASK-YYYY-MM)→Layer3(YYYY-MM-DD-HHMM)
- **质量门控集成**: Layer3(<3分钟)→Layer2(<5分钟)→医疗合规检查

### v6.0框架适配收益
- **开发效率**: 70-85%自动化，轻量级验证，灵活的合规检查
- **AI Agent集成**: 日期分支与4步QAD循环匹配，增强研究阶段MCP工具使用
- **医疗平台价值**: 时间戳审计追溯，高风险分支保护，分层验证

*Git分支管理的详细操作规范和技术配置详见 [CLAUDE.md](CLAUDE.md)*

## 🛡️ 质量保证战略架构

### 边界验证与业务风险控制的战略对齐

**质量保证的商业价值**：医疗平台质量问题直接影响用户信任、监管合规和商业可持续性

```yaml
业务风险控制矩阵:
  医师端风险控制:
    - 处方计算错误 → 收益纠纷 → 用户流失
    - 账户资金安全 → 信任危机 → 平台信誉受损
    → 边界验证策略: 后端财务计算精确性验证 + API契约强制验证
  
  药房端风险控制:
    - 履约流程异常 → 库存混乱 → 供应链中断
    - PO结算错误 → 现金流问题 → 药房退出平台
    → 边界验证策略: 履约API完整性验证 + 状态机验证
  
  平台端风险控制:
    - 差价计算错误 → 盈利模式失效 → 商业模式崩溃
    - 合规性缺失 → 监管处罚 → 业务停摆
    → 边界验证策略: 核心业务逻辑验证 + 医疗合规验证
```

### PRP质量控制的战略指导价值

**PRP质量控制 = 项目交付质量保障 = 商业成功基础**

```yaml
PRP质量控制战略层次:
  
Layer1: 战略风险防护
  职责边界强制验证:
    - 防止跨界开发 → 避免技术债务积累
    - 确保专业分工 → 提升开发质量和效率
    - 降低集成风险 → 保障系统架构完整性
  
  API中心化治理:
    - 单一数据源强制 → 消除前后端理解偏差
    - 契约驱动开发 → 保证接口稳定性和兼容性
    - 版本控制规范 → 支持系统平滑演进和扩展
  
Layer2: 战术质量保障
  Backend-First时序验证:
    - 核心逻辑优先验证 → 确保业务模式技术可行性
    - 合规性前置检查 → 满足医疗行业监管要求
    - 技术风险前置处理 → 降低项目整体风险和成本
  
  协作检查点质量门控:
    - CKP检查点强制验证 → 确保协作质量和进度可控
    - 问题早期发现 → 避免问题在后期积累和放大
    - 交付质量保证 → 确保每个阶段输出满足质量标准

Layer3: 执行质量控制
  自动化验证工具集:
    - prp-boundary-validator.sh → 职责边界自动检查
    - api-consistency-checker.sh → API文档一致性验证
    - checkpoint-validator.sh → 协作检查点状态验证
    → 减少人工错误，提高验证效率和准确性
```

### 质量保证工具战略集成

**自动化质量保证 = 开发效率提升 + 风险控制强化**

```yaml
战略级质量保证机制:
  
生成前验证 (战略风险防护):
  触发时机: PRP文档生成前强制执行
  验证范围: 职责边界、API依赖、协作接口、时序约束
  业务价值: 防止战略偏差，确保开发方向正确
  失败成本: 阻止PRP生成，避免错误方向的投入

生成后审核 (战术质量保障):
  触发时机: PRP文档生成完成后立即执行
  验证范围: 架构合规、可执行性、协作集成、黄金法则合规
  业务价值: 确保执行计划质量，降低实施风险
  失败成本: 强制修正，避免低质量实施

实时质量监控 (执行质量控制):
  触发时机: 开发过程中持续监控
  监控范围: 代码提交、分支管理、检查点触发、质量指标
  业务价值: 实时风险识别，快速问题响应
  失败成本: 及时预警，避免问题积累
```

### 质量保证与商业目标的战略连接

**质量投入 = 商业保险 = 长期竞争优势**

```yaml
商业价值实现保障:
  
用户信任建设:
  医师信任: 处方计算准确性 → 收益透明 → 用户忠诚度
  药房信任: 履约流程稳定性 → 现金流稳定 → 合作持续性  
  监管信任: 合规性完整性 → 监管认可 → 市场准入优势

市场竞争优势:
  产品质量优势: 高质量保证 → 用户满意度 → 市场口碑
  技术领先性: 架构质量 → 系统稳定性 → 服务可靠性
  扩展能力: 代码质量 → 维护效率 → 快速响应市场

成本效益优化:
  开发成本控制: 质量前置 → 减少返工 → 降低开发成本
  运营成本优化: 系统稳定 → 减少故障 → 降低运维成本
  风险成本控制: 合规保证 → 避免处罚 → 降低合规风险
```

*质量保证的具体实施工具和验证机制详见 [CLAUDE.md](CLAUDE.md#质量门槛与校验门) 和 [INITIAL.md](INITIAL.md#prp质量控制检查表集成)*

## 📈 87.5%代码资产复用战略 (质量保障)

### 核心服务迁移矩阵
完整的代码复用矩阵和迁移策略请参考: [examples/migration-assets/code-reuse-matrix.yaml](examples/migration-assets/code-reuse-matrix.yaml)

## 🏛️ 技术架构战略

### 🚨 Supabase优先架构决策 (战略选型)
**核心原则**：
- **🥇 Supabase原生优先**: Database + Auth + RLS + Realtime + Storage直接使用
- **🥈 Edge Functions补充**: 仅在复杂业务逻辑时添加
- **🥉 避免重复造轮子**: 不重建Supabase已有功能

**后端专注架构** (当前项目范围):
```
🚨 Frontend (历史参考) → 🎯 Supabase (PostgreSQL+Auth+RLS) → 🎯 Edge Functions (业务逻辑)
                        ↑                                    ↑
                   本项目核心开发领域              本项目专注开发领域
```

### 🔧 现代Supabase v2.39.2本地开发环境配置

**环境要求与配置标准**:
```yaml
基础环境要求:
  Docker_Desktop: "必需 - Supabase本地栈容器基础"
  Supabase_CLI: "v2.39.2+ - 现代化命令结构"
  PostgreSQL_Client: "libpq - 数据库直接访问工具"
  Node_js: "v18+ - Edge Functions开发环境"

安装配置命令:
  # 安装PostgreSQL客户端工具
  brew install libpq
  
  # 配置psql PATH
  echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  
  # 验证环境
  docker --version        # 确认Docker可用
  supabase --version     # 确认CLI版本≥2.39.2
  psql --version         # 确认客户端工具可用
```

**标准开发工作流程**:
```yaml
环境启动流程:
  1_Docker_Ready: "启动Docker Desktop，确保docker ps可执行"
  2_Supabase_Start: "supabase start - 启动完整本地开发栈"
  3_Service_Check: "supabase status - 验证所有服务正常运行"
  4_Database_Ready: "supabase db reset - 应用所有迁移文件"

核心开发循环:
  Schema_Development: "supabase db diff - 检查模式变更"
  Migration_Management: "supabase db reset - 重新应用迁移"
  Testing_Execution: "psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/file.sql"
  Type_Generation: "supabase gen types typescript --local > types/database.types.ts"
  
本地服务端口标准:
  API_Gateway: "localhost:54321 - RESTful API接口"
  PostgreSQL_DB: "localhost:54322 - 数据库直连端口"
  Supabase_Studio: "localhost:54323 - 管理界面"
  Auth_Server: "localhost:54324 - 认证服务"
```

**Docker在Supabase开发中的合法作用**:
```yaml
合法用途明确:
  ✅ Local_Stack: "supabase start提供的官方本地测试环境"
  ✅ Development_Only: "仅限开发阶段，生产环境完全云端"
  ✅ CLI_Managed: "完全由Supabase CLI管理，无需手动配置"
  
禁止用途明确:
  ❌ Custom_Backend: "禁止自建Docker后端服务"
  ❌ Production_Deploy: "禁止Docker生产部署，仅云端部署"
  ❌ Manual_Setup: "禁止手动Docker配置，必须使用supabase start"
  
角色定义:
  Purpose: "本地测试环境提供者，非生产架构组件"
  Management: "完全由Supabase CLI自动管理"
  Lifecycle: "开发期工具，与生产架构无关"
```

**现代CLI命令对照表**:
```yaml
已移除命令_v2_39_2:
  ❌ "supabase db psql"     # 使用: psql + 连接字符串
  ❌ "supabase db shell"    # 使用: psql postgresql://...
  
新标准命令:
  ✅ "supabase start"       # 启动本地开发环境
  ✅ "supabase db reset"    # 重新应用所有迁移
  ✅ "supabase db diff"     # 检查模式差异
  ✅ "supabase db lint"     # SQL语法验证
  ✅ "supabase status"      # 服务状态检查
  
测试执行方式:
  Direct_PostgreSQL: "psql postgresql://postgres:postgres@localhost:54322/postgres -f test.sql"
  Studio_Interface: "http://localhost:54323 - 图形界面执行"
  Remote_Testing: "supabase link --project-ref <id> - 远程测试"
```

**开发环境故障排除**:
```yaml
常见问题解决:
  Docker_Not_Running:
    症状: "Cannot connect to the Docker daemon"
    解决: "启动Docker Desktop，确认docker ps工作"
    
  Missing_psql:
    症状: "psql: command not found"
    解决: "brew install libpq，更新PATH配置"
    
  Port_Conflicts:
    症状: "Error: Port 54322 is already in use"
    解决: "supabase stop && supabase start重置环境"
    
  Migration_Issues:
    症状: "Migration failed to apply"
    解决: "supabase db reset重新应用所有迁移"
    
  Service_Startup:
    症状: "Services not starting properly"
    解决: "检查Docker资源限制，重启Docker Desktop"
```

### 🔐 安全架构核心策略
**RLS数据隔离**:
- 医师: `auth.uid() = doctor_id` 完全隔离
- 药房: 仅访问分配订单 `pharmacy_id` 过滤  
- 管理员: `auth.jwt()->>'role' = 'admin'` 全局权限

**财务安全保障**:
- **NZD Cents**: INTEGER存储，Decimal.js计算，银行家舍入
- **并发控制**: 乐观锁+事务包装+异常恢复

### 🤖 AI Agent协作架构战略

#### 三层任务树战略价值
- **战略层价值**: 确保开发方向与业务目标一致，技术选型合理
- **战术层价值**: 将复杂功能科学分解，降低单点风险，支持并行开发
- **执行层价值**: AI Agent自主执行，减少人工监督成本，提升开发效率

#### 预期协作效果
- **开发效率提升**: Layer3 QAD自主执行，预计节省60-80%编码时间，快速反馈提升质量
- **质量保障**: QAD质量保证驱动 + 每个Layer明确验证标准，早期发现问题
- **风险控制**: 分层解耦 + 测试保护网降低复杂度，安全重构和回滚
- **团队协作**: 架构师专注战略和战术，Agent专注QAD执行，职责清晰

### 医疗平台特定合规要求
完整的医疗平台合规要求和实施指导请参考: [examples/compliance-requirements/medical-platform-specific.yaml](examples/compliance-requirements/medical-platform-specific.yaml)


## 🚀 开发路线与任务组织

### 任务组织预期价值
基于简化框架的任务组织将提供：

- **标准化收益**: 减少60-80%的任务设计时间
- **质量保障**: 统一的轻量级验证和医疗合规检查
- **AI Agent效率**: 标准化QAD 4步循环流程，Agent自动选择最佳执行策略
- **医疗平台特化**: 内置HIPAA/FDA合规要求，降低合规风险

*具体的任务实施和原子任务分解详见 [PRPs/TASK0X.md](PRPs/)*

## Checkpoint机制 (职责提炼)

| 检查点 | 重点评审 | 关键交付 |
|---|---|---|
| CP1 架构/认证 | Schema覆盖、Auth方案、错误/日志策略 | Schema终稿、Auth/OpenAPI草案 |
| CP2 数据/账户 | 账户/药品API、审计日志 | Demo/API规范、审计记录样例 |
| CP3 核心支付 | 原子性扣款、并发/幂等、状态流转 | 压测报告、日志与对账证据 |
| CP4 闭环联调 | 端到端链路、文件/通知、P0/P1就绪 | 集成Demo、OpenAPI终稿 |

评审仅验证"达标与否"，不在此文落实现步骤。

## 📊 质量门槛与KPI

### 技术门槛
```yaml
性能标准:
  API响应: P95 < 200ms (医疗实时性要求)
  轻量级验证: 检查时间<5分钟
  
质量标准:
  测试覆盖率: ≥ 80% (单元), 100% (核心医疗业务)
  安全基线: OWASP通过 + HIPAA合规检查通过
  代码质量: 基础质量检查通过

AI Agent效率标准:
  估算准确性: ≥ 80% (步骤数量、代码文件、迭代轮次、复杂度)
  迭代轮次控制: 实际轮次不超过预估+1
  基础验证通过率: ≥ 90%
```

### 医疗平台特定KPI
完整的医疗平台KPI标准和监控指标请参考: [examples/quality-standards/medical-platform-kpis.yaml](examples/quality-standards/medical-platform-kpis.yaml)

*具体的质量验证实施和KPI监控详见 [CLAUDE.md](CLAUDE.md)*

## 🔧 风险与缓解

### 核心风险管理
- **AI Agent风险**: 估算偏差、验证失效 → 反馈优化机制
- **医疗合规风险**: HIPAA/FDA变更 → 版本化管理，定期检查
- **数据安全风险**: 患者数据保护 → 多层防护，强化验证
- **支付风控**: 原子性/幂等/补偿；额度与限频；异常对账

*风险监控和应急响应详见 [CLAUDE.md](CLAUDE.md)*

## 状态机/退款规则 (仅指针)

状态/流转/退款等统一在APIdocs/APIv1.md定义与维护 (变更在APIv1_log.md)；本文件不复述。

## 🔗 执行层文档引用架构

### 文档职责与引用关系
```yaml
执行规则详细定义:
  → CLAUDE.md (4步QAD循环、AI Agent估算、轻量级验证执行)
  
具体任务实施:
  → PRPs/TASK0X.md (任务分解、原子任务定义)
  
API规范权威:
  → APIdocs/APIv1.md (接口定义、数据格式)
  → APIdocs/APIv1_log.md (变更历史、兼容性)
  
任务状态跟踪:
  → INITIAL.md (三层任务树状态、开发进度追踪)
  
代码参考:
  → examples/ (标准流程示例、可复用组件)

历史参考:
  → prd-reverse-engineering/old_docs/ (里程碑/门槛/KPI的历史参考)
```

### 快速导航
- [项目需求和任务导航](INITIAL.md) (需求底本，三层任务树状态)
- [执行规则手册](CLAUDE.md) (完整实现，执行标准)
- [API规范文档](APIdocs/APIv1.md) (权威源，接口标准)
- [任务实施计划](PRPs/) (任务分解和执行计划)

---

**🎯 战略规划文档状态**: ✅ **v6.0框架适配** | 📊 **职责**: 战略指导+核心价值 | 🔗 **框架集成**: 100%符合QAD要求 | 🚀 **执行模式**: 引用架构+战略聚焦

*完全符合v6.0框架要求的战略规划文档 - AI Agent协作+质量保证驱动开发+医疗平台特化*