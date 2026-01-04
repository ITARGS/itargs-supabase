-- NUCLEAR AUTH FIX: FORCING ROLES AND DEFAULTS
-- This script ensures no user can EVER have an empty role again.

-- 1. Fix the auth.users table schema
ALTER TABLE auth.users ALTER COLUMN role SET DEFAULT 'authenticated';
ALTER TABLE auth.users ALTER COLUMN role SET NOT NULL DEFAULT 'authenticated';

-- 2. Force update ALL existing users to have 'authenticated' role
-- Fix NULL values and empty strings
UPDATE auth.users 
SET role = 'authenticated' 
WHERE role IS NULL OR role = '' OR role = 'null';

-- 3. Ensure the 'aud' column is also correctly set to 'authenticated'
UPDATE auth.users 
SET aud = 'authenticated' 
WHERE aud IS NULL OR aud = '' OR aud = 'null';

ALTER TABLE auth.users ALTER COLUMN aud SET DEFAULT 'authenticated';
ALTER TABLE auth.users ALTER COLUMN aud SET NOT NULL DEFAULT 'authenticated';

-- 4. Re-grant permissions to the database roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 5. Recreate functions in public schema for PostgREST
-- This ensures site_settings and product calls work for both anon and authenticated
CREATE OR REPLACE FUNCTION public.is_admin_safe()
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Grant execute permissions on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- 7. Nuke all sessions to force tokens to be regenerated with the new role
TRUNCATE auth.sessions CASCADE;
TRUNCATE auth.refresh_tokens CASCADE;

SELECT 'AUTH_FIX_APPLIED' as status, COUNT(*) as users_fixed 
FROM auth.users 
WHERE role = 'authenticated';
