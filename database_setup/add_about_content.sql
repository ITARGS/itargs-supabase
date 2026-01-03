-- Create about_content table for dynamic homepage about section
-- Allows admins to manage about section from admin panel

BEGIN;

CREATE TABLE IF NOT EXISTS public.about_content (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    section_key text UNIQUE NOT NULL, -- 'main', 'mission', 'directive_1', 'directive_2', 'directive_3', 'facility_1', 'facility_2', 'facility_3'
    title text,
    title_ar text,
    content text,
    content_ar text,
    icon text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.about_content ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active about content"
ON public.about_content FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "Admins can manage about content"
ON public.about_content FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Add timestamp trigger
CREATE TRIGGER update_about_content_updated_at
    BEFORE UPDATE ON public.about_content
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_about_content_active_order 
ON public.about_content(is_active, display_order);

-- Insert default about content
INSERT INTO public.about_content (section_key, title, title_ar, content, content_ar, icon, display_order) VALUES
    ('main', 'Technical Lab & Strategic Directive', 'المختبر الفني والتوجيه الاستراتيجي', 'BenchMark – Elnajar is not just a hardware vendor. We are a computational architecture firm dedicated to providing the raw power required for the next generation of digital innovation.', 'بنش مارك – النجار ليس مجرد بائع أجهزة. نحن شركة حوسبة معمارية مكرسة لتوفير القوة الخام المطلوبة للجيل القادم من الابتكار الرقمي.', 'Terminal', 0),
    ('mission', 'Soverign Objective', 'الهدف السيادي', 'To architect the most robust, high-availability workstation environments for specialized industrial and creative workloads.', 'بناء بيئات العمل الأكثر قوة وعالية التوفر لأعباء العمل الصناعية والإبداعية المتخصصة.', 'Target', 1),
    ('directive_1', 'Advanced Diagnostics', 'التشخيصات المتقدمة', 'Real-time telemetry and hardware monitoring systems.', 'أنظمة القياس عن بعد ومراقبة الأجهزة في الوقت الفعلي.', 'Activity', 2),
    ('directive_2', 'Thermal Optimization', 'التحسين الحراري', 'Custom-engineered cooling protocols for peak performance.', 'بروتوكولات التبريد المصممة خصيصاً لتحقيق ذروة الأداء.', 'Thermometer', 3),
    ('directive_3', 'Structural Integrity', 'النزاهة الهيكلية', 'Industrial-grade chassis and component standards.', 'هيكل من الدرجة الصناعية ومعايير المكونات.', 'Shield', 4)
ON CONFLICT (section_key) DO NOTHING;

-- Grant permissions
GRANT SELECT ON about_content TO anon, authenticated;

COMMIT;

-- Verify table created
SELECT 'about_content table created' as status, COUNT(*) as row_count 
FROM about_content;
