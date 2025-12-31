-- Make type column nullable in payment_methods
ALTER TABLE public.payment_methods 
ALTER COLUMN type DROP NOT NULL;

-- Notify PostgREST
NOTIFY pgrst, 'reload schema';
