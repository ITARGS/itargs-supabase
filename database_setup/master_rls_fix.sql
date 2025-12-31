-- ============================================
-- MASTER RLS FIX - GRANT ADMIN FULL ACCESS TO EVERYTHING
-- This script gives admin users complete access to all tables
-- ============================================

-- Recreate is_admin_safe function with CASCADE to drop dependencies
DROP FUNCTION IF EXISTS public.is_admin_safe() CASCADE;

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
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$;

-- Grant execute to everyone
GRANT EXECUTE ON FUNCTION public.is_admin_safe() TO authenticated, anon, public;

-- Now create admin bypass policies for EVERY table
-- The pattern: admins can do ANYTHING, others have restricted access

DO $$
DECLARE
  table_record RECORD;
BEGIN
  -- Loop through all tables in public schema
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
  LOOP
    -- Drop all existing policies
    EXECUTE format('DROP POLICY IF EXISTS "admin_full_access_%s" ON public.%I', table_record.tablename, table_record.tablename);
    
    -- Create admin full access policy
    EXECUTE format('
      CREATE POLICY "admin_full_access_%s" 
      ON public.%I 
      FOR ALL 
      TO authenticated 
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles 
          WHERE id = auth.uid() AND role = ''admin''
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles 
          WHERE id = auth.uid() AND role = ''admin''
        )
      )', table_record.tablename, table_record.tablename);
    
    RAISE NOTICE 'Created admin policy for table: %', table_record.tablename;
  END LOOP;
END $$;

-- Special handling for storage.objects
DROP POLICY IF EXISTS "admin_full_access_storage" ON storage.objects;
CREATE POLICY "admin_full_access_storage"
ON storage.objects
FOR ALL
TO authenticated
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

-- Public read access for storage
DROP POLICY IF EXISTS "public_read_storage" ON storage.objects;
CREATE POLICY "public_read_storage"
ON storage.objects
FOR SELECT
TO public
USING (true);

-- Grant all permissions to authenticated users
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('GRANT ALL ON public.%I TO authenticated', table_record.tablename);
  END LOOP;
END $$;

-- Grant storage permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Ensure profiles table allows users to see their own profile
DROP POLICY IF EXISTS "users_own_profile" ON public.profiles;
CREATE POLICY "users_own_profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Ensure site_settings is readable by everyone
DROP POLICY IF EXISTS "public_read_settings" ON public.site_settings;
CREATE POLICY "public_read_settings"
ON public.site_settings
FOR SELECT
TO public
USING (true);

-- Verify admin user exists and has correct role
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE email = 'admin@elnajar.itargs.com' AND role = 'admin'
  ) THEN
    -- Update or insert admin profile
    INSERT INTO public.profiles (id, email, full_name, role)
    SELECT id, email, 'Admin User', 'admin'
    FROM auth.users
    WHERE email = 'admin@elnajar.itargs.com'
    ON CONFLICT (id) DO UPDATE SET role = 'admin', email = 'admin@elnajar.itargs.com';
  END IF;
END $$;

-- Final verification
SELECT 
  'Admin user verified' as status,
  email,
  role
FROM public.profiles
WHERE email = 'admin@elnajar.itargs.com';
