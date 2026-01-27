-- Create FAQ items table
CREATE TABLE IF NOT EXISTS faq_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question TEXT NOT NULL,
  question_ar TEXT NOT NULL,
  answer TEXT NOT NULL,
  answer_ar TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE faq_items ENABLE ROW LEVEL SECURITY;

-- Policy: FAQ items are viewable by everyone (only active ones)
CREATE POLICY "FAQ items are viewable by everyone"
  ON faq_items FOR SELECT
  USING (is_active = true);

-- Policy: FAQ items are manageable by admins
CREATE POLICY "FAQ items are manageable by admins"
  ON faq_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create index for ordering
CREATE INDEX IF NOT EXISTS idx_faq_items_display_order ON faq_items(display_order);

-- Insert sample FAQ items
INSERT INTO faq_items (question, question_ar, answer, answer_ar, display_order) VALUES
('What are your shipping options?', 'ما هي خيارات الشحن المتاحة؟', 'We offer standard and express shipping options. Standard shipping takes 3-5 business days, while express shipping takes 1-2 business days.', 'نوفر خيارات الشحن القياسي والسريع. يستغرق الشحن القياسي من 3 إلى 5 أيام عمل، بينما يستغرق الشحن السريع من يوم إلى يومين عمل.', 1),
('How can I track my order?', 'كيف يمكنني تتبع طلبي؟', 'Once your order ships, you will receive a tracking number via email. You can use this number to track your package on our website or the carrier''s website.', 'بمجرد شحن طلبك، ستتلقى رقم تتبع عبر البريد الإلكتروني. يمكنك استخدام هذا الرقم لتتبع الطرد على موقعنا أو موقع شركة الشحن.', 2),
('What is your return policy?', 'ما هي سياسة الإرجاع؟', 'We accept returns within 30 days of purchase. Items must be unused and in original packaging. Please contact our support team to initiate a return.', 'نقبل الإرجاع خلال 30 يومًا من الشراء. يجب أن تكون المنتجات غير مستخدمة وفي عبوتها الأصلية. يرجى الاتصال بفريق الدعم لبدء عملية الإرجاع.', 3),
('Do you offer international shipping?', 'هل تقدمون الشحن الدولي؟', 'Yes, we ship to most countries worldwide. Shipping costs and delivery times vary by destination.', 'نعم، نشحن إلى معظم الدول حول العالم. تختلف تكاليف الشحن وأوقات التسليم حسب الوجهة.', 4),
('How do I contact customer support?', 'كيف أتواصل مع خدمة العملاء؟', 'You can reach our customer support team via email, phone, or live chat. Visit our Contact page for more details.', 'يمكنك التواصل مع فريق خدمة العملاء عبر البريد الإلكتروني أو الهاتف أو الدردشة المباشرة. قم بزيارة صفحة الاتصال لمزيد من التفاصيل.', 5);
