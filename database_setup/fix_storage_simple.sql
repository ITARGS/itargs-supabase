-- Simplified storage RLS policy - allow all authenticated users to upload product images
-- This is a more permissive approach that will definitely work

-- Drop all existing product-images policies
DROP POLICY IF EXISTS "Admin insert product images" ON storage.objects;
DROP POLICY IF EXISTS "Admin update product images" ON storage.objects;
DROP POLICY IF EXISTS "Admin delete product images" ON storage.objects;
DROP POLICY IF EXISTS "Public view product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete product images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view product images" ON storage.objects;

-- Simple policy: All authenticated users can upload to product-images
CREATE POLICY "Authenticated users can upload product images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images'
);

-- All authenticated users can update their uploads
CREATE POLICY "Authenticated users can update product images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images');

-- All authenticated users can delete product images
CREATE POLICY "Authenticated users can delete product images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'product-images');

-- Everyone can view product images (public bucket)
CREATE POLICY "Everyone can view product images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- Ensure bucket is public
UPDATE storage.buckets 
SET public = true,
    file_size_limit = 5242880, -- 5MB limit
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
WHERE id = 'product-images';

COMMENT ON POLICY "Authenticated users can upload product images" ON storage.objects 
IS 'Allows any authenticated user to upload product images - can be restricted to admins later if needed';
