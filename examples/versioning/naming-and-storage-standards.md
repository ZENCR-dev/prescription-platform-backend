# PRP版本化命名和存储标准

## 🎯 设计目标

### 核心目标
- **一致性**: 所有版本化PRP遵循统一的命名规范
- **可发现性**: 通过文件名即可理解版本关系和时间序列
- **可维护性**: 支持版本清理、归档和长期维护
- **集成性**: 与Git分支管理和CI/CD流程无缝集成

### 设计原则
1. **语义化版本**: 使用语义化版本号表达变更影响程度
2. **时间可追溯**: 文件名包含足够信息支持时间线重建
3. **冲突避免**: 命名规则避免并发开发时的文件冲突
4. **扩展性**: 支持未来可能的特殊版本类型

## 📁 文件命名规范

### 基础命名格式
```
TASK{NN}_v{MAJOR}.{MINOR}.md
```

#### 组成部分说明
```yaml
TASK{NN}:
  description: "任务编号，两位数字，前导零填充"
  examples: ["TASK01", "TASK05", "TASK15"]
  rules:
    - 保持与原始TASK编号一致
    - 跨项目迁移时编号保持不变
    
v{MAJOR}.{MINOR}:
  description: "语义化版本号"
  format: "v1.0, v1.1, v2.0, v2.1, ..."
  rules:
    - MAJOR: 重大功能变更、架构调整、不兼容变更
    - MINOR: 功能增强、兼容性变更、优化改进
    - 起始版本: v1.0 (对应原始TASK.md)

file_extension:
  format: ".md"
  description: "Markdown格式，保持与原始PRP一致"
```

### 命名示例
```yaml
标准版本:
  - "TASK01_v1.0.md"  # 原始版本 (对应TASK01.md)
  - "TASK01_v1.1.md"  # 小版本更新
  - "TASK01_v2.0.md"  # 重大版本更新
  - "TASK05_v1.0.md"  # TASK05的原始版本
  - "TASK05_v3.2.md"  # TASK05的第3个大版本，第2次小更新

特殊版本:
  - "TASK01_v2.0-hotfix.md"    # 热修复版本
  - "TASK03_v1.1-emergency.md" # 紧急版本
  - "TASK07_v2.0-compliance.md" # 合规驱动版本
```

### 版本号递增规则
```yaml
MAJOR版本递增 (X.0):
  triggers:
    - 架构级别的重大变更
    - API接口的破坏性变更  
    - 数据库schema的重构
    - 医疗合规框架的变更
    - INITIAL.md底本需求的重大调整
  examples:
    - v1.0 → v2.0: 从单一认证改为双认证系统
    - v2.0 → v3.0: 从Supabase迁移到混合架构

MINOR版本递增 (X.Y):
  triggers:
    - 功能增强和优化
    - 向后兼容的API变更
    - 新增非破坏性功能
    - 合规要求的增强
    - 性能优化和bug修复
  examples:
    - v1.0 → v1.1: 增加密码强度验证
    - v2.1 → v2.2: 优化认证响应时间
```

## 📂 目录结构和存储规范

### 标准目录结构
```
PRPs/
├── TASK01.md                    # 当前活跃版本 (软链接或拷贝)
├── TASK01_v1.0.md              # 历史版本
├── TASK01_v1.1.md              # 历史版本
├── TASK01_v2.0.md              # 历史版本 
├── TASK02.md                    # 当前活跃版本
├── TASK02_v1.0.md              # 历史版本
├── versions/                    # 版本管理目录
│   ├── active/                  # 当前活跃版本链接
│   │   ├── TASK01 -> ../TASK01_v2.1.md
│   │   └── TASK02 -> ../TASK02_v1.0.md  
│   ├── archived/                # 归档版本 (>6个月)
│   │   ├── TASK01_v1.0.md
│   │   └── TASK01_v1.1.md
│   └── metadata/                # 版本元数据
│       ├── TASK01_versions.yaml
│       └── TASK02_versions.yaml
└── templates/                   # 模板目录
    └── Layer2-Standard-Template.md
```

### 版本管理策略
```yaml
活跃版本管理:
  current_version:
    location: "PRPs/TASK{NN}.md"
    strategy: "软链接指向最新版本"
    purpose: "保持现有引用路径不变"
  
  latest_versions:
    location: "PRPs/TASK{NN}_v{X}.{Y}.md"
    retention: "最近3个版本保持在主目录"
    strategy: "便于快速访问和比较"

归档策略:
  archive_triggers:
    - 版本创建超过6个月
    - 该版本之后有3+个新版本
    - 主目录版本文件数>20个
  
  archive_location: "PRPs/versions/archived/"
  archive_format: "保持原文件名不变"
  access_method: "通过版本元数据索引访问"

清理策略:
  retention_policy:
    - 最新版本: 永久保留
    - 最近6个月: 全部保留
    - 6个月-2年: 保留MAJOR版本
    - 2年以上: 仅保留关键里程碑版本
  
  cleanup_automation:
    - 定期扫描超期版本
    - 自动移动到归档目录
    - 更新版本元数据索引
```

