-- FINAL RLS CLEANUP & IMAGES FIX
-- This script simplifies RLS to ensure images are always visible.

-- 1. Products Cleanup
DROP POLICY IF EXISTS "Allow public read" ON public.products;
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Public can view active products" ON public.products;
DROP POLICY IF EXISTS "Public view products" ON public.products;
DROP POLICY IF EXISTS "Products are manageable by authenticated users" ON public.products;

CREATE POLICY "Allow public read" ON public.products FOR SELECT USING (true);
CREATE POLICY "Admins manage products" ON public.products FOR ALL TO authenticated USING (public.is_admin_safe());

-- 2. Product Images Cleanup
DROP POLICY IF EXISTS "Product images are viewable by everyone" ON public.product_images;
DROP POLICY IF EXISTS "Product images are manageable by authenticated users" ON public.product_images;

CREATE POLICY "Allow public read images" ON public.product_images FOR SELECT USING (true);
CREATE POLICY "Admins manage images" ON public.product_images FOR ALL TO authenticated USING (public.is_admin_safe());

-- 3. Sync Permissions for Roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- 4. Create is_admin alias for compatibility
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
    RETURN public.is_admin_safe();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- 5. Categories & Site Settings (Final Sync)
DROP POLICY IF EXISTS "Allow public read" ON public.categories;
CREATE POLICY "Allow public read" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read" ON public.site_settings;
CREATE POLICY "Allow public read" ON public.site_settings FOR SELECT USING (true);

SELECT 'FINAL RLS CLEANUP APPLIED' as status;
