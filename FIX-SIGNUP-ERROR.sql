-- FIX: REMOVE BREAKING CONSTRAINTS
-- The CHECK constraints on auth.users are blocking GoTrue (Supabase Auth) 
-- from inserting new users because it sends an empty string initially.

-- 1. Remove the breaking constraints
ALTER TABLE auth.users DROP CONSTRAINT IF EXISTS role_must_be_authenticated;
ALTER TABLE auth.users DROP CONSTRAINT IF EXISTS aud_must_be_authenticated;

-- 2. Use a TRIGGER instead to ensure the role is NEVER empty
-- This is safer than a CHECK constraint because it allows the insert to happen 
-- and then fixes the value if it's wrong.

CREATE OR REPLACE FUNCTION auth.ensure_authenticated_role()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role IS NULL OR NEW.role = '' THEN
        NEW.role := 'authenticated';
    END IF;
    IF NEW.aud IS NULL OR NEW.aud = '' THEN
        NEW.aud := 'authenticated';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_role_on_insert ON auth.users;
CREATE TRIGGER ensure_role_on_insert
    BEFORE INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION auth.ensure_authenticated_role();

-- 3. Just in case, ensure existing ones are still clean
UPDATE auth.users SET role = 'authenticated' WHERE role IS NULL OR role = '';

SELECT 'CONSTRAINTS REMOVED AND SAFE TRIGGER ADDED' as status;
