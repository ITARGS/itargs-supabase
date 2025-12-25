-- ============================================
-- COMPLETE DATABASE SETUP SCRIPT
-- KAT Education E-commerce Platform
-- ============================================
-- This script creates all tables, indexes, RLS policies, and storage buckets
-- Run this on a fresh Supabase instance to set up the complete database

-- ============================================
-- 1. EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ============================================
-- 2. CORE TABLES
-- ============================================

-- Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    name_ar TEXT,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    description_ar TEXT,
    image_url TEXT,
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products Table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    name_ar TEXT,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    description_ar TEXT,
    base_price DECIMAL(10,2) NOT NULL,
    price DECIMAL(10,2),
    sale_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    sku TEXT UNIQUE,
    barcode TEXT,
    stock_quantity INTEGER DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 5,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    age_range TEXT,
    weight DECIMAL(10,2),
    dimensions TEXT,
    meta_title TEXT,
    meta_description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Product Images Table
CREATE TABLE IF NOT EXISTS product_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    display_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bundles Table
CREATE TABLE IF NOT EXISTS bundles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    name_ar TEXT,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    description_ar TEXT,
    base_price DECIMAL(10,2) NOT NULL,
    bundle_price DECIMAL(10,2),
    sale_price DECIMAL(10,2),
    savings_percentage DECIMAL(5,2) DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bundle Products Table
CREATE TABLE IF NOT EXISTS bundle_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bundle_id UUID REFERENCES bundles(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(bundle_id, product_id)
);

-- Profiles Table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    role TEXT DEFAULT 'customer',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Addresses Table
CREATE TABLE IF NOT EXISTS addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    street_address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Egypt',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    order_number TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'pending',
    payment_method TEXT NOT NULL,
    payment_status TEXT DEFAULT 'pending',
    subtotal DECIMAL(10,2) NOT NULL,
    shipping_cost DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping_address_id UUID REFERENCES addresses(id) ON DELETE SET NULL,
    notes TEXT,
    tracking_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    bundle_id UUID REFERENCES bundles(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reviews Table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title TEXT,
    comment TEXT,
    is_approved BOOLEAN DEFAULT false,
    is_verified_purchase BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Review Images Table
CREATE TABLE IF NOT EXISTS review_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Discount Codes Table
CREATE TABLE IF NOT EXISTS discount_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    min_purchase_amount DECIMAL(10,2),
    max_discount_amount DECIMAL(10,2),
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shipping Methods Table
CREATE TABLE IF NOT EXISTS shipping_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    name_ar TEXT,
    description TEXT,
    description_ar TEXT,
    base_cost DECIMAL(10,2) NOT NULL,
    cost_per_kg DECIMAL(10,2) DEFAULT 0,
    estimated_days TEXT,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Methods Table
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    name_ar TEXT,
    description TEXT,
    description_ar TEXT,
    type TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    config JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Site Settings Table
CREATE TABLE IF NOT EXISTS site_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Newsletter Subscribers Table
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    subscribed_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Site Analytics Table
CREATE TABLE IF NOT EXISTS site_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type TEXT DEFAULT 'page_view',
    event_data JSONB,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    session_id TEXT,
    ip_address TEXT,
    user_agent TEXT,
    page_path TEXT,
    referrer TEXT,
    country TEXT,
    device_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cart Items Table
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id TEXT,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    bundle_id UUID REFERENCES bundles(id) ON DELETE CASCADE,
    variant_id UUID,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT cart_items_user_or_session CHECK (user_id IS NOT NULL OR session_id IS NOT NULL),
    CONSTRAINT cart_items_product_or_bundle CHECK (
        (product_id IS NOT NULL AND bundle_id IS NULL) OR
        (product_id IS NULL AND bundle_id IS NOT NULL)
    )
);

-- Product Variants Table
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sku TEXT,
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key from cart_items to product_variants
ALTER TABLE cart_items
ADD CONSTRAINT cart_items_variant_id_fkey
FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL;

-- Wishlists Table
CREATE TABLE IF NOT EXISTS wishlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- Age Ranges Table (for filters)
CREATE TABLE IF NOT EXISTS age_ranges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subjects Table (for filters)
CREATE TABLE IF NOT EXISTS subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Product Age Ranges Junction Table
CREATE TABLE IF NOT EXISTS product_age_ranges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
    age_range_id UUID REFERENCES age_ranges(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, age_range_id)
);

-- Product Subjects Junction Table
CREATE TABLE IF NOT EXISTS product_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, subject_id)
);

-- ============================================
-- 3. INDEXES
-- ============================================

-- Categories
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id);

-- Products
CREATE INDEX IF NOT EXISTS idx_products_slug ON products(slug);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_featured ON products(is_featured);

-- Product Images
CREATE INDEX IF NOT EXISTS idx_product_images_product ON product_images(product_id);

-- Bundles
CREATE INDEX IF NOT EXISTS idx_bundles_slug ON bundles(slug);
CREATE INDEX IF NOT EXISTS idx_bundles_active ON bundles(is_active);

-- Orders
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at DESC);

-- Order Items
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);

-- Reviews
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_approved ON reviews(is_approved);

-- Newsletter
CREATE INDEX IF NOT EXISTS idx_newsletter_email ON newsletter_subscribers(email);

-- Analytics
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON site_analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_created ON site_analytics(created_at DESC);

