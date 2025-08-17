# Requirements Snapshot演进规则

## 🎯 目标和原则

### 核心目标
- **完整追溯性**: 每个PRP版本都能追溯到其需求来源和演进历史
- **变更可视性**: 清晰展示从v1到vN的所有关键变更
- **依赖透明性**: 明确当前版本对其他TASK和系统组件的依赖关系
- **合规连续性**: 确保医疗合规要求在版本演进中的完整传承

### 设计原则
1. **向前追溯**: 新版本必须包含到原始需求的完整路径
2. **增量记录**: 每个版本只记录相对于前一版本的变更
3. **依赖映射**: 明确记录版本间的依赖关系变化
4. **合规传承**: 医疗合规要求必须在所有版本中保持连续性

## 📋 Requirements Snapshot标准结构

### v1.0版本 (基础版本)
```markdown
## 🔗 Requirements Snapshot (v1.0)

**source**: INITIAL.md@<commit_hash>  
**api_source**: APIdocs/APIv1.md@<version>  
**planning_ref**: PLANNING.md@<commit_hash>  
**creation_date**: YYYY-MM-DD

### 核心约束
- [从INITIAL.md继承的核心技术和业务约束]

### 成功标准
- [从INITIAL.md继承的成功标准]

### 非目标(OOS)
- [从INITIAL.md继承的排除项]
```

### v2.0+版本 (演进版本)
```markdown
## 🔗 Requirements Snapshot (v{N}.0)

**source**: INITIAL.md@<commit_hash>, Delta@v{N-1}.0→v{N}.0  
**api_source**: APIdocs/APIv1.md@<version>  
**planning_ref**: PLANNING.md@<commit_hash>  
**previous_version**: PRPs/TASK{XX}_v{N-1}.md@<commit_hash>  
**creation_date**: YYYY-MM-DD  
**change_trigger**: [业务需求变更/技术约束调整/合规要求更新/架构优化]

### 版本演进路径
```
v1.0 → v2.0 → ... → v{N}.0
 │      │            │
 │      │            └─ 当前版本
 │      └─ [简要变更描述]
 └─ 原始版本
```

### 核心约束 (v{N}.0)
**继承约束**:
- [从v{N-1}.0继承且未变更的约束]

**新增约束**:
- [v{N}.0新增的约束]

**修改约束**:
- [原约束] → [修改后约束]

**移除约束**:
- ~~[被移除的约束]~~ (移除原因: XXX)

### 成功标准 (v{N}.0)
**继承标准**:
- [从v{N-1}.0继承且未变更的标准]

**新增标准**:
- [v{N}.0新增的成功标准]

**修改标准**:
- [原标准] → [修改后标准]

**移除标准**:
- ~~[被移除的标准]~~ (移除原因: XXX)

### 非目标(OOS) (v{N}.0)
**继承排除项**:
- [从v{N-1}.0继承的排除项]

**新增排除项**:
- [v{N}.0新增的排除项]

**移除排除项** (现在包含在范围内):
- ~~[不再排除的项目]~~ (纳入原因: XXX)
```

## 🔄 演进规则详解

### 1. 源追溯规则
```yaml
基础版本(v1.0):
  source_priority:
    1: INITIAL.md@commit_hash (主要需求来源)
    2: APIdocs/APIv1.md@version (API规范)
    3: PLANNING.md@commit_hash (战略上下文)

演进版本(v2.0+):
  source_priority:
    1: Delta@v{N-1}.0→v{N}.0 (主要变更来源)
    2: INITIAL.md@commit_hash (原始需求底本)
    3: APIdocs/APIv1.md@version (更新的API规范)
    4: PLANNING.md@commit_hash (战略上下文)
    5: previous_version (前一版本完整信息)
```

### 2. 变更追踪规则
```yaml
继承规则:
  - 前一版本的所有约束默认继承
  - 仅明确变更的项目需要特别标注
  - 继承项目无需重复详细描述

变更标注:
  新增: 使用"新增约束/标准/排除项"分类
  修改: 使用"原项目 → 新项目"格式
  移除: 使用"~~删除线~~"格式并说明原因

变更原因:
  - 每个变更都必须包含clear的原因说明
  - 原因应追溯到Delta段的具体分析
  - 必须标明是否为外部强制要求
```

### 3. 依赖关系演进
```yaml
依赖映射:
  task_dependencies:
    - TASK{XX}: [依赖类型变化描述]
    - TASK{YY}: [新增/移除/修改的依赖关系]
  
  api_dependencies:
    - endpoint_new: [新增的API依赖]
    - endpoint_modified: [修改的API依赖]
    - endpoint_removed: [移除的API依赖]
  
  database_dependencies:
    - table_new: [新增的数据表依赖]
    - table_modified: [修改的数据表依赖]
    - schema_changes: [架构级变更的依赖影响]

外部依赖:
  compliance_dependencies:
    - HIPAA: [合规依赖的变化]
    - FDA: [监管要求的变化]
  
  technology_dependencies:
    - supabase: [技术栈依赖的变化]
    - third_party: [第三方服务依赖的变化]
```

