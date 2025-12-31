-- Fix RLS policies for customer-facing tables
-- This allows public read access to tables needed for the storefront

-- Performance Tiers Table
DROP POLICY IF EXISTS "Allow public read access to active performance tiers" ON performance_tiers;
CREATE POLICY "Allow public read access to active performance tiers"
ON performance_tiers FOR SELECT
TO anon, authenticated
USING (is_active = true);

-- Age Ranges Table (if exists)
DROP POLICY IF EXISTS "Allow public read access to active age ranges" ON age_ranges;
CREATE POLICY "Allow public read access to active age ranges"
ON age_ranges FOR SELECT
TO anon, authenticated
USING (is_active = true);

-- Subjects Table (if exists)
DROP POLICY IF EXISTS "Allow public read access to active subjects" ON subjects;
CREATE POLICY "Allow public read access to active subjects"
ON subjects FOR SELECT
TO anon, authenticated
USING (is_active = true);

-- Ensure RLS is enabled on these tables
ALTER TABLE performance_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE age_ranges ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

-- Grant SELECT permissions to anon and authenticated roles
GRANT SELECT ON performance_tiers TO anon, authenticated;
GRANT SELECT ON age_ranges TO anon, authenticated;
GRANT SELECT ON subjects TO anon, authenticated;
