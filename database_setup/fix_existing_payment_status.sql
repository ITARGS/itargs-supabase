-- Update existing cancelled orders to have correct payment status
-- This applies the business logic retroactively to existing data

UPDATE orders
SET payment_status = 'failed'
WHERE status = 'cancelled' 
  AND payment_status = 'pending';

UPDATE orders
SET payment_status = 'refunded'
WHERE status = 'cancelled' 
  AND payment_status = 'paid';

-- Update confirmed/processing/shipped/delivered orders with pending payment to paid
UPDATE orders
SET payment_status = 'paid'
WHERE status IN ('confirmed', 'processing', 'shipped', 'delivered')
  AND payment_status = 'pending';

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
