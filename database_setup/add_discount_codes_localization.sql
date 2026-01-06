-- Add Arabic description field to discount_codes table for localization support
-- This allows storing discount code descriptions in Arabic

ALTER TABLE discount_codes 
ADD COLUMN IF NOT EXISTS description_ar TEXT;

COMMENT ON COLUMN discount_codes.description_ar IS 'Arabic description for the discount code';

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'discount_codes' AND column_name = 'description_ar';
