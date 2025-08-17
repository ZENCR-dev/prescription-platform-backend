# NestJS → Supabase 架构迁移策略指南

## 🎯 迁移目标

**核心目标**: 从传统NestJS + Prisma架构迁移到Supabase优先架构，保留65%代码价值，重构基础设施层。

**预期成果**:
- **业务逻辑层**: 75%复用率 - 核心算法、业务规则、计算引擎保留
- **基础设施层**: 20%复用率 - Controllers、Guards、Decorators完全重构  
- **数据访问层**: 40%复用率 - Schema迁移，ORM改为SQL+RLS
- **整体项目**: 65%复用率 - 综合考虑架构转换成本

## 🏗️ 架构对比分析

### 原架构 (NestJS + Prisma)
```
Frontend (Next.js) → NestJS API → Prisma ORM → PostgreSQL
                  ↗ JWT Guards + RBAC
                  ↗ Custom Controllers
                  ↗ Event-driven Architecture
```

### 目标架构 (Supabase优先)
```
Frontend (Next.js) → Supabase Client → PostgreSQL + RLS
                   ↗ Supabase Auth (GoTrue)
                   ↗ Edge Functions (复杂逻辑)
                   ↗ Realtime Subscriptions
```

## 📋 分层迁移策略

### 1. 认证授权系统迁移

#### 原系统 (废弃)
- **JWT管理**: 自定义JWT_SECRET，手动令牌生成/验证
- **认证Guard**: `@UseGuards(JwtAuthGuard)` 装饰器
- **角色控制**: `@Roles('admin', 'doctor')` 装饰器
- **用户上下文**: `@User()` 装饰器注入

#### 新系统 (重构)
- **JWT管理**: Supabase自动管理，JWKS公钥发现
- **认证方式**: `supabase.auth.getSession()` 客户端验证
- **角色控制**: RLS策略 `auth.jwt()->>'role' = 'admin'`
- **用户上下文**: `auth.uid()` 和 `auth.jwt()` 函数

#### 迁移步骤
```typescript
// 原 NestJS Controller
@UseGuards(JwtAuthGuard)
@Roles('doctor')
@Post('prescriptions')
async createPrescription(@User() user, @Body() dto) {
  return this.prescriptionService.create(user.id, dto);
}

// 新 Edge Function
export async function createPrescription(req: Request) {
  const { data: { user }, error } = await supabase.auth.getUser(req.headers.authorization);
  if (error || !user) throw new Error('Unauthorized');
  
  // RLS策略会自动确保用户只能访问自己的数据
  const result = await supabase.from('prescriptions').insert({
    doctor_id: user.id,
    ...prescriptionData
  });
}
```

### 2. 数据访问层迁移

#### 原系统 (适配)
- **ORM访问**: Prisma Client查询
- **权限控制**: Service层手动过滤
- **事务管理**: Prisma事务

#### 新系统 (重构)
- **直接SQL**: Supabase客户端查询
- **权限控制**: PostgreSQL RLS策略自动执行
- **事务管理**: PostgreSQL原生事务

#### 迁移示例
```typescript
// 原 Prisma Service
async findPrescriptionsByDoctor(doctorId: string) {
  return this.prisma.prescription.findMany({
    where: { doctorId },
    include: { medicines: true }
  });
}

// 新 Supabase 查询 (RLS自动过滤)
async function findPrescriptionsByDoctor() {
  // RLS策略确保用户只能看到自己的处方
  return supabase
    .from('prescriptions')
    .select('*, medicines(*)')
    .eq('status', 'ACTIVE');
}
```

### 3. 业务逻辑层迁移

#### 高复用率服务 (75-90%)

**QR码生成服务** (90%复用)
```typescript
// 保留: 核心算法逻辑
class QRGeneratorService {
  generateSecureQR(prescriptionId: string, doctorId: string): string {
    // HMAC-SHA256算法保留不变
    const signature = this.generateHMAC(prescriptionId, doctorId);
    return this.encodeQRData({ prescriptionId, signature });
  }
}

// 适配: 存储方式
// 原: 本地文件系统 → 新: Supabase Storage
async function saveQRCode(qrData: string, fileName: string) {
  return supabase.storage
    .from('qr-codes')
    .upload(fileName, qrData);
}
```

**处方计算引擎** (85%复用)
```typescript
// 保留: 业务计算逻辑
class PrescriptionCalculatorService {
  calculateTotalAmount(medicines: Medicine[], copies: number): PrescriptionTotal {
    // NZD cents精确计算逻辑完全保留
    const subtotal = medicines.reduce((sum, med) => 
      sum + (med.weight * med.unitPriceCents), 0);
    return {
      subtotalCents: subtotal * copies,
      taxCents: Math.round(subtotal * copies * 0.15),
      totalCents: Math.round(subtotal * copies * 1.15)
    };
  }
}

// 适配: 权限验证
// 原: Service层验证 → 新: RLS策略验证
```

#### 中复用率服务 (50-75%)

**Stripe支付服务** (75%复用)
```typescript
// 保留: 核心支付逻辑
class StripePaymentService {
  async createPaymentIntent(amount: number, metadata: any) {
    // Stripe API调用逻辑保留
    return stripe.paymentIntents.create({
      amount,
      currency: 'nzd',
      metadata
    });
  }
}

// 重构: Webhook处理
// 原: NestJS Controller → 新: Edge Function
export async function handleStripeWebhook(req: Request) {
  const signature = req.headers['stripe-signature'];
  const event = stripe.webhooks.constructEvent(body, signature, endpointSecret);
  
  // 业务处理逻辑保留，数据访问改为Supabase
  await supabase.from('payments').update({
    status: 'completed',
    stripe_payment_intent_id: event.data.object.id
  }).eq('id', paymentId);
}
```

