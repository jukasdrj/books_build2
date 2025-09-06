#!/bin/bash

echo "🚀 TESTING OPTIMIZED BOOK-ONLY CACHE WARMING"
echo "============================================"

# Deploy the optimized worker
echo "📦 Deploying optimized worker..."
cd /Users/justingardner/Downloads/xcode/books_cloudflare/server/books-api-proxy

wrangler deploy

echo "✅ Deployment complete"

# Wait for propagation
sleep 10

# Test book-only cache warming endpoints
echo ""
echo "📚 Testing book cache warming (25 books)..."
curl -X POST "https://books-api-proxy.jukasdrj.workers.dev/cache/warm/books" \
  -H "Content-Type: application/json" \
  --max-time 120 | jq '.'

echo ""
echo "🌍 Testing diverse book cache warming (25 books)..."  
curl -X POST "https://books-api-proxy.jukasdrj.workers.dev/cache/warm/diverse" \
  -H "Content-Type: application/json" \
  --max-time 120 | jq '.'

echo ""
echo "✅ Testing complete! Check success rates above."

echo ""
echo "📊 Expected Results:"
echo "• Books cache: 90-100% success rate"
echo "• Diverse cache: 85-95% success rate" 
echo "• Response time: <60 seconds per batch"
echo "• No CPU timeout errors"

echo ""
echo "🎯 Next: If successful, create chunked script for full 270-book cache"