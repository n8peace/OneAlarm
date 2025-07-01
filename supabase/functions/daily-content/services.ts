import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';
import axios from 'npm:axios';
import { 
  ApiResponse, 
  NewsContent, 
  SportsContent, 
  SportsEvent,
  StockContent,
  LogEntry,
  HolidayContent
} from './types.ts';
import { CONFIG, API_ENDPOINTS, RATE_LIMITS } from './config.ts';
import { 
  logger, 
  metrics, 
  withRetry, 
  checkRateLimit, 
  validateNewsResponse, 
  validateSportsResponse, 
  validateStockResponse,
  validateHolidayResponse
} from './utils.ts';

// Base API client class
abstract class BaseApiClient {
  protected abstract apiName: string;
  protected abstract endpoint: string;
  
  protected async makeRequest<T>(
    url: string, 
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const startTime = Date.now();
    
    try {
      checkRateLimit(this.apiName, RATE_LIMITS[this.apiName as keyof typeof RATE_LIMITS]);
      
      const response = await withRetry(
        () => fetch(url, {
          ...options,
          headers: {
            'User-Agent': 'Supabase-Edge-Function/2.0',
            ...options.headers
          }
        }),
        CONFIG.apis[this.apiName as keyof typeof CONFIG.apis].retries
      );
      
      const executionTime = Date.now() - startTime;
      metrics.recordMetric(`${this.apiName}_latency`, executionTime);
      
      if (!response.ok) {
        const errorText = await response.text();
        logger.error(`${this.apiName} API request failed`, new Error(`HTTP ${response.status}: ${errorText}`));
        return {
          success: false,
          error: `HTTP ${response.status}: ${errorText}`,
          executionTime
        };
      }
      
      const data = await response.json();
      return {
        success: true,
        data,
        executionTime
      };
    } catch (error) {
      const executionTime = Date.now() - startTime;
      metrics.recordMetric(`${this.apiName}_latency`, executionTime);
      logger.error(`${this.apiName} API request failed`, error as Error);
      return {
        success: false,
        error: (error as Error).message,
        executionTime
      };
    }
  }
}

// News API client
export class NewsApiClient extends BaseApiClient {
  protected apiName = 'news';
  protected endpoint = API_ENDPOINTS.news;
  
  async fetchNewsForAllCategories(): Promise<ApiResponse<Record<string, NewsContent>>> {
    const apiKey = Deno.env.get('NEWSAPI_KEY');
    if (!apiKey) {
      logger.warn('No NewsAPI key provided');
      return {
        success: false,
        error: 'No API key provided',
        executionTime: 0
      };
    }
    
    const allContent: Record<string, NewsContent> = {};
    let totalExecutionTime = 0;
    
    // Fetch content for each category in parallel
    const promises = CONFIG.apis.news.categories.map(async (category) => {
      const url = `${this.endpoint}?country=us&category=${category}&apiKey=${apiKey}`;
      
      // Use category-specific rate limiting
      const startTime = Date.now();
      try {
        checkRateLimit(`news_${category}`, RATE_LIMITS.news);
        
        const response = await withRetry(
          () => fetch(url, {
            headers: {
              'User-Agent': 'Supabase-Edge-Function/2.0'
            }
          }),
          CONFIG.apis.news.retries
        );
        
        const executionTime = Date.now() - startTime;
        metrics.recordMetric(`${this.apiName}_${category}_latency`, executionTime);
        
        if (!response.ok) {
          const errorText = await response.text();
          logger.error(`News API request failed for ${category}`, new Error(`HTTP ${response.status}: ${errorText}`));
          return;
        }
        
        const data = await response.json();
        if (data && data.articles) {
          allContent[category] = this.processNewsResponse(data);
        }
        
        totalExecutionTime += executionTime;
      } catch (error) {
        const executionTime = Date.now() - startTime;
        metrics.recordMetric(`${this.apiName}_${category}_latency`, executionTime);
        logger.error(`News API request failed for ${category}`, error as Error);
      }
    });
    
    await Promise.all(promises);
    
    return {
      success: Object.keys(allContent).length > 0,
      data: allContent,
      executionTime: totalExecutionTime
    };
  }
  