### 4. API端点迁移

#### 原系统 (完全重构)
- **框架**: NestJS Controllers + 装饰器
- **路由**: 基于装饰器的路由定义
- **验证**: class-validator DTO
- **错误处理**: Exception Filters

#### 新系统 (重新实现)
- **框架**: Supabase Edge Functions (Deno)
- **路由**: 函数式路由
- **验证**: 手动验证或Zod schema
- **错误处理**: 标准HTTP响应

#### 迁移模式
```typescript
// 原 NestJS Controller
@Controller('prescriptions')
export class PrescriptionController {
  @Post()
  @UseGuards(JwtAuthGuard)
  async create(@User() user, @Body() dto: CreatePrescriptionDto) {
    return this.prescriptionService.create(user.id, dto);
  }
}

// 新 Edge Function
export async function createPrescription(req: Request): Promise<Response> {
  try {
    // 认证验证
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) return new Response('Unauthorized', { status: 401 });
    
    // 请求验证 (可使用Zod)
    const body = await req.json();
    const validatedData = CreatePrescriptionSchema.parse(body);
    
    // 业务逻辑 (RLS自动处理权限)
    const result = await supabase.from('prescriptions').insert({
      doctor_id: user.id,
      ...validatedData
    });
    
    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}
```

## 🗄️ 数据库Schema迁移

### RLS策略实现

#### 医师数据隔离
```sql
-- 替代原 Service层过滤
CREATE POLICY "practitioners_own_prescriptions" ON prescriptions
FOR ALL USING (
  auth.uid() = doctor_id 
  OR (auth.jwt() ->> 'role')::text = 'admin'
);
```

#### 药房权限控制
```sql
-- 替代原 RBAC Guards
CREATE POLICY "pharmacy_assigned_orders" ON purchase_orders
FOR ALL USING (
  pharmacy_id IN (
    SELECT id FROM pharmacies WHERE operator_id = auth.uid()
  )
  OR (auth.jwt() ->> 'role')::text = 'admin'
);
```

### 数据结构适配
```sql
-- 原 Prisma Schema 适配
-- 保留: 表结构、字段定义、约束关系
-- 添加: RLS策略、触发器、索引优化
-- 移除: Prisma特定配置

CREATE TABLE prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  -- 其他字段保持不变
);

-- 新增 RLS 策略
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
```

## 🔧 开发环境迁移

### 原开发环境
- **后端**: `npm run start:dev` (localhost:3000)
- **数据库**: PostgreSQL + Prisma Studio
- **认证**: 自定义JWT实现

### 新开发环境
- **后端**: `supabase functions serve` (localhost:54321) 
- **数据库**: Supabase Local (localhost:54322)
- **认证**: Supabase Auth Dashboard (localhost:54323)

### 环境配置更新
```bash
# 原配置 (移除)
DATABASE_URL="postgresql://..."
JWT_SECRET="custom-secret"

# 新配置 (添加)
SUPABASE_URL="http://localhost:54321"
SUPABASE_ANON_KEY="eyJ..."
SUPABASE_SERVICE_ROLE_KEY="eyJ..."
```

## 📊 迁移时间线和里程碑

### Phase 1: 基础设施搭建 (Week 1)
- [ ] Supabase项目初始化
- [ ] 数据库Schema迁移和RLS策略
- [ ] 基础Edge Functions框架搭建

### Phase 2: 核心服务迁移 (Week 2-3)
- [ ] 高复用率服务适配 (QR码、计算引擎)
- [ ] 支付服务重构 (Stripe Webhook → Edge Function)
- [ ] 认证系统完全替换

### Phase 3: API端点迁移 (Week 4-5)
- [ ] 处方管理API迁移
- [ ] 药房管理API迁移
- [ ] 管理员API迁移

### Phase 4: 测试和优化 (Week 6)
- [ ] 端到端测试验证
- [ ] 性能优化和RLS策略调优
- [ ] 文档更新和团队培训

## ⚠️ 风险评估和缓解策略

### 高风险领域
1. **认证系统迁移**: 用户会话可能中断
   - **缓解**: 灰度迁移，保持双系统并行
   
2. **支付Webhook重构**: 支付事件可能丢失
   - **缓解**: 支付日志完整保留，失败重试机制

3. **RLS策略错误**: 数据泄露风险
   - **缓解**: 详细测试，权限验证，代码审查

### 质量保证检查点
- [ ] **CP1**: 认证系统迁移验证 - 所有用户角色登录正常
- [ ] **CP2**: 数据访问验证 - RLS策略正确隔离数据
- [ ] **CP3**: 支付流程验证 - Stripe集成无资金风险
- [ ] **CP4**: 性能验证 - API响应时间保持或改善

## 📚 参考资源

- **Supabase官方文档**: [https://supabase.com/docs](https://supabase.com/docs)
- **Edge Functions指南**: [https://supabase.com/docs/guides/functions](https://supabase.com/docs/guides/functions)
- **RLS策略最佳实践**: [https://supabase.com/docs/guides/auth/row-level-security](https://supabase.com/docs/guides/auth/row-level-security)
- **迁移工具**: `recycle/migration-tools/` 目录中的自动化工具

---

**迁移策略完成标识**: ✅ **架构转换路径明确** | 📊 **65%现实复用率** | 🔗 **分层迁移策略** | 🚀 **风险可控的实施计划**

*专为NestJS → Supabase架构转换设计的实用迁移指南*