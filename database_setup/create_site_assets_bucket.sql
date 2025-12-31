-- Create the site-assets bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'site-assets', 
  'site-assets', 
  true, 
  5242880, -- 5MB limit
  ARRAY['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/svg+xml'];

-- Ensure RLS is enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Allow public access to site-assets
DROP POLICY IF EXISTS "Public Access site-assets" ON storage.objects;
CREATE POLICY "Public Access site-assets"
ON storage.objects FOR SELECT
USING ( bucket_id = 'site-assets' );

-- Allow authenticated uploads
DROP POLICY IF EXISTS "Authenticated Upload site-assets" ON storage.objects;
CREATE POLICY "Authenticated Upload site-assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'site-assets' );

-- Allow authenticated updates
DROP POLICY IF EXISTS "Authenticated Update site-assets" ON storage.objects;
CREATE POLICY "Authenticated Update site-assets"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'site-assets' );

-- Allow authenticated deletes
DROP POLICY IF EXISTS "Authenticated Delete site-assets" ON storage.objects;
CREATE POLICY "Authenticated Delete site-assets"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'site-assets' );
