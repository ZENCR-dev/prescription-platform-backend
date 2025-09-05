# API治理修复清单 - API Governance Remediation Plan

**状态**: 并行处理，非阻塞Task 1.2/1.3进展  
**发现来源**: CI检查识别的2项API中心化违规  
**目标**: 统一收敛到`prescription-platform-backend/APIdocs/APIv1.md`，符合Backend-First原则

## 🔍 违规源分析

### 违规1: API定义散布问题
**现状**: API定义散布在45+个文件中，违反API中心化原则  
**影响**: API文档不一致，维护成本高，版本控制困难

### 违规2: 前端API文档违规  
**现状**: 前端项目保留API文档副本，违反Backend-First架构原则  
**影响**: API权威性不明确，可能导致前后端接口不一致

## 📋 违规源列表→迁移路径→验收脚本

### Phase 1: 散布API定义整合

**违规源扫描** (预估45+文件):
```bash
# API定义查找脚本
find . -name "*.md" -o -name "*.js" -o -name "*.ts" \
  -exec grep -l "GET\|POST\|PUT\|DELETE\|PATCH.*/" {} \; \
  | grep -v APIdocs/APIv1.md \
  | sort > api-violations-list.txt
```

**迁移路径**:
1. **扫描收集**: 识别所有散布的API定义和端点
2. **分类整理**: 按模块/功能对API端点分组  
3. **合并写入**: 统一整合到`APIdocs/APIv1.md`
4. **源文件清理**: 移除原始位置的API定义
5. **引用更新**: 更新所有引用指向统一文档

**验收脚本**:
```bash
#!/bin/bash
# api-centralization-verification.sh

echo "=== API中心化违规验收脚本 ==="

# 检查1: 确认统一API文档存在且完整
if [ -f "APIdocs/APIv1.md" ]; then
    api_endpoints=$(grep -c "GET\|POST\|PUT\|DELETE\|PATCH" APIdocs/APIv1.md)
    echo "✅ 统一API文档存在，包含 $api_endpoints 个端点"
else
    echo "❌ 统一API文档不存在"
    exit 1
fi

# 检查2: 确认散布API定义已清理  
scattered_apis=$(find . -name "*.md" -not -path "./APIdocs/*" \
  -exec grep -l "GET\|POST\|PUT\|DELETE\|PATCH.*/" {} \; | wc -l)
if [ $scattered_apis -eq 0 ]; then
    echo "✅ 散布API定义已清理完成"
else
    echo "❌ 仍有 $scattered_apis 个文件包含散布的API定义"
    exit 1
fi

# 检查3: 验证API文档完整性
required_sections=("Authentication" "User Profiles" "Prescriptions" "Pharmacy Management")
for section in "${required_sections[@]}"; do
    if grep -q "$section" APIdocs/APIv1.md; then
        echo "✅ $section 章节存在"
    else
        echo "❌ $section 章节缺失"
        exit 1
    fi
done

echo "✅ API中心化整合验收通过"
```

### Phase 2: 前端API文档清理

**前端违规位置** (预估):
```
prescription-platform-frontend/docs/api/
prescription-platform-frontend/src/services/api-docs/
prescription-platform-frontend/README.md (API章节)
```

**迁移路径**:
1. **备份现有**: 备份前端API文档以防数据丢失
2. **内容比对**: 确认前端文档无后端缺失的API定义  
3. **引用替换**: 将前端API引用改为后端文档引用
4. **文件清理**: 移除前端API文档文件
5. **说明更新**: 在前端添加API文档位置说明

