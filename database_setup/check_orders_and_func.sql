-- Check orders table columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders';

-- Check for delete_user_as_admin function (corrected)
SELECT proname
FROM pg_catalog.pg_proc
JOIN pg_catalog.pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
WHERE pg_namespace.nspname = 'public' AND proname = 'delete_user_as_admin';
