-- BenchMark - Elnajar Brand Data Seeding Script

-- 1. Fix Missing Schema Column (Safety Check)
ALTER TABLE public.cart_items 
ADD COLUMN IF NOT EXISTS product_variant_id UUID REFERENCES public.product_variants(id) ON DELETE SET NULL;

-- 2. Clear Existing Data (Optional - Comment out if you want to keep existing data)
-- TRUNCATE public.order_items, public.orders, public.cart_items, public.reviews, public.product_images, public.product_variants, public.products, public.categories CASCADE;

-- 3. Insert Categories
INSERT INTO public.categories (id, name, name_ar, slug, description, description_ar, image_url, is_active, display_order)
VALUES 
  (gen_random_uuid(), 'Workstations', 'محطات العمل', 'workstations', 'High-performance PCs for rendering, engineering, and AI.', 'أجهزة كمبيوتر عالية الأداء للرندرة والهندسة والذكاء الاصطناعي.', 'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?auto=format&fit=crop&q=80', true, 1),
  (gen_random_uuid(), 'Gaming PCs', 'أجهزة الألعاب', 'gaming-pcs', 'Ultimate gaming rigs with high FPS and ray tracing.', 'أجهزة ألعاب فائقة مع إطارات عالية وتتبع الأشعة.', 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&q=80', true, 2),
  (gen_random_uuid(), 'Laptops', 'لابتوب', 'laptops', 'Portable powerhouses for work and play.', 'أجهزة محمولة قوية للعمل واللعب.', 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?auto=format&fit=crop&q=80', true, 3),
  (gen_random_uuid(), 'GPUs', 'كروت الشاشة', 'gpus', 'Latest graphics cards from NVIDIA and AMD.', 'أحدث كروت الشاشة من نيفيديا و AMD.', 'https://images.unsplash.com/photo-1591488320449-011701bb6704?auto=format&fit=crop&q=80', true, 4)
ON CONFLICT (slug) DO UPDATE SET 
  name = EXCLUDED.name,
  name_ar = EXCLUDED.name_ar,
  description = EXCLUDED.description,
  description_ar = EXCLUDED.description_ar;

-- 4. Insert Products (Fetching Category IDs dynamically)
WITH cats AS (SELECT id, slug FROM public.categories)
INSERT INTO public.products (id, name, name_ar, slug, description, description_ar, base_price, sale_price, stock_quantity, category_id, is_active, is_featured)
VALUES
  -- Workstation Product
  (
    gen_random_uuid(), 
    'Threadripper Render Station', 
    'محطة رندرة Threadripper', 
    'threadripper-render-station', 
    'AMD Ryzen Threadripper 7000, 128GB RAM, Dual RTX 4090. Created for 3D rendering and simulation.', 
    'معالج AMD Ryzen Threadripper 7000، رام 128 جيجا، وكارتين شاشة RTX 4090. مصمم للرندرة ثلاثية الأبعاد والمحاكاة.',
    250000.00, 
    NULL, 
    5, 
    (SELECT id FROM cats WHERE slug = 'workstations'), 
    true, 
    true
  ),
  -- Gaming PC Product
  (
    gen_random_uuid(), 
    'RTX 4080 Super Gaming PC', 
    'كمبيوتر ألعاب RTX 4080 Super', 
    'rtx-4080-super-gaming-pc', 
    'Intel Core i9-14900K, 64GB DDR5, RTX 4080 Super. The ultimate 4K gaming experience.', 
    'معالج Intel Core i9-14900K، رام 64 جيجا DDR5، وكارت شاشة RTX 4080 Super. تجربة ألعاب 4K فائقة.',
    120000.00, 
    115000.00, 
    10, 
    (SELECT id FROM cats WHERE slug = 'gaming-pcs'), 
    true, 
    true
  ),
   -- Laptop Product
  (
    gen_random_uuid(), 
    'Mobile Workstation Pro 16', 
    'لابتوب محطة عمل برو 16', 
    'mobile-workstation-pro-16', 
    'Core i9, 32GB RAM, RTX 4070 Laptop GPU. Power on the go.', 
    'معالج Core i9، رام 32 جيجا، كارت شاشة RTX 4070. قوة أثناء التنقل.',
    85000.00, 
    NULL, 
    15, 
    (SELECT id FROM cats WHERE slug = 'laptops'), 
    true, 
    false
  )
ON CONFLICT (slug) DO NOTHING;

-- 5. Insert Product Images (Fetching Product IDs dynamically)
WITH prods AS (SELECT id, slug FROM public.products)
INSERT INTO public.product_images (product_id, image_url, is_primary, display_order)
VALUES
  ((SELECT id FROM prods WHERE slug = 'threadripper-render-station'), 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&q=80', true, 1),
  ((SELECT id FROM prods WHERE slug = 'rtx-4080-super-gaming-pc'), 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?auto=format&fit=crop&q=80', true, 1),
  ((SELECT id FROM prods WHERE slug = 'mobile-workstation-pro-16'), 'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?auto=format&fit=crop&q=80', true, 1);
