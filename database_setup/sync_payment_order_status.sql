-- Enhanced trigger to synchronize payment status with order status
-- This ensures payment and order states are always in sync

CREATE OR REPLACE FUNCTION sync_payment_and_order_status()
RETURNS TRIGGER AS $$
BEGIN
    -- When order status changes, update payment status accordingly
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        -- Log to status history
        INSERT INTO order_status_history (order_id, status, notes, created_by)
        VALUES (NEW.id, NEW.status, 'Status updated automatically', auth.uid());

        -- Update timestamp fields
        NEW.updated_at = now();

        CASE NEW.status
            WHEN 'confirmed' THEN 
                NEW.confirmed_at = now();
                -- If order is confirmed and payment was pending, mark as paid
                IF NEW.payment_status = 'pending' THEN
                    NEW.payment_status = 'paid';
                END IF;
            WHEN 'processing' THEN
                -- Processing implies payment was successful
                IF NEW.payment_status = 'pending' THEN
                    NEW.payment_status = 'paid';
                END IF;
            WHEN 'shipped' THEN 
                NEW.shipped_at = now();
                -- Shipped orders must have been paid
                IF NEW.payment_status = 'pending' THEN
                    NEW.payment_status = 'paid';
                END IF;
            WHEN 'delivered' THEN 
                NEW.delivered_at = now();
                -- Delivered orders must have been paid
                IF NEW.payment_status = 'pending' THEN
                    NEW.payment_status = 'paid';
                END IF;
            WHEN 'cancelled' THEN 
                NEW.cancelled_at = now();
                -- Automated payment status update on cancellation
                IF NEW.payment_status = 'pending' THEN
                    NEW.payment_status = 'failed';
                ELSIF NEW.payment_status = 'paid' THEN
                    NEW.payment_status = 'refunded';
                END IF;
            ELSE NULL;
        END CASE;
    END IF;

    -- When payment status changes to 'paid', auto-confirm the order if it's still pending
    IF NEW.payment_status IS DISTINCT FROM OLD.payment_status THEN
        IF NEW.payment_status = 'paid' AND NEW.status = 'pending' THEN
            NEW.status = 'confirmed';
            NEW.confirmed_at = now();
            -- Log the auto-confirmation
            INSERT INTO order_status_history (order_id, status, notes, created_by)
            VALUES (NEW.id, 'confirmed', 'Auto-confirmed after payment', auth.uid());
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the old trigger if it exists
DROP TRIGGER IF EXISTS order_status_change_trigger ON orders;

-- Create the new trigger
CREATE TRIGGER order_status_change_trigger
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION sync_payment_and_order_status();

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
