#!/bin/bash

# ============================================================================
# Deploy Elnajar Client Updates to Linux Server (31.97.34.23)
# ============================================================================

set -e  # Exit on error

echo "🚀 Starting deployment to elnajar client..."

# Configuration
SERVER="root@31.97.34.23"
PROJECT_PATH="/root/itargs-supabase"
CLIENT_NAME="elnajar"
BRANCH="elnajar-brand-identity"

echo "📡 Connecting to server..."

# Step 1: Pull latest code
echo "📥 Pulling latest code from GitHub..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase
git fetch origin
git checkout elnajar-brand-identity
git pull origin elnajar-brand-identity
echo "✅ Code updated successfully"
ENDSSH

# Step 2: Apply database schema fixes
echo "🗄️  Applying database schema fixes..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

# Apply master sync fix
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/master_sync_fix.sql

# Apply use_cases table migration
echo "📊 Creating use_cases table..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_use_cases.sql

# Add use_case column to products table
echo "🔧 Adding use_case column to products..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_products_use_case_column.sql

# Create hero_sections table
echo "🎨 Creating hero_sections table..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_hero_sections.sql

# Create trust_badges table
echo "⚖️  Creating trust_badges table..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_trust_badges.sql

# Create about_content table
echo "📖 Creating about_content table..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_about_content.sql

# Create footer_links and social_links tables
echo "🔗 Creating footer and social links tables..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_footer_links.sql

# Create nav_links table
echo "🧭 Creating nav_links table..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_nav_links.sql

# Create working_hours table
echo "🕒 Creating working_hours table..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/add_working_hours.sql

echo "✅ Database schema updated successfully"
ENDSSH

# Step 3: Verify deployment
echo "🔍 Verifying deployment..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

# Check if containers are running
docker ps | grep elnajar

echo "✅ Containers are running"
ENDSSH

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📋 What was deployed:"
echo "  ✅ Latest code from elnajar-brand-identity branch"
echo "  ✅ Database schema fixes (master_sync_fix.sql)"
echo "  ✅ Use cases filter table (add_use_cases.sql)"
echo "  ✅ Cart localization support (name_ar, name_en)"
echo "  ✅ Dynamic filter system (Performance Tiers, Workload Types, Categories, Use Cases)"
echo ""
echo "🔗 Access your site:"
echo "  Frontend: https://elnajar.itargs.com"
echo "  API: https://api.elnajar.itargs.com"
echo "  Studio: https://studio.elnajar.itargs.com"
echo ""
