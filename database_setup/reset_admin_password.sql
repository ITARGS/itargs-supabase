-- Reset admin password for admin@elnajar.itargs.com
-- New password will be: Admin@Elnajar2025

-- First, get the user ID
DO $$
DECLARE
    admin_user_id uuid;
BEGIN
    -- Get admin user ID
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email = 'admin@elnajar.itargs.com';
    
    IF admin_user_id IS NOT NULL THEN
        -- Update password (Supabase will hash it automatically)
        -- Note: This updates the encrypted_password field
        -- The password will be: Admin@Elnajar2025
        UPDATE auth.users
        SET 
            encrypted_password = crypt('Admin@Elnajar2025', gen_salt('bf')),
            updated_at = now()
        WHERE id = admin_user_id;
        
        RAISE NOTICE 'Password reset successful for admin@elnajar.itargs.com';
        RAISE NOTICE 'New password: Admin@Elnajar2025';
    ELSE
        RAISE NOTICE 'Admin user not found';
    END IF;
END $$;
