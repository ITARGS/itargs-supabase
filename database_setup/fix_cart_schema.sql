-- Add product_variant_id column to cart_items table
ALTER TABLE public.cart_items 
ADD COLUMN IF NOT EXISTS product_variant_id UUID REFERENCES public.product_variants(id) ON DELETE SET NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_cart_items_product_variant_id ON public.cart_items(product_variant_id);

-- Verify column existence
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'cart_items' AND column_name = 'product_variant_id';
