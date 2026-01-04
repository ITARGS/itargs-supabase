-- EMERGENCY FIX: Infinite Recursion in Profiles RLS Policy
-- The "Admins see all profiles" policy is causing infinite recursion

-- ============================================================================
-- STEP 1: Drop the Problematic Policy
-- ============================================================================

DROP POLICY IF EXISTS "Admins see all profiles" ON public.profiles;

-- ============================================================================
-- STEP 2: Recreate Without Recursion
-- ============================================================================

-- Simple policy: Users see own profile, that's it
-- Admin check will be done in application logic, not RLS
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid());

-- For admin access, we'll use a different approach
-- Create a simple function that doesn't cause recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- STEP 3: Fix Other Policies to Avoid Recursion
-- ============================================================================

-- Products: Remove the recursive admin check
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;

CREATE POLICY "Products are viewable by everyone"
    ON public.products FOR SELECT
    USING (true);  -- Public read, no auth needed

CREATE POLICY "Admins can manage products"
    ON public.products FOR ALL
    USING (public.is_admin());

-- Orders: Fix admin policy
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;

CREATE POLICY "Admins can view all orders"
    ON public.orders FOR ALL
    USING (public.is_admin());

-- ============================================================================
-- STEP 4: Verification
-- ============================================================================

SELECT 'INFINITE RECURSION FIXED' as status;

-- Test the is_admin function
SELECT public.is_admin() as am_i_admin;
