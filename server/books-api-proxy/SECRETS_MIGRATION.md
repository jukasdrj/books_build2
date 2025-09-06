# Cloudflare Secrets Store to Worker Environment Variables Migration

## Overview

Due to limitations with the alpha Cloudflare Secrets Store API, we need to manually migrate API keys from the Secrets Store to Worker environment variables.

## Current Secrets Store Configuration

| Secrets Store Name | Secret ID | Worker Variable | Description |
|-------------------|-----------|-----------------|-------------|
| `Google_books_hardoooe` | `776ba36023fa4aeca3cfa45d3b26378e` | `google1` | Primary Google Books API key |
| `Google_books_ioskey` | `41dc6f80f65045b99b5040f8c0a37ba2` | `google2` | Secondary Google Books API key |
| `ISBN_search_key` | `d76bef738c324d4788ce1775b5aef680` | `ISBNdb1` | ISBNdb API key |
| `GOOGLE_SEARCH_API_KEY` | `21cfd588ab924752bc9f713eb649d4a0` | `GOOGLE_SEARCH_API_KEY` | Google Custom Search API key |

## Migration Steps

### Step 1: Retrieve Secret Values

Since the Secrets Store alpha API doesn't provide direct value access, retrieve the values from:

1. **Cloudflare Dashboard Method:**
   - Navigate to Cloudflare Dashboard
   - Go to Workers & Pages > Overview
   - Click on your account settings or secrets management
   - Look for Secrets Store section

2. **Your Records Method:**
   - Check your password manager
   - Check your secure notes/documentation
   - Check your original Google Cloud Console / ISBNdb account

### Step 2: Set Worker Environment Variables

Run these commands one by one, pasting the corresponding secret value when prompted:

```bash
# Set Primary Google Books API Key
wrangler secret put google1

# Set Secondary Google Books API Key  
wrangler secret put google2

# Set ISBNdb API Key
wrangler secret put ISBNdb1

# Set Google Search API Key (for future enhancement)
wrangler secret put GOOGLE_SEARCH_API_KEY
```

### Step 3: Verify Secrets are Set

```bash
wrangler secret list
```

Expected output:
```
[
  { "name": "google1", "type": "secret_text" },
  { "name": "google2", "type": "secret_text" },
  { "name": "ISBNdb1", "type": "secret_text" },
  { "name": "GOOGLE_SEARCH_API_KEY", "type": "secret_text" }
]
```

### Step 4: Deploy Worker

```bash
wrangler deploy
```

### Step 5: Test API Access

```bash
# Test health endpoint
curl -s "https://books-api-proxy.jukasdrj.workers.dev/health" | jq '.'

# Test search functionality
curl -s "https://books-api-proxy.jukasdrj.workers.dev/search?q=python&maxResults=2" | jq '.books[0].title'

# Test ISBN lookup
curl -s "https://books-api-proxy.jukasdrj.workers.dev/isbn?isbn=9780134685991" | jq '.title'
```

## Expected Results

After migration:

1. **Higher API Limits:** The worker will now use your higher-limit API keys instead of basic ones
2. **Better Performance:** More API quota means fewer rate limiting issues
3. **Reliable Access:** Environment variables are more stable than alpha Secrets Store binding

## Troubleshooting

### If secrets aren't working:
1. Verify secrets are set: `wrangler secret list`
2. Check worker logs: `wrangler tail books-api-proxy`
3. Test individual APIs to isolate issues

### If API calls fail:
1. Verify API keys are valid in Google Console / ISBNdb dashboard  
2. Check quota usage in respective API dashboards
3. Verify the keys have the required permissions

## Code Changes Required

The worker code is already prepared for this migration:

- Uses `env.google1` and `env.google2` for Google Books API
- Uses `env.ISBNdb1` for ISBNdb API  
- Has fallback logic between multiple keys

No code changes are needed - just setting the environment variables.

## Security Notes

- Environment variables in Cloudflare Workers are encrypted at rest
- They're only accessible to your worker code
- Consider rotating these keys periodically for security
- Never commit these values to version control

## Migration Script

Use the provided `migrate-secrets.sh` script for guided migration:

```bash
./migrate-secrets.sh
```

This script will prompt you for each secret value and set them automatically.