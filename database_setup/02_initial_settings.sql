-- ============================================
-- INITIAL SETTINGS POPULATION
-- KAT Education E-commerce Platform
-- ============================================
-- This script populates the settings table with default values
-- Run this after 01_complete_schema.sql

-- ============================================
-- STORE INFORMATION
-- ============================================
INSERT INTO settings (key, value, description) VALUES
('store_name', 'KAT Education', 'Store name displayed across the site'),
('store_description', 'Smart learning tools that make education fun', 'Store tagline/description'),
('store_email', 'info@kateducation.com', 'Store contact email'),
('store_phone', '+20 123 456 7890', 'Store contact phone'),
('store_whatsapp', '201234567890', 'WhatsApp number for customer support'),
('store_location', 'Cairo, Egypt', 'Store physical location'),
('store_logo', '/kat-education-logo.jpg', 'URL to store logo image'),
('offers_banner', '', 'URL to offers/bundles banner image'),

-- ============================================
-- SOCIAL MEDIA
-- ============================================
('store_facebook', 'https://facebook.com/kateducation', 'Facebook page URL'),
('store_instagram', 'https://instagram.com/kateducation', 'Instagram profile URL'),

-- ============================================
-- CURRENCY & LOCALIZATION
-- ============================================
('currency', 'EGP', 'Default currency code'),
('currency_symbol', 'ج.م', 'Currency symbol'),
('default_language', 'ar', 'Default language (ar/en)'),

-- ============================================
-- EMAIL NOTIFICATIONS
-- ============================================
('email_order_confirmation', 'true', 'Send order confirmation emails'),
('email_order_shipped', 'true', 'Send order shipped emails'),
('email_order_delivered', 'true', 'Send order delivered emails'),
('notify_new_orders', 'true', 'Notify admin of new orders'),
('notify_low_stock', 'true', 'Notify admin of low stock'),

-- ============================================
-- META PIXEL / ANALYTICS
-- ============================================
('meta_pixel_id', '', 'Facebook/Meta Pixel ID'),
('enable_meta_pixel', 'false', 'Enable Meta Pixel tracking'),
('google_analytics_id', '', 'Google Analytics ID'),

-- ============================================
-- THEME COLORS (KAT Theme)
-- ============================================
('theme_primary', '#9b87f5', 'Primary brand color'),
('theme_secondary', '#7E69AB', 'Secondary brand color'),
('theme_accent', '#6E59A5', 'Accent color'),
('theme_kat_purple', '#9b87f5', 'KAT purple color'),
('theme_kat_yellow', '#F2FCE2', 'KAT yellow/light color'),

-- ============================================
-- SHIPPING & DELIVERY
-- ============================================
('free_shipping_threshold', '500', 'Minimum order for free shipping'),
('default_shipping_cost', '50', 'Default shipping cost'),
('estimated_delivery_days', '3-5', 'Estimated delivery time'),

-- ============================================
-- BUSINESS SETTINGS
-- ============================================
('tax_rate', '0', 'Tax rate percentage'),
('min_order_amount', '0', 'Minimum order amount'),
('enable_reviews', 'true', 'Allow customer reviews'),
('auto_approve_reviews', 'false', 'Auto-approve reviews without moderation'),
('enable_wishlist', 'true', 'Enable wishlist feature'),
('enable_bundles', 'true', 'Enable product bundles'),

-- ============================================
-- LANDING PAGE SECTIONS
-- ============================================
('landing_hero_enabled', 'true', 'Show hero section on landing page'),
('landing_categories_enabled', 'true', 'Show categories section'),
('landing_featured_enabled', 'true', 'Show featured products'),
('landing_bundles_enabled', 'true', 'Show bundles section'),
('landing_about_enabled', 'true', 'Show about section'),
('landing_trust_enabled', 'true', 'Show trust badges'),
('landing_newsletter_enabled', 'true', 'Show newsletter signup'),

-- ============================================
-- SECTION ORDER
-- ============================================
('section_order_hero', '1', 'Hero section display order'),
('section_order_categories', '2', 'Categories section display order'),
('section_order_featured', '3', 'Featured products display order'),
('section_order_bundles', '4', 'Bundles section display order'),
('section_order_about', '5', 'About section display order'),
('section_order_trust', '6', 'Trust badges display order'),
('section_order_newsletter', '7', 'Newsletter section display order')

ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = NOW();

-- ============================================
-- PAYMENT METHODS
-- ============================================
INSERT INTO payment_methods (name, name_ar, description, description_ar, type, is_active, display_order) VALUES
('Cash on Delivery', 'الدفع عند الاستلام', 'Pay when you receive your order', 'ادفع عند استلام طلبك', 'cod', true, 1),
('Vodafone Cash', 'فودافون كاش', 'Pay using Vodafone Cash', 'ادفع باستخدام فودافون كاش', 'vodafone_cash', true, 2),
('InstaPay', 'إنستاباي', 'Pay using InstaPay', 'ادفع باستخدام إنستاباي', 'instapay', true, 3),
('Credit Card', 'بطاقة ائتمان', 'Pay with Visa or Mastercard', 'ادفع باستخدام فيزا أو ماستركارد', 'credit_card', true, 4)
ON CONFLICT DO NOTHING;

-- ============================================
-- SHIPPING METHODS
-- ============================================
INSERT INTO shipping_methods (name, name_ar, description, description_ar, base_cost, estimated_days, is_active, display_order) VALUES
('Standard Delivery', 'التوصيل العادي', 'Delivery within 3-5 business days', 'التوصيل خلال 3-5 أيام عمل', 50.00, '3-5 days', true, 1),
('Express Delivery', 'التوصيل السريع', 'Delivery within 1-2 business days', 'التوصيل خلال 1-2 يوم عمل', 100.00, '1-2 days', true, 2),
('Same Day Delivery', 'التوصيل في نفس اليوم', 'Delivery on the same day (Cairo only)', 'التوصيل في نفس اليوم (القاهرة فقط)', 150.00, 'Same day', true, 3)
ON CONFLICT DO NOTHING;

-- ============================================
-- CATEGORIES
-- ============================================
INSERT INTO categories (name, name_ar, slug, description, description_ar, is_active, display_order) VALUES
('Learning Toys', 'ألعاب تعليمية', 'learning-toys', 'Educational toys for children', 'ألعاب تعليمية للأطفال', true, 1),
('Books & Reading', 'كتب وقراءة', 'books-reading', 'Educational books and reading materials', 'كتب ومواد قراءة تعليمية', true, 2),
('Art & Crafts', 'فنون وحرف', 'art-crafts', 'Art supplies and craft materials', 'مستلزمات فنية ومواد حرفية', true, 3),
('STEM Kits', 'مجموعات العلوم', 'stem-kits', 'Science, Technology, Engineering, Math kits', 'مجموعات العلوم والتكنولوجيا والهندسة والرياضيات', true, 4),
('Puzzles & Games', 'ألغاز وألعاب', 'puzzles-games', 'Educational puzzles and board games', 'ألغاز وألعاب لوحية تعليمية', true, 5)
ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Settings have been populated with default values
-- You can update these values through the admin dashboard
