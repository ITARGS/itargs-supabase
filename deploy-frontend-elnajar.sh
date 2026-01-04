#!/bin/bash

# ============================================================================
# Deploy and Run Elnajar Ecommerce Frontend on Port 8080
# ============================================================================

set -e  # Exit on error

echo "🚀 Deploying Elnajar Ecommerce Frontend..."

# Configuration
SERVER="root@31.97.34.23"
PROJECT_PATH="/root/itargs-supabase"
FRONTEND_PATH="/root/itargs-supabase/ecommerce_website_reactjs"
PORT=8080

echo "📡 Connecting to server: $SERVER"

# Step 1: Pull latest code
echo "📥 Pulling latest code from GitHub..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase
git fetch origin
git checkout elnajar-brand-identity
git pull origin elnajar-brand-identity
echo "✅ Code updated successfully"
ENDSSH

# Step 2: Install dependencies and restart frontend
echo "📦 Installing dependencies and restarting frontend..."
ssh $SERVER << 'ENDSSH'
cd /root/itargs-supabase/ecommerce_website_reactjs

# Kill existing processes on port 8080
echo "🔄 Stopping existing frontend processes..."
fuser -k 8080/tcp || true
sleep 2

# Install dependencies
echo "📦 Installing npm dependencies..."
npm install

# Start the dev server in the background
echo "🚀 Starting Vite dev server on port 8080..."
nohup npm run dev -- --host 0.0.0.0 --port 8080 > frontend.log 2>&1 &

# Wait a moment for the server to start
sleep 5

# Check if the server is running
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Frontend is running on http://31.97.34.23:8080"
    echo "✅ Public URL: http://elnajar.itargs.com (if proxied)"
else
    echo "❌ Frontend failed to start. Check logs:"
    tail -n 50 frontend.log
    exit 1
fi

ENDSSH

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📍 Access URLs:"
echo "   - Direct: http://31.97.34.23:8080"
echo "   - Public: https://elnajar.itargs.com"
echo ""
echo "📊 To view logs:"
echo "   ssh root@31.97.34.23 'tail -f /root/itargs-supabase/ecommerce_website_reactjs/frontend.log'"
echo ""
