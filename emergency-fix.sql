-- EMERGENCY FIX: The trigger exists but isn't working
-- Let's fix the new user that was just created and verify the trigger

-- Step 1: Fix the user that just signed up
UPDATE auth.users
SET role = 'authenticated'
WHERE id = '1c217913-1132-42c9-b143-fc378292fe1a';

-- Step 2: Fix ALL users with empty roles
UPDATE auth.users
SET role = 'authenticated'
WHERE role IS NULL OR role = '';

-- Step 3: Recreate the trigger with better error handling
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user_correct();

CREATE OR REPLACE FUNCTION public.handle_new_user_correct()
RETURNS TRIGGER AS $$
BEGIN
    -- CRITICAL: Set the role column (this generates the JWT role claim)
    IF NEW.role IS NULL OR NEW.role = '' THEN
        NEW.role := 'authenticated';
    END IF;
    
    RAISE NOTICE 'Setting role for new user: % to %', NEW.email, NEW.role;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_correct();

-- Step 4: Verify
SELECT 
    'EMERGENCY FIX APPLIED' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN role = 'authenticated' THEN 1 END) as users_with_role,
    COUNT(CASE WHEN role IS NULL OR role = '' THEN 1 END) as users_without_role
FROM auth.users;

-- Step 5: Show the user we just fixed
SELECT id, email, role 
FROM auth.users 
WHERE id = '1c217913-1132-42c9-b143-fc378292fe1a';
