-- ============================================================================
-- 1. إعادة إنشاء وظيفة إنشاء الملف الشخصي (Profile)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, created_at, updated_at, role)
    VALUES (NEW.id, NOW(), NOW(), 'customer')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. إعادة إنشاء الـ Trigger الوحيد المطلوب
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 3. التأكد من وجود سجلات لكل المستخدمين الحاليين (لحل مشكلة المستخدمين القدامى)
-- ============================================================================
INSERT INTO public.profiles (id, created_at, updated_at, role)
SELECT id, created_at, last_sign_in_at, 'customer'
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 4. تبسيط صلاحيات الوصول (RLS) لأقصى درجة
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow users to view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to insert own profile" ON public.profiles;

CREATE POLICY "individual_select" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "individual_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "individual_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================================================
-- 5. ضمان صلاحيات الـ Roles في الـ Postgres
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

SELECT 'FIX APPLIED: Standard Trigger and Profiles Restored' as status;
