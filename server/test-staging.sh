#!/bin/bash

# Test script for staging worker deployment
STAGING_URL="https://books-api-proxy-staging.jukasdrj.workers.dev"
PROD_URL="https://books-api-proxy.jukasdrj.workers.dev"

echo "🔍 Testing Books API Proxy Staging Deployment"
echo "=============================================="
echo ""

# Test 1: Basic connectivity
echo "📡 Test 1: Basic Worker Response"
echo "Staging URL: $STAGING_URL"
echo "Testing root endpoint..."

# Make request without compression to avoid binary output issues
RESPONSE=$(curl -s -H "Accept-Encoding: identity" -w "HTTPCODE:%{http_code}" "$STAGING_URL/" 2>/dev/null)
HTTP_CODE=$(echo "$RESPONSE" | grep -o "HTTPCODE:[0-9]*" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed 's/HTTPCODE:[0-9]*$//')

echo "HTTP Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Worker is responding"
else
    echo "❌ Worker not responding correctly"
fi
echo ""

# Test 2: Search functionality (if secrets are set)
echo "📚 Test 2: Search Functionality"
echo "Testing search endpoint..."

SEARCH_RESPONSE=$(curl -s -H "Accept-Encoding: identity" -w "HTTPCODE:%{http_code}" "$STAGING_URL/search?q=javascript" 2>/dev/null)
SEARCH_CODE=$(echo "$SEARCH_RESPONSE" | grep -o "HTTPCODE:[0-9]*" | cut -d: -f2)

echo "Search HTTP Status: $SEARCH_CODE"
if [ "$SEARCH_CODE" = "200" ]; then
    echo "✅ Search endpoint responding"
elif [ "$SEARCH_CODE" = "401" ] || [ "$SEARCH_CODE" = "403" ]; then
    echo "⚠️  Search requires API keys (expected - need to copy secrets)"
else
    echo "❌ Search endpoint error"
fi
echo ""

# Test 3: Performance comparison
echo "⏱️  Test 3: Performance Comparison"
echo "Testing response times..."

echo -n "Staging response time: "
STAGING_TIME=$(curl -w "%{time_total}" -s -o /dev/null "$STAGING_URL/" 2>/dev/null)
echo "${STAGING_TIME}s"

echo -n "Production response time: "
PROD_TIME=$(curl -w "%{time_total}" -s -o /dev/null "$PROD_URL/" 2>/dev/null)
echo "${PROD_TIME}s"
echo ""

# Test 4: Headers and security
echo "🔒 Test 4: Security Headers"
echo "Checking security headers..."

HEADERS=$(curl -s -I "$STAGING_URL/" 2>/dev/null)
if echo "$HEADERS" | grep -q "X-Content-Type-Options"; then
    echo "✅ Security headers present"
else
    echo "⚠️  Security headers may be missing"
fi
echo ""

echo "🎯 Summary"
echo "=========="
echo "Staging URL: $STAGING_URL"
echo "Worker Status: $([ "$HTTP_CODE" = "200" ] && echo "✅ Online" || echo "❌ Issues")"
echo ""
echo "📋 Next Steps:"
echo "1. Copy API secrets from production to staging:"
echo "   wrangler secret put ISBNdb1 --name books-api-proxy-staging"
echo "   wrangler secret put google1 --name books-api-proxy-staging" 
echo "   wrangler secret put google2 --name books-api-proxy-staging"
echo ""
echo "2. Test search functionality after secrets are copied"
echo "3. Monitor logs with: wrangler tail books-api-proxy-staging"
echo ""