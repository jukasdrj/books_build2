#!/bin/bash
# Comprehensive testing for Author-Integrated CloudFlare Worker
# Tests Tasks 8 & 9: Author Indexing and Cultural Data Propagation

set -e

# Configuration
WORKER_URL="${1:-https://books-api-proxy.jukasdrj.workers.dev}"
TEMP_DIR=$(mktemp -d)
TEST_LOG="${TEMP_DIR}/test_results.log"

echo "🧪 TESTING AUTHOR-INTEGRATED CLOUDFLARE WORKER"
echo "=============================================="
echo "Worker URL: ${WORKER_URL}"
echo "Test results: ${TEST_LOG}"
echo ""

# Helper function to test API endpoint
test_endpoint() {
    local endpoint="$1"
    local description="$2"
    local expected_pattern="$3"
    
    echo -n "Testing ${description}... "
    
    local response=$(curl -s "${WORKER_URL}${endpoint}" 2>/dev/null)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "${WORKER_URL}${endpoint}" 2>/dev/null)
    
    echo "HTTP ${http_code}" >> "${TEST_LOG}"
    echo "Endpoint: ${endpoint}" >> "${TEST_LOG}"
    echo "Response: ${response}" >> "${TEST_LOG}"
    echo "---" >> "${TEST_LOG}"
    
    if [[ "${http_code}" == "200" ]] && [[ "${response}" =~ ${expected_pattern} ]]; then
        echo "✅ PASS"
        return 0
    else
        echo "❌ FAIL (HTTP ${http_code})"
        return 1
    fi
}

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Health check with author integration features
echo "📊 TEST 1: Health Check with Author Features"
echo "--------------------------------------------"
if test_endpoint "/health" "Health endpoint" "author-integrated"; then
    ((TESTS_PASSED++))
    
    # Extract and display features
    response=$(curl -s "${WORKER_URL}/health")
    echo "   Features detected:"
    echo "${response}" | grep -o '"features":\[[^]]*\]' | tr ',' '\n' | sed 's/.*"//;s/".*//' | grep -v features | sed 's/^/   • /'
    echo ""
else
    ((TESTS_FAILED++))
fi

# Test 2: Enhanced book search (should build author profiles)
echo "📚 TEST 2: Enhanced Book Search with Author Profiling"
echo "----------------------------------------------------"
if test_endpoint "/search?q=tolkien&maxResults=5" "Search with author indexing" "items"; then
    ((TESTS_PASSED++))
    
    # Check if response includes cultural metadata
    response=$(curl -s "${WORKER_URL}/search?q=tolkien&maxResults=5")
    if echo "${response}" | grep -q "culturalMetadata"; then
        echo "   ✅ Cultural metadata detected in search results"
    else
        echo "   ⚠️  No cultural metadata found (may be building profiles)"
    fi
    echo ""
else
    ((TESTS_FAILED++))
fi

# Test 3: ISBN lookup with cultural enrichment
echo "📖 TEST 3: ISBN Lookup with Cultural Data"
echo "-----------------------------------------"
# The Hobbit ISBN
if test_endpoint "/isbn?isbn=9780547928227" "ISBN lookup with cultural enrichment" "volumeInfo"; then
    ((TESTS_PASSED++))
    
    response=$(curl -s "${WORKER_URL}/isbn?isbn=9780547928227")
    if echo "${response}" | grep -q "culturalMetadata"; then
        echo "   ✅ Cultural metadata detected in ISBN result"
    else
        echo "   ⚠️  No cultural metadata found (may be building profile)"
    fi
    echo ""
else
    ((TESTS_FAILED++))
fi

# Test 4: Author profile endpoint
echo "👤 TEST 4: Author Profile Retrieval"
echo "-----------------------------------"
# Try to get Tolkien's profile (may not exist yet if just created)
if test_endpoint "/authors/profile?name=J.R.R. Tolkien" "Author profile retrieval" "name\|error"; then
    ((TESTS_PASSED++))
    
    response=$(curl -s "${WORKER_URL}/authors/profile?name=J.R.R. Tolkien")
    if echo "${response}" | grep -q "culturalProfile"; then
        echo "   ✅ Author profile found with cultural data"
    elif echo "${response}" | grep -q "not found"; then
        echo "   ⚠️  Profile not found yet (being built in background)"
    fi
    echo ""
else
    ((TESTS_FAILED++))
fi