**验收脚本**:
```bash
#!/bin/bash  
# frontend-api-cleanup-verification.sh

echo "=== 前端API文档清理验收脚本 ==="

# 检查1: 确认前端API文档目录已移除
frontend_api_dirs=(
    "../prescription-platform-frontend/docs/api"
    "../prescription-platform-frontend/src/services/api-docs"
)

for dir in "${frontend_api_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "❌ 前端API文档目录仍存在: $dir"
        exit 1
    else
        echo "✅ 前端API文档目录已清理: $dir"  
    fi
done

# 检查2: 确认前端保留消费副本引用
if [ -f "../prescription-platform-frontend/docs/api-reference.md" ]; then
    if grep -q "prescription-platform-backend/APIdocs/APIv1.md" ../prescription-platform-frontend/docs/api-reference.md; then
        echo "✅ 前端API引用指向后端权威文档"
    else  
        echo "❌ 前端API引用未指向后端权威文档"
        exit 1
    fi
else
    echo "⚠️ 前端API引用文档不存在，需要创建"
fi

echo "✅ 前端API文档清理验收通过"
```

### Phase 3: PRP引用更新

**需要更新的PRP文件** (预估):
```
PRPs/PRP-M*.md (所有里程碑PRP文档)  
前端工作区PRPs/PRP-*.md
全局APIdocs分发副本更新
```

**迁移路径**:
1. **引用扫描**: 扫描所有PRP文档中的API文档引用
2. **批量替换**: 将所有API引用替换为统一文档路径  
3. **链接验证**: 确认所有新引用链接有效
4. **版本同步**: 确保引用版本与统一文档版本一致

**验收脚本**:
```bash
#!/bin/bash
# prp-reference-update-verification.sh  

echo "=== PRP引用更新验收脚本 ==="

# 检查1: 扫描PRP文档API引用
prp_files=$(find . -name "PRP-*.md")
inconsistent_refs=0

for file in $prp_files; do
    # 检查是否包含非统一的API引用
    if grep -q "api.*\.md" "$file" && ! grep -q "APIdocs/APIv1.md" "$file"; then
        echo "❌ $file 包含不一致的API引用"
        inconsistent_refs=$((inconsistent_refs + 1))
    fi
done

if [ $inconsistent_refs -eq 0 ]; then
    echo "✅ 所有PRP文档API引用已统一"
else
    echo "❌ 有 $inconsistent_refs 个PRP文档包含不一致引用"
    exit 1  
fi

# 检查2: 验证统一引用有效性
if grep -r "APIdocs/APIv1.md" PRPs/ >/dev/null; then
    echo "✅ PRP文档包含统一API文档引用"
    # 验证引用的文件确实存在
    if [ -f "APIdocs/APIv1.md" ]; then
        echo "✅ 统一API文档引用目标存在"
    else
        echo "❌ 统一API文档引用目标不存在"
        exit 1
    fi
else
    echo "⚠️ PRP文档中未找到API引用，可能不需要更新"
fi

echo "✅ PRP引用更新验收通过"
```

## 🎯 整体验收标准

### 成功标准
1. ✅ **API文档中心化**: 单一权威API文档`APIdocs/APIv1.md`  
2. ✅ **散布清理完成**: 无散布在其他位置的API定义
3. ✅ **前端合规**: 前端仅保留消费副本引用，无API文档副本
4. ✅ **引用一致性**: 所有PRP和文档引用指向统一API文档
5. ✅ **Backend-First**: API权威性明确，后端为API文档真源

### 验收执行序列
```bash
# 完整验收流程
./api-centralization-verification.sh
./frontend-api-cleanup-verification.sh  
./prp-reference-update-verification.sh

# 综合检查
echo "=== API治理修复综合验收 ==="
if [ $? -eq 0 ]; then
    echo "✅ API治理修复完成，符合Backend-First架构原则"
else
    echo "❌ API治理修复未完成，需要继续整改"
    exit 1
fi
```

## 📅 执行时间线

**并行执行** (不阻塞Task 1.2/1.3):
- **Week 1**: Phase 1 散布API整合
- **Week 2**: Phase 2 前端文档清理  
- **Week 3**: Phase 3 PRP引用更新
- **Week 4**: 综合验收与文档更新

**里程碑检查点**:
- 每个Phase完成后运行对应验收脚本
- 最终综合验收通过后更新治理状态
- 与前端团队协调确认API引用更新

---
**API治理修复状态**: 🔄 **计划完成，等待执行** - 不阻塞当前Task 1.2/1.3进展，可并行处理