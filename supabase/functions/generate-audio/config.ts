// Configuration for the generate-audio function

import { CONFIG as SHARED_CONFIG } from '../_shared/constants/config.ts';

export const CONFIG = {
  // Use shared TTS configuration
  openai: SHARED_CONFIG.TTS,

  // Use shared storage configuration
  storage: {
    bucket: SHARED_CONFIG.STORAGE.bucket,
    pathPrefix: SHARED_CONFIG.STORAGE.userAudioFolder,
    audioFolder: 'audio',
    fileExtension: SHARED_CONFIG.STORAGE.fileExtension
  },

  // Audio clip definitions - Only general wake-up messages
  clips: {
    wake_up_message_1: {
      id: 'wake_up_message_1',
      fileName: 'wake_up_message_1.aac',
      description: 'General wake-up message 1',
      template: 'Good morning, {preferred_name}.\n...\n...\nIt\'s time to start the day — no rush.\n...\n...\nJust take a breath.\n...\n...\nMaybe roll your shoulders or stretch your back a little.\n...\n...\nWaking up is a process.\n...\n...\nYou\'ve got things to do — but you don\'t have to sprint into them.\n...\n...\nOne thing at a time.\n...\n...\nLet\'s get started.'
    },
    wake_up_message_2: {
      id: 'wake_up_message_2',
      fileName: 'wake_up_message_2.aac',
      description: 'General wake-up message 2',
      template: 'Good morning, {preferred_name}.\n...\n...\nTake a moment to just be here.\n...\n...\nFeel your breath, feel your body.\n...\n...\nYou\'re awake, you\'re alive.\n...\n...\nToday is a new day, a fresh start.\n...\n...\nLet\'s begin.'
    },
    wake_up_message_3: {
      id: 'wake_up_message_3',
      fileName: 'wake_up_message_3.aac',
      description: 'General wake-up message 3',
      template: 'Hello, {preferred_name}.\n...\n...\nWelcome to this new day.\n...\n...\nTake a deep breath in... and out.\n...\n...\nYou\'re here, you\'re present.\n...\n...\nReady to face whatever comes.\n...\n...\nLet\'s start.'
    }
  },

  // Generation settings
  generation: {
    batchSize: 3,
    maxRetries: 3,
    retryDelayMs: 1000,
    timeoutMs: 30000
  }
} as const;

// Utility functions
export function getClipTemplate(clipId: string): string {
  return CONFIG.clips[clipId as keyof typeof CONFIG.clips]?.template || '';
}

export function getAllClipIds(): string[] {
  return Object.keys(CONFIG.clips);
}

export function getVoiceFromPreference(voiceGender: string | null): string {
  // Use shared voice validation
  return SHARED_CONFIG.TTS.defaultVoice;
} 