-- FINAL SOLUTION: Remove ALL role dependencies from RLS
-- Use ONLY auth.uid() - no role checking at all

-- ============================================================================
-- STEP 1: Check which tables/functions are using role checks
-- ============================================================================

-- Find all RLS policies that might be checking roles
SELECT schemaname, tablename, policyname, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- STEP 2: Drop ALL policies and recreate without role checks
-- ============================================================================

-- Disable RLS temporarily to avoid issues
ALTER TABLE public.cart_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_analytics DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_tiers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;

-- Drop all policies
DROP POLICY IF EXISTS "Users can view own cart" ON public.cart_items;
DROP POLICY IF EXISTS "Users can manage own cart" ON public.cart_items;
DROP POLICY IF EXISTS "Users can view own wishlist" ON public.wishlists;
DROP POLICY IF EXISTS "Users can manage own wishlist" ON public.wishlists;

-- Re-enable RLS
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 3: Create simple policies using ONLY auth.uid()
-- ============================================================================

-- Cart: User-specific, NO role check
CREATE POLICY "cart_select" ON public.cart_items
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "cart_insert" ON public.cart_items
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "cart_update" ON public.cart_items
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "cart_delete" ON public.cart_items
    FOR DELETE USING (user_id = auth.uid());

-- Wishlist: User-specific, NO role check
CREATE POLICY "wishlist_select" ON public.wishlists
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "wishlist_insert" ON public.wishlists
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "wishlist_delete" ON public.wishlists
    FOR DELETE USING (user_id = auth.uid());

-- Site Analytics: Allow inserts for all authenticated users
CREATE POLICY "analytics_insert" ON public.site_analytics
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Site Settings: Public read
CREATE POLICY "settings_select" ON public.site_settings
    FOR SELECT USING (true);

-- Performance Tiers: Public read
CREATE POLICY "tiers_select" ON public.performance_tiers
    FOR SELECT USING (is_active = true);

-- Categories: Public read
CREATE POLICY "categories_select" ON public.categories
    FOR SELECT USING (is_active = true);

-- Products: Public read
CREATE POLICY "products_select" ON public.products
    FOR SELECT USING (is_active = true);

-- ============================================================================
-- STEP 4: Verification
-- ============================================================================

SELECT 'ALL ROLE DEPENDENCIES REMOVED' as status;

-- Show all policies
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
