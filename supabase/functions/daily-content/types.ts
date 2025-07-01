// Types for the daily content function

import type { ApiResponse, DailyContent } from '../_shared/types/common.ts';

// Re-export shared types
export type { ApiResponse, DailyContent };

export interface NewsArticle {
  title: string;
  description: string;
  content: string;
  url: string;
  publishedAt: string;
}

export interface NewsContent {
  articles: NewsArticle[];
  summary: string;
}

export interface SportsEvent {
  strEvent: string;
  intHomeScore?: number;
  intAwayScore?: number;
  dateEvent: string;
  dateEventLocal: string;
  strTime: string;
  strTimeLocal: string;
  strStatus: string;
  strHomeTeam: string;
  strAwayTeam: string;
  strLeague: string;
  strSport: string;
}

export interface SportsContent {
  events: SportsEvent[];
  summary: string;
  todayGames: SportsEvent[];
  tomorrowGames: SportsEvent[];
}

export interface StockQuote {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
}

export interface StockContent {
  quotes: StockQuote[];
  summary: string;
}

export interface Holiday {
  name: string;
  name_local: string;
  language: string;
  description: string;
  country: string;
  location: string;
  type: string;
  date: string;
  date_year: string;
  date_month: string;
  date_day: string;
  week_day: string;
}

export interface HolidayContent {
  holidays: Holiday[];
  summary: string;
}

// Function-specific DailyContent with API data (separate from database DailyContent)
export interface DailyContentWithApiData {
  date: string;
  general_headlines: string;
  business_headlines: string;
  technology_headlines: string;
  sports_headlines: string;
  sports: SportsContent;
  stocks: StockContent;
  holidays: HolidayContent;
}

export interface ApiConfig {
  maxArticles: number;
  maxEvents: number;
  symbols: string[];
  timeout: number;
  retries: number;
  categories?: readonly string[];
}

export interface FunctionConfig {
  apis: {
    news: ApiConfig & { categories: readonly string[] };
    sports: ApiConfig;
    stocks: ApiConfig;
    holidays: ApiConfig;
  };
  database: {
    retries: number;
    timeout: number;
  };
  logging: {
    level: 'debug' | 'info' | 'warn' | 'error';
  };
  notifications: {
    enabled: boolean;
    webhook_url: string;
    slack_webhook: string;
    email: string;
    retry_failures: number;
    alert_threshold_ms: number;
  };
}

export interface LogEntry {
  id?: string;
  event_type: string;
  meta: {
    function_name: string;
    status: 'running' | 'success' | 'error';
    execution_time_ms?: number;
    api_results?: {
      news: { success: boolean; error: string | null };
      sports: { success: boolean; error: string | null };
      stocks: { success: boolean; error: string | null };
      holidays: { success: boolean; error: string | null };
    };
    fallback_used?: {
      news: boolean;
      sports: boolean;
      stocks: boolean;
      holidays: boolean;
    };
    error_message?: string;
    start_time?: string;
    end_time?: string;
  };
}

export interface Metrics {
  apiLatency: Map<string, number[]>;
  successRate: Map<string, number>;
  recordMetric: (name: string, value: number) => void;
} 