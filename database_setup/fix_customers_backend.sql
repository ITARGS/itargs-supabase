-- 1. Create delete_user_as_admin function
CREATE OR REPLACE FUNCTION delete_user_as_admin(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the executing user is an admin is handled by RLS/App logic usually, 
  -- but strictly speaking this function allows deleting ANY user. 
  -- We rely on the API to only expose this to admins or check roles here.
  -- For safety, let's verify if the caller has 'admin' role in user_roles table.
  
  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Only admins can delete users.';
  END IF;

  -- Delete from auth.users (cascades to profiles, orders, etc. if configured)
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

-- 2. Fix FK relationship for PostgREST embedding (orders -> profiles)
-- First drop existing constraint if it points to auth.users to avoid ambiguity or conflicts
-- We want orders.user_id to point to profiles.id so we can do profiles -> orders(count)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'orders_user_id_fkey'
    ) THEN
        ALTER TABLE public.orders DROP CONSTRAINT orders_user_id_fkey;
    END IF;
END $$;

ALTER TABLE public.orders
ADD CONSTRAINT orders_user_id_fkey
FOREIGN KEY (user_id) REFERENCES public.profiles(id)
ON DELETE CASCADE;

-- 3. Ensure RLS Policies for Admin on Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
  OR auth.uid() = id -- Users can see themselves
);

DROP POLICY IF EXISTS "Admins can update profiles" ON public.profiles;
CREATE POLICY "Admins can update profiles"
ON public.profiles FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
  OR auth.uid() = id
);

DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;
CREATE POLICY "Admins can delete profiles"
ON public.profiles FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
