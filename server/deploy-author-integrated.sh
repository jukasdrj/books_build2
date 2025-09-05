#!/bin/bash
# Deploy Author-Integrated CloudFlare Worker
# Implements Tasks 8 & 9: Author Indexing and Cultural Data Propagation

set -e

echo "🚀 DEPLOYING AUTHOR-INTEGRATED CLOUDFLARE WORKER"
echo "================================================="

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
  --config wrangler-author-integrated.toml \
  --env staging \
  --name books-api-proxy-author-staging

echo "✅ Staging deployment complete"

# Test staging deployment
echo ""
echo "🧪 STEP 2: Testing STAGING deployment..."
echo "----------------------------------------"

STAGING_URL="https://books-api-proxy-author-staging.jukasdrj.workers.dev"

# Test health endpoint
echo "Testing health endpoint..."
if curl -s "${STAGING_URL}/health" | grep -q "author-integrated"; then
    echo "✅ Health check passed - author integration detected"
else
    echo "❌ Health check failed"
    exit 1
fi

# Test basic search (should build author profiles)
echo "Testing search with author indexing..."
if curl -s "${STAGING_URL}/search?q=tolkien&maxResults=3" | grep -q "items"; then
    echo "✅ Search test passed"
else
    echo "❌ Search test failed"
    exit 1
fi

echo "✅ All staging tests passed"

# Deploy to production
echo ""
echo "🌟 STEP 3: Deploy to PRODUCTION..."
echo "----------------------------------"

read -p "Deploy to production? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying to production..."
    
    wrangler deploy \
      --config wrangler-author-integrated.toml \
      --env production \
      --name books-api-proxy
    
    echo "✅ Production deployment complete!"
    
    # Test production
    echo ""
    echo "🧪 Testing PRODUCTION deployment..."
    echo "-----------------------------------"
    
    PROD_URL="https://books-api-proxy.jukasdrj.workers.dev"
    
    echo "Testing production health endpoint..."
    if curl -s "${PROD_URL}/health" | grep -q "author-integrated"; then
        echo "✅ Production health check passed"
    else
        echo "❌ Production health check failed"
        exit 1
    fi
    
    echo ""
    echo "🎉 DEPLOYMENT COMPLETE!"
    echo "======================="
    echo "Production URL: ${PROD_URL}"
    echo ""
    echo "📊 NEW ENDPOINTS AVAILABLE:"
    echo "• ${PROD_URL}/search - Enhanced with author profiles"
    echo "• ${PROD_URL}/isbn - Enhanced with cultural data"
    echo "• ${PROD_URL}/authors/search - Search authors by culture"
    echo "• ${PROD_URL}/authors/profile?name=AuthorName - Get author profile"
    echo "• ${PROD_URL}/authors/cultural-stats - Get diversity statistics"
    echo "• ${PROD_URL}/authors/propagate?author=Name - Trigger data propagation"
    echo ""
    echo "🔥 FEATURES IMPLEMENTED:"
    echo "✅ Task 8: Author Indexing Service"
    echo "✅ Task 9: Cultural Data Propagation"
    echo "✅ Multi-tier caching (KV + R2)"
    echo "✅ Author profile building from search results"
    echo "✅ Cultural metadata enrichment"
    echo "✅ Author-based cultural search"
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
    wrangler delete books-api-proxy-author-staging --force
    echo "✅ Staging worker removed"
fi

echo ""
echo "🎯 NEXT STEPS:"
echo "• Update iOS BookSearchService to use new cultural metadata"
echo "• Test author profile features in production"
echo "• Monitor CloudFlare analytics for performance"
echo "• Consider implementing author deduplication maintenance"