-- Create nav_links table for dynamic navigation menu
-- Allows admins to manage shop navigation from admin panel

BEGIN;

CREATE TABLE IF NOT EXISTS public.nav_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    label text NOT NULL,
    label_ar text NOT NULL,
    url text NOT NULL,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.nav_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active nav links"
ON public.nav_links FOR SELECT TO public USING (is_active = true);

CREATE POLICY "Admins can manage nav links"
ON public.nav_links FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM user_roles WHERE user_roles.user_id = auth.uid() AND user_roles.role = 'admin'));

-- Add timestamp trigger
CREATE TRIGGER update_nav_links_updated_at BEFORE UPDATE ON public.nav_links FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default nav links
INSERT INTO public.nav_links (label, label_ar, url, display_order) VALUES
    ('Home', 'الرئيسية', '/', 1),
    ('Shop', 'المتجر', '/shop', 2),
    ('Categories', 'الأقسام', '/categories', 3),
    ('About', 'من نحن', '/about', 4),
    ('Contact', 'اتصل بنا', '/contact', 5)
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT ON nav_links TO anon, authenticated;

COMMIT;

-- Verify
SELECT 'nav_links table created' as status;
