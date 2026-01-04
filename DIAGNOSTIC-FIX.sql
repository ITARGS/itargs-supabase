-- DIAGNOSTIC AND FIX SCRIPT
-- 1. Check for empty roles in auth.users
SELECT id, email, role FROM auth.users WHERE role = '' OR role IS NULL;

-- 2. Ensure everyone has 'authenticated' role
UPDATE auth.users SET role = 'authenticated' WHERE role = '' OR role IS NULL;

-- 3. Check anon role permissions again
SELECT grantee, table_name, privilege_type 
FROM information_schema.table_privileges 
WHERE grantee = 'anon' AND table_schema = 'public' 
AND table_name IN ('site_settings', 'products', 'categories');

-- 4. Recreate is_admin_safe dummy function (Frontend expects it)
CREATE OR REPLACE FUNCTION public.is_admin_safe()
RETURNS boolean AS $$
BEGIN
    -- Check if user is admin in profiles table
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Final Role Permission Hammer
DO $$ 
BEGIN
    -- Ensure roles exist (they should, but just in case)
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- 6. Ensure postgres can assume these roles (for PostgREST)
GRANT anon TO postgres;
GRANT authenticated TO postgres;

SELECT 'DIAGNOSTIC AND FIX COMPLETE' as status;
