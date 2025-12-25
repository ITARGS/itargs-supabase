-- ============================================
-- DUMMY DATA FOR TESTING
-- KAT Education E-commerce Platform
-- ============================================
-- This script populates the database with sample data for testing
-- Run this after 01_complete_schema.sql and 02_initial_settings.sql

-- ============================================
-- SAMPLE PRODUCTS
-- ============================================
INSERT INTO products (name, name_ar, slug, description, description_ar, price, sale_price, sku, stock_quantity, category_id, is_featured, is_active, age_range) VALUES
-- Learning Toys
('Alphabet Learning Board', 'لوحة تعلم الحروف', 'alphabet-learning-board', 'Interactive board to learn letters and sounds', 'لوحة تفاعلية لتعلم الحروف والأصوات', 299.00, 249.00, 'ALB-001', 50, (SELECT id FROM categories WHERE slug = 'learning-toys'), true, true, '3-5'),
('Number Counting Set', 'مجموعة عد الأرقام', 'number-counting-set', 'Colorful counting blocks for math skills', 'مكعبات ملونة لتعلم مهارات الرياضيات', 199.00, NULL, 'NCS-001', 75, (SELECT id FROM categories WHERE slug = 'learning-toys'), true, true, '3-5'),
('Shape Sorter Toy', 'لعبة فرز الأشكال', 'shape-sorter-toy', 'Learn shapes and colors through play', 'تعلم الأشكال والألوان من خلال اللعب', 149.00, 129.00, 'SST-001', 100, (SELECT id FROM categories WHERE slug = 'learning-toys'), false, true, '2-4'),

-- Books & Reading
('Arabic Alphabet Book', 'كتاب الحروف العربية', 'arabic-alphabet-book', 'Illustrated book for learning Arabic letters', 'كتاب مصور لتعلم الحروف العربية', 89.00, NULL, 'AAB-001', 120, (SELECT id FROM categories WHERE slug = 'books-reading'), true, true, '3-6'),
('Story Time Collection', 'مجموعة وقت القصة', 'story-time-collection', 'Set of 5 educational stories', 'مجموعة من 5 قصص تعليمية', 249.00, 199.00, 'STC-001', 60, (SELECT id FROM categories WHERE slug = 'books-reading'), true, true, '4-8'),

-- Art & Crafts
('Coloring Book Set', 'مجموعة كتب التلوين', 'coloring-book-set', '3 coloring books with crayons', '3 كتب تلوين مع أقلام تلوين', 129.00, NULL, 'CBS-001', 80, (SELECT id FROM categories WHERE slug = 'art-crafts'), false, true, '3-7'),
('Clay Modeling Kit', 'مجموعة الصلصال', 'clay-modeling-kit', 'Non-toxic clay in 12 colors', 'صلصال غير سام ب 12 لون', 179.00, 149.00, 'CMK-001', 45, (SELECT id FROM categories WHERE slug = 'art-crafts'), true, true, '4-10'),

-- STEM Kits
('Science Experiment Kit', 'مجموعة التجارب العلمية', 'science-experiment-kit', '20 fun science experiments', '20 تجربة علمية ممتعة', 399.00, 349.00, 'SEK-001', 30, (SELECT id FROM categories WHERE slug = 'stem-kits'), true, true, '6-12'),
('Robot Building Set', 'مجموعة بناء الروبوت', 'robot-building-set', 'Build and program your own robot', 'ابني وبرمج روبوتك الخاص', 599.00, NULL, 'RBS-001', 25, (SELECT id FROM categories WHERE slug = 'stem-kits'), true, true, '8-14'),

-- Puzzles & Games
('Educational Puzzle Set', 'مجموعة الألغاز التعليمية', 'educational-puzzle-set', '4 puzzles for different skills', '4 ألغاز لمهارات مختلفة', 169.00, 139.00, 'EPS-001', 90, (SELECT id FROM categories WHERE slug = 'puzzles-games'), false, true, '4-8'),
('Memory Matching Game', 'لعبة مطابقة الذاكرة', 'memory-matching-game', 'Improve memory and concentration', 'حسن الذاكرة والتركيز', 119.00, NULL, 'MMG-001', 110, (SELECT id FROM categories WHERE slug = 'puzzles-games'), false, true, '3-6')
ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- PRODUCT IMAGES
-- ============================================
-- Note: Replace these URLs with actual image URLs
INSERT INTO product_images (product_id, image_url, alt_text, display_order, is_primary) VALUES
((SELECT id FROM products WHERE slug = 'alphabet-learning-board'), '/placeholder.svg', 'Alphabet Learning Board', 1, true),
((SELECT id FROM products WHERE slug = 'number-counting-set'), '/placeholder.svg', 'Number Counting Set', 1, true),
((SELECT id FROM products WHERE slug = 'shape-sorter-toy'), '/placeholder.svg', 'Shape Sorter Toy', 1, true),
((SELECT id FROM products WHERE slug = 'arabic-alphabet-book'), '/placeholder.svg', 'Arabic Alphabet Book', 1, true),
((SELECT id FROM products WHERE slug = 'story-time-collection'), '/placeholder.svg', 'Story Time Collection', 1, true),
((SELECT id FROM products WHERE slug = 'coloring-book-set'), '/placeholder.svg', 'Coloring Book Set', 1, true),
((SELECT id FROM products WHERE slug = 'clay-modeling-kit'), '/placeholder.svg', 'Clay Modeling Kit', 1, true),
((SELECT id FROM products WHERE slug = 'science-experiment-kit'), '/placeholder.svg', 'Science Experiment Kit', 1, true),
((SELECT id FROM products WHERE slug = 'robot-building-set'), '/placeholder.svg', 'Robot Building Set', 1, true),
((SELECT id FROM products WHERE slug = 'educational-puzzle-set'), '/placeholder.svg', 'Educational Puzzle Set', 1, true),
((SELECT id FROM products WHERE slug = 'memory-matching-game'), '/placeholder.svg', 'Memory Matching Game', 1, true)
ON CONFLICT DO NOTHING;

