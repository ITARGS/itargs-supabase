-- Complete discount_codes table sync with frontend form

-- Add all missing columns that the form expects
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS min_order_amount numeric(10,2);
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS max_discount_amount numeric(10,2);
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS allowed_products text[];
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS allowed_categories text[];
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS excluded_products text[];
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS excluded_categories text[];
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS first_order_only boolean DEFAULT false;
ALTER TABLE discount_codes ADD COLUMN IF NOT EXISTS one_per_customer boolean DEFAULT false;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify final schema
SELECT 'Complete discount_codes schema:' as status, 
       column_name, 
       data_type, 
       is_nullable
FROM information_schema.columns 
WHERE table_name = 'discount_codes' AND table_schema = 'public' 
ORDER BY ordinal_position;
