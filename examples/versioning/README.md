# PRP版本化管理系统

## 🎯 概述

本目录包含完整的PRP版本化管理体系，实现CLAUDE.md第56行和INITIAL.md第7行规定的需求变更版本化规则："**需求变更：新建PRP版本(PRPs/<feature>_vN.md)，在Delta段描述变化与影响**"。

## 📁 目录结构

```
examples/versioning/
├── README.md                              # 本文件 - 系统概述和使用指南
├── delta-section-template.md              # Delta段标准模板
├── versioning-trigger-matrix.yaml         # 版本化触发条件评估矩阵
├── requirements-snapshot-evolution.md     # Requirements Snapshot演进规则
├── naming-and-storage-standards.md        # 版本化命名和存储标准
├── prp-versioning-template.md            # PRP版本化标准模板 (待创建)
├── task01-versioning-example/            # TASK01版本化完整示例 (待创建)
└── versioning-sop.md                     # 版本化操作标准流程 (待创建)
```

## 🚀 快速开始

### 1. 评估是否需要版本化
使用 `versioning-trigger-matrix.yaml` 评估您的变更是否需要创建新版本：

```yaml
# 评估您的变更
impact_scope: [1-5]        # 影响范围
change_magnitude: [1-5]    # 变更幅度  
requirements_source: [1-5] # 需求来源
api_impact: [1-5]         # API影响
database_impact: [1-5]    # 数据库影响
compliance_impact: [1-5]  # 合规影响

# 根据评分决策
score >= 4.0: MUST_VERSION      # 必须版本化
score >= 3.0: SHOULD_VERSION    # 强烈建议版本化
score >= 2.0: CONSIDER_VERSION  # 考虑版本化
score < 2.0:  UPDATE_CURRENT    # 更新当前版本
```

### 2. 创建新版本
如果决定创建新版本，按以下步骤操作：

1. **确定版本号**：根据 `naming-and-storage-standards.md` 确定新版本号
   - MAJOR版本 (v1.0→v2.0)：架构级变更、破坏性变更
   - MINOR版本 (v1.0→v1.1)：功能增强、兼容性变更

2. **创建文件**：按标准格式创建新版本文件
   ```bash
   cp PRPs/TASK01.md PRPs/TASK01_v2.0.md
   ```

3. **填写Delta段**：使用 `delta-section-template.md` 填写变更分析

4. **更新Requirements Snapshot**：按 `requirements-snapshot-evolution.md` 更新需求快照

### 3. 质量检查
确保新版本符合所有标准：

- [ ] 文件命名符合 `naming-and-storage-standards.md`
- [ ] Delta段按 `delta-section-template.md` 完整填写
- [ ] Requirements Snapshot按演进规则正确更新
- [ ] 所有依赖关系准确记录
- [ ] 医疗合规要求完整传承

## 📋 核心组件说明

### Delta段模板 (`delta-section-template.md`)
**作用**：标准化变更描述格式，确保所有版本间变更都有完整的影响分析。

**关键章节**：
- 变更概述：版本号、日期、原因、影响范围
- 具体变更项：新增/修改/删除功能的详细列表
- 影响分析：对依赖任务、API、数据库、合规性的具体影响
- 迁移路径：从旧版本到新版本的具体迁移策略

### 触发条件矩阵 (`versioning-trigger-matrix.yaml`)
**作用**：提供客观的评估框架，避免过度版本化或版本化不足。

**评估维度**：
- impact_scope：影响范围 (1=单任务内部 → 5=系统级)
- change_magnitude：变更幅度 (1=微调 → 5=架构级)
- requirements_source：需求来源 (1=技术优化 → 5=外部合规)
- api_impact：API影响 (1=无变更 → 5=重构)
- database_impact：数据库影响 (1=无变更 → 5=架构变更)
- compliance_impact：合规影响 (1=无影响 → 5=框架变更)

