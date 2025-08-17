# Technical Setup Validation Checklist

Based on INITIAL.md Lines 332-340 (技术验证检查点)

## 基础环境配置验证

### 开发工具安装验证
- [ ] Node.js 18+ 安装验证
  ```bash
  node --version  # Should be >= 18.0.0
  npm --version   # Should be >= 8.0.0
  ```

- [ ] Supabase CLI 安装验证
  ```bash
  supabase --version  # Should be latest stable
  supabase login      # Should authenticate successfully
  ```

- [ ] Vercel CLI 安装验证
  ```bash
  vercel --version    # Should be latest stable
  vercel login        # Should authenticate successfully
  ```

### Supabase项目配置验证
- [ ] Supabase项目创建和本地开发环境连接
  ```bash
  supabase init
  supabase start      # Should start on localhost:54321
  curl http://localhost:54321/health  # Should return OK
  ```

- [ ] 数据库连接测试
  ```bash
  supabase db reset   # Should initialize database
  supabase db status  # Should show running status
  ```

### 前端项目配置验证 (协作参考)
- [ ] Next.js项目初始化和TypeScript配置
  ```bash
  npm create next-app@latest --typescript
  npm run dev         # Should start on localhost:3000
  curl http://localhost:3000  # Should return HTML
  ```

- [ ] 环境变量配置验证
  ```bash
  # .env.local should contain:
  # NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
  # NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
  # SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
  ```

### 数据库Schema验证
- [ ] 基础数据库Schema设计和迁移测试
  ```bash
  supabase migration new initial_schema
  supabase db push    # Should apply migrations successfully
  ```

- [ ] RLS策略测试
  ```sql
  -- Test basic RLS policy
  SELECT * FROM auth.users;  # Should respect row-level security
  ```

### Edge Functions验证
- [ ] 第一个Edge Function部署成功
  ```bash
  supabase functions new hello-world
  supabase functions deploy hello-world
  curl -X POST http://localhost:54321/functions/v1/hello-world
  ```

### 跨域访问配置验证
- [ ] 前后端跨域访问配置验证
  ```bash
  # Test CORS from frontend (localhost:3000) to Supabase (localhost:54321)
  fetch('http://localhost:54321/rest/v1/', {
    headers: {
      'apikey': 'your-anon-key',
      'Authorization': 'Bearer your-anon-key'
    }
  })
  ```

### 多端口开发环境验证
- [ ] 多端口开发环境配置测试
  ```bash
  # Port 3000: Next.js development server
  npm run dev -- --port 3000
  
  # Port 3001: Alternative frontend instance
  npm run dev -- --port 3001
  
  # Port 3002-3009: Additional development instances
  # All should be accessible and CORS-enabled
  ```

### 本地后端服务验证
- [ ] 本地后端服务集成测试
  ```bash
  # Start local backend service on port 4000
  npm run start:backend  # Should start on localhost:4000
  curl http://localhost:4000/health  # Should return service status
  ```

### 综合集成验证
- [ ] 端到端连接测试
  ```bash
  # Frontend (3000) → Supabase (54321) → Database
  # Should complete full request chain
  ```

- [ ] 认证流程测试
  ```bash
  # Test Supabase Auth integration
  # Should handle signup/login/logout successfully
  ```

- [ ] 实时订阅测试
  ```bash
  # Test Supabase Realtime
  # Should handle WebSocket connections
  ```

## 医疗平台特殊验证

### HIPAA合规基础配置
- [ ] 数据加密配置验证
  ```bash
  # Verify database encryption at rest
  # Verify connection encryption (SSL/TLS)
  ```

- [ ] 审计日志配置
  ```bash
  # Verify audit logging is enabled
  # Test audit log entry creation
  ```

### 安全配置验证
- [ ] RLS策略安全验证
  ```sql
  -- Test user data isolation
  -- Verify no unauthorized access
  ```

- [ ] API安全验证
  ```bash
  # Test API rate limiting
  # Verify authentication requirements
  ```

## 性能基准验证

### 响应时间验证
- [ ] API响应时间基准测试
  ```bash
  # Should achieve P95 < 500ms for API calls
  curl -w "@curl-format.txt" http://localhost:54321/rest/v1/
  ```

### 数据库性能验证
- [ ] 基础查询性能测试
  ```sql
  -- Test basic CRUD operations performance
  -- Verify index effectiveness
  ```

## 失败处理和恢复

### 常见问题解决
```bash
# Supabase connection issues
supabase stop && supabase start

# Port conflicts
lsof -ti:54321 | xargs kill -9

# Database reset
supabase db reset --linked

# Environment variables refresh
source .env.local
```

### 验证失败处理流程
1. 识别具体失败点
2. 查看相关日志文件
3. 应用标准解决方案
4. 重新运行验证检查
5. 记录问题和解决方案

## 验证完成确认

### 最终检查清单
- [ ] 所有基础服务正常运行
- [ ] 前后端通信正常
- [ ] 数据库连接和操作正常
- [ ] 认证和授权功能正常
- [ ] 开发环境稳定性验证
- [ ] 团队成员环境一致性确认

### 文档更新
- [ ] 更新环境配置文档
- [ ] 记录特殊配置步骤
- [ ] 更新故障排除指南
- [ ] 同步团队配置标准