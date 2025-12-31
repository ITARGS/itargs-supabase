-- ============================================
-- FIX ADMIN RLS POLICIES
-- Grant admin users full access to all tables
-- ============================================

-- Drop conflicting policies and create proper admin bypass policies

-- Categories
DROP POLICY IF EXISTS "Categories are manageable by authenticated users" ON categories;
CREATE POLICY "Admins can manage all categories" ON categories FOR ALL TO authenticated USING (public.is_admin_safe());
CREATE POLICY "Categories are manageable by admins" ON categories FOR ALL TO authenticated USING (public.is_admin_safe());

-- Products  
DROP POLICY IF EXISTS "Products are manageable by authenticated users" ON products;
CREATE POLICY "Admins can manage all products" ON products FOR ALL TO authenticated USING (public.is_admin_safe());

-- Product Images
DROP POLICY IF EXISTS "Product images are manageable by authenticated users" ON product_images;
CREATE POLICY "Admins can manage product images" ON product_images FOR ALL TO authenticated USING (public.is_admin_safe());

-- Bundles
DROP POLICY IF EXISTS "Bundles are manageable by authenticated users" ON bundles;
CREATE POLICY "Admins can manage all bundles" ON bundles FOR ALL TO authenticated USING (public.is_admin_safe());

-- Bundle Products
DROP POLICY IF EXISTS "Bundle products are manageable by authenticated users" ON bundle_products;
CREATE POLICY "Admins can manage bundle products" ON bundle_products FOR ALL TO authenticated USING (public.is_admin_safe());

-- Addresses
CREATE POLICY "Admins can manage all addresses" ON addresses FOR ALL TO authenticated USING (public.is_admin_safe());

-- Orders
-- Already has admin policy, just ensure it's correct
DROP POLICY IF EXISTS "Orders are manageable by authenticated users" ON orders;
CREATE POLICY "Admins can manage all orders" ON orders FOR ALL TO authenticated USING (public.is_admin_safe());

-- Order Items
DROP POLICY IF EXISTS "Order items are manageable by authenticated users" ON order_items;
CREATE POLICY "Admins can manage order items" ON order_items FOR ALL TO authenticated USING (public.is_admin_safe());

-- Reviews
DROP POLICY IF EXISTS "Reviews are manageable by authenticated users" ON reviews;
CREATE POLICY "Admins can manage all reviews" ON reviews FOR ALL TO authenticated USING (public.is_admin_safe());

-- Review Images
DROP POLICY IF EXISTS "Review images are manageable by authenticated users" ON review_images;
CREATE POLICY "Admins can manage review images" ON review_images FOR ALL TO authenticated USING (public.is_admin_safe());

-- Discount Codes
DROP POLICY IF EXISTS "Discount codes are manageable by authenticated users" ON discount_codes;
CREATE POLICY "Admins can manage discount codes" ON discount_codes FOR ALL TO authenticated USING (public.is_admin_safe());

-- Shipping Methods
DROP POLICY IF EXISTS "Shipping methods are manageable by authenticated users" ON shipping_methods;
CREATE POLICY "Admins can manage shipping methods" ON shipping_methods FOR ALL TO authenticated USING (public.is_admin_safe());

-- Payment Methods
DROP POLICY IF EXISTS "Payment methods are manageable by authenticated users" ON payment_methods;
CREATE POLICY "Admins can manage payment methods" ON payment_methods FOR ALL TO authenticated USING (public.is_admin_safe());

-- Site Settings
DROP POLICY IF EXISTS "Settings are manageable by authenticated users" ON site_settings;
CREATE POLICY "Admins can manage settings" ON site_settings FOR ALL TO authenticated USING (public.is_admin_safe());

-- Newsletter Subscribers
DROP POLICY IF EXISTS "Authenticated users can manage subscribers" ON newsletter_subscribers;
CREATE POLICY "Admins can manage subscribers" ON newsletter_subscribers FOR ALL TO authenticated USING (public.is_admin_safe());

-- Cart Items
-- Already has admin policy

-- Wishlists
CREATE POLICY "Admins can manage all wishlists" ON wishlists FOR ALL TO authenticated USING (public.is_admin_safe());

-- Product Variants (if exists)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'product_variants') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Product variants manageable by authenticated" ON product_variants';
        EXECUTE 'CREATE POLICY "Admins can manage product variants" ON product_variants FOR ALL TO authenticated USING (public.is_admin_safe())';
    END IF;
END $$;

-- FAQs
-- Already has admin policy

-- Age Ranges
-- Already has admin policy

-- Subjects
-- Already has admin policy

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
