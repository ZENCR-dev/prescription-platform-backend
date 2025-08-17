# API v1.0 版本变更日志

## 日志记录规范

本文档记录API版本的技术变更，包括端点修改、数据格式调整、配置更新。记录格式遵循：
- 操作事实记录，不含评价性语言
- 按时间顺序记录变更
- 明确技术影响和迁移要求

## 变更记录

### v1.0.0 (2024-01-15) - 初始规范

**Added**:
- Endpoint: POST /auth/login (JWT认证)
- Endpoint: POST /auth/logout (会话管理)
- Endpoint: POST /auth/refresh (令牌刷新)
- Authentication: JWT Bearer token (ES256算法)
- Database: Supabase PostgreSQL with RLS policies
- Data format: JSON request/response structure
- Error handling: 统一错误响应格式 (success/error fields)
- Real-time: Supabase Realtime订阅支持

**API Endpoints**: 25个端点
- Authentication: 4个端点 (login, logout, refresh, forgot-password)
- Practitioner: 8个端点 (prescriptions, account management)
- Pharmacy: 7个端点 (orders, price lists, withdrawals)
- Admin: 6个端点 (reviews, metrics, user management)

**Technical Specifications**:
- Character encoding: UTF-8
- Rate limiting: 1000-5000 requests/hour (role-based)
- Response time requirement: P95 < 500ms
- HTTPS: Mandatory TLS 1.3
- Financial precision: NZD cents (INTEGER storage)
- Database: Row Level Security policies implemented

**Security Measures**:
- JWT signing: ES256 elliptic curve algorithm
- JWKS endpoint: /.well-known/jwks.json
- Data isolation: RLS policies for practitioner/pharmacy separation
- Privacy compliance: Zero patient data collection
- Authentication: Supabase GoTrue integration

**Business Logic**:
- Prescription states: DRAFT, PAID, FULFILLED, COMPLETED, CANCELLED
- Financial calculations: Decimal.js precision, banker's rounding
- Price constraints: basePrice validation for pharmacy submissions
- Audit requirements: Complete operation logging

**Environment Configuration**:
- SUPABASE_URL: Required
- SUPABASE_ANON_KEY: Required
- SUPABASE_SERVICE_ROLE_KEY: Required (server-side only)

---

## 兼容性政策

### 版本兼容性
- v1.x: 向后兼容保证
- 响应结构: 仅新增字段，不删除现有字段
- 认证机制: JWT格式维持稳定

### Breaking Changes处理
- 主版本升级: Breaking changes仅在v2.0+
- 通知周期: 功能废弃提前3个月通知
- 迁移期: 新旧版本并行支持6个月
- 迁移工具: 提供自动迁移脚本

### 变更请求流程
1. GitHub Issue提交
2. 技术影响评估
3. API设计审查
4. 开发实施
5. 兼容性测试
6. 文档同步更新

---

**维护**: Backend Development Team  
**更新**: 每月15日  
**记录**: 仅技术变更，不含规划内容