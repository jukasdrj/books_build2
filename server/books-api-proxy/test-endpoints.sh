#!/bin/bash

# Books API Proxy Test Script
# Tests all endpoints after deployment

if [ -z "$1" ]; then
    echo "❌ Please provide your Worker URL as an argument"
    echo "Usage: ./test-endpoints.sh https://books-api-proxy.YOUR-SUBDOMAIN.workers.dev"
    exit 1
fi

BASE_URL="$1"

echo "🧪 Testing Books API Proxy at: $BASE_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1: Health Check
echo "1️⃣ Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ Health check passed"
    echo "📊 Response: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed"
    echo "📊 Response: $HEALTH_RESPONSE"
fi

echo ""

# Test 2: Book Search
echo "2️⃣ Testing book search..."
SEARCH_RESPONSE=$(curl -s "$BASE_URL/search?q=javascript&maxResults=3")
if echo "$SEARCH_RESPONSE" | grep -q "totalItems"; then
    echo "✅ Book search passed"
    # Extract some info from the response
    TOTAL_ITEMS=$(echo "$SEARCH_RESPONSE" | grep -o '"totalItems":[0-9]*' | cut -d':' -f2)
    PROVIDER=$(echo "$SEARCH_RESPONSE" | grep -o '"provider":"[^"]*' | cut -d':' -f2 | tr -d '"')
    echo "📊 Found $TOTAL_ITEMS results from provider: $PROVIDER"
else
    echo "❌ Book search failed"
    echo "📊 Response: $SEARCH_RESPONSE"
fi

echo ""

# Test 3: ISBN Lookup
echo "3️⃣ Testing ISBN lookup..."
ISBN_RESPONSE=$(curl -s "$BASE_URL/isbn?isbn=9780451524935")
if echo "$ISBN_RESPONSE" | grep -q "volumeInfo"; then
    echo "✅ ISBN lookup passed"
    TITLE=$(echo "$ISBN_RESPONSE" | grep -o '"title":"[^"]*' | cut -d':' -f2 | tr -d '"')
    echo "📊 Found book: $TITLE"
else
    echo "❌ ISBN lookup failed"
    echo "📊 Response: $ISBN_RESPONSE"
fi

echo ""

# Test 4: Rate Limiting (make multiple requests quickly)
echo "4️⃣ Testing rate limiting..."
echo "📡 Making 5 rapid requests to test rate limiting..."
for i in {1..5}; do
    RESPONSE=$(curl -s -w "%{http_code}" "$BASE_URL/search?q=test$i&maxResults=1" -o /dev/null)
    if [ "$RESPONSE" = "200" ]; then
        echo "✅ Request $i: Success (200)"
    elif [ "$RESPONSE" = "429" ]; then
        echo "⏱️ Request $i: Rate limited (429) - This is expected!"
        break
    else
        echo "⚠️ Request $i: Unexpected response ($RESPONSE)"
    fi
    sleep 0.1
done

echo ""

# Test 5: Cache Headers
echo "5️⃣ Testing caching headers..."
CACHE_TEST=$(curl -s -I "$BASE_URL/search?q=cachetest&maxResults=1")
if echo "$CACHE_TEST" | grep -q "X-Cache"; then
    CACHE_STATUS=$(echo "$CACHE_TEST" | grep "X-Cache" | cut -d':' -f2 | tr -d ' \r')
    echo "✅ Cache headers present: $CACHE_STATUS"
else
    echo "⚠️ No cache headers found (might be first request)"
fi

echo ""
echo "🎉 Testing complete!"
echo ""
echo "📋 Next Steps:"
echo "1. If all tests passed, update your iOS app with the Worker URL:"
echo "   BookSearchServiceProxy.swift line 15:"
echo "   private let proxyBaseURL = \"$BASE_URL\""
echo ""
echo "2. Remove the old API key dependencies from your iOS app"
echo "3. Test the iOS app search functionality"
echo "4. Submit to App Store! 🚀"