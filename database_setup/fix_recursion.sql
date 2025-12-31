-- 1. Create secure is_admin function
-- This function bypasses RLS (SECURITY DEFINER) to safely check user_roles
-- preventing infinite recursion loops in policies.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role = 'admin'
  );
$$;

-- 2. Update Profiles Policies to use is_admin()
-- Remove the direct query to user_roles which was causing recursion (if user_roles checked profiles)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (
  is_admin() OR auth.uid() = id
);

DROP POLICY IF EXISTS "Admins can update profiles" ON public.profiles;
CREATE POLICY "Admins can update profiles"
ON public.profiles FOR UPDATE
TO authenticated
USING (
  is_admin() OR auth.uid() = id
);

DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;
CREATE POLICY "Admins can delete profiles"
ON public.profiles FOR DELETE
TO authenticated
USING (
  is_admin()
);

-- 3. Update User Roles Policies
-- Remove dependency on profiles.role to break the cycle
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_full_access_user_roles" ON public.user_roles;
CREATE POLICY "Admins can manage user_roles"
ON public.user_roles FOR ALL
TO authenticated
USING (
  is_admin()
)
WITH CHECK (
  is_admin() -- Only admins can insert/update roles
);

-- Ensure users can still read their own role (critical for is_admin to work for non-admins? 
-- No, is_admin is SECURITY DEFINER so it doesn't need this, but the frontend might)
-- Existing policy "Users read own role" should be fine, but ensuring it exists:
DROP POLICY IF EXISTS "Users read own role" ON public.user_roles;
CREATE POLICY "Users read own role"
ON public.user_roles FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

-- 4. Update delete_user_as_admin to use is_admin()
CREATE OR REPLACE FUNCTION delete_user_as_admin(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Only admins can delete users.';
  END IF;

  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

-- Notify PostgREST
NOTIFY pgrst, 'reload schema';
