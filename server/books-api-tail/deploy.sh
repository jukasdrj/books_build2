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

# Create KV namespace if it doesn't exist
echo "📦 Setting up KV namespace for tail analytics..."

# Create production KV namespace
TAIL_ANALYTICS_ID=$(wrangler kv:namespace create TAIL_ANALYTICS --json | jq -r '.result.id' 2>/dev/null || echo "")
if [ -z "$TAIL_ANALYTICS_ID" ]; then
    echo "⚠️  KV namespace might already exist or there was an error. Continuing with deployment..."
else
    echo "✅ Created KV namespace: $TAIL_ANALYTICS_ID"
    
    # Update wrangler.toml with the actual namespace ID
    sed -i.bak "s/tail_analytics_namespace_id_placeholder/$TAIL_ANALYTICS_ID/g" wrangler.toml
fi

# Create preview KV namespace
TAIL_ANALYTICS_PREVIEW_ID=$(wrangler kv:namespace create TAIL_ANALYTICS --preview --json | jq -r '.result.id' 2>/dev/null || echo "")
if [ -z "$TAIL_ANALYTICS_PREVIEW_ID" ]; then
    echo "⚠️  Preview KV namespace might already exist or there was an error. Continuing with deployment..."
else
    echo "✅ Created preview KV namespace: $TAIL_ANALYTICS_PREVIEW_ID"
    
    # Update wrangler.toml with the actual preview namespace ID
    sed -i.bak "s/tail_analytics_preview_id_placeholder/$TAIL_ANALYTICS_PREVIEW_ID/g" wrangler.toml
fi

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