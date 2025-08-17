# B2B2C中医处方履约平台 - API v1.0 文档

## ⚠️ 实施状态说明

**🚨 重要提示**: 本API文档当前处于规划阶段，尚未开始生效。Supabase数据库设计和后端功能开发正在进行中，实际API端点将在后端实施完成后逐步启用。

**当前开发状态**:
- ✅ API规范设计完成
- 🔄 Supabase数据库架构设计中
- ⏳ Edge Functions后端逻辑待开发
- ⏳ RLS权限策略待实施
- ⏳ 前端集成待开始

**预计启用时间**: 根据开发进度，预计在TASK01-06完成后开始分阶段启用API端点。

---

## 📋 API概览

**版本**: v1.0  
**基础URL**: `https://api.prescription-platform.com/v1`  
**认证方式**: JWT Bearer Token (Supabase Auth)  
**数据格式**: JSON  
**字符编码**: UTF-8  

## 🔐 认证体系

### Supabase Auth集成
**技术架构**: 基于Supabase GoTrue的现代认证系统
- **认证引擎**: Supabase Auth (GoTrue) 替代自定义JWT实现
- **签名算法**: ES256椭圆曲线算法，支持零停机密钥轮换
- **JWKS发现**: `https://project-id.supabase.co/auth/v1/.well-known/jwks.json`
- **会话管理**: 基于httpOnly Cookie和CSRF保护

### JWT认证流程
```http
POST /auth/login
Content-Type: application/json

{
  "email": "practitioner@example.com",
  "password": "securePassword"
}
```

**响应格式**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "email": "practitioner@example.com",
      "role": "practitioner|pharmacy|admin"
    }
  }
}
```

### 权限角色定义
基于Supabase RLS策略的数据隔离控制：

- **practitioner**: 医师用户
  - 权限范围: 仅能访问自有处方数据 (`auth.uid() = doctor_id`)
  - 核心功能: 处方创建、支付、账户管理、收益追踪
  - 数据隔离: 完全数据隔离，无法访问其他医师信息

- **pharmacy**: 药房用户  
  - 权限范围: 仅能处理分配的订单 (`pharmacy_id IN (SELECT id FROM pharmacies WHERE operator_id = auth.uid())`)
  - 核心功能: 扫码履约、价格表管理、批量结算、库存优化
  - 数据隔离: 基于药房ID的订单访问控制

- **admin**: 管理员用户
  - 权限范围: 全局数据访问 (`auth.jwt()->>'role' = 'admin'`)
  - 核心功能: 平台审核、用户管理、财务监控、合规保障
  - 特殊权限: 跨用户数据访问和系统配置管理

## 💊 处方业务流程

### 处方生命周期状态机
基于PRD业务规则的严格状态流转控制：

```
DRAFT → PAID → FULFILLED → COMPLETED
  ↓       ↓        ↓
CANCELLED ← ← ← ← ←
```

**状态转换规则**：
- `DRAFT → PAID`: 账户余额充足 + 支付确认
- `PAID → FULFILLED`: 药房扫码验证 + 履约凭证上传
- `FULFILLED → COMPLETED`: 管理员审核通过 + 资金结算
- `任意状态 → CANCELLED`: 业务异常或用户取消

**业务规则验证**：
- 处方创建: 医师权限验证 + 药品存在性检查 + 用法用量合规性
- 支付处理: 事务控制账户扣费 + 状态流转 + QR码生成
- 履约验证: 药房权限验证 + QR码有效性 + 凭证文件上传
- 审核确认: 管理员权限 + 履约质量评估 + 成本合规检查

### NZD财务计算引擎
**精确计算实现** (基于PRD财务规范)：

```typescript
// 处方总价计算示例
interface PrescriptionCalculation {
  medicines: Array<{
    medicineId: string
    weight: number        // 克重，精确到0.1g
    basePrice: number    // NZD cents，整数存储
  }>
  copies: number         // 帖数：1-30
  totalCents: number     // 总价：NZD cents
  totalDisplay: string   // 显示："$XX.XX NZD"
}

