-- HARDEN RLS POLICIES 2026
-- This script ensures all tables have RLS enabled and proper policies are in place.

-- 1. Enable RLS on all core tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discount_codes ENABLE ROW LEVEL SECURITY;

-- 2. Profiles: Users manage own, Admin can view/manage
DROP POLICY IF EXISTS "Allow users to view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to insert own profile" ON public.profiles;

CREATE POLICY "Users can manage own profile" ON public.profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON public.profiles FOR ALL TO authenticated USING (public.is_admin_safe());

-- 3. Products & Metadata: Public read, Admin manage
DROP POLICY IF EXISTS "Allow public read" ON public.products;
DROP POLICY IF EXISTS "Admins manage products" ON public.products;
CREATE POLICY "Public read products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Admins manage products" ON public.products FOR ALL TO authenticated USING (public.is_admin_safe());

DROP POLICY IF EXISTS "Allow public read images" ON public.product_images;
DROP POLICY IF EXISTS "Admins manage images" ON public.product_images;
CREATE POLICY "Public read images" ON public.product_images FOR SELECT USING (true);
CREATE POLICY "Admins manage images" ON public.product_images FOR ALL TO authenticated USING (public.is_admin_safe());

-- 4. Orders: Users see own, Admin manage all
DROP POLICY IF EXISTS "Users view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users create own orders" ON public.orders;
DROP POLICY IF EXISTS "Admins manage orders" ON public.orders;

CREATE POLICY "Users view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
-- Insert for orders is usually handled by an edge function, but if client-side:
CREATE POLICY "Users create own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage orders" ON public.orders FOR ALL TO authenticated USING (public.is_admin_safe());

-- 5. Order Items: Link to orders RLS
DROP POLICY IF EXISTS "Users view own order items" ON public.order_items;
CREATE POLICY "Users view own order items" ON public.order_items FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND user_id = auth.uid())
);
CREATE POLICY "Admins manage order items" ON public.order_items FOR ALL TO authenticated USING (public.is_admin_safe());

-- 6. Cart Items: Users manage own
DROP POLICY IF EXISTS "Users manage own cart" ON public.cart_items;
CREATE POLICY "Users manage own cart" ON public.cart_items FOR ALL USING (auth.uid() = user_id);

-- 7. Reviews: Public read, Authenticated create
DROP POLICY IF EXISTS "Public read reviews" ON public.reviews;
CREATE POLICY "Public read reviews" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users create reviews" ON public.reviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage reviews" ON public.reviews FOR ALL TO authenticated USING (public.is_admin_safe());

-- 8. site_settings, shipping_methods, categories: Public read
DROP POLICY IF EXISTS "Allow public read categories" ON public.categories;
CREATE POLICY "Public read categories" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read settings" ON public.site_settings;
CREATE POLICY "Public read settings" ON public.site_settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read shipping" ON public.shipping_methods;
CREATE POLICY "Public read shipping" ON public.shipping_methods FOR SELECT USING (true);

-- 9. sync permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

SELECT 'RLS HARDENING COMPLETE' as status;
