-- Create Privacy Policy Versions table
CREATE TABLE IF NOT EXISTS privacy_policy_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL,
  content_ar TEXT NOT NULL,
  version INTEGER GENERATED ALWAYS AS IDENTITY,
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create Terms & Conditions Versions table
CREATE TABLE IF NOT EXISTS terms_conditions_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL,
  content_ar TEXT NOT NULL,
  version INTEGER GENERATED ALWAYS AS IDENTITY,
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE privacy_policy_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE terms_conditions_versions ENABLE ROW LEVEL SECURITY;

-- Grant table permissions
GRANT SELECT ON privacy_policy_versions TO anon;
GRANT ALL ON privacy_policy_versions TO authenticated;
GRANT SELECT ON terms_conditions_versions TO anon;
GRANT ALL ON terms_conditions_versions TO authenticated;

-- Privacy Policy Policies
CREATE POLICY "Anyone can view active privacy policy"
  ON privacy_policy_versions FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

CREATE POLICY "Admins can manage privacy policy"
  ON privacy_policy_versions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Terms & Conditions Policies
CREATE POLICY "Anyone can view active terms"
  ON terms_conditions_versions FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

CREATE POLICY "Admins can manage terms"
  ON terms_conditions_versions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_privacy_policy_active ON privacy_policy_versions(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_terms_conditions_active ON terms_conditions_versions(is_active) WHERE is_active = true;

-- Insert initial Privacy Policy content
INSERT INTO privacy_policy_versions (content, content_ar, is_active) VALUES (
  'Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website or make a purchase from us.

**Information We Collect**

We collect information that you provide directly to us, including:
- Name and contact information
- Billing and shipping addresses
- Payment information
- Order history
- Communication preferences

**How We Use Your Information**

We use the information we collect to:
- Process and fulfill your orders
- Communicate with you about your orders
- Send you marketing communications (with your consent)
- Improve our products and services
- Prevent fraud and enhance security

**Information Sharing**

We do not sell or rent your personal information to third parties. We may share your information with:
- Service providers who assist us in operating our website
- Payment processors
- Shipping companies
- Legal authorities when required by law

**Data Security**

We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

**Your Rights**

You have the right to:
- Access your personal information
- Correct inaccurate information
- Request deletion of your information
- Opt-out of marketing communications
- Lodge a complaint with a supervisory authority

**Cookies**

We use cookies and similar tracking technologies to enhance your browsing experience and analyze website traffic.

**Changes to This Policy**

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page.

**Contact Us**

If you have any questions about this Privacy Policy, please contact us through our contact page.',
  
  'خصوصيتك مهمة بالنسبة لنا. توضح سياسة الخصوصية هذه كيفية جمع معلوماتك واستخدامها والكشف عنها وحمايتها عند زيارة موقعنا الإلكتروني أو إجراء عملية شراء منا.

**المعلومات التي نجمعها**

نجمع المعلومات التي تقدمها لنا مباشرة، بما في ذلك:
- الاسم ومعلومات الاتصال
- عناوين الفواتير والشحن
- معلومات الدفع
- سجل الطلبات
- تفضيلات الاتصال

**كيف نستخدم معلوماتك**

نستخدم المعلومات التي نجمعها من أجل:
- معالجة طلباتك وتنفيذها
- التواصل معك بشأن طلباتك
- إرسال رسائل تسويقية لك (بموافقتك)
- تحسين منتجاتنا وخدماتنا
- منع الاحتيال وتعزيز الأمان

**مشاركة المعلومات**

نحن لا نبيع أو نؤجر معلوماتك الشخصية لأطراف ثالثة. قد نشارك معلوماتك مع:
- مقدمي الخدمات الذين يساعدوننا في تشغيل موقعنا
- معالجي الدفع
- شركات الشحن
- السلطات القانونية عند الطلب بموجب القانون

**أمن البيانات**

نطبق تدابير تقنية وتنظيمية مناسبة لحماية معلوماتك الشخصية من الوصول غير المصرح به أو التعديل أو الكشف أو التدمير.

**حقوقك**

لديك الحق في:
- الوصول إلى معلوماتك الشخصية
- تصحيح المعلومات غير الدقيقة
- طلب حذف معلوماتك
- إلغاء الاشتراك في الرسائل التسويقية
- تقديم شكوى إلى سلطة إشرافية

**ملفات تعريف الارتباط**

نستخدم ملفات تعريف الارتباط وتقنيات التتبع المماثلة لتحسين تجربة التصفح وتحليل حركة المرور على الموقع.

**التغييرات على هذه السياسة**

قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر. سنخطرك بأي تغييرات عن طريق نشر السياسة الجديدة على هذه الصفحة.

**اتصل بنا**

إذا كان لديك أي أسئلة حول سياسة الخصوصية هذه، يرجى الاتصال بنا من خلال صفحة الاتصال الخاصة بنا.',
  
  true
);

-- Insert initial Terms & Conditions content
INSERT INTO terms_conditions_versions (content, content_ar, is_active) VALUES (
  'Please read these Terms and Conditions carefully before using our website or purchasing our products.

**Acceptance of Terms**

By accessing and using this website, you accept and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our website.

**Products and Services**

- All products are subject to availability
- We reserve the right to limit quantities
- Prices are subject to change without notice
- Product descriptions and images are as accurate as possible but may vary

**Orders and Payment**

- All orders are subject to acceptance and availability
- Payment must be received before order processing
- We accept major credit cards and other payment methods as displayed
- You are responsible for providing accurate billing information

**Shipping and Delivery**

- Shipping times are estimates and not guaranteed
- Risk of loss passes to you upon delivery
- We are not responsible for delays caused by shipping carriers
- International orders may be subject to customs fees

**Returns and Refunds**

- Returns must be made within 30 days of purchase
- Items must be unused and in original packaging
- Refunds will be processed within 7-10 business days
- Shipping costs are non-refundable unless the return is due to our error

**Intellectual Property**

All content on this website, including text, graphics, logos, and images, is our property and protected by copyright laws.

**Limitation of Liability**

We are not liable for any indirect, incidental, or consequential damages arising from your use of our website or products.

**Governing Law**

These Terms and Conditions are governed by and construed in accordance with applicable laws.

**Changes to Terms**

We reserve the right to modify these terms at any time. Continued use of the website constitutes acceptance of modified terms.

**Contact Information**

For questions about these Terms and Conditions, please contact us through our contact page.',
  
  'يرجى قراءة هذه الشروط والأحكام بعناية قبل استخدام موقعنا الإلكتروني أو شراء منتجاتنا.

**قبول الشروط**

من خلال الوصول إلى هذا الموقع واستخدامه، فإنك تقبل وتوافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام موقعنا.

**المنتجات والخدمات**

- جميع المنتجات تخضع للتوفر
- نحتفظ بالحق في تحديد الكميات
- الأسعار عرضة للتغيير دون إشعار
- أوصاف المنتجات والصور دقيقة قدر الإمكان ولكن قد تختلف

**الطلبات والدفع**

- جميع الطلبات تخضع للقبول والتوفر
- يجب استلام الدفع قبل معالجة الطلب
- نقبل بطاقات الائتمان الرئيسية وطرق الدفع الأخرى المعروضة
- أنت مسؤول عن تقديم معلومات فواتير دقيقة

**الشحن والتسليم**

- أوقات الشحن تقديرية وغير مضمونة
- تنتقل مخاطر الخسارة إليك عند التسليم
- نحن لسنا مسؤولين عن التأخير الناجم عن شركات الشحن
- قد تخضع الطلبات الدولية لرسوم جمركية

**الإرجاع والاسترداد**

- يجب إجراء الإرجاع خلال 30 يومًا من الشراء
- يجب أن تكون العناصر غير مستخدمة وفي عبوتها الأصلية
- سيتم معالجة المبالغ المستردة خلال 7-10 أيام عمل
- تكاليف الشحن غير قابلة للاسترداد ما لم يكن الإرجاع بسبب خطأ منا

**الملكية الفكرية**

جميع المحتويات الموجودة على هذا الموقع، بما في ذلك النصوص والرسومات والشعارات والصور، هي ملكنا ومحمية بموجب قوانين حقوق النشر.

**تحديد المسؤولية**

نحن غير مسؤولين عن أي أضرار غير مباشرة أو عرضية أو تبعية ناشئة عن استخدامك لموقعنا أو منتجاتنا.

**القانون الحاكم**

تخضع هذه الشروط والأحكام وتفسر وفقًا للقوانين المعمول بها.

**التغييرات على الشروط**

نحتفظ بالحق في تعديل هذه الشروط في أي وقت. يشكل الاستخدام المستمر للموقع قبولًا للشروط المعدلة.

**معلومات الاتصال**

للأسئلة حول هذه الشروط والأحكام، يرجى الاتصال بنا من خلال صفحة الاتصال الخاصة بنا.',
  
  true
);
