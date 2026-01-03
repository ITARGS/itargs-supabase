-- Create footer_links and social_links tables for dynamic footer content
-- Allows admins to manage footer links and social media from admin panel

BEGIN;

-- Footer Links
CREATE TABLE IF NOT EXISTS public.footer_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    section text NOT NULL, -- 'company', 'support', 'legal', etc.
    label text NOT NULL,
    label_ar text NOT NULL,
    url text NOT NULL,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Social Links
CREATE TABLE IF NOT EXISTS public.social_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    platform text NOT NULL, -- 'facebook', 'twitter', 'linkedin', 'instagram', etc.
    url text NOT NULL,
    icon text, -- Icon name or emoji
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.footer_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active footer links"
ON public.footer_links FOR SELECT TO public USING (is_active = true);

CREATE POLICY "Admins can manage footer links"
ON public.footer_links FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM user_roles WHERE user_roles.user_id = auth.uid() AND user_roles.role = 'admin'));

CREATE POLICY "Public can view active social links"
ON public.social_links FOR SELECT TO public USING (is_active = true);

CREATE POLICY "Admins can manage social links"
ON public.social_links FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM user_roles WHERE user_roles.user_id = auth.uid() AND user_roles.role = 'admin'));

-- Add timestamp triggers
CREATE TRIGGER update_footer_links_updated_at BEFORE UPDATE ON public.footer_links FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_social_links_updated_at BEFORE UPDATE ON public.social_links FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default footer links
INSERT INTO public.footer_links (section, label, label_ar, url, display_order) VALUES
    ('company', 'About Us', 'من نحن', '/about', 1),
    ('company', 'Contact', 'اتصل بنا', '/contact', 2),
    ('support', 'FAQs', 'الأسئلة الشائعة', '/faqs', 1),
    ('support', 'Tech Hub', 'المركز التقني', '/tech-hub', 2),
    ('legal', 'Privacy Policy', 'سياسة الخصوصية', '/privacy', 1),
    ('legal', 'Terms of Service', 'شروط الخدمة', '/terms', 2)
ON CONFLICT DO NOTHING;

-- Insert default social links
INSERT INTO public.social_links (platform, url, icon, display_order) VALUES
    ('facebook', 'https://facebook.com/elnajar', 'Facebook', 1),
    ('twitter', 'https://twitter.com/elnajar', 'Twitter', 2),
    ('linkedin', 'https://linkedin.com/company/elnajar', 'Linkedin', 3),
    ('instagram', 'https://instagram.com/elnajar', 'Instagram', 4)
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT ON footer_links TO anon, authenticated;
GRANT SELECT ON social_links TO anon, authenticated;

COMMIT;

-- Verify
SELECT 'footer and social tables created' as status;
