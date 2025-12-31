-- Clear existing test shipping methods and insert proper ones
DELETE FROM shipping_methods WHERE code = 'dasfgfh';

-- Insert Standard Shipping
INSERT INTO shipping_methods (
    id,
    name,
    name_ar,
    code,
    description,
    description_ar,
    base_cost,
    estimated_days_min,
    estimated_days_max,
    is_enabled,
    display_order,
    free_shipping_threshold
) VALUES (
    gen_random_uuid(),
    'Standard Shipping',
    'الشحن القياسي',
    'standard',
    'Delivery within 3-5 business days',
    'التوصيل خلال 3-5 أيام عمل',
    5.00,
    3,
    5,
    true,
    1,
    50.00
) ON CONFLICT (id) DO NOTHING;

-- Insert Express Shipping
INSERT INTO shipping_methods (
    id,
    name,
    name_ar,
    code,
    description,
    description_ar,
    base_cost,
    estimated_days_min,
    estimated_days_max,
    is_enabled,
    display_order,
    free_shipping_threshold
) VALUES (
    gen_random_uuid(),
    'Express Shipping',
    'الشحن السريع',
    'express',
    'Delivery within 1-2 business days',
    'التوصيل خلال 1-2 أيام عمل',
    15.00,
    1,
    2,
    true,
    2,
    100.00
) ON CONFLICT (id) DO NOTHING;

-- Insert Free Shipping
INSERT INTO shipping_methods (
    id,
    name,
    name_ar,
    code,
    description,
    description_ar,
    base_cost,
    estimated_days_min,
    estimated_days_max,
    is_enabled,
    display_order,
    free_shipping_threshold
) VALUES (
    gen_random_uuid(),
    'Free Shipping',
    'الشحن المجاني',
    'free',
    'Free delivery on orders over $100',
    'توصيل مجاني للطلبات التي تزيد عن 100 دولار',
    0.00,
    5,
    7,
    true,
    3,
    100.00
) ON CONFLICT (id) DO NOTHING;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
