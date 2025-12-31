-- Fix handle_new_user function to remove email column
-- The profiles table doesn't have an email column (email is in auth.users)

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Create Profile from Meta Data (without email)
  INSERT INTO public.profiles (id, full_name)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'New User')
  );

  -- Assign Default 'customer' Role
  -- (Admins must be manually promoted)
  INSERT INTO public.user_roles (user_id, role)
  VALUES (new.id, 'customer')
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN new;
END;
$$;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
