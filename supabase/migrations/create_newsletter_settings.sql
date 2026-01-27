-- Create newsletter_settings table
CREATE TABLE IF NOT EXISTS newsletter_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL DEFAULT 'Stay Updated',
    title_ar TEXT NOT NULL DEFAULT 'ابق على اطلاع',
    description TEXT NOT NULL DEFAULT 'Subscribe to our newsletter for the latest updates and exclusive offers.',
    description_ar TEXT NOT NULL DEFAULT 'اشترك في نشرتنا الإخبارية للحصول على آخر التحديثات والعروض الحصرية.',
    placeholder_text TEXT NOT NULL DEFAULT 'Enter your email',
    placeholder_text_ar TEXT NOT NULL DEFAULT 'أدخل بريدك الإلكتروني',
    button_text TEXT NOT NULL DEFAULT 'Subscribe',
    button_text_ar TEXT NOT NULL DEFAULT 'اشترك',
    success_message TEXT NOT NULL DEFAULT 'Thank you for subscribing!',
    success_message_ar TEXT NOT NULL DEFAULT 'شكراً لاشتراكك!',
    background_color TEXT NOT NULL DEFAULT '#f3f4f6',
    text_color TEXT NOT NULL DEFAULT '#1f2937',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add constraint to ensure only one settings record exists
CREATE UNIQUE INDEX IF NOT EXISTS idx_newsletter_settings_singleton ON newsletter_settings ((true));

-- Add trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_newsletter_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_newsletter_settings_updated_at
    BEFORE UPDATE ON newsletter_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_newsletter_settings_updated_at();

-- Enable RLS
ALTER TABLE newsletter_settings ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read newsletter settings (public access)
CREATE POLICY "Anyone can view newsletter settings"
    ON newsletter_settings
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Only authenticated users can insert/update/delete (admin only)
CREATE POLICY "Only authenticated users can manage newsletter settings"
    ON newsletter_settings
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Insert default settings record
INSERT INTO newsletter_settings (
    title,
    title_ar,
    description,
    description_ar,
    placeholder_text,
    placeholder_text_ar,
    button_text,
    button_text_ar,
    success_message,
    success_message_ar,
    background_color,
    text_color,
    is_active
) VALUES (
    'Stay Updated',
    'ابق على اطلاع',
    'Subscribe to our newsletter for the latest updates and exclusive offers.',
    'اشترك في نشرتنا الإخبارية للحصول على آخر التحديثات والعروض الحصرية.',
    'Enter your email',
    'أدخل بريدك الإلكتروني',
    'Subscribe',
    'اشترك',
    'Thank you for subscribing!',
    'شكراً لاشتراكك!',
    '#f3f4f6',
    '#1f2937',
    TRUE
)
ON CONFLICT DO NOTHING;
