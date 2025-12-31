-- Fix categories table and create proper BenchMark categories

-- Add missing columns to categories table
ALTER TABLE categories ADD COLUMN IF NOT EXISTS icon text;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS image_url text;

-- Create category-images storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'category-images',
  'category-images',
  true,
  3145728, -- 3MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 3145728,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];

-- Clear and recreate categories
DELETE FROM categories;

-- Insert BenchMark tech hardware categories
INSERT INTO categories (id, name, name_ar, slug, description, description_ar, icon, is_active, display_order, parent_id, meta_title, meta_description) VALUES
-- Main Categories
('a1111111-1111-1111-1111-111111111111', 'Workstations', 'محطات العمل', 'workstations', 'High-performance workstations for professionals', 'محطات عمل عالية الأداء للمحترفين', 'monitor', true, 1, NULL, 'Professional Workstations', 'High-performance workstations for demanding professional workflows'),
('a2222222-2222-2222-2222-222222222222', 'Components', 'المكونات', 'components', 'PC components and hardware', 'مكونات الكمبيوتر والأجهزة', 'cpu', true, 2, NULL, 'PC Components', 'Computer components and hardware for custom builds'),
('a3333333-3333-3333-3333-333333333333', 'Peripherals', 'الملحقات', 'peripherals', 'Keyboards, mice, and accessories', 'لوحات المفاتيح والفأرة والملحقات', 'keyboard', true, 3, NULL, 'Computer Peripherals', 'Professional keyboards, mice, and computer accessories'),
('a4444444-4444-4444-4444-444444444444', 'Networking', 'الشبكات', 'networking', 'Network equipment and solutions', 'معدات وحلول الشبكات', 'network', true, 4, NULL, 'Networking Equipment', 'Professional networking hardware and solutions'),
('a5555555-5555-5555-5555-555555555555', 'Storage', 'التخزين', 'storage', 'Storage devices and solutions', 'أجهزة وحلول التخزين', 'hard-drive', true, 5, NULL, 'Storage Solutions', 'SSDs, HDDs, and enterprise storage solutions'),
('a6666666-6666-6666-6666-666666666666', 'Displays', 'الشاشات', 'displays', 'Monitors and display solutions', 'الشاشات وحلول العرض', 'monitor', true, 6, NULL, 'Professional Displays', 'Professional monitors and display solutions'),

-- Workstation Subcategories
('b1111111-1111-1111-1111-111111111111', 'Desktop Workstations', 'محطات عمل مكتبية', 'desktop-workstations', 'Professional desktop workstations', 'محطات عمل مكتبية احترافية', 'pc-case', true, 1, 'a1111111-1111-1111-1111-111111111111', 'Desktop Workstations', 'Professional desktop workstations for demanding tasks'),
('b1111112-1111-1111-1111-111111111111', 'Mobile Workstations', 'محطات عمل متنقلة', 'mobile-workstations', 'Portable workstation laptops', 'أجهزة لابتوب محطات عمل', 'laptop', true, 2, 'a1111111-1111-1111-1111-111111111111', 'Mobile Workstations', 'Portable workstation laptops for professionals'),
('b1111113-1111-1111-1111-111111111111', 'Rackmount Workstations', 'محطات عمل رف', 'rackmount-workstations', 'Server rack workstations', 'محطات عمل للخوادم', 'server', true, 3, 'a1111111-1111-1111-1111-111111111111', 'Rackmount Workstations', 'Server rack-mounted workstations'),

-- Component Subcategories
('b2222221-2222-2222-2222-222222222222', 'Processors', 'المعالجات', 'processors', 'Intel and AMD processors', 'معالجات إنتل وإيه إم دي', 'cpu', true, 1, 'a2222222-2222-2222-2222-222222222222', 'CPUs & Processors', 'Intel and AMD processors for workstations'),
('b2222222-2222-2222-2222-222222222222', 'Graphics Cards', 'كروت الشاشة', 'graphics-cards', 'NVIDIA and AMD graphics cards', 'كروت شاشة إنفيديا وإيه إم دي', 'gpu', true, 2, 'a2222222-2222-2222-2222-222222222222', 'Graphics Cards', 'Professional NVIDIA and AMD graphics cards'),
('b2222223-2222-2222-2222-222222222222', 'Memory', 'الذاكرة', 'memory-ram', 'DDR4 and DDR5 memory modules', 'وحدات ذاكرة DDR4 و DDR5', 'memory-stick', true, 3, 'a2222222-2222-2222-2222-222222222222', 'RAM Memory', 'DDR4 and DDR5 memory modules'),
('b2222224-2222-2222-2222-222222222222', 'Motherboards', 'اللوحات الأم', 'motherboards', 'Motherboards for workstations', 'لوحات أم لمحطات العمل', 'circuit-board', true, 4, 'a2222222-2222-2222-2222-222222222222', 'Motherboards', 'Professional motherboards for workstations'),
('b2222225-2222-2222-2222-222222222222', 'Power Supplies', 'مزودات الطاقة', 'power-supplies', 'PSUs for workstations', 'مزودات طاقة لمحطات العمل', 'zap', true, 5, 'a2222222-2222-2222-2222-222222222222', 'Power Supplies', 'High-quality PSUs for workstations'),
('b2222226-2222-2222-2222-222222222222', 'Cooling', 'التبريد', 'cooling-solutions', 'CPU and case cooling', 'تبريد المعالج والكيس', 'fan', true, 6, 'a2222222-2222-2222-2222-222222222222', 'Cooling Solutions', 'CPU and case cooling solutions'),

