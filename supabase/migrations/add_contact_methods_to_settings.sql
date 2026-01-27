-- Add contact method fields to contact_page_settings table
ALTER TABLE contact_page_settings
ADD COLUMN IF NOT EXISTS whatsapp_number TEXT DEFAULT '+201234567890',
ADD COLUMN IF NOT EXISTS phone_number TEXT DEFAULT '+20 123 456 7890',
ADD COLUMN IF NOT EXISTS email_address TEXT DEFAULT 'info@itargs.com',
ADD COLUMN IF NOT EXISTS whatsapp_title TEXT DEFAULT 'WhatsApp',
ADD COLUMN IF NOT EXISTS whatsapp_title_ar TEXT DEFAULT 'واتساب',
ADD COLUMN IF NOT EXISTS whatsapp_subtitle TEXT DEFAULT 'Fastest way to reach us',
ADD COLUMN IF NOT EXISTS whatsapp_subtitle_ar TEXT DEFAULT 'أسرع طريقة للتواصل معنا',
ADD COLUMN IF NOT EXISTS phone_title TEXT DEFAULT 'Phone',
ADD COLUMN IF NOT EXISTS phone_title_ar TEXT DEFAULT 'الهاتف',
ADD COLUMN IF NOT EXISTS phone_subtitle TEXT DEFAULT 'Call us directly',
ADD COLUMN IF NOT EXISTS phone_subtitle_ar TEXT DEFAULT 'اتصل بنا مباشرة',
ADD COLUMN IF NOT EXISTS email_title TEXT DEFAULT 'Email',
ADD COLUMN IF NOT EXISTS email_title_ar TEXT DEFAULT 'البريد الإلكتروني',
ADD COLUMN IF NOT EXISTS email_subtitle TEXT DEFAULT 'Send us an email',
ADD COLUMN IF NOT EXISTS email_subtitle_ar TEXT DEFAULT 'أرسل لنا بريدًا إلكترونيًا';

-- Update existing row with default values
UPDATE contact_page_settings
SET 
  whatsapp_number = COALESCE(whatsapp_number, '+201234567890'),
  phone_number = COALESCE(phone_number, '+20 123 456 7890'),
  email_address = COALESCE(email_address, 'info@itargs.com'),
  whatsapp_title = COALESCE(whatsapp_title, 'WhatsApp'),
  whatsapp_title_ar = COALESCE(whatsapp_title_ar, 'واتساب'),
  whatsapp_subtitle = COALESCE(whatsapp_subtitle, 'Fastest way to reach us'),
  whatsapp_subtitle_ar = COALESCE(whatsapp_subtitle_ar, 'أسرع طريقة للتواصل معنا'),
  phone_title = COALESCE(phone_title, 'Phone'),
  phone_title_ar = COALESCE(phone_title_ar, 'الهاتف'),
  phone_subtitle = COALESCE(phone_subtitle, 'Call us directly'),
  phone_subtitle_ar = COALESCE(phone_subtitle_ar, 'اتصل بنا مباشرة'),
  email_title = COALESCE(email_title, 'Email'),
  email_title_ar = COALESCE(email_title_ar, 'البريد الإلكتروني'),
  email_subtitle = COALESCE(email_subtitle, 'Send us an email'),
  email_subtitle_ar = COALESCE(email_subtitle_ar, 'أرسل لنا بريدًا إلكترونيًا');
