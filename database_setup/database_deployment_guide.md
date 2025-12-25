# 🚀 Complete Database Setup & Deployment Guide
## KAT Education E-commerce Platform

This guide provides step-by-step instructions for deploying the complete database setup to a new Supabase instance or production server.

---

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Supabase project created (cloud or self-hosted)
- ✅ Database connection details (host, port, password)
- ✅ PostgreSQL client or Supabase SQL Editor access
- ✅ The SQL scripts from this package

---

## 📦 SQL Scripts Overview

### 1. `01_complete_schema.sql`
**Purpose:** Creates all database tables, indexes, RLS policies, and triggers

**Includes:**
- 16 core tables (products, orders, reviews, bundles, etc.)
- All indexes for performance
- Row Level Security (RLS) policies
- Triggers for auto-updating timestamps
- Storage bucket requirements

### 2. `02_initial_settings.sql`
**Purpose:** Populates initial settings and configuration

**Includes:**
- Store information (name, email, phone, logo)
- Social media links
- Currency and localization settings
- Email notification preferences
- Theme colors (KAT purple/yellow)
- Payment methods (COD, Vodafone Cash, InstaPay, Credit Card)
- Shipping methods (Standard, Express, Same Day)
- Initial categories (Learning Toys, Books, Art, STEM, Puzzles)

### 3. `03_dummy_data.sql`
**Purpose:** Adds sample data for testing

**Includes:**
- 11 sample products across all categories
- Product images (placeholder URLs)
- 3 product bundles
- Sample discount codes
- Sample reviews (approved)
- Test newsletter subscribers

---

## 🎯 Deployment Methods

### Method 1: Supabase SQL Editor (Recommended for Cloud)

**Step 1: Access SQL Editor**
1. Go to your Supabase project dashboard
2. Click "SQL Editor" in the left sidebar
3. Click "New Query"

**Step 2: Run Schema Script**
1. Copy entire contents of `01_complete_schema.sql`
2. Paste into SQL Editor
3. Click "Run" or press `Ctrl+Enter`
4. Wait for completion (should take 10-30 seconds)
5. Verify: Check "Table Editor" to see all tables created

**Step 3: Run Settings Script**
1. Create new query
2. Copy entire contents of `02_initial_settings.sql`
3. Paste and run
4. Verify: Check `settings` table has ~50 rows

**Step 4: Run Dummy Data Script (Optional)**
1. Create new query
2. Copy entire contents of `03_dummy_data.sql`
3. Paste and run
4. Verify: Check `products` table has sample products

**Step 5: Create Storage Buckets**
1. Go to "Storage" in Supabase dashboard
2. Create these buckets (all public):
   - `product-images`
   - `review-images`
   - `store-assets`
3. Set policies to allow public read access

---

### Method 2: Command Line (Self-Hosted Supabase)

**For Docker-based Supabase:**

```bash
# Navigate to your Supabase directory
cd /root/itargs-supabase

# Run schema script
docker exec supabase_kat-db-1 psql -U postgres -d postgres < 01_complete_schema.sql

# Run settings script
docker exec supabase_kat-db-1 psql -U postgres -d postgres < 02_initial_settings.sql

# Run dummy data script (optional)
docker exec supabase_kat-db-1 psql -U postgres -d postgres < 03_dummy_data.sql
```

**For Direct PostgreSQL Connection:**

```bash
# Run all scripts in order
psql -h your-host -U postgres -d postgres -f 01_complete_schema.sql
psql -h your-host -U postgres -d postgres -f 02_initial_settings.sql
psql -h your-host -U postgres -d postgres -f 03_dummy_data.sql
```

---

### Method 3: Automated Deployment Script

Use the provided `deploy_database.sh` script:

```bash
# Make script executable
chmod +x deploy_database.sh

# Run deployment
./deploy_database.sh

# Follow the prompts to:
# 1. Choose deployment method (Supabase Cloud / Self-hosted)
# 2. Enter connection details
# 3. Select which scripts to run
# 4. Verify deployment
```

---

## ✅ Verification Checklist

After running the scripts, verify everything is set up correctly:

### Database Tables
```sql
-- Check all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**Expected tables (16):**
- addresses
- bundles
- bundle_products
- categories
- discount_codes
- newsletter_subscribers
- orders
- order_items
- payment_methods
- products
- product_images
- profiles
- reviews
- review_images
- settings
- shipping_methods
- site_analytics

### Settings Populated
```sql
-- Check settings count
SELECT COUNT(*) FROM settings;
-- Expected: ~50 rows

