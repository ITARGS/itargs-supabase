-- Create contact_page_settings table for page-level metadata
CREATE TABLE IF NOT EXISTS contact_page_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  badge_text TEXT DEFAULT 'Live Support Available',
  badge_text_ar TEXT DEFAULT 'الدعم المباشر متاح',
  main_title TEXT DEFAULT 'Contact Us',
  main_title_ar TEXT DEFAULT 'اتصل بنا',
  subtitle TEXT DEFAULT 'We''re here to help! Reach out to us in any way that suits you.',
  subtitle_ar TEXT DEFAULT 'نحن هنا للمساعدة! تواصل معنا بأي طريقة تناسبك.',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE contact_page_settings ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT ON contact_page_settings TO anon;
GRANT SELECT ON contact_page_settings TO authenticated;
GRANT ALL ON contact_page_settings TO authenticated;

-- RLS Policies
CREATE POLICY "Public can view contact page settings"
  ON contact_page_settings FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Authenticated users can manage contact page settings"
  ON contact_page_settings FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Insert default settings (single row)
INSERT INTO contact_page_settings (badge_text, badge_text_ar, main_title, main_title_ar, subtitle, subtitle_ar)
VALUES (
  'Live Support Available',
  'الدعم المباشر متاح',
  'Contact Us',
  'اتصل بنا',
  'We''re here to help! Reach out to us in any way that suits you.',
  'نحن هنا للمساعدة! تواصل معنا بأي طريقة تناسبك.'
);
