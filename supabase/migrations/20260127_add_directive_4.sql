-- Add directive_4 to about_content table
INSERT INTO about_content (
    section_key,
    title,
    title_ar,
    content,
    content_ar,
    icon,
    display_order,
    is_active
) VALUES (
    'directive_4',
    'Precision Engineering',
    'هندسة دقيقة',
    'Every component is carefully selected and tested to ensure optimal performance and reliability.',
    'يتم اختبار كل مكون بعناية لضمان الأداء الأمثل والموثوقية.',
    'Terminal',
    7,
    true
)
ON CONFLICT (section_key) DO NOTHING;
