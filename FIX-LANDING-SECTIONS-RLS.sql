-- FIX LANDING SECTIONS RLS
-- Use is_admin_safe() instead of auth.jwt() ->> 'role' = 'admin'

-- 1. Featured Products
DROP POLICY IF EXISTS "Anyone can view active featured products" ON public.featured_products;
DROP POLICY IF EXISTS "Admins can manage featured products" ON public.featured_products;

CREATE POLICY "Public read active featured products" ON public.featured_products 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins manage featured products" ON public.featured_products 
FOR ALL TO authenticated USING (public.is_admin_safe());

-- 2. Homepage Categories
DROP POLICY IF EXISTS "Anyone can view active homepage categories" ON public.homepage_categories;
DROP POLICY IF EXISTS "Admins can manage homepage categories" ON public.homepage_categories;

CREATE POLICY "Public read active homepage categories" ON public.homepage_categories 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins manage homepage categories" ON public.homepage_categories 
FOR ALL TO authenticated USING (public.is_admin_safe());

-- 3. Recommendation Settings
DROP POLICY IF EXISTS "Anyone can view recommendation settings" ON public.recommendation_settings;
DROP POLICY IF EXISTS "Admins can manage recommendation settings" ON public.recommendation_settings;

CREATE POLICY "Public read recommendation settings" ON public.recommendation_settings 
FOR SELECT USING (true);

CREATE POLICY "Admins manage recommendation settings" ON public.recommendation_settings 
FOR ALL TO authenticated USING (public.is_admin_safe());

-- 4. Newsletter Settings
DROP POLICY IF EXISTS "Anyone can view newsletter settings" ON public.newsletter_settings;
DROP POLICY IF EXISTS "Admins can manage newsletter settings" ON public.newsletter_settings;

CREATE POLICY "Public read newsletter settings" ON public.newsletter_settings 
FOR SELECT USING (true);

CREATE POLICY "Admins manage newsletter settings" ON public.newsletter_settings 
FOR ALL TO authenticated USING (public.is_admin_safe());

-- 5. Newsletter Subscribers
DROP POLICY IF EXISTS "Admins can view all subscribers" ON public.newsletter_subscribers;
DROP POLICY IF EXISTS "Admins can manage subscribers" ON public.newsletter_subscribers;
DROP POLICY IF EXISTS "Anyone can subscribe" ON public.newsletter_subscribers;

CREATE POLICY "Anyone can subscribe" ON public.newsletter_subscribers 
FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins manage newsletter subscribers" ON public.newsletter_subscribers 
FOR ALL TO authenticated USING (public.is_admin_safe());

-- 6. Ensure RLS is enabled
ALTER TABLE public.featured_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homepage_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendation_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.newsletter_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.newsletter_subscribers ENABLE ROW LEVEL SECURITY;

SELECT 'LANDING SECTIONS RLS FIXED' as status;
