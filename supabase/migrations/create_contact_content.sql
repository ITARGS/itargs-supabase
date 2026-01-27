-- Create contact_content table (mirrors about_content structure)
CREATE TABLE IF NOT EXISTS contact_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key TEXT NOT NULL UNIQUE,
  title TEXT,
  title_ar TEXT,
  content TEXT,
  content_ar TEXT,
  icon TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE contact_content ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT ON contact_content TO anon;
GRANT SELECT ON contact_content TO authenticated;
GRANT ALL ON contact_content TO authenticated;

-- RLS Policies
CREATE POLICY "Public can view active contact content"
  ON contact_content FOR SELECT
  TO anon
  USING (is_active = true);

CREATE POLICY "Authenticated users can manage contact content"
  ON contact_content FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create indexes
CREATE INDEX idx_contact_content_active ON contact_content(is_active) WHERE is_active = true;
CREATE INDEX idx_contact_content_order ON contact_content(display_order);

-- Insert initial contact sections
INSERT INTO contact_content (section_key, title, title_ar, content, content_ar, icon, display_order, is_active) VALUES
('hero', 'Get in Touch', 'تواصل معنا', 
 'We''d love to hear from you! Whether you have a question about our products, need assistance, or just want to provide feedback, our team is ready to help.',
 'نحن نحب أن نسمع منك! سواء كان لديك سؤال حول منتجاتنا، أو تحتاج إلى مساعدة، أو ترغب فقط في تقديم ملاحظات، فريقنا جاهز للمساعدة.',
 'MessageCircle', 0, true),

('contact_info', 'Contact Information', 'معلومات الاتصال',
 'Email: info@benchmark-elnajar.com
Phone: +20 123 456 7890
Address: Cairo, Egypt',
 'البريد الإلكتروني: info@benchmark-elnajar.com
الهاتف: +20 123 456 7890
العنوان: القاهرة، مصر',
 'Phone', 1, true),

('business_hours', 'Business Hours', 'ساعات العمل',
 'Sunday - Thursday: 9:00 AM - 6:00 PM
Friday - Saturday: Closed

WhatsApp support available 24/7',
 'الأحد - الخميس: 9:00 صباحاً - 6:00 مساءً
الجمعة - السبت: مغلق

دعم WhatsApp متاح على مدار الساعة',
 'Clock', 2, true);
