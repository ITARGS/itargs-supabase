-- Fix RLS policies for products table to allow admin INSERT/UPDATE/DELETE

-- Drop existing admin policies if they exist
DROP POLICY IF EXISTS "Admins can insert products" ON products;
DROP POLICY IF EXISTS "Admins can update products" ON products;
DROP POLICY IF EXISTS "Admins can delete products" ON products;
DROP POLICY IF EXISTS "Admins manage products" ON products;

-- Create comprehensive admin policy for all operations
CREATE POLICY "Admins can manage products"
ON products
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Ensure public can view active products
DROP POLICY IF EXISTS "Public can view active products" ON products;
CREATE POLICY "Public can view active products"
ON products
FOR SELECT
TO public, anon, authenticated
USING (is_active = true);

-- Reload PostgREST
NOTIFY pgrst, 'reload schema';
