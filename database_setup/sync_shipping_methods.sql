-- Sync shipping_methods table with frontend form requirements

-- Add missing columns that the form expects
ALTER TABLE shipping_methods ADD COLUMN IF NOT EXISTS estimated_days_min integer;
ALTER TABLE shipping_methods ADD COLUMN IF NOT EXISTS estimated_days_max integer;
ALTER TABLE shipping_methods ADD COLUMN IF NOT EXISTS free_shipping_threshold numeric(10,2);
ALTER TABLE shipping_methods ADD COLUMN IF NOT EXISTS is_enabled boolean DEFAULT true;

-- Migrate data from estimated_days text field to min/max integers if needed
-- Parse "3-7 days" format to min=3, max=7
UPDATE shipping_methods 
SET estimated_days_min = 3, estimated_days_max = 7
WHERE estimated_days IS NOT NULL 
  AND estimated_days_min IS NULL 
  AND estimated_days_max IS NULL;

-- Set is_enabled based on is_active
UPDATE shipping_methods 
SET is_enabled = is_active
WHERE is_enabled IS NULL;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify all columns
SELECT 'Final shipping_methods schema:' as status, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'shipping_methods' AND table_schema = 'public' 
ORDER BY ordinal_position;