  // Keep the old method for backward compatibility
  async fetchNews(): Promise<ApiResponse<NewsContent>> {
    const apiKey = Deno.env.get('NEWSAPI_KEY');
    if (!apiKey) {
      logger.warn('No NewsAPI key provided');
      return {
        success: false,
        error: 'No API key provided',
        executionTime: 0
      };
    }
    
    const url = `${this.endpoint}?country=us&apiKey=${apiKey}`;
    const response = await this.makeRequest(url);
    
    if (!response.success || !response.data) {
      return response as ApiResponse<NewsContent>;
    }
    
    if (!validateNewsResponse(response.data)) {
      logger.error('Invalid news response structure', new Error('Response validation failed'));
      return {
        success: false,
        error: 'Invalid response structure',
        executionTime: response.executionTime
      };
    }
    
    const articles = response.data.articles.slice(0, CONFIG.apis.news.maxArticles).map((article: any) => ({
      title: article.title || 'No title available',
      description: article.description || 'No description available',
      content: article.content || 'No content available',
      url: article.url || '',
      publishedAt: article.publishedAt || new Date().toISOString()
    }));
    
    const summary = articles.map((article, index) => 
      `${index + 1}. ${article.title}\n   Description: ${article.description}\n   Content: ${article.content}\n`
    ).join('\n');
    
    return {
      success: true,
      data: { articles, summary },
      executionTime: response.executionTime
    };
  }
  
  private processNewsResponse(data: any): NewsContent {
    if (!validateNewsResponse(data)) {
      logger.error('Invalid news response structure', new Error('Response validation failed'));
      return {
        articles: [],
        summary: 'News data temporarily unavailable'
      };
    }
    
    const articles = data.articles.slice(0, CONFIG.apis.news.maxArticles).map((article: any) => ({
      title: article.title || 'No title available',
      description: article.description || 'No description available',
      content: article.content || 'No content available',
      url: article.url || '',
      publishedAt: article.publishedAt || new Date().toISOString()
    }));
    
    const summary = articles.map((article, index) => 
      `${index + 1}. ${article.title}\n   Description: ${article.description}\n   Content: ${article.content}\n`
    ).join('\n');
    
    return { articles, summary };
  }
}

// Sports API client
export class SportsApiClient extends BaseApiClient {
  protected apiName = 'sports';
  protected endpoint = API_ENDPOINTS.sports;
  
