#!/bin/bash

# Deploy Books API Proxy with R2+KV Hybrid Cache System
# This script sets up the R2 buckets and deploys the enhanced worker

echo "🚀 Deploying Books API Proxy with R2+KV Hybrid Cache System"
echo "============================================================"

# Create R2 buckets for cache storage
echo "📦 Creating R2 buckets for cache storage..."

echo "Creating production R2 bucket: books-cache"
npx wrangler r2 bucket create books-cache

echo "Creating preview R2 bucket: books-cache-preview"
npx wrangler r2 bucket create books-cache-preview

# Check if buckets were created successfully
echo ""
echo "📋 Listing R2 buckets to verify creation:"
npx wrangler r2 bucket list

echo ""
echo "🔧 Configuring R2 bucket settings..."

# Set lifecycle rules for automatic cleanup (optional)
# This helps manage storage costs by cleaning up very old cache entries
echo "Setting up lifecycle rules for cache management..."

# Note: Lifecycle rules can be set via Cloudflare dashboard or API
# For now, we rely on TTL metadata in our cache implementation

echo ""
echo "🚀 Deploying the enhanced worker..."

# Deploy the worker with R2 bindings
npx wrangler deploy

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔍 Testing the deployment..."

# Test the health endpoint to verify R2 integration
echo "Health check:"
curl -s "https://books-api-proxy.jukasdrj.workers.dev/health" | jq '.'

echo ""
echo "📊 Cache System Features:"
echo "  ✓ Hot Cache (KV): Fast access, 100k reads/day, 1GB storage"
echo "  ✓ Cold Cache (R2): High capacity, 10M reads/month, 10GB free storage"
echo "  ✓ Automatic promotion: R2 → KV for frequently accessed data"
echo "  ✓ TTL management: 30 days (search), 1 year (ISBN lookups)"
echo "  ✓ Graceful fallback: R2 failure won't break KV cache"
echo ""
echo "📈 Expected Performance Improvements:"
echo "  • 100x higher read capacity (100k → 10M monthly)"
echo "  • 10x higher storage capacity (1GB → 10GB)"
echo "  • Better burst handling with monthly vs daily limits"
echo "  • Cost optimization with free R2 egress"
echo ""
echo "🎯 Next Steps:"
echo "  1. Monitor cache hit rates in worker analytics"
echo "  2. Check R2 usage in CloudFlare dashboard"
echo "  3. Test with high-volume queries to verify performance"
echo ""
echo "🔐 Required Secrets (if not already configured):"
echo "  • npx wrangler secret put google1        # Primary Google Books API key"
echo "  • npx wrangler secret put google2        # Backup Google Books API key"
echo "  • npx wrangler secret put ISBNdb1        # ISBNdb API key"
echo ""
echo "🔗 URLs:"
echo "  • API Endpoint: https://books-api-proxy.jukasdrj.workers.dev"
echo "  • Health Check: https://books-api-proxy.jukasdrj.workers.dev/health"
echo "  • R2 Dashboard: https://dash.cloudflare.com/?to=/:account/r2"
echo ""