---
# --- 架构师定义区 (由PRP_GENERATION_PLAN自动生成) ---
title: "PRP-M1.1: 认证基础模块"
layer: "Layer 2 - 战术规划"
log_file: "PRPs/LOGS/LOG-PRP-M1.1-Auth-Backend.md"
milestone: "M1: 核心处方创建闭环"
owner: "Backend Team"
unlocks: "M1.2: 认证UI集成模块"
depends_on: []
engineering_units:
  components: 3
  dev_steps: ~12
  files: ~5
  config_items: 2
module_exit_criteria:
  - "API契约已更新APIdocs/APIv1.md并记录APIdocs/APIv1_log.md"
  - "Postman/curl可验证端点与鉴权"
  - "相关RLS/审计最小用例通过"
  - "消费方字段/错误码/限流说明清晰"
---

## 模块目标
# ... (由架构师定义) ...

## 模块出厂门 (MEM)
# ... (由架构师定义) ...

---
## **[工程师自主规划区]**

> 说明: 以下“阶段划分”和“原子任务分解”由负责本模块的工程师在接收此PRP后自主规划填写。

### 阶段一：数据库Schema与RLS策略
- **阶段目标**: ...
- **阶段验收标准**: ...

#### 原子任务1.1: 实现`user_profiles`表
- **描述**: ...
- **验收标准**: ...

---
## 版本控制策略 (Version Control Strategy)

本文档 (Layer 2) 对应Git的 `task` 分支。
- 分支命名：`task/M1.1-auth-backend`
- 来源分支：`milestone/M1`
- 合并策略：MEM通过后PR合并回 `milestone/M1`

本PRP内“原子任务”对应Git的 `atomic` 分支。
- 分支命名：`atomic/M1.1.1-user-profiles`
- 来源分支：`task/M1.1-auth-backend`
- 合并策略：组件通过最小验证后回合到task分支

---
## Layer 3 执行说明
> 日志与时间戳: 所有开发活动记录到 `log_file`；时间戳使用 `date '+%Y-%m-%d %H:%M:%S'`。