### 版本元数据管理
```yaml
metadata_file_format: "PRPs/versions/metadata/TASK{NN}_versions.yaml"

metadata_content:
  task_info:
    task_id: "TASK01"
    title: "Supabase Starter Kit集成和认证验证"
    current_version: "v2.1"
    
  version_history:
    - version: "v1.0"
      created: "2025-01-16"
      status: "archived"
      location: "versions/archived/TASK01_v1.0.md"
      change_summary: "原始版本"
      
    - version: "v1.1" 
      created: "2025-01-20"
      status: "archived"
      location: "versions/archived/TASK01_v1.1.md"
      change_summary: "增强密码验证"
      
    - version: "v2.0"
      created: "2025-01-25"
      status: "active"
      location: "TASK01_v2.0.md"
      change_summary: "双认证系统集成"
      
    - version: "v2.1"
      created: "2025-01-30"
      status: "current"
      location: "TASK01_v2.1.md" 
      change_summary: "认证性能优化"
      
  dependencies:
    current:
      - task: "TASK00"
        version: "v1.0"
        relationship: "depends_on"
      - task: "TASK02"  
        version: "v1.2"
        relationship: "feeds_into"
        
  compliance_tracking:
    hipaa_compliance: "validated"
    fda_compliance: "not_applicable"
    last_audit: "2025-01-30"
```

## 🔄 Git集成策略

### 分支命名映射
```yaml
版本开发分支:
  format: "task{nn}-v{major}-{minor}"
  examples:
    - "task01-v2-0"    # TASK01 v2.0开发分支
    - "task01-v2-1"    # TASK01 v2.1开发分支
    - "task05-v1-0"    # TASK05 v1.0开发分支

特殊版本分支:
  hotfix: "task{nn}-v{major}-{minor}-hotfix"
  emergency: "task{nn}-v{major}-{minor}-emergency" 
  compliance: "task{nn}-v{major}-{minor}-compliance"

分支生命周期:
  development: "版本开发期间保持活跃"
  merge: "合并到main后标记为合并完成"
  cleanup: "30天后自动删除开发分支"
```

### Commit消息规范
```yaml
版本创建commit:
  format: "feat(task{nn}): create v{major}.{minor} - {brief_description}"
  examples:
    - "feat(task01): create v2.0 - dual authentication system"
    - "feat(task05): create v1.1 - prescription validation enhancement"

版本更新commit:
  format: "update(task{nn}): v{major}.{minor} - {change_description}"
  examples:
    - "update(task01): v2.0 - add Clerk integration details"
    - "update(task03): v1.2 - refine compliance requirements"

版本归档commit:
  format: "archive(task{nn}): move v{major}.{minor} to archived"
  examples:
    - "archive(task01): move v1.0 to archived"
```

### Tag管理
```yaml
版本标签格式:
  format: "task{nn}-v{major}.{minor}"
  examples:
    - "task01-v1.0"
    - "task01-v2.0" 
    - "task05-v1.1"

标签策略:
  creation: "每次版本创建时自动添加标签"
  message: "包含版本变更摘要"
  retention: "与版本文件同步保留策略"
```

## 🛠️ 自动化工具支持

### 版本管理脚本
```bash
# 创建新版本
./scripts/create-version.sh TASK01 2.0 "dual authentication system"

# 列出版本历史
./scripts/list-versions.sh TASK01

# 归档旧版本
./scripts/archive-versions.sh --older-than 6months

# 版本比较
./scripts/compare-versions.sh TASK01 v1.0 v2.0
```

### CI/CD集成
```yaml
version_validation:
  trigger: "PRP文件变更"
  checks:
    - naming_convention: "文件名符合标准格式"
    - version_sequence: "版本号递增逻辑正确"  
    - metadata_sync: "元数据文件同步更新"
    - delta_section: "Delta段内容完整"

automatic_archiving:
  trigger: "定期任务 (每月第一天)"
  actions:
    - 扫描超期版本文件
    - 移动到归档目录
    - 更新元数据索引
    - 清理无效软链接
```

### 质量检查工具
```yaml
version_validator:
  purpose: "验证版本文件的格式和内容完整性"
  checks:
    - file_naming: "文件名格式正确"
    - version_continuity: "版本号连续性检查"
    - delta_completeness: "Delta段内容完整"
    - snapshot_evolution: "Requirements Snapshot正确演进"

dependency_analyzer:
  purpose: "分析版本间和跨TASK的依赖关系"
  outputs:
    - dependency_graph: "依赖关系图"
    - impact_analysis: "版本变更影响分析"
    - circular_dependency: "循环依赖检测"
```

## 📊 使用指南和最佳实践

### 版本创建工作流
```yaml
步骤1_需求评估:
  - 使用versioning-trigger-matrix.yaml评估是否需要版本化
  - 确定版本号递增策略 (MAJOR vs MINOR)
  - 记录版本化决策依据

步骤2_版本创建:
  - 从当前版本拷贝生成新版本文件
  - 按naming-and-storage-standards.md命名
  - 更新版本元数据文件

步骤3_内容更新:
  - 添加Delta段描述变更
  - 更新Requirements Snapshot
  - 修改原子任务和验收标准

步骤4_质量检查:
  - 运行version_validator工具
  - 检查dependency_analyzer输出
  - 确认所有质量标准通过

步骤5_版本发布:
  - 创建对应Git分支
  - 提交版本文件和元数据
  - 添加版本标签
  - 更新软链接指向
```

### 维护最佳实践
```yaml
定期维护:
  weekly:
    - 检查版本元数据一致性
    - 验证软链接有效性
    - 更新依赖关系图
  
  monthly:
    - 执行自动归档流程
    - 清理过期开发分支
    - 生成版本使用报告
  
  quarterly:
    - 评估归档策略有效性
    - 优化版本管理工具
    - 更新命名规范 (如需要)

监控指标:
  version_proliferation: "版本数量增长监控"
  storage_usage: "存储空间使用监控"
  access_patterns: "版本访问模式分析"
  maintenance_overhead: "维护工作量评估"
```