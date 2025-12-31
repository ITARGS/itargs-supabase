-- Rename min_purchase_amount to min_order_amount to match frontend
ALTER TABLE public.discount_codes 
RENAME COLUMN min_purchase_amount TO min_order_amount;

-- Notify PostgREST
NOTIFY pgrst, 'reload schema';
