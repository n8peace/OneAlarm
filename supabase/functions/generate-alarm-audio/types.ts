// TypeScript types for the generate-alarm-audio function

import type { 
  AudioResponse, 
  GeneratedClip, 
  FailedClip, 
  AudioType, 
  UserPreferences,
  DailyContent,
  WeatherData,
  Alarm,
  AudioMetadata
} from '../_shared/types/common.ts';

export interface GenerateAlarmAudioRequest {
  alarmId: string;
  forceRegenerate?: boolean;
}

// Use shared AudioResponse interface
export type GenerateAlarmAudioResponse = AudioResponse;

// Re-export shared types to avoid duplication
export type { 
  GeneratedClip, 
  FailedClip, 
  AudioType, 
  UserPreferences,
  DailyContent,
  WeatherData,
  Alarm,
  AudioMetadata
};

export interface DailyContentResult {
  news_category: string;
  content: DailyContent | null;
  success: boolean;
}

export interface GPTResponse {
  script: string;
  estimated_duration_seconds: number;
}

export interface TTSServiceResponse {
  audioBuffer: ArrayBuffer;
  fileName: string;
  fileSize: number;
  durationSeconds: number;
} 