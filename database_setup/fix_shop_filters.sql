-- Fix Shop Filters: Populate difficulty_level and use_case for products
-- This ensures the filters in Shop.tsx work correctly

-- Update products with difficulty levels based on their characteristics
UPDATE products 
SET difficulty_level = CASE 
    WHEN base_price > 50000 THEN 'advanced'
    WHEN base_price > 20000 THEN 'intermediate'
    ELSE 'beginner'
END
WHERE difficulty_level IS NULL;

-- Update products with use cases based on their categories
UPDATE products p
SET use_case = CASE 
    WHEN c.name ILIKE '%gaming%' OR c.name ILIKE '%game%' THEN 'gaming'
    WHEN c.name ILIKE '%workstation%' OR c.name ILIKE '%professional%' THEN 'workstation'
    WHEN c.name ILIKE '%server%' THEN 'server'
    WHEN c.name ILIKE '%office%' THEN 'office'
    WHEN c.name ILIKE '%content%' OR c.name ILIKE '%creator%' THEN 'content-creation'
    ELSE 'home'
END
FROM categories c
WHERE p.category_id = c.id AND p.use_case IS NULL;

-- For products without categories, set a default use case
UPDATE products 
SET use_case = 'workstation'
WHERE use_case IS NULL;

-- Verify the updates
SELECT 
    COUNT(*) as total_products,
    COUNT(DISTINCT difficulty_level) as difficulty_levels,
    COUNT(DISTINCT use_case) as use_cases,
    COUNT(CASE WHEN difficulty_level IS NOT NULL THEN 1 END) as products_with_difficulty,
    COUNT(CASE WHEN use_case IS NOT NULL THEN 1 END) as products_with_use_case
FROM products;

-- Show distribution
SELECT difficulty_level, COUNT(*) as count
FROM products
WHERE difficulty_level IS NOT NULL
GROUP BY difficulty_level
ORDER BY difficulty_level;

SELECT use_case, COUNT(*) as count
FROM products
WHERE use_case IS NOT NULL
GROUP BY use_case
ORDER BY use_case;
