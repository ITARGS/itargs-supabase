#!/bin/bash

# ============================================================================
# Deploy Egyptian Payment Methods to Elnajar Production Server
# ============================================================================

set -e  # Exit on error

echo "💳 Deploying Egyptian Payment Methods to elnajar..."

# Configuration
SERVER="root@31.97.34.23"
PROJECT_PATH="/root/itargs-supabase"
CLIENT_NAME="elnajar"

echo "📡 Connecting to server $SERVER..."

# Step 1: Upload migration files
echo "📤 Uploading payment migration files..."
scp ecommerce_website_reactjs/supabase/migrations/20260106_seed_egyptian_payments.sql $SERVER:$PROJECT_PATH/
scp ecommerce_website_reactjs/supabase/migrations/20260106_payment_screenshots_bucket.sql $SERVER:$PROJECT_PATH/

# Step 2: Apply migrations to database
echo "🗄️  Applying payment methods migration..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

# Apply payment methods seed
echo "💳 Seeding Egyptian payment methods..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < 20260106_seed_egyptian_payments.sql

# Apply storage bucket migration
echo "📸 Creating payment screenshots bucket..."
docker exec -i supabase_elnajar-db-1 psql -U postgres < 20260106_payment_screenshots_bucket.sql

# Clean up migration files
rm 20260106_seed_egyptian_payments.sql
rm 20260106_payment_screenshots_bucket.sql

echo "✅ Payment methods deployed successfully"
ENDSSH

# Step 3: Verify deployment
echo "🔍 Verifying payment methods..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase

# Check payment methods in database
echo "📋 Checking payment methods..."
docker exec -i supabase_elnajar-db-1 psql -U postgres -c "SELECT code, name, name_ar, is_enabled FROM payment_methods ORDER BY display_order;"

echo "✅ Verification complete"
ENDSSH

echo ""
echo "🎉 Payment Methods Deployment Complete!"
echo ""
echo "📋 What was deployed:"
echo "  ✅ Vodafone Cash payment method"
echo "  ✅ Instapay payment method"
echo "  ✅ Fawry payment method"
echo "  ✅ Cash on Delivery payment method"
echo "  ✅ Payment screenshots storage bucket"
echo "  ✅ Payment verification fields (verified_by, verified_at, payment_phone)"
echo ""
echo "🔗 Next steps:"
echo "  1. Update payment details in admin settings (Vodafone number, bank account)"
echo "  2. Upload payment method icons to /public/icons/"
echo "  3. Test checkout flow with each payment method"
echo ""
