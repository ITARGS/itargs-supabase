-- Add display_order column to bundle_products
ALTER TABLE public.bundle_products 
ADD COLUMN IF NOT EXISTS display_order integer DEFAULT 0;

-- Notify PostgREST
NOTIFY pgrst, 'reload schema';
