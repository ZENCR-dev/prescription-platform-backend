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

### 最小执行单元 (v5.0框架)
- **粒度要求**: 1.5-2.5小时可完成的原子任务
- **开发循环**: 3+1简化循环 → 需求分析与设计 → 实现与自测 → 集成准备 → 质量验证与提交

### 持久化要求
- **任务拆分**: 写入PRPs/<feature>_vN.md或progress.md
- **状态更新**: 每次执行完一个原子任务，更新状态与验证结果

### TASK文档Wave/Loop模式标识规范
在每个TASK文档头部添加:
```yaml
**Wave Mode Eligible**: ✅/❌ (复杂度评分说明)
**Loop Mode Applicable**: ✅/❌ (迭代优化场景)
```

## 🤖 Layer3: Agent自主执行3+1简化循环 (v5.0框架)

当Agent接收到Layer2文档中的原子任务时，自动启动以下简化循环：

### 标准3+1简化开发循环

1. **需求分析与设计** (主实现角色: frontend/backend)
   - 理解任务需求，设计实现方案 → TodoWrite(设计方案)

2. **实现与自测** (同一主实现角色)
   - 编写核心代码，执行基础测试 → TodoWrite(实现清单)

3. **集成准备** (同一主实现角色)
   - 代码格式化，准备集成接口 → TodoWrite(集成准备)

4. **质量验证与提交** (qa角色)
   - 验证功能完整性，执行Git提交 → TodoWrite(验证清单)

### Agent执行原则 (v5.0框架优化)

- **单一主角色**: 前3步由同一主实现角色(frontend/backend)负责，降低角色切换成本
- **TodoWrite驱动**: 每步开始前使用TodoWrite工具制定具体执行计划
- **质量上移**: 安全、性能、重构检查移至Layer2智能质量门控，原子任务仅保留基础检查
- **原子任务**: 每个原子任务控制在1.5-2.5小时内完成
- **简化验证**: 原子任务级别仅进行代码规范、基础功能测试、集成准备检查

## 🌊 SuperClaude Wave/Loop模式集成 (医疗平台专用)

### Wave模式 - 复杂医疗工作流编排

**定义**: Wave模式是SuperClaude的多阶段复合智能执行机制，专门处理医疗平台的复杂业务流程。

**医疗平台触发条件**:
```yaml
医疗复杂度评分 (Healthcare Complexity Score):
  处方流程复杂度: >0.7 (涉及医生开方、药师审核、保险验证)
  利益相关者数量: >=3 (医生、患者、药房、保险方)
  数据敏感级别: HIGH (患者隐私数据、处方信息)
  合规要求等级: CRITICAL (HIPAA、FDA规范)
  
自动触发公式:
  complexity_score = (workflow_complexity * 0.3) + 
                    (stakeholder_count * 0.2) + 
                    (data_sensitivity * 0.3) + 
                    (compliance_level * 0.2)
  
  当 complexity_score >= 0.7 时自动激活Wave模式
```

**Wave执行策略**:
1. **Progressive Wave (渐进式)**: 处方审批流程优化
2. **Systematic Wave (系统式)**: 全平台安全合规审计
3. **Adaptive Wave (自适应)**: 多角色协作功能开发
4. **Enterprise Wave (企业级)**: 大规模数据迁移与升级

**医疗场景示例 - 处方开具Wave流程**:
```bash
# Wave 1: 需求分析与合规验证
/sc:analyze --persona-security --focus compliance --seq
- 分析HIPAA合规要求
- 验证FDA处方规范
- 评估数据隐私风险

# Wave 2: 架构设计与安全建模
/sc:design --persona-architect --type workflow --seq --c7
- 设计多方验证流程
- 建立安全数据流
- 定义角色权限模型

# Wave 3: 核心功能实现
/sc:implement --persona-backend --type feature --safe --wave-mode
- 实现处方创建API
- 集成药品数据库
- 建立审核机制

# Wave 4: 安全与合规验证
/sc:test --persona-security --type compliance --seq
- HIPAA合规测试
- 数据加密验证
- 审计日志检查

# Wave 5: 性能与可靠性优化
/sc:improve --persona-performance --focus reliability --seq
- 处方处理性能优化
- 故障恢复机制
- 负载均衡配置
```

### Loop模式 - 医疗合规迭代优化

**定义**: Loop模式是SuperClaude的迭代改进机制，适用于医疗平台的持续合规和质量提升。

**医疗平台应用场景**:
1. **合规迭代**: HIPAA/FDA规范的持续符合性改进
2. **安全加固**: 患者数据保护的渐进式增强
3. **性能调优**: 处方处理速度的迭代优化
4. **用户体验**: 医患交互界面的持续改善

**Loop触发条件**:
```yaml
迭代改进指标:
  合规得分提升: 每轮提升5-10%直至95%+
  安全漏洞修复: 每轮减少security issues 20%+
  性能基准改善: 每轮响应时间降低10-15%
  代码质量提升: 每轮技术债务减少15%+
  
自动触发关键词:
  - "持续改进处方系统安全性"
  - "迭代优化患者数据保护"
  - "渐进式提升HIPAA合规性"
  - "循环改善医疗API性能"
```

**医疗场景示例 - 患者数据安全Loop优化**:
```bash
# 初始化Loop模式
/sc:analyze --persona-security --loop --iterations 3

# Loop 1: 基础安全评估
- 扫描现有安全漏洞
- 识别敏感数据暴露点
- 生成安全改进清单

# Loop 2: 安全加固实施
- 实施数据加密升级
- 增强访问控制机制
- 添加审计日志功能

# Loop 3: 合规验证与优化
- HIPAA合规性验证
- 性能影响评估
- 最终安全报告生成

# 自动终止条件
- 安全得分达到95%+
- 所有高危漏洞已修复
- 性能损耗<5%
```

### 医疗平台集成配置

**Wave/Loop模式配置文件** (建议添加到项目根目录):
```yaml
# .superclause-medical.yml
wave_config:
  medical_triggers:
    prescription_workflow:
      complexity_threshold: 0.7
      required_waves: 5
      stakeholders: [doctor, patient, pharmacy, insurance]
      
    compliance_audit:
      complexity_threshold: 0.8
      required_waves: 4
      compliance_standards: [HIPAA, FDA, STATE_REGULATIONS]
      
    data_migration:
      complexity_threshold: 0.9
      required_waves: 6
      data_sensitivity: CRITICAL
      
loop_config:
  medical_improvements:
    security_hardening:
      max_iterations: 5
      target_score: 95
      focus_areas: [encryption, access_control, audit_logs]
      
    performance_tuning:
      max_iterations: 4
      target_latency: 200ms
      critical_endpoints: [prescription_create, patient_lookup]
      
    compliance_enhancement:
      max_iterations: 3
      target_compliance: 100
      standards: [HIPAA, FDA]
```

### 与现有质量门控的集成

**智能触发机制**:
1. **Layer2质量门控触发Wave**: 当Comprehensive Gate检测到高复杂度时自动建议Wave模式
2. **Loop模式与质量门控联动**: 每个Loop迭代后自动触发相应级别的质量门控
3. **医疗特定门控**: 添加HIPAA合规检查、FDA规范验证到质量门控流程

**执行命令示例**:
```bash
# 自动检测并建议Wave模式
/sc:analyze --persona-architect --scope project
# 输出: "检测到处方系统复杂度0.82，建议使用Wave模式"

# 强制启用Wave模式
/sc:implement --wave-mode --wave-strategy systematic

# 启用Loop模式进行合规改进
/sc:improve --loop --iterations 3 --focus compliance
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