// 平台收益计算
platformRevenue = basePrice(医师收费) - pharmacyPrice(药房成本)
```

**计算保障机制**：
- 整数cents存储避免浮点误差
- Decimal.js确保计算精度
- 银行家舍入法符合金融标准
- 并发乐观锁防止账户不一致
- 完整审计日志满足合规要求

## 🏥 医师端API

### 处方管理
#### 创建处方草稿
```http
POST /prescriptions
Authorization: Bearer {token}
Content-Type: application/json

{
  "medicines": [
    {
      "medicineId": "uuid",
      "weight": 10.5,
      "instructions": "每日三次，饭后服用"
    }
  ],
  "copies": 7,
  "notes": "患者需要注意饮食调节"
}
```

#### 处方支付确认
```http
POST /prescriptions/{id}/pay
Authorization: Bearer {token}

{
  "paymentMethodId": "stripe_payment_method_id"
}
```

#### 获取处方列表
```http
GET /prescriptions?status=PAID&page=1&limit=20
Authorization: Bearer {token}
```

### 账户管理
#### 查看账户余额
```http
GET /practitioner/account
Authorization: Bearer {token}
```

**响应格式**:
```json
{
  "success": true,
  "data": {
    "balance_cents": 245000,
    "balance_display": "$2,450.00 NZD",
    "currency": "NZD"
  }
}
```

## 🏪 药房端API

### 订单管理
#### 扫码获取处方详情
```http
GET /pharmacy/scan/{qr_code}
Authorization: Bearer {token}
```

#### 上传履约凭证
```http
POST /pharmacy/orders/{orderId}/fulfill
Authorization: Bearer {token}
Content-Type: multipart/form-data

fulfillment_proof: <image_file>
notes: "配药完成，药材质量良好"
```

### 价格表管理
#### 上传价格表
```http
POST /pharmacy/price-lists
Authorization: Bearer {token}
Content-Type: multipart/form-data

price_list_file: <csv_file>
```

#### 获取价格表状态
```http
GET /pharmacy/price-lists
Authorization: Bearer {token}
```

### 财务管理
#### 申请批量提现
```http
POST /pharmacy/withdrawals
Authorization: Bearer {token}

{
  "purchase_order_ids": ["uuid1", "uuid2", "uuid3"],
  "bank_account": {
    "account_number": "12-3456-0123456-00",
    "account_name": "Pharmacy Name Ltd"
  }
}
```

## 👨‍💼 管理员API

### 审核管理
#### 获取待审核队列
```http
GET /admin/pending-reviews?type=price_list|purchase_order
Authorization: Bearer {token}
```

#### 审核价格表
```http
POST /admin/price-lists/{id}/review
Authorization: Bearer {token}

{
  "decision": "approved|rejected|pending",
  "notes": "审核意见和建议"
}
```

#### 审核采购订单
```http
POST /admin/purchase-orders/{id}/review  
Authorization: Bearer {token}

{
  "decision": "approved|rejected",
  "notes": "履约质量评估"
}
```

### 平台监控
#### 获取业务指标
```http
GET /admin/metrics?timeframe=7d&metrics=revenue,prescriptions,fulfillment_rate
Authorization: Bearer {token}
```

## 📊 通用响应格式

### 成功响应
```json
{
  "success": true,
  "data": {
    // 响应数据
  },
  "metadata": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "v1.0"
  }
}
```

### 错误响应  
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "账户余额不足",
    "details": {
      "current_balance": 1500,
      "required_amount": 2000
    }
  },
  "metadata": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "v1.0"
  }
}
```

## 🔍 错误码定义

### 业务错误码体系
基于PRD规范的统一错误处理机制：

