import { Metrics } from './types.ts';

// Utility functions for the daily content function

export const delay = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

export const withRetry = async <T>(
  fn: () => Promise<T>, 
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      const waitTime = Math.pow(2, i) * baseDelay;
      console.log(`Retry ${i + 1}/${maxRetries} after ${waitTime}ms`);
      await delay(waitTime);
    }
  }
  throw new Error('Max retries exceeded');
};

export const validateEnvironment = (): void => {
  const required = [
    'SUPABASE_URL', 
    'SUPABASE_SERVICE_ROLE_KEY',
    'OPENAI_API_KEY',
    'NEWSAPI_KEY',
    'SPORTSDB_API_KEY',
    'RAPIDAPI_KEY',
    'ABSTRACT_API_KEY'
  ];
  const missing = required.filter(key => !Deno.env.get(key));
  if (missing.length > 0) {
    throw new Error(`Missing environment variables: ${missing.join(', ')}`);
  }
};

export const rateLimiter = new Map<string, number>();

export const checkRateLimit = (apiKey: string, limit: number): void => {
  const now = Date.now();
  const lastCall = rateLimiter.get(apiKey) || 0;
  if (now - lastCall < limit) {
    throw new Error(`Rate limit exceeded for ${apiKey}. Wait ${limit - (now - lastCall)}ms`);
  }
  rateLimiter.set(apiKey, now);
};

export const logger = {
  info: (msg: string, meta?: Record<string, any>) => {
    console.log(JSON.stringify({ 
      level: 'info', 
      message: msg, 
      timestamp: new Date().toISOString(),
      ...meta 
    }));
  },
  error: (msg: string, error?: Error, meta?: Record<string, any>) => {
    console.error(JSON.stringify({ 
      level: 'error', 
      message: msg, 
      error: error?.message,
      stack: error?.stack,
      timestamp: new Date().toISOString(),
      ...meta 
    }));
  },
  warn: (msg: string, meta?: Record<string, any>) => {
    console.warn(JSON.stringify({ 
      level: 'warn', 
      message: msg, 
      timestamp: new Date().toISOString(),
      ...meta 
    }));
  },
  debug: (msg: string, meta?: Record<string, any>) => {
    console.log(JSON.stringify({ 
      level: 'debug', 
      message: msg, 
      timestamp: new Date().toISOString(),
      ...meta 
    }));
  }
};

export const metrics: Metrics = {
  apiLatency: new Map<string, number[]>(),
  successRate: new Map<string, number>(),
  recordMetric: (name: string, value: number) => {
    if (!metrics.apiLatency.has(name)) {
      metrics.apiLatency.set(name, []);
    }
    metrics.apiLatency.get(name)!.push(value);
    
    // Keep only last 100 measurements
    const measurements = metrics.apiLatency.get(name)!;
    if (measurements.length > 100) {
      measurements.splice(0, measurements.length - 100);
    }
  }
};

export const getAverageLatency = (apiName: string): number => {
  const measurements = metrics.apiLatency.get(apiName) || [];
  if (measurements.length === 0) return 0;
  return measurements.reduce((a, b) => a + b, 0) / measurements.length;
};

export const validateNewsResponse = (data: any): data is { articles: any[] } => {
  return data && 
         typeof data === 'object' && 
         Array.isArray(data.articles) && 
         data.articles.length > 0;
};

export const validateSportsResponse = (data: any): data is { events: any[] } => {
  return data && 
         typeof data === 'object' && 
         Array.isArray(data.events);
};

export const validateStockResponse = (data: any): data is { quoteResponse: { result: any[] } } => {
  return data && 
         typeof data === 'object' && 
         data.quoteResponse && 
         Array.isArray(data.quoteResponse.result) && 
         data.quoteResponse.result.length > 0;
};

export const validateHolidayResponse = (data: any): data is any[] => {
  return data && 
         Array.isArray(data) && 
         data.length >= 0; // Holidays API returns an array (can be empty)
}; 