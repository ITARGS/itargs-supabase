-- ============================================================================
-- BRAND MIGRATION: Educational → Hardware/Software Tech (BenchMark)
-- ============================================================================
-- This script transforms the database from educational products to tech hardware/software
-- Execute on: api.elnajar.itargs.com (supabase_elnajar-db-1)
-- ============================================================================

-- ============================================================================
-- PHASE 1: Create New Tech-Focused Tables
-- ============================================================================

-- 1.1 Workload Types Table
CREATE TABLE IF NOT EXISTS public.workload_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    name_ar text,
    description text,
    description_ar text,
    icon text, -- Lucide icon name
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 1.2 Product Workloads Junction Table
CREATE TABLE IF NOT EXISTS public.product_workloads (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    workload_type_id uuid NOT NULL REFERENCES workload_types(id) ON DELETE CASCADE,
    performance_score integer CHECK (performance_score >= 0 AND performance_score <= 100),
    created_at timestamptz DEFAULT now(),
    UNIQUE(product_id, workload_type_id)
);

-- 1.3 Tech Specs Table
CREATE TABLE IF NOT EXISTS public.tech_specs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE UNIQUE,
    
    -- CPU Specs
    cpu_model text,
    cpu_cores integer,
    cpu_threads integer,
    cpu_base_clock decimal(4,2), -- GHz
    cpu_boost_clock decimal(4,2), -- GHz
    
    -- GPU Specs
    gpu_model text,
    gpu_vram integer, -- GB
    gpu_cuda_cores integer,
    
    -- Memory
    ram_size integer, -- GB
    ram_type text, -- DDR4, DDR5
    ram_speed integer, -- MHz
    
    -- Storage
    storage_type text, -- NVMe SSD, SATA SSD, HDD
    storage_capacity integer, -- GB
    
    -- Power & Cooling
    psu_wattage integer,
    cooling_type text,
    
    -- Dimensions
    form_factor text,
    weight decimal(5,2), -- kg
    
    -- Connectivity
    ports jsonb, -- {usb_a: 4, usb_c: 2, hdmi: 1, ...}
    wifi_standard text,
    bluetooth_version text,
    
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 1.4 Tech Resources Table (replaces learning_content)
CREATE TABLE IF NOT EXISTS public.tech_resources (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    title_ar text,
    content text,
    content_ar text,
    resource_type text CHECK (resource_type IN ('guide', 'benchmark', 'review', 'tutorial', 'comparison')),
    product_id uuid REFERENCES products(id) ON DELETE SET NULL,
    workload_type_id uuid REFERENCES workload_types(id) ON DELETE SET NULL,
    thumbnail_url text,
    video_url text,
    author text,
    is_published boolean DEFAULT false,
    view_count integer DEFAULT 0,
    slug text UNIQUE,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- PHASE 2: Add Triggers
-- ============================================================================

CREATE TRIGGER update_workload_types_updated_at
    BEFORE UPDATE ON public.workload_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tech_specs_updated_at
    BEFORE UPDATE ON public.tech_specs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tech_resources_updated_at
    BEFORE UPDATE ON public.tech_resources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PHASE 3: Add RLS Policies
-- ============================================================================

-- workload_types
ALTER TABLE public.workload_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active workload types"
ON public.workload_types FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "Admins manage workload types"
ON public.workload_types FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- product_workloads
ALTER TABLE public.product_workloads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view product workloads"
ON public.product_workloads FOR SELECT
TO public
USING (true);

CREATE POLICY "Admins manage product workloads"
ON public.product_workloads FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- tech_specs
ALTER TABLE public.tech_specs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view tech specs"
ON public.tech_specs FOR SELECT
TO public
USING (true);

CREATE POLICY "Admins manage tech specs"
ON public.tech_specs FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- tech_resources
ALTER TABLE public.tech_resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view published resources"
ON public.tech_resources FOR SELECT
TO public
USING (is_published = true);

CREATE POLICY "Admins manage resources"
ON public.tech_resources FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_roles.user_id = auth.uid()
        AND user_roles.role = 'admin'
    )
);

