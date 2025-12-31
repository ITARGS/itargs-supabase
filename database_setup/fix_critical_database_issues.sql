-- ============================================================================
-- CRITICAL DATABASE FIXES FOR ELNAJAR SUPABASE
-- ============================================================================
-- This script fixes all critical issues found in database verification
-- Execute on: api.elnajar.itargs.com (supabase_elnajar-db-1)
-- ============================================================================

-- ============================================================================
-- FIX 1: Create customer_addresses view (CRITICAL - Frontend expects this)
-- ============================================================================

-- Option A: Create VIEW pointing to addresses table (RECOMMENDED)
CREATE OR REPLACE VIEW customer_addresses AS
SELECT 
    id,
    user_id,
    full_name,
    phone,
    street_address,
    city,
    state,
    postal_code,
    country,
    is_default,
    created_at,
    updated_at
FROM addresses;

-- Grant permissions on view
GRANT SELECT ON customer_addresses TO anon, authenticated;

-- ============================================================================
-- FIX 2: Add RLS Policies to Missing Tables (CRITICAL SECURITY)
-- ============================================================================

-- Fix product_variants table
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view product variants"
ON product_variants FOR SELECT
TO public
USING (true);

CREATE POLICY "Admins can manage product variants"
ON product_variants FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Fix product_age_ranges table
ALTER TABLE product_age_ranges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view product age ranges"
ON product_age_ranges FOR SELECT
TO public
USING (true);

CREATE POLICY "Admins can manage product age ranges"
ON product_age_ranges FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Fix product_subjects table
ALTER TABLE product_subjects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view product subjects"
ON product_subjects FOR SELECT
TO public
USING (true);

CREATE POLICY "Admins can manage product subjects"
ON product_subjects FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- ============================================================================
-- FIX 3: Add Missing Indexes (PERFORMANCE)
-- ============================================================================

-- Orders table indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Cart items indexes
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON cart_items(product_id);

-- Reviews indexes
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_approved ON reviews(is_approved) WHERE is_approved = true;

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Products indexes
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active) WHERE is_active = true;

-- Wishlists indexes
CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_product_id ON wishlists(product_id);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at ON analytics_events(created_at DESC);

-- ============================================================================
-- FIX 4: Verify All Fixes Applied
-- ============================================================================

-- Check customer_addresses view exists
SELECT COUNT(*) as view_exists FROM information_schema.views 
WHERE table_schema = 'public' AND table_name = 'customer_addresses';

-- Check RLS enabled on all tables
SELECT tablename, 
       CASE WHEN rowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as rls_status
FROM pg_tables t
JOIN pg_class c ON t.tablename = c.relname
WHERE t.schemaname = 'public' 
  AND t.tablename IN ('product_variants', 'product_age_ranges', 'product_subjects')
ORDER BY tablename;

-- Check indexes created
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- ============================================================================
-- VERIFICATION COMPLETE
-- ============================================================================

COMMENT ON VIEW customer_addresses IS 'View for frontend compatibility - maps to addresses table';
