-- Complete payment_methods table sync with all missing columns

-- Add all missing columns that the admin form and checkout expect
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS api_key text;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS api_secret text;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS webhook_url text;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS test_mode boolean DEFAULT true;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS icon_url text;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify final schema
SELECT 'Complete payment_methods schema:' as status, 
       column_name, 
       data_type, 
       is_nullable,
       column_default
FROM information_schema.columns 
WHERE table_name = 'payment_methods' AND table_schema = 'public' 
ORDER BY ordinal_position;