### Requirements Snapshot演进 (`requirements-snapshot-evolution.md`)
**作用**：确保需求追溯的完整性和版本间约束的正确传承。

**核心规则**：
- 源追溯：明确每个版本的需求来源
- 变更追踪：清晰记录约束、标准、排除项的演进
- 依赖关系：跟踪版本间和跨TASK的依赖变化
- 合规传承：确保医疗合规要求的连续性

### 命名存储标准 (`naming-and-storage-standards.md`)
**作用**：统一版本文件的命名、存储和管理策略。

**核心标准**：
- 文件命名：`TASK{NN}_v{MAJOR}.{MINOR}.md`
- 目录结构：主目录、归档目录、元数据管理
- Git集成：分支命名、标签管理、CI/CD支持
- 清理策略：自动归档、版本保留政策

## 🛠️ 实际使用场景

### 场景1：业务需求变更
```yaml
情况: TASK01需要从单一Supabase认证改为双认证系统
评估:
  impact_scope: 3 (跨Phase影响)
  change_magnitude: 4 (核心逻辑变更)
  requirements_source: 3 (业务需求调整)
  api_impact: 3 (API增强)
  database_impact: 2 (新增表)
  compliance_impact: 3 (新增合规要求)
决策: SHOULD_VERSION (score = 3.0)
操作: 创建TASK01_v2.0.md，详细记录双认证集成方案
```

### 场景2：合规要求更新
```yaml
情况: FDA要求新增药物批次追溯功能
评估:
  impact_scope: 4 (跨TASK影响)
  change_magnitude: 4 (核心逻辑变更)
  requirements_source: 5 (外部合规要求)
  api_impact: 4 (API重大修改)
  database_impact: 4 (表结构重构)
  compliance_impact: 5 (合规框架变更)
决策: MUST_VERSION (score = 4.25)
操作: 立即创建新版本，启动合规评估流程
```

### 场景3：性能优化
```yaml
情况: 优化数据库查询性能，减少响应时间
评估:
  impact_scope: 1 (单任务内部)
  change_magnitude: 2 (功能优化)
  requirements_source: 1 (技术优化)
  api_impact: 1 (无API变更)
  database_impact: 2 (优化查询)
  compliance_impact: 1 (无合规影响)
决策: UPDATE_CURRENT (score = 1.35)
操作: 直接更新当前PRP，无需版本化
```

## 📊 版本管理最佳实践

### 版本创建时机
- **立即版本化**：外部合规要求、架构级变更、破坏性API变更
- **计划版本化**：重大功能变更、跨任务影响、数据库重构
- **评估版本化**：功能增强、性能优化、中等范围变更
- **无需版本化**：微调优化、bug修复、局部改进

### 版本维护策略
- **活跃维护**：当前版本 + 前一个MAJOR版本
- **被动维护**：仅修复关键问题
- **归档管理**：超过6个月的版本自动归档
- **定期清理**：2年以上仅保留里程碑版本

### 质量保证
- **创建前检查**：触发条件评估、版本号规划、影响分析
- **创建时验证**：模板完整性、格式规范性、内容准确性
- **创建后监控**：使用效果、维护成本、团队反馈

## 🔗 相关文档

- **CLAUDE.md第56行**：PRP版本化规则的原始定义
- **INITIAL.md第7行**：需求变更管理的总体原则
- **PRPs/templates/Layer2-Standard-Template.md**：基础PRP模板
- **examples/workflow-templates/3+1-steps-template.yaml**：执行工作流模板

## 📞 支持和反馈

如果在使用过程中遇到问题或有改进建议，请：

1. 检查相关文档是否有解答
2. 查看 `task01-versioning-example/` 中的完整示例
3. 参考 `versioning-sop.md` 中的操作流程
4. 联系项目架构师获得支持

---

**最后更新**：2025-01-17  
**版本**：v1.0  
**维护者**：项目架构团队