-- Peripheral Subcategories
('b3333331-3333-3333-3333-333333333333', 'Keyboards', 'لوحات المفاتيح', 'keyboards', 'Mechanical and professional keyboards', 'لوحات مفاتيح ميكانيكية واحترافية', 'keyboard', true, 1, 'a3333333-3333-3333-3333-333333333333', 'Professional Keyboards', 'Mechanical and professional keyboards'),
('b3333332-3333-3333-3333-333333333333', 'Mice', 'الفأرة', 'mice', 'Professional and gaming mice', 'فأرة احترافية وألعاب', 'mouse', true, 2, 'a3333333-3333-3333-3333-333333333333', 'Computer Mice', 'Professional and gaming mice'),
('b3333333-3333-3333-3333-333333333333', 'Headsets', 'سماعات الرأس', 'headsets', 'Professional audio headsets', 'سماعات رأس صوتية احترافية', 'headphones', true, 3, 'a3333333-3333-3333-3333-333333333333', 'Audio Headsets', 'Professional audio headsets'),
('b3333334-3333-3333-3333-333333333333', 'Webcams', 'كاميرات الويب', 'webcams', 'HD and 4K webcams', 'كاميرات ويب عالية الدقة', 'camera', true, 4, 'a3333333-3333-3333-3333-333333333333', 'Webcams', 'HD and 4K webcams for professionals'),

-- Networking Subcategories
('b4444441-4444-4444-4444-444444444444', 'Routers', 'الموجهات', 'routers', 'Enterprise routers', 'موجهات احترافية', 'router', true, 1, 'a4444444-4444-4444-4444-444444444444', 'Network Routers', 'Enterprise and professional routers'),
('b4444442-4444-4444-4444-444444444444', 'Switches', 'المحولات', 'switches', 'Network switches', 'محولات الشبكة', 'network', true, 2, 'a4444444-4444-4444-4444-444444444444', 'Network Switches', 'Professional network switches'),
('b4444443-4444-4444-4444-444444444444', 'Network Cards', 'كروت الشبكة', 'network-cards', 'Ethernet and WiFi adapters', 'محولات إيثرنت وواي فاي', 'wifi', true, 3, 'a4444444-4444-4444-4444-444444444444', 'Network Adapters', 'Ethernet and WiFi network adapters'),

-- Storage Subcategories
('b5555551-5555-5555-5555-555555555555', 'SSDs', 'أقراص SSD', 'ssds', 'Solid state drives', 'أقراص الحالة الصلبة', 'hard-drive', true, 1, 'a5555555-5555-5555-5555-555555555555', 'SSD Storage', 'High-performance solid state drives'),
('b5555552-5555-5555-5555-555555555555', 'HDDs', 'أقراص HDD', 'hdds', 'Hard disk drives', 'الأقراص الصلبة', 'database', true, 2, 'a5555555-5555-5555-5555-555555555555', 'HDD Storage', 'High-capacity hard disk drives'),
('b5555553-5555-5555-5555-555555555555', 'NAS Systems', 'أنظمة NAS', 'nas-systems', 'Network attached storage', 'التخزين المتصل بالشبكة', 'server', true, 3, 'a5555555-5555-5555-5555-555555555555', 'NAS Storage', 'Network attached storage systems'),
('b5555554-5555-5555-5555-555555555555', 'External Storage', 'التخزين الخارجي', 'external-storage', 'Portable storage devices', 'أجهزة تخزين محمولة', 'usb', true, 4, 'a5555555-5555-5555-5555-555555555555', 'External Storage', 'Portable external storage devices'),

-- Display Subcategories
('b6666661-6666-6666-6666-666666666666', 'Professional Monitors', 'شاشات احترافية', 'professional-monitors', '4K and 5K displays', 'شاشات احترافية 4K و 5K', 'monitor', true, 1, 'a6666666-6666-6666-6666-666666666666', 'Professional Monitors', '4K and 5K professional displays'),
('b6666662-6666-6666-6666-666666666666', 'Ultrawide Monitors', 'شاشات عريضة', 'ultrawide-monitors', 'Ultrawide displays', 'شاشات فائقة العرض', 'monitor', true, 2, 'a6666666-6666-6666-6666-666666666666', 'Ultrawide Monitors', 'Ultrawide professional displays'),
('b6666663-6666-6666-6666-666666666666', 'Monitor Arms', 'حوامل الشاشات', 'monitor-arms', 'Ergonomic monitor mounts', 'حوامل شاشات مريحة', 'move', true, 3, 'a6666666-6666-6666-6666-666666666666', 'Monitor Arms', 'Ergonomic monitor mounting solutions');

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify
SELECT 'Categories and bucket created:' as status, 
       COUNT(*) as total_categories,
       COUNT(CASE WHEN parent_id IS NULL THEN 1 END) as main_categories,
       COUNT(CASE WHEN parent_id IS NOT NULL THEN 1 END) as subcategories
FROM categories;
