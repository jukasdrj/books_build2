# Books API Proxy

A CloudFlare Worker that provides a unified API for book search across multiple providers with **R2+KV Hybrid Caching**, intelligent fallbacks, and comprehensive rate limiting.

## 🚀 Architecture Overview

```
Request → Rate Limit → Hot Cache (KV) → Cold Cache (R2) → API Providers → Response
                           ↑                ↑
                    Fast Access         High Capacity
                   100k reads/day      10M reads/month
                      1GB storage        10GB storage
```

## ✨ Features

### 🔍 Multi-Provider Search Chain
1. **Google Books API** (primary) - Comprehensive book data
2. **ISBNdb API** (premium fallback) - 31+ million ISBNs, 19 data points  
3. **Open Library API** (free fallback) - Extensive catalog

### ⚡ Hybrid R2+KV Cache System
- **Hot Cache (KV)**: Lightning-fast access for popular queries
- **Cold Cache (R2)**: High-capacity long-term storage (10GB free)
- **Smart Promotion**: R2 hits automatically promoted to KV
- **Extended TTLs**: 30 days (searches), 1 year (ISBN lookups)
- **Graceful Fallback**: R2 failures don't break KV cache

### 🛡️ Performance & Reliability
- **100x Read Capacity**: 100k/day → 10M/month with R2
- **10x Storage**: 1GB → 10GB capacity increase
- **Rate Limiting** - 100 requests/hour per IP
- **Intelligent Fallbacks** - Multi-tier provider chain
- **CORS Support** - Ready for web and mobile apps

### 📊 Analytics Ready
- Provider success/failure tracking
- Cache hit rates
- Request patterns by IP

## Endpoints

### Search Books
```
GET /search?q=QUERY&maxResults=20&orderBy=relevance&langRestrict=en
```

**Parameters:**
- `q` (required) - Search query (title, author, or keywords)
- `maxResults` (optional) - Number of results (default: 20, max: 40)
- `orderBy` (optional) - Sort order: `relevance` or `newest`
- `langRestrict` (optional) - Language restriction (e.g., `en` for English only)

### ISBN Lookup
```
GET /isbn?isbn=9780451524935
```

**Parameters:**
- `isbn` (required) - ISBN-10 or ISBN-13

### Health Check
```
GET /health
```

## Setup Instructions

### 1. Install Dependencies
```bash
cd server/books-api-proxy
npm install
```

### 2. Set Up Storage (R2 + KV)
```bash
# R2 buckets for cold cache (high capacity)
npx wrangler r2 bucket create books-cache
npx wrangler r2 bucket create books-cache-preview

# KV namespace for hot cache (fast access) - if not already created
npx wrangler kv:namespace create "BOOKS_CACHE"
npx wrangler kv:namespace create "BOOKS_CACHE" --preview
```

### 3. Configure API Keys
```bash
# Required: Google Books API keys (primary and backup)
npx wrangler secret put google1        # Primary Google Books API key
npx wrangler secret put google2        # Backup Google Books API key

# Required: ISBNdb API key (premium fallback provider)
npx wrangler secret put ISBNdb1        # ISBNdb API key for 31M+ ISBN database
```