### 4. 医疗合规传承规则
```yaml
合规要求继承:
  基础原则: 所有合规要求默认继承并增强
  例外情况: 仅当合规标准发生官方变更时才调整
  
HIPAA要求演进:
  数据加密: [从v{N-1}.0的基础上如何演进]
  访问控制: [权限管理的变更]
  审计日志: [日志要求的变化]
  
FDA要求演进:
  处方管理: [处方相关功能的合规演进]
  药物追溯: [追溯要求的变化]
  质量保证: [质量标准的演进]

合规验证:
  - 每个版本都必须包含完整的合规检查清单
  - 新增的合规要求必须有具体的实施计划
  - 合规要求的变更必须有监管依据
```

## 📊 版本兼容性管理

### 向后兼容性评估
```yaml
兼容性级别:
  COMPATIBLE: 完全兼容，可无缝切换
  COMPATIBLE_WITH_MIGRATION: 需要数据迁移但逻辑兼容
  BREAKING_CHANGES: 包含破坏性变更
  INCOMPATIBLE: 完全不兼容，需要重新实现

评估维度:
  api_compatibility: [API接口的兼容性级别]
  data_compatibility: [数据结构的兼容性级别]
  config_compatibility: [配置文件的兼容性级别]
  dependency_compatibility: [依赖关系的兼容性级别]
```

### 并行版本支持策略
```yaml
支持策略:
  current_version: v{N}.0 (当前开发版本)
  maintenance_version: v{N-1}.0 (维护版本，仅修复关键问题)
  deprecated_versions: v{N-2}.0及更早 (已废弃，不再支持)

切换策略:
  gradual_migration: 渐进式迁移，允许部分功能先行
  big_bang_migration: 一次性完整切换
  parallel_development: 并行开发，最终合并
```

## 🛠️ 实施工具和检查

### 自动化检查工具
```yaml
snapshot_validator:
  purpose: 验证Requirements Snapshot的完整性和一致性
  checks:
    - source_references: 所有引用的source都存在且可访问
    - version_continuity: 版本演进路径完整无缺失
    - constraint_inheritance: 约束继承规则正确执行
    - compliance_completeness: 医疗合规要求完整传承
    
change_impact_analyzer:
  purpose: 分析版本间变更的影响范围
  outputs:
    - affected_tasks: 受影响的其他TASK列表
    - api_changes: API变更的详细分析
    - database_impact: 数据库变更的影响评估
    - compliance_gap: 合规性差异分析
```

### 质量检查清单
```yaml
创建新版本时:
  - [ ] source引用格式正确且可验证
  - [ ] 版本演进路径清晰完整
  - [ ] 所有变更都有明确的Delta段支持
  - [ ] 医疗合规要求完整传承
  - [ ] 依赖关系变化准确记录
  - [ ] 兼容性级别正确评估

演进一致性检查:
  - [ ] 新增约束与INITIAL.md原始意图一致
  - [ ] 修改标准有充分的业务依据
  - [ ] 移除项目不影响核心功能目标
  - [ ] 合规要求没有降级或遗漏

文档质量检查:
  - [ ] 格式符合标准模板要求
  - [ ] 内容具体明确，避免模糊描述
  - [ ] 变更原因清晰可追溯
  - [ ] 依赖关系准确无遗漏
```

## 📈 使用示例

### 示例1: TASK01认证系统升级
```markdown
## 🔗 Requirements Snapshot (v2.0)

**source**: INITIAL.md@a1b2c3d, Delta@v1.0→v2.0  
**api_source**: APIdocs/APIv1.md@v2.1  
**planning_ref**: PLANNING.md@a1b2c3d  
**previous_version**: PRPs/TASK01_v1.md@x1y2z3w  
**creation_date**: 2025-01-17  
**change_trigger**: 业务需求变更 (双认证系统需求)

### 版本演进路径
```
v1.0 (Supabase Auth) → v2.0 (Supabase + Clerk双认证)
```

### 核心约束 (v2.0)
**继承约束**:
- Supabase作为主要后端架构
- 医疗数据HIPAA合规要求

**新增约束**:
- 支持Clerk第三方认证服务集成
- 双认证系统数据同步要求
- 认证故障时的降级策略

**修改约束**:
- 用户认证流程: [单一Supabase] → [Supabase + Clerk双重验证]
```

### 示例2: 合规要求驱动的版本升级
```markdown
**change_trigger**: 合规要求更新 (FDA药物追溯新规)

### 核心约束 (v3.0)
**继承约束**:
- [所有v2.0的技术和业务约束]

**新增约束**:
- 药物批次号完整追溯链记录
- 处方-药物-患者三级关联审计
- 7年数据保留要求

**成功标准 (v3.0)**:
**新增标准**:
- 100%药物批次可追溯到源头厂商
- 审计报告生成时间<30秒
- 数据完整性检查通过率>99.9%
```