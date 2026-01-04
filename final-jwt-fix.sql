-- FINAL FIX: Use app_metadata for JWT role claims
-- Supabase Auth uses app_metadata, not raw_user_meta_data for JWT generation

-- Step 1: Move role to app_metadata for ALL users
UPDATE auth.users
SET app_metadata = COALESCE(app_metadata, '{}'::jsonb) || '{"role": "authenticated"}'::jsonb;

-- Step 2: Update trigger to use app_metadata
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE OR REPLACE FUNCTION public.handle_new_user_final()
RETURNS TRIGGER AS $$
BEGIN
    -- Set role in app_metadata (this is what Supabase Auth uses for JWT)
    NEW.app_metadata = COALESCE(NEW.app_metadata, '{}'::jsonb) || '{"role": "authenticated"}'::jsonb;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_final();

-- Step 3: Clear all sessions to force new JWT generation
DELETE FROM auth.sessions;
DELETE FROM auth.refresh_tokens;

-- Step 4: Verify
SELECT 
    'Fix applied successfully' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN app_metadata->>'role' = 'authenticated' THEN 1 END) as users_with_role
FROM auth.users;

-- Step 5: Show sample
SELECT 
    email,
    app_metadata->>'role' as app_role,
    raw_user_meta_data->>'role' as raw_role
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;
