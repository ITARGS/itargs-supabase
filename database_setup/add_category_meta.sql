-- Add meta columns to categories table
ALTER TABLE public.categories 
ADD COLUMN IF NOT EXISTS meta_title TEXT,
ADD COLUMN IF NOT EXISTS meta_description TEXT;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
