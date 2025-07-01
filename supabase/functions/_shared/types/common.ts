// Common types shared across all functions

export interface BaseResponse {
  success: boolean;
  message?: string;
  error?: string;
}

export interface User {
  id: string;
  email: string | null;
  phone: string | null;
  onboarding_done: boolean | null;
  subscription_status: string | null;
  created_at: string | null;
  is_admin: boolean | null;
  last_login: string | null;
}

export interface LogEntry {
  id: string;
  event_type: string;
  user_id?: string;
  meta?: Record<string, any>;
  created_at: string;
}

export interface CronJob {
  jobid: number;
  jobname: string;
  schedule: string;
  active: boolean;
  command: string;
}

export interface HealthCheckResult {
  status: 'healthy' | 'warning' | 'error';
  message: string;
  last_execution?: string;
  details?: Record<string, any>;
}

export interface AudioFile {
  id: string;
  user_id: string;
  file_path: string;
  file_size: number;
  created_at: string;
  expires_at?: string;
}

// Updated DailyContent to match database schema (1 row per day with category columns)
export interface DailyContent {
  id: string;
  date: string | null;
  general_headlines: string | null;
  business_headlines: string | null;
  technology_headlines: string | null;
  sports_headlines: string | null;
  sports_summary: string | null;
  stocks_summary: string | null;
  holidays: string | null;
  created_at: string | null;
  // Backward compatibility fields (added dynamically by functions)
  news_category?: string | null;
  headline?: string | null;
}

// Updated UserPreferences to match database schema exactly
export interface UserPreferences {
  id: string;
  user_id: string | null;
  news_categories: string[] | null;
  sports_team: string | null;
  stocks: string[] | null;
  include_weather: boolean | null;
  timezone: string | null;
  updated_at: string | null;
  preferred_name: string | null;
  created_at: string;
  tts_voice: string | null;
}

// Updated AudioType to match database schema constraints
export type AudioType = 'weather' | 'content' | 'general' | 'combined' | 'wake_up_message_1' | 'wake_up_message_2' | 'wake_up_message_3' | 'test_clip';

// Shared audio response interface
export interface AudioResponse {
  success: boolean;
  message: string;
  generatedClips: GeneratedClip[];
  failedClips: FailedClip[];
  alarmId?: string;
  userId?: string;
  storageBaseUrl?: string;
}

export interface GeneratedClip {
  clipId: string;
  fileName: string;
  audioUrl: string;
  fileSize: number;
  audioType?: AudioType;
  duration?: number;
}

export interface FailedClip {
  clipId: string;
  fileName?: string;
  error: string;
  audioType?: AudioType;
  retryCount?: number;
}

// API response interfaces
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  executionTime?: number;
}

// File upload result interface
export interface FileUploadResult {
  success: boolean;
  url?: string;
  error?: string;
  fileSize?: number;
}

// Function execution context
export interface FunctionContext {
  requestId: string;
  userId?: string;
  functionName: string;
  startTime: number;
  [key: string]: any;
}

// Weather data interface matching database schema
export interface WeatherData {
  id: string;
  user_id: string;
  location: string;
  current_temp: number | null;
  high_temp: number | null;
  low_temp: number | null;
  condition: string | null;
  sunrise_time: string | null;
  sunset_time: string | null;
  updated_at: string | null;
  created_at: string | null;
}

// Alarm interface matching database schema
export interface Alarm {
  id: string;
  user_id: string | null;
  alarm_date: string | null;
  alarm_time_local: string;
  alarm_timezone: string;
  next_trigger_at: string | null;
  active: boolean | null;
  updated_at: string | null;
  is_overridden: boolean | null;
}

// Audio metadata interface matching database schema
export interface AudioMetadata {
  id: string;
  user_id: string | null;
  alarm_id: string | null;
  script_text: string | null;
  audio_url: string | null;
  generated_at: string | null;
  error: string | null;
  audio_type: string | null;
  duration_seconds: number | null;
  file_size: number | null;
  expires_at: string | null;
  status: string | null;
  cached_at: string | null;
  cache_status: string | null;
} 