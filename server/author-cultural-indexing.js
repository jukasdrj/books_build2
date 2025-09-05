// Author Cultural Data Indexing System for CloudFlare Workers
// Builds author-to-works relationships and propagates cultural diversity metadata

export class AuthorCulturalIndexer {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    
    // Cultural diversity categorization system
    this.culturalCategories = {
      regions: {
        'Africa': ['DZ', 'AO', 'BW', 'BF', 'BI', 'CM', 'CV', 'CF', 'TD', 'KM', 'CG', 'CD', 'CI', 'DJ', 'EG', 'GQ', 'ER', 'ET', 'GA', 'GM', 'GH', 'GN', 'GW', 'KE', 'LS', 'LR', 'LY', 'MG', 'MW', 'ML', 'MR', 'MU', 'MA', 'MZ', 'NA', 'NE', 'NG', 'RW', 'ST', 'SN', 'SC', 'SL', 'SO', 'ZA', 'SS', 'SD', 'SZ', 'TZ', 'TG', 'TN', 'UG', 'ZM', 'ZW'],
        'Asia': ['AF', 'AM', 'AZ', 'BH', 'BD', 'BT', 'BN', 'KH', 'CN', 'CY', 'GE', 'IN', 'ID', 'IR', 'IQ', 'IL', 'JP', 'JO', 'KZ', 'KW', 'KG', 'LA', 'LB', 'MY', 'MV', 'MN', 'MM', 'NP', 'KP', 'OM', 'PK', 'PS', 'PH', 'QA', 'SA', 'SG', 'KR', 'LK', 'SY', 'TJ', 'TH', 'TL', 'TR', 'TM', 'AE', 'UZ', 'VN', 'YE'],
        'Europe': ['AL', 'AD', 'AM', 'AT', 'AZ', 'BY', 'BE', 'BA', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'GE', 'DE', 'GR', 'HU', 'IS', 'IE', 'IT', 'XK', 'LV', 'LI', 'LT', 'LU', 'MK', 'MT', 'MD', 'MC', 'ME', 'NL', 'NO', 'PL', 'PT', 'RO', 'RU', 'SM', 'RS', 'SK', 'SI', 'ES', 'SE', 'CH', 'UA', 'GB', 'VA'],
        'North America': ['US', 'CA', 'MX', 'GT', 'BZ', 'SV', 'HN', 'NI', 'CR', 'PA', 'CU', 'JM', 'HT', 'DO', 'PR', 'TT', 'BB', 'DM', 'GD', 'AG', 'KN', 'LC', 'VC'],
        'South America': ['AR', 'BO', 'BR', 'CL', 'CO', 'EC', 'FK', 'GF', 'GY', 'PY', 'PE', 'SR', 'UY', 'VE'],
        'Oceania': ['AU', 'FJ', 'KI', 'MH', 'FM', 'NR', 'NZ', 'PW', 'PG', 'WS', 'SB', 'TO', 'TV', 'VU']
      },
      
      genders: ['Female', 'Male', 'Non-binary', 'Other', 'Not specified'],
      
      languages: {
        'major': ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'ko', 'zh', 'ar', 'hi'],
        'african': ['sw', 'yo', 'ig', 'ha', 'am', 'so', 'zu', 'xh', 'af', 'rw'],
        'asian': ['th', 'vi', 'id', 'ms', 'tl', 'my', 'km', 'lo', 'ne', 'si', 'ta', 'te', 'ml', 'kn', 'gu', 'pa', 'bn'],
        'european': ['nl', 'sv', 'no', 'da', 'fi', 'pl', 'cs', 'sk', 'hu', 'ro', 'bg', 'hr', 'sr', 'sl', 'mk', 'sq', 'lt', 'lv', 'et'],
        'indigenous': ['qu', 'gn', 'ay', 'nv', 'ik', 'chr', 'lkt']
      }
    };
  }

  // Build comprehensive author profile with cultural metadata
  async buildAuthorProfile(authorName, books = []) {
    const normalizedName = this.normalizeAuthorName(authorName);
    const authorId = await this.generateAuthorId(normalizedName);
    
    try {
      // Check if author profile already exists
      let existingProfile = await this.getAuthorProfile(authorId);
      
      if (!existingProfile) {
        existingProfile = {
          id: authorId,
          name: authorName,
          normalizedName: normalizedName,
          aliases: [authorName],
          works: [],
          culturalProfile: {
            nationality: null,
            gender: 'Not specified',
            languages: [],
            regions: [],
            themes: [],
            lastUpdated: null,
            confidence: 0
          },
          metadata: {
            created: Date.now(),
            lastUpdated: Date.now(),
            version: '1.0',
            sources: [],
            workCount: 0
          }
        };
      }

      // Add new books to author's works
      for (const book of books) {
        await this.addBookToAuthor(existingProfile, book);
      }

      // Analyze cultural data from all works
      await this.analyzeCulturalData(existingProfile);
      
      // Update metadata
      existingProfile.metadata.lastUpdated = Date.now();
      existingProfile.metadata.workCount = existingProfile.works.length;

      // Store updated profile
      await this.storeAuthorProfile(existingProfile);
      
      console.log(`👤 AUTHOR PROFILE: ${authorName} (${existingProfile.works.length} works, confidence: ${existingProfile.culturalProfile.confidence}%)`);
      
      return existingProfile;
      
    } catch (error) {
      console.error(`Failed to build author profile for ${authorName}:`, error.message);
      return null;
    }
  }

  // Normalize author name for consistent indexing
  normalizeAuthorName(name) {
    return name
      .toLowerCase()
      .replace(/[^\w\s-]/g, '') // Remove special characters except hyphens
      .replace(/\s+/g, ' ')     // Normalize whitespace
      .trim();
  }

  // Generate unique author ID
  async generateAuthorId(normalizedName) {
    const encoder = new TextEncoder();
    const data = encoder.encode(normalizedName);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = new Uint8Array(hashBuffer);
    const hashHex = Array.from(hashArray)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
    return `author_${hashHex.substring(0, 16)}`;
  }

  // Get existing author profile
  async getAuthorProfile(authorId) {
    try {
      const cacheKey = `author/${authorId}`;
      const cached = await this.env.BOOKS_CACHE?.get(cacheKey);
      
      if (cached) {
        return JSON.parse(cached);
      }

      // Try R2 storage
      if (this.env.BOOKS_R2) {
        const r2Object = await this.env.BOOKS_R2.get(cacheKey);
        if (r2Object) {
          const data = JSON.parse(await r2Object.text());
          
          // Promote to KV for faster access
          this.ctx.waitUntil(
            this.env.BOOKS_CACHE?.put(cacheKey, JSON.stringify(data), { 
              expirationTtl: 604800 // 7 days
            })
          );
          
          return data;
        }
      }

      return null;
    } catch (error) {
      console.error(`Failed to get author profile ${authorId}:`, error.message);
      return null;
    }
  }

  // Store author profile in both KV and R2
  async storeAuthorProfile(profile) {
    const cacheKey = `author/${profile.id}`;
    const profileData = JSON.stringify(profile);
    
    const storagePromises = [];
    
    // Store in KV for fast access (7 days)
    storagePromises.push(
      this.env.BOOKS_CACHE?.put(cacheKey, profileData, { 
        expirationTtl: 604800 
      })
    );
    
    // Store in R2 for long-term storage (1 year)
    if (this.env.BOOKS_R2) {
      storagePromises.push(
        this.env.BOOKS_R2.put(cacheKey, profileData, {
          httpMetadata: {
            contentType: "application/json",
            cacheControl: "max-age=31536000"
          },
          customMetadata: {
            authorName: profile.name,
            workCount: profile.metadata.workCount.toString(),
            confidence: profile.culturalProfile.confidence.toString(),
            lastUpdated: profile.metadata.lastUpdated.toString(),
            type: 'author-profile'
          }
        })
      );
    }

    try {
      if (this.ctx?.waitUntil) {
        this.ctx.waitUntil(Promise.allSettled(storagePromises.filter(Boolean)));
      } else {
        await Promise.allSettled(storagePromises.filter(Boolean));
      }
    } catch (error) {
      console.error(`Failed to store author profile ${profile.id}:`, error.message);
    }
  }

  // Add book to author's works
  async addBookToAuthor(authorProfile, bookMetadata) {
    const workId = bookMetadata.id || bookMetadata.isbn13 || bookMetadata.isbn;
    
    // Check if work already exists
    const existingWork = authorProfile.works.find(work => work.id === workId);
    if (existingWork) {
      return; // Already added
    }

    const work = {
      id: workId,
      title: bookMetadata.title,
      publishedDate: bookMetadata.publishedDate,
      publisher: bookMetadata.publisher,
      language: bookMetadata.language || 'en',
      genres: bookMetadata.categories || [],
      isbn13: bookMetadata.industryIdentifiers?.find(id => id.type === 'ISBN_13')?.identifier,
      isbn10: bookMetadata.industryIdentifiers?.find(id => id.type === 'ISBN_10')?.identifier,
      culturalHints: this.extractCulturalHints(bookMetadata),
      addedAt: Date.now()
    };

    authorProfile.works.push(work);
    
    // Update aliases if different name variations found
    if (bookMetadata.authors) {
      for (const author of bookMetadata.authors) {
        if (author && !authorProfile.aliases.includes(author)) {
          authorProfile.aliases.push(author);
        }
      }
    }
  }

  // Extract cultural hints from book metadata
  extractCulturalHints(bookMetadata) {
    const hints = {
      languages: [],
      regions: [],
      themes: [],
      publishers: []
    };

    // Language hints
    if (bookMetadata.language) {
      hints.languages.push(bookMetadata.language);
    }

    // Regional hints from publisher
    if (bookMetadata.publisher) {
      const publisher = bookMetadata.publisher.toLowerCase();
      
      // Common publisher region patterns
      if (publisher.includes('oxford') || publisher.includes('cambridge') || 
          publisher.includes('penguin uk') || publisher.includes('faber')) {
        hints.regions.push('Europe');
      } else if (publisher.includes('simon') || publisher.includes('random house') || 
                 publisher.includes('harpercollins') || publisher.includes('macmillan')) {
        hints.regions.push('North America');
      }
      
      hints.publishers.push(bookMetadata.publisher);
    }

    // Thematic hints from categories and description
    if (bookMetadata.categories) {
      for (const category of bookMetadata.categories) {
        const categoryLower = category.toLowerCase();
        
        if (categoryLower.includes('african') || categoryLower.includes('africa')) {
          hints.themes.push('African Literature');
          hints.regions.push('Africa');
        } else if (categoryLower.includes('asian') || categoryLower.includes('japanese') || 
                   categoryLower.includes('chinese') || categoryLower.includes('indian')) {
          hints.themes.push('Asian Literature');
          hints.regions.push('Asia');
        } else if (categoryLower.includes('latin') || categoryLower.includes('hispanic') ||
                   categoryLower.includes('chicano')) {
          hints.themes.push('Latin American Literature');
          hints.regions.push('South America');
        }
      }
    }

    // Hints from title and description
    const textToAnalyze = [
      bookMetadata.title || '',
      bookMetadata.description || ''
    ].join(' ').toLowerCase();

    // Cultural keywords
    const culturalKeywords = {
      'Africa': ['african', 'nigeria', 'kenya', 'south africa', 'ghana', 'senegal', 'morocco', 'egypt'],
      'Asia': ['asian', 'chinese', 'japanese', 'korean', 'indian', 'thai', 'vietnamese', 'filipino'],
      'Europe': ['european', 'british', 'french', 'german', 'italian', 'spanish', 'scandinavian'],
      'Latin America': ['latin american', 'mexican', 'brazilian', 'argentinian', 'colombian', 'chilean'],
      'Indigenous': ['indigenous', 'native american', 'aboriginal', 'first nations', 'maori']
    };

    for (const [region, keywords] of Object.entries(culturalKeywords)) {
      for (const keyword of keywords) {
        if (textToAnalyze.includes(keyword)) {
          hints.regions.push(region);
          hints.themes.push(`${region} Literature`);
          break;
        }
      }
    }

    return hints;
  }

  // ===== ENHANCED GOOGLE APIs FOR BIOGRAPHICAL DATA =====
  
  // Get author biographical data from Google Knowledge Graph API
  async getAuthorBiographyFromKnowledgeGraph(authorName) {
    const apiKey = this.env.google1; // Using existing google1 key with KG access
    if (!apiKey) {
      console.warn('Google Knowledge Graph API key not available');
      return null;
    }

    try {
      const params = new URLSearchParams({
        query: `${authorName} author writer`,
        types: 'Person',
        languages: 'en',
        key: apiKey
      });

      const response = await fetch(
        `https://kgsearch.googleapis.com/v1/entities:search?${params}`,
        { 
          headers: { 'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy' },
          signal: AbortSignal.timeout(5000)
        }
      );

      if (!response.ok) {
        console.warn(`Knowledge Graph API error: ${response.status}`);
        return null;
      }

      const data = await response.json();
      return this.extractKnowledgeGraphCulturalData(data.itemListElement, authorName);

    } catch (error) {
      console.warn(`Knowledge Graph lookup failed for ${authorName}:`, error.message);
      return null;
    }
  }

  // Extract cultural data from Knowledge Graph response
  extractKnowledgeGraphCulturalData(entities, authorName) {
    if (!entities || entities.length === 0) return null;

    for (const entity of entities) {
      const item = entity.result;
      const name = item.name?.toLowerCase();
      const description = item.description?.toLowerCase() || '';
      const detailedDescription = item.detailedDescription?.articleBody?.toLowerCase() || '';
      
      // Verify this is likely the correct author
      if (!name || !name.includes(authorName.toLowerCase().split(' ')[0])) {
        continue;
      }

      // Check if this is an author/writer
      if (!description.includes('author') && !description.includes('writer') && 
          !description.includes('novelist') && !description.includes('poet')) {
        continue;
      }

      const culturalData = {
        nationality: this.extractNationalityFromKG(description, detailedDescription),
        gender: this.extractGenderFromKG(description, detailedDescription),
        birthPlace: this.extractBirthPlaceFromKG(detailedDescription),
        culturalBackground: this.extractCulturalBackgroundFromKG(detailedDescription),
        confidence: 85, // High confidence for Knowledge Graph data
        source: 'Google Knowledge Graph API',
        entityId: item['@id'],
        lastUpdated: Date.now()
      };

      console.log(`📚 KNOWLEDGE GRAPH: Found ${authorName} - ${culturalData.nationality}, ${culturalData.gender}`);
      return culturalData;
    }

    return null;
  }

  // Extract nationality from Knowledge Graph data
  extractNationalityFromKG(description, detailedDescription) {
    const text = `${description} ${detailedDescription}`;
    
    const nationalityPatterns = {
      'American': /\b(american|united states|usa|us)\b/,
      'British': /\b(british|england|uk|united kingdom|english)\b/,
      'Canadian': /\b(canadian|canada)\b/,
      'Australian': /\b(australian|australia)\b/,
      'French': /\b(french|france)\b/,
      'German': /\b(german|germany)\b/,
      'Italian': /\b(italian|italy)\b/,
      'Spanish': /\b(spanish|spain)\b/,
      'Japanese': /\b(japanese|japan)\b/,
      'Chinese': /\b(chinese|china)\b/,
      'Indian': /\b(indian|india)\b/,
      'Nigerian': /\b(nigerian|nigeria)\b/,
      'South African': /\b(south african|south africa)\b/,
      'Brazilian': /\b(brazilian|brazil)\b/,
      'Mexican': /\b(mexican|mexico)\b/,
      'Kenyan': /\b(kenyan|kenya)\b/,
      'Ghanaian': /\b(ghanaian|ghana)\b/,
      'Irish': /\b(irish|ireland)\b/,
      'Scottish': /\b(scottish|scotland)\b/,
      'Welsh': /\b(welsh|wales)\b/
    };

    for (const [nationality, pattern] of Object.entries(nationalityPatterns)) {
      if (pattern.test(text)) {
        return nationality;
      }
    }

    return null;
  }

  // Extract gender from Knowledge Graph data
  extractGenderFromKG(description, detailedDescription) {
    const text = `${description} ${detailedDescription}`;
    
    if (/\b(she|her|woman|female|actress|authoress)\b/.test(text)) {
      return 'Female';
    } else if (/\b(he|him|man|male|actor)\b/.test(text)) {
      return 'Male';
    }
    
    return 'Not specified';
  }

  // Extract birth place from Knowledge Graph data
  extractBirthPlaceFromKG(detailedDescription) {
    const birthPatterns = [
      /born in ([^,\.]+)/,
      /birth place[:\s]+([^,\.]+)/i,
      /native of ([^,\.]+)/
    ];

    for (const pattern of birthPatterns) {
      const match = detailedDescription.match(pattern);
      if (match) {
        return match[1].trim();
      }
    }

    return null;
  }

  // Extract cultural background from Knowledge Graph data
  extractCulturalBackgroundFromKG(detailedDescription) {
    const culturalKeywords = {
      'African': ['african', 'africa', 'diaspora', 'post-colonial'],
      'Asian': ['asian', 'east asian', 'south asian', 'oriental'],
      'Latin American': ['latin american', 'hispanic', 'latino', 'chicano'],
      'Indigenous': ['indigenous', 'native american', 'first nations', 'aboriginal'],
      'Caribbean': ['caribbean', 'west indian', 'antillean'],
      'Middle Eastern': ['middle eastern', 'arab', 'persian', 'islamic']
    };

    const themes = [];
    const text = detailedDescription.toLowerCase();

    for (const [background, keywords] of Object.entries(culturalKeywords)) {
      for (const keyword of keywords) {
        if (text.includes(keyword)) {
          themes.push(background);
          break;
        }
      }
    }

    return themes;
  }

  // Get author biographical data from Google Custom Search API
  async getAuthorBiographyFromCustomSearch(authorName) {
    const apiKey = this.env.GOOGLE_SEARCH_API_KEY;
    const cxId = this.env.GOOGLE_SEARCH_CX_ID || '017576662512468239146:omuauf_lfve'; // Default Books CX
    
    if (!apiKey) {
      console.warn('Google Custom Search API key not available');
      return null;
    }

    try {
      const queries = [
        `"${authorName}" author biography nationality gender`,
        `"${authorName}" writer cultural background ethnicity`,
        `"${authorName}" author diversity demographics`
      ];

      const allResults = [];

      for (const query of queries) {
        const params = new URLSearchParams({
          key: apiKey,
          cx: cxId,
          q: query,
          num: 3,
          safe: 'active'
        });

        const response = await fetch(
          `https://customsearch.googleapis.com/customsearch/v1?${params}`,
          { 
            headers: { 'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy' },
            signal: AbortSignal.timeout(5000)
          }
        );

        if (response.ok) {
          const data = await response.json();
          allResults.push(...(data.items || []));
        }

        // Rate limiting delay
        await new Promise(resolve => setTimeout(resolve, 200));
      }

      return this.parseCustomSearchBiographicalData(allResults, authorName);

    } catch (error) {
      console.warn(`Custom Search lookup failed for ${authorName}:`, error.message);
      return null;
    }
  }

  // Parse biographical data from Custom Search results
  parseCustomSearchBiographicalData(searchResults, authorName) {
    if (!searchResults || searchResults.length === 0) return null;

    const culturalData = {
      nationality: null,
      gender: 'Not specified',
      ethnicity: null,
      regions: [],
      languages: [],
      themes: [],
      confidence: 0,
      source: 'Google Custom Search API',
      lastUpdated: Date.now()
    };

    let totalText = '';
    for (const result of searchResults) {
      totalText += `${result.title} ${result.snippet} `.toLowerCase();
    }

    // Gender detection with higher precision
    const femaleIndicators = /\b(she|her|herself|woman|female|daughter|wife|mother|actress|authoress|ms\.|mrs\.|miss)\b/g;
    const maleIndicators = /\b(he|him|himself|man|male|son|husband|father|actor|mr\.)\b/g;

    const femaleMatches = (totalText.match(femaleIndicators) || []).length;
    const maleMatches = (totalText.match(maleIndicators) || []).length;

    if (femaleMatches > maleMatches && femaleMatches >= 2) {
      culturalData.gender = 'Female';
      culturalData.confidence += 25;
    } else if (maleMatches > femaleMatches && maleMatches >= 2) {
      culturalData.gender = 'Male';
      culturalData.confidence += 25;
    }

    // Enhanced nationality extraction
    const nationalityPatterns = {
      'American': /(american|united states|usa|us|born in america|from america)\b/,
      'British': /(british|england|uk|united kingdom|english|born in britain|from britain)\b/,
      'Canadian': /(canadian|canada|born in canada|from canada)\b/,
      'Australian': /(australian|australia|born in australia|from australia)\b/,
      'Nigerian': /(nigerian|nigeria|born in nigeria|from nigeria)\b/,
      'South African': /(south african|south africa|born in south africa)\b/,
      'Kenyan': /(kenyan|kenya|born in kenya|from kenya)\b/,
      'Ghanaian': /(ghanaian|ghana|born in ghana|from ghana)\b/,
      'Indian': /(indian|india|born in india|from india)\b/,
      'Chinese': /(chinese|china|born in china|from china)\b/,
      'Japanese': /(japanese|japan|born in japan|from japan)\b/,
      'French': /(french|france|born in france|from france)\b/,
      'German': /(german|germany|born in germany|from germany)\b/,
      'Brazilian': /(brazilian|brazil|born in brazil|from brazil)\b/,
      'Mexican': /(mexican|mexico|born in mexico|from mexico)\b/
    };

    for (const [nationality, pattern] of Object.entries(nationalityPatterns)) {
      if (pattern.test(totalText)) {
        culturalData.nationality = nationality;
        culturalData.confidence += 30;
        break;
      }
    }

    // Cultural/ethnic background detection
    const culturalPatterns = {
      'African American': /(african american|afro-american|black american)\b/,
      'Hispanic': /(hispanic|latino|latina|chicano|chicana)\b/,
      'Asian American': /(asian american|chinese american|japanese american|korean american)\b/,
      'Indigenous': /(indigenous|native american|first nations|aboriginal)\b/,
      'Jewish': /(jewish|judaism|hebrew)\b/,
      'Caribbean': /(caribbean|west indian|jamaican|haitian|trinidadian)\b/
    };

    for (const [ethnicity, pattern] of Object.entries(culturalPatterns)) {
      if (pattern.test(totalText)) {
        culturalData.ethnicity = ethnicity;
        culturalData.confidence += 15;
        break;
      }
    }

    // Regional and thematic extraction
    const regionalKeywords = {
      'Africa': ['african', 'nigeria', 'kenya', 'ghana', 'senegal', 'south africa'],
      'Asia': ['asian', 'chinese', 'japanese', 'indian', 'korean', 'vietnamese'],
      'Latin America': ['latin american', 'mexican', 'brazilian', 'argentinian', 'colombian'],
      'Caribbean': ['caribbean', 'jamaican', 'haitian', 'trinidadian'],
      'Middle East': ['middle eastern', 'arab', 'persian', 'israeli']
    };

    for (const [region, keywords] of Object.entries(regionalKeywords)) {
      for (const keyword of keywords) {
        if (totalText.includes(keyword)) {
          culturalData.regions.push(region);
          culturalData.themes.push(`${region} Literature`);
          culturalData.confidence += 10;
          break;
        }
      }
    }

    console.log(`🔍 CUSTOM SEARCH: ${authorName} - ${culturalData.nationality}, ${culturalData.gender} (${culturalData.confidence}% confidence)`);
    
    return culturalData.confidence > 20 ? culturalData : null;
  }

  // Enhanced author profile building with Google APIs
  async buildEnhancedAuthorProfile(authorName, books = []) {
    const profile = await this.buildAuthorProfile(authorName, books);
    if (!profile) return null;

    try {
      // Try Knowledge Graph API first (higher accuracy)
      let enhancedData = await this.getAuthorBiographyFromKnowledgeGraph(authorName);
      
      // Fallback to Custom Search if KG doesn't have data
      if (!enhancedData || enhancedData.confidence < 50) {
        const searchData = await this.getAuthorBiographyFromCustomSearch(authorName);
        if (searchData && (!enhancedData || searchData.confidence > enhancedData.confidence)) {
          enhancedData = searchData;
        }
      }

      // Merge enhanced data into profile
      if (enhancedData) {
        profile.culturalProfile.nationality = enhancedData.nationality || profile.culturalProfile.nationality;
        profile.culturalProfile.gender = enhancedData.gender !== 'Not specified' ? enhancedData.gender : profile.culturalProfile.gender;
        
        if (enhancedData.regions) {
          profile.culturalProfile.regions = [...new Set([...profile.culturalProfile.regions, ...enhancedData.regions])];
        }
        
        if (enhancedData.themes) {
          profile.culturalProfile.themes = [...new Set([...profile.culturalProfile.themes, ...enhancedData.themes])];
        }

        // Boost confidence with external data
        profile.culturalProfile.confidence = Math.min(100, profile.culturalProfile.confidence + (enhancedData.confidence * 0.3));
        
        // Track data sources
        profile.metadata.sources = profile.metadata.sources || [];
        profile.metadata.sources.push(enhancedData.source);
        profile.metadata.enhancedAt = Date.now();

        console.log(`🎯 ENHANCED PROFILE: ${authorName} (${profile.culturalProfile.confidence}% confidence from ${profile.metadata.sources.length} sources)`);
      }

      return profile;

    } catch (error) {
      console.error(`Enhanced profiling failed for ${authorName}:`, error.message);
      return profile; // Return basic profile if enhancement fails
    }
  }

  // Analyze and update cultural profile based on all works
  async analyzeCulturalData(authorProfile) {
    const culturalData = {
      languages: {},
      regions: {},
      themes: {},
      publishers: {},
      timeSpan: { earliest: null, latest: null }
    };

    // Aggregate data from all works
    for (const work of authorProfile.works) {
      // Language frequency
      if (work.language) {
        culturalData.languages[work.language] = 
          (culturalData.languages[work.language] || 0) + 1;
      }

      // Cultural hints aggregation
      if (work.culturalHints) {
        // Regions
        for (const region of work.culturalHints.regions) {
          culturalData.regions[region] = 
            (culturalData.regions[region] || 0) + 1;
        }

        // Themes
        for (const theme of work.culturalHints.themes) {
          culturalData.themes[theme] = 
            (culturalData.themes[theme] || 0) + 1;
        }

        // Publishers
        for (const publisher of work.culturalHints.publishers) {
          culturalData.publishers[publisher] = 
            (culturalData.publishers[publisher] || 0) + 1;
        }
      }

      // Time span
      if (work.publishedDate) {
        const year = parseInt(work.publishedDate.substring(0, 4));
        if (!isNaN(year)) {
          if (!culturalData.timeSpan.earliest || year < culturalData.timeSpan.earliest) {
            culturalData.timeSpan.earliest = year;
          }
          if (!culturalData.timeSpan.latest || year > culturalData.timeSpan.latest) {
            culturalData.timeSpan.latest = year;
          }
        }
      }
    }

    // Update cultural profile with highest confidence data
    const workCount = authorProfile.works.length;
    
    // Primary language (most frequent)
    const primaryLanguages = Object.entries(culturalData.languages)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 3)
      .map(([lang]) => lang);
    
    // Primary regions (most frequent)
    const primaryRegions = Object.entries(culturalData.regions)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 2)
      .map(([region]) => region);

    // Primary themes
    const primaryThemes = Object.entries(culturalData.themes)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5)
      .map(([theme]) => theme);

    // Calculate confidence based on consistency and work count
    let confidence = 0;
    if (workCount >= 3) confidence += 30;
    if (workCount >= 5) confidence += 20;
    if (workCount >= 10) confidence += 20;

    // Language consistency
    if (primaryLanguages.length > 0) {
      const topLangFreq = culturalData.languages[primaryLanguages[0]] / workCount;
      confidence += topLangFreq * 15;
    }

    // Regional consistency  
    if (primaryRegions.length > 0) {
      const topRegionFreq = culturalData.regions[primaryRegions[0]] / workCount;
      confidence += topRegionFreq * 15;
    }

    // Update cultural profile
    authorProfile.culturalProfile = {
      nationality: await this.inferNationality(culturalData),
      gender: authorProfile.culturalProfile.gender, // Preserve existing gender info
      languages: primaryLanguages,
      regions: primaryRegions,
      themes: primaryThemes,
      timeSpan: culturalData.timeSpan,
      lastUpdated: Date.now(),
      confidence: Math.min(100, Math.round(confidence))
    };
  }

  // Infer nationality from cultural data
  async inferNationality(culturalData) {
    // This is a simplified inference - in production you'd want more sophisticated logic
    const regionCounts = culturalData.regions;
    const publisherCounts = culturalData.publishers;
    
    if (!regionCounts || Object.keys(regionCounts).length === 0) {
      return null;
    }

    // Most frequent region
    const primaryRegion = Object.entries(regionCounts)
      .sort(([,a], [,b]) => b - a)[0]?.[0];

    // Publisher hints for specific countries
    const publishers = Object.keys(publisherCounts);
    for (const publisher of publishers) {
      const publisherLower = publisher.toLowerCase();
      
      if (publisherLower.includes('penguin uk') || publisherLower.includes('faber') ||
          publisherLower.includes('oxford')) {
        return 'British';
      } else if (publisherLower.includes('gallimard') || publisherLower.includes('seuil')) {
        return 'French';
      } else if (publisherLower.includes('suhrkamp') || publisherLower.includes('fischer')) {
        return 'German';
      }
    }

    // Fallback to region
    const regionToNationality = {
      'Africa': 'African',
      'Asia': 'Asian', 
      'Europe': 'European',
      'North America': 'North American',
      'South America': 'South American',
      'Oceania': 'Australian/New Zealand'
    };

    return regionToNationality[primaryRegion] || null;
  }

  // Find related authors based on cultural similarity
  async findRelatedAuthors(authorProfile, limit = 10) {
    // This would implement similarity matching based on cultural profiles
    // For now, return a placeholder structure
    return {
      similar: [],
      sameRegion: [],
      sameLanguage: [],
      sameThemes: []
    };
  }

  // Propagate cultural data to books by same author
  async propagateCulturalData(authorProfile) {
    const propagationResults = {
      updated: 0,
      errors: []
    };

    for (const work of authorProfile.works) {
      try {
        // Get book cache key
        const bookCacheKey = work.isbn13 ? 
          `isbn/${work.isbn13}.json` : 
          `book/${work.id}.json`;

        // Get cached book data
        const cachedBook = await this.env.BOOKS_CACHE?.get(bookCacheKey);
        if (!cachedBook) continue;

        const bookData = JSON.parse(cachedBook);
        
        // Add cultural metadata if not present
        if (!bookData.culturalMetadata) {
          bookData.culturalMetadata = {
            authorProfile: {
              nationality: authorProfile.culturalProfile.nationality,
              gender: authorProfile.culturalProfile.gender,
              regions: authorProfile.culturalProfile.regions,
              themes: authorProfile.culturalProfile.themes,
              confidence: authorProfile.culturalProfile.confidence
            },
            lastUpdated: Date.now(),
            version: '1.0'
          };

          // Update cache with cultural data
          await this.env.BOOKS_CACHE?.put(
            bookCacheKey,
            JSON.stringify(bookData),
            { expirationTtl: 2592000 } // 30 days
          );

          propagationResults.updated++;
        }

      } catch (error) {
        propagationResults.errors.push({
          workId: work.id,
          error: error.message
        });
      }
    }

    console.log(`🌍 CULTURAL PROPAGATION: ${authorProfile.name} - ${propagationResults.updated} books updated`);
    return propagationResults;
  }

  // Search authors by cultural criteria
  async searchAuthorsByCulture(criteria) {
    const {
      region,
      nationality, 
      gender,
      language,
      theme,
      minConfidence = 50
    } = criteria;

    // This would implement a search across author profiles
    // For now, return placeholder structure
    return {
      authors: [],
      total: 0,
      criteria: criteria
    };
  }

  // Get cultural diversity statistics
  async getCulturalDiversityStats() {
    try {
      const stats = {
        timestamp: new Date().toISOString(),
        authors: {
          total: 0,
          byRegion: {},
          byGender: {},
          byLanguage: {},
          avgConfidence: 0
        },
        books: {
          total: 0,
          withCulturalData: 0,
          coverage: 0
        }
      };

      // This would aggregate statistics from all author profiles
      // For production, you'd implement efficient aggregation

      return stats;
    } catch (error) {
      console.error('Failed to get cultural diversity stats:', error.message);
      return { error: error.message };
    }
  }

  // Maintenance: Clean up old or low-confidence author profiles
  async performMaintenance() {
    console.log('🧹 CULTURAL INDEX MAINTENANCE: Starting cleanup...');
    
    const maintenanceResults = {
      cleaned: 0,
      updated: 0,
      errors: 0
    };

    // This would implement cleanup logic for:
    // - Profiles with very low confidence (<20%)
    // - Profiles not updated in 6+ months
    // - Duplicate profiles that need merging

    return maintenanceResults;
  }
}

