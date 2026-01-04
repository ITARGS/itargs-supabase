-- Fix the trigger to remove email column reference
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Set role in raw_user_meta_data for JWT claims
    NEW.raw_user_meta_data = COALESCE(NEW.raw_user_meta_data, '{}'::jsonb) || '{"role": "authenticated"}'::jsonb;
    
    -- Insert into profiles table (without email column)
    INSERT INTO public.profiles (id, role, created_at, updated_at)
    VALUES (
        NEW.id,
        'customer',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the function was created
SELECT 'Trigger function updated successfully' as status;
