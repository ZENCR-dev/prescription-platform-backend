# Backend Development Profile

## 后端开发环境配置
专用于Supabase Edge Functions + PostgreSQL + 业务逻辑开发的Claude Code配置。

### 技术栈焦点
- **运行时**: Deno, Edge Functions
- **数据库**: Supabase PostgreSQL, Row Level Security
- **认证**: Supabase Auth, JWT验证
- **支付**: Stripe API集成
- **计算**: 财务精确计算 (NZD cents)

### 开发优先级
1. **数据安全**: RLS策略，权限隔离
2. **计算精度**: 金融级精确计算
3. **性能优化**: 查询优化，索引设计
4. **可扩展性**: 模块化设计，服务解耦

### 常用命令
```bash
# Supabase开发环境
supabase start
supabase status
supabase logs

# 数据库管理
supabase migration new migration_name
supabase migration up
supabase db reset

# Edge Functions开发
supabase functions new function_name
supabase functions serve
supabase functions deploy function_name

# 类型生成
supabase gen types typescript > types/database.types.ts
```

### 项目结构规范
```
supabase/
├── functions/           # Edge Functions
│   ├── prescription-calculator/
│   ├── payment-processor/
│   ├── audit-logger/
│   └── qr-generator/
├── migrations/          # 数据库迁移
├── seed.sql            # 种子数据
└── config.toml         # Supabase配置

recycle/core-business/   # 可复用业务逻辑
├── prescription-calculator.service.ts
├── payment-stripe.service.ts
├── qr-generator.service.ts
└── audit-logger.service.ts
```

### RLS策略模板
```sql
-- 医师数据隔离
CREATE POLICY "practitioners_own_data" ON prescriptions
FOR ALL USING (auth.uid() = doctor_id OR auth.jwt() ->> 'role' = 'admin');

-- 药房数据隔离
CREATE POLICY "pharmacy_assigned_orders" ON purchase_orders
FOR ALL USING (
  pharmacy_id IN (SELECT id FROM pharmacies WHERE operator_id = auth.uid())
  OR auth.jwt() ->> 'role' = 'admin'
);

-- 隐私保护
CREATE POLICY "no_patient_data" ON prescriptions
FOR INSERT WITH CHECK (patient_name IS NULL);
```

### 财务计算规范
```typescript
// NZD Cents精确计算
import { Decimal } from 'decimal.js'

// 存储: INTEGER cents
// 显示: DECIMAL dollars
// 计算: Decimal.js精确运算

const amountCents = 24483  // $244.83
const amountDollars = new Decimal(amountCents).div(100)
```

### 性能优化清单
- [ ] 数据库查询索引优化
- [ ] Edge Functions冷启动优化
- [ ] 连接池配置和管理
- [ ] 缓存策略实施
- [ ] 并发控制和锁机制

### 安全检查清单
- [ ] RLS策略全覆盖
- [ ] JWT验证和角色权限
- [ ] SQL注入防护
- [ ] 敏感数据脱敏
- [ ] API限流和防护

### 监控和日志
- [ ] Supabase Analytics配置
- [ ] 错误追踪和告警
- [ ] 性能指标监控
- [ ] 审计日志完整性
- [ ] 业务指标统计

### 测试策略
- **单元测试**: Deno Test框架
- **集成测试**: Supabase客户端测试
- **性能测试**: 负载测试和基准测试
- **安全测试**: 权限渗透测试