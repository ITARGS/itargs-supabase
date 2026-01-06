-- Fix RLS policy for product_performance_tiers to allow admin INSERT operations
-- The existing policy only has USING clause, which doesn't work for INSERT
-- We need to add WITH CHECK clause for INSERT/UPDATE operations

-- Drop the existing admin policy
DROP POLICY IF EXISTS "Admins can manage product performance tiers" ON public.product_performance_tiers;

-- Recreate with proper INSERT support using WITH CHECK
CREATE POLICY "Admins can manage product performance tiers"
ON public.product_performance_tiers FOR ALL
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

-- Verify the policy was created
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'product_performance_tiers'
ORDER BY policyname;
