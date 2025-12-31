-- Add missing code column to shipping_methods table

ALTER TABLE shipping_methods ADD COLUMN IF NOT EXISTS code text UNIQUE;

-- Update existing records with generated codes if they don't have one
UPDATE shipping_methods 
SET code = LOWER(REPLACE(name, ' ', '_'))
WHERE code IS NULL;

-- Make code NOT NULL after populating
ALTER TABLE shipping_methods ALTER COLUMN code SET NOT NULL;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify column added
SELECT 'Shipping methods columns:' as check, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'shipping_methods' AND table_schema = 'public' 
ORDER BY ordinal_position;
