-- Add short_description columns to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS short_description TEXT,
ADD COLUMN IF NOT EXISTS short_description_ar TEXT;

-- Verify description columns exist (usually do, but ensuring for mapping)
-- We strictly map 'long_description' in code to 'description' in DB.
