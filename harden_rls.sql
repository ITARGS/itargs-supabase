-- SECURITY HARDENING MIGRATION (Supabase Native RLS)
-- Target: Orders, Shipping, Payments, FAQs, Settings, Categories

-- 1. ORDERS TABLE
DROP POLICY IF EXISTS "Orders are manageable by authenticated users" ON public.orders;
DROP POLICY IF EXISTS "Customers can cancel own pending orders" ON public.orders;

-- Allow Admins Full Access
CREATE POLICY "Admins manage all orders" 
ON public.orders FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- Allow Customers to Cancel PENDING orders
CREATE POLICY "Customers can cancel own pending orders" 
ON public.orders FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id AND status = 'pending')
WITH CHECK (status = 'cancelled');

-- 2. ORDER ITEMS TABLE
DROP POLICY IF EXISTS "Order items are manageable by authenticated users" ON public.order_items;

CREATE POLICY "Admins manage all order items" 
ON public.order_items FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- 3. ORDER STATUS HISTORY TABLE
DROP POLICY IF EXISTS "authenticated_insert_order_status_history" ON public.order_status_history;

CREATE POLICY "Admins manage all status history" 
ON public.order_status_history FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- 4. SHIPPING METHODS
DROP POLICY IF EXISTS "Shipping methods are manageable by authenticated users" ON public.shipping_methods;

CREATE POLICY "Admins manage shipping methods" 
ON public.shipping_methods FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- 5. PAYMENT METHODS
DROP POLICY IF EXISTS "Payment methods are manageable by authenticated users" ON public.payment_methods;

CREATE POLICY "Admins manage payment_methods" 
ON public.payment_methods FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- 6. FAQS
DROP POLICY IF EXISTS "Admins manage faqs" ON public.faqs;

CREATE POLICY "Admins manage faqs" 
ON public.faqs FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- 7. SITE SETTINGS
DROP POLICY IF EXISTS "Settings are manageable by authenticated users" ON public.site_settings;

CREATE POLICY "Admins manage settings" 
ON public.site_settings FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- 8. CATEGORIES
DROP POLICY IF EXISTS "Categories are manageable by authenticated users" ON public.categories;

CREATE POLICY "Admins manage categories" 
ON public.categories FOR ALL 
TO authenticated 
USING (public.is_admin_safe());

-- FINAL CHECK: Ensure RLS is enabled on all target tables
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
