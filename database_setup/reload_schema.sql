-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';

-- Verify the columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('short_description', 'short_description_ar');