  async fetchSports(date: string): Promise<ApiResponse<SportsContent>> {
    const apiKey = Deno.env.get('SPORTSDB_API_KEY');
    if (!apiKey) {
      logger.warn('No SportsDB API key provided');
      return {
        success: false,
        error: 'No API key provided',
        executionTime: 0
      };
    }
    
    try {
      // Calculate tomorrow's date
      const today = new Date(date);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      const tomorrowStr = tomorrow.toISOString().split('T')[0];
      
      logger.info('Fetching sports data for two days', { today: date, tomorrow: tomorrowStr });
      
      // Make two API calls in parallel
      const [todayResponse, tomorrowResponse] = await Promise.all([
        this.makeRequest(`${this.endpoint}/${apiKey}/eventsday.php?d=${date}`),
        this.makeRequest(`${this.endpoint}/${apiKey}/eventsday.php?d=${tomorrowStr}`)
      ]);
      
      // Combine execution times
      const totalExecutionTime = (todayResponse.executionTime || 0) + (tomorrowResponse.executionTime || 0);
      
      // Process today's response
      let todayEvents: any[] = [];
      if (todayResponse.success && todayResponse.data && validateSportsResponse(todayResponse.data)) {
        todayEvents = todayResponse.data.events || [];
      } else {
        logger.warn('Today sports API call failed or invalid response', { 
          success: todayResponse.success, 
          error: todayResponse.error 
        });
      }
      
      // Process tomorrow's response
      let tomorrowEvents: any[] = [];
      if (tomorrowResponse.success && tomorrowResponse.data && validateSportsResponse(tomorrowResponse.data)) {
        tomorrowEvents = tomorrowResponse.data.events || [];
      } else {
        logger.warn('Tomorrow sports API call failed or invalid response', { 
          success: tomorrowResponse.success, 
          error: tomorrowResponse.error 
        });
      }
      
      // Combine all events
      const allEvents = [...todayEvents, ...tomorrowEvents];
      
      // Categorize events by dateEventLocal
      const todayGames: SportsEvent[] = [];
      const tomorrowGames: SportsEvent[] = [];
      
      allEvents.forEach((event: any) => {
        const sportsEvent: SportsEvent = {
          strEvent: event.strEvent || 'Unknown event',
          intHomeScore: event.intHomeScore || null,
          intAwayScore: event.intAwayScore || null,
          dateEvent: event.dateEvent || date,
          dateEventLocal: event.dateEventLocal || event.dateEvent || date,
          strTime: event.strTime || '',
          strTimeLocal: event.strTimeLocal || event.strTime || '',
          strStatus: event.strStatus || 'Unknown',
          strHomeTeam: event.strHomeTeam || '',
          strAwayTeam: event.strAwayTeam || '',
          strLeague: event.strLeague || '',
          strSport: event.strSport || ''
        };
        
        // Categorize by dateEventLocal
        if (sportsEvent.dateEventLocal === date) {
          todayGames.push(sportsEvent);
        } else if (sportsEvent.dateEventLocal === tomorrowStr) {
          tomorrowGames.push(sportsEvent);
        }
      });
      
      // Generate summaries
      const todaySummary = this.generateDaySummary(todayGames, 'Today');
      const tomorrowSummary = this.generateDaySummary(tomorrowGames, 'Tomorrow');
      
      const summary = [todaySummary, tomorrowSummary].filter(s => s).join('\n\n');
      
      logger.info('Sports data processed successfully', {
        totalEvents: allEvents.length,
        todayGames: todayGames.length,
        tomorrowGames: tomorrowGames.length,
        executionTime: totalExecutionTime
      });
      
      return {
        success: true,
        data: { 
          events: allEvents, 
          summary,
          todayGames,
          tomorrowGames
        },
        executionTime: totalExecutionTime
      };
      
    } catch (error) {
      logger.error('Sports API error', error as Error);
      return {
        success: false,
        error: (error as Error).message,
        executionTime: 0
      };
    }
  }
  
  private generateDaySummary(games: SportsEvent[], dayLabel: string): string {
    if (games.length === 0) {
      return '';
    }
    
    const finishedGames = games.filter(game => 
      game.strStatus === 'FT' || game.strStatus === 'AET' || game.strStatus === 'PEN'
    );
    
    const upcomingGames = games.filter(game => 
      game.strStatus === 'NS' || game.strStatus === 'Not Started'
    );
    
    const parts: string[] = [];
    
    // Add finished games with scores
    if (finishedGames.length > 0) {
      const finishedSummary = finishedGames.map(game => {
        const homeScore = game.intHomeScore || 0;
        const awayScore = game.intAwayScore || 0;
        return `${game.strHomeTeam} ${homeScore} - ${awayScore} ${game.strAwayTeam}`;
      }).join(', ');
      parts.push(`${dayLabel}'s Results: ${finishedSummary}`);
    }
    
    // Add upcoming games with local times
    if (upcomingGames.length > 0) {
      const upcomingSummary = upcomingGames.map(game => {
        const localTime = game.strTimeLocal || game.strTime || 'TBD';
        return `${game.strHomeTeam} vs ${game.strAwayTeam} at ${localTime}`;
      }).join(', ');
      parts.push(`${dayLabel}'s Games: ${upcomingSummary}`);
    }
    
    return parts.join('. ');
  }
}

