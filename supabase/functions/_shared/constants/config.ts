// Shared configuration constants

export const CONFIG = {
  // Audio settings
  AUDIO: {
    MAX_FILE_SIZE: 50 * 1024 * 1024, // 50MB
    SUPPORTED_FORMATS: ['mp3', 'wav', 'm4a'],
    EXPIRY_HOURS: 24,
    CLEANUP_INTERVAL_HOURS: 6,
    DEFAULT_DURATION_SECONDS: 300, // 5 minutes
    COMBINED_DURATION_SECONDS: 300 // 5 minutes for combined audio
  },

  // OpenAI TTS settings
  TTS: {
    model: 'gpt-4o-mini-tts',
    apiUrl: 'https://api.openai.com/v1/audio/speech',
    defaultVoice: 'nova',
    speed: 1.0, // Normal speed for natural audio generation
    format: 'aac',
    retries: 3,
    retryDelay: 2000, // 2 seconds
    timeout: 30000, // 30 seconds
    maxRetries: 3,
    // Voice options available in OpenAI TTS
    voices: {
      alloy: 'alloy',
      ash: 'ash',
      echo: 'echo', 
      fable: 'fable',
      onyx: 'onyx',
      nova: 'nova',
      sage: 'sage',
      shimmer: 'shimmer',
      verse: 'verse'
    },
    // Instructions for balanced gentle wake-up messages with alertness
    instructions: `Voice Affect: Soft and inviting, like a close friend nudging you awake—retaining gentleness, but with a touch of alertness.

Tone: Calm and reassuring, with subtle warmth and light optimism—convey the quiet joy of a new beginning.

Pacing: Naturally slow but slightly lifted—just enough forward motion to keep energy building without feeling rushed.

Emotion: Warm, kind, and quietly encouraging—let a hint of anticipation or light wonder shine through to guide the listener into wakefulness.

Pronunciation: Smooth and clear—elongate select vowels for comfort, but vary rhythm to prevent flatness. Let key words stand out with intention.

Pauses: Use thoughtful, well-placed pauses to let key ideas land—allow just enough space for breath and reflection, but avoid lulls that might lull them back to sleep.`
  },

  // Storage settings
  STORAGE: {
    bucket: 'audio-files', // Default bucket name
    alarmAudioFolder: 'alarm-audio',
    userAudioFolder: 'users',
    fileExtension: 'aac',
    maxFileSize: 10 * 1024 * 1024 // 10MB
  },

  // Content settings
  CONTENT: {
    MAX_LENGTH: 5000,
    MIN_LENGTH: 10,
    GENERATION_TIMEOUT_MS: 30000 // 30 seconds
  },

  // Cron job settings
  CRON: {
    DAILY_CONTENT_SCHEDULE: '3 * * * *', // Every hour at minute 3
    HEALTH_CHECK_SCHEDULE: '*/30 * * * *', // Every 30 minutes
    CLEANUP_SCHEDULE: '0 */6 * * *' // Every 6 hours
  },

  // Health check settings
  HEALTH: {
    MAX_EXECUTION_GAP_HOURS: 2,
    WARNING_THRESHOLD_HOURS: 1
  },

  // Rate limiting
  RATE_LIMIT: {
    MAX_REQUESTS_PER_MINUTE: 60,
    MAX_REQUESTS_PER_HOUR: 1000
  },

  // Error messages
  ERRORS: {
    INVALID_USER: 'Invalid user ID provided',
    CONTENT_TOO_LONG: 'Content exceeds maximum length',
    CONTENT_TOO_SHORT: 'Content is too short',
    AUDIO_FILE_TOO_LARGE: 'Audio file exceeds maximum size',
    UNSUPPORTED_FORMAT: 'Unsupported audio format',
    GENERATION_TIMEOUT: 'Content generation timed out',
    DATABASE_ERROR: 'Database operation failed',
    UNAUTHORIZED: 'Unauthorized access',
    STORAGE_ERROR: 'Storage upload failed',
    MISSING_PREFERENCES: 'User preferences not found',
    INVALID_VOICE: 'Invalid voice selection',
    OPENAI_ERROR: 'OpenAI TTS generation failed',
    TIMEOUT: 'Audio generation timed out',
    PARTIAL_SUCCESS: 'Some audio clips failed to generate',
    MISSING_ENV_VARS: 'Missing required environment variables'
  }
} as const;

export const EVENT_TYPES = {
  // User events
  USER_LOGIN: 'user_login',
  USER_LOGOUT: 'user_logout',
  USER_REGISTER: 'user_register',

  // Content events
  CONTENT_GENERATED: 'content_generated',
  CONTENT_FAILED: 'content_failed',
  CONTENT_DELIVERED: 'content_delivered',

  // Audio events
  AUDIO_GENERATED: 'audio_generated',
  AUDIO_FAILED: 'audio_failed',
  AUDIO_DELETED: 'audio_deleted',
  AUDIO_GENERATION_COMPLETED: 'audio_generation_completed',

  // System events
  FUNCTION_STARTED: 'function_started',
  FUNCTION_COMPLETED: 'function_completed',
  FUNCTION_FAILED: 'function_failed',
  HEALTH_CHECK: 'health_check',
  CRON_JOB_EXECUTED: 'cron_job_executed',
  DAILY_CONTENT_FUNCTION_STARTED: 'daily_content_function_started'
} as const;

// Supported voices for TTS
export const SUPPORTED_VOICES = [
  'alloy', 'ash', 'echo', 'fable', 'onyx', 'nova', 'sage', 'shimmer', 'verse'
] as const;

export type SupportedVoice = typeof SUPPORTED_VOICES[number];

// Validate voice selection
export function validateVoice(voice: string | null): SupportedVoice {
  if (!voice || !SUPPORTED_VOICES.includes(voice as SupportedVoice)) {
    return 'nova'; // Default fallback
  }
  return voice as SupportedVoice;
} 