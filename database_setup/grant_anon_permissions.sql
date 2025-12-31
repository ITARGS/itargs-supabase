-- Grant SELECT permissions to anon and authenticated roles on new tech tables

-- Grant on performance_tiers
GRANT SELECT ON performance_tiers TO anon, authenticated;

-- Grant on workload_types
GRANT SELECT ON workload_types TO anon, authenticated;

-- Grant on product_performance_tiers
GRANT SELECT ON product_performance_tiers TO anon, authenticated;

-- Grant on product_workloads
GRANT SELECT ON product_workloads TO anon, authenticated;

-- Grant on tech_specs
GRANT SELECT ON tech_specs TO anon, authenticated;

-- Grant on tech_resources (only published ones via RLS)
GRANT SELECT ON tech_resources TO anon, authenticated;

-- Reload PostgREST
NOTIFY pgrst, 'reload schema';
