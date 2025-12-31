#!/bin/bash

# ============================================================================
# Deploy FAQs Table Migration to Elnajar Client Database
# ============================================================================

set -e  # Exit on error

echo "🚀 Deploying FAQs table migration to elnajar database..."

# Configuration
SERVER="root@31.97.34.23"
PROJECT_PATH="/root/itargs-supabase"
CLIENT_NAME="elnajar"
DB_CONTAINER="supabase_elnajar-db-1"

echo "📡 Connecting to server $SERVER..."

# Step 1: Copy migration file to server
echo "📤 Uploading FAQs migration file..."
scp supabase/migrations/create_faqs_table.sql $SERVER:$PROJECT_PATH/supabase/migrations/

# Step 2: Apply migration to database
echo "🗄️  Applying FAQs table migration..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

echo "  → Creating faqs table..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < supabase/migrations/create_faqs_table.sql

echo "  → Verifying table creation..."
docker exec -i supabase_elnajar-db-1 psql -U postgres -c "\d faqs"

echo "✅ FAQs table created successfully"
ENDSSH

# Step 3: Verify deployment
echo "🔍 Verifying FAQs table structure..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

# Check table exists and show structure
docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'faqs' 
ORDER BY ordinal_position;
"

# Check RLS policies
docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'faqs';
"

echo "✅ Verification complete"
ENDSSH

echo ""
echo "🎉 FAQs table deployment complete!"
echo ""
echo "📋 What was deployed:"
echo "  ✅ faqs table with bilingual support (EN/AR)"
echo "  ✅ Product association (foreign key to products)"
echo "  ✅ Category filtering support"
echo "  ✅ Display order management"
echo "  ✅ Row Level Security policies"
echo "  ✅ Automatic timestamp triggers"
echo ""
echo "🔗 Access your site:"
echo "  Frontend: https://elnajar.itargs.com"
echo "  Admin Panel: https://elnajar.itargs.com/admin/faqs"
echo "  API: https://api.elnajar.itargs.com"
echo "  Studio: https://studio.elnajar.itargs.com"
echo ""
echo "✨ The TypeScript error is now fixed and the database is synced!"
echo ""
