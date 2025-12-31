-- Complete storage bucket reset and RLS policy fix
-- This will ensure everything is properly configured

-- 1. Ensure bucket exists with correct settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    5242880, -- 5MB
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];

-- 2. Drop ALL existing policies on storage.objects
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
    END LOOP;
END $$;

-- 3. Create simple, permissive policies for product-images

-- Allow INSERT for authenticated users
CREATE POLICY "product_images_insert"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- Allow SELECT for everyone
CREATE POLICY "product_images_select"
ON storage.objects
FOR SELECT
USING (bucket_id = 'product-images');

-- Allow UPDATE for authenticated users
CREATE POLICY "product_images_update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images');

-- Allow DELETE for authenticated users
CREATE POLICY "product_images_delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'product-images');

-- 4. Ensure RLS is enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 5. Grant permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT SELECT ON storage.objects TO anon;
GRANT ALL ON storage.buckets TO authenticated;
GRANT SELECT ON storage.buckets TO anon;

-- Verify setup
SELECT 'Bucket configured:' as status, id, name, public FROM storage.buckets WHERE id = 'product-images';
SELECT 'Policies created:' as status, policyname, cmd FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE 'product_images%';
