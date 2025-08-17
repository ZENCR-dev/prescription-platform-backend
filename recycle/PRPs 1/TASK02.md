# TASK02: API日志系统和基础数据扩展

## 📋 阶段目标

在TASK01成功集成Supabase starter kit的基础上，实施API日志记录系统，扩展基础数据表结构，确保所有API调用被正确记录在数据库中，为后续业务功能开发建立完整的监控和审计基础。

**验收标准**:
- [ ] 创建api_logs表记录所有API调用
- [ ] 实现API日志中间件自动记录请求
- [ ] 创建用户profile扩展表
- [ ] 在Supabase Dashboard中能查看API调用记录  
- [ ] 验证日志记录功能完整性
- [ ] 为未来业务扩展预留数据结构

## 🎯 最小单位任务列表

### Phase A: API日志表设计 (1.5小时) 🔄
**前后端对齐节点**: 数据库日志表结构建立
**SuperClaude工具建议**: `/sc:implement --persona-backend --persona-security --seq --c7` (数据库设计和安全策略)
- **A1**: 设计api_logs表结构和字段
- **A2**: 创建数据库迁移文件
- **A3**: 实施RLS策略保护日志数据
- **A4**: 验证表创建和权限设置

### Phase B: API日志中间件实现 (1.5小时) 🔄  
**前后端对齐节点**: 自动日志记录机制建立
**SuperClaude工具建议**: `/sc:implement --persona-backend --seq --c7` (中间件开发和API模式)
- **B1**: 创建API日志记录中间件
- **B2**: 集成到Next.js API路由中
- **B3**: 实现请求响应时间计算
- **B4**: 测试日志记录功能

### Phase C: 用户Profile扩展 (0.5小时) 🔄
**前后端对齐节点**: 用户数据扩展准备
**SuperClaude工具建议**: `/sc:implement --persona-backend --persona-security --seq` (数据库扩展和RLS策略)
- **C1**: 创建user_profiles扩展表
- **C2**: 设置与auth.users的关联
- **C3**: 实施基础RLS策略
- **C4**: 验证用户数据关联

### Phase D: 功能测试和验证 (0.5小时)
**前后端对齐节点**: 完整功能验证
**SuperClaude工具建议**: `/sc:test --persona-backend --seq --play` (系统测试和验证)
- **D1**: 测试API调用日志记录
- **D2**: 验证Supabase Dashboard中的日志查看
- **D3**: 测试不同用户权限的日志访问
- **D4**: 确认系统性能无明显影响

## 🔧 数据库结构设计

### API日志表结构
```sql
-- API调用日志表
CREATE TABLE api_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  method TEXT NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),
  path TEXT NOT NULL,
  status_code INTEGER CHECK (status_code >= 100 AND status_code < 600),
  response_time_ms INTEGER CHECK (response_time_ms >= 0),
  ip_address INET,
  user_agent TEXT,
  request_body JSONB,
  response_body JSONB,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引优化查询性能
CREATE INDEX idx_api_logs_user_id ON api_logs(user_id);
CREATE INDEX idx_api_logs_created_at ON api_logs(created_at DESC);
CREATE INDEX idx_api_logs_path ON api_logs(path);
CREATE INDEX idx_api_logs_status ON api_logs(status_code);
```

### 用户Profile扩展表
```sql
-- 用户扩展信息表
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'practitioner', 'pharmacy')),
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 更新时间自动更新触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### RLS安全策略
```sql
-- API日志RLS策略
ALTER TABLE api_logs ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的API日志
CREATE POLICY "users_own_api_logs" ON api_logs
FOR SELECT USING (auth.uid() = user_id);

-- 管理员可以查看所有日志
CREATE POLICY "admin_view_all_logs" ON api_logs
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- 用户Profile RLS策略
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 用户可以查看和更新自己的profile
CREATE POLICY "users_own_profile" ON user_profiles
FOR ALL USING (auth.uid() = user_id);

-- 允许插入新的profile记录
CREATE POLICY "users_insert_profile" ON user_profiles
FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## 🔧 API日志中间件实现

