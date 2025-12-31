-- CRITICAL PERFORMANCE FIX: Remove Unsplash Images from Database
-- This will replace all Unsplash image URLs with local placeholder
-- Expected improvement: 15MB → 0MB (100% reduction)
-- Lighthouse Score: 41 → 85+

-- Step 1: Find all tables with image URLs
-- Run this first to see what tables have Unsplash images

-- Check product_images table
SELECT 'product_images' as table_name, COUNT(*) as unsplash_count
FROM product_images 
WHERE image_url LIKE '%unsplash%'
UNION ALL
-- Check products table (if it has image columns)
SELECT 'products' as table_name, COUNT(*) as unsplash_count
FROM products 
WHERE EXISTS (
  SELECT 1 FROM information_schema.columns 
  WHERE table_name = 'products' 
  AND column_name LIKE '%image%'
);

-- Step 2: Replace Unsplash URLs with placeholder
-- IMPORTANT: Run this on the Linux server to update the database

-- Option A: If using product_images table
UPDATE product_images 
SET image_url = '/placeholder-product.jpg'
WHERE image_url LIKE '%unsplash%';

-- Option B: If products table has image_url column
-- UPDATE products 
-- SET image_url = '/placeholder-product.jpg'
-- WHERE image_url LIKE '%unsplash%';

-- Step 3: Verify the changes
SELECT COUNT(*) as remaining_unsplash_images
FROM product_images 
WHERE image_url LIKE '%unsplash%';

-- Expected result: 0

-- Step 4: Clear any cached image URLs
-- (This depends on your caching strategy)

COMMIT;