// Stocks API client
export class StocksApiClient extends BaseApiClient {
  protected apiName = 'stocks';
  protected endpoint = API_ENDPOINTS.stocks;
  
  async fetchStocks(): Promise<ApiResponse<StockContent>> {
    const apiKey = Deno.env.get('RAPIDAPI_KEY');
    if (!apiKey) {
      logger.warn('No RapidAPI key provided');
      return {
        success: false,
        error: 'No API key provided',
        executionTime: 0
      };
    }
    
    try {
      const startTime = Date.now();
      
      // Make single API call with all symbols
      const allSymbols = CONFIG.apis.stocks.symbols.join(',');
      const response = await withRetry(
        () => axios.get(this.endpoint, {
          headers: {
            'X-RapidAPI-Key': apiKey,
            'X-RapidAPI-Host': 'apidojo-yahoo-finance-v1.p.rapidapi.com'
          },
          params: {
            region: 'US',
            symbols: allSymbols
          },
          timeout: CONFIG.apis.stocks.timeout
        }),
        CONFIG.apis.stocks.retries
      );
      
      const executionTime = Date.now() - startTime;
      metrics.recordMetric(`${this.apiName}_latency`, executionTime);
      
      if (validateStockResponse(response.data) && response.data.quoteResponse.result) {
        const quotes = response.data.quoteResponse.result.map((q: any) => ({
          symbol: q.symbol || 'UNKNOWN',
          price: q.regularMarketPrice || 0,
          change: q.regularMarketChange || 0,
          changePercent: q.regularMarketChangePercent || 0
        }));
        
        const summary = quotes.length > 0
          ? quotes.map(q => `${q.symbol}: $${q.price} (${q.changePercent.toFixed(2)}%)`).join('\n')
          : 'Stock data temporarily unavailable';
        
        return {
          success: quotes.length > 0,
          data: { quotes, summary },
          executionTime
        };
      } else {
        logger.error('Invalid stock response structure', { responseData: response.data });
        return {
          success: false,
          error: 'Invalid response structure',
          executionTime
        };
      }
    } catch (error) {
      logger.error('Stock API error', error as Error);
      return {
        success: false,
        error: (error as Error).message,
        executionTime: 0
      };
    }
  }
}

// Holidays API client
export class HolidaysApiClient extends BaseApiClient {
  protected apiName = 'holidays';
  protected endpoint = API_ENDPOINTS.holidays;
  
  async fetchHolidays(date: string): Promise<ApiResponse<HolidayContent>> {
    const apiKey = Deno.env.get('ABSTRACT_API_KEY');
    if (!apiKey) {
      logger.warn('No Abstract API key provided');
      return {
        success: false,
        error: 'No API key provided',
        executionTime: 0
      };
    }
    
    logger.info('Starting holidays API call', { 
      date, 
      apiKeyLength: apiKey.length,
      hasApiKey: !!apiKey 
    });
    
    try {
      const startTime = Date.now();
      
      // Parse the date to get year, month, and day
      const dateObj = new Date(date);
      const year = dateObj.getFullYear();
      const month = dateObj.getMonth() + 1; // getMonth() returns 0-11
      const day = dateObj.getDate();
      
      logger.info('Parsed date parameters', { year, month, day, date });
      
      const requestUrl = `${this.endpoint}?api_key=${apiKey}&country=US&year=${year}&month=${month}&day=${day}`;
      logger.info('Making holidays API request', { 
        url: requestUrl.replace(apiKey, '[REDACTED]'),
        timeout: CONFIG.apis.holidays.timeout 
      });
      
      const response = await withRetry(
        () => axios.get(this.endpoint, {
          params: {
            api_key: apiKey,
            country: 'US',
            year: year,
            month: month,
            day: day
          },
          timeout: CONFIG.apis.holidays.timeout
        }),
        CONFIG.apis.holidays.retries
      );
      
      const executionTime = Date.now() - startTime;
      metrics.recordMetric(`${this.apiName}_latency`, executionTime);
      
      logger.info('Holidays API response received', { 
        executionTime, 
        statusCode: response.status,
        dataLength: Array.isArray(response.data) ? response.data.length : 'not array',
        dataType: typeof response.data
      });
      
      if (validateHolidayResponse(response.data)) {
        const holidays = response.data;
        const summary = holidays.length > 0
          ? `Today's holidays: ${holidays.map(h => h.name).join(', ')}`
          : 'No holidays today';
        
        logger.info('Holidays data processed successfully', { 
          holidayCount: holidays.length, 
          summary 
        });
        
        return {
          success: true,
          data: { holidays, summary },
          executionTime
        };
      } else {
        logger.error('Invalid holiday response format', { 
          responseData: response.data,
          responseType: typeof response.data 
        });
        throw new Error('Invalid holiday response format');
      }
    } catch (error) {
      logger.error('Holiday API error', error as Error, { 
        date,
        endpoint: this.endpoint,
        hasApiKey: !!apiKey 
      });
      return {
        success: false,
        error: (error as Error).message,
        executionTime: 0
      };
    }
  }
}

