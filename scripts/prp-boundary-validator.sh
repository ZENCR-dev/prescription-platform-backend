#!/bin/bash
# prp-boundary-validator.sh - PRP职责边界自动检查工具
# 基于《PROJECT_PLAYBOOK.md》第553-596行实例

validate_backend_prp() {
    local prp_file="$1"
    local violations=0
    
    echo "🔍 验证后端PRP: $(basename "$prp_file")"
    
    # 检查禁止的前端技术栈
    if grep -i "next\.js\|react\|前端\|UI\|component\|前端路由\|页面结构\|客户端状态管理" "$prp_file"; then
        echo "❌ 后端PRP包含前端技术栈违规: $prp_file"
        echo "   发现禁用关键词，违反黄金法则1：职责边界不可突破"
        ((violations++))
    fi
    
    # 检查必需的后端技术栈
    if ! grep -i "edge functions\|postgresql\|supabase\|RLS策略\|数据库" "$prp_file"; then
        echo "⚠️ 后端PRP缺少必需的后端技术栈: $prp_file"
        echo "   应包含: Edge Functions, PostgreSQL, Supabase, RLS策略等"
        ((violations++))
    fi
    
    # 检查API文档中心化合规性
    if grep -i "API.*定义\|接口.*规范" "$prp_file" | grep -v "APIdocs/APIv1.md"; then
        echo "❌ 后端PRP违反API文档中心化原则: $prp_file"
        echo "   应统一引用APIdocs/APIv1.md，违反黄金法则2"
        ((violations++))
    fi
    
    # 检查主实现角色正确性
    if ! grep -q "backend persona\|architect persona" "$prp_file"; then
        echo "⚠️ 后端PRP缺少正确的主实现角色标识: $prp_file"
        ((violations++))
    fi
    
    return $violations
}

validate_frontend_prp() {
    local prp_file="$1"
    local violations=0
    
    echo "🔍 验证前端PRP: $(basename "$prp_file")"
    
    # 检查禁止的后端技术栈
    if grep -i "postgresql\|rls\|edge functions\|数据库设计\|服务器端安全配置\|后端业务逻辑" "$prp_file"; then
        echo "❌ 前端PRP包含后端技术栈违规: $prp_file"
        echo "   发现禁用关键词，违反黄金法则1：职责边界不可突破"
        ((violations++))
    fi
    
    # 检查必需的前端技术栈
    if ! grep -i "next\.js\|react\|supabase client\|UI\|前端" "$prp_file"; then
        echo "⚠️ 前端PRP缺少必需的前端技术栈: $prp_file"
        echo "   应包含: Next.js, React, Supabase Client等"
        ((violations++))
    fi
    
    # 检查API依赖管理合规性
    if ! grep -q "APIdocs/APIv1.md" "$prp_file"; then
        echo "⚠️ 前端PRP缺少API文档依赖引用: $prp_file"
        echo "   应正确引用APIdocs/APIv1.md作为API规范源"
        ((violations++))
    fi
    
    # 检查主实现角色正确性
    if ! grep -q "frontend persona" "$prp_file"; then
        echo "⚠️ 前端PRP缺少正确的主实现角色标识: $prp_file"
        ((violations++))
    fi
    
    return $violations
}

validate_backend_first_compliance() {
    local prp_file="$1"
    local violations=0
    
    # 检查Backend-First时序约束遵循
    if grep -i "前端.*Mock\|自行.*假设.*接口" "$prp_file"; then
        echo "❌ 发现Backend-First时序违规: $prp_file"
        echo "   违反黄金法则3：前端不得自行Mock或假设接口"
        ((violations++))
    fi
    
    # 检查协作检查点集成
    if ! grep -qi "CKP-\|协作检查点\|检查点" "$prp_file"; then
        echo "⚠️ PRP缺少协作检查点集成: $prp_file"
        echo "   应包含相关的CKP检查点定义"
        ((violations++))
    fi
    
    return $violations
}

# 主验证流程
echo "🚀 开始PRP职责边界验证..."
echo "📋 执行《PROJECT_PLAYBOOK.md》黄金法则验证"
echo ""

total_violations=0
backend_violations=0
frontend_violations=0
compliance_violations=0

# 检查项目目录存在性
backend_prp_dir="PRPs"
if [[ ! -d "$backend_prp_dir" ]]; then
    echo "⚠️ 后端PRPs目录不存在: $backend_prp_dir"
    exit 1
fi

# 验证后端PRPs（当前项目是后端项目）
echo "🔍 验证后端项目PRPs..."
for prp in "$backend_prp_dir"/TASK*.md; do
    if [[ -f "$prp" ]] && [[ "$prp" != *"_LOG.md" ]]; then
        validate_backend_prp "$prp"
        backend_violations=$((backend_violations + $?))
        
        validate_backend_first_compliance "$prp"
        compliance_violations=$((compliance_violations + $?))
        
        echo ""
    fi
done

# 检查API文档中心化
echo "📄 检查API文档中心化合规性..."
api_doc_path="APIdocs/APIv1.md"
if [[ ! -f "$api_doc_path" ]]; then
    echo "❌ API文档不存在: $api_doc_path"
    echo "   违反黄金法则2：API文档中心化管理"
    ((backend_violations++))
else
    echo "✅ API文档存在: $api_doc_path"
fi

api_log_path="APIdocs/APIv1_log.md"
if [[ ! -f "$api_log_path" ]]; then
    echo "⚠️ API变更日志不存在: $api_log_path"
    echo "   建议创建API变更历史记录"
    ((backend_violations++))
else
    echo "✅ API变更日志存在: $api_log_path"
fi

echo ""

# 输出验证结果汇总
total_violations=$((backend_violations + frontend_violations + compliance_violations))

echo "📊 验证结果汇总："
echo "   后端PRP违规: $backend_violations"
echo "   前端PRP违规: $frontend_violations" 
echo "   协作合规违规: $compliance_violations"
echo "   总违规数: $total_violations"
echo ""

if [[ $total_violations -eq 0 ]]; then
    echo "✅ 所有PRP职责边界验证通过"
    echo "🎉 完全符合《PROJECT_PLAYBOOK.md》要求"
    exit 0
else
    echo "🚨 发现 $total_violations 个职责边界违规，需要立即修正"
    echo ""
    echo "🔧 修复建议："
    echo "1. 检查违规PRP，移除跨边界技术栈引用"
    echo "2. 确保API文档统一引用APIdocs/APIv1.md"
    echo "3. 验证主实现角色标识正确性"
    echo "4. 集成协作检查点机制"
    echo "5. 遵循Backend-First开发时序约束"
    echo ""
    echo "📚 参考文档：《PROJECT_PLAYBOOK.md》第251-446行"
    exit 1
fi