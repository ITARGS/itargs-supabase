-- ============================================
-- FIX ADMIN RLS POLICIES - WITH CHECK CLAUSE
-- Ensure admin users can INSERT/UPDATE without restrictions
-- ============================================

-- The issue is that WITH CHECK policies also need to allow admin access
-- We need to recreate policies with both USING and WITH CHECK clauses

-- Categories
DROP POLICY IF EXISTS "Admins can manage all categories" ON categories;
DROP POLICY IF EXISTS "Categories are manageable by admins" ON categories;
CREATE POLICY "Admins have full access to categories" ON categories FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Products  
DROP POLICY IF EXISTS "Admins can manage all products" ON products;
DROP POLICY IF EXISTS "Admins manage products" ON products;
CREATE POLICY "Admins have full access to products" ON products FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Product Images
DROP POLICY IF EXISTS "Admins can manage product images" ON product_images;
CREATE POLICY "Admins have full access to product images" ON product_images FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Bundles
DROP POLICY IF EXISTS "Admins can manage all bundles" ON bundles;
DROP POLICY IF EXISTS "Admins can manage bundles" ON bundles;
CREATE POLICY "Admins have full access to bundles" ON bundles FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Bundle Products
DROP POLICY IF EXISTS "Admins can manage bundle products" ON bundle_products;
CREATE POLICY "Admins have full access to bundle products" ON bundle_products FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Addresses
DROP POLICY IF EXISTS "Admins can manage all addresses" ON addresses;
CREATE POLICY "Admins have full access to addresses" ON addresses FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Orders
DROP POLICY IF EXISTS "Admins can manage all orders" ON orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
CREATE POLICY "Admins have full access to orders" ON orders FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Order Items
DROP POLICY IF EXISTS "Admins can manage order items" ON order_items;
CREATE POLICY "Admins have full access to order items" ON order_items FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Reviews
DROP POLICY IF EXISTS "Admins can manage all reviews" ON reviews;
CREATE POLICY "Admins have full access to reviews" ON reviews FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Review Images
DROP POLICY IF EXISTS "Admins can manage review images" ON review_images;
CREATE POLICY "Admins have full access to review images" ON review_images FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Discount Codes
DROP POLICY IF EXISTS "Admins can manage discount codes" ON discount_codes;
CREATE POLICY "Admins have full access to discount codes" ON discount_codes FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Shipping Methods
DROP POLICY IF EXISTS "Admins can manage shipping methods" ON shipping_methods;
CREATE POLICY "Admins have full access to shipping methods" ON shipping_methods FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Payment Methods
DROP POLICY IF EXISTS "Admins can manage payment methods" ON payment_methods;
CREATE POLICY "Admins have full access to payment methods" ON payment_methods FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Site Settings
DROP POLICY IF EXISTS "Admins can manage settings" ON site_settings;
CREATE POLICY "Admins have full access to settings" ON site_settings FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Newsletter Subscribers
DROP POLICY IF EXISTS "Admins can manage subscribers" ON newsletter_subscribers;
CREATE POLICY "Admins have full access to subscribers" ON newsletter_subscribers FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Wishlists
DROP POLICY IF EXISTS "Admins can manage all wishlists" ON wishlists;
CREATE POLICY "Admins have full access to wishlists" ON wishlists FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- Product Variants
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'product_variants') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Admins can manage product variants" ON product_variants';
        EXECUTE 'CREATE POLICY "Admins have full access to product variants" ON product_variants FOR ALL TO authenticated USING (public.is_admin_safe()) WITH CHECK (public.is_admin_safe())';
    END IF;
END $$;

-- Cart Items (already has admin policy, update it)
DROP POLICY IF EXISTS "Admins can view all cart items" ON cart_items;
CREATE POLICY "Admins have full access to cart items" ON cart_items FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());
