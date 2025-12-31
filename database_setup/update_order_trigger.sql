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

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
