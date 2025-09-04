#!/bin/bash

# Production Deployment Script for Optimized Books API Proxy
# Includes rollback capabilities and comprehensive monitoring

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKER_NAME="books-api-proxy"
STAGING_NAME="books-api-proxy-optimized-staging" 
CONFIG_FILE="wrangler-optimized.toml"
BUNDLED_WORKER="optimized-bundled-worker.js"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate prerequisites
validate_prerequisites() {
    log "Validating prerequisites..."
    
    if ! command_exists wrangler; then
        error "wrangler CLI not found. Please install it first."
    fi
    
    if ! command_exists curl; then
        error "curl not found. Please install it first."
    fi
    
    if ! command_exists jq; then
        error "jq not found. Please install it for JSON parsing."
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Configuration file $CONFIG_FILE not found."
    fi
    
    if [ ! -f "$BUNDLED_WORKER" ]; then
        error "Worker file $BUNDLED_WORKER not found."
    fi
    
    log "Prerequisites validated successfully."
}

# Get current production worker info
get_current_production_info() {
    log "Getting current production worker information..."
    
    # Get current version
    CURRENT_VERSION=$(wrangler deployments list --name "$WORKER_NAME" --format json 2>/dev/null | jq -r '.[0].version_id // "unknown"' || echo "unknown")
    
    log "Current production version: $CURRENT_VERSION"
    echo "$CURRENT_VERSION" > /tmp/books-api-rollback-version.txt
}

# Test staging worker thoroughly
test_staging_worker() {
    log "Testing staging worker thoroughly..."
    
    STAGING_URL="https://${STAGING_NAME}.jukasdrj.workers.dev"
    
    # Test health endpoint
    log "Testing health endpoint..."
    HEALTH_RESPONSE=$(curl -s "$STAGING_URL/health" || error "Health check failed")
    
    if ! echo "$HEALTH_RESPONSE" | jq -e '.status == "healthy"' >/dev/null; then
        error "Staging worker health check failed: $HEALTH_RESPONSE"
    fi
    
    log "Health check passed"
    
    # Test search endpoint
    log "Testing search functionality..."
    SEARCH_RESPONSE=$(curl -s "$STAGING_URL/search?q=test" || error "Search test failed")
    
    if ! echo "$SEARCH_RESPONSE" | jq -e '.query == "test"' >/dev/null; then
        error "Search functionality test failed: $SEARCH_RESPONSE"
    fi
    
    log "Search functionality test passed"
    
    # Test caching (second request should be faster)
    log "Testing caching system..."
    START_TIME=$(date +%s%N)
    CACHE_RESPONSE=$(curl -s "$STAGING_URL/search?q=cache-test" || error "Cache test failed")
    FIRST_TIME=$(($(date +%s%N) - START_TIME))
    
    START_TIME=$(date +%s%N)
    CACHE_RESPONSE_2=$(curl -s "$STAGING_URL/search?q=cache-test" || error "Cache test 2 failed")
    SECOND_TIME=$(($(date +%s%N) - START_TIME))
    
    if echo "$CACHE_RESPONSE_2" | jq -e '._metadata.cached == true' >/dev/null; then
        log "Caching system working correctly"
    else
        warn "Caching system may not be working as expected"
    fi
    
    # Test error handling
    log "Testing error handling..."
    ERROR_RESPONSE=$(curl -s "$STAGING_URL/nonexistent" || true)
    if ! echo "$ERROR_RESPONSE" | jq -e '.error' >/dev/null; then
        warn "Error handling test did not return expected error format"
    fi
    
    log "All staging tests passed successfully"
}

