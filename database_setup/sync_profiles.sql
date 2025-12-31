-- 1. Insert missing profiles from auth.users
INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
SELECT 
  id, 
  email, 
  COALESCE(raw_user_meta_data->>'full_name', 'Unnamed User'),
  created_at,
  updated_at
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles);

-- 2. Ensure Trigger exists for future users
-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Unnamed User'),
    NEW.created_at,
    NEW.updated_at
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
