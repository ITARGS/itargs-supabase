-- Migration to fix orders table schema and add missing foreign keys/columns
DO $$ 
BEGIN
    -- Add payment_method_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'payment_method_id') THEN
        ALTER TABLE public.orders ADD COLUMN payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL;
    END IF;

    -- Add shipping_method_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_method_id') THEN
        ALTER TABLE public.orders ADD COLUMN shipping_method_id UUID REFERENCES public.shipping_methods(id) ON DELETE SET NULL;
    END IF;

    -- Add tax_amount if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'tax_amount') THEN
        ALTER TABLE public.orders ADD COLUMN tax_amount DECIMAL(10,2) DEFAULT 0;
    END IF;

    -- Add payment_fee if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'payment_fee') THEN
        ALTER TABLE public.orders ADD COLUMN payment_fee DECIMAL(10,2) DEFAULT 0;
    END IF;

    -- Add customer_email if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'customer_email') THEN
        ALTER TABLE public.orders ADD COLUMN customer_email TEXT;
    END IF;

    -- Add customer_phone if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'customer_phone') THEN
        ALTER TABLE public.orders ADD COLUMN customer_phone TEXT;
    END IF;

    -- Ensure total_amount column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'total_amount') THEN
        ALTER TABLE public.orders ADD COLUMN total_amount DECIMAL(10,2) DEFAULT 0;
    END IF;
END $$;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
