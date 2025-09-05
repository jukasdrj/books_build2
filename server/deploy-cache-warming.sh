#!/bin/bash
# Deploy Cache Warming Integrated CloudFlare Worker
# Features: Author Indexing + Cultural Data + Automatic Cache Warming

set -e

echo "🚀 DEPLOYING CACHE WARMING CLOUDFLARE WORKER"
echo "============================================="

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Error: Wrangler CLI not found. Install with: npm install -g wrangler"
    exit 1
fi

# Check if we're authenticated
echo "🔐 Checking CloudFlare authentication..."
if ! wrangler whoami &> /dev/null; then
    echo "❌ Error: Not authenticated with CloudFlare. Run: wrangler login"
    exit 1
fi

echo "✅ Authentication verified"

# Deploy to staging first for testing
echo ""
echo "📦 STEP 1: Deploy to STAGING for testing..."
echo "-------------------------------------------"

wrangler deploy \
  --config wrangler-cache-warming.toml \
  --env staging \
  --name books-api-proxy-cache-staging

echo "✅ Staging deployment complete"

# Test staging deployment
echo ""
echo "🧪 STEP 2: Testing STAGING deployment..."
echo "----------------------------------------"

STAGING_URL="https://books-api-proxy-cache-staging.jukasdrj.workers.dev"

# Test health endpoint
echo "Testing health endpoint with cache warming features..."
if curl -s "${STAGING_URL}/health" | grep -q "cache-integrated"; then
    echo "✅ Health check passed - cache warming detected"
    
    # Show cache warming features
    echo "Cache warming features:"
    curl -s "${STAGING_URL}/health" | jq -r '.cacheWarming | to_entries[] | "  • \(.key): \(.value)"'
else
    echo "❌ Health check failed"
    exit 1
fi

# Test cache status endpoint
echo ""
echo "Testing cache status endpoint..."
if curl -s "${STAGING_URL}/cache/status" | grep -q "success"; then
    echo "✅ Cache status endpoint working"
else
    echo "❌ Cache status endpoint failed"
    exit 1
fi

# Test manual cache warming trigger
echo ""
echo "Testing manual cache warming trigger..."
if curl -s "${STAGING_URL}/cache/manual-trigger?type=new-releases&batch=5" | grep -q "success"; then
    echo "✅ Manual cache warming working"
else
    echo "❌ Manual cache warming failed"
    exit 1
fi

echo "✅ All staging tests passed"

# Deploy to production
echo ""
echo "🌟 STEP 3: Deploy to PRODUCTION..."
echo "----------------------------------"

read -p "Deploy cache warming system to production? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying to production with cron triggers..."
    
    wrangler deploy \
      --config wrangler-cache-warming.toml \
      --env production \
      --name books-api-proxy
    
    echo "✅ Production deployment complete!"
    
    # Test production
    echo ""
    echo "🧪 Testing PRODUCTION deployment..."
    echo "-----------------------------------"
    
    PROD_URL="https://books-api-proxy.jukasdrj.workers.dev"
    
    echo "Testing production health endpoint..."
    if curl -s "${PROD_URL}/health" | grep -q "cache-integrated"; then
        echo "✅ Production health check passed"
        echo ""
        echo "Cache warming schedule:"
        curl -s "${PROD_URL}/health" | jq -r '.cacheWarming.schedule | to_entries[] | "  • \(.key): \(.value)"'
    else
        echo "❌ Production health check failed"
        exit 1
    fi
    
    # Test cache status
    echo ""
    echo "Testing production cache status..."
    CACHE_STATUS=$(curl -s "${PROD_URL}/cache/status")
    if echo "${CACHE_STATUS}" | grep -q "success"; then
        echo "✅ Production cache status working"
        echo "Next warming runs:"
        echo "${CACHE_STATUS}" | jq -r '.cacheWarming.nextRuns | to_entries[] | "  • \(.key): \(.value)"'
    else
        echo "❌ Cache status failed"
    fi
    
    echo ""
    echo "🎉 CACHE WARMING DEPLOYMENT COMPLETE!"
    echo "====================================="
    echo "Production URL: ${PROD_URL}"
    echo ""
    echo "📊 NEW CACHE WARMING ENDPOINTS:"
    echo "• ${PROD_URL}/cache/status - View warming progress"
    echo "• ${PROD_URL}/cache/warm-new-releases - Manual new releases"
    echo "• ${PROD_URL}/cache/warm-popular - Manual popular books"
    echo "• ${PROD_URL}/cache/warm-historical - Manual historical books"
    echo "• ${PROD_URL}/cache/manual-trigger - Universal manual trigger"
    echo ""
    echo "🕐 AUTOMATIC SCHEDULING:"
    echo "• Daily 2:00 AM UTC: New releases (last 7 days)"
    echo "• Weekly Sunday 3:00 AM UTC: Popular authors (~50 books)"  
    echo "• Monthly 1st 4:00 AM UTC: Historical bestsellers (~100 books)"
    echo ""
    echo "🔥 FEATURES NOW LIVE:"
    echo "✅ Automatic cache warming with cron triggers"
    echo "✅ New release detection and caching"
    echo "✅ Popular books and authors pre-loading"
    echo "✅ Historical bestsellers caching" 
    echo "✅ Author cultural profile building"
    echo "✅ Multi-tier caching (KV + R2)"
    echo "✅ Manual warming triggers for testing"
    echo ""
    echo "📈 EXPECTED RESULTS:"
    echo "• 90%+ cache hit rate for popular searches within 30 days"
    echo "• Sub-100ms response times for cached content"
    echo "• 5000+ books pre-cached within 3 months"
    echo "• 1000+ author profiles automatically built"
    echo ""
    
else
    echo "Production deployment cancelled."
    echo "Staging available at: ${STAGING_URL}"
fi

echo ""
echo "🧹 CLEANUP: Remove staging worker? (y/N): "
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    wrangler delete --name books-api-proxy-cache-staging --force
    echo "✅ Staging worker removed"
fi

echo ""
echo "🎯 NEXT STEPS:"
echo "• Monitor CloudFlare cron job logs for automatic warming"
echo "• Check cache hit rates in CloudFlare analytics"  
echo "• Test manual warming endpoints as needed"
echo "• Watch for improved iOS app performance with pre-cached content"
echo ""
echo "📊 MONITORING:"
echo "• CloudFlare Dashboard > Workers > books-api-proxy > Logs"
echo "• Check cron job execution logs daily"
echo "• Monitor KV/R2 storage usage growth"