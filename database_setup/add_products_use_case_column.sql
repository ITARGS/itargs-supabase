-- Add use_case column to products table
-- This links products to the use_cases filter

BEGIN;

-- Add use_case column to products table
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS use_case text;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_products_use_case ON products(use_case);

-- Add comment
COMMENT ON COLUMN products.use_case IS 'Product use case (gaming, workstation, office, server, content-creation, home)';

COMMIT;

-- Verify column added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'products' AND column_name = 'use_case';
