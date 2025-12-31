-- Phase 1: Complete Orders Table Enhancement
-- Add all missing columns for comprehensive order management

-- Customer Information
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_email text;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_phone text;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name text;

-- Shipping Details
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_method_id uuid REFERENCES shipping_methods(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_delivery_date date;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS actual_delivery_date date;

-- Payment Details
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method_id uuid REFERENCES payment_methods(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_transaction_id text;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_gateway text;

-- Order Management
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_code_id uuid REFERENCES discount_codes(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tax_amount numeric(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS currency text DEFAULT 'EGP';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_source text DEFAULT 'web';

-- Timestamps for order lifecycle
ALTER TABLE orders ADD COLUMN IF NOT EXISTS confirmed_at timestamptz;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipped_at timestamptz;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at timestamptz;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_customer_email ON orders(customer_email);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);

-- Status validation function
CREATE OR REPLACE FUNCTION validate_order_status_transition(
    old_status text,
    new_status text
) RETURNS boolean AS $$
BEGIN
    -- Allow any status change from pending
    IF old_status = 'pending' THEN
        RETURN true;
    END IF;
    
    -- Define valid transitions
    RETURN CASE
        WHEN old_status = 'confirmed' AND new_status IN ('processing', 'cancelled') THEN true
        WHEN old_status = 'processing' AND new_status IN ('shipped', 'cancelled') THEN true
        WHEN old_status = 'shipped' AND new_status IN ('delivered', 'cancelled') THEN true
        WHEN old_status = 'delivered' AND new_status = 'refunded' THEN true
        ELSE false
    END;
END;
$$ LANGUAGE plpgsql;

-- Status change trigger with automatic logging
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        -- Log to status history
        INSERT INTO order_status_history (order_id, status, notes, created_by)
        VALUES (NEW.id, NEW.status, 'Status updated automatically', auth.uid());
        
        -- Update timestamp fields
        NEW.updated_at = now();
        
        CASE NEW.status
            WHEN 'confirmed' THEN NEW.confirmed_at = now();
            WHEN 'shipped' THEN NEW.shipped_at = now();
            WHEN 'delivered' THEN NEW.delivered_at = now();
            WHEN 'cancelled' THEN NEW.cancelled_at = now();
            ELSE NULL;
        END CASE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF NOT EXISTS order_status_change_trigger ON orders;
CREATE TRIGGER order_status_change_trigger
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify all columns added
SELECT 'Enhanced orders table:' as status, 
       column_name, 
       data_type,
       is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' AND table_schema = 'public' 
ORDER BY ordinal_position;
