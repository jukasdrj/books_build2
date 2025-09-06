# Books API Proxy Tail Worker

A CloudFlare Tail Worker that monitors, analyzes, and provides real-time observability for the `books-api-proxy` worker.

## Features

### 🔍 Real-Time Monitoring
- **Performance Metrics**: Request duration, cache hit rates, API response times
- **Error Tracking**: Exception monitoring with detailed error analysis
- **Cache Analytics**: KV/R2 usage patterns and optimization insights
- **Geographic Insights**: Request distribution by country and CloudFlare colo

### 🚨 Intelligent Alerting
- **Error Rate Alerts**: Triggers when error rate exceeds 10%
- **Performance Alerts**: Warns when >20% of requests are slow (>5s)
- **Cache Efficiency**: Monitors cache miss rates and storage patterns
- **Automated Storage**: Alerts stored in KV for dashboard access

### 📊 Analytics & Reporting
- **Hourly Aggregation**: Detailed metrics stored for 7 days
- **Real-Time Data**: Minute-by-minute performance snapshots
- **Usage Patterns**: API endpoint popularity and search query analysis
- **Provider Tracking**: Google Books vs ISBNdb vs Open Library usage

## Quick Start

### 1. Deploy the Tail Worker
```bash
cd server/books-api-tail
./deploy.sh
```

The deployment script will:
- Create necessary KV namespaces
- Update configuration with actual namespace IDs  
- Deploy the tail worker to CloudFlare

### 2. Verify Deployment
```bash
# Check if the tail worker is running
wrangler tail books-api-proxy

# View worker status
wrangler status books-api-tail
```

### 3. Monitor Analytics
The tail worker automatically stores analytics in KV storage:

**Hourly Metrics**: `analytics:YYYY-MM-DDTHH`
```json
{
  "requests": 1250,
  "errors": 12,
  "cacheHits": 892,
  "cacheMisses": 358,
  "totalDuration": 15420,
  "apiCalls": 358,
  "countries": {"US": 456, "GB": 123, "CA": 89},
  "endpoints": {"/api/books/search": 890, "/api/books/details": 360},
  "providers": {"google_books": 280, "isbndb": 78}
}
```

**Real-Time Metrics**: `realtime:YYYY-MM-DDTHHMM`
```json
{
  "timestamp": "2025-01-06T15:30:00Z",
  "requestCount": 45,
  "errorCount": 2,
  "cacheHitCount": 32,
  "avgDuration": 145
}
```

**Latest Alerts**: `alerts:latest`
```json
{
  "timestamp": "2025-01-06T15:30:00Z",
  "alerts": [
    {
      "type": "high_error_rate",
      "severity": "critical",
      "message": "High error rate: 12.3% (15/122)",
      "timestamp": "2025-01-06T15:30:00Z"
    }
  ]
}
```

## Configuration

Edit `wrangler.toml` to customize monitoring thresholds:

```toml
[vars]
ALERT_THRESHOLD_ERROR_RATE = "0.1"     # 10% error rate
ALERT_THRESHOLD_SLOW_RATE = "0.2"      # 20% slow requests  
ALERT_THRESHOLD_CACHE_MISS = "0.5"     # 50% cache miss rate
SLOW_REQUEST_THRESHOLD = "5000"        # 5 seconds
RETENTION_HOURS = "168"                # 7 days
```

## Advanced Usage

### Custom Analytics Queries
Access analytics data programmatically:

```javascript
// Get hourly metrics for last 24 hours
const hours = [];
for (let i = 0; i < 24; i++) {
  const hour = new Date(Date.now() - i * 60 * 60 * 1000)
    .toISOString().substring(0, 13);
  const metrics = await env.TAIL_ANALYTICS.get(`analytics:${hour}`);
  if (metrics) hours.push(JSON.parse(metrics));
}
```

### Real-Time Monitoring
```bash
# Stream live logs from the main API proxy
wrangler tail books-api-proxy

# View tail worker logs (processing output)
wrangler tail books-api-tail
```

### Performance Optimization Insights
The tail worker provides actionable insights:

1. **Cache Optimization**: Identifies frequently missed queries for warming
2. **Geographic Patterns**: Shows regional usage for edge optimization
3. **API Provider Efficiency**: Tracks which providers are fastest/most reliable
4. **Error Pattern Analysis**: Groups errors by type for targeted fixes

## Architecture

```
[books-api-proxy] ----logs----> [books-api-tail]
                                       |
                                   Analytics
                                       |
                                   ┌─────────┐
                                   │   KV    │
                                   │ Storage │
                                   └─────────┘
                                       |
                              ┌────────────────┐
                              │  • Hourly Metrics
                              │  • Real-time Data  
                              │  • Alert History
                              │  • Performance Trends
                              └────────────────┘
```

## Troubleshooting

### Common Issues

**Tail worker not receiving events:**
```bash
# Check if the main worker is generating logs
wrangler tail books-api-proxy

# Verify tail worker configuration
wrangler status books-api-tail
```

**KV namespace issues:**
```bash
# List all KV namespaces
wrangler kv:namespace list

# Manually create if needed
wrangler kv:namespace create TAIL_ANALYTICS
```

**Missing analytics data:**
```bash
# Check KV storage contents
wrangler kv:key list --namespace-id=YOUR_NAMESPACE_ID

# View specific analytics
wrangler kv:key get "analytics:2025-01-06T15" --namespace-id=YOUR_NAMESPACE_ID
```

### Performance Considerations

- **Batch Processing**: Events are processed in batches for efficiency
- **Storage Optimization**: Hourly aggregation reduces storage costs
- **TTL Management**: Automatic cleanup prevents storage bloat
- **Error Resilience**: Tail worker continues processing even if storage fails

## Cost Optimization

The tail worker is designed to minimize CloudFlare costs:

- **KV Operations**: ~1,000 writes/day for typical usage
- **Compute Time**: <1ms per event (sub-millisecond billing)
- **Storage**: ~50KB/day of analytics data
- **Estimated Cost**: <$0.50/month for moderate traffic

## Monitoring the Monitor

The tail worker includes self-monitoring:
- Logs processing errors to console
- Tracks its own performance metrics
- Provides alerts about its own health
- Graceful degradation when storage fails

---

## Development

### Local Development
```bash
# Install dependencies
npm install

# Start local development
npm run dev

# Test with local books API proxy
wrangler dev --local --port 8788
```

### Deployment Options
```bash
# Standard deployment
npm run deploy

# Deploy to specific environment
wrangler deploy --env production

# Deploy with custom configuration
wrangler deploy --var ALERT_THRESHOLD_ERROR_RATE:0.05
```