**API Key Setup Guide:**
1. **Google Books API Keys**: Get from [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Books API
   - Create 2 API keys for redundancy
   - Restrict keys to Books API only

2. **ISBNdb API Key**: Get from [ISBNdb.com](https://isbndb.com/)
   - Sign up for API access
   - Choose plan based on usage (starts at $10/month)
   - Provides access to 31+ million ISBNs with 19 data points

### 4. Deploy with R2+KV Hybrid System
```bash
# Automated deployment (creates R2 buckets + deploys worker)
./deploy-r2-cache.sh

# Or manual deployment
npx wrangler deploy --env=""
```

### 5. Test R2+KV Hybrid Cache System
```bash
# Test health endpoint (verify R2+KV system status)
curl "https://books-api-proxy.jukasdrj.workers.dev/health" | jq '.cache'

# Test search with cache headers
curl -I "https://books-api-proxy.jukasdrj.workers.dev/search?q=programming&maxResults=1"

# Verify cache promotion: Run same query twice, check X-Cache-Source header
curl "https://books-api-proxy.jukasdrj.workers.dev/search?q=javascript&maxResults=1"

# Test ISBN lookup
curl "https://books-api-proxy.jukasdrj.workers.dev/isbn?isbn=9780451524935"

# Test ISBNdb fallback (when Google Books might be down)
curl "https://books-api-proxy.jukasdrj.workers.dev/search?q=obscure+technical+book"
```

## Adding New Providers

To add a new book provider (e.g., Amazon Books API, Goodreads):

1. **Add provider function** in `src/index.js`:
```javascript
async function searchNewProvider(query, maxResults, env) {
  const response = await fetch(`https://new-api.com/search?q=${query}`);
  const data = await response.json();
  
  // Convert to Google Books format
  return {
    kind: 'books#volumes',
    totalItems: data.total,
    items: data.results.map(convertToGoogleBooksFormat)
  };
}
```

2. **Add to fallback chain** in `handleBookSearch()`:
```javascript
// 4. New Provider (additional fallback)
if (!result || result.items?.length === 0) {
  try {
    result = await searchNewProvider(query, maxResults, env);
    provider = 'new-provider';
  } catch (error) {
    console.error('New Provider failed:', error.message);
  }
}
```

3. **Update health endpoint** to include new provider.

## 💰 Cost Estimation (Enhanced R2+KV System)

### CloudFlare Storage (FREE TIER CAPACITY)
#### KV Hot Cache
- **Free**: 100k reads/day, 1k writes/day, 1GB storage
- **Paid**: $0.50/million reads, $5.00/million writes

#### R2 Cold Cache  
- **Free**: 10M reads/month, 1M writes/month, 10GB storage
- **Paid**: $0.36/million reads, $4.50/million writes, $0.015/GB-month
- **No egress fees** (major cost advantage)

### API Providers
#### Google Books API
- **Free tier**: 1,000 requests/day (cached for 30 days)
- **Paid tier**: $0.50 per 1,000 requests

#### ISBNdb API (Premium Fallback)
- **Pricing**: $10-50/month depending on usage tier
- **Value**: 31+ million ISBNs, 19 data points per book

### **Total Monthly Cost**
- **Light Usage** (< 100k requests): **FREE** (within all free tiers)
- **Medium Usage** (1M requests): **$10-20/month** (mostly ISBNdb costs)  
- **Heavy Usage** (10M requests): **$50-100/month** (API + storage costs)

### **Cost Optimization Benefits**
- **100x cache capacity increase** drastically reduces API costs
- **R2 free egress** eliminates data transfer fees
- **Smart cache promotion** keeps popular queries in free KV tier
- **Long TTLs** (30 days/1 year) minimize repeated API calls

## 📊 Cache Monitoring & Headers

### Response Headers
```bash
X-Cache: HIT-KV-HOT        # Cache hit from KV hot cache
X-Cache: HIT-R2-COLD       # Cache hit from R2 cold cache (promoted to KV)
X-Cache: MISS              # Cache miss, fetched from APIs
X-Cache-Source: KV-HOT     # Shows which cache tier served the response
X-Cache-System: R2+KV-Hybrid  # Confirms hybrid system is active
X-Provider: google-books   # Which API provider was used
```

### Health Endpoint Cache Status
```json
{
  "cache": {
    "system": "R2+KV-Hybrid",
    "kv": "available",
    "r2": "available"
  }
}
```

### Cache Behavior
1. **First Request**: Stored in both R2 (30 days) and KV (1 day)
2. **Hot Cache Hit**: Served from KV (`X-Cache-Source: KV-HOT`)
3. **Cold Cache Hit**: Served from R2, promoted to KV (`X-Cache-Source: R2-COLD`)
4. **Cache Miss**: Fetches from API chain, stores in both tiers

## 🔒 Security Features

- **No API keys exposed** to client apps
- **Rate limiting** - 100 requests/hour per IP prevents abuse
- **IP-based throttling** with CloudFlare edge intelligence
- **CORS properly configured** for cross-origin requests
- **Error handling** prevents API key or internal information leakage
- **Input validation** (TODO: needs enhancement)
- **Secure secret storage** via CloudFlare environment variables

## Response Format

All endpoints return Google Books API compatible format:

```json
{
  "kind": "books#volumes",
  "totalItems": 1234,
  "provider": "google-books",
  "cached": false,
  "items": [
    {
      "kind": "books#volume",
      "id": "book-id",
      "volumeInfo": {
        "title": "Book Title",
        "authors": ["Author Name"],
        "publishedDate": "2023",
        "publisher": "Publisher",
        "description": "Book description...",
        "industryIdentifiers": [
          {
            "type": "ISBN_13",
            "identifier": "9780123456789"
          }
        ],
        "pageCount": 300,
        "categories": ["Fiction"],
        "imageLinks": {
          "thumbnail": "https://covers.example.com/thumb.jpg"
        },
        "language": "en",
        "previewLink": "https://books.google.com/books?id=...",
        "infoLink": "https://books.google.com/books?id=..."
      }
    }
  ]
}
```