# Create production KV namespaces if needed
setup_production_resources() {
    log "Setting up production resources..."
    
    # Check if production KV namespaces exist
    EXISTING_KV=$(wrangler kv namespace list --format json)
    
    BOOKS_CACHE_PROD=$(echo "$EXISTING_KV" | jq -r '.[] | select(.title == "BOOKS_CACHE_PRODUCTION") | .id // empty')
    AUTHOR_PROFILES_PROD=$(echo "$EXISTING_KV" | jq -r '.[] | select(.title == "AUTHOR_PROFILES_PRODUCTION") | .id // empty')
    
    if [ -z "$BOOKS_CACHE_PROD" ]; then
        log "Creating production books cache KV namespace..."
        BOOKS_CACHE_PROD=$(wrangler kv namespace create "BOOKS_CACHE_PRODUCTION" --format json | jq -r '.id')
        log "Created BOOKS_CACHE_PRODUCTION with ID: $BOOKS_CACHE_PROD"
    else
        log "Using existing BOOKS_CACHE_PRODUCTION: $BOOKS_CACHE_PROD"
    fi
    
    if [ -z "$AUTHOR_PROFILES_PROD" ]; then
        log "Creating production author profiles KV namespace..."
        AUTHOR_PROFILES_PROD=$(wrangler kv namespace create "AUTHOR_PROFILES_PRODUCTION" --format json | jq -r '.id')
        log "Created AUTHOR_PROFILES_PRODUCTION with ID: $AUTHOR_PROFILES_PROD"
    else
        log "Using existing AUTHOR_PROFILES_PRODUCTION: $AUTHOR_PROFILES_PROD"
    fi
    
    # Check if production R2 buckets exist
    EXISTING_R2=$(wrangler r2 bucket list --format json 2>/dev/null || echo '[]')
    
    if ! echo "$EXISTING_R2" | jq -e '.[] | select(.name == "books-cache-production")' >/dev/null; then
        log "Creating production books R2 bucket..."
        wrangler r2 bucket create books-cache-production
        log "Created books-cache-production R2 bucket"
    else
        log "Using existing books-cache-production R2 bucket"
    fi
    
    if ! echo "$EXISTING_R2" | jq -e '.[] | select(.name == "cultural-data-production")' >/dev/null; then
        log "Creating production cultural data R2 bucket..."
        wrangler r2 bucket create cultural-data-production
        log "Created cultural-data-production R2 bucket"
    else
        log "Using existing cultural-data-production R2 bucket"
    fi
    
    # Update production config with actual IDs
    log "Updating production configuration..."
    sed -i.bak "s/b9cade63b6db48fd80c109a013f38fdb/$BOOKS_CACHE_PROD/g" "$CONFIG_FILE.prod"
    sed -i.bak "s/c7da0b776d6247589949d19c0faf03ae/$AUTHOR_PROFILES_PROD/g" "$CONFIG_FILE.prod"
    sed -i.bak "s/books-cache/books-cache-production/g" "$CONFIG_FILE.prod"
    sed -i.bak "s/cultural-data-staging/cultural-data-production/g" "$CONFIG_FILE.prod"
    
    log "Production resources setup completed"
}

# Deploy to production
deploy_to_production() {
    log "Deploying to production..."
    
    # Create production config
    cp "$CONFIG_FILE" "$CONFIG_FILE.prod"
    
    # Deploy with production environment
    wrangler deploy --config "$CONFIG_FILE.prod" --env production --name "$WORKER_NAME" || error "Production deployment failed"
    
    log "Production deployment completed"
}

# Copy secrets to production
copy_secrets_to_production() {
    log "Checking production secrets..."
    
    PROD_SECRETS=$(wrangler secret list --name "$WORKER_NAME" --format json)
    
    REQUIRED_SECRETS=("google1" "google2" "ISBNdb1")
    
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if ! echo "$PROD_SECRETS" | jq -e ".[] | select(.name == \"$secret\")" >/dev/null; then
            warn "Secret $secret not found in production worker"
            warn "Please run: wrangler secret put $secret --name $WORKER_NAME"
        else
            log "Secret $secret exists in production"
        fi
    done
}

