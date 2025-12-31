-- Rename amount to value to match frontend
ALTER TABLE public.payment_methods 
RENAME COLUMN additional_fee_amount TO additional_fee_value;

-- Add remaining missing columns
ALTER TABLE public.payment_methods 
ADD COLUMN IF NOT EXISTS code TEXT,
ADD COLUMN IF NOT EXISTS min_order_amount NUMERIC,
ADD COLUMN IF NOT EXISTS max_order_amount NUMERIC;

-- Notify PostgREST
NOTIFY pgrst, 'reload schema';
