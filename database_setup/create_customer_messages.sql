-- Create customer_messages table for contact form submissions

CREATE TABLE IF NOT EXISTS public.customer_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    email text NOT NULL,
    phone text,
    subject text,
    message text NOT NULL,
    status text DEFAULT 'new' CHECK (status IN ('new', 'read', 'replied', 'archived')),
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add timestamp trigger
CREATE TRIGGER update_customer_messages_updated_at
    BEFORE UPDATE ON public.customer_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE public.customer_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Allow anyone to insert (for contact form)
CREATE POLICY "Anyone can submit messages"
ON public.customer_messages FOR INSERT
TO public, anon, authenticated
WITH CHECK (true);

-- Users can view their own messages
CREATE POLICY "Users can view own messages"
ON public.customer_messages FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Admins can view all messages
CREATE POLICY "Admins can view all messages"
ON public.customer_messages FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Admins can update messages (change status, etc.)
CREATE POLICY "Admins can update messages"
ON public.customer_messages FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Admins can delete messages
CREATE POLICY "Admins can delete messages"
ON public.customer_messages FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Grant permissions
GRANT SELECT, INSERT ON customer_messages TO anon, authenticated;
GRANT UPDATE, DELETE ON customer_messages TO authenticated;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_customer_messages_status ON customer_messages(status);
CREATE INDEX IF NOT EXISTS idx_customer_messages_created_at ON customer_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_messages_user_id ON customer_messages(user_id);

-- Reload PostgREST
NOTIFY pgrst, 'reload schema';

COMMENT ON TABLE customer_messages IS 'Stores customer contact form submissions and messages';
