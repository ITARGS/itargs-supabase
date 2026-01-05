#!/bin/bash

# ============================================================================
# Generate Supabase TypeScript Types - CORRECTED
# ============================================================================

set -e

echo "🔧 Generating Supabase TypeScript types from database..."

SERVER="root@31.97.34.23"
DB_CONTAINER="supabase_elnajar-db-1"

# Initialize the types file
cat > /tmp/elnajar_types.ts << 'EOF'
export type Json =
    | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

export interface Database {
    public: {
        Tables: {
EOF

# Get list of tables
echo "📡 Getting table list..."
TABLES=$(ssh $SERVER "docker exec -i $DB_CONTAINER psql -U postgres -t -c \"SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY table_name;\"")

echo "$TABLES" | while read -r table; do
    # Skip empty lines
    if [ -z "$table" ]; then
        continue
    fi
    table=$(echo "$table" | xargs)
    echo "  Processing table: $table"

    # Append table header
    echo "            $table: {" >> /tmp/elnajar_types.ts
    echo "                Row: {" >> /tmp/elnajar_types.ts
    
    # Get columns with types
    # We output format: column_name|data_type|is_nullable
    COLUMNS=$(ssh -n $SERVER "docker exec -i $DB_CONTAINER psql -U postgres -t -c \"
        SELECT 
            column_name || '|' || data_type || '|' || is_nullable
        FROM information_schema.columns 
        WHERE table_schema='public' AND table_name='$table'
        ORDER BY ordinal_position;
    \"")

    # Function to map postgres type to TS type
    map_type() {
        local type=$1
        case "$type" in
            "character varying"|"text"|"uuid"|"timestamp with time zone"|"timestamp without time zone"|"date"|"time without time zone") echo "string" ;;
            "boolean") echo "boolean" ;;
            "integer"|"bigint"|"numeric"|"double precision"|"real"|"smallint") echo "number" ;;
            "jsonb"|"json") echo "Json" ;;
            "ARRAY") echo "string[]" ;; # Simplified
            *) echo "any" ;;
        esac
    }

    # Generate Row
    echo "$COLUMNS" | while read -r line; do
        if [ -z "$line" ]; then continue; fi
        col_name=$(echo "$line" | cut -d'|' -f1 | xargs)
        data_type=$(echo "$line" | cut -d'|' -f2 | xargs)
        is_null=$(echo "$line" | cut -d'|' -f3 | xargs)
        
        ts_type=$(map_type "$data_type")
        
        if [ "$is_null" = "YES" ]; then
            echo "                    $col_name: $ts_type | null" >> /tmp/elnajar_types.ts
        else
            echo "                    $col_name: $ts_type" >> /tmp/elnajar_types.ts
        fi
    done
    echo "                }" >> /tmp/elnajar_types.ts

    # Generate Insert (all optional for simplicity in this generated script, or better logic?)
    # For now, let's make nullable fields optional, and ID optional
    echo "                Insert: {" >> /tmp/elnajar_types.ts
    echo "$COLUMNS" | while read -r line; do
        if [ -z "$line" ]; then continue; fi
        col_name=$(echo "$line" | cut -d'|' -f1 | xargs)
        data_type=$(echo "$line" | cut -d'|' -f2 | xargs)
        is_null=$(echo "$line" | cut -d'|' -f3 | xargs)
        
        ts_type=$(map_type "$data_type")
        
        # Make id and nullable fields optional
        if [ "$col_name" = "id" ] || [ "$is_null" = "YES" ]; then
            echo "                    $col_name?: $ts_type | null" >> /tmp/elnajar_types.ts
        else
            echo "                    $col_name: $ts_type" >> /tmp/elnajar_types.ts
        fi
    done
    echo "                }" >> /tmp/elnajar_types.ts

    # Generate Update (all optional)
    echo "                Update: {" >> /tmp/elnajar_types.ts
    echo "$COLUMNS" | while read -r line; do
        if [ -z "$line" ]; then continue; fi
        col_name=$(echo "$line" | cut -d'|' -f1 | xargs)
        data_type=$(echo "$line" | cut -d'|' -f2 | xargs)
        is_null=$(echo "$line" | cut -d'|' -f3 | xargs)
        
        ts_type=$(map_type "$data_type")
        
        echo "                    $col_name?: $ts_type | null" >> /tmp/elnajar_types.ts
    done
    echo "                }" >> /tmp/elnajar_types.ts
    
    echo "            }" >> /tmp/elnajar_types.ts

done

# Close the file
cat >> /tmp/elnajar_types.ts << 'EOF'
            [key: string]: any
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
}
EOF

echo "💾 Installing new types file..."
LOCAL_TYPES_PATH="/Users/meflm/Desktop/itargs-training/itargs-supabase/ecommerce_website_reactjs/src/integrations/supabase/types.ts"
cp /tmp/elnajar_types.ts "$LOCAL_TYPES_PATH"

echo "✅ Done! Types generated for $(echo "$TABLES" | wc -l) tables."
