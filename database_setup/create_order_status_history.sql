-- Create order_status_history table for tracking order status changes

CREATE TABLE IF NOT EXISTS order_status_history (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status text NOT NULL,
    notes text,
    created_by uuid REFERENCES auth.users(id),
    created_at timestamptz DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_created_at ON order_status_history(created_at DESC);

-- Enable RLS
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Admin can view all status history
CREATE POLICY "Admin can view all order status history"
    ON order_status_history FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_roles.user_id = auth.uid()
            AND user_roles.role = 'admin'
        )
    );

-- Admin can insert status history
CREATE POLICY "Admin can insert order status history"
    ON order_status_history FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_roles.user_id = auth.uid()
            AND user_roles.role = 'admin'
        )
    );

-- Users can view their own order status history
CREATE POLICY "Users can view own order status history"
    ON order_status_history FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_status_history.order_id
            AND orders.user_id = auth.uid()
        )
    );

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify table created
SELECT 'Order status history table created:' as status, 
       column_name, 
       data_type,
       is_nullable
FROM information_schema.columns 
WHERE table_name = 'order_status_history' AND table_schema = 'public' 
ORDER BY ordinal_position;
