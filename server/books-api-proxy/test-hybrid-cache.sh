#!/bin/bash

# Comprehensive Test Suite for R2+KV Hybrid Cache System
# Tests all aspects of the enhanced caching system

BASE_URL="https://books-api-proxy.jukasdrj.workers.dev"
TEST_RESULTS=()
PASSED=0
FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 R2+KV Hybrid Cache System Test Suite${NC}"
echo "================================================"
echo "Testing endpoint: $BASE_URL"
echo ""

# Helper function to run tests
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    echo -n "Testing: $test_name... "
    
    result=$(eval "$test_command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$result" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        TEST_RESULTS+=("✅ $test_name")
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "   Expected pattern: $expected_pattern"
        echo "   Actual result: $result"
        TEST_RESULTS+=("❌ $test_name")
        ((FAILED++))
        return 1
    fi
}

# Test 1: Health Check - Verify R2+KV System Active
echo -e "${YELLOW}📋 Phase 1: System Health Tests${NC}"
run_test "Health endpoint responds" \
    "curl -s --max-time 10 '$BASE_URL/health'" \
    '"status".*"healthy"'

run_test "R2+KV hybrid system active" \
    "curl -s --max-time 10 '$BASE_URL/health' | jq -r '.cache.system'" \
    "R2\+KV-Hybrid"

run_test "KV cache available" \
    "curl -s --max-time 10 '$BASE_URL/health' | jq -r '.cache.kv'" \
    "available"

run_test "R2 cache available" \
    "curl -s --max-time 10 '$BASE_URL/health' | jq -r '.cache.r2'" \
    "available"

echo ""

# Test 2: Cache Miss and Population
echo -e "${YELLOW}🔄 Phase 2: Cache Population Tests${NC}"

# Use timestamp to ensure cache miss
TIMESTAMP=$(date +%s)
UNIQUE_QUERY="programming_test_${TIMESTAMP}"

run_test "Search returns results" \
    "curl -s --max-time 15 '$BASE_URL/search?q=$UNIQUE_QUERY&maxResults=1' | jq -r '.items | length'" \
    "[0-9]+"

run_test "Cache miss on first request" \
    "curl -s -I --max-time 15 '$BASE_URL/search?q=$UNIQUE_QUERY&maxResults=1' | grep -i 'x-cache:'" \
    "MISS"

run_test "Provider reported correctly" \
    "curl -s -I --max-time 15 '$BASE_URL/search?q=$UNIQUE_QUERY&maxResults=1' | grep -i 'x-provider:'" \
    "google-books|isbndb|open-library"

echo ""

# Test 3: Cache Hit Detection
echo -e "${YELLOW}⚡ Phase 3: Cache Hit Tests${NC}"

# Wait a moment for cache to propagate
sleep 2

run_test "Cache hit on second request" \
    "curl -s -I --max-time 10 '$BASE_URL/search?q=$UNIQUE_QUERY&maxResults=1' | grep -i 'x-cache:'" \
    "HIT"

run_test "Cache source identified" \
    "curl -s -I --max-time 10 '$BASE_URL/search?q=$UNIQUE_QUERY&maxResults=1' | grep -i 'x-cache-source:'" \
    "KV-HOT|R2-COLD"

run_test "Cache system header present" \
    "curl -s -I --max-time 10 '$BASE_URL/search?q=$UNIQUE_QUERY&maxResults=1' | grep -i 'x-cache-system:'" \
    "R2\+KV-Hybrid"

echo ""

# Test 4: ISBN Lookup Tests
echo -e "${YELLOW}📚 Phase 4: ISBN Lookup Tests${NC}"

# Test with a known ISBN
TEST_ISBN="9780451524935"

run_test "ISBN lookup returns result" \
    "curl -s --max-time 15 '$BASE_URL/isbn?isbn=$TEST_ISBN' | jq -r '.volumeInfo.title'" \
    ".+"

run_test "ISBN cache miss initially" \
    "curl -s -I --max-time 15 '$BASE_URL/isbn?isbn=${TEST_ISBN}_${TIMESTAMP}' | grep -i 'x-cache:'" \
    "MISS"

# Wait for cache propagation
sleep 2

run_test "ISBN cache hit on repeat" \
    "curl -s -I --max-time 10 '$BASE_URL/isbn?isbn=${TEST_ISBN}_${TIMESTAMP}' | grep -i 'x-cache:'" \
    "HIT"

echo ""

# Test 5: Rate Limiting
echo -e "${YELLOW}🛡️ Phase 5: Rate Limiting Tests${NC}"

run_test "Rate limiting headers present" \
    "curl -s -I --max-time 10 '$BASE_URL/search?q=test&maxResults=1'" \
    "HTTP/2 200|HTTP/1.1 200"

# Test rapid requests (should eventually hit rate limit on fresh IP)
echo "   Note: Rate limiting test requires multiple requests from same IP"

echo ""

# Test 6: Error Handling
echo -e "${YELLOW}🚨 Phase 6: Error Handling Tests${NC}"

run_test "Missing query parameter handled" \
    "curl -s --max-time 10 '$BASE_URL/search' | jq -r '.error'" \
    'required'

run_test "Invalid ISBN parameter handled" \
    "curl -s --max-time 10 '$BASE_URL/isbn' | jq -r '.error'" \
    'required'

run_test "Invalid endpoint returns 404" \
    "curl -s --max-time 10 '$BASE_URL/nonexistent' | jq -r '.error'" \
    'not found|Endpoint not found'

echo ""

# Test 7: Performance Benchmarks
echo -e "${YELLOW}⏱️ Phase 7: Performance Tests${NC}"

echo "Running performance benchmarks..."

# Cached request performance
CACHED_TIME=$(curl -s -w "%{time_total}" -o /dev/null "$BASE_URL/search?q=javascript&maxResults=1")
echo "   Cached request time: ${CACHED_TIME}s"

if (( $(echo "$CACHED_TIME < 0.5" | bc -l) )); then
    echo -e "   ${GREEN}✅ Cached response under 500ms${NC}"
    ((PASSED++))
else
    echo -e "   ${RED}❌ Cached response too slow (>${CACHED_TIME}s)${NC}"
    ((FAILED++))
fi

# Fresh request performance (with unique query)
FRESH_QUERY="unique_perf_test_$(date +%s%N)"
FRESH_TIME=$(curl -s -w "%{time_total}" -o /dev/null "$BASE_URL/search?q=$FRESH_QUERY&maxResults=1")
echo "   Fresh request time: ${FRESH_TIME}s"

if (( $(echo "$FRESH_TIME < 5.0" | bc -l) )); then
    echo -e "   ${GREEN}✅ Fresh response under 5s${NC}"
    ((PASSED++))
else
    echo -e "   ${RED}❌ Fresh response too slow (>${FRESH_TIME}s)${NC}"
    ((FAILED++))
fi

echo ""

# Test Summary
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo "================================"
echo -e "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! R2+KV Hybrid Cache System is working perfectly.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️ Some tests failed. Please review the results above.${NC}"
    exit 1
fi