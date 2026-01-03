#!/bin/bash

# Deploy use_cases table migration to Linux server
# Run this script from your local machine

echo "Deploying use_cases table migration..."

# Copy migration file to server
scp database_setup/add_use_cases.sql root@your-server-ip:/tmp/

# Execute migration on server
ssh root@your-server-ip << 'EOF'
cd /root/itargs-supabase
docker exec -i itargs-supabase-db-1 psql -U postgres -d postgres < /tmp/add_use_cases.sql
rm /tmp/add_use_cases.sql
echo "Migration completed successfully!"
EOF

echo "Done!"
