-- Add code column to shipping_methods table
ALTER TABLE public.shipping_methods 
ADD COLUMN IF NOT EXISTS code TEXT;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
