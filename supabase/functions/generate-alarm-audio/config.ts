// Configuration for the generate-alarm-audio function

import { CONFIG as SHARED_CONFIG, validateVoice, SUPPORTED_VOICES, type SupportedVoice } from '../_shared/constants/config.ts';

export const CONFIG = {
  // OpenAI GPT settings
  gpt: {
    model: 'gpt-4o',
    temperature: 0.8, // Balanced creativity for natural, varied responses
    maxTokens: {
      combined: 1200  // ~4-5 minute combined script (weather + content)
    },
    retries: 3,
    retryDelay: 1000, // 1 second
  },

  // Use shared TTS configuration
  tts: SHARED_CONFIG.TTS,

  // Audio settings - use shared duration
  audio: {
    combinedDuration: SHARED_CONFIG.AUDIO.COMBINED_DURATION_SECONDS, // 300 seconds (5 minutes)
    expirationHours: 48, // Audio files expire after 48 hours
  },

  // Use shared storage configuration
  storage: {
    bucket: SHARED_CONFIG.STORAGE.bucket,
    folder: SHARED_CONFIG.STORAGE.alarmAudioFolder,
    maxFileSize: SHARED_CONFIG.STORAGE.maxFileSize,
  },

  // System settings
  system: {
    timeout: 300000, // 5 minutes
    maxExecutionTime: 240000, // 4 minutes
  },

  // Prompts
  prompts: {
    system: `You are a warm and intelligent personal guide. Generate a gentle but motivating morning message script to help wake someone up.

Your tone is: calm, positive, emotionally intelligent — like a close friend or thoughtful companion easing them into the day.

Target a spoken duration of 4–5 minutes (~500–700 words). If needed, slow the pacing by adding ellipses and line breaks.

Structure (vary language, but keep this general flow):
1. Greeting — Use a natural, slightly varied morning greeting with the user's first name.
2. Date & Weather — Mention today's date, location, the current weather, highs and lows, and sunrise. Do not create any information — only use what's provided in the user data. Add basic applicable suggestions (umbrella, layers, sunscreen, avoid outside at this time, be safe, etc.) if relevant.
3. Stretch Prompt — Suggest a gentle breathing or movement exercise. Keep it light and optional.
4. News, Market, and Sports — Choose 2–4 news stories based on the user's preferences. Select the stories that are most important or impactful to them — including serious or negative news when relevant. Maintain a calm, matter-of-fact tone. Limit summaries to 1–2 sentences per story. Don't rush through them and do not make anything up. Add a pause between stories. Follow with stock price updates for their selected tickers and the S&P 500, rounded to the nearest dollar. Mention a sports result or schedule if it applies to the user's team.
5. Closing — End with a calm, grounded message or short quote. Focus on clarity, progress, or intention. Gently encourage presence, confidence, or gratitude. Avoid clichés.

Include natural transitions between sections to maintain a smooth, conversational flow.

Use ellipses (...) and paragraph breaks to insert natural pauses.

If any data (weather, tickers, sports, etc.) is missing, skip that section gracefully. Do not invent or assume any information.

Refer to places colloquially when appropriate. Use contractions. Talk like a human.

The message should be warm and human. Avoid robotic phrasing or obvious scripting.

This message is cached — do not invite interaction or ask questions.`,

    combined: `Create a personalized morning message using the following inputs:

Structure (vary language, but keep this general flow):
1. Greeting — Use a natural, slightly varied morning greeting with the user's first name.
2. Date & Weather — Mention today's date, location, the current weather, highs and lows, and sunrise. Do not create any information — only use what's provided in the user data. Add basic applicable suggestions (umbrella, layers, sunscreen, avoid outside at this time, be safe, etc.) if relevant.
3. Stretch Prompt — Suggest a gentle breathing or movement exercise. Keep it light and optional.
4. News, Market, and Sports — Choose 2–4 news stories based on the user's preferences. Select the stories that are most important or impactful to them — including serious or negative news when relevant. Maintain a calm, matter-of-fact tone. Limit summaries to 1–2 sentences per story. Don't rush through them and do not make anything up. Add a pause between stories. Follow with stock price updates for their selected tickers and the S&P 500, rounded to the nearest dollar. Mention a sports result or schedule if it applies to the user's team.
5. Closing — End with a calm, grounded message or short quote. Focus on clarity, progress, or intention. Gently encourage presence, confidence, or gratitude. Avoid clichés.

Include natural transitions between sections to maintain a smooth, conversational flow.

Use ellipses (...) and paragraph breaks to insert natural pauses.

If any data (weather, tickers, sports, etc.) is missing, skip that section gracefully. Do not invent or assume any information.

Refer to places colloquially when appropriate. Use contractions. Talk like a human.

The message should be warm and human. Avoid robotic phrasing or obvious scripting.

This message is cached — do not invite interaction or ask questions.

**Weather Integration:**
- If weather data is available, start with a natural weather summary
- Include location, current conditions, and forecast
- Add helpful recommendations based on conditions
- If no weather data, skip weather section and start with content

**Content Integration:**
- Focus on news, sports, and market information relevant to user preferences
- Include smooth transitions between sections
- Keep it professional and low-affect
- Do not use phrases like "you've got this" or "it's going to be a great day"

**User Preferences:**
- Name: {preferred_name or 'there'}
- News Category: {news_category or 'general'}
- Sports Team: {sports_team or 'none specified'}
- Stocks: {stocks_list or 'none specified'}
- Content Duration: 300 seconds

Output a JSON object like this:
{
  "script": "the full spoken message with line breaks and ellipses",
  "estimated_duration_seconds": estimated_spoken_duration
}`
  },

  // Use shared error messages
  errors: SHARED_CONFIG.ERRORS
} as const;

// Re-export shared voice validation
export { validateVoice, SUPPORTED_VOICES, type SupportedVoice };