// Export utility functions
export const CulturalUtils = {
  // Validate cultural metadata structure
  validateCulturalMetadata(metadata) {
    const required = ['nationality', 'gender', 'languages', 'regions'];
    const missing = required.filter(field => !metadata.hasOwnProperty(field));
    
    return {
      valid: missing.length === 0,
      missing: missing,
      score: ((required.length - missing.length) / required.length) * 100
    };
  },

  // Merge cultural profiles (for duplicate author resolution)
  mergeCulturalProfiles(profile1, profile2) {
    // Implement sophisticated merging logic
    // For now, return higher confidence profile
    return profile1.culturalProfile.confidence >= profile2.culturalProfile.confidence ? 
           profile1 : profile2;
  },

  // Calculate cultural diversity score for a book collection
  calculateDiversityScore(books) {
    const diversity = {
      regions: new Set(),
      languages: new Set(), 
      genders: new Set(),
      score: 0
    };

    for (const book of books) {
      if (book.culturalMetadata?.authorProfile) {
        const profile = book.culturalMetadata.authorProfile;
        
        if (profile.regions) {
          profile.regions.forEach(region => diversity.regions.add(region));
        }
        if (profile.gender) {
          diversity.genders.add(profile.gender);
        }
      }
    }

    // Simple diversity scoring
    diversity.score = (diversity.regions.size * 2) + 
                     (diversity.languages.size * 1.5) + 
                     (diversity.genders.size * 1);

    return diversity;
  }
};