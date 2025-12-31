-- ============================================
-- COMPREHENSIVE ADMIN RLS FIX
-- Grant admin users complete bypass of all RLS policies
-- ============================================

-- First, let's check and fix the is_admin_safe function
CREATE OR REPLACE FUNCTION public.is_admin_safe()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  );
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.is_admin_safe() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_safe() TO anon;

-- Now, drop ALL existing admin policies and recreate them properly
-- This ensures no conflicts

-- PROFILES
DROP POLICY IF EXISTS "Admins see all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins have full access to profiles" ON profiles;
CREATE POLICY "admin_all_profiles" ON profiles FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- PRODUCTS
DROP POLICY IF EXISTS "Products are manageable by authenticated users" ON products;
DROP POLICY IF EXISTS "Admins can manage all products" ON products;
DROP POLICY IF EXISTS "Admins manage products" ON products;
DROP POLICY IF EXISTS "Admins have full access to products" ON products;
CREATE POLICY "admin_all_products" ON products FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- CATEGORIES
DROP POLICY IF EXISTS "Categories are manageable by authenticated users" ON categories;
DROP POLICY IF EXISTS "Admins can manage all categories" ON categories;
DROP POLICY IF EXISTS "Categories are manageable by admins" ON categories;
DROP POLICY IF EXISTS "Admins have full access to categories" ON categories;
CREATE POLICY "admin_all_categories" ON categories FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- PRODUCT IMAGES
DROP POLICY IF EXISTS "Product images are manageable by authenticated users" ON product_images;
DROP POLICY IF EXISTS "Admins can manage product images" ON product_images;
DROP POLICY IF EXISTS "Admins have full access to product images" ON product_images;
CREATE POLICY "admin_all_product_images" ON product_images FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- BUNDLES
DROP POLICY IF EXISTS "Bundles are manageable by authenticated users" ON bundles;
DROP POLICY IF EXISTS "Admins can manage all bundles" ON bundles;
DROP POLICY IF EXISTS "Admins can manage bundles" ON bundles;
DROP POLICY IF EXISTS "Admins have full access to bundles" ON bundles;
CREATE POLICY "admin_all_bundles" ON bundles FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- BUNDLE PRODUCTS
DROP POLICY IF EXISTS "Bundle products are manageable by authenticated users" ON bundle_products;
DROP POLICY IF EXISTS "Admins can manage bundle products" ON bundle_products;
DROP POLICY IF EXISTS "Admins have full access to bundle products" ON bundle_products;
CREATE POLICY "admin_all_bundle_products" ON bundle_products FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- ORDERS
DROP POLICY IF EXISTS "Orders are manageable by authenticated users" ON orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON orders;
DROP POLICY IF EXISTS "Admins have full access to orders" ON orders;
CREATE POLICY "admin_all_orders" ON orders FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- ORDER ITEMS
DROP POLICY IF EXISTS "Order items are manageable by authenticated users" ON order_items;
DROP POLICY IF EXISTS "Admins can manage order items" ON order_items;
DROP POLICY IF EXISTS "Admins have full access to order items" ON order_items;
CREATE POLICY "admin_all_order_items" ON order_items FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- REVIEWS
DROP POLICY IF EXISTS "Reviews are manageable by authenticated users" ON reviews;
DROP POLICY IF EXISTS "Admins can manage all reviews" ON reviews;
DROP POLICY IF EXISTS "Admins have full access to reviews" ON reviews;
CREATE POLICY "admin_all_reviews" ON reviews FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- REVIEW IMAGES
DROP POLICY IF EXISTS "Review images are manageable by authenticated users" ON review_images;
DROP POLICY IF EXISTS "Admins can manage review images" ON review_images;
DROP POLICY IF EXISTS "Admins have full access to review images" ON review_images;
CREATE POLICY "admin_all_review_images" ON review_images FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- ADDRESSES
DROP POLICY IF EXISTS "Admins can manage all addresses" ON addresses;
DROP POLICY IF EXISTS "Admins have full access to addresses" ON addresses;
CREATE POLICY "admin_all_addresses" ON addresses FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- DISCOUNT CODES
DROP POLICY IF EXISTS "Discount codes are manageable by authenticated users" ON discount_codes;
DROP POLICY IF EXISTS "Admins can manage discount codes" ON discount_codes;
DROP POLICY IF EXISTS "Admins have full access to discount codes" ON discount_codes;
CREATE POLICY "admin_all_discount_codes" ON discount_codes FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- SHIPPING METHODS
DROP POLICY IF EXISTS "Shipping methods are manageable by authenticated users" ON shipping_methods;
DROP POLICY IF EXISTS "Admins can manage shipping methods" ON shipping_methods;
DROP POLICY IF EXISTS "Admins have full access to shipping methods" ON shipping_methods;
CREATE POLICY "admin_all_shipping_methods" ON shipping_methods FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- PAYMENT METHODS
DROP POLICY IF EXISTS "Payment methods are manageable by authenticated users" ON payment_methods;
DROP POLICY IF EXISTS "Admins can manage payment methods" ON payment_methods;
DROP POLICY IF EXISTS "Admins have full access to payment methods" ON payment_methods;
CREATE POLICY "admin_all_payment_methods" ON payment_methods FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- SITE SETTINGS
DROP POLICY IF EXISTS "Settings are manageable by authenticated users" ON site_settings;
DROP POLICY IF EXISTS "Admins can manage settings" ON site_settings;
DROP POLICY IF EXISTS "Admins have full access to settings" ON site_settings;
CREATE POLICY "admin_all_site_settings" ON site_settings FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- NEWSLETTER SUBSCRIBERS
DROP POLICY IF EXISTS "Authenticated users can manage subscribers" ON newsletter_subscribers;
DROP POLICY IF EXISTS "Admins can manage subscribers" ON newsletter_subscribers;
DROP POLICY IF EXISTS "Admins have full access to subscribers" ON newsletter_subscribers;
CREATE POLICY "admin_all_newsletter" ON newsletter_subscribers FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- CART ITEMS
DROP POLICY IF EXISTS "Admins can view all cart items" ON cart_items;
DROP POLICY IF EXISTS "Admins have full access to cart items" ON cart_items;
CREATE POLICY "admin_all_cart_items" ON cart_items FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- WISHLISTS
DROP POLICY IF EXISTS "Admins can manage all wishlists" ON wishlists;
DROP POLICY IF EXISTS "Admins have full access to wishlists" ON wishlists;
CREATE POLICY "admin_all_wishlists" ON wishlists FOR ALL TO authenticated 
  USING (public.is_admin_safe()) 
  WITH CHECK (public.is_admin_safe());

