-- ============================================
-- FIX STORAGE SERVICE PERMISSIONS
-- Grant the storage service role access to storage schema
-- ============================================

-- Step 1: Grant usage on storage schema
GRANT USAGE ON SCHEMA storage TO postgres, anon, authenticated, service_role;

-- Step 2: Grant all permissions on storage tables
GRANT ALL ON ALL TABLES IN SCHEMA storage TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO postgres, anon, authenticated, service_role;

-- Step 3: Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;

-- Step 4: Specifically grant on objects table
GRANT ALL ON storage.objects TO postgres, anon, authenticated, service_role, PUBLIC;
GRANT ALL ON storage.buckets TO postgres, anon, authenticated, service_role, PUBLIC;

-- Step 5: Ensure RLS is disabled
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- Step 6: Verify permissions
SELECT 
  'Storage Objects Permissions' as info,
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'storage' AND table_name = 'objects'
ORDER BY grantee, privilege_type;

-- Step 7: Verify table exists and is accessible
SELECT 'Storage Objects Table' as info, COUNT(*) as row_count FROM storage.objects;
SELECT 'Storage Buckets Table' as info, COUNT(*) as bucket_count FROM storage.buckets;
