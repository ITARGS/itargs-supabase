-- Database Migration: Synchronize Cart and Variants Schema

-- 1. Update cart_items table: Rename variant_id to product_variant_id
ALTER TABLE IF EXISTS cart_items RENAME COLUMN variant_id TO product_variant_id;

-- 2. Update order_items table: Add missing variant tracking columns
ALTER TABLE IF EXISTS order_items ADD COLUMN IF NOT EXISTS product_variant_id uuid REFERENCES product_variants(id);
ALTER TABLE IF EXISTS order_items ADD COLUMN IF NOT EXISTS product_sku text;

-- 3. Ensure foreign key in cart_items points to product_variants correctly 
-- (Renaming the column usually preserves the constraint, but let's be explicit if needed)
-- Check if constraint exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cart_items_variant_id_fkey') THEN
        ALTER TABLE cart_items 
        ADD CONSTRAINT cart_items_variant_id_fkey 
        FOREIGN KEY (product_variant_id) REFERENCES product_variants(id);
    END IF;
END $$;

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
