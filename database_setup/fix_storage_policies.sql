-- ============================================
-- FIX STORAGE BUCKET POLICIES
-- Allow admin users to upload/manage files in storage buckets
-- ============================================

-- Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('store-assets', 'store-assets', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'])
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('product-images', 'product-images', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('review-images', 'review-images', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop existing storage policies
DROP POLICY IF EXISTS "Admin can upload store assets" ON storage.objects;
DROP POLICY IF EXISTS "Admin can update store assets" ON storage.objects;
DROP POLICY IF EXISTS "Admin can delete store assets" ON storage.objects;
DROP POLICY IF EXISTS "Public can view store assets" ON storage.objects;

DROP POLICY IF EXISTS "Admin can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Admin can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Admin can delete product images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view product images" ON storage.objects;

DROP POLICY IF EXISTS "Admin can upload review images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view review images" ON storage.objects;

-- Create comprehensive admin storage policies
-- STORE ASSETS BUCKET
CREATE POLICY "Admin full access to store assets"
ON storage.objects FOR ALL
TO authenticated
USING (
  bucket_id = 'store-assets' AND 
  public.is_admin_safe()
)
WITH CHECK (
  bucket_id = 'store-assets' AND 
  public.is_admin_safe()
);

CREATE POLICY "Public can view store assets"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'store-assets');

-- PRODUCT IMAGES BUCKET
CREATE POLICY "Admin full access to product images"
ON storage.objects FOR ALL
TO authenticated
USING (
  bucket_id = 'product-images' AND 
  public.is_admin_safe()
)
WITH CHECK (
  bucket_id = 'product-images' AND 
  public.is_admin_safe()
);

CREATE POLICY "Public can view product images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- REVIEW IMAGES BUCKET
CREATE POLICY "Admin full access to review images"
ON storage.objects FOR ALL
TO authenticated
USING (
  bucket_id = 'review-images' AND 
  public.is_admin_safe()
)
WITH CHECK (
  bucket_id = 'review-images' AND 
  public.is_admin_safe()
);

CREATE POLICY "Authenticated users can upload review images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'review-images');

CREATE POLICY "Public can view review images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'review-images');
