-- Create newsletter_subscribers table
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    subscribed_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_newsletter_email ON newsletter_subscribers(email);

-- Add RLS policies
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Allow anyone to subscribe (insert)
CREATE POLICY "Anyone can subscribe to newsletter"
    ON newsletter_subscribers
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Only authenticated users can view subscribers (admin only)
CREATE POLICY "Only authenticated users can view subscribers"
    ON newsletter_subscribers
    FOR SELECT
    TO authenticated
    USING (true);

-- Only authenticated users can update/delete (admin only)
CREATE POLICY "Only authenticated users can manage subscribers"
    ON newsletter_subscribers
    FOR ALL
    TO authenticated
    USING (true);
