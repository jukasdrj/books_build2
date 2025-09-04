// Simple staging worker to test deployment before adding optimizations
export default {
  async fetch(request, env, ctx) {
    try {
      const url = new URL(request.url);
      
      // Basic health check
      if (url.pathname === '/' || url.pathname === '/health') {
        return new Response(JSON.stringify({
          status: 'ok',
          environment: 'staging',
          version: '3.0-simple-test',
          timestamp: new Date().toISOString(),
          bindings: {
            kv_books: !!env.BOOKS_CACHE,
            kv_authors: !!env.AUTHOR_PROFILES,
            r2_books: !!env.BOOKS_R2,
            r2_cultural: !!env.CULTURAL_DATA_R2
          }
        }), {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'X-Environment': 'staging',
            'X-Version': '3.0-simple-test'
          }
        });
      }
      
      // Basic search endpoint (without API calls for now)
      if (url.pathname === '/search') {
        const query = url.searchParams.get('q');
        if (!query) {
          return new Response(JSON.stringify({
            error: 'Missing query parameter',
            message: 'Please provide a search query with ?q=searchterm'
          }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          });
        }
        
        return new Response(JSON.stringify({
          status: 'staging_test',
          query: query,
          message: 'Search endpoint working - API integration will be added next',
          timestamp: new Date().toISOString()
        }), {
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
      
      // Basic ISBN endpoint
      if (url.pathname === '/isbn') {
        const isbn = url.searchParams.get('isbn');
        if (!isbn) {
          return new Response(JSON.stringify({
            error: 'Missing ISBN parameter',
            message: 'Please provide an ISBN with ?isbn=9781234567890'
          }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          });
        }
        
        return new Response(JSON.stringify({
          status: 'staging_test',
          isbn: isbn,
          message: 'ISBN endpoint working - API integration will be added next',
          timestamp: new Date().toISOString()
        }), {
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
      
      // Return 404 for other paths
      return new Response(JSON.stringify({
        error: 'Not Found',
        message: 'Available endpoints: /, /health, /search?q=term, /isbn?isbn=123',
        environment: 'staging'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
      
    } catch (error) {
      console.error('Worker error:', error);
      
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message || 'Unknown error occurred',
        environment: 'staging',
        timestamp: new Date().toISOString()
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
};