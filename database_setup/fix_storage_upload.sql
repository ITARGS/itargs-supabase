-- ============================================
-- FIX STORAGE UPLOAD RLS POLICIES
-- Allow admin to upload files to storage buckets
-- ============================================

-- Step 1: Check current storage policies
SELECT 'Current storage policies' as info, policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Step 2: DISABLE RLS on storage.objects
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Step 3: Re-enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop ALL existing policies on storage.objects
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON storage.objects';
    END LOOP;
END $$;

-- Step 5: Create simple permissive policies

-- Allow authenticated users to upload to any bucket
CREATE POLICY "authenticated_insert_objects"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update any object
CREATE POLICY "authenticated_update_objects"
ON storage.objects FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow authenticated users to delete any object
CREATE POLICY "authenticated_delete_objects"
ON storage.objects FOR DELETE
TO authenticated
USING (true);

-- Allow public to view all objects
CREATE POLICY "public_select_objects"
ON storage.objects FOR SELECT
TO public
USING (true);

-- Step 6: Grant permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Step 7: Ensure buckets exist and are public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('store-assets', 'store-assets', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']::text[])
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']::text[];

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('product-images', 'product-images', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']::text[])
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']::text[];

-- Step 8: Verify
SELECT 'Storage buckets' as info, id, name, public FROM storage.buckets ORDER BY name;
SELECT 'Storage policies' as info, policyname, cmd FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';
