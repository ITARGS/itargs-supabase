-- Add missing payment_fee column to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_fee numeric DEFAULT 0;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
