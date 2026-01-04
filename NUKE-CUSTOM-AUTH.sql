-- NUCLEAR CLEANUP: RESTORE TO COMPLETELY RAW SUPABASE AUTH
-- This removes EVERY custom trigger and function we added.

-- 1. DROP ALL TRIGGERS from auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_profile_async ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_metadata ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_metadata_fix ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_final ON auth.users CASCADE;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users CASCADE;

-- 2. DROP ALL FUNCTIONS related to auth/profiles
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_correct() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_final() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_metadata() CASCADE;
DROP FUNCTION IF EXISTS public.set_user_role_metadata() CASCADE;
DROP FUNCTION IF EXISTS public.create_user_profile() CASCADE;
DROP FUNCTION IF EXISTS public.create_profile_async() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_safe() CASCADE;

-- 3. CLEAN auth.users table 
-- Remove custom metadata that we added which might be poisoning JWTs
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data - 'role',
    raw_app_meta_data = raw_app_meta_data - 'role',
    role = 'authenticated'; -- Ensure everyone has the default role

-- 4. CLEAN UP RLS POLICIES
-- We will restore basic policies so the site still works, 
-- but we move away from any custom role logic.

-- Products
DROP POLICY IF EXISTS "products_select" ON public.products;
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
CREATE POLICY "Allow public read" ON public.products FOR SELECT USING (true);

-- Categories
DROP POLICY IF EXISTS "categories_select" ON public.categories;
CREATE POLICY "Allow public read" ON public.categories FOR SELECT USING (true);

-- Site Settings
DROP POLICY IF EXISTS "settings_select" ON public.site_settings;
CREATE POLICY "Allow public read" ON public.site_settings FOR SELECT USING (true);

-- 5. CLEAR SESSIONS
TRUNCATE auth.sessions CASCADE;
TRUNCATE auth.refresh_tokens CASCADE;

SELECT 'DATABASE RESET TO RAW SUPABASE AUTH' as status;