-- PRODUCT VARIANTS
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'product_variants') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Admins can manage product variants" ON product_variants';
        EXECUTE 'DROP POLICY IF EXISTS "Admins have full access to product variants" ON product_variants';
        EXECUTE 'CREATE POLICY "admin_all_product_variants" ON product_variants FOR ALL TO authenticated USING (public.is_admin_safe()) WITH CHECK (public.is_admin_safe())';
    END IF;
END $$;

-- FAQs
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'faqs') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Admins manage faqs" ON faqs';
        EXECUTE 'CREATE POLICY "admin_all_faqs" ON faqs FOR ALL TO authenticated USING (public.is_admin_safe()) WITH CHECK (public.is_admin_safe())';
    END IF;
END $$;

-- AGE RANGES
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'age_ranges') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Admins can manage age ranges" ON age_ranges';
        EXECUTE 'CREATE POLICY "admin_all_age_ranges" ON age_ranges FOR ALL TO authenticated USING (public.is_admin_safe()) WITH CHECK (public.is_admin_safe())';
    END IF;
END $$;

-- SUBJECTS
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'subjects') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Admins can manage subjects" ON subjects';
        EXECUTE 'CREATE POLICY "admin_all_subjects" ON subjects FOR ALL TO authenticated USING (public.is_admin_safe()) WITH CHECK (public.is_admin_safe())';
    END IF;
END $$;

-- SITE ANALYTICS
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'site_analytics') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Authenticated users can view analytics" ON site_analytics';
        EXECUTE 'CREATE POLICY "admin_all_analytics" ON site_analytics FOR ALL TO authenticated USING (public.is_admin_safe()) WITH CHECK (public.is_admin_safe())';
    END IF;
END $$;
