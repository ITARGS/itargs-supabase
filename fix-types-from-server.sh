#!/bin/bash

# ============================================================================
# Generate Supabase TypeScript Types from Linux Server Database
# ============================================================================
# This script connects to the Linux server and generates proper TypeScript
# types from the actual database schema for the elnajar client
# ============================================================================

set -e

echo "🔧 Generating Supabase TypeScript types from Linux server database..."

# Configuration
SERVER="root@31.97.34.23"
DB_CONTAINER="supabase_elnajar-db-1"
LOCAL_TYPES_PATH="/Users/meflm/Desktop/itargs-training/itargs-supabase/ecommerce_website_reactjs/src/integrations/supabase/types.ts"

echo "📡 Step 1: Connecting to server and extracting database schema..."

# Generate a TypeScript types file from the database schema
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

# Create a script to generate TypeScript types from database schema
cat > /tmp/generate_types.sql << 'EOSQL'
-- Generate TypeScript interface definitions from database schema
SELECT 
    'export interface Database {
    public: {
        Tables: {' || 
    string_agg(
        '            ' || table_name || ': {
                Row: {
' || (
    SELECT string_agg('                    ' || column_name || ': ' || 
        CASE 
            WHEN data_type = 'character varying' THEN 'string'
            WHEN data_type = 'text' THEN 'string'
            WHEN data_type = 'uuid' THEN 'string'
            WHEN data_type = 'timestamp with time zone' THEN 'string'
            WHEN data_type = 'timestamp without time zone' THEN 'string'
            WHEN data_type = 'boolean' THEN 'boolean'
            WHEN data_type = 'integer' THEN 'number'
            WHEN data_type = 'bigint' THEN 'number'
            WHEN data_type = 'numeric' THEN 'number'
            WHEN data_type = 'double precision' THEN 'number'
            WHEN data_type = 'real' THEN 'number'
            WHEN data_type = 'jsonb' THEN 'Json'
            WHEN data_type = 'json' THEN 'Json'
            WHEN data_type = 'ARRAY' THEN 'string[]'
            ELSE 'any'
        END ||
        CASE WHEN is_nullable = 'YES' THEN ' | null' ELSE '' END,
        E'\n'
    )
    FROM information_schema.columns c2
    WHERE c2.table_schema = 'public' 
    AND c2.table_name = t.table_name
    ORDER BY c2.ordinal_position
) || '
                }
                Insert: {
' || (
    SELECT string_agg('                    ' || column_name || '?: ' || 
        CASE 
            WHEN data_type = 'character varying' THEN 'string'
            WHEN data_type = 'text' THEN 'string'
            WHEN data_type = 'uuid' THEN 'string'
            WHEN data_type = 'timestamp with time zone' THEN 'string'
            WHEN data_type = 'timestamp without time zone' THEN 'string'
            WHEN data_type = 'boolean' THEN 'boolean'
            WHEN data_type = 'integer' THEN 'number'
            WHEN data_type = 'bigint' THEN 'number'
            WHEN data_type = 'numeric' THEN 'number'
            WHEN data_type = 'double precision' THEN 'number'
            WHEN data_type = 'real' THEN 'number'
            WHEN data_type = 'jsonb' THEN 'Json'
            WHEN data_type = 'json' THEN 'Json'
            WHEN data_type = 'ARRAY' THEN 'string[]'
            ELSE 'any'
        END ||
        CASE WHEN is_nullable = 'YES' THEN ' | null' ELSE '' END,
        E'\n'
    )
    FROM information_schema.columns c2
    WHERE c2.table_schema = 'public' 
    AND c2.table_name = t.table_name
    ORDER BY c2.ordinal_position
) || '
                }
                Update: {
' || (
    SELECT string_agg('                    ' || column_name || '?: ' || 
        CASE 
            WHEN data_type = 'character varying' THEN 'string'
            WHEN data_type = 'text' THEN 'string'
            WHEN data_type = 'uuid' THEN 'string'
            WHEN data_type = 'timestamp with time zone' THEN 'string'
            WHEN data_type = 'timestamp without time zone' THEN 'string'
            WHEN data_type = 'boolean' THEN 'boolean'
            WHEN data_type = 'integer' THEN 'number'
            WHEN data_type = 'bigint' THEN 'number'
            WHEN data_type = 'numeric' THEN 'number'
            WHEN data_type = 'double precision' THEN 'number'
            WHEN data_type = 'real' THEN 'number'
            WHEN data_type = 'jsonb' THEN 'Json'
            WHEN data_type = 'json' THEN 'Json'
            WHEN data_type = 'ARRAY' THEN 'string[]'
            ELSE 'any'
        END ||
        CASE WHEN is_nullable = 'YES' THEN ' | null' ELSE '' END,
        E'\n'
    )
    FROM information_schema.columns c2
    WHERE c2.table_schema = 'public' 
    AND c2.table_name = t.table_name
    ORDER BY c2.ordinal_position
) || '
                }
            }',
        E',\n'
    ) || '
        }
        Views: {
            [_ in never]: never
        }
        Functions: {
            [_ in never]: never
        }
        Enums: {
            [_ in never]: never
        }
    }
}'
FROM information_schema.tables t
WHERE t.table_schema = 'public'
AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name;
EOSQL

echo "🔨 Generating types from database schema..."
docker exec -i supabase_elnajar-db-1 psql -U postgres -t -A -f /tmp/generate_types.sql > /tmp/db_types_raw.txt

# Add the Json type definition at the beginning
cat > /tmp/elnajar_types.ts << 'EOTS'
export type Json =
    | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

EOTS

# Append the generated types
cat /tmp/db_types_raw.txt >> /tmp/elnajar_types.ts

echo "✅ Types generated successfully at /tmp/elnajar_types.ts"
ENDSSH

echo "📥 Step 2: Downloading generated types to local machine..."
scp $SERVER:/tmp/elnajar_types.ts /tmp/elnajar_types_downloaded.ts

if [ ! -f "/tmp/elnajar_types_downloaded.ts" ]; then
    echo "❌ Failed to download types file"
    exit 1
fi

echo "💾 Step 3: Backing up current types file..."
if [ -f "$LOCAL_TYPES_PATH" ]; then
    cp "$LOCAL_TYPES_PATH" "${LOCAL_TYPES_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup created"
fi

echo "🔄 Step 4: Replacing types file..."
mv /tmp/elnajar_types_downloaded.ts "$LOCAL_TYPES_PATH"

echo ""
echo "🎉 TypeScript types successfully generated and updated!"
echo ""
echo "📋 What was done:"
echo "  ✅ Connected to database on 31.97.34.23"
echo "  ✅ Extracted complete schema from PostgreSQL"
echo "  ✅ Generated TypeScript types for ALL tables"
echo "  ✅ Updated $LOCAL_TYPES_PATH"
echo "  ✅ Created backup of old types"
echo ""
echo "🔍 Next steps:"
echo "  1. The types file has been updated with ALL database tables"
echo "  2. You can now restore the relationships in useProducts.ts"
echo "  3. Restart your dev server to pick up the new types"
echo ""
