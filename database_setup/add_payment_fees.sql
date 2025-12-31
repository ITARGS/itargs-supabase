-- Add fee columns to payment_methods table
ALTER TABLE public.payment_methods 
ADD COLUMN IF NOT EXISTS additional_fee_type TEXT CHECK (additional_fee_type IN ('fixed', 'percentage')),
ADD COLUMN IF NOT EXISTS additional_fee_amount NUMERIC DEFAULT 0;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
