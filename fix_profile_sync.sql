-- PROFILE DATA SYNC FIX (Supabase Native)

-- 1. Update handle_new_user function to sync metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        full_name, 
        avatar_url, 
        phone, 
        role,
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''), 
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        'customer',
        NOW(), 
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        avatar_url = EXCLUDED.avatar_url,
        phone = CASE WHEN public.profiles.phone IS NULL OR public.profiles.phone = '' THEN EXCLUDED.phone ELSE public.profiles.phone END,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Backfill existing profiles from auth.users metadata
UPDATE public.profiles p
SET 
    full_name = COALESCE(u.raw_user_meta_data->>'full_name', p.full_name, ''),
    avatar_url = COALESCE(u.raw_user_meta_data->>'avatar_url', p.avatar_url, ''),
    phone = CASE 
        WHEN p.phone IS NULL OR p.phone = '' 
        THEN COALESCE(u.raw_user_meta_data->>'phone', '') 
        ELSE p.phone 
    END,
    updated_at = NOW()
FROM auth.users u
WHERE p.id = u.id
AND (p.full_name IS NULL OR p.full_name = '' OR p.phone IS NULL OR p.phone = '');

-- 3. Robust RLS Policies for Profiles
DROP POLICY IF EXISTS "individual_select" ON public.profiles;
DROP POLICY IF EXISTS "individual_update" ON public.profiles;
DROP POLICY IF EXISTS "individual_insert" ON public.profiles;

CREATE POLICY "Users can view own profile" 
ON public.profiles FOR SELECT 
TO public 
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE 
TO authenticated 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" 
ON public.profiles FOR SELECT 
TO authenticated 
USING (public.is_admin_safe());

-- Ensure RLS is active
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