-- ============================================================================
-- PHASE 4: Add Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_product_workloads_product_id ON product_workloads(product_id);
CREATE INDEX IF NOT EXISTS idx_product_workloads_workload_id ON product_workloads(workload_type_id);
CREATE INDEX IF NOT EXISTS idx_tech_specs_product_id ON tech_specs(product_id);
CREATE INDEX IF NOT EXISTS idx_tech_resources_product_id ON tech_resources(product_id);
CREATE INDEX IF NOT EXISTS idx_tech_resources_workload_id ON tech_resources(workload_type_id);
CREATE INDEX IF NOT EXISTS idx_tech_resources_published ON tech_resources(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_tech_resources_slug ON tech_resources(slug);

-- ============================================================================
-- PHASE 5: Insert Sample Data
-- ============================================================================

INSERT INTO public.workload_types (name, name_ar, description, description_ar, icon, display_order)
VALUES
    ('Professional Workstation', 'محطة عمل احترافية', 'High-performance systems for professional applications', 'أنظمة عالية الأداء للتطبيقات الاحترافية', 'Briefcase', 1),
    ('Gaming & Esports', 'الألعاب والرياضات الإلكترونية', 'Optimized for gaming and competitive esports', 'محسّن للألعاب والرياضات الإلكترونية التنافسية', 'Gamepad2', 2),
    ('Content Creation', 'إنشاء المحتوى', 'Video editing, photo editing, and creative work', 'تحرير الفيديو والصور والأعمال الإبداعية', 'Video', 3),
    ('3D Rendering & CAD', 'التصميم ثلاثي الأبعاد', '3D modeling, rendering, and CAD applications', 'النمذجة ثلاثية الأبعاد والتصميم بمساعدة الحاسوب', 'Box', 4),
    ('Data Science & AI', 'علوم البيانات والذكاء الاصطناعي', 'Machine learning, data analysis, and AI development', 'التعلم الآلي وتحليل البيانات وتطوير الذكاء الاصطناعي', 'Brain', 5),
    ('Software Development', 'تطوير البرمجيات', 'Programming, compilation, and software engineering', 'البرمجة والتجميع وهندسة البرمجيات', 'Code2', 6)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- PHASE 6: Clean Up Educational Columns from Profiles
-- ============================================================================

ALTER TABLE public.profiles 
    DROP COLUMN IF EXISTS child_age_range,
    DROP COLUMN IF EXISTS child_ages,
    DROP COLUMN IF EXISTS preferred_subjects,
    DROP COLUMN IF EXISTS is_teacher,
    DROP COLUMN IF EXISTS school_name,
    DROP COLUMN IF EXISTS teaching_grade;

-- Update customer_type to tech-focused values
UPDATE public.profiles 
SET customer_type = CASE
    WHEN customer_type = 'parent' THEN 'individual'
    WHEN customer_type = 'teacher' THEN 'professional'
    ELSE customer_type
END;

-- ============================================================================
-- PHASE 7: Clean Up Educational Columns from Products
-- ============================================================================

ALTER TABLE public.products
    DROP COLUMN IF EXISTS age_range,
    DROP COLUMN IF EXISTS subject;

-- Add tech-focused columns
ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS sku text,
    ADD COLUMN IF NOT EXISTS brand text,
    ADD COLUMN IF NOT EXISTS model text,
    ADD COLUMN IF NOT EXISTS warranty_months integer DEFAULT 12;

-- Create unique index on SKU
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_sku ON products(sku) WHERE sku IS NOT NULL;

-- ============================================================================
-- PHASE 8: Drop Old Educational Tables
-- ============================================================================

-- Drop junction tables first (have foreign keys)
DROP TABLE IF EXISTS public.product_age_ranges CASCADE;
DROP TABLE IF EXISTS public.product_subjects CASCADE;

-- Drop reference tables
DROP TABLE IF EXISTS public.age_ranges CASCADE;
DROP TABLE IF EXISTS public.subjects CASCADE;
DROP TABLE IF EXISTS public.learning_content CASCADE;

-- ============================================================================
-- PHASE 9: Reload PostgREST Schema Cache
-- ============================================================================

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'Migration Complete!' as status;

SELECT 'New Tables Created:' as info;
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('workload_types', 'product_workloads', 'tech_specs', 'tech_resources')
ORDER BY tablename;

SELECT 'Workload Types Inserted:' as info;
SELECT name, name_ar, is_active FROM workload_types ORDER BY display_order;

SELECT 'Old Tables Removed:' as info;
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'Successfully removed all educational tables'
    ELSE 'Warning: Some tables still exist'
END as result
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('age_ranges', 'subjects', 'learning_content', 'product_age_ranges', 'product_subjects');
