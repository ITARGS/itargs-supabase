-- Replace educational categories with BenchMark tech hardware categories

-- Clear existing categories and product_categories
TRUNCATE TABLE product_categories CASCADE;
DELETE FROM categories;

-- Insert BenchMark tech hardware categories
INSERT INTO categories (id, name, name_ar, slug, description, description_ar, icon, is_active, display_order, parent_id) VALUES
-- Main Categories
('a1111111-1111-1111-1111-111111111111', 'Workstations', 'محطات العمل', 'workstations', 'High-performance workstations for professionals', 'محطات عمل عالية الأداء للمحترفين', 'monitor', true, 1, NULL),
('a2222222-2222-2222-2222-222222222222', 'Components', 'المكونات', 'components', 'PC components and hardware', 'مكونات الكمبيوتر والأجهزة', 'cpu', true, 2, NULL),
('a3333333-3333-3333-3333-333333333333', 'Peripherals', 'الملحقات', 'peripherals', 'Keyboards, mice, and accessories', 'لوحات المفاتيح والفأرة والملحقات', 'keyboard', true, 3, NULL),
('a4444444-4444-4444-4444-444444444444', 'Networking', 'الشبكات', 'networking', 'Network equipment and solutions', 'معدات وحلول الشبكات', 'network', true, 4, NULL),
('a5555555-5555-5555-5555-555555555555', 'Storage', 'التخزين', 'storage', 'Storage devices and solutions', 'أجهزة وحلول التخزين', 'hard-drive', true, 5, NULL),
('a6666666-6666-6666-6666-666666666666', 'Displays', 'الشاشات', 'displays', 'Monitors and display solutions', 'الشاشات وحلول العرض', 'monitor', true, 6, NULL),

-- Workstation Subcategories
('b1111111-1111-1111-1111-111111111111', 'Desktop Workstations', 'محطات عمل مكتبية', 'desktop-workstations', 'Professional desktop workstations', 'محطات عمل مكتبية احترافية', 'pc-case', true, 1, 'a1111111-1111-1111-1111-111111111111'),
('b1111112-1111-1111-1111-111111111111', 'Mobile Workstations', 'محطات عمل متنقلة', 'mobile-workstations', 'Portable workstation laptops', 'أجهزة لابتوب محطات عمل', 'laptop', true, 2, 'a1111111-1111-1111-1111-111111111111'),
('b1111113-1111-1111-1111-111111111111', 'Rackmount Workstations', 'محطات عمل رف', 'rackmount-workstations', 'Server rack workstations', 'محطات عمل للخوادم', 'server', true, 3, 'a1111111-1111-1111-1111-111111111111'),

-- Component Subcategories
('b2222221-2222-2222-2222-222222222222', 'Processors (CPUs)', 'المعالجات', 'processors', 'Intel and AMD processors', 'معالجات إنتل وإيه إم دي', 'cpu', true, 1, 'a2222222-2222-2222-2222-222222222222'),
('b2222222-2222-2222-2222-222222222222', 'Graphics Cards (GPUs)', 'كروت الشاشة', 'graphics-cards', 'NVIDIA and AMD graphics cards', 'كروت شاشة إنفيديا وإيه إم دي', 'gpu', true, 2, 'a2222222-2222-2222-2222-222222222222'),
('b2222223-2222-2222-2222-222222222222', 'Memory (RAM)', 'الذاكرة', 'memory-ram', 'DDR4 and DDR5 memory modules', 'وحدات ذاكرة DDR4 و DDR5', 'memory-stick', true, 3, 'a2222222-2222-2222-2222-222222222222'),
('b2222224-2222-2222-2222-222222222222', 'Motherboards', 'اللوحات الأم', 'motherboards', 'Motherboards for workstations', 'لوحات أم لمحطات العمل', 'circuit-board', true, 4, 'a2222222-2222-2222-2222-222222222222'),
('b2222225-2222-2222-2222-222222222222', 'Power Supplies', 'مزودات الطاقة', 'power-supplies', 'PSUs for workstations', 'مزودات طاقة لمحطات العمل', 'zap', true, 5, 'a2222222-2222-2222-2222-222222222222'),
('b2222226-2222-2222-2222-222222222222', 'Cooling Solutions', 'حلول التبريد', 'cooling-solutions', 'CPU and case cooling', 'تبريد المعالج والكيس', 'fan', true, 6, 'a2222222-2222-2222-2222-222222222222'),

