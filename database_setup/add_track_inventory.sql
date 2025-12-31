ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS track_inventory BOOLEAN DEFAULT true;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
