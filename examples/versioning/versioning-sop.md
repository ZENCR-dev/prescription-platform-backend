# PRP版本化操作标准流程 (SOP)

## 🎯 文档目标

本SOP提供PRP版本化的完整操作流程，确保团队成员能够标准化、高效地执行PRP版本创建、管理和维护工作。

## 📋 适用范围

- **适用人员**: 后端开发团队、架构师、项目经理、QA工程师
- **适用场景**: 所有需要PRP版本化的需求变更情况
- **适用项目**: 医疗处方履约平台后端项目及其衍生项目

## 🚦 操作前置条件

### 必需工具和权限
- [ ] Git仓库访问权限 (可创建分支和提交)
- [ ] PRPs目录写入权限
- [ ] 版本化评估工具访问权限
- [ ] 相关TASK的当前版本文档

### 必需知识和培训
- [ ] 理解PRP版本化规则和原理
- [ ] 熟悉触发条件评估矩阵
- [ ] 掌握Delta段和Requirements Snapshot编写
- [ ] 了解Git分支管理策略

## 📊 标准操作流程

### Phase 1: 版本化需求评估

#### Step 1.1: 变更需求分析
**目标**: 明确变更的具体内容和影响范围

**操作步骤**:
1. 收集变更需求的详细信息
   ```yaml
   变更来源: [业务需求/技术约束/合规要求/架构优化]
   变更描述: [具体的功能变更或需求调整]
   紧急程度: [紧急/高/中/低]
   业务影响: [对业务目标和用户体验的影响]
   ```

2. 识别受影响的组件和系统
   - 确定涉及的TASK范围
   - 分析API接口变更需求
   - 评估数据库schema影响
   - 检查医疗合规要求变化

3. 记录变更需求基础信息
   ```bash
   # 创建变更需求记录
   echo "变更需求: [标题]" > change-request-$(date +%Y%m%d).md
   echo "申请人: [姓名]" >> change-request-$(date +%Y%m%d).md
   echo "申请日期: $(date)" >> change-request-$(date +%Y%m%d).md
   ```

**输出物**: 变更需求分析文档

#### Step 1.2: 触发条件评估
**目标**: 客观评估是否需要创建新版本

**操作步骤**:
1. 使用评估矩阵进行评分
   ```bash
   # 打开评估矩阵
   cat examples/versioning/versioning-trigger-matrix.yaml
   ```

2. 逐项评估各维度得分
   ```yaml
   impact_scope: [1-5]        # 影响范围评分
   change_magnitude: [1-5]    # 变更幅度评分
   requirements_source: [1-5] # 需求来源评分
   api_impact: [1-5]         # API影响评分
   database_impact: [1-5]    # 数据库影响评分
   compliance_impact: [1-5]  # 合规影响评分
   ```

3. 计算综合评分
   ```
   score = (impact_scope × 0.3) + (change_magnitude × 0.25) + 
           (requirements_source × 0.2) + (api_impact × 0.15) + 
           (database_impact × 0.05) + (compliance_impact × 0.05)
   ```

4. 确定版本化决策
   ```yaml
   score >= 4.0: MUST_VERSION      # 必须版本化
   score >= 3.0: SHOULD_VERSION    # 强烈建议版本化
   score >= 2.0: CONSIDER_VERSION  # 考虑版本化
   score < 2.0:  UPDATE_CURRENT    # 更新当前版本
   ```

**输出物**: 版本化评估报告

#### Step 1.3: 利益相关者确认
**目标**: 获得关键利益相关者的版本化决策确认

**操作步骤**:
1. 准备决策汇报材料
   - 变更需求概述
   - 评估矩阵结果
   - 版本化建议和理由
   - 预期影响和风险

2. 组织决策评审会议
   - **必需参与者**: 技术负责人、产品经理
   - **建议参与者**: QA负责人、安全专家(如涉及合规)
   - **评审时间**: 30-60分钟

3. 记录决策结果
   ```yaml
   决策结果: [APPROVED_VERSION / REJECTED_VERSION / UPDATE_CURRENT]
   决策理由: [具体理由和依据]
   特殊要求: [任何特殊的实施要求]
   时间要求: [期望的完成时间]
   ```

**输出物**: 版本化决策确认文档

### Phase 2: 版本创建和内容编写

#### Step 2.1: 版本文件创建
**目标**: 按标准格式创建新版本文件

**操作步骤**:
1. 确定版本号
   ```bash
   # 查看当前版本
   ls PRPs/TASK{NN}*.md | sort -V | tail -1
   
   # 确定新版本号 (根据变更类型)
   # MAJOR: 架构级变更、破坏性变更
   # MINOR: 功能增强、兼容性变更
   ```

