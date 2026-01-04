-- CORRECT FIX: Use the 'role' column in auth.users table
-- This is the column that Supabase Auth uses for JWT generation

-- Step 1: Set role column for ALL users
UPDATE auth.users
SET role = 'authenticated'
WHERE role IS NULL OR role = '';

-- Step 2: Update trigger to set the role column
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_profile_async ON auth.users;

CREATE OR REPLACE FUNCTION public.handle_new_user_correct()
RETURNS TRIGGER AS $$
BEGIN
    -- Set the role column (this is what generates the JWT role claim)
    NEW.role = 'authenticated';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_correct();

-- Step 3: Create profile async (non-blocking)
CREATE OR REPLACE FUNCTION public.create_profile_async()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        INSERT INTO public.profiles (id, role, created_at, updated_at)
        VALUES (NEW.id, 'customer', NOW(), NOW())
        ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Profile creation failed: %', SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_profile_async
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_profile_async();

-- Step 4: Clear sessions
DELETE FROM auth.sessions;
DELETE FROM auth.refresh_tokens;

-- Step 5: Verify
SELECT 
    'FINAL FIX APPLIED' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN role = 'authenticated' THEN 1 END) as users_with_role
FROM auth.users;

SELECT email, role, created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;