### Next.js Middleware实现
```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createServerClient } from '@supabase/ssr'

export async function middleware(request: NextRequest) {
  const startTime = Date.now()
  
  // 创建Supabase客户端
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => 
            request.cookies.set(name, value)
          )
        },
      },
    }
  )

  // 获取用户session
  const { data: { user } } = await supabase.auth.getUser()
  
  const response = NextResponse.next()
  
  // 记录API日志（异步执行，不阻塞请求）
  if (request.nextUrl.pathname.startsWith('/api/')) {
    const responseTime = Date.now() - startTime
    
    // 异步记录日志
    recordApiLog({
      userId: user?.id,
      method: request.method,
      path: request.nextUrl.pathname,
      responseTime,
      ipAddress: request.ip || request.headers.get('x-forwarded-for'),
      userAgent: request.headers.get('user-agent'),
    }).catch(console.error)
  }

  return response
}

async function recordApiLog(logData: {
  userId?: string
  method: string
  path: string
  responseTime: number
  ipAddress?: string | null
  userAgent?: string | null
}) {
  // 创建服务端Supabase客户端记录日志
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      cookies: {
        getAll: () => [],
        setAll: () => {},
      },
    }
  )

  await supabase.from('api_logs').insert({
    user_id: logData.userId,
    method: logData.method,
    path: logData.path,
    response_time_ms: logData.responseTime,
    ip_address: logData.ipAddress,
    user_agent: logData.userAgent,
    status_code: 200, // 默认成功状态，实际应用中需要获取真实状态码
  })
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### API路由日志增强
```typescript
// lib/api-logger.ts
import { createServerClient } from '@supabase/ssr'
import { NextRequest, NextResponse } from 'next/server'

export function withApiLogging<T>(
  handler: (request: NextRequest) => Promise<NextResponse<T>>
) {
  return async (request: NextRequest): Promise<NextResponse<T>> => {
    const startTime = Date.now()
    let statusCode = 200
    let errorMessage: string | null = null

    try {
      const response = await handler(request)
      statusCode = response.status
      return response
    } catch (error) {
      statusCode = 500
      errorMessage = error instanceof Error ? error.message : 'Unknown error'
      throw error
    } finally {
      // 记录API调用日志
      const responseTime = Date.now() - startTime
      
      recordDetailedApiLog({
        method: request.method,
        path: request.nextUrl.pathname,
        statusCode,
        responseTime,
        errorMessage,
        request,
      }).catch(console.error)
    }
  }
}

async function recordDetailedApiLog(data: {
  method: string
  path: string
  statusCode: number
  responseTime: number
  errorMessage?: string | null
  request: NextRequest
}) {
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      cookies: {
        getAll: () => [],
        setAll: () => {},
      },
    }
  )

  // 获取用户ID
  const authHeader = data.request.headers.get('authorization')
  let userId: string | null = null
  
  if (authHeader) {
    try {
      const { data: { user } } = await supabase.auth.getUser(
        authHeader.replace('Bearer ', '')
      )
      userId = user?.id || null
    } catch {
      // 忽略认证错误
    }
  }

  await supabase.from('api_logs').insert({
    user_id: userId,
    method: data.method,
    path: data.path,
    status_code: data.statusCode,
    response_time_ms: data.responseTime,
    ip_address: data.request.ip || data.request.headers.get('x-forwarded-for'),
    user_agent: data.request.headers.get('user-agent'),
    error_message: data.errorMessage,
  })
}
```

## ✅ 完成检查清单

### 🗄️ 数据库表结构验证
- [ ] **API日志表**: api_logs表创建成功，字段约束生效
- [ ] **用户扩展表**: user_profiles表创建，关联auth.users正确
- [ ] **索引优化**: 关键查询路径索引创建完成
- [ ] **触发器**: 自动更新时间戳触发器工作正常

### 🔒 RLS策略安全验证  
- [ ] **API日志隔离**: 用户只能查看自己的API调用记录
- [ ] **管理员权限**: 管理员角色可以查看所有日志
- [ ] **Profile隔离**: 用户只能访问自己的profile数据
- [ ] **数据保护**: 敏感信息访问控制生效

### ⚡ 中间件功能验证
- [ ] **日志记录**: API调用自动记录到数据库
- [ ] **性能影响**: 日志记录不影响API响应时间
- [ ] **错误处理**: 记录失败不影响正常API功能
- [ ] **数据完整**: 记录包含完整的请求响应信息

### 🔄 集成测试验证
- [ ] **Dashboard查看**: 在Supabase Dashboard中能查看api_logs数据
- [ ] **实时记录**: API调用立即在数据库中可见
- [ ] **权限控制**: 不同用户看到不同的日志记录
- [ ] **性能监控**: 系统整体性能无明显下降

## 🔧 实施步骤

### 数据库迁移执行
```bash
# 1. 创建迁移文件
supabase migration new create_api_logs_and_profiles