-- ============================================
-- SAMPLE BUNDLES
-- ============================================
INSERT INTO bundles (name, name_ar, slug, description, description_ar, price, sale_price, is_active) VALUES
('Starter Learning Pack', 'حزمة التعلم المبتدئة', 'starter-learning-pack', 'Perfect bundle for beginners', 'حزمة مثالية للمبتدئين', 599.00, 499.00, true),
('Complete Reading Bundle', 'حزمة القراءة الكاملة', 'complete-reading-bundle', 'Everything needed for reading skills', 'كل ما تحتاجه لمهارات القراءة', 449.00, 399.00, true),
('STEM Explorer Pack', 'حزمة مستكشف العلوم', 'stem-explorer-pack', 'Science and technology bundle', 'حزمة العلوم والتكنولوجيا', 899.00, 799.00, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- BUNDLE PRODUCTS
-- ============================================
INSERT INTO bundle_products (bundle_id, product_id, quantity) VALUES
-- Starter Learning Pack
((SELECT id FROM bundles WHERE slug = 'starter-learning-pack'), (SELECT id FROM products WHERE slug = 'alphabet-learning-board'), 1),
((SELECT id FROM bundles WHERE slug = 'starter-learning-pack'), (SELECT id FROM products WHERE slug = 'number-counting-set'), 1),
((SELECT id FROM bundles WHERE slug = 'starter-learning-pack'), (SELECT id FROM products WHERE slug = 'shape-sorter-toy'), 1),

-- Complete Reading Bundle
((SELECT id FROM bundles WHERE slug = 'complete-reading-bundle'), (SELECT id FROM products WHERE slug = 'arabic-alphabet-book'), 1),
((SELECT id FROM bundles WHERE slug = 'complete-reading-bundle'), (SELECT id FROM products WHERE slug = 'story-time-collection'), 1),

-- STEM Explorer Pack
((SELECT id FROM bundles WHERE slug = 'stem-explorer-pack'), (SELECT id FROM products WHERE slug = 'science-experiment-kit'), 1),
((SELECT id FROM bundles WHERE slug = 'stem-explorer-pack'), (SELECT id FROM products WHERE slug = 'robot-building-set'), 1)
ON CONFLICT DO NOTHING;

-- ============================================
-- SAMPLE DISCOUNT CODES
-- ============================================
INSERT INTO discount_codes (code, description, discount_type, discount_value, min_purchase_amount, usage_limit, valid_from, valid_until, is_active) VALUES
('WELCOME10', 'Welcome discount for new customers', 'percentage', 10.00, 200.00, 100, NOW(), NOW() + INTERVAL '30 days', true),
('SAVE50', 'Save 50 EGP on orders over 500', 'fixed', 50.00, 500.00, 50, NOW(), NOW() + INTERVAL '15 days', true),
('BUNDLE20', '20% off on all bundles', 'percentage', 20.00, 0.00, NULL, NOW(), NOW() + INTERVAL '60 days', true)
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- SAMPLE REVIEWS (Approved)
-- ============================================
-- Note: These reviews reference auth.users which may not exist yet
-- You'll need to create test users first or update user_id values

-- Create a dummy UUID for reviews (replace with actual user IDs in production)
DO $$
DECLARE
    dummy_user_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Insert sample reviews
    INSERT INTO reviews (product_id, user_id, rating, title, comment, is_approved, is_verified_purchase) VALUES
    ((SELECT id FROM products WHERE slug = 'alphabet-learning-board'), dummy_user_id, 5, 'Excellent product!', 'My child loves it! Very educational and fun.', true, true),
    ((SELECT id FROM products WHERE slug = 'alphabet-learning-board'), dummy_user_id, 4, 'Great quality', 'Good quality but a bit expensive.', true, false),
    ((SELECT id FROM products WHERE slug = 'number-counting-set'), dummy_user_id, 5, 'Perfect for learning', 'Helped my son learn numbers quickly!', true, true),
    ((SELECT id FROM products WHERE slug = 'science-experiment-kit'), dummy_user_id, 5, 'Amazing!', 'So many fun experiments. Highly recommend!', true, true),
    ((SELECT id FROM products WHERE slug = 'story-time-collection'), dummy_user_id, 4, 'Nice stories', 'Good collection of educational stories.', true, true)
    ON CONFLICT DO NOTHING;
END $$;

-- ============================================
-- NEWSLETTER SUBSCRIBERS (Sample)
-- ============================================
INSERT INTO newsletter_subscribers (email, is_active) VALUES
('test1@example.com', true),
('test2@example.com', true),
('test3@example.com', true)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Dummy data has been populated
-- You can now test the e-commerce platform with sample data
