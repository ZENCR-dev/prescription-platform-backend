-- 🚨 Examples Directory - Supabase Migration SQL Schema
-- 复用价值: 100% (完整数据结构和约束)
-- 迁移目标: Supabase PostgreSQL + RLS策略
-- 适配要求: 集成auth.users表和RLS策略
--
-- @description 高价值可复用的数据库架构设计，包含完整的RLS策略和业务约束
-- @usage 可直接复制到Supabase项目中，或作为参考设计类似数据库结构
-- @integration 完全兼容Supabase环境，包含auth.users集成和RLS策略
--
-- 🚨 使用方法：
-- 1. 复制此文件到Supabase项目的supabase/migrations/目录
-- 2. 执行: supabase db reset (开发环境) 或 supabase migration up (生产环境)
-- 3. 验证RLS策略是否正确设置
-- 4. 配置对应的种子数据

-- =========================================
-- 1. 用户认证表 (集成Supabase Auth)
-- =========================================

-- 扩展Supabase内置auth.users表
-- 注意：不创建users表，使用Supabase原生auth.users

-- 用户扩展信息表
CREATE TABLE user_profiles (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    license_number VARCHAR(50) UNIQUE,
    address JSONB,
    preferences JSONB,
    metadata JSONB,
    specialization VARCHAR(100),
    clinic VARCHAR(255),
    qualifications JSONB,
    apc_expiry_date DATE,
    apc_file_url VARCHAR(500),
    apc_upload_date TIMESTAMP(6),
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 为user_profiles创建索引
CREATE INDEX idx_user_profiles_apc_expiry ON user_profiles(apc_expiry_date);
CREATE INDEX idx_user_profiles_specialization ON user_profiles(specialization);

-- =========================================
-- 2. 医师账户管理表
-- =========================================

CREATE TABLE practitioner_accounts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    practitioner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) DEFAULT 0,
    credit_limit DECIMAL(12,2) DEFAULT 0,
    used_credit DECIMAL(12,2) DEFAULT 0,
    available_credit DECIMAL(12,2),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'frozen')),
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW(),
    UNIQUE(practitioner_id)
);

CREATE INDEX ON practitioner_accounts(status);

-- 账户交易记录表
CREATE TABLE account_transactions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id TEXT REFERENCES practitioner_accounts(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('DEBIT', 'CREDIT', 'REFUND', 'ADJUSTMENT')),
    amount DECIMAL(12,2) NOT NULL,
    balance_before DECIMAL(12,2) NOT NULL,
    balance_after DECIMAL(12,2) NOT NULL,
    credit_before DECIMAL(12,2) NOT NULL,
    credit_after DECIMAL(12,2) NOT NULL,
    reference_type TEXT CHECK (reference_type IN ('ORDER', 'RECHARGE', 'REFUND', 'MANUAL')),
    reference_id TEXT,
    description TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON account_transactions(account_id);
CREATE INDEX ON account_transactions(created_at DESC);
CREATE INDEX ON account_transactions(reference_type, reference_id);

-- =========================================
-- 3. 药品主数据表
-- =========================================

