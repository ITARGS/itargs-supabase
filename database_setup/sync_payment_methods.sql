-- Sync payment_methods table with frontend form requirements

-- Add missing columns that the form expects
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS code text UNIQUE;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS additional_fee numeric(10,2) DEFAULT 0;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS additional_fee_type text DEFAULT 'fixed';
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS min_amount numeric(10,2);
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS max_amount numeric(10,2);
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS supported_currencies text[];
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS requires_billing_address boolean DEFAULT false;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS requires_phone boolean DEFAULT false;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS payment_instructions text;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS payment_instructions_ar text;
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS is_enabled boolean DEFAULT true;

-- Generate codes for existing records if they don't have one
UPDATE payment_methods 
SET code = LOWER(REPLACE(name, ' ', '_'))
WHERE code IS NULL;

-- Make code NOT NULL after populating
ALTER TABLE payment_methods ALTER COLUMN code SET NOT NULL;

-- Set is_enabled based on is_active for existing records
UPDATE payment_methods 
SET is_enabled = is_active
WHERE is_enabled IS NULL;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify all columns
SELECT 'Final payment_methods schema:' as status, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'payment_methods' AND table_schema = 'public' 
ORDER BY ordinal_position;
