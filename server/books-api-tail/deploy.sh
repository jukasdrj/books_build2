#!/bin/bash

# Deploy Books API Tail Worker
# This script sets up and deploys the tail worker for monitoring the books API proxy

set -e

echo "🚀 Deploying Books API Tail Worker..."

# Check if wrangler is available
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found. Please install with: npm install -g wrangler"
    exit 1
fi

# Check if we're logged in to Cloudflare
echo "📋 Checking Cloudflare authentication..."
if ! wrangler whoami &> /dev/null; then
    echo "❌ Not logged in to Cloudflare. Please run: wrangler login"
    exit 1
fi

echo "✅ Authenticated with Cloudflare"

# KV namespaces are already configured in wrangler.toml
echo "📦 KV namespaces already configured:"
echo "  • Production: ce6a611a14b845478c087429dffe3372"
echo "  • Preview: 44e4c458e5d742908c409170d1069517"

# Deploy the tail worker
echo "🚀 Deploying tail worker..."
wrangler deploy

echo ""
echo "✅ Books API Tail Worker deployed successfully!"
echo ""
echo "📊 Monitoring Features:"
echo "  • Real-time performance metrics"
echo "  • Cache hit/miss analytics"
echo "  • Error rate monitoring"
echo "  • Geographic usage patterns"
echo "  • API provider usage tracking"
echo "  • Automated alerting"
echo ""
echo "🔧 Management Commands:"
echo "  • View logs: wrangler tail books-api-proxy"
echo "  • View analytics: Check KV namespace TAIL_ANALYTICS"
echo "  • Monitor alerts: Check alerts:latest key in KV"
echo ""
echo "🎯 The tail worker is now processing logs from books-api-proxy!"

# Clean up backup files
rm -f wrangler.toml.bak