// Database service
export class DatabaseService {
  private supabase: SupabaseClient;
  
  constructor() {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    this.supabase = createClient(supabaseUrl, supabaseKey);
  }
  
  async createLogEntry(logEntry: Omit<LogEntry, 'id'>): Promise<string | null> {
    try {
      logger.info('Attempting to create log entry', { event_type: logEntry.event_type });
      
      const result = await withRetry(
        () => this.supabase.from('logs').insert([logEntry]).select('id').single(),
        CONFIG.database.retries
      );
      
      if (result.error) {
        logger.error('Failed to create log entry', new Error(result.error.message), { 
          error_code: result.error.code,
          error_details: result.error.details,
          error_hint: result.error.hint
        });
        
        // If table doesn't exist, log it but don't fail the function
        if (result.error.code === '42P01') { // undefined_table
          logger.warn('Logs table does not exist - skipping logging');
          return null;
        }
        
        return null;
      }
      
      logger.info('Log entry created successfully', { logId: result.data.id });
      return result.data.id;
    } catch (error) {
      logger.error('Failed to create log entry', error as Error);
      return null;
    }
  }
  
  async updateLogEntry(id: string, updates: Partial<LogEntry['meta']>): Promise<void> {
    try {
      logger.info('Attempting to update log entry', { logId: id });
      
      const result = await withRetry(
        () => this.supabase.from('logs').update({
          event_type: 'daily_content_function_completed',
          meta: updates
        }).eq('id', id),
        CONFIG.database.retries
      );
      
      if (result.error) {
        logger.error('Failed to update log entry', new Error(result.error.message), { 
          logId: id,
          error_code: result.error.code,
          error_details: result.error.details
        });
        return;
      }
      
      logger.info('Log entry updated successfully', { logId: id });
    } catch (error) {
      logger.error('Failed to update log entry', error as Error, { logId: id });
    }
  }
  
  async insertDailyContent(content: {
    date: string;
    general_headlines: string;
    business_headlines: string;
    technology_headlines: string;
    sports_headlines: string;
    sports_summary: string;
    stocks_summary: string;
    holidays?: string;
  }): Promise<void> {
    try {
      const result = await withRetry(
        () => this.supabase.from('daily_content').insert([content]),
        CONFIG.database.retries
      );
      
      if (result.error) {
        throw new Error(result.error.message);
      }
      
      logger.info('Daily content inserted successfully');
    } catch (error) {
      logger.error('Failed to insert daily content', error as Error);
      throw error;
    }
  }

