-- Fix: Change trigger from BEFORE to AFTER INSERT
-- The profiles table has FK constraint to auth.users, so we must insert AFTER the user exists

-- Step 1: Create separate function for metadata (BEFORE trigger)
CREATE OR REPLACE FUNCTION public.set_user_role_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set role in metadata for JWT claims
    NEW.raw_user_meta_data = COALESCE(NEW.raw_user_meta_data, '{}'::jsonb) || '{"role": "authenticated"}'::jsonb;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create function for profile creation (AFTER trigger)
CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into profiles table AFTER user is created
    INSERT INTO public.profiles (id, role, created_at, updated_at)
    VALUES (
        NEW.id,
        'customer',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Drop old trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 4: Create BEFORE trigger for metadata
CREATE TRIGGER on_auth_user_created_metadata
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.set_user_role_metadata();

-- Step 5: Create AFTER trigger for profile
CREATE TRIGGER on_auth_user_created_profile
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_user_profile();

-- Verify
SELECT 'Triggers fixed successfully - metadata BEFORE, profile AFTER' as status;
