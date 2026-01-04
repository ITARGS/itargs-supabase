-- Remove the final 8 role-checking policies

DROP POLICY IF EXISTS "Admins can manage product variants" ON public.product_variants;
DROP POLICY IF EXISTS "Admins can view all preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Admins can manage performance tiers" ON public.performance_tiers;
DROP POLICY IF EXISTS "Admins can manage product performance tiers" ON public.product_performance_tiers;
DROP POLICY IF EXISTS "Admins can delete messages" ON public.customer_messages;
DROP POLICY IF EXISTS "Admins manage workload types" ON public.workload_types;
DROP POLICY IF EXISTS "Admins can manage bundles" ON public.bundles;
DROP POLICY IF EXISTS "Admins can manage testimonials" ON public.testimonials;

SELECT 'ALL ROLE POLICIES REMOVED' as status;

-- Final verification
SELECT COUNT(*) as remaining_role_policies
FROM pg_policies
WHERE schemaname = 'public'
AND qual LIKE '%role%';