  // Updated method to insert content for all categories in a single row
  async insertDailyContentForCategories(contentByCategory: Record<string, any>, sportsSummary: string, stocksSummary: string, holidaysSummary?: string): Promise<void> {
    try {
      const today = new Date().toISOString().split('T')[0];
      
      // Extract headlines for each category
      const generalHeadlines = contentByCategory.general?.summary || 'General news temporarily unavailable';
      const businessHeadlines = contentByCategory.business?.summary || 'Business news temporarily unavailable';
      const technologyHeadlines = contentByCategory.technology?.summary || 'Technology news temporarily unavailable';
      const sportsHeadlines = contentByCategory.sports?.summary || 'Sports news temporarily unavailable';
      
      const insertData = {
        date: today,
        general_headlines: generalHeadlines,
        business_headlines: businessHeadlines,
        technology_headlines: technologyHeadlines,
        sports_headlines: sportsHeadlines,
        sports_summary: sportsSummary,
        stocks_summary: stocksSummary,
        holidays: holidaysSummary
      };
      
      const result = await withRetry(
        () => this.supabase.from('daily_content').insert([insertData]),
        CONFIG.database.retries
      );
      
      if (result.error) {
        throw new Error(result.error.message);
      }
      
      logger.info('Daily content inserted for all categories', { 
        categories: Object.keys(contentByCategory),
        date: today
      });
    } catch (error) {
      logger.error('Failed to insert daily content for categories', error as Error);
      throw error;
    }
  }

  // Updated method to get content for user categories
  async getContentForUserCategories(userId: string): Promise<any[]> {
    try {
      const today = new Date().toISOString().split('T')[0];
      
      const { data, error } = await this.supabase
        .from('daily_content')
        .select('*')
        .eq('date', today)
        .order('created_at', { ascending: false })
        .limit(1);
      
      if (error) {
        logger.warn('Failed to fetch content for user categories', { error: error.message, userId });
        return [];
      }
      
      return data || [];
    } catch (error) {
      logger.warn('Error fetching content for user categories', error as Error, { userId });
      return [];
    }
  }

  // Updated method to get latest content by category
  async getLatestContentByCategory(category: string): Promise<any[]> {
    try {
      const today = new Date().toISOString().split('T')[0];
      
      const { data, error } = await this.supabase
        .from('daily_content')
        .select('*')
        .eq('date', today)
        .order('created_at', { ascending: false })
        .limit(1);
      
      if (error) {
        logger.warn('Failed to fetch content by category', { error: error.message, category });
        return [];
      }
      
      // Transform the data to match the expected format for backward compatibility
      if (data && data.length > 0) {
        const row = data[0];
        const headlineColumn = `${category}_headlines` as keyof typeof row;
        const headline = row[headlineColumn] as string;
        
        return [{
          ...row,
          news_category: category,
          headline: headline
        }];
      }
      
      return [];
    } catch (error) {
      logger.warn('Error fetching content by category', error as Error, { category });
      return [];
    }
  }

  // Updated method to get last hour data
  async getLastHourData(): Promise<{
    general_headlines?: string;
    business_headlines?: string;
    technology_headlines?: string;
    sports_headlines?: string;
    sports_summary?: string;
    stocks_summary?: string;
    holidays?: string;
  } | null> {
    try {
      const { data, error } = await this.supabase
        .from('daily_content')
        .select('*')
        .gte('created_at', new Date(Date.now() - 60 * 60 * 1000).toISOString())
        .order('created_at', { ascending: false })
        .limit(1);
      
      if (error) {
        logger.warn('Failed to get last hour data', { error: error.message });
        return null;
      }
      
      return data?.[0] || null;
    } catch (error) {
      logger.warn('Error getting last hour data', error as Error);
      return null;
    }
  }
}

// Notification service for error alerting
export class NotificationService {
  private config = CONFIG.notifications;

