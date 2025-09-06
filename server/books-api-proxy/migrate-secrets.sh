#!/bin/bash

# Script to migrate API keys from Cloudflare Secrets Store to Worker Environment Variables
# Since Secrets Store API is in alpha and not fully functional, this script guides through manual migration

echo "📋 Cloudflare Secrets Store to Worker Environment Variables Migration"
echo "=================================================================="
echo ""
echo "This script will help you migrate the following API keys:"
echo "1. Google_books_hardoooe -> google1 (Primary Google Books API key)"
echo "2. Google_books_ioskey -> google2 (Secondary Google Books API key)" 
echo "3. ISBN_search_key -> ISBNdb1 (ISBNdb API key)"
echo "4. GOOGLE_SEARCH_API_KEY -> GOOGLE_SEARCH_API_KEY (Future use)"
echo ""

echo "⚠️  Since Cloudflare Secrets Store API is in alpha and doesn't provide direct value retrieval,"
echo "   you'll need to manually retrieve the values from the Cloudflare dashboard or your records."
echo ""

# Function to set a worker secret
set_worker_secret() {
    local secret_name=$1
    local description=$2
    local store_secret_name=$3
    
    echo "---"
    echo "Setting $secret_name ($description)"
    echo "Secrets Store reference: $store_secret_name"
    echo ""
    echo "Please retrieve the value for '$store_secret_name' from:"
    echo "1. Cloudflare Dashboard > Workers & Pages > Secrets"
    echo "2. Or your secure records/password manager"
    echo ""
    
    read -p "Press Enter when you're ready to set the $secret_name secret..."
    
    echo "Setting worker secret: $secret_name"
    if wrangler secret put "$secret_name"; then
        echo "✅ Successfully set $secret_name"
    else
        echo "❌ Failed to set $secret_name"
        return 1
    fi
}

# Set the worker secrets
echo "🔑 Setting Worker Environment Variables"
echo "======================================"

# Primary Google Books API key
set_worker_secret "google1" "Primary Google Books API key" "Google_books_hardoooe"

# Secondary Google Books API key  
set_worker_secret "google2" "Secondary Google Books API key" "Google_books_ioskey"

# ISBNdb API key
set_worker_secret "ISBNdb1" "ISBNdb API key" "ISBN_search_key"

# Google Search API key (for future use)
set_worker_secret "GOOGLE_SEARCH_API_KEY" "Google Custom Search API key" "GOOGLE_SEARCH_API_KEY"

echo ""
echo "🚀 Deploying worker with new environment variables..."
if wrangler deploy; then
    echo "✅ Worker deployed successfully!"
else
    echo "❌ Worker deployment failed!"
    exit 1
fi

echo ""
echo "🧪 Testing worker API access..."
echo "Testing health endpoint..."
curl -s "https://books-api-proxy.jukasdrj.workers.dev/health" | jq '.'

echo ""
echo "Testing search functionality..."
curl -s "https://books-api-proxy.jukasdrj.workers.dev/search?q=python&maxResults=2" | jq '.books[0].title' || echo "Search test failed"

echo ""
echo "✅ Migration complete!"
echo "The worker now uses environment variables instead of Secrets Store binding."
echo ""
echo "🔍 To verify secrets are set, run: wrangler secret list"