-- Expert Solution: Simplify Authentication
-- Remove profile dependency from JWT tokens
-- Use auth.users as the single source of truth for authentication

-- Step 1: Remove the profile creation trigger (it's causing issues)
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_metadata ON auth.users;

-- Step 2: Create a simple BEFORE INSERT trigger that ONLY sets JWT metadata
CREATE OR REPLACE FUNCTION public.handle_new_user_simple()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set role in metadata for JWT claims - no profile creation
    NEW.raw_user_meta_data = COALESCE(NEW.raw_user_meta_data, '{}'::jsonb) || '{"role": "authenticated"}'::jsonb;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_simple();

-- Step 3: Create profiles AFTER user is created (separate, non-blocking)
-- This runs asynchronously and won't block signup if it fails
CREATE OR REPLACE FUNCTION public.create_profile_async()
RETURNS TRIGGER AS $$
BEGIN
    -- Try to create profile, but don't fail if it errors
    BEGIN
        INSERT INTO public.profiles (id, role, created_at, updated_at)
        VALUES (NEW.id, 'customer', NOW(), NOW())
        ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail the signup
        RAISE WARNING 'Profile creation failed for user %: %', NEW.id, SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_profile_async
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_profile_async();

-- Step 4: Ensure all existing users have the correct role
UPDATE auth.users
SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "authenticated"}'::jsonb
WHERE raw_user_meta_data->>'role' IS NULL OR raw_user_meta_data->>'role' = '';

-- Step 5: Verify
SELECT 
    'Setup complete' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN raw_user_meta_data->>'role' = 'authenticated' THEN 1 END) as users_with_role
FROM auth.users;
