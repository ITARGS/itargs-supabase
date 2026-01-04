-- Expert Solution: Force all users to get new JWT tokens
-- This updates the user metadata which will invalidate cached tokens

-- Step 1: Force token refresh by updating all users' updated_at timestamp
UPDATE auth.users
SET 
    updated_at = NOW(),
    -- Ensure role is set
    raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "authenticated", "token_version": 2}'::jsonb
WHERE raw_user_meta_data->>'role' IS NOT NULL;

-- Step 2: For any users still without role (edge case)
UPDATE auth.users
SET 
    updated_at = NOW(),
    raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "authenticated", "token_version": 2}'::jsonb
WHERE raw_user_meta_data->>'role' IS NULL;

-- Step 3: Verify all users have correct role
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN raw_user_meta_data->>'role' = 'authenticated' THEN 1 END) as users_with_role,
    COUNT(CASE WHEN raw_user_meta_data->>'role' IS NULL THEN 1 END) as users_without_role
FROM auth.users;

-- Step 4: Show sample of updated users
SELECT 
    id,
    email,
    raw_user_meta_data->>'role' as role,
    raw_user_meta_data->>'token_version' as token_version,
    updated_at
FROM auth.users
ORDER BY updated_at DESC
LIMIT 5;
