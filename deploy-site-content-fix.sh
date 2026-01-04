#!/bin/bash

# ============================================================================
# Deploy Site Content RLS Fix to Elnajar Linux Server
# ============================================================================
# This script deploys the RLS policy fixes for 8 site content tables
# to the production Supabase database running on the Linux server.
# ============================================================================

set -e  # Exit on error

echo "🚀 Starting RLS fix deployment to Elnajar server..."
echo ""

# Configuration
SERVER="root@31.97.34.23"
PROJECT_PATH="/root/itargs-supabase"
DB_CONTAINER="supabase_elnajar-db-1"
SQL_FILE="database_setup/fix_site_content_rls.sql"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📡 Connecting to server: ${SERVER}${NC}"
echo ""

# Step 1: Upload the SQL fix file
echo -e "${YELLOW}📤 Uploading SQL fix file...${NC}"
scp database_setup/fix_site_content_rls.sql ${SERVER}:${PROJECT_PATH}/database_setup/
echo -e "${GREEN}✅ File uploaded successfully${NC}"
echo ""

# Step 2: Execute the SQL fix
echo -e "${YELLOW}🗄️  Applying RLS policy fixes...${NC}"
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

echo "Executing fix_site_content_rls.sql..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < database_setup/fix_site_content_rls.sql

echo ""
echo "✅ SQL fix executed successfully"
ENDSSH

echo ""
echo -e "${GREEN}✅ RLS policies updated on server${NC}"
echo ""

# Step 3: Verify the deployment
echo -e "${YELLOW}🔍 Verifying deployment...${NC}"
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

echo "Checking updated policies..."
docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
SELECT 
  tablename,
  policyname
FROM pg_policies
WHERE tablename IN (
  'nav_links', 
  'footer_links', 
  'social_links', 
  'hero_sections', 
  'trust_badges', 
  'about_content', 
  'use_cases', 
  'working_hours'
)
AND policyname LIKE 'admin_full_access%'
ORDER BY tablename;
"

echo ""
echo "Verifying admin user..."
docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
SELECT email, role 
FROM public.profiles 
WHERE email = 'admin@elnajar.itargs.com';
"

echo ""
echo "✅ Verification complete"
ENDSSH

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "  ✅ nav_links - Navigation menu management"
echo "  ✅ footer_links - Footer links management"
echo "  ✅ social_links - Social media links management"
echo "  ✅ hero_sections - Homepage hero content management"
echo "  ✅ trust_badges - Trust/SLA badges management"
echo "  ✅ about_content - About page content management"
echo "  ✅ use_cases - Product use cases management"
echo "  ✅ working_hours - Store hours management"
echo ""
echo -e "${BLUE}🔗 Test your admin panel:${NC}"
echo "  Frontend: https://elnajar.itargs.com/admin"
echo "  Local: http://localhost:8080/admin"
echo ""
echo -e "${BLUE}👤 Admin credentials:${NC}"
echo "  Email: admin@elnajar.itargs.com"
echo "  Password: Admin@Elnajar2025"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  1. Login to admin panel"
echo "  2. Try editing navigation links, footer links, etc."
echo "  3. Verify no more 'permission denied' errors"
echo ""
