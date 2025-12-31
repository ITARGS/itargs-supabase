-- Add missing columns to products table for full e-commerce functionality

-- Add short_description columns (for product cards/listings)
ALTER TABLE products ADD COLUMN IF NOT EXISTS short_description text;
ALTER TABLE products ADD COLUMN IF NOT EXISTS short_description_ar text;

-- Add long_description columns (for product detail pages)
ALTER TABLE products ADD COLUMN IF NOT EXISTS long_description text;
ALTER TABLE products ADD COLUMN IF NOT EXISTS long_description_ar text;

-- Add cost_price for profit margin calculations
ALTER TABLE products ADD COLUMN IF NOT EXISTS cost_price numeric(10,2);

-- Add low_stock_threshold for inventory alerts
ALTER TABLE products ADD COLUMN IF NOT EXISTS low_stock_threshold integer DEFAULT 10;

-- Add track_inventory flag
ALTER TABLE products ADD COLUMN IF NOT EXISTS track_inventory boolean DEFAULT true;

-- Add physical dimensions
ALTER TABLE products ADD COLUMN IF NOT EXISTS weight numeric(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS width numeric(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS height numeric(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS depth numeric(10,2);

-- Add material and color for product attributes
ALTER TABLE products ADD COLUMN IF NOT EXISTS material text;
ALTER TABLE products ADD COLUMN IF NOT EXISTS color text;

-- Add tech-specific fields
ALTER TABLE products ADD COLUMN IF NOT EXISTS specifications jsonb;
ALTER TABLE products ADD COLUMN IF NOT EXISTS warranty_info text;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

COMMENT ON COLUMN products.short_description IS 'Brief product description for listings (max 500 chars)';
COMMENT ON COLUMN products.long_description IS 'Detailed product description for product pages';
COMMENT ON COLUMN products.specifications IS 'JSON array of tech specifications {key, value}';
COMMENT ON COLUMN products.warranty_info IS 'Warranty information and terms';