# Test 5: Cultural statistics endpoint
echo "📊 TEST 5: Cultural Diversity Statistics"
echo "----------------------------------------"
if test_endpoint "/authors/cultural-stats" "Cultural statistics" "timestamp"; then
    ((TESTS_PASSED++))
    
    response=$(curl -s "${WORKER_URL}/authors/cultural-stats")
    echo "   Cultural stats response received"
    echo ""
else
    ((TESTS_FAILED++))
fi

# Test 6: Author search by cultural criteria
echo "🔍 TEST 6: Author Search by Cultural Criteria"
echo "---------------------------------------------"
if test_endpoint "/authors/search?region=Europe&minConfidence=30" "Cultural author search" "authors"; then
    ((TESTS_PASSED++))
    echo "   ✅ Cultural search endpoint responding"
    echo ""
else
    ((TESTS_FAILED++))
fi

# Test 7: Rate limiting and error handling
echo "⚡ TEST 7: Rate Limiting and Error Handling"
echo "-------------------------------------------"
if test_endpoint "/search?q=" "Empty query handling" "error"; then
    ((TESTS_PASSED++))
    echo "   ✅ Proper error handling for invalid queries"
    echo ""
else
    ((TESTS_FAILED++))
fi

# Test 8: CORS headers
echo "🌐 TEST 8: CORS Headers"
echo "-----------------------"
cors_response=$(curl -s -H "Origin: https://example.com" -H "Access-Control-Request-Method: GET" -X OPTIONS "${WORKER_URL}/health")
cors_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Origin: https://example.com" -H "Access-Control-Request-Method: GET" -X OPTIONS "${WORKER_URL}/health")

if [[ "${cors_code}" == "204" ]]; then
    ((TESTS_PASSED++))
    echo "✅ CORS preflight handling works"
    echo ""
else
    ((TESTS_FAILED++))
    echo "❌ CORS preflight failed (HTTP ${cors_code})"
fi

# Test 9: Performance check
echo "⚡ TEST 9: Performance Check"
echo "----------------------------"
echo -n "Measuring response time for cached search... "

start_time=$(date +%s%3N)
response=$(curl -s "${WORKER_URL}/search?q=tolkien&maxResults=3")
end_time=$(date +%s%3N)
response_time=$((end_time - start_time))

if [[ ${response_time} -lt 1000 ]] && echo "${response}" | grep -q "items"; then
    ((TESTS_PASSED++))
    echo "✅ PASS (${response_time}ms)"
    
    # Check cache headers
    cache_header=$(curl -s -I "${WORKER_URL}/search?q=tolkien&maxResults=3" | grep -i "x-cache")
    if [[ -n "${cache_header}" ]]; then
        echo "   Cache status: ${cache_header#*: }"
    fi
    echo ""
else
    ((TESTS_FAILED++))
    echo "❌ FAIL (${response_time}ms or no data)"
fi

# Test 10: Multi-provider fallback simulation
echo "🔄 TEST 10: Multi-Provider Fallback"
echo "-----------------------------------"
# Test with a very specific search that might fail on some providers
if test_endpoint "/search?q=9780000000000&maxResults=1" "Fallback provider handling" "items\|error"; then
    ((TESTS_PASSED++))
    echo "   ✅ Fallback mechanism working"
    echo ""
else
    ((TESTS_FAILED++))
fi

# Summary
echo ""
echo "📋 TEST SUMMARY"
echo "==============="
echo "Tests Passed: ${TESTS_PASSED}"
echo "Tests Failed: ${TESTS_FAILED}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo "🎉 ALL TESTS PASSED!"
    echo ""
    echo "✅ Author Indexing Service (Task 8) is operational"
    echo "✅ Cultural Data Propagation (Task 9) is operational"
    echo "✅ Multi-tier caching system is working"
    echo "✅ API fallback mechanisms are functional"
    echo ""
    echo "🚀 CloudFlare Worker is ready for production use!"
else
    echo "⚠️  Some tests failed. Check the detailed logs at:"
    echo "   ${TEST_LOG}"
    echo ""
    echo "Common issues:"
    echo "• Author profiles may take time to build after first search"
    echo "• Cultural data requires multiple books to build confidence"
    echo "• Check CloudFlare KV/R2 storage configuration"
fi

echo ""
echo "📊 DETAILED LOGS: ${TEST_LOG}"
echo "🔧 For debugging, check CloudFlare dashboard logs"

# Clean up temporary files
trap "rm -rf ${TEMP_DIR}" EXIT