-- Add missing columns to shipping_methods table
ALTER TABLE public.shipping_methods 
ADD COLUMN IF NOT EXISTS free_shipping_threshold NUMERIC,
ADD COLUMN IF NOT EXISTS estimated_days_min INTEGER,
ADD COLUMN IF NOT EXISTS estimated_days_max INTEGER,
ADD COLUMN IF NOT EXISTS is_enabled BOOLEAN DEFAULT true;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
