-- Comprehensive RLS Fix for Customer-Facing Tables
-- Execute this via Supabase Dashboard SQL Editor

-- 1. Performance Tiers Table
ALTER TABLE IF EXISTS performance_tiers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to active performance tiers" ON performance_tiers;
CREATE POLICY "Allow public read access to active performance tiers"
ON performance_tiers FOR SELECT
TO anon, authenticated
USING (is_active = true);

GRANT SELECT ON performance_tiers TO anon, authenticated;

-- 2. Age Ranges Table
ALTER TABLE IF EXISTS age_ranges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to active age ranges" ON age_ranges;
CREATE POLICY "Allow public read access to active age ranges"
ON age_ranges FOR SELECT
TO anon, authenticated
USING (is_active = true);

GRANT SELECT ON age_ranges TO anon, authenticated;

-- 3. Subjects Table
ALTER TABLE IF EXISTS subjects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to active subjects" ON subjects;
CREATE POLICY "Allow public read access to active subjects"
ON subjects FOR SELECT
TO anon, authenticated
USING (is_active = true);

GRANT SELECT ON subjects TO anon, authenticated;

-- 4. Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('performance_tiers', 'age_ranges', 'subjects')
ORDER BY tablename, policyname;