-- Peripheral Subcategories
('b3333331-3333-3333-3333-333333333333', 'Keyboards', 'لوحات المفاتيح', 'keyboards', 'Mechanical and professional keyboards', 'لوحات مفاتيح ميكانيكية واحترافية', 'keyboard', true, 1, 'a3333333-3333-3333-3333-333333333333'),
('b3333332-3333-3333-3333-333333333333', 'Mice', 'الفأرة', 'mice', 'Professional and gaming mice', 'فأرة احترافية وألعاب', 'mouse', true, 2, 'a3333333-3333-3333-3333-333333333333'),
('b3333333-3333-3333-3333-333333333333', 'Headsets', 'سماعات الرأس', 'headsets', 'Professional audio headsets', 'سماعات رأس صوتية احترافية', 'headphones', true, 3, 'a3333333-3333-3333-3333-333333333333'),
('b3333334-3333-3333-3333-333333333333', 'Webcams', 'كاميرات الويب', 'webcams', 'HD and 4K webcams', 'كاميرات ويب عالية الدقة', 'camera', true, 4, 'a3333333-3333-3333-3333-333333333333'),

-- Networking Subcategories
('b4444441-4444-4444-4444-444444444444', 'Routers', 'الموجهات', 'routers', 'Enterprise and professional routers', 'موجهات احترافية ومؤسسية', 'router', true, 1, 'a4444444-4444-4444-4444-444444444444'),
('b4444442-4444-4444-4444-444444444444', 'Switches', 'المحولات', 'switches', 'Network switches', 'محولات الشبكة', 'network', true, 2, 'a4444444-4444-4444-4444-444444444444'),
('b4444443-4444-4444-4444-444444444444', 'Network Cards', 'كروت الشبكة', 'network-cards', 'Ethernet and WiFi adapters', 'محولات إيثرنت وواي فاي', 'wifi', true, 3, 'a4444444-4444-4444-4444-444444444444'),

-- Storage Subcategories
('b5555551-5555-5555-5555-555555555555', 'SSDs', 'أقراص SSD', 'ssds', 'Solid state drives', 'أقراص الحالة الصلبة', 'hard-drive', true, 1, 'a5555555-5555-5555-5555-555555555555'),
('b5555552-5555-5555-5555-555555555555', 'HDDs', 'أقراص HDD', 'hdds', 'Hard disk drives', 'الأقراص الصلبة', 'database', true, 2, 'a5555555-5555-5555-5555-555555555555'),
('b5555553-5555-5555-5555-555555555555', 'NAS Systems', 'أنظمة NAS', 'nas-systems', 'Network attached storage', 'التخزين المتصل بالشبكة', 'server', true, 3, 'a5555555-5555-5555-5555-555555555555'),
('b5555554-5555-5555-5555-555555555555', 'External Storage', 'التخزين الخارجي', 'external-storage', 'Portable storage devices', 'أجهزة تخزين محمولة', 'usb', true, 4, 'a5555555-5555-5555-5555-555555555555'),

-- Display Subcategories
('b6666661-6666-6666-6666-666666666666', 'Professional Monitors', 'شاشات احترافية', 'professional-monitors', '4K and 5K professional displays', 'شاشات احترافية 4K و 5K', 'monitor', true, 1, 'a6666666-6666-6666-6666-666666666666'),
('b6666662-6666-6666-6666-666666666666', 'Ultrawide Monitors', 'شاشات عريضة', 'ultrawide-monitors', 'Ultrawide displays', 'شاشات فائقة العرض', 'monitor', true, 2, 'a6666666-6666-6666-6666-666666666666'),
('b6666663-6666-6666-6666-666666666666', 'Monitor Arms', 'حوامل الشاشات', 'monitor-arms', 'Ergonomic monitor mounts', 'حوامل شاشات مريحة', 'move', true, 3, 'a6666666-6666-6666-6666-666666666666');

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify categories created
SELECT 'BenchMark categories created:' as status, 
       COUNT(*) as total_categories,
       COUNT(CASE WHEN parent_id IS NULL THEN 1 END) as main_categories,
       COUNT(CASE WHEN parent_id IS NOT NULL THEN 1 END) as subcategories
FROM categories;

SELECT name, name_ar, slug, 
       CASE WHEN parent_id IS NULL THEN 'Main' ELSE 'Sub' END as type
FROM categories 
ORDER BY display_order, parent_id NULLS FIRST;
