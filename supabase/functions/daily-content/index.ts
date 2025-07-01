// File: supabase/functions/daily-content/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { 
  NewsApiClient, 
  SportsApiClient, 
  StocksApiClient, 
  HolidaysApiClient,
  DatabaseService,
  NotificationService
} from './services.ts';
import { validateEnvironment, logger, metrics } from './utils.ts';
import { CONFIG } from './config.ts';
import { createHealthCheckResponse, createCorsResponse } from '../_shared/utils/logging.ts';

// Main service class with dependency injection
class DailyContentService {
  constructor(
    private newsApi: NewsApiClient,
    private sportsApi: SportsApiClient,
    private stocksApi: StocksApiClient,
    private holidaysApi: HolidaysApiClient,
    private db: DatabaseService,
    private notifications: NotificationService
  ) {}

  async execute(): Promise<void> {
    const startTime = Date.now();
    let logId: string | null = null;

    try {
      // Validate environment
      validateEnvironment();
      logger.info('Environment validation passed');

      // Create initial log entry
      logId = await this.db.createLogEntry({
        event_type: 'daily_content_function_started',
        meta: {
          function_name: 'daily-content',
          status: 'running',
          start_time: new Date().toISOString()
        }
      });

      if (logId) {
        logger.info('Initial log entry created', { logId });
      }

      const today = new Date().toISOString().split('T')[0];
      logger.info('Starting daily content collection', { date: today });

      // Execute all API calls in parallel with error boundaries
      const [newsResult, sportsResult, stocksResult, holidaysResult] = await Promise.allSettled([
        this.newsApi.fetchNewsForAllCategories(),
        this.sportsApi.fetchSports(today),
        this.stocksApi.fetchStocks(),
        this.holidaysApi.fetchHolidays(today)
      ]);

      // Process results
      const news = newsResult.status === 'fulfilled' ? newsResult.value : {
        success: false,
        error: newsResult.reason?.message || 'Unknown error',
        executionTime: 0,
        data: undefined
      };

      const sports = sportsResult.status === 'fulfilled' ? sportsResult.value : {
        success: false,
        error: sportsResult.reason?.message || 'Unknown error',
        executionTime: 0,
        data: undefined
      };

      const stocks = stocksResult.status === 'fulfilled' ? stocksResult.value : {
        success: false,
        error: stocksResult.reason?.message || 'Unknown error',
        executionTime: 0,
        data: undefined
      };

      const holidays = holidaysResult.status === 'fulfilled' ? holidaysResult.value : {
        success: false,
        error: holidaysResult.reason?.message || 'Unknown error',
        executionTime: 0,
        data: undefined
      };

      // Get last hour's data as fallback
      const lastHourData = await this.db.getLastHourData();
      logger.info('Retrieved last hour data for fallback', { hasData: !!lastHourData });

      // Prepare sports, stocks, and holidays summaries
      const sportsSummary = this.getContentWithFallback(
        sports.success && sports.data ? sports.data.summary : null,
        lastHourData?.sports_summary,
        'Sports data temporarily unavailable',
        'Sports'
      );

      const stocksSummary = this.getContentWithFallback(
        stocks.success && stocks.data ? stocks.data.summary : null,
        lastHourData?.stocks_summary,
        'Stock data temporarily unavailable',
        'Stocks'
      );

      const holidaysSummary = this.getContentWithFallback(
        holidays.success && holidays.data ? holidays.data.summary : null,
        lastHourData?.holidays,
        'Holiday data temporarily unavailable',
        'Holidays'
      );

      // Insert content for all categories if news was successful
      if (news.success && news.data) {
        await this.db.insertDailyContentForCategories(
          news.data,
          sportsSummary,
          stocksSummary,
          holidaysSummary
        );
      } else {
        // Fallback: insert general content only
        const fallbackContent = {
          date: today,
          general_headlines: this.getContentWithFallback(
            null,
            lastHourData?.general_headlines,
            'News temporarily unavailable',
            'News'
          ),
          business_headlines: 'Business news temporarily unavailable',
          technology_headlines: 'Technology news temporarily unavailable',
          sports_headlines: 'Sports news temporarily unavailable',
          sports_summary: sportsSummary,
          stocks_summary: stocksSummary,
          holidays: holidaysSummary
        };
        await this.db.insertDailyContent(fallbackContent);
      }

      const executionTime = Date.now() - startTime;
      logger.info('Daily content collection completed successfully', {
        executionTime,
        newsSuccess: news.success,
        sportsSuccess: sports.success,
        stocksSuccess: stocks.success,
        holidaysSuccess: holidays.success,
        usedFallback: {
          news: !news.success || !news.data,
          sports: !sports.success || !sports.data,
          stocks: !stocks.success || !stocks.data,
          holidays: !holidays.success || !holidays.data
        }
      });

      // Check for timeout and send notification if needed
      if (executionTime > CONFIG.notifications.alert_threshold_ms) {
        await this.notifications.sendTimeoutNotification(executionTime);
      }

      // Send success notification
      await this.notifications.sendSuccessNotification(executionTime);

      // Update log with success
      if (logId) {
        await this.db.updateLogEntry(logId, {
          status: 'success',
          execution_time_ms: executionTime,
          api_results: {
            news: { success: news.success, error: news.error || null },
            sports: { success: sports.success, error: sports.error || null },
            stocks: { success: stocks.success, error: stocks.error || null },
            holidays: { success: holidays.success, error: holidays.error || null }
          },
          fallback_used: {
            news: !news.success || !news.data,
            sports: !sports.success || !sports.data,
            stocks: !stocks.success || !stocks.data,
            holidays: !holidays.success || !holidays.data
          },
          end_time: new Date().toISOString()
        });
      }

    } catch (error) {
      const executionTime = Date.now() - startTime;
      logger.error('Daily content collection failed', error as Error, { executionTime });

      // Send failure notification
      await this.notifications.sendFailureNotification(error as Error, executionTime);

      // Update log with error
      if (logId) {
        await this.db.updateLogEntry(logId, {
          status: 'error',
          execution_time_ms: executionTime,
          error_message: (error as Error).message,
          end_time: new Date().toISOString()
        });
      }

      throw error;
    }
  }

