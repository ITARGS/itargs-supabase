-- ============================================
-- NUCLEAR FIX - COMPLETELY REBUILD RLS
-- Temporarily disable RLS, verify admin function, rebuild everything
-- ============================================

-- Step 1: Verify and recreate is_admin_safe function
DROP FUNCTION IF EXISTS public.is_admin_safe();

CREATE OR REPLACE FUNCTION public.is_admin_safe()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.is_admin_safe() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_safe() TO anon;
GRANT EXECUTE ON FUNCTION public.is_admin_safe() TO public;

-- Step 2: Temporarily disable RLS on critical tables for admin operations
ALTER TABLE public.site_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Step 3: Re-enable RLS
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop ALL existing policies on these tables
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on site_settings
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'site_settings') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.site_settings';
    END LOOP;
    
    -- Drop all policies on profiles
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.profiles';
    END LOOP;
    
    -- Drop all policies on storage.objects
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON storage.objects';
    END LOOP;
END $$;

-- Step 5: Create simple, permissive policies

-- SITE_SETTINGS: Allow everyone to read, admins to write
CREATE POLICY "allow_all_select_site_settings" ON public.site_settings
    FOR SELECT TO public
    USING (true);

CREATE POLICY "allow_admin_all_site_settings" ON public.site_settings
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- PROFILES: Users see own, admins see all
CREATE POLICY "allow_users_select_own_profile" ON public.profiles
    FOR SELECT TO authenticated
    USING (id = auth.uid());

CREATE POLICY "allow_users_update_own_profile" ON public.profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "allow_users_insert_own_profile" ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (id = auth.uid());

CREATE POLICY "allow_admin_all_profiles" ON public.profiles
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- STORAGE: Public read, admin write
CREATE POLICY "allow_public_select_storage" ON storage.objects
    FOR SELECT TO public
    USING (true);

CREATE POLICY "allow_admin_all_storage" ON storage.objects
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Step 6: Grant necessary permissions
GRANT ALL ON public.site_settings TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;
