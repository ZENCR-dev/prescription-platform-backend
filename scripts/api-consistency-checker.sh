#!/bin/bash
# api-consistency-checker.sh - API文档一致性验证工具
# 基于《PROJECT_PLAYBOOK.md》第629-674行实例

check_api_centralization() {
    echo "🔍 检查API文档中心化合规性..."
    local violations=0
    
    # 检查API文档是否只存在于后端项目的正确位置
    backend_api_path="APIdocs/APIv1.md"
    backend_api_log_path="APIdocs/APIv1_log.md"
    
    if [[ ! -f "$backend_api_path" ]]; then
        echo "❌ 后端项目API文档不存在: $backend_api_path"
        echo "   违反黄金法则2：API文档中心化管理原则"
        ((violations++))
    else
        echo "✅ 后端项目API文档存在: $backend_api_path"
        
        # 检查API文档内容质量
        if [[ $(wc -l < "$backend_api_path") -lt 10 ]]; then
            echo "⚠️ API文档内容过少，可能不完整: $backend_api_path"
            ((violations++))
        fi
        
        # 检查API文档格式规范
        if ! grep -q "# API" "$backend_api_path"; then
            echo "⚠️ API文档缺少标准标题格式: $backend_api_path"
            ((violations++))
        fi
    fi
    
    if [[ ! -f "$backend_api_log_path" ]]; then
        echo "⚠️ API变更日志不存在: $backend_api_log_path"
        echo "   建议创建API变更历史记录文件"
        ((violations++))
    else
        echo "✅ API变更日志存在: $backend_api_log_path"
    fi
    
    # 检查是否存在分散的API定义（违规行为）
    scattered_api_files=$(find . -name "*.md" -not -path "./APIdocs/*" -not -path "./node_modules/*" -not -path "./scripts/*" | xargs grep -l "API.*端点\|接口.*定义\|POST\|GET\|PUT\|DELETE" 2>/dev/null | grep -v "$0")
    
    if [[ -n "$scattered_api_files" ]]; then
        echo "❌ 发现分散的API定义，违反中心化原则:"
        echo "$scattered_api_files"
        echo "   所有API定义应统一在 $backend_api_path 中管理"
        ((violations++))
    else
        echo "✅ 未发现分散的API定义"
    fi
    
    # 检查前端项目中的API文档（如果存在）
    frontend_project_path="../prescription-platform-frontend"
    if [[ -d "$frontend_project_path" ]]; then
        frontend_api_files=$(find "$frontend_project_path" -name "*API*.md" 2>/dev/null)
        if [[ -n "$frontend_api_files" ]]; then
            echo "❌ 前端项目包含API文档，违反中心化原则:"
            echo "$frontend_api_files"
            echo "   前端项目应只读消费后端API文档，不得自建API文档"
            ((violations++))
        else
            echo "✅ 前端项目未包含API文档（符合中心化原则）"
        fi
    fi
    
    return $violations
}

check_api_references() {
    echo ""
    echo "🔍 检查PRP中的API引用规范..."
    local violations=0
    
    # 检查后端PRP是否正确维护API文档
    for prp in PRPs/TASK*.md; do
        if [[ -f "$prp" ]] && [[ "$prp" != *"_LOG.md" ]]; then
            echo "   检查后端PRP: $(basename "$prp")"
            
            # 检查是否有API相关内容但未引用统一文档
            if grep -q -i "API\|接口\|端点" "$prp"; then
                if grep -q "APIdocs/APIv1.md" "$prp"; then
                    echo "     ✅ 正确引用统一API文档"
                else
                    echo "     ⚠️ 包含API内容但未引用APIdocs/APIv1.md"
                    ((violations++))
                fi
            fi
            
            # 检查是否包含内联API定义（违规）
            if grep -q -E "(POST|GET|PUT|DELETE)\s+/" "$prp"; then
                echo "     ❌ 包含内联API定义，违反中心化原则"
                echo "       应将API定义统一到APIdocs/APIv1.md"
                ((violations++))
            fi
        fi
    done
    
    # 检查前端PRP（如果存在）
    frontend_prp_path="../prescription-platform-frontend/PRPs"
    if [[ -d "$frontend_prp_path" ]]; then
        for prp in "$frontend_prp_path"/TASK*.md; do
            if [[ -f "$prp" ]] && [[ "$prp" != *"_LOG.md" ]]; then
                echo "   检查前端PRP: $(basename "$prp")"
                
                if grep -q -i "API\|接口" "$prp"; then
                    if grep -q "APIdocs/APIv1.md" "$prp"; then
                        echo "     ✅ 正确引用后端API文档"
                    else
                        echo "     ❌ 缺少对后端API文档的引用"
                        echo "       前端PRP应引用: prescription-platform-backend/APIdocs/APIv1.md"
                        ((violations++))
                    fi
                fi
            fi
        done
    fi
    
    return $violations
}

