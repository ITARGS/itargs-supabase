#!/bin/bash

# ============================================================================
# Deploy SQL Changes to Supabase Server (31.97.34.23)
# ============================================================================
# This script applies the storage bucket and Meta Pixel settings to your
# self-hosted Supabase instance
# ============================================================================

echo "🚀 Deploying SQL changes to Supabase..."

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

# Create SQL file
cat > /tmp/supabase_updates.sql <<'EOF'
-- ============================================================================
-- Storage Bucket Setup
-- ============================================================================

-- Create the storage bucket for store assets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'store-assets',
  'store-assets',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete" ON storage.objects;

-- Allow public read access to all files in the bucket
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT
USING ( bucket_id = 'store-assets' );

-- Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT
WITH CHECK ( 
  bucket_id = 'store-assets' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to update their uploads
CREATE POLICY "Authenticated users can update" ON storage.objects
FOR UPDATE
USING ( 
  bucket_id = 'store-assets' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to delete their uploads
CREATE POLICY "Authenticated users can delete" ON storage.objects
FOR DELETE
USING ( 
  bucket_id = 'store-assets' 
  AND auth.role() = 'authenticated'
);

-- ============================================================================
-- Meta Pixel Settings
-- ============================================================================

-- Add Meta Pixel settings if they don't exist
INSERT INTO settings (key, value, created_at, updated_at)
VALUES 
  ('meta_pixel_id', '', NOW(), NOW()),
  ('enable_meta_pixel', 'false', NOW(), NOW())
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- Verification
-- ============================================================================

-- Verify the setup
SELECT 
  'Storage Bucket Created' as status,
  id,
  name,
  public,
  file_size_limit
FROM storage.buckets
WHERE id = 'store-assets';

SELECT 
  'Meta Pixel Settings Added' as status,
  key,
  value
FROM settings
WHERE key IN ('meta_pixel_id', 'enable_meta_pixel');

SELECT 'Deployment Complete!' as message;
EOF

echo "📝 Applying SQL changes..."

# Execute SQL in the container
docker exec -i "${CONTAINER_NAME}" psql -U postgres <<EOF
\i /tmp/supabase_updates.sql
EOF

if [ $? -eq 0 ]; then
    echo "✅ SQL changes applied successfully!"
    echo ""
    echo "📋 What was deployed:"
    echo "  ✅ Created 'store-assets' storage bucket"
    echo "  ✅ Set up public access policies"
    echo "  ✅ Added Meta Pixel settings"
    echo ""
    echo "🎉 Deployment complete!"
else
    echo "❌ Error applying SQL changes"
    exit 1
fi

# Cleanup
rm -f /tmp/supabase_updates.sql
