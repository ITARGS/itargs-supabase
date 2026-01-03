-- Create trust_badges table for dynamic homepage trust section
-- Allows admins to manage trust badges from admin panel

BEGIN;

CREATE TABLE IF NOT EXISTS public.trust_badges (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    title_ar text NOT NULL,
    description text,
    description_ar text,
    icon text, -- Emoji or icon name
    metric_value text, -- e.g., "99.9%", "24/7", "v2.1.4"
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.trust_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active trust badges"
ON public.trust_badges FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "Admins can manage trust badges"
ON public.trust_badges FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Add timestamp trigger
CREATE TRIGGER update_trust_badges_updated_at
    BEFORE UPDATE ON public.trust_badges
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_trust_badges_active_order 
ON public.trust_badges(is_active, display_order);

-- Insert default trust badges
INSERT INTO public.trust_badges (title, title_ar, description, description_ar, icon, metric_value, display_order) VALUES
    ('Uptime SLA', 'اتفاقية مستوى الخدمة', 'System Reliability', 'موثوقية النظام', '⚡', '99.9%', 1),
    ('Support', 'الدعم', 'Technical Assistance', 'المساعدة الفنية', '🛠️', '24/7', 2),
    ('Warranty', 'الضمان', 'Product Coverage', 'تغطية المنتج', '🔒', '2 Years', 3),
    ('Delivery', 'التوصيل', 'Fast Shipping', 'شحن سريع', '🚚', '2-5 Days', 4)
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT ON trust_badges TO anon, authenticated;

COMMIT;

-- Verify table created
SELECT 'trust_badges table created' as status, COUNT(*) as row_count 
FROM trust_badges;
