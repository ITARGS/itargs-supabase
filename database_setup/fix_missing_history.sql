
-- ============================================
-- FIX: RESTORE ORDER STATUS HISTORY
-- ============================================
-- This script restores the order_status_history table and helper function
-- which were inadvertently omitted in the recent schema rebuild.

-- 1. Create order_status_history table
CREATE TABLE IF NOT EXISTS public.order_status_history (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    status TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    changed_by UUID,
    CONSTRAINT order_status_history_pkey PRIMARY KEY (id),
    CONSTRAINT order_status_history_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE
);

-- 2. Create Index
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON public.order_status_history(order_id);

-- 3. Enable RLS
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

-- 4. Create Policies
-- Allow Read access for all (auth and anon if needed)
CREATE POLICY "Enable read access for all" ON public.order_status_history FOR SELECT USING (true);

-- Allow Insert for authenticated users (admins/system)
CREATE POLICY "Enable insert for authenticated users" ON public.order_status_history FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 5. Create Helper Function
CREATE OR REPLACE FUNCTION public.append_order_history_safe(p_order_id UUID, p_status TEXT, p_notes TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.order_status_history (order_id, status, notes, changed_by)
    VALUES (p_order_id, p_status, p_notes, auth.uid());
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Failed to append order history: %', SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION public.append_order_history_safe TO authenticated;
