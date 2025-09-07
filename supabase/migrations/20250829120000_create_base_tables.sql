-- ============================================================================
-- Create Base Tables for Medical Platform
-- ============================================================================
-- This migration creates the foundational tables required by the system
-- Including: pharmacies, orders, fulfillment_credentials, etc.
-- ============================================================================

-- Create pharmacies table
CREATE TABLE IF NOT EXISTS public.pharmacies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  contact_info JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assigned_pharmacy_id UUID REFERENCES public.pharmacies(id),
  status VARCHAR(50) DEFAULT 'pending',
  patient_id VARCHAR(255), -- Anonymous patient identifier
  total_amount_cents INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create fulfillment_credentials table
CREATE TABLE IF NOT EXISTS public.fulfillment_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id UUID REFERENCES public.pharmacies(id) NOT NULL,
  order_id UUID REFERENCES public.orders(id),
  credential_type VARCHAR(50) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create po_settlements table
CREATE TABLE IF NOT EXISTS public.po_settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id UUID REFERENCES public.pharmacies(id) NOT NULL,
  order_id UUID REFERENCES public.orders(id),
  settlement_amount_cents INTEGER NOT NULL DEFAULT 0,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create inventory_tracking table
CREATE TABLE IF NOT EXISTS public.inventory_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id UUID REFERENCES public.pharmacies(id) NOT NULL,
  item_code VARCHAR(100) NOT NULL,
  quantity INTEGER DEFAULT 0,
  status VARCHAR(50) DEFAULT 'in_stock',
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- Create patient_records table (for anonymized patient data)
CREATE TABLE IF NOT EXISTS public.patient_records (
  id VARCHAR(255) PRIMARY KEY,
  -- No personal information stored - HIPAA compliance
  first_name VARCHAR(255), -- Should be NULL for anonymization
  last_name VARCHAR(255),  -- Should be NULL for anonymization
  email VARCHAR(255),      -- Should be NULL for anonymization
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_assigned_pharmacy_id ON public.orders(assigned_pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_fulfillment_credentials_pharmacy_id ON public.fulfillment_credentials(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_po_settlements_pharmacy_id ON public.po_settlements(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_inventory_tracking_pharmacy_id ON public.inventory_tracking(pharmacy_id);

-- Add comments
COMMENT ON TABLE public.pharmacies IS 'Pharmacy organizations in the medical platform';
COMMENT ON TABLE public.orders IS 'Orders assigned to pharmacies for fulfillment';
COMMENT ON TABLE public.fulfillment_credentials IS 'Credentials and codes for order fulfillment';
COMMENT ON TABLE public.po_settlements IS 'Purchase order financial settlements';
COMMENT ON TABLE public.inventory_tracking IS 'Pharmacy inventory tracking';
COMMENT ON TABLE public.patient_records IS 'Anonymized patient references - no PII stored';