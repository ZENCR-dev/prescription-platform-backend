# Generate PRP Command

自动生成PRP (Progressive Requirement and Planning) 文档的Claude Code自定义命令。

## 命令格式
```
@generate-prp [task-name] [--phase number] [--priority high|medium|low]
```

## 功能描述
基于Context Engineering三层任务树架构，自动生成符合项目规范的TASK文档。

## 使用示例
```bash
# 生成新的任务文档
@generate-prp user-authentication --phase 1 --priority high

# 生成支付集成任务
@generate-prp payment-integration --phase 2 --priority medium
```

## 自动生成内容
1. **阶段目标**: 基于任务名称和项目上下文
2. **最小单位任务列表**: 4-8小时可完成的原子任务
3. **工具和命令**: SuperClaude命令映射
4. **检查清单**: 质量门控和验收标准
5. **进度追踪**: 任务状态和问题记录

## 模板参数
- `{TASK_NAME}`: 任务名称
- `{PHASE_NUMBER}`: 开发阶段
- `{PRIORITY_LEVEL}`: 优先级
- `{ESTIMATED_HOURS}`: 预估工时
- `{DEPENDENCIES}`: 前置依赖任务

## 集成规范
- 遵循CLAUDE.md行为规范
- 对接INITIAL.md任务树索引
- 支持SuperClaude工具链集成
- 自动更新项目进度追踪