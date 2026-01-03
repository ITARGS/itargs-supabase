-- Create working_hours table for dynamic store hours
-- Allows admins to manage store schedule from admin panel

BEGIN;

CREATE TABLE IF NOT EXISTS public.working_hours (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    day_range text NOT NULL, -- e.g., 'Saturday - Thursday'
    day_range_ar text NOT NULL,
    hours text NOT NULL, -- e.g., '9 AM - 6 PM'
    hours_ar text NOT NULL,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.working_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active working hours"
ON public.working_hours FOR SELECT TO public USING (is_active = true);

CREATE POLICY "Admins can manage working hours"
ON public.working_hours FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM user_roles WHERE user_roles.user_id = auth.uid() AND user_roles.role = 'admin'));

-- Add timestamp trigger
CREATE TRIGGER update_working_hours_updated_at BEFORE UPDATE ON public.working_hours FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default working hours
INSERT INTO public.working_hours (day_range, day_range_ar, hours, hours_ar, display_order) VALUES
    ('Saturday - Thursday', 'السبت - الخميس', '9 AM - 6 PM', '9 صباحاً - 6 مساءً', 1),
    ('Friday', 'الجمعة', 'Closed', 'مغلق', 2)
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT ON working_hours TO anon, authenticated;

COMMIT;

-- Verify
SELECT 'working_hours table created' as status;