-- Check key settings
SELECT key, value FROM settings 
WHERE key IN ('store_name', 'currency', 'theme_primary')
ORDER BY key;
```

### Payment & Shipping Methods
```sql
-- Check payment methods
SELECT name, name_ar, type, is_active FROM payment_methods ORDER BY display_order;
-- Expected: 4 methods (COD, Vodafone Cash, InstaPay, Credit Card)

-- Check shipping methods
SELECT name, name_ar, base_cost, estimated_days FROM shipping_methods ORDER BY display_order;
-- Expected: 3 methods (Standard, Express, Same Day)
```

### Categories
```sql
-- Check categories
SELECT name, name_ar, slug FROM categories ORDER BY display_order;
-- Expected: 5 categories
```

### Sample Data (if loaded)
```sql
-- Check products
SELECT COUNT(*) FROM products;
-- Expected: 11 products

-- Check bundles
SELECT COUNT(*) FROM bundles;
-- Expected: 3 bundles

-- Check reviews
SELECT COUNT(*) FROM reviews WHERE is_approved = true;
-- Expected: 5 reviews
```

### RLS Policies
```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('products', 'orders', 'reviews')
ORDER BY tablename;
-- All should show rowsecurity = true
```

---

## 🔧 Post-Deployment Configuration

### 1. Update Settings via Admin Dashboard
After deployment, login to admin dashboard and update:
- Store name, email, phone
- Social media links
- Upload store logo
- Configure payment method details
- Set shipping costs for your region

### 2. Create Admin User
```sql
-- After first user signup, make them admin
UPDATE profiles 
SET role = 'admin' 
WHERE id = 'user-uuid-here';
```

### 3. Upload Product Images
- Replace placeholder image URLs in `product_images` table
- Upload actual images to `product-images` storage bucket
- Update image URLs to point to uploaded files

### 4. Configure Storage Buckets
Ensure these buckets exist with correct policies:

**product-images:**
- Public read access
- Authenticated write access

**review-images:**
- Public read access
- Authenticated write access

**store-assets:**
- Public read access
- Authenticated write access

---

## 🔄 Updating Existing Database

If you need to update an existing database:

### Add Missing Tables
```bash
# Extract only new table definitions from 01_complete_schema.sql
# Run only those CREATE TABLE statements
```

### Update Settings
```bash
# Run 02_initial_settings.sql
# Uses ON CONFLICT to update existing settings
```

### Migrate Data
```bash
# Create custom migration script
# Copy data from old structure to new
```

---

## 🐛 Troubleshooting

### Issue: "relation already exists"
**Solution:** Tables already exist. Either:
- Drop existing tables first (⚠️ loses data)
- Skip schema creation, run only settings/data scripts
- Create migration script for updates

### Issue: "permission denied"
**Solution:** Ensure you're connected as superuser or have sufficient privileges

### Issue: Foreign key violations
**Solution:** Run scripts in correct order:
1. Schema first (creates tables)
2. Settings second (populates lookup tables)
3. Dummy data last (references other tables)

### Issue: RLS policies blocking access
**Solution:** 
- Ensure you're authenticated when testing
- Check policy conditions match your use case
- Temporarily disable RLS for testing: `ALTER TABLE tablename DISABLE ROW LEVEL SECURITY;`

---

## 📊 Database Statistics

After full deployment:

| Metric | Count |
|--------|-------|
| Tables | 16 |
| Indexes | 20+ |
| RLS Policies | 30+ |
| Settings | ~50 |
| Categories | 5 |
| Payment Methods | 4 |
| Shipping Methods | 3 |
| Sample Products | 11 |
| Sample Bundles | 3 |

---

## 🔐 Security Notes

1. **Change Default Values:** Update all default settings after deployment
2. **Admin Access:** Limit admin role to trusted users only
3. **RLS Policies:** Review and customize for your security requirements
4. **API Keys:** Never commit Supabase keys to version control
5. **Storage Policies:** Ensure sensitive files aren't publicly accessible

---

## 📝 Maintenance

### Regular Tasks
- Backup database regularly
- Monitor storage usage
- Review and approve pending reviews
- Update product inventory
- Check for low stock items

### Database Backups
```bash
# Backup entire database
pg_dump -h your-host -U postgres -d postgres > backup_$(date +%Y%m%d).sql

# Backup specific tables
pg_dump -h your-host -U postgres -d postgres -t products -t orders > backup_data.sql
```

---

## 🎉 Success!

If all verification checks pass, your database is fully set up and ready for production use!

**Next Steps:**
1. Deploy React frontend to Bluehost
2. Configure environment variables
3. Test all features end-to-end
4. Go live! 🚀

---

## 📞 Support

For issues or questions:
- Check troubleshooting section above
- Review Supabase documentation
- Contact development team

**Happy deploying!** ✨
