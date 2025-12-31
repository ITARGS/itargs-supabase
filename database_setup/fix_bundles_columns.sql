-- Add missing columns to bundles and bundle_products tables

-- Add is_featured column to bundles table
ALTER TABLE bundles ADD COLUMN IF NOT EXISTS is_featured boolean DEFAULT false;

-- Add display_order column to bundle_products table
ALTER TABLE bundle_products ADD COLUMN IF NOT EXISTS display_order integer DEFAULT 0;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify columns added
SELECT 'Bundles columns:' as check, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'bundles' AND table_schema = 'public' 
AND column_name IN ('is_featured', 'is_active', 'discount_type')
ORDER BY column_name;

SELECT 'Bundle products columns:' as check, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'bundle_products' AND table_schema = 'public' 
AND column_name IN ('display_order', 'quantity')
ORDER BY column_name;
