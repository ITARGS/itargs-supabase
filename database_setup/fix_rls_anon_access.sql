-- Fix RLS policies for new tech tables to allow anonymous access

-- Fix performance_tiers policy
DROP POLICY IF EXISTS "Public can view active performance tiers" ON performance_tiers;
CREATE POLICY "Public can view active performance tiers" 
ON performance_tiers FOR SELECT 
TO public, anon 
USING (is_active = true);

-- Fix workload_types policy  
DROP POLICY IF EXISTS "Public can view active workload types" ON workload_types;
CREATE POLICY "Public can view active workload types" 
ON workload_types FOR SELECT 
TO public, anon 
USING (is_active = true);

-- Reload PostgREST cache
NOTIFY pgrst, 'reload schema';
