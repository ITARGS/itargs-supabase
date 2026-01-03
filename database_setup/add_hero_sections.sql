-- Create hero_sections table for dynamic homepage hero content
-- Allows admins to manage hero section from admin panel

BEGIN;

CREATE TABLE IF NOT EXISTS public.hero_sections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    title_ar text NOT NULL,
    subtitle text,
    subtitle_ar text,
    cta_primary_text text,
    cta_primary_text_ar text,
    cta_primary_link text,
    cta_secondary_text text,
    cta_secondary_text_ar text,
    cta_secondary_link text,
    background_image text,
    background_video text,
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.hero_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active hero sections"
ON public.hero_sections FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "Admins can manage hero sections"
ON public.hero_sections FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Add timestamp trigger
CREATE TRIGGER update_hero_sections_updated_at
    BEFORE UPDATE ON public.hero_sections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_hero_sections_active_order 
ON public.hero_sections(is_active, display_order);

-- Insert default hero section
INSERT INTO public.hero_sections (
    title, 
    title_ar, 
    subtitle, 
    subtitle_ar, 
    cta_primary_text, 
    cta_primary_text_ar, 
    cta_primary_link,
    cta_secondary_text,
    cta_secondary_text_ar,
    cta_secondary_link,
    display_order
) VALUES (
    'Professional Hardware Solutions',
    'حلول الأجهزة الاحترافية',
    'Premium components for AI, rendering, and high-performance computing',
    'مكونات متميزة للذكاء الاصطناعي والتصيير والحوسبة عالية الأداء',
    'Explore Products',
    'استكشف المنتجات',
    '/shop',
    'Learn More',
    'اعرف المزيد',
    '/about',
    1
) ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT ON hero_sections TO anon, authenticated;

COMMIT;

-- Verify table created
SELECT 'hero_sections table created' as status, COUNT(*) as row_count 
FROM hero_sections;
