-- Fix missing performance_tiers table and reload PostgREST cache

-- ============================================================================
-- Create performance_tiers table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.performance_tiers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    name_ar text,
    description text,
    description_ar text,
    min_score integer,
    max_score integer,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add RLS policies
ALTER TABLE public.performance_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active performance tiers"
ON public.performance_tiers FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "Admins can manage performance tiers"
ON public.performance_tiers FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Add timestamp trigger
CREATE TRIGGER update_performance_tiers_updated_at
    BEFORE UPDATE ON public.performance_tiers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Create product_performance_tiers junction table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.product_performance_tiers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    performance_tier_id uuid NOT NULL REFERENCES performance_tiers(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE(product_id, performance_tier_id)
);

-- Add RLS policies
ALTER TABLE public.product_performance_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view product performance tiers"
ON public.product_performance_tiers FOR SELECT
TO public
USING (true);

CREATE POLICY "Admins can manage product performance tiers"
ON public.product_performance_tiers FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_product_performance_tiers_product_id 
    ON product_performance_tiers(product_id);
CREATE INDEX IF NOT EXISTS idx_product_performance_tiers_tier_id 
    ON product_performance_tiers(performance_tier_id);

-- ============================================================================
-- Insert sample performance tiers
-- ============================================================================

INSERT INTO public.performance_tiers (name, name_ar, description, description_ar, min_score, max_score, display_order)
VALUES
    ('Entry Level', 'مستوى مبتدئ', 'Basic performance for everyday tasks', 'أداء أساسي للمهام اليومية', 0, 30, 1),
    ('Mid Range', 'متوسط المدى', 'Good performance for most applications', 'أداء جيد لمعظم التطبيقات', 31, 60, 2),
    ('High Performance', 'أداء عالي', 'Excellent performance for demanding tasks', 'أداء ممتاز للمهام المتطلبة', 61, 85, 3),
    ('Enthusiast', 'للمحترفين', 'Top-tier performance for professionals', 'أداء من الدرجة الأولى للمحترفين', 86, 100, 4)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- Reload PostgREST schema cache
-- ============================================================================

NOTIFY pgrst, 'reload schema';

-- Verify tables created
SELECT 'performance_tiers table created' as status, COUNT(*) as row_count 
FROM performance_tiers;

SELECT 'product_performance_tiers table created' as status, COUNT(*) as row_count 
FROM product_performance_tiers;
