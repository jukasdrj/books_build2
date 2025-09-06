#!/bin/bash

echo "📚 FULL BOOK CACHE WARMING - CHUNKED APPROACH"
echo "=============================================="
echo "Warming all 270+ books in 25-book chunks to avoid CPU timeouts"
echo ""

BASE_URL="https://books-api-proxy.jukasdrj.workers.dev"
BATCH_SIZE=25
DELAY_BETWEEN_BATCHES=30  # seconds

# Counter for tracking progress
TOTAL_CACHED=0
TOTAL_FAILED=0
BATCH_COUNT=0

echo "📊 Strategy:"
echo "• Batch size: $BATCH_SIZE books per API call"
echo "• Delay between batches: $DELAY_BETWEEN_BATCHES seconds"  
echo "• Expected total batches: ~11 (270 ÷ 25)"
echo "• Expected total time: ~8 minutes"
echo ""

# Function to run a single batch and track results
run_batch() {
    local endpoint=$1
    local name=$2
    
    echo "🔄 Running batch: $name"
    
    BATCH_COUNT=$((BATCH_COUNT + 1))
    echo "   Batch #$BATCH_COUNT - $(date)"
    
    RESULT=$(curl -s -X POST "$BASE_URL$endpoint" \
        -H "Content-Type: application/json" \
        --max-time 120)
    
    if [ $? -eq 0 ]; then
        # Parse success/failure from JSON
        CACHED=$(echo "$RESULT" | jq -r '.results.cached // 0' 2>/dev/null)
        FAILED=$(echo "$RESULT" | jq -r '.results.failed // 0' 2>/dev/null)
        SUCCESS_RATE=$(echo "$RESULT" | jq -r '.results.successRate // "0%"' 2>/dev/null)
        
        if [ "$CACHED" != "null" ] && [ "$CACHED" != "0" ]; then
            echo "   ✅ Success: $CACHED cached, $FAILED failed ($SUCCESS_RATE success rate)"
            TOTAL_CACHED=$((TOTAL_CACHED + CACHED))
            TOTAL_FAILED=$((TOTAL_FAILED + FAILED))
        else
            echo "   ⚠️  Unexpected response: $RESULT"
            TOTAL_FAILED=$((TOTAL_FAILED + 25))
        fi
    else
        echo "   ❌ HTTP request failed"
        TOTAL_FAILED=$((TOTAL_FAILED + 25))
    fi
    
    echo "   📊 Running totals: $TOTAL_CACHED cached, $TOTAL_FAILED failed"
    echo ""
}

# Run all book cache warming batches
echo "🚀 Starting chunked cache warming..."
echo ""

# Batch 1: Core books (25 books)
run_batch "/cache/warm/books" "Core Books #1"
sleep $DELAY_BETWEEN_BATCHES

# Batch 2: Diverse books (25 books) 
run_batch "/cache/warm/diverse" "Diverse Books #1"
sleep $DELAY_BETWEEN_BATCHES

# Repeat core books to get more coverage (books array has 270 items)
# Each call processes 25 books, so we need ~11 total calls
for i in {3..11}; do
    run_batch "/cache/warm/books" "Core Books #$((i-1))"
    if [ $i -lt 11 ]; then
        echo "⏳ Waiting $DELAY_BETWEEN_BATCHES seconds before next batch..."
        sleep $DELAY_BETWEEN_BATCHES
    fi
done

echo "🎉 FULL CACHE WARMING COMPLETE!"
echo "==============================="
echo "📊 Final Results:"
echo "• Total books cached: $TOTAL_CACHED"
echo "• Total failures: $TOTAL_FAILED"
echo "• Overall success rate: $(echo "scale=1; $TOTAL_CACHED * 100 / ($TOTAL_CACHED + $TOTAL_FAILED)" | bc -l 2>/dev/null || echo "N/A")%"
echo "• Total batches run: $BATCH_COUNT"
echo "• Total time: ~$(date)"
echo ""

if [ $TOTAL_CACHED -gt 200 ]; then
    echo "🎯 EXCELLENT: Over 200 books cached - cache system is highly effective!"
elif [ $TOTAL_CACHED -gt 100 ]; then
    echo "🎯 GOOD: Over 100 books cached - solid cache foundation established"
else
    echo "⚠️  LIMITED: Less than 100 books cached - may need optimization"
fi

echo ""
echo "💡 Next steps:"
echo "• Monitor cache hit rates in CloudFlare analytics"
echo "• Test search performance with cached vs uncached books" 
echo "• Consider running this script daily to maintain fresh cache"