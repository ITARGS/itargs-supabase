-- DEFINITIVE AUTH FIX (SUPABASE-SAFE CHECKLIST)
-- Source: User Instructions for corrupted auth.users roles

-- 1) Fix existing corrupted users (empty / null / wrong role)
UPDATE auth.users
SET role = 'authenticated',
    aud  = 'authenticated'
WHERE
    (role IS NULL OR role = '' OR role <> 'authenticated')
    OR (aud IS NULL OR aud = '' OR aud <> 'authenticated');

-- 2) Enforce defaults so the bug never happens again
ALTER TABLE auth.users ALTER COLUMN role SET DEFAULT 'authenticated';
ALTER TABLE auth.users ALTER COLUMN aud SET DEFAULT 'authenticated';

-- 3) Block null / empty values permanently
-- First ensure no data violates this (Step 1 did this)
ALTER TABLE auth.users ALTER COLUMN role SET NOT NULL;
ALTER TABLE auth.users ALTER COLUMN aud SET NOT NULL;

-- 4) Add constraints to prevent wrong values
-- Drop existing constraints if any (to avoid "already exists" errors)
ALTER TABLE auth.users DROP CONSTRAINT IF EXISTS role_must_be_authenticated;
ALTER TABLE auth.users DROP CONSTRAINT IF EXISTS aud_must_be_authenticated;

ALTER TABLE auth.users
ADD CONSTRAINT role_must_be_authenticated
CHECK (role = 'authenticated');

ALTER TABLE auth.users
ADD CONSTRAINT aud_must_be_authenticated
CHECK (aud = 'authenticated');

-- 5) Ensure every auth user has a profile
INSERT INTO public.profiles (id)
SELECT id
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = u.id
)
ON CONFLICT (id) DO NOTHING;

-- 6) Invalidate sessions + refresh tokens (forces new JWTs)
DELETE FROM auth.refresh_tokens;
DELETE FROM auth.sessions;

-- 7) Rebuild public.is_admin_safe (if missing or broken)
CREATE OR REPLACE FUNCTION public.is_admin_safe()
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.is_admin_safe() TO anon, authenticated;

SELECT 'DEFINITIVE FIX APPLIED SUCCESS' as status;