| 错误码 | HTTP状态 | 业务分类 | 描述 | 解决方案 |
|--------|----------|----------|------|----------|
| `INSUFFICIENT_BALANCE` | 400 | 财务计算 | 账户余额不足 | 充值或检查账户状态 |
| `INVALID_QR_CODE` | 404 | 履约验证 | QR码无效或已过期 | 验证QR码格式和有效期 |
| `PRESCRIPTION_NOT_PAID` | 400 | 状态流转 | 处方未支付无法履约 | 完成支付流程 |
| `UNAUTHORIZED_ACCESS` | 403 | 权限控制 | RLS策略拒绝访问 | 检查用户角色和权限 |
| `PRICE_LIST_VIOLATION` | 400 | 价格审核 | 价格表违反basePrice约束 | 调整价格符合基准价格要求 |
| `VALIDATION_ERROR` | 400 | 数据验证 | 输入验证失败 | 检查请求参数格式和完整性 |
| `PRESCRIPTION_STATE_ERROR` | 400 | 状态机控制 | 处方状态转换违规 | 检查处方当前状态和允许操作 |
| `CONCURRENT_MODIFICATION` | 409 | 并发控制 | 乐观锁冲突 | 重新获取数据后重试操作 |
| `PAYMENT_PROCESSING_ERROR` | 402 | 支付集成 | Stripe支付处理失败 | 检查支付方式或联系客服 |
| `FILE_UPLOAD_ERROR` | 413 | 文件处理 | 文件上传失败 | 检查文件格式、大小限制 |
| `AUDIT_LOG_REQUIRED` | 400 | 合规要求 | 关键操作缺少审计信息 | 提供完整的操作审计数据 |
| `RLS_POLICY_VIOLATION` | 403 | 数据安全 | 违反行级安全策略 | 验证数据访问权限 |

## 🔄 实时订阅

### WebSocket连接
```javascript
// 处方状态更新订阅
const subscription = supabase
  .channel('prescription-updates')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public', 
    table: 'prescriptions',
    filter: `doctor_id=eq.${userId}`
  }, (payload) => {
    console.log('处方状态更新:', payload)
  })
  .subscribe()
```

### 支持的实时事件
- `prescription.status_changed` - 处方状态变更
- `purchase_order.created` - 新采购订单创建
- `payment.completed` - 支付完成通知
- `account.balance_updated` - 账户余额更新

## 🔒 数据隐私与合规

### 患者隐私保护红线
**强制要求** (基于PRD安全规范)：
- **❌ 禁止收集**: 系统不得存储任何患者个人身份信息
- **✅ 处方匿名化**: 处方仅包含医师信息、药品信息、用法用量
- **✅ GDPR/HIPAA兼容**: 符合国际隐私保护标准和医疗合规要求

### 数据安全保障机制
- **端到端加密**: 数据传输和存储全程加密保护
- **RLS数据隔离**: 数据库行级安全策略完全覆盖
- **审计追踪机制**: 完整记录所有操作用于合规审查
- **敏感信息保护**: 日志和监控数据必须脱敏处理

### Supabase安全机制
- **密码管理**: Supabase Auth自动处理密码哈希和盐值
- **会话安全**: 基于httpOnly Cookie和CSRF保护
- **API安全**: 自动HTTPS、CORS配置、请求限流
- **数据加密**: 数据库连接和数据传输端到端加密

## 📈 性能标准

### 技术性能要求
基于PRD规范的性能基准：

- **响应时间**: P95 < 500ms, P99 < 1000ms
- **可用性**: > 99.5% 月度可用性
- **请求限流**: 基于角色的差异化限流
  - practitioner: 1000 requests/hour
  - pharmacy: 1500 requests/hour  
  - admin: 5000 requests/hour
- **数据传输**: 强制HTTPS，支持gzip压缩
- **并发处理**: 支持1000+ 并发连接
- **数据库查询**: 95%查询响应时间 < 100ms

### 财务计算精度标准
- **存储精度**: NZD cents整数存储，避免浮点误差
- **计算引擎**: Decimal.js精确计算，银行级精度
- **舍入规则**: 银行家舍入法 (四舍六入五成双)
- **审计要求**: 所有财务操作完整审计记录

### 安全性能要求
- **JWT验证**: ES256算法，< 10ms验证时间
- **RLS策略**: 数据库层权限检查，< 5ms额外延迟
- **加密传输**: TLS 1.3，完整数据传输保护

## 🔧 开发工具

### Postman集合
[下载Postman API集合](./prescription-platform-api.postman_collection.json)

### SDK支持
- **JavaScript/TypeScript**: `@prescription-platform/api-client`
- **Python**: `prescription-platform-python`
- **cURL示例**: 详见各API端点说明

---

**文档维护**: 本文档与代码同步更新，版本变更记录见 [APIv1_log.md](./APIv1_log.md)

**技术支持**: api-support@prescription-platform.com  
**最后更新**: 2024-01-15T10:30:00Z