2. 创建新版本文件
   ```bash
   # 从当前版本拷贝
   cp PRPs/TASK{NN}.md PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
   
   # 或从模板创建
   cp examples/versioning/prp-versioning-template.md PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
   ```

3. 更新基础信息
   ```bash
   # 更新文档头部信息
   sed -i 's/v{MAJOR}.{MINOR}/v2.0/g' PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
   sed -i 's/YYYY-MM-DD/'$(date +%Y-%m-%d)'/g' PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
   ```

**输出物**: 新版本文件骨架

#### Step 2.2: Delta段编写
**目标**: 详细记录变更内容和影响分析

**操作步骤**:
1. 打开Delta段模板
   ```bash
   cat examples/versioning/delta-section-template.md
   ```

2. 填写变更概述
   ```markdown
   **版本**: v{X}.0 → v{X+1}.0
   **变更日期**: $(date +%Y-%m-%d)
   **变更原因**: [从Phase 1获取]
   **变更紧急程度**: [从评估获取]
   **影响范围**: [从评估获取]
   ```

3. 详细填写各变更项
   - **新增功能**: 列出所有新增的功能点
   - **修改功能**: 记录功能变更的前后对比
   - **删除功能**: 说明删除的功能和原因

4. 完成影响分析
   - **依赖任务影响**: 分析对其他TASK的具体影响
   - **API接口影响**: 记录API变更的详细信息
   - **数据库影响**: 说明schema变更和迁移策略
   - **合规性影响**: 评估医疗合规要求的变化

5. 制定迁移路径
   - **并行执行策略**: 确定新旧版本的共存方案
   - **迁移步骤**: 详细的迁移操作步骤
   - **风险缓解**: 识别风险点和缓解措施
   - **向后兼容性**: 评估兼容性级别

**输出物**: 完整的Delta段内容

#### Step 2.3: Requirements Snapshot更新
**目标**: 正确演进需求快照，保持追溯性

**操作步骤**:
1. 参考演进规则
   ```bash
   cat examples/versioning/requirements-snapshot-evolution.md
   ```

2. 更新源引用信息
   ```markdown
   **source**: INITIAL.md@<commit_hash>, Delta@v{X}.0→v{X+1}.0
   **previous_version**: PRPs/TASK{NN}_v{X}.md@<commit_hash>
   **change_trigger**: [从Delta段获取]
   ```

3. 更新版本演进路径
   ```markdown
   v1.0 → v{X}.0 → ... → v{X+1}.0
    │      │              │
    │      │              └─ 当前版本
    │      └─ [变更描述]
    └─ 原始版本
   ```

4. 分类更新约束、标准和排除项
   - **继承项**: 从前一版本继承的内容
   - **新增项**: 当前版本新增的内容
   - **修改项**: 使用"原项目 → 新项目"格式
   - **移除项**: 使用删除线格式并说明原因

**输出物**: 更新的Requirements Snapshot

#### Step 2.4: 原子任务调整
**目标**: 根据变更调整任务分解和验收标准

**操作步骤**:
1. 评估现有任务的适用性
   - 确定哪些任务需要调整
   - 确定是否需要新增任务
   - 评估任务间的依赖关系

2. 调整AI Agent估算
   ```yaml
   步骤数量: [更新步骤数量]
   代码文件: [更新文件数量]
   迭代轮次: [更新轮次]
   复杂度: [更新复杂度级别]
   ```

3. 更新原子任务分解
   - 修改现有任务的3+1步骤内容
   - 新增必要的原子任务
   - 调整SuperClaude命令建议

4. 更新完成检查清单
   - 添加新功能的验证项
   - 修改现有验证标准
   - 确保医疗合规要求覆盖

**输出物**: 调整后的任务分解和验收标准

### Phase 3: 质量检查和发布

#### Step 3.1: 内容质量检查
**目标**: 确保新版本文档的完整性和准确性

**操作步骤**:
1. 使用质量检查清单
   ```bash
   # 检查文件命名
   echo "检查文件命名格式..." 
   [[ "PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md" =~ ^PRPs/TASK[0-9]{2}_v[0-9]+\.[0-9]+\.md$ ]]
   
   # 检查必需章节
   echo "检查必需章节完整性..."
   grep -q "## 🔄 Delta段" PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
   grep -q "## 🔗 Requirements Snapshot" PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
   ```

2. 验证内容完整性
   - [ ] Delta段所有变更项都有详细描述
   - [ ] 影响分析覆盖所有相关维度
   - [ ] Requirements Snapshot正确演进
   - [ ] 原子任务分解合理可执行
   - [ ] 医疗合规要求完整考虑

