-- SIMPLIFIED AUTHENTICATION - Phase 1: Database Cleanup
-- This removes all custom JWT logic and uses Supabase native auth

-- ============================================================================
-- STEP 1: Remove All Custom Triggers
-- ============================================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_profile_async ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_metadata ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user_correct() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_final() CASCADE;
DROP FUNCTION IF EXISTS public.set_user_role_metadata() CASCADE;
DROP FUNCTION IF EXISTS public.create_user_profile() CASCADE;
DROP FUNCTION IF EXISTS public.create_profile_async() CASCADE;

-- ============================================================================
-- STEP 2: Create Simple Profile Trigger (No Role Manipulation)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Simply create a profile for the new user
    -- No JWT role manipulation, no metadata changes
    INSERT INTO public.profiles (id, role, created_at, updated_at)
    VALUES (NEW.id, 'customer', NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger runs AFTER user is created (no blocking)
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- STEP 3: Ensure Profiles Table Has Role Column
-- ============================================================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'customer';

-- ============================================================================
-- STEP 4: Set Admin Users
-- ============================================================================

UPDATE public.profiles
SET role = 'admin'
WHERE id IN (
    SELECT id FROM auth.users
    WHERE email IN ('admin@elnajar.itargs.com')
);

-- ============================================================================
-- STEP 5: Update RLS Policies to Use auth.uid()
-- ============================================================================

-- Products: Public read, admin write
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;

CREATE POLICY "Products are viewable by everyone"
    ON public.products FOR SELECT
    USING (is_active = true OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    ));

CREATE POLICY "Admins can manage products"
    ON public.products FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Cart: User-specific
DROP POLICY IF EXISTS "Users can view own cart" ON public.cart_items;
DROP POLICY IF EXISTS "Users can manage own cart" ON public.cart_items;

CREATE POLICY "Users can view own cart"
    ON public.cart_items FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can manage own cart"
    ON public.cart_items FOR ALL
    USING (user_id = auth.uid());

-- Wishlist: User-specific
DROP POLICY IF EXISTS "Users can view own wishlist" ON public.wishlists;
DROP POLICY IF EXISTS "Users can manage own wishlist" ON public.wishlists;

CREATE POLICY "Users can view own wishlist"
    ON public.wishlists FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can manage own wishlist"
    ON public.wishlists FOR ALL
    USING (user_id = auth.uid());

-- Orders: User can view own, admin can view all
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;

CREATE POLICY "Users can view own orders"
    ON public.orders FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Admins can view all orders"
    ON public.orders FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Profiles: Users can view/update own, admins can view all
DROP POLICY IF EXISTS "Users see own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins see all profiles" ON public.profiles;

CREATE POLICY "Users see own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users update own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid());

CREATE POLICY "Admins see all profiles"
    ON public.profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- ============================================================================
-- STEP 6: Clear All Sessions (Force Fresh Login)
-- ============================================================================

DELETE FROM auth.sessions;
DELETE FROM auth.refresh_tokens;

-- ============================================================================
-- STEP 7: Verification
-- ============================================================================

SELECT 
    'SIMPLIFIED AUTH IMPLEMENTED' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN p.role = 'admin' THEN 1 END) as admin_users,
    COUNT(CASE WHEN p.role = 'customer' THEN 1 END) as customer_users
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id;

-- Show admin users
SELECT u.email, p.role
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.role = 'admin';
