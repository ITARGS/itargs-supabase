-- Fix storage.objects RLS policies - ensure admin can upload

-- First, ensure RLS is enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop all existing product-images policies
DROP POLICY IF EXISTS "Admins can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete product images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view product images" ON storage.objects;

-- Create a comprehensive admin policy for INSERT
CREATE POLICY "Admin insert product images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images' AND
    (
        -- Check if user is admin
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_roles.user_id = auth.uid()
            AND user_roles.role = 'admin'::public.app_role
        )
        OR
        -- Allow if owner matches
        (storage.foldername(name))[1] = auth.uid()::text
    )
);

-- Create admin policy for UPDATE
CREATE POLICY "Admin update product images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'::public.app_role
    )
);

-- Create admin policy for DELETE
CREATE POLICY "Admin delete product images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'::public.app_role
    )
);

-- Create public SELECT policy
CREATE POLICY "Public view product images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- Ensure bucket exists and is public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'product-images';

-- Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT SELECT ON storage.objects TO anon;

COMMENT ON POLICY "Admin insert product images" ON storage.objects IS 'Allows admins to upload product images';