# 2. 编辑迁移文件，添加上述SQL代码
# 路径: supabase/migrations/[timestamp]_create_api_logs_and_profiles.sql

# 3. 应用迁移
supabase db reset  # 本地开发环境
# 或
supabase migration up  # 应用新迁移

# 4. 生成TypeScript类型
supabase gen types typescript > types/database.types.ts
```

### 代码集成步骤
```bash
# 1. 创建API日志工具文件
mkdir -p lib
touch lib/api-logger.ts

# 2. 更新middleware.ts文件
# 添加API日志记录逻辑

# 3. 创建测试API端点
mkdir -p app/api/test
touch app/api/test/route.ts

# 4. 测试日志记录功能
npm run dev
curl http://localhost:3000/api/test
```

### 验证和测试
```bash
# 1. 验证数据库表创建
supabase db list

# 2. 测试API调用
curl -X GET http://localhost:3000/api/test
curl -X POST http://localhost:3000/api/test -d '{"test": "data"}'

# 3. 查看日志记录
# 在Supabase Dashboard > Table Editor > api_logs 查看记录

# 4. 性能测试
# 使用浏览器开发者工具监控API响应时间
```

## 🔄 进度追踪和问题解决

### 常见问题和解决方案

#### 🚨 RLS策略阻止日志写入
**症状**: API日志无法写入数据库
**解决方案**:
```sql
-- 确保service role key有写入权限
-- 或者为api_logs表添加插入策略
CREATE POLICY "service_role_insert_logs" ON api_logs
FOR INSERT WITH CHECK (true);
```

#### 🚨 中间件性能影响
**症状**: API响应时间明显增加
**解决方案**:
```typescript
// 使用异步日志记录，不阻塞请求响应
Promise.resolve().then(() => recordApiLog(logData))
```

#### 🚨 TypeScript类型错误
**症状**: 数据库类型定义与实际表结构不匹配
**解决方案**:
```bash
# 重新生成类型定义
supabase gen types typescript --project-id [project-id] > types/database.types.ts
```

### 下一阶段衔接要求

**后续任务前置条件确认**:
- [ ] API日志系统完整运行，所有调用被记录
- [ ] 用户profile扩展表创建成功，为业务功能准备
- [ ] RLS策略保护数据安全，权限控制生效  
- [ ] 系统性能无明显影响，日志记录不阻塞业务

**交付物检查清单**:
- [ ] 完整的数据库迁移文件
- [ ] API日志中间件和工具函数
- [ ] 更新的TypeScript类型定义
- [ ] 测试API端点和验证脚本
- [ ] Supabase Dashboard中的日志查看验证

**技术债务和优化点**:
- [ ] 考虑实施日志数据归档策略（避免表过大）
- [ ] 评估集成更详细的性能监控
- [ ] 计划实施日志数据分析功能
- [ ] 考虑添加API限流和安全监控

---

**🎯 TASK02完成标识**: API日志系统实施完成，能够自动记录所有API调用到数据库，用户profile扩展表建立，在Supabase Dashboard中可以查看完整的API调用记录，为后续业务功能开发提供了完善的监控和审计基础。