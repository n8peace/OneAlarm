// Logging utilities for consistent logging across functions

export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error'
}

export interface LogContext {
  function?: string;
  userId?: string;
  requestId?: string;
  [key: string]: any;
}

export function log(
  level: LogLevel,
  message: string,
  context?: LogContext
) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...context
  };

  switch (level) {
    case LogLevel.DEBUG:
      console.debug(JSON.stringify(logEntry));
      break;
    case LogLevel.INFO:
      console.info(JSON.stringify(logEntry));
      break;
    case LogLevel.WARN:
      console.warn(JSON.stringify(logEntry));
      break;
    case LogLevel.ERROR:
      console.error(JSON.stringify(logEntry));
      break;
  }
}

export function logDebug(message: string, context?: LogContext) {
  log(LogLevel.DEBUG, message, context);
}

export function logInfo(message: string, context?: LogContext) {
  log(LogLevel.INFO, message, context);
}

export function logWarn(message: string, context?: LogContext) {
  log(LogLevel.WARN, message, context);
}

export function logError(message: string, context?: LogContext) {
  log(LogLevel.ERROR, message, context);
}

export function logFunctionStart(functionName: string, context?: LogContext) {
  logInfo(`Function ${functionName} started`, { function: functionName, ...context });
}

export function logFunctionEnd(functionName: string, context?: LogContext) {
  logInfo(`Function ${functionName} completed`, { function: functionName, ...context });
}

export function logFunctionError(functionName: string, error: Error, context?: LogContext) {
  logError(`Function ${functionName} failed: ${error.message}`, { 
    function: functionName, 
    error: error.stack,
    ...context 
  });
}

// Shared health check utility
export function createHealthCheckResponse(functionName: string, additionalData?: Record<string, any>) {
  const healthData = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    function: functionName,
    ...additionalData
  };

  return new Response(JSON.stringify(healthData, null, 2), {
    status: 200,
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    }
  });
}

// Shared CORS utility
export function createCorsResponse() {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
} 