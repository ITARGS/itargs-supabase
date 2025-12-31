-- Add Specifications and Warranty columns to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS specifications JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS warranty_info TEXT;

-- Index for valid searching if needed later (GIN index on jsonb)
CREATE INDEX IF NOT EXISTS idx_products_specifications ON public.products USING GIN (specifications);
