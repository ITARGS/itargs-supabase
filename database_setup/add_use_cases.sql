-- Create use_cases table for dynamic filter management
-- This allows admins to manage use case filters from the admin panel

CREATE TABLE IF NOT EXISTS public.use_cases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    name_ar text NOT NULL,
    description text,
    description_ar text,
    icon text, -- emoji or icon identifier
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.use_cases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active use cases"
ON public.use_cases FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "Admins can manage use cases"
ON public.use_cases FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Add timestamp trigger
CREATE TRIGGER update_use_cases_updated_at
    BEFORE UPDATE ON public.use_cases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default use cases
INSERT INTO public.use_cases (name, name_ar, icon, display_order) VALUES
    ('gaming', 'ألعاب', '🎮', 1),
    ('workstation', 'محطة عمل', '💼', 2),
    ('office', 'مكتب', '🏢', 3),
    ('server', 'خادم', '🖥️', 4),
    ('content-creation', 'إنشاء محتوى', '🎬', 5),
    ('home', 'منزلي', '🏠', 6)
ON CONFLICT (name) DO NOTHING;

-- Grant permissions
GRANT SELECT ON use_cases TO anon, authenticated;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify table created
SELECT 'use_cases table created' as status, COUNT(*) as row_count 
FROM use_cases;
