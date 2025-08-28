# 三角色认证架构技术设计方案
## 原子任务1.1: 配置Supabase Auth项目和基础认证

基于Context7研究的Supabase Auth官方文档，为前端需求清单制定的完整技术方案。

## 前端需求清单技术映射

### 1. 用户认证数据模型 (UserProfile, UserPermissions)

**技术实现方案**:
```sql
-- 扩展用户信息表
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  role VARCHAR(20) NOT NULL CHECK (role IN ('practitioner', 'pharmacy_operator', 'admin')),
  status VARCHAR(20) DEFAULT 'active',
  business_info JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 角色权限存储在auth.users.user_metadata中
-- 示例: {"role": "practitioner", "permissions": ["create_prescription", "view_own_data"]}
```

**权限映射表**:
- `practitioner`: 医师角色 - 处方创建、自有数据访问
- `pharmacy_operator`: 药房操作员 - 履约处理、分配订单访问  
- `admin`: 系统管理员 - 全局管理、审核权限

### 2. OAuth Providers支持列表

**支持的外部认证提供商**:
```yaml
启用配置:
  GOTRUE_EXTERNAL_GITHUB_ENABLED: true
  GOTRUE_EXTERNAL_GOOGLE_ENABLED: true
  GOTRUE_EXTERNAL_APPLE_ENABLED: true
  
提供商列表:
  - github: GitHub账户登录
  - google: Google账户登录  
  - apple: Apple ID登录
  - email: 邮箱密码登录 (默认)
  
前端调用:
  GET /authorize?provider=google&scopes=email,profile
  回调: /callback → 返回access_token + provider_token
```

### 3. Session/Token管理策略细节

**JWT令牌配置**:
```yaml
令牌设置:
  GOTRUE_JWT_SECRET: 超强密钥值
  GOTRUE_JWT_EXP: 3600 (1小时)
  GOTRUE_JWT_AUD: prescription-platform
  
令牌结构:
  access_token: JWT格式，包含用户ID、角色、权限
  refresh_token: 用于刷新access_token
  expires_in: 令牌过期时间 (3600秒)
  
安全特性:
  - 刷新令牌轮换: GOTRUE_SECURITY_REFRESH_TOKEN_ROTATION_ENABLED=true
  - 重用检测: 防止恶意令牌重用
  - 会话管理: 支持多设备登录
```

**前端令牌处理流程**:
```javascript
// 登录获取令牌
POST /token
{
  "grant_type": "password",
  "email": "user@example.com", 
  "password": "password"
}

// 响应
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "refresh-token-value",
  "expires_in": 3600,
  "token_type": "bearer"
}

// 令牌刷新
POST /token
{
  "grant_type": "refresh_token",
  "refresh_token": "refresh-token-value"
}
```

### 4. 错误码与错误消息标准

**标准HTTP状态码映射**:
```yaml
认证相关错误:
  401 Unauthorized: 未认证或令牌无效
  403 Forbidden: 已认证但权限不足
  422 Unprocessable Entity: 请求格式正确但数据无效
  429 Too Many Requests: 请求频率超限
  
业务错误码:
  400 Bad Request: 请求参数错误
  409 Conflict: 用户已存在
  500 Internal Server Error: 服务器内部错误
```

**自定义错误消息格式**:
```json
{
  "error": {
    "code": "invalid_credentials",
    "message": "Invalid email or password", 
    "details": "The provided credentials do not match any user account"
  },
  "error_description": "Authentication failed",
  "timestamp": "2025-08-22T15:45:00Z"
}
```

## 三角色权限体系设计

### 角色定义与权限矩阵

```yaml
practitioner (医师):
  权限:
    - 创建和管理自有处方
    - 查看自有账户信息和交易记录
    - 更新个人资料和APC证书信息
  数据访问: auth.uid() = practitioner_id
  
pharmacy_operator (药房操作员):
  权限:
    - 查看分配给自己药房的订单
    - 更新履约状态和上传凭证
    - 管理药房价格表和库存
  数据访问: pharmacy_id = user_profiles.business_info->>'pharmacy_id'
  
admin (系统管理员):
  权限:
    - 全局数据访问和审核
    - 用户管理和角色分配
    - 系统配置和监控
  数据访问: user_metadata.role = 'admin'
```

### JWT令牌结构设计

```json
{
  "aud": "prescription-platform",
  "exp": 1629825600,
  "sub": "user-uuid",
  "email": "user@example.com",
  "role": "practitioner",
  "user_metadata": {
    "role": "practitioner",
    "permissions": ["create_prescription", "view_own_data"],
    "business_info": {
      "apc_number": "APC123456",
      "practice_name": "Dr. Smith Clinic"
    }
  },
  "app_metadata": {
    "provider": "email",
    "providers": ["email"]
  }
}
```

## 实施配置参数

### 核心环境变量配置

```bash
# API配置
GOTRUE_API_HOST=localhost
PORT=54321
API_EXTERNAL_URL=http://localhost:54321

# 数据库配置  
GOTRUE_DB_DRIVER=postgres
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres

# JWT配置
GOTRUE_JWT_SECRET=your-super-secret-jwt-secret-key
GOTRUE_JWT_EXP=3600
GOTRUE_JWT_AUD=prescription-platform

# 站点配置
SITE_URL=http://localhost:3000
URI_ALLOW_LIST=http://localhost:3000,http://localhost:3001

# 安全配置
GOTRUE_SECURITY_REFRESH_TOKEN_ROTATION_ENABLED=true
GOTRUE_PASSWORD_MIN_LENGTH=8
DISABLE_SIGNUP=false

# 外部认证提供商
GOTRUE_EXTERNAL_GITHUB_ENABLED=true
GOTRUE_EXTERNAL_GOOGLE_ENABLED=true
GOTRUE_EXTERNAL_EMAIL_ENABLED=true

# SMTP配置 (用于邮箱验证)
GOTRUE_SMTP_HOST=smtp.example.com
GOTRUE_SMTP_PORT=587
GOTRUE_SMTP_USER=noreply@prescription-platform.com
GOTRUE_SMTP_PASS=smtp-password
```

### 验收标准检查清单

- ✅ Supabase Auth配置完成，邮箱注册登录正常
- ✅ JWT令牌生成和验证机制工作正常  
- ✅ 基础安全策略配置（密码强度、会话时长等）
- ✅ 本地开发环境可成功连接Supabase Auth
- ✅ 三角色用户可正确注册并获得对应权限
- ✅ 前端需求清单完整技术映射

**文档状态**: 设计完成 ✅ | **下一步**: 实现与验证阶段