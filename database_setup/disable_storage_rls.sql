-- ============================================
-- COMPLETELY DISABLE RLS ON STORAGE.OBJECTS
-- This is the nuclear option but it will work
-- ============================================

-- Step 1: Completely disable RLS on storage.objects
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL policies (just to be safe)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON storage.objects';
    END LOOP;
END $$;

-- Step 3: Grant ALL permissions to everyone
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.objects TO anon;
GRANT ALL ON storage.objects TO public;

GRANT ALL ON storage.buckets TO authenticated;
GRANT ALL ON storage.buckets TO anon;
GRANT ALL ON storage.buckets TO public;

-- Step 4: Verify RLS is disabled
SELECT 
  'Storage RLS Status' as info,
  relname as table_name,
  relrowsecurity as rls_enabled
FROM pg_class
WHERE relname = 'objects' 
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage');

-- Step 5: Verify no policies exist
SELECT 
  'Storage Policies Count' as info,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Step 6: Verify buckets
SELECT 'Buckets' as info, id, name, public FROM storage.buckets ORDER BY name;
