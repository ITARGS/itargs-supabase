-- Create about_page_settings table for page-level metadata
CREATE TABLE IF NOT EXISTS about_page_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  badge_text TEXT DEFAULT 'Corporate Identity',
  badge_text_ar TEXT DEFAULT 'هوية الشركة',
  main_title TEXT DEFAULT 'Who We Are',
  main_title_ar TEXT DEFAULT 'من نحن',
  subtitle TEXT DEFAULT 'Pioneering high-performance computing solutions. Engineered for professionals, gamers, and creators who demand excellence.',
  subtitle_ar TEXT DEFAULT 'نحن نبني مستقبل الحوسبة عالية الأداء. أنظمة مصممة للمحترفين، الجيمرز، والمبدعين.',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE about_page_settings ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT ON about_page_settings TO anon;
GRANT SELECT ON about_page_settings TO authenticated;
GRANT ALL ON about_page_settings TO authenticated;

-- RLS Policies
CREATE POLICY "Public can view about page settings"
  ON about_page_settings FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Authenticated users can manage about page settings"
  ON about_page_settings FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Insert default settings (single row)
INSERT INTO about_page_settings (badge_text, badge_text_ar, main_title, main_title_ar, subtitle, subtitle_ar)
VALUES (
  'Corporate Identity',
  'هوية الشركة',
  'Who We Are',
  'من نحن',
  'Pioneering high-performance computing solutions. Engineered for professionals, gamers, and creators who demand excellence.',
  'نحن نبني مستقبل الحوسبة عالية الأداء. أنظمة مصممة للمحترفين، الجيمرز، والمبدعين.'
);
