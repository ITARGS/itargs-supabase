-- Migration to synchronize order_items and orders schema with frontend types
DO $$ 
BEGIN
    -- order_items table updates
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'product_sku') THEN
        ALTER TABLE public.order_items ADD COLUMN product_sku TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'product_variant_id') THEN
        ALTER TABLE public.order_items ADD COLUMN product_variant_id UUID REFERENCES public.product_variants(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'variant_name') THEN
        ALTER TABLE public.order_items ADD COLUMN variant_name TEXT;
    END IF;

    -- orders table updates (ensuring fields from previous fixes are robust)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'billing_address_id') THEN
        ALTER TABLE public.orders ADD COLUMN billing_address_id UUID REFERENCES public.addresses(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'discount_code') THEN
        ALTER TABLE public.orders ADD COLUMN discount_code TEXT;
    END IF;

    -- Extra safety for previously added columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'customer_email') THEN
        ALTER TABLE public.orders ADD COLUMN customer_email TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'customer_phone') THEN
        ALTER TABLE public.orders ADD COLUMN customer_phone TEXT;
    END IF;

END $$;

-- Update existing order_items to have empty sku if null (avoid further frontend issues)
UPDATE public.order_items SET product_sku = '' WHERE product_sku IS NULL;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
