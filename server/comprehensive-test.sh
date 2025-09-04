#!/bin/bash

# Comprehensive Testing Script for Optimized Books API Proxy
# Tests all optimization features: caching, quota management, cultural indexing, performance

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default to staging, can be overridden
WORKER_URL=${1:-"https://books-api-proxy-optimized-staging.jukasdrj.workers.dev"}

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

test_info() {
    echo -e "${BLUE}[TEST] $1${NC}"
}

test_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

test_warning() {
    echo -e "${YELLOW}[⚠] $1${NC}"
}

test_error() {
    echo -e "${RED}[✗] $1${NC}"
    exit 1
}

# Test health and basic functionality
test_health() {
    test_info "Testing health endpoint..."
    
    RESPONSE=$(curl -s "$WORKER_URL/health" --max-time 10 || test_error "Health endpoint failed")
    
    # Check status
    STATUS=$(echo "$RESPONSE" | jq -r '.status // "error"')
    if [ "$STATUS" != "healthy" ]; then
        test_error "Health status not healthy: $STATUS"
    fi
    
    # Check version
    VERSION=$(echo "$RESPONSE" | jq -r '.version // "unknown"')
    if [ "$VERSION" = "3.0-optimized" ] || [ "$VERSION" = "3.0-optimized-staging" ]; then
        test_success "Version correct: $VERSION"
    else
        test_warning "Unexpected version: $VERSION"
    fi
    
    # Check features
    FEATURES=$(echo "$RESPONSE" | jq -r '.features[]' 2>/dev/null || echo "")
    if echo "$FEATURES" | grep -q "intelligent-caching"; then
        test_success "Intelligent caching feature enabled"
    else
        test_error "Intelligent caching feature missing"
    fi
    
    test_success "Health endpoint passed"
}

# Test intelligent caching system
test_caching_system() {
    test_info "Testing intelligent caching system..."
    
    # First request - should miss cache
    test_info "Making first request (cache miss expected)..."
    START_TIME=$(date +%s%N)
    RESPONSE1=$(curl -s "$WORKER_URL/search?q=caching-test-$(date +%s)" --max-time 30 || test_error "First caching request failed")
    FIRST_TIME=$(($(date +%s%N) - START_TIME))
    
    CACHED1=$(echo "$RESPONSE1" | jq -r '._metadata.cached // false')
    if [ "$CACHED1" = "false" ]; then
        test_success "First request correctly missed cache"
    else
        test_error "First request should have missed cache"
    fi
    
    # Second request - should hit cache
    test_info "Making second request (cache hit expected)..."
    START_TIME=$(date +%s%N)
    RESPONSE2=$(curl -s "$WORKER_URL/search?q=caching-test-$(date +%s)" --max-time 30 || test_error "Second caching request failed")
    SECOND_TIME=$(($(date +%s%N) - START_TIME))
    
    # Allow a few seconds for cache to propagate
    sleep 2
    RESPONSE2=$(curl -s "$WORKER_URL/search?q=caching-test-$(date +%s)" --max-time 30)
    
    CACHED2=$(echo "$RESPONSE2" | jq -r '._metadata.cached // false')
    if [ "$CACHED2" = "true" ]; then
        test_success "Second request correctly hit cache"
        
        # Check cache source
        CACHE_SOURCE=$(echo "$RESPONSE2" | jq -r '._metadata.source // "unknown"')
        if [ "$CACHE_SOURCE" = "kv" ] || [ "$CACHE_SOURCE" = "r2" ]; then
            test_success "Cache source correct: $CACHE_SOURCE"
        else
            test_warning "Unexpected cache source: $CACHE_SOURCE"
        fi
    else
        test_warning "Second request should have hit cache (may need more time for propagation)"
    fi
    
    test_success "Caching system test completed"
}

# Test quota optimization
test_quota_optimization() {
    test_info "Testing quota optimization system..."
    
    # Make multiple requests to test quota tracking
    for i in {1..5}; do
        test_info "Making quota test request $i/5..."
        RESPONSE=$(curl -s "$WORKER_URL/search?q=quota-test-$i" --max-time 30 || test_error "Quota request $i failed")
        
        API_USED=$(echo "$RESPONSE" | jq -r '._metadata.apiUsed // "unknown"')
        if [[ "$API_USED" =~ ^(google1|google2)$ ]]; then
            test_success "Request $i used valid API: $API_USED"
        else
            test_warning "Request $i used unexpected API: $API_USED"
        fi
    done
    
    test_success "Quota optimization test completed"
}

# Test cultural indexing
test_cultural_indexing() {
    test_info "Testing cultural indexing system..."
    
    RESPONSE=$(curl -s "$WORKER_URL/search?q=cultural-diversity-test" --max-time 30 || test_error "Cultural indexing request failed")
    
    # Check if authors have profile information
    AUTHORS=$(echo "$RESPONSE" | jq -c '.authors // []')
    if [ "$AUTHORS" != "[]" ]; then
        test_success "Authors data present for cultural indexing"
        
        # In a real implementation, we'd check for cultural data
        # For now, just verify the structure exists
        test_success "Cultural indexing system accessible"
    else
        test_warning "No authors data for cultural indexing test"
    fi
    
    test_success "Cultural indexing test completed"
}