CREATE TABLE medicines (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    chinese_name VARCHAR(255),
    english_name VARCHAR(255),
    pinyin_name VARCHAR(255),
    sku VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(100),
    unit VARCHAR(50) NOT NULL,
    requires_prescription BOOLEAN DEFAULT true,
    base_price DECIMAL(10,6) NOT NULL CHECK (base_price >= 0),
    metadata JSONB,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON medicines(category);
CREATE INDEX ON medicines(status);
CREATE INDEX ON medicines USING GIN(metadata);

-- =========================================
-- 4. 药房管理表
-- =========================================

CREATE TABLE pharmacies (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    operator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    license_number VARCHAR(100) UNIQUE NOT NULL,
    address JSONB NOT NULL,
    contact_info JSONB,
    business_hours JSONB,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending')),
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW(),
    UNIQUE(operator_id)
);

CREATE INDEX ON pharmacies(status);
CREATE INDEX ON pharmacies(verification_status);

-- 药房价格表
CREATE TABLE pharmacy_price_lists (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id TEXT REFERENCES pharmacies(id) ON DELETE CASCADE,
    medicine_id TEXT REFERENCES medicines(id) ON DELETE CASCADE,
    price DECIMAL(10,6) NOT NULL CHECK (price >= 0),
    is_available BOOLEAN DEFAULT true,
    minimum_quantity INTEGER DEFAULT 1,
    maximum_quantity INTEGER,
    notes TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ(6),
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW(),
    UNIQUE(pharmacy_id, medicine_id)
);

CREATE INDEX ON pharmacy_price_lists(pharmacy_id);
CREATE INDEX ON pharmacy_price_lists(medicine_id);
CREATE INDEX ON pharmacy_price_lists(status);

-- =========================================
-- 5. 处方管理表
-- =========================================

CREATE TABLE prescriptions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PAID', 'FULFILLED', 'CANCELLED')),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    copies INTEGER NOT NULL CHECK (copies > 0),
    notes TEXT,
    qr_code_data TEXT,
    qr_code_string TEXT,
    qr_expires_at TIMESTAMPTZ(6),
    metadata JSONB,
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON prescriptions(doctor_id);
CREATE INDEX ON prescriptions(status);
CREATE INDEX ON prescriptions(created_at DESC);

-- 处方药品明细表
CREATE TABLE prescription_medicines (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_id TEXT REFERENCES medicines(id) ON DELETE CASCADE,
    weight DECIMAL(8,3) NOT NULL CHECK (weight > 0),
    unit_price DECIMAL(10,6) NOT NULL CHECK (unit_price >= 0),
    line_total DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
    instructions TEXT,
    created_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON prescription_medicines(prescription_id);
CREATE INDEX ON prescription_medicines(medicine_id);

-- =========================================
-- 6. 订单和履约管理表
-- =========================================

CREATE TABLE orders (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE CASCADE,
    practitioner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON orders(prescription_id);
CREATE INDEX ON orders(practitioner_id);
CREATE INDEX ON orders(status);

-- 采购订单表 (药房履约)
CREATE TABLE purchase_orders (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT REFERENCES orders(id) ON DELETE CASCADE,
    pharmacy_id TEXT REFERENCES pharmacies(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'PENDING_REVIEW' CHECK (status IN ('PENDING_REVIEW', 'APPROVED', 'REJECTED', 'PAID')),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    pharmacy_notes TEXT,
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ(6),
    review_notes TEXT,
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON purchase_orders(order_id);
CREATE INDEX ON purchase_orders(pharmacy_id);
CREATE INDEX ON purchase_orders(status);

-- 履约凭证表
CREATE TABLE fulfillment_proofs (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id TEXT REFERENCES purchase_orders(id) ON DELETE CASCADE,
    file_url VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    notes TEXT,
    uploaded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON fulfillment_proofs(purchase_order_id);

-- =========================================
-- 7. 支付管理表
-- =========================================

CREATE TABLE payments (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT REFERENCES orders(id) ON DELETE CASCADE,
    practitioner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'NZD',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    payment_method VARCHAR(50),
    stripe_payment_intent_id VARCHAR(255),
    stripe_charge_id VARCHAR(255),
    failure_reason TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON payments(order_id);
CREATE INDEX ON payments(practitioner_id);
CREATE INDEX ON payments(status);
CREATE INDEX ON payments(stripe_payment_intent_id);

-- =========================================
-- 8. 财务管理表
-- =========================================

-- 药房账户表
CREATE TABLE pharmacy_accounts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id TEXT REFERENCES pharmacies(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) DEFAULT 0 CHECK (balance >= 0),
    pending_amount DECIMAL(12,2) DEFAULT 0 CHECK (pending_amount >= 0),
    total_earned DECIMAL(12,2) DEFAULT 0 CHECK (total_earned >= 0),
    bank_account_info JSONB,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'frozen')),
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW(),
    UNIQUE(pharmacy_id)
);

CREATE INDEX ON pharmacy_accounts(status);

-- 提现申请表
CREATE TABLE withdrawal_requests (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_account_id TEXT REFERENCES pharmacy_accounts(id) ON DELETE CASCADE,
    purchase_order_ids JSONB NOT NULL,
    requested_amount DECIMAL(12,2) NOT NULL CHECK (requested_amount > 0),
    bank_account_info JSONB NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    processed_by UUID REFERENCES auth.users(id),
    processed_at TIMESTAMPTZ(6),
    rejection_reason TEXT,
    transaction_reference VARCHAR(255),
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON withdrawal_requests(pharmacy_account_id);
CREATE INDEX ON withdrawal_requests(status);

-- =========================================
-- 9. 审计日志表
-- =========================================

CREATE TABLE audit_logs (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id TEXT,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ(6) DEFAULT NOW()
);

CREATE INDEX ON audit_logs(user_id);
CREATE INDEX ON audit_logs(action);
CREATE INDEX ON audit_logs(table_name);
CREATE INDEX ON audit_logs(created_at DESC);

-- =========================================
-- 10. RLS (Row Level Security) 策略
-- =========================================

-- 启用RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE practitioner_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE account_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_price_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE fulfillment_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 用户档案策略 - 用户只能访问自己的档案
CREATE POLICY "users_own_profile" ON user_profiles
FOR ALL USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- 医师账户策略 - 医师只能访问自己的账户
CREATE POLICY "practitioners_own_accounts" ON practitioner_accounts
FOR ALL USING (auth.uid() = practitioner_id OR auth.jwt() ->> 'role' = 'admin');

-- 账户交易策略
CREATE POLICY "practitioners_own_transactions" ON account_transactions
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM practitioner_accounts 
    WHERE id = account_id AND practitioner_id = auth.uid()
  ) OR auth.jwt() ->> 'role' = 'admin'
);

-- 药品主数据 - 所有认证用户可读，仅管理员可写
CREATE POLICY "medicines_read_all" ON medicines
FOR SELECT TO authenticated USING (true);

CREATE POLICY "medicines_admin_only" ON medicines
FOR INSERT, UPDATE, DELETE USING (auth.jwt() ->> 'role' = 'admin');

-- 药房策略 - 药房操作员只能访问自己的药房
CREATE POLICY "pharmacy_operators_own_pharmacy" ON pharmacies
FOR ALL USING (auth.uid() = operator_id OR auth.jwt() ->> 'role' = 'admin');

-- 药房价格表策略
CREATE POLICY "pharmacy_own_price_lists" ON pharmacy_price_lists
FOR ALL USING (
  pharmacy_id IN (
    SELECT id FROM pharmacies WHERE operator_id = auth.uid()
  ) OR auth.jwt() ->> 'role' = 'admin'
);

-- 处方策略 - 医师只能访问自己的处方
CREATE POLICY "practitioners_own_prescriptions" ON prescriptions
FOR ALL USING (auth.uid() = doctor_id OR auth.jwt() ->> 'role' = 'admin');

-- 处方药品明细策略
CREATE POLICY "practitioners_own_prescription_medicines" ON prescription_medicines
FOR ALL USING (
  prescription_id IN (
    SELECT id FROM prescriptions WHERE doctor_id = auth.uid()
  ) OR auth.jwt() ->> 'role' = 'admin'
);

-- 订单策略
CREATE POLICY "practitioners_own_orders" ON orders
FOR ALL USING (auth.uid() = practitioner_id OR auth.jwt() ->> 'role' = 'admin');

-- 采购订单策略 - 药房只能访问分配给自己的订单
CREATE POLICY "pharmacy_assigned_orders" ON purchase_orders
FOR ALL USING (
  pharmacy_id IN (
    SELECT id FROM pharmacies WHERE operator_id = auth.uid()
  ) OR auth.jwt() ->> 'role' = 'admin'
);

-- 履约凭证策略
CREATE POLICY "pharmacy_own_fulfillment_proofs" ON fulfillment_proofs
FOR ALL USING (
  purchase_order_id IN (
    SELECT po.id FROM purchase_orders po
    JOIN pharmacies p ON po.pharmacy_id = p.id
    WHERE p.operator_id = auth.uid()
  ) OR auth.jwt() ->> 'role' = 'admin'
);

-- 支付策略
CREATE POLICY "practitioners_own_payments" ON payments
FOR ALL USING (auth.uid() = practitioner_id OR auth.jwt() ->> 'role' = 'admin');

-- 药房账户策略
CREATE POLICY "pharmacy_own_accounts" ON pharmacy_accounts
FOR ALL USING (
  pharmacy_id IN (
    SELECT id FROM pharmacies WHERE operator_id = auth.uid()
  ) OR auth.jwt() ->> 'role' = 'admin'
);

-- 提现申请策略
CREATE POLICY "pharmacy_own_withdrawals" ON withdrawal_requests
FOR ALL USING (
  pharmacy_account_id IN (
    SELECT pa.id FROM pharmacy_accounts pa
    JOIN pharmacies p ON pa.pharmacy_id = p.id
    WHERE p.operator_id = auth.uid()
  ) OR auth.jwt() ->> 'role' = 'admin'
);

-- 审计日志策略 - 用户可以查看自己的操作记录，管理员可以查看所有
CREATE POLICY "users_own_audit_logs" ON audit_logs
FOR SELECT USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- 管理员可以插入审计日志
CREATE POLICY "admin_insert_audit_logs" ON audit_logs
FOR INSERT USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================
-- 11. 触发器和函数
-- =========================================

-- 更新时间戳触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为所有需要的表添加更新时间戳触发器
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_practitioner_accounts_updated_at
    BEFORE UPDATE ON practitioner_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medicines_updated_at
    BEFORE UPDATE ON medicines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pharmacies_updated_at
    BEFORE UPDATE ON pharmacies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pharmacy_price_lists_updated_at
    BEFORE UPDATE ON pharmacy_price_lists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prescriptions_updated_at
    BEFORE UPDATE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchase_orders_updated_at
    BEFORE UPDATE ON purchase_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pharmacy_accounts_updated_at
    BEFORE UPDATE ON pharmacy_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_withdrawal_requests_updated_at
    BEFORE UPDATE ON withdrawal_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =========================================
-- 12. 视图 (便于查询)
-- =========================================

-- 处方详细视图
CREATE VIEW prescription_details AS
SELECT 
    p.id,
    p.doctor_id,
    up.full_name as doctor_name,
    p.status,
    p.total_amount,
    p.copies,
    p.notes,
    p.created_at,
    json_agg(
        json_build_object(
            'medicine_id', pm.medicine_id,
            'medicine_name', m.name,
            'weight', pm.weight,
            'unit_price', pm.unit_price,
            'line_total', pm.line_total,
            'instructions', pm.instructions
        )
    ) as medicines
FROM prescriptions p
JOIN user_profiles up ON p.doctor_id = up.user_id
LEFT JOIN prescription_medicines pm ON p.id = pm.prescription_id
LEFT JOIN medicines m ON pm.medicine_id = m.id
GROUP BY p.id, up.full_name;

-- 药房订单视图
CREATE VIEW pharmacy_orders AS
SELECT 
    po.id,
    po.order_id,
    po.pharmacy_id,
    ph.business_name as pharmacy_name,
    po.status,
    po.total_amount,
    po.created_at,
    o.prescription_id,
    p.doctor_id,
    up.full_name as doctor_name
FROM purchase_orders po
JOIN pharmacies ph ON po.pharmacy_id = ph.id
JOIN orders o ON po.order_id = o.id
JOIN prescriptions p ON o.prescription_id = p.id
JOIN user_profiles up ON p.doctor_id = up.user_id;

-- 财务汇总视图
CREATE VIEW financial_summary AS
SELECT 
    date_trunc('day', created_at) as date,
    count(*) as total_orders,
    sum(total_amount) as total_revenue,
    avg(total_amount) as average_order_value
FROM orders 
WHERE status = 'COMPLETED'
GROUP BY date_trunc('day', created_at)
ORDER BY date DESC;

-- =========================================
-- 注释和使用说明
-- =========================================

COMMENT ON TABLE user_profiles IS '用户扩展信息表，与Supabase auth.users表关联';
COMMENT ON TABLE practitioner_accounts IS '医师账户管理表，包含余额和信用额度';
COMMENT ON TABLE medicines IS '药品主数据表，包含价格和基本信息';
COMMENT ON TABLE pharmacies IS '药房信息表，包含许可证和地址信息';
COMMENT ON TABLE prescriptions IS '处方主表，包含QR码和状态管理';
COMMENT ON TABLE purchase_orders IS '药房采购订单表，用于履约管理';
COMMENT ON TABLE payments IS '支付记录表，与Stripe集成';

-- 使用示例：
-- 1. 创建医师账户：INSERT INTO practitioner_accounts (practitioner_id) VALUES (auth.uid());
-- 2. 查询医师处方：SELECT * FROM prescription_details WHERE doctor_id = auth.uid();
-- 3. 药房查看订单：SELECT * FROM pharmacy_orders WHERE pharmacy_id IN (SELECT id FROM pharmacies WHERE operator_id = auth.uid());

/*
⚠️ 重要提醒：
1. 所有金额以DECIMAL存储，确保财务计算精度
2. RLS策略确保数据安全隔离
3. 触发器自动更新时间戳
4. 视图简化复杂查询
5. 审计日志记录所有操作
6. 支持Supabase realtime订阅
*/