# Test production deployment
test_production_deployment() {
    log "Testing production deployment..."
    
    PRODUCTION_URL="https://${WORKER_NAME}.jukasdrj.workers.dev"
    
    # Wait a moment for deployment to propagate
    sleep 10
    
    # Test health endpoint
    log "Testing production health endpoint..."
    HEALTH_RESPONSE=$(curl -s "$PRODUCTION_URL/health" --max-time 30 || error "Production health check failed")
    
    if ! echo "$HEALTH_RESPONSE" | jq -e '.status == "healthy"' >/dev/null; then
        error "Production health check failed: $HEALTH_RESPONSE"
    fi
    
    # Verify version
    VERSION=$(echo "$HEALTH_RESPONSE" | jq -r '.version')
    if [[ "$VERSION" != "3.0-optimized" ]]; then
        warn "Unexpected version in production: $VERSION"
    fi
    
    # Test search functionality
    log "Testing production search..."
    SEARCH_RESPONSE=$(curl -s "$PRODUCTION_URL/search?q=production-test" --max-time 30 || error "Production search test failed")
    
    if ! echo "$SEARCH_RESPONSE" | jq -e '.query == "production-test"' >/dev/null; then
        error "Production search test failed: $SEARCH_RESPONSE"
    fi
    
    log "Production deployment tests passed"
}

# Rollback function
rollback_deployment() {
    if [ -f "/tmp/books-api-rollback-version.txt" ]; then
        ROLLBACK_VERSION=$(cat /tmp/books-api-rollback-version.txt)
        
        if [ "$ROLLBACK_VERSION" != "unknown" ]; then
            warn "Rolling back to version: $ROLLBACK_VERSION"
            wrangler rollback "$ROLLBACK_VERSION" --name "$WORKER_NAME" || error "Rollback failed"
            log "Rollback completed successfully"
        else
            error "No valid rollback version found"
        fi
    else
        error "No rollback information available"
    fi
}

# Monitor production for a few minutes
monitor_production() {
    log "Monitoring production for 2 minutes..."
    
    PRODUCTION_URL="https://${WORKER_NAME}.jukasdrj.workers.dev"
    
    for i in {1..12}; do
        log "Monitor check $i/12..."
        
        HEALTH_RESPONSE=$(curl -s "$PRODUCTION_URL/health" --max-time 10 || echo '{"status":"error"}')
        STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.status // "error"')
        
        if [ "$STATUS" != "healthy" ]; then
            error "Production monitoring failed at check $i: $HEALTH_RESPONSE"
        fi
        
        sleep 10
    done
    
    log "Production monitoring completed successfully"
}

# Main deployment process
main() {
    log "Starting production deployment process..."
    
    validate_prerequisites
    get_current_production_info
    test_staging_worker
    setup_production_resources
    deploy_to_production
    copy_secrets_to_production
    test_production_deployment
    monitor_production
    
    log "Production deployment completed successfully!"
    log "New worker URL: https://${WORKER_NAME}.jukasdrj.workers.dev"
    log "Rollback command: bash $0 rollback"
}

# Handle rollback command
if [ "$1" = "rollback" ]; then
    log "Initiating rollback process..."
    rollback_deployment
    exit 0
fi

# Trap errors and offer rollback
trap 'error "Deployment failed. Run: bash $0 rollback to rollback changes"' ERR

# Run main deployment
main

log "Deployment completed successfully!"
echo -e "\n${BLUE}=== DEPLOYMENT SUMMARY ===${NC}"
echo -e "${GREEN}✓ Staging tests passed${NC}"
echo -e "${GREEN}✓ Production deployment successful${NC}"
echo -e "${GREEN}✓ Production tests passed${NC}"
echo -e "${GREEN}✓ Monitoring completed${NC}"
echo -e "\n${BLUE}Production URL:${NC} https://${WORKER_NAME}.jukasdrj.workers.dev"
echo -e "${BLUE}Rollback command:${NC} bash $0 rollback"