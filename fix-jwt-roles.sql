-- Fix JWT Role Authentication Issues
-- This script ensures all users have proper role claims in their JWT tokens

-- Step 1: Update existing users to have 'authenticated' role in metadata
UPDATE auth.users
SET raw_user_meta_data = 
    CASE 
        WHEN raw_user_meta_data IS NULL THEN '{"role": "authenticated"}'::jsonb
        ELSE raw_user_meta_data || '{"role": "authenticated"}'::jsonb
    END
WHERE raw_user_meta_data->>'role' IS NULL OR raw_user_meta_data->>'role' = '';

-- Step 2: Create or replace trigger function to set role on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Set role in raw_user_meta_data for JWT claims
    NEW.raw_user_meta_data = COALESCE(NEW.raw_user_meta_data, '{}'::jsonb) || '{"role": "authenticated"}'::jsonb;
    
    -- Insert into profiles table
    INSERT INTO public.profiles (id, email, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        'customer',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Drop existing trigger if it exists and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 4: Verify the fix
SELECT 
    id, 
    email, 
    raw_user_meta_data->>'role' as jwt_role,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- Step 5: Show profiles
SELECT id, email, role FROM public.profiles ORDER BY created_at DESC LIMIT 10;
