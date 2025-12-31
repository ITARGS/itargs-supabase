-- Add missing columns to bundles table
ALTER TABLE public.bundles 
ADD COLUMN IF NOT EXISTS is_featured boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS stock_quantity integer DEFAULT 0;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
