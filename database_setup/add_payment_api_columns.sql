-- Add API configuration columns to payment_methods table
ALTER TABLE public.payment_methods 
ADD COLUMN IF NOT EXISTS api_key TEXT,
ADD COLUMN IF NOT EXISTS api_secret TEXT,
ADD COLUMN IF NOT EXISTS merchant_id TEXT,
ADD COLUMN IF NOT EXISTS webhook_secret TEXT,
ADD COLUMN IF NOT EXISTS sandbox_mode BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS icon TEXT;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