  async sendAlert(message: string, details?: any): Promise<void> {
    if (!this.config.enabled) {
      return;
    }

    const alert = {
      timestamp: new Date().toISOString(),
      function: 'daily-content',
      message,
      details,
      environment: Deno.env.get('ENVIRONMENT') || 'production'
    };

    const promises: Promise<void>[] = [];

    // Send webhook notification
    if (this.config.webhook_url) {
      promises.push(this.sendWebhookAlert(alert));
    }

    // Send Slack notification
    if (this.config.slack_webhook) {
      promises.push(this.sendSlackAlert(alert));
    }

    // Send email notification
    if (this.config.email) {
      promises.push(this.sendEmailAlert(alert));
    }

    await Promise.allSettled(promises);
  }

  private async sendWebhookAlert(alert: any): Promise<void> {
    try {
      const response = await fetch(this.config.webhook_url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(alert)
      });

      if (!response.ok) {
        throw new Error(`Webhook failed: ${response.status}`);
      }
    } catch (error) {
      console.error('Failed to send webhook alert:', error);
    }
  }

  private async sendSlackAlert(alert: any): Promise<void> {
    try {
      const slackMessage = {
        text: `🚨 *Daily Content Function Alert*\n${alert.message}`,
        attachments: [{
          fields: [
            { title: 'Function', value: alert.function, short: true },
            { title: 'Environment', value: alert.environment, short: true },
            { title: 'Timestamp', value: alert.timestamp, short: true },
            { title: 'Details', value: JSON.stringify(alert.details, null, 2), short: false }
          ],
          color: 'danger'
        }]
      };

      const response = await fetch(this.config.slack_webhook, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(slackMessage)
      });

      if (!response.ok) {
        throw new Error(`Slack webhook failed: ${response.status}`);
      }
    } catch (error) {
      console.error('Failed to send Slack alert:', error);
    }
  }

  private async sendEmailAlert(alert: any): Promise<void> {
    if (!this.config.email) {
      return;
    }

    try {
      const sendgridApiKey = Deno.env.get('SENDGRID_API_KEY');
      if (!sendgridApiKey) {
        console.error('SENDGRID_API_KEY not configured');
        return;
      }

      const emailData = {
        personalizations: [{
          to: [{ email: this.config.email }],
          subject: `🚨 OneAlarm Alert: ${alert.message}`
        }],
        from: { email: 'alerts@onealarm.com', name: 'OneAlarm Alert System' },
        content: [{
          type: 'text/html',
          value: `
            <html>
              <body>
                <h2>🚨 OneAlarm Alert</h2>
                <p><strong>Function:</strong> ${alert.function}</p>
                <p><strong>Message:</strong> ${alert.message}</p>
                <p><strong>Time:</strong> ${alert.timestamp}</p>
                <p><strong>Environment:</strong> ${alert.environment}</p>
                ${alert.details ? `
                <h3>Details:</h3>
                <pre>${JSON.stringify(alert.details, null, 2)}</pre>
                ` : ''}
                <hr>
                <p><small>This is an automated alert from OneAlarm's daily content function.</small></p>
              </body>
            </html>
          `
        }]
      };

      const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${sendgridApiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(emailData)
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`SendGrid failed: ${response.status} - ${errorText}`);
      }

      console.log('Email alert sent successfully');
    } catch (error) {
      console.error('Failed to send email alert:', error);
    }
  }

  async sendSuccessNotification(executionTime: number): Promise<void> {
    if (!this.config.enabled) {
      return;
    }

    const message = `✅ Daily content collection completed successfully in ${executionTime}ms`;
    await this.sendAlert(message, { executionTime });
  }

  async sendFailureNotification(error: Error, executionTime: number): Promise<void> {
    if (!this.config.enabled) {
      return;
    }

    const message = `❌ Daily content collection failed after ${executionTime}ms`;
    await this.sendAlert(message, { 
      error: error.message, 
      stack: error.stack,
      executionTime 
    });
  }

  async sendTimeoutNotification(executionTime: number): Promise<void> {
    if (!this.config.enabled) {
      return;
    }

    const message = `⏰ Daily content collection took too long: ${executionTime}ms`;
    await this.sendAlert(message, { executionTime });
  }
} 