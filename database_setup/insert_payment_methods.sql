-- Clear existing test payment methods and insert proper ones
DELETE FROM payment_methods WHERE code = 'adsfghgf';

-- Insert Cash on Delivery (COD)
INSERT INTO payment_methods (
    id,
    name,
    name_ar,
    code,
    description,
    description_ar,
    type,
    is_active,
    is_enabled,
    display_order,
    additional_fee_value,
    additional_fee_type,
    payment_instructions,
    payment_instructions_ar,
    test_mode
) VALUES (
    gen_random_uuid(),
    'Cash on Delivery',
    'الدفع عند الاستلام',
    'cod',
    'Pay with cash when your order is delivered',
    'ادفع نقدًا عند تسليم طلبك',
    'offline',
    true,
    true,
    1,
    0,
    'fixed',
    'Please have the exact amount ready when the delivery arrives.',
    'يرجى تجهيز المبلغ الدقيق عند وصول التوصيل.',
    false
) ON CONFLICT (id) DO NOTHING;

-- Insert Stripe (for online payments)
INSERT INTO payment_methods (
    id,
    name,
    name_ar,
    code,
    description,
    description_ar,
    type,
    is_active,
    is_enabled,
    display_order,
    additional_fee_value,
    additional_fee_type,
    requires_billing_address,
    requires_phone,
    payment_instructions,
    payment_instructions_ar,
    test_mode
) VALUES (
    gen_random_uuid(),
    'Credit/Debit Card',
    'بطاقة ائتمان/خصم',
    'stripe',
    'Pay securely with your credit or debit card',
    'ادفع بأمان باستخدام بطاقتك الائتمانية أو بطاقة الخصم',
    'online',
    true,
    true,
    2,
    0,
    'percentage',
    true,
    true,
    'You will be redirected to a secure payment page.',
    'سيتم توجيهك إلى صفحة دفع آمنة.',
    true
) ON CONFLICT (id) DO NOTHING;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
