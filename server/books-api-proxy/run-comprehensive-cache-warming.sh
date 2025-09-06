#!/bin/bash

# Comprehensive Cache Warming Script for Books API
# Runs multiple cache warming batches to populate 200+ books while respecting CloudFlare limits

BASE_URL="https://books-api-proxy.jukasdrj.workers.dev"
TOTAL_RUNS=6  # 6 runs × 50 books = 300 books maximum
DELAY_BETWEEN_RUNS=10  # 10 seconds between runs

echo "🔥 Starting Comprehensive Cache Warming Process"
echo "========================================================"
echo "Target: Warm cache with 300+ popular books from 2024-2025"
echo "Strategy: Multiple small batches (50 books each) to avoid CloudFlare limits"
echo "Base URL: $BASE_URL"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track results
TOTAL_CACHED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0
RUN_RESULTS=()

for run in $(seq 1 $TOTAL_RUNS); do
    echo -e "${BLUE}📦 Cache Warming Run $run/$TOTAL_RUNS${NC}"
    echo "----------------------------------------"
    
    # Execute cache warming
    echo "Executing cache warming batch..."
    RESULT=$(curl -s -X POST "$BASE_URL/cache/warm" -H "Content-Type: application/json" --max-time 60)
    
    if [ $? -eq 0 ]; then
        # Parse results
        STATUS=$(echo "$RESULT" | jq -r '.status' 2>/dev/null)
        CACHED=$(echo "$RESULT" | jq -r '.results.cached' 2>/dev/null)
        SKIPPED=$(echo "$RESULT" | jq -r '.results.skipped' 2>/dev/null)
        FAILED=$(echo "$RESULT" | jq -r '.results.failed' 2>/dev/null)
        SUCCESS_RATE=$(echo "$RESULT" | jq -r '.results.successRate' 2>/dev/null)
        TOTAL_TIME=$(echo "$RESULT" | jq -r '.results.totalTime' 2>/dev/null)
        
        if [ "$STATUS" = "completed" ]; then
            echo -e "${GREEN}✅ Run $run completed successfully${NC}"
            echo "   📚 Cached: $CACHED books"
            echo "   ⏭️  Skipped: $SKIPPED books (already cached)"
            echo "   ❌ Failed: $FAILED books"
            echo "   📈 Success Rate: $SUCCESS_RATE"
            echo "   ⏱️  Execution Time: ${TOTAL_TIME}ms"
            
            # Update totals
            TOTAL_CACHED=$((TOTAL_CACHED + CACHED))
            TOTAL_SKIPPED=$((TOTAL_SKIPPED + SKIPPED))
            TOTAL_FAILED=$((TOTAL_FAILED + FAILED))
            
            RUN_RESULTS+=("Run $run: ✅ Cached=$CACHED, Skipped=$SKIPPED, Failed=$FAILED")
            
            # Test a few popular books to verify caching
            echo "   🔍 Testing cache hits for popular titles..."
            HITS=0
            TESTS=0
            for book in "Fourth+Wing+Rebecca+Yarros" "Atomic+Habits+James+Clear" "Dune+Frank+Herbert" "The+Midnight+Library+Matt+Haig"; do
                CACHE_STATUS=$(curl -s -I "$BASE_URL/search?q=$book&maxResults=3" | grep -i "x-cache:" | cut -d' ' -f2)
                if [ "$CACHE_STATUS" = "HIT-KV-HOT" ]; then
                    HITS=$((HITS + 1))
                fi
                TESTS=$((TESTS + 1))
            done
            echo "   📊 Cache Hit Rate (test sample): $HITS/$TESTS books cached"
            
        else
            echo -e "${RED}❌ Run $run failed${NC}"
            echo "   Error: $RESULT"
            RUN_RESULTS+=("Run $run: ❌ FAILED")
        fi
    else
        echo -e "${RED}❌ Run $run failed - curl timeout or error${NC}"
        RUN_RESULTS+=("Run $run: ❌ TIMEOUT")
    fi
    
    echo ""
    
    # Wait between runs (except last one)
    if [ $run -lt $TOTAL_RUNS ]; then
        echo -e "${YELLOW}⏳ Waiting ${DELAY_BETWEEN_RUNS}s before next run...${NC}"
        sleep $DELAY_BETWEEN_RUNS
        echo ""
    fi
done

# Final summary
echo -e "${BLUE}📊 COMPREHENSIVE CACHE WARMING SUMMARY${NC}"
echo "========================================================"
echo -e "${GREEN}🎯 Total Books Cached: $TOTAL_CACHED${NC}"
echo -e "${YELLOW}⏭️  Total Books Skipped: $TOTAL_SKIPPED${NC}"
echo -e "${RED}❌ Total Books Failed: $TOTAL_FAILED${NC}"
echo ""
echo "📋 Run-by-Run Results:"
for result in "${RUN_RESULTS[@]}"; do
    echo "   $result"
done
echo ""

# Performance verification
echo -e "${BLUE}🚀 Final Performance Verification${NC}"
echo "----------------------------------------"
echo "Testing response times for cached vs non-cached books..."

# Test cached books performance
echo "🔥 Cached Books Performance:"
for book in "Fourth+Wing+Rebecca+Yarros" "Iron+Flame+Rebecca+Yarros" "Atomic+Habits+James+Clear"; do
    echo -n "   $book: "
    TIME=$(curl -s -w "%{time_total}" -o /dev/null "$BASE_URL/search?q=$book&maxResults=3")
    CACHE_STATUS=$(curl -s -I "$BASE_URL/search?q=$book&maxResults=3" | grep -i "x-cache:" | cut -d' ' -f2)
    echo "${TIME}s ($CACHE_STATUS)"
done

echo ""
echo -e "${GREEN}🎉 Cache Warming Process Complete!${NC}"

# Final cache status check
echo ""
echo "📈 Checking final cache warming status..."
curl -s "$BASE_URL/cache/warm" | jq '.' 2>/dev/null || echo "Status check failed"