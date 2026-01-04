-- ============================================================================
-- FIX SITE CONTENT TABLES RLS POLICIES
-- ============================================================================
-- This script fixes the RLS policies for 8 tables that incorrectly reference
-- the non-existent 'user_roles' table. Updates them to use 'profiles.role'
--
-- Affected tables: nav_links, footer_links, social_links, hero_sections,
--                  trust_badges, about_content, use_cases, working_hours
-- ============================================================================

BEGIN;

-- 1. NAV_LINKS
DROP POLICY IF EXISTS "Admins can manage nav links" ON public.nav_links;
CREATE POLICY "admin_full_access_nav_links" ON public.nav_links FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.nav_links TO authenticated;

-- 2. FOOTER_LINKS
DROP POLICY IF EXISTS "Admins can manage footer links" ON public.footer_links;
CREATE POLICY "admin_full_access_footer_links" ON public.footer_links FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.footer_links TO authenticated;

-- 3. SOCIAL_LINKS
DROP POLICY IF EXISTS "Admins can manage social links" ON public.social_links;
CREATE POLICY "admin_full_access_social_links" ON public.social_links FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.social_links TO authenticated;

-- 4. HERO_SECTIONS
DROP POLICY IF EXISTS "Admins can manage hero sections" ON public.hero_sections;
CREATE POLICY "admin_full_access_hero_sections" ON public.hero_sections FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.hero_sections TO authenticated;

-- 5. TRUST_BADGES
DROP POLICY IF EXISTS "Admins can manage trust badges" ON public.trust_badges;
CREATE POLICY "admin_full_access_trust_badges" ON public.trust_badges FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.trust_badges TO authenticated;

-- 6. ABOUT_CONTENT
DROP POLICY IF EXISTS "Admins can manage about content" ON public.about_content;
CREATE POLICY "admin_full_access_about_content" ON public.about_content FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.about_content TO authenticated;

-- 7. USE_CASES
DROP POLICY IF EXISTS "Admins can manage use cases" ON public.use_cases;
CREATE POLICY "admin_full_access_use_cases" ON public.use_cases FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.use_cases TO authenticated;

-- 8. WORKING_HOURS
DROP POLICY IF EXISTS "Admins can manage working hours" ON public.working_hours;
CREATE POLICY "admin_full_access_working_hours" ON public.working_hours FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
GRANT ALL ON public.working_hours TO authenticated;

COMMIT;

-- Verification
SELECT '✅ Fixed: ' || tablename as status, policyname
FROM pg_policies
WHERE tablename IN ('nav_links', 'footer_links', 'social_links', 'hero_sections', 'trust_badges', 'about_content', 'use_cases', 'working_hours')
AND policyname LIKE 'admin_full_access%'
ORDER BY tablename;