check_api_modification_workflow() {
    echo ""
    echo "🔍 检查API修改工作流合规性..."
    local violations=0
    
    # 检查API文档修改权限（基于git历史）
    if command -v git >/dev/null 2>&1 && [[ -d .git ]]; then
        # 检查最近的API文档修改记录
        recent_api_changes=$(git log --oneline -10 --follow APIdocs/APIv1.md 2>/dev/null)
        if [[ -n "$recent_api_changes" ]]; then
            echo "✅ API文档有修改历史记录"
            echo "   最近修改："
            echo "$recent_api_changes" | head -3 | sed 's/^/     /'
        fi
        
        # 检查API变更日志的同步性
        if [[ -f "APIdocs/APIv1_log.md" ]]; then
            api_doc_last_modified=$(stat -f "%m" "APIdocs/APIv1.md" 2>/dev/null || stat -c "%Y" "APIdocs/APIv1.md" 2>/dev/null)
            api_log_last_modified=$(stat -f "%m" "APIdocs/APIv1_log.md" 2>/dev/null || stat -c "%Y" "APIdocs/APIv1_log.md" 2>/dev/null)
            
            if [[ -n "$api_doc_last_modified" ]] && [[ -n "$api_log_last_modified" ]]; then
                time_diff=$((api_doc_last_modified - api_log_last_modified))
                if [[ $time_diff -gt 86400 ]]; then  # 24小时
                    echo "⚠️ API文档修改后未及时更新变更日志"
                    echo "   API文档与变更日志修改时间差超过24小时"
                    ((violations++))
                else
                    echo "✅ API文档与变更日志同步及时"
                fi
            fi
        fi
    fi
    
    # 检查Backend-First工作流遵循情况
    echo "   检查Backend-First工作流标识..."
    
    # 在API文档中查找工作流标识
    if [[ -f "APIdocs/APIv1.md" ]]; then
        if grep -q -i "backend.*first\|后端.*优先\|数据库.*驱动" "APIdocs/APIv1.md"; then
            echo "✅ API文档体现Backend-First原则"
        else
            echo "⚠️ API文档未明确体现Backend-First工作流"
            ((violations++))
        fi
    fi
    
    return $violations
}

validate_coordination_checkpoints() {
    echo ""
    echo "🔍 验证协作检查点集成..."
    local violations=0
    
    # 检查协作检查点在PRP中的集成情况
    for prp in PRPs/TASK*.md; do
        if [[ -f "$prp" ]] && [[ "$prp" != *"_LOG.md" ]]; then
            echo "   检查协作检查点集成: $(basename "$prp")"
            
            # 检查是否包含协作检查点引用
            if grep -q -i "CKP-\|检查点\|协作.*点" "$prp"; then
                echo "     ✅ 包含协作检查点集成"
                
                # 检查具体的检查点类型
                ckp_types=$(grep -o -i "CKP-[1-5]\|API契约确认\|接口联调\|集成测试\|生产部署\|性能优化" "$prp" | sort -u)
                if [[ -n "$ckp_types" ]]; then
                    echo "     ✅ 具体检查点: $ckp_types"
                fi
            else
                echo "     ⚠️ 缺少协作检查点集成"
                echo "       建议集成CKP-1到CKP-5协作检查点机制"
                ((violations++))
            fi
        fi
    done
    
    return $violations
}

# 执行完整的API一致性检查
echo "🚀 开始API文档一致性验证..."
echo "📋 执行《PROJECT_PLAYBOOK.md》API中心化验证"
echo ""

total_violations=0

# 执行各项检查
check_api_centralization
centralization_violations=$?
total_violations=$((total_violations + centralization_violations))

check_api_references  
reference_violations=$?
total_violations=$((total_violations + reference_violations))

check_api_modification_workflow
workflow_violations=$?
total_violations=$((total_violations + workflow_violations))

validate_coordination_checkpoints
checkpoint_violations=$?
total_violations=$((total_violations + checkpoint_violations))

# 输出验证结果汇总
echo ""
echo "📊 API一致性验证结果汇总："
echo "   API中心化违规: $centralization_violations"
echo "   API引用违规: $reference_violations"
echo "   工作流违规: $workflow_violations"
echo "   协作检查点违规: $checkpoint_violations"
echo "   总违规数: $total_violations"
echo ""

if [[ $total_violations -eq 0 ]]; then
    echo "✅ API文档一致性验证通过"
    echo "🎉 完全符合API文档中心化管理要求"
    echo "📚 遵循《PROJECT_PLAYBOOK.md》黄金法则2"
    exit 0
else
    echo "🚨 发现 $total_violations 个API一致性违规，需要立即修正"
    echo ""
    echo "🔧 修复建议："
    echo "1. 确保APIdocs/APIv1.md为唯一API文档源"
    echo "2. 创建并维护APIdocs/APIv1_log.md变更日志"
    echo "3. 移除分散在其他文件中的API定义"
    echo "4. 确保PRP正确引用统一API文档"
    echo "5. 建立Backend-First API修改工作流"
    echo "6. 集成CKP-1到CKP-5协作检查点机制"
    echo ""
    echo "📚 参考文档：《PROJECT_PLAYBOOK.md》第274-292行"
    exit 1
fi