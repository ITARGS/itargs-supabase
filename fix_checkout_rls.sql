-- FIX CHECKOUT PERMISSIONS (RLS)

-- 1. Allow customers to insert items into their own orders
DROP POLICY IF EXISTS "Customers can insert order items" ON public.order_items;
CREATE POLICY "Customers can insert order items" 
ON public.order_items FOR INSERT 
TO authenticated 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.orders 
        WHERE id = order_items.order_id 
        AND user_id = auth.uid()
    )
);

-- 2. Allow customers to insert initial status history
DROP POLICY IF EXISTS "Customers can insert order status history" ON public.order_status_history;
CREATE POLICY "Customers can insert order status history" 
ON public.order_status_history FOR INSERT 
TO authenticated 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.orders 
        WHERE id = order_status_history.order_id 
        AND user_id = auth.uid()
    )
);

-- Ensure RLS is enabled (it should be already, but for safety)
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
