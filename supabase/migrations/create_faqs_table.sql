-- Create FAQs table
CREATE TABLE IF NOT EXISTS public.faqs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    question_ar TEXT,
    answer TEXT NOT NULL,
    answer_ar TEXT,
    category TEXT DEFAULT 'general',
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create index on category for faster filtering
CREATE INDEX IF NOT EXISTS idx_faqs_category ON public.faqs(category);

-- Create index on product_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_faqs_product_id ON public.faqs(product_id);

-- Create index on display_order for sorting
CREATE INDEX IF NOT EXISTS idx_faqs_display_order ON public.faqs(display_order);

-- Enable Row Level Security
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access
CREATE POLICY "Allow public read access to active FAQs"
    ON public.faqs
    FOR SELECT
    USING (is_active = true);

-- Create policy to allow authenticated users to read all FAQs
CREATE POLICY "Allow authenticated users to read all FAQs"
    ON public.faqs
    FOR SELECT
    TO authenticated
    USING (true);

-- Create policy to allow authenticated users to insert FAQs
CREATE POLICY "Allow authenticated users to insert FAQs"
    ON public.faqs
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Create policy to allow authenticated users to update FAQs
CREATE POLICY "Allow authenticated users to update FAQs"
    ON public.faqs
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Create policy to allow authenticated users to delete FAQs
CREATE POLICY "Allow authenticated users to delete FAQs"
    ON public.faqs
    FOR DELETE
    TO authenticated
    USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_faqs_updated_at
    BEFORE UPDATE ON public.faqs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
