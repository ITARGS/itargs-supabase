-- Add admin policy to addresses table to allow admins to view all addresses
-- This is needed for the admin panel to display customer shipping addresses in orders

CREATE POLICY "Admins can view all addresses"
ON addresses
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
