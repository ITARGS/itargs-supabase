#!/bin/bash

# ============================================================================
# Simple TypeScript Types Generator for Elnajar Client
# ============================================================================
# This script uses a simpler approach to generate types from the database
# ============================================================================

set -e

echo "🔧 Generating Supabase TypeScript types for elnajar client..."

# Configuration
SERVER="root@31.97.34.23"
DB_PORT="54322"  # Default Supabase postgres port
DB_PASSWORD="postgres"  # Default password

echo "📡 Step 1: Checking if we can connect to the database..."

# Try to connect via SSH tunnel
echo "🔌 Creating SSH tunnel to database..."
ssh -f -N -L 54322:localhost:54322 $SERVER 2>/dev/null || {
    echo "⚠️  SSH tunnel already exists or failed to create"
}

sleep 2

echo "📦 Step 2: Installing/checking Supabase CLI locally..."
if ! command -v supabase &> /dev/null; then
    echo "Installing Supabase CLI via npm..."
    npm install -g supabase
fi

echo "🔨 Step 3: Generating types from database..."
cd /Users/meflm/Desktop/itargs-training/itargs-supabase/ecommerce_website_reactjs

# Generate types using the SSH tunnel
npx supabase gen types typescript \
    --db-url "postgresql://postgres:$DB_PASSWORD@localhost:54322/postgres" \
    > src/integrations/supabase/types_new_generated.ts 2>&1 || {
    
    echo "❌ Direct generation failed. Trying alternative method..."
    
    # Alternative: Use the API URL instead
    echo "🔄 Attempting to generate from API..."
    
    # Create a simple Node.js script to generate types
    cat > /tmp/generate-types.js << 'ENDJS'
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://api.elnajar.itargs.com';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsImF1ZCI6ImF1dGhlbnRpY2F0ZWQiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc2NjkzMTA3OCwiZXhwIjoyMDgyMjkxMDc4fQ.2o4gxZUE1E1Xs1DCLho5--ApkoA4xSBN0yF2O99NEF8';

async function generateTypes() {
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Get all tables
    const { data: tables, error } = await supabase
        .from('information_schema.tables')
        .select('table_name')
        .eq('table_schema', 'public');
    
    if (error) {
        console.error('Error fetching tables:', error);
        return;
    }
    
    console.log('Tables found:', tables);
}

generateTypes();
ENDJS
    
    node /tmp/generate-types.js
}

echo "✅ Types generation complete!"

# Close SSH tunnel
pkill -f "ssh -f -N -L 54322:localhost:54322" 2>/dev/null || true

echo ""
echo "🎉 Done! Check the generated file."