3. 检查格式规范性
   - [ ] Markdown格式正确
   - [ ] 链接和引用有效
   - [ ] 表格和代码块格式正确
   - [ ] 符合模板结构要求

**输出物**: 质量检查报告

#### Step 3.2: 技术评审
**目标**: 通过技术专家评审确保方案可行性

**操作步骤**:
1. 组织技术评审会议
   - **必需参与者**: 架构师、技术负责人
   - **建议参与者**: 相关TASK负责人、安全专家
   - **评审重点**: 技术方案、实施路径、风险评估

2. 评审关键内容
   - [ ] 技术方案的可行性和合理性
   - [ ] API变更的影响和兼容性
   - [ ] 数据库变更的安全性
   - [ ] 实施时间线的现实性
   - [ ] 风险缓解措施的有效性

3. 记录评审结果
   ```yaml
   评审结果: [APPROVED / APPROVED_WITH_CONDITIONS / REJECTED]
   评审意见: [具体的评审意见和建议]
   修改要求: [需要修改的内容和要求]
   再评审安排: [如需要，安排再评审时间]
   ```

**输出物**: 技术评审报告

#### Step 3.3: 版本发布和通知
**目标**: 正式发布新版本并通知相关团队

**操作步骤**:
1. 更新版本元数据
   ```bash
   # 更新版本元数据文件
   cat >> PRPs/versions/metadata/TASK{NN}_versions.yaml << EOF
   - version: "v{MAJOR}.{MINOR}"
     created: "$(date +%Y-%m-%d)"
     status: "current"
     location: "TASK{NN}_v{MAJOR}.{MINOR}.md"
     change_summary: "[简要变更描述]"
   EOF
   ```

2. 更新当前版本链接
   ```bash
   # 更新软链接指向新版本
   rm PRPs/TASK{NN}.md
   ln -s TASK{NN}_v{MAJOR}.{MINOR}.md PRPs/TASK{NN}.md
   ```

3. 提交Git变更
   ```bash
   # 创建专用分支
   git checkout -b task{nn}-v{major}-{minor}
   
   # 添加所有相关文件
   git add PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
   git add PRPs/versions/metadata/TASK{NN}_versions.yaml
   
   # 提交变更
   git commit -m "feat(task{nn}): create v{major}.{minor} - [变更简要描述]
   
   详细变更:
   - [主要变更点1]
   - [主要变更点2]
   - [主要变更点3]
   
   🤖 Generated with Claude Code
   
   Co-Authored-By: Claude <noreply@anthropic.com>"
   
   # 添加版本标签
   git tag task{nn}-v{major}.{minor}
   ```

4. 通知相关团队
   ```yaml
   通知对象:
     - 依赖任务负责人
     - 相关开发团队成员
     - 项目经理和产品经理
     - QA团队
   
   通知内容:
     - 新版本发布信息
     - 主要变更概述
     - 对其他任务的影响
     - 后续执行计划
   ```

**输出物**: 版本发布通知和Git记录

### Phase 4: 后续跟踪和维护

#### Step 4.1: 执行跟踪
**目标**: 跟踪新版本的执行进度和质量

**操作步骤**:
1. 建立跟踪机制
   ```yaml
   跟踪频率: 每周一次状态更新
   跟踪内容:
     - 开发进度和里程碑
     - 遇到的问题和解决方案
     - 质量指标和测试结果
     - 风险状况和缓解措施
   ```

2. 记录执行日志
   ```bash
   # 在对应的TASK0X_LOG.md中记录
   echo "### [$(date +'%Y-%m-%d %H:%M:%S')] 📋 v{MAJOR}.{MINOR}执行启动" >> PRPs/TASK{NN}_LOG.md
   echo "- 版本创建完成，开始按v{MAJOR}.{MINOR}规划执行" >> PRPs/TASK{NN}_LOG.md
   ```

3. 监控关键指标
   - 开发进度是否按计划推进
   - 质量门控是否正常通过
   - 是否出现预期外的技术问题
   - 团队对新版本的反馈

**输出物**: 执行跟踪报告

#### Step 4.2: 问题处理
**目标**: 及时处理执行过程中的问题和偏差

**操作步骤**:
1. 问题识别和分类
   ```yaml
   问题类型:
     - 技术实现问题
     - 需求理解偏差
     - 依赖任务冲突
     - 资源或时间约束
   ```

2. 问题解决流程
   - **轻微问题**: 直接在当前版本中调整
   - **重大问题**: 考虑创建hotfix版本或回滚
   - **需求变更**: 重新评估是否需要新版本

3. 记录问题和解决方案
   ```markdown
   ## 问题记录
   **问题描述**: [具体问题描述]
   **发现时间**: [发现时间]
   **影响程度**: [高/中/低]
   **解决方案**: [具体解决方案]
   **解决时间**: [解决时间]
   **经验教训**: [从问题中学到的经验]
   ```

