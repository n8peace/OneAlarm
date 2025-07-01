// Types for the generate-audio function

import type { AudioResponse, GeneratedClip, FailedClip, AudioType, UserPreferences } from '../_shared/types/common.ts';

export interface AudioClip {
  id: string;
  text: string;
  fileName: string;
  description: string;
}

// Re-export shared types to avoid duplication
export type { UserPreferences, AudioResponse, GeneratedClip, FailedClip, AudioType };

export interface AudioGenerationRequest {
  userId: string;
  forceRegenerate?: boolean;
}

// Use shared AudioResponse interface
export type AudioGenerationResponse = AudioResponse;

export interface OpenAITTSRequest {
  model: string;
  input: string;
  voice: string;
  response_format: string;
  speed: number;
  instructions?: string;
}

export interface OpenAITTSResponse {
  data: Array<{
    url: string;
  }>;
}

// Alias for backward compatibility
export type S3UploadResult = import('../_shared/types/common.ts').FileUploadResult;

export interface AudioGenerationConfig {
  maxRetries: number;
  retryDelayMs: number;
  timeoutMs: number;
  voiceMapping: Record<string, string>;
}

export interface AudioGenerationJob {
  userId: string;
  clips: AudioClip[];
  preferences: UserPreferences;
  status: 'pending' | 'in_progress' | 'completed' | 'failed' | 'partial';
  generatedClips: GeneratedClip[];
  failedClips: FailedClip[];
  startedAt: string;
  completedAt?: string;
  error?: string;
} 