  private getContentWithFallback(
    newData: string | null, 
    fallbackData: string | undefined, 
    defaultMessage: string,
    apiName: string
  ): string {
    // If we have new data, use it
    if (newData && newData.trim() !== '') {
      return newData;
    }
    
    // If we have fallback data, use it
    if (fallbackData && fallbackData.trim() !== '') {
      logger.warn(`Using fallback data for ${apiName}`);
      return fallbackData;
    }
    
    // Otherwise, use default message
    logger.warn(`No data available for ${apiName}, using default message`);
    return defaultMessage;
  }
}

// Initialize services
const newsApi = new NewsApiClient();
const sportsApi = new SportsApiClient();
const stocksApi = new StocksApiClient();
const holidaysApi = new HolidaysApiClient();
const db = new DatabaseService();
const notifications = new NotificationService();

// Initialize the main service
const dailyContentService = new DailyContentService(
  newsApi,
  sportsApi,
  stocksApi,
  holidaysApi,
  db,
  notifications
);

// Main request handler
serve(async (req) => {
  try {
    // Handle CORS
    if (req.method === 'OPTIONS') {
      return createCorsResponse();
    }

    // Handle health check
    if (req.method === 'GET') {
      return createHealthCheckResponse('daily-content', {
        config: {
          apis: Object.keys(CONFIG.apis),
          notifications: CONFIG.notifications.enabled
        }
      });
    }

    // Handle content generation (POST request)
    if (req.method === 'POST') {
      await dailyContentService.execute();
      
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Daily content collection completed successfully',
          timestamp: new Date().toISOString()
        }),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // Method not allowed
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Method not allowed. Use POST to generate daily content or GET for health check.'
      }),
      {
        status: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );

  } catch (error) {
    console.error('Daily content function failed:', error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: `Internal server error: ${(error as Error).message}`,
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  }
}); 