**输出物**: 问题处理记录

#### Step 4.3: 版本归档
**目标**: 适时归档旧版本，维护版本管理的整洁性

**操作步骤**:
1. 评估归档条件
   ```yaml
   归档触发条件:
     - 版本创建超过6个月
     - 该版本之后有3+个新版本
     - 主目录版本文件数>20个
   ```

2. 执行归档操作
   ```bash
   # 移动旧版本到归档目录
   mkdir -p PRPs/versions/archived/
   mv PRPs/TASK{NN}_v{OLD}.{VERSION}.md PRPs/versions/archived/
   
   # 更新元数据
   sed -i 's/status: "active"/status: "archived"/' PRPs/versions/metadata/TASK{NN}_versions.yaml
   ```

3. 清理和优化
   ```bash
   # 清理无效链接
   find PRPs/ -type l ! -exec test -e {} \; -delete
   
   # 更新README文件
   echo "版本 v{OLD}.{VERSION} 已归档到 versions/archived/" >> PRPs/README.md
   ```

**输出物**: 归档操作记录

## 🚨 应急程序

### 紧急版本创建
当遇到生产环境紧急问题需要立即修复时：

1. **跳过评估流程**: 直接创建hotfix版本
2. **简化文档**: 使用简化的Delta段模板
3. **加急评审**: 1小时内完成技术评审
4. **优先发布**: 优先级最高，立即发布

### 版本回滚
当新版本执行出现严重问题时：

1. **停止执行**: 立即停止当前版本的开发
2. **评估影响**: 快速评估已完成工作的影响
3. **执行回滚**: 恢复到前一个稳定版本
4. **问题分析**: 深入分析问题原因，避免重复

### 利益相关者争议
当对版本化决策存在争议时：

1. **暂停操作**: 停止版本创建操作
2. **重新评估**: 使用更严格的评估标准
3. **高级评审**: 升级到更高级别的决策者
4. **记录决策**: 详细记录争议和最终决策

## 📊 质量标准

### 文档质量标准
- **完整性**: 所有必需章节都完整填写
- **准确性**: 技术信息准确，无误导性描述
- **一致性**: 格式和术语使用一致
- **可操作性**: 步骤清晰，可以直接执行

### 流程质量标准
- **及时性**: 评估和决策在合理时间内完成
- **透明性**: 所有关键决策都有明确记录
- **可追溯性**: 版本变更历史完整可追溯
- **可维护性**: 版本管理策略可持续执行

### 团队协作标准
- **参与度**: 关键利益相关者充分参与
- **沟通性**: 及时、准确的信息传递
- **责任性**: 明确的角色职责和时间要求
- **学习性**: 持续改进和经验积累

## 🔧 工具和模板

### 必需文件清单
- [ ] `examples/versioning/versioning-trigger-matrix.yaml`
- [ ] `examples/versioning/delta-section-template.md`
- [ ] `examples/versioning/requirements-snapshot-evolution.md`
- [ ] `examples/versioning/naming-and-storage-standards.md`
- [ ] `examples/versioning/prp-versioning-template.md`

### 检查清单模板
```markdown
## PRP版本化完成检查清单

### Phase 1: 需求评估
- [ ] 变更需求分析完成
- [ ] 触发条件评估完成 (评分: ___)
- [ ] 利益相关者确认获得

### Phase 2: 版本创建
- [ ] 版本文件按标准格式创建
- [ ] Delta段完整填写
- [ ] Requirements Snapshot正确更新
- [ ] 原子任务合理调整

### Phase 3: 质量检查
- [ ] 内容质量检查通过
- [ ] 技术评审通过
- [ ] 版本发布和通知完成

### Phase 4: 后续跟踪
- [ ] 执行跟踪机制建立
- [ ] 问题处理流程就绪
- [ ] 归档计划制定
```

### 常用命令参考
```bash
# 评估当前版本
ls PRPs/TASK*.md | wc -l

# 检查版本命名格式
ls PRPs/TASK*_v*.md | grep -E "TASK[0-9]{2}_v[0-9]+\.[0-9]+\.md"

# 查看版本历史
cat PRPs/versions/metadata/TASK{NN}_versions.yaml

# 创建新版本分支
git checkout -b task{nn}-v{major}-{minor}

# 验证文档格式
markdown-link-check PRPs/TASK{NN}_v{MAJOR}.{MINOR}.md
```

---

**SOP版本**: v1.0  
**发布日期**: 2025-01-17  
**下次评审**: 2025-04-17  
**维护团队**: 项目架构组  
**批准人**: [技术负责人签名]