-- Cart Items
CREATE INDEX IF NOT EXISTS idx_cart_items_user ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_session ON cart_items(session_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product ON cart_items(product_id);

-- Product Variants
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);

-- Wishlists
CREATE INDEX IF NOT EXISTS idx_wishlists_user ON wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_product ON wishlists(product_id);

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bundle_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE discount_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;

-- Categories Policies
CREATE POLICY "Categories are viewable by everyone" ON categories FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "Categories are manageable by authenticated users" ON categories FOR ALL TO authenticated USING (true);

-- Products Policies
CREATE POLICY "Products are viewable by everyone" ON products FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "Products are manageable by authenticated users" ON products FOR ALL TO authenticated USING (true);

-- Product Images Policies
CREATE POLICY "Product images are viewable by everyone" ON product_images FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Product images are manageable by authenticated users" ON product_images FOR ALL TO authenticated USING (true);

-- Bundles Policies
CREATE POLICY "Bundles are viewable by everyone" ON bundles FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "Bundles are manageable by authenticated users" ON bundles FOR ALL TO authenticated USING (true);

-- Bundle Products Policies
CREATE POLICY "Bundle products are viewable by everyone" ON bundle_products FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Bundle products are manageable by authenticated users" ON bundle_products FOR ALL TO authenticated USING (true);

-- Profiles Policies
CREATE POLICY "Profiles are viewable by owner" ON profiles FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "Profiles are updatable by owner" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Profiles are insertable by owner" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

-- Addresses Policies
CREATE POLICY "Addresses are viewable by owner" ON addresses FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Addresses are manageable by owner" ON addresses FOR ALL TO authenticated USING (auth.uid() = user_id);

-- Orders Policies
CREATE POLICY "Orders are viewable by owner" ON orders FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Orders are insertable by authenticated users" ON orders FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Orders are manageable by authenticated users" ON orders FOR ALL TO authenticated USING (true);
CREATE POLICY "Admins can view all orders" ON orders FOR ALL TO authenticated USING (public.is_admin_safe());


-- Order Items Policies
CREATE POLICY "Order items are viewable by order owner" ON order_items FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
);
CREATE POLICY "Order items are manageable by authenticated users" ON order_items FOR ALL TO authenticated USING (true);

-- Reviews Policies
CREATE POLICY "Approved reviews are viewable by everyone" ON reviews FOR SELECT TO anon, authenticated USING (is_approved = true);
CREATE POLICY "Own reviews are viewable by owner" ON reviews FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Reviews are insertable by authenticated users" ON reviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Reviews are manageable by authenticated users" ON reviews FOR ALL TO authenticated USING (true);

-- Review Images Policies
CREATE POLICY "Review images are viewable by everyone" ON review_images FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Review images are manageable by authenticated users" ON review_images FOR ALL TO authenticated USING (true);

-- Discount Codes Policies
CREATE POLICY "Active discount codes are viewable by everyone" ON discount_codes FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "Discount codes are manageable by authenticated users" ON discount_codes FOR ALL TO authenticated USING (true);

-- Shipping Methods Policies
CREATE POLICY "Active shipping methods are viewable by everyone" ON shipping_methods FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "Shipping methods are manageable by authenticated users" ON shipping_methods FOR ALL TO authenticated USING (true);

-- Payment Methods Policies
CREATE POLICY "Active payment methods are viewable by everyone" ON payment_methods FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "Payment methods are manageable by authenticated users" ON payment_methods FOR ALL TO authenticated USING (true);

-- Settings Policies
CREATE POLICY "Settings are viewable by everyone" ON site_settings FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Settings are manageable by authenticated users" ON site_settings FOR ALL TO authenticated USING (true);

-- Newsletter Subscribers Policies
CREATE POLICY "Anyone can subscribe to newsletter" ON newsletter_subscribers FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can view subscribers" ON newsletter_subscribers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can manage subscribers" ON newsletter_subscribers FOR ALL TO authenticated USING (true);

-- Site Analytics Policies
CREATE POLICY "Anyone can insert analytics" ON site_analytics FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can view analytics" ON site_analytics FOR SELECT TO authenticated USING (true);

-- Cart Items Policies
CREATE POLICY "Users can view their own cart items" ON cart_items FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own cart items" ON cart_items FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Anonymous users can manage cart by session" ON cart_items FOR ALL TO anon USING (session_id IS NOT NULL);
CREATE POLICY "Admins can view all cart items" ON cart_items FOR SELECT TO authenticated USING (public.is_admin_safe());

-- Wishlists Policies
CREATE POLICY "Users can view their own wishlist" ON wishlists FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own wishlist" ON wishlists FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all wishlists" ON wishlists FOR SELECT TO authenticated USING (public.is_admin_safe());


-- ============================================
-- 5. STORAGE BUCKETS
-- ============================================
-- Note: Storage buckets must be created via Supabase Dashboard or API
-- These are the required buckets:
-- - product-images (public)
-- - review-images (public)
-- - store-assets (public)

-- ============================================
-- 6. FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bundles_updated_at BEFORE UPDATE ON bundles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discount_codes_updated_at BEFORE UPDATE ON discount_codes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shipping_methods_updated_at BEFORE UPDATE ON shipping_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON site_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Admin check function
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

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Next steps:
-- 1. Run 02_initial_settings.sql to populate settings
-- 2. Run 03_dummy_data.sql to add sample data
-- 3. Create storage buckets in Supabase Dashboard
