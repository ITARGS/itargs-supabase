-- ============================================
-- FIX INFINITE RECURSION IN PROFILES TABLE
-- The is_admin_safe() function queries profiles table
-- So profiles table CANNOT use is_admin_safe() in its policies
-- ============================================

-- Step 1: Drop ALL policies on profiles table
DROP POLICY IF EXISTS "admin_full_access_profiles" ON public.profiles;
DROP POLICY IF EXISTS "allow_admin_all_profiles" ON public.profiles;
DROP POLICY IF EXISTS "users_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by owner" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are updatable by owner" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are insertable by owner" ON public.profiles;
DROP POLICY IF EXISTS "Admins see all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users see own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;

-- Step 2: Create simple policies WITHOUT using is_admin_safe()
-- Users can see and manage their own profile
CREATE POLICY "profiles_select_own"
ON public.profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "profiles_insert_own"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Admins can see ALL profiles (using direct role check, not function)
CREATE POLICY "profiles_admin_select_all"
ON public.profiles FOR SELECT
TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- Admins can update ANY profile (using direct role check)
CREATE POLICY "profiles_admin_update_all"
ON public.profiles FOR UPDATE
TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- Admins can insert ANY profile (using direct role check)
CREATE POLICY "profiles_admin_insert_all"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- Step 3: Clean up site_settings - remove duplicate policies
DROP POLICY IF EXISTS "Settings are manageable by authenticated users" ON public.site_settings;
DROP POLICY IF EXISTS "Settings are viewable by everyone" ON public.site_settings;
DROP POLICY IF EXISTS "allow_admin_all_site_settings" ON public.site_settings;
DROP POLICY IF EXISTS "allow_all_select_site_settings" ON public.site_settings;
DROP POLICY IF EXISTS "public_read_settings" ON public.site_settings;

-- Keep only the admin_full_access policy
-- (admin_full_access_site_settings already exists from master fix)

-- Add public read for site_settings
CREATE POLICY "site_settings_public_read"
ON public.site_settings FOR SELECT
TO public
USING (true);

-- Step 4: Verify admin user
SELECT 
  'Admin verification' as status,
  id,
  email,
  role
FROM public.profiles
WHERE email = 'admin@elnajar.itargs.com';