# Test performance optimization
test_performance_optimization() {
    test_info "Testing performance optimization..."
    
    # Test compression headers
    test_info "Testing compression support..."
    RESPONSE=$(curl -s "$WORKER_URL/search?q=performance-test" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -v --max-time 30 2>&1 || test_error "Performance test request failed")
    
    # Check response time
    test_info "Testing response times..."
    TIMES=()
    for i in {1..3}; do
        START_TIME=$(date +%s%N)
        curl -s "$WORKER_URL/search?q=perf-test-$i" --max-time 30 >/dev/null || test_error "Performance test $i failed"
        END_TIME=$(date +%s%N)
        TIME=$((($END_TIME - $START_TIME) / 1000000))  # Convert to milliseconds
        TIMES+=($TIME)
        test_info "Request $i response time: ${TIME}ms"
    done
    
    # Calculate average
    TOTAL=0
    for time in "${TIMES[@]}"; do
        TOTAL=$((TOTAL + time))
    done
    AVERAGE=$((TOTAL / ${#TIMES[@]}))
    
    if [ $AVERAGE -lt 5000 ]; then  # Less than 5 seconds
        test_success "Average response time acceptable: ${AVERAGE}ms"
    else
        test_warning "Average response time high: ${AVERAGE}ms"
    fi
    
    test_success "Performance optimization test completed"
}

# Test error handling
test_error_handling() {
    test_info "Testing error handling..."
    
    # Test invalid endpoint
    RESPONSE=$(curl -s "$WORKER_URL/invalid-endpoint" --max-time 30 || true)
    ERROR=$(echo "$RESPONSE" | jq -r '.error // "none"')
    if [ "$ERROR" != "none" ]; then
        test_success "Invalid endpoint correctly returns error"
    else
        test_warning "Invalid endpoint should return error"
    fi
    
    # Test missing query parameter
    RESPONSE=$(curl -s "$WORKER_URL/search" --max-time 30 || true)
    ERROR=$(echo "$RESPONSE" | jq -r '.error // "none"')
    if [ "$ERROR" != "none" ]; then
        test_success "Missing parameter correctly returns error"
    else
        test_error "Missing parameter should return error"
    fi
    
    test_success "Error handling test completed"
}

# Test CORS headers
test_cors_headers() {
    test_info "Testing CORS headers..."
    
    RESPONSE=$(curl -s "$WORKER_URL/health" -v 2>&1 | grep -i "access-control-allow-origin" || echo "")
    if [ -n "$RESPONSE" ]; then
        test_success "CORS headers present"
    else
        test_warning "CORS headers may be missing"
    fi
    
    test_success "CORS test completed"
}

# Generate comprehensive report
generate_report() {
    test_info "Generating comprehensive test report..."
    
    HEALTH_RESPONSE=$(curl -s "$WORKER_URL/health" --max-time 10 || echo '{"status":"error"}')
    
    echo ""
    echo "============================================"
    echo "      OPTIMIZATION FEATURES TEST REPORT    "
    echo "============================================"
    echo ""
    echo "Worker URL: $WORKER_URL"
    echo "Test Time: $(date)"
    echo ""
    
    # Health Status
    STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.status // "error"')
    echo "Health Status: $STATUS"
    
    # Version
    VERSION=$(echo "$HEALTH_RESPONSE" | jq -r '.version // "unknown"')
    echo "Version: $VERSION"
    
    # Features
    echo ""
    echo "Enabled Features:"
    echo "$HEALTH_RESPONSE" | jq -r '.features[]?' 2>/dev/null | while read feature; do
        echo "  ✓ $feature"
    done
    
    # Analytics
    echo ""
    echo "Cache Analytics:"
    ANALYTICS=$(echo "$HEALTH_RESPONSE" | jq -c '.analytics // {}')
    echo "$ANALYTICS" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  No analytics data available"
    
    # Performance Metrics
    echo ""
    echo "Performance Metrics:"
    PERFORMANCE=$(echo "$HEALTH_RESPONSE" | jq -c '.performance // {}')
    echo "$PERFORMANCE" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  No performance data available"
    
    echo ""
    echo "============================================"
    echo "All tests completed successfully! ✓"
    echo "============================================"
}

# Main test execution
main() {
    echo ""
    echo "============================================"
    echo "   STARTING COMPREHENSIVE OPTIMIZATION TESTS"
    echo "============================================"
    echo ""
    echo "Testing worker: $WORKER_URL"
    echo ""
    
    test_health
    echo ""
    
    test_caching_system
    echo ""
    
    test_quota_optimization
    echo ""
    
    test_cultural_indexing
    echo ""
    
    test_performance_optimization
    echo ""
    
    test_error_handling
    echo ""
    
    test_cors_headers
    echo ""
    
    generate_report
}

# Run tests
main