#!/bin/bash

# ============================================================================
# Deploy RLS Fix for product_performance_tiers to Supabase Server
# ============================================================================
# This script fixes the RLS policy to allow admin INSERT operations
# ============================================================================

echo "🚀 Deploying RLS fix for product_performance_tiers..."

# Configuration
CLIENT_NAME="kat"  # Change this if your client name is different
CONTAINER_NAME="supabase_${CLIENT_NAME}-db-1"

# Check if container exists
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: Container ${CONTAINER_NAME} not found"
    echo "Available containers:"
    docker ps --format '{{.Names}}' | grep supabase
    exit 1
fi

echo "✅ Found container: ${CONTAINER_NAME}"
echo "📝 Applying RLS policy fix..."

# Execute SQL directly in the container
docker exec -i "${CONTAINER_NAME}" psql -U postgres <<'EOF'
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
    '✅ RLS Policy Fixed' as status,
    schemaname, 
    tablename, 
    policyname, 
    cmd
FROM pg_policies 
WHERE tablename = 'product_performance_tiers'
ORDER BY policyname;

SELECT '🎉 Deployment Complete!' as message;
EOF

if [ $? -eq 0 ]; then
    echo "✅ RLS policy fix applied successfully!"
    echo ""
    echo "📋 What was deployed:"
    echo "  ✅ Updated 'product_performance_tiers' RLS policy"
    echo "  ✅ Added WITH CHECK clause for INSERT operations"
    echo "  ✅ Admins can now create/edit product performance tier assignments"
    echo ""
    echo "🎉 You can now add products with performance tiers from the Admin panel!"
else
    echo "❌ Error applying RLS fix"
    exit 1
fi
