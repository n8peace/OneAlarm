import { FunctionConfig } from './types.ts';

// Supported news categories (selective approach)
export const NEWS_CATEGORIES = [
  'general', 'business', 'technology', 'sports'
] as const;

export type NewsCategory = typeof NEWS_CATEGORIES[number];

export const CONFIG: FunctionConfig = {
  apis: {
    news: {
      categories: NEWS_CATEGORIES,
      maxArticles: 10,
      maxEvents: 0, // Not used for news
      symbols: [], // Not used for news
      timeout: 5000,
      retries: 3
    },
    sports: {
      maxArticles: 0, // Not used for sports
      maxEvents: 3,
      symbols: [], // Not used for sports
      timeout: 10000,
      retries: 2
    },
    stocks: {
      maxArticles: 0, // Not used for stocks
      maxEvents: 0, // Not used for stocks
      symbols: [
        // Technology (Current + New)
        'AAPL', 'GOOGL', 'TSLA', 'MSFT', 'NVDA', 'META', 'AMZN', 'NFLX', 'ADBE', 'CRM',
        // Finance
        'JPM', 'BAC', 'WFC', 'GS',
        // Healthcare
        'JNJ', 'PFE', 'UNH', 'ABBV',
        // Consumer
        'KO', 'PG', 'WMT', 'DIS',
        // Market Index
        '^GSPC',
        // Crypto
        'BTC-USD', 'ETH-USD'
      ],
      timeout: 10000,
      retries: 2
    },
    holidays: {
      maxArticles: 0, // Not used for holidays
      maxEvents: 0, // Not used for holidays
      symbols: [], // Not used for holidays
      timeout: 8000,
      retries: 2
    }
  },
  database: {
    retries: 3,
    timeout: 5000
  },
  logging: {
    level: 'info'
  },
  notifications: {
    enabled: true,
    webhook_url: Deno.env.get('NOTIFICATION_WEBHOOK_URL') || '',
    slack_webhook: Deno.env.get('SLACK_WEBHOOK_URL') || '',
    email: Deno.env.get('ALERT_EMAIL') || '',
    retry_failures: 3,
    alert_threshold_ms: 30000 // Alert if execution takes longer than 30 seconds
  }
};

export const API_ENDPOINTS = {
  news: 'https://newsapi.org/v2/top-headlines',
  sports: 'https://www.thesportsdb.com/api/v1/json',
  stocks: 'https://apidojo-yahoo-finance-v1.p.rapidapi.com/market/v2/get-quotes',
  holidays: 'https://holidays.abstractapi.com/v1/'
};

export const RATE_LIMITS = {
  news: 1000, // ms between calls
  sports: 2000,
  stocks: 1000,
  holidays: 1500
}; 