#!/bin/bash

# ============================================================================
# Sync Database Updates to Elnajar Production Server
# ============================================================================
# This script applies pending database migrations from fix/elnajar_version_4
# to the production elnajar database on Linux server 31.97.34.23
# ============================================================================

set -e  # Exit on error

echo "🚀 Starting database synchronization for elnajar client..."
echo ""

# Configuration
SERVER="root@31.97.34.23"
PROJECT_PATH="/root/itargs-supabase"
CLIENT_NAME="elnajar"
DB_CONTAINER="supabase_elnajar-db-1"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Migration files in order
MIGRATIONS=(
    "add_hero_sections.sql"
    "add_trust_badges.sql"
    "add_about_content.sql"
    "add_nav_links.sql"
    "add_footer_links.sql"
    "add_working_hours.sql"
    "add_discount_codes_localization.sql"
    "fix_product_performance_tiers_rls.sql"
    "fix_site_content_rls.sql"
)

echo "📋 Migration Plan:"
echo "   Total migrations: ${#MIGRATIONS[@]}"
echo "   Database container: $DB_CONTAINER"
echo "   Server: $SERVER"
echo ""

# Function to apply a single migration
apply_migration() {
    local migration=$1
    local index=$2
    local total=$3
    
    echo -e "${YELLOW}[$index/$total]${NC} Applying: $migration"
    
    ssh $SERVER << ENDSSH
        cd $PROJECT_PATH
        
        # Check if container is running
        if ! docker ps | grep -q $DB_CONTAINER; then
            echo "❌ Error: Database container is not running"
            exit 1
        fi
        
        # Apply migration
        if docker exec -i $DB_CONTAINER psql -U postgres < database_setup/$migration 2>&1; then
            echo "✅ Success: $migration"
        else
            echo "❌ Failed: $migration"
            exit 1
        fi
ENDSSH
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Completed: $migration${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Failed: $migration${NC}"
        return 1
    fi
}

# Pre-flight checks
echo "🔍 Running pre-flight checks..."
ssh $SERVER << 'ENDSSH'
    # Check if project directory exists
    if [ ! -d /root/itargs-supabase ]; then
        echo "❌ Error: Project directory not found"
        exit 1
    fi
    
    # Check if database container is running
    if ! docker ps | grep -q supabase_elnajar-db-1; then
        echo "❌ Error: Database container is not running"
        echo "   Run: cd /root/itargs-supabase/clients/elnajar && docker-compose up -d"
        exit 1
    fi
    
    echo "✅ Pre-flight checks passed"
ENDSSH

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Pre-flight checks failed. Aborting.${NC}"
    exit 1
fi

echo ""
echo "🗄️  Applying migrations..."
echo ""

# Apply each migration
TOTAL=${#MIGRATIONS[@]}
SUCCESS_COUNT=0
FAILED_COUNT=0

for i in "${!MIGRATIONS[@]}"; do
    INDEX=$((i + 1))
    MIGRATION="${MIGRATIONS[$i]}"
    
    if apply_migration "$MIGRATION" "$INDEX" "$TOTAL"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        echo -e "${RED}❌ Migration failed. Stopping deployment.${NC}"
        break
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Migration Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "   Total migrations: $TOTAL"
echo -e "   ${GREEN}Successful: $SUCCESS_COUNT${NC}"
echo -e "   ${RED}Failed: $FAILED_COUNT${NC}"
echo ""

if [ $FAILED_COUNT -eq 0 ]; then
    echo "🔍 Running verification checks..."
    echo ""
    
    # Verification queries
    ssh $SERVER << 'ENDSSH'
        cd /root/itargs-supabase
        
        echo "📋 Verifying new tables..."
        docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN ('about_content', 'hero_sections', 'trust_badges', 
                              'nav_links', 'footer_links', 'social_links', 'working_hours')
            ORDER BY table_name;
        "
        
        echo ""
        echo "📋 Verifying new column..."
        docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
            SELECT column_name, data_type
            FROM information_schema.columns 
            WHERE table_name = 'discount_codes' AND column_name = 'description_ar';
        "
        
        echo ""
        echo "📋 Verifying RLS policies..."
        docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
            SELECT tablename, COUNT(*) as policy_count
            FROM pg_policies 
            WHERE tablename IN ('about_content', 'hero_sections', 'trust_badges', 
                               'nav_links', 'footer_links', 'social_links', 
                               'use_cases', 'working_hours', 'product_performance_tiers')
            GROUP BY tablename
            ORDER BY tablename;
        "
        
        echo ""
        echo "📋 Checking seeded data..."
        docker exec -i supabase_elnajar-db-1 psql -U postgres -c "
            SELECT 
                'about_content' as table_name, COUNT(*) as row_count FROM about_content
            UNION ALL
            SELECT 'hero_sections', COUNT(*) FROM hero_sections
            UNION ALL
            SELECT 'trust_badges', COUNT(*) FROM trust_badges
            UNION ALL
            SELECT 'nav_links', COUNT(*) FROM nav_links
            UNION ALL
            SELECT 'footer_links', COUNT(*) FROM footer_links
            UNION ALL
            SELECT 'social_links', COUNT(*) FROM social_links
            UNION ALL
            SELECT 'working_hours', COUNT(*) FROM working_hours;
        "
ENDSSH
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}🎉 Database synchronization completed successfully!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 What was deployed:"
    echo "   ✅ 6 new site content tables (hero_sections, trust_badges, about_content, etc.)"
    echo "   ✅ 1 schema enhancement (discount_codes localization)"
    echo "   ✅ 2 RLS policy fixes (product_performance_tiers, site content tables)"
    echo ""
    echo "🔗 Next steps:"
    echo "   1. Regenerate TypeScript types: ./regenerate-types-elnajar.sh"
    echo "   2. Test admin dashboard: https://elnajar.itargs.com/admin"
    echo "   3. Verify frontend: https://elnajar.itargs.com"
    echo ""
    echo "🔗 Access your site:"
    echo "   Frontend: https://elnajar.itargs.com"
    echo "   API: https://api.elnajar.itargs.com"
    echo "   Studio: https://studio.elnajar.itargs.com"
    echo ""
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${RED}❌ Database synchronization failed${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  Some migrations failed. Please review the errors above."
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Check database logs: docker logs supabase_elnajar-db-1"
    echo "   2. Verify container is running: docker ps | grep elnajar"
    echo "   3. Check migration file syntax"
    echo "   4. Review RLS policies: docker exec -i supabase_elnajar-db-1 psql -U postgres -c '\dp'"
    echo ""
    exit 1
fi
