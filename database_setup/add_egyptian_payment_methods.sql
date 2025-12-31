-- Add Egyptian Payment Methods to Existing System
-- This adds Vodafone Cash, InstaPay, and Fawry to the existing payment_methods table
-- NO SCHEMA CHANGES - Works with existing architecture

-- Insert Vodafone Cash
INSERT INTO payment_methods (
  name,
  name_ar,
  description,
  description_ar,
  type,
  code,
  is_active,
  is_enabled,
  display_order,
  icon,
  sandbox_mode,
  additional_fee_type,
  additional_fee_value
) VALUES (
  'Vodafone Cash',
  'فودافون كاش',
  'Pay using Vodafone Cash mobile wallet',
  'ادفع باستخدام محفظة فودافون كاش',
  'mobile_wallet',
  'vodafone_cash',
  true,
  true,
  4,
  '📱',
  true,
  'fixed',
  0
) ON CONFLICT DO NOTHING;

-- Insert InstaPay
INSERT INTO payment_methods (
  name,
  name_ar,
  description,
  description_ar,
  type,
  code,
  is_active,
  is_enabled,
  display_order,
  icon,
  sandbox_mode,
  additional_fee_type,
  additional_fee_value
) VALUES (
  'InstaPay',
  'إنستا باي',
  'Instant bank transfer via InstaPay',
  'تحويل بنكي فوري عبر إنستا باي',
  'instant_transfer',
  'instapay',
  true,
  true,
  5,
  '⚡',
  true,
  'fixed',
  0
) ON CONFLICT DO NOTHING;

-- Insert Fawry
INSERT INTO payment_methods (
  name,
  name_ar,
  description,
  description_ar,
  type,
  code,
  is_active,
  is_enabled,
  display_order,
  icon,
  sandbox_mode,
  additional_fee_type,
  additional_fee_value
) VALUES (
  'Fawry',
  'فوري',
  'Pay at any Fawry location or online',
  'ادفع في أي فرع فوري أو عبر الإنترنت',
  'payment_gateway',
  'fawry',
  true,
  true,
  6,
  '🏪',
  true,
  'fixed',
  0
) ON CONFLICT DO NOTHING;

-- Verify the new payment methods
SELECT id, name, name_ar, code, type, is_active, is_enabled, display_order, icon
FROM payment_methods
ORDER BY display_order;

COMMIT;
