// TTS service for generating audio from scripts

import { CONFIG, type SupportedVoice } from '../config.ts';
import type { TTSServiceResponse } from '../types.ts';

export class TTSService {
  private apiKey: string;
  private baseUrl = 'https://api.openai.com/v1/audio/speech';

  constructor() {
    const apiKey = Deno.env.get('OPENAI_API_KEY');
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY environment variable is required');
    }
    this.apiKey = apiKey;
  }

  async generateSpeech(script: string, voice: SupportedVoice): Promise<TTSServiceResponse> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= CONFIG.tts.retries; attempt++) {
      try {
        const response = await fetch(this.baseUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: CONFIG.tts.model,
            input: script,
            voice: voice,
            speed: CONFIG.tts.speed,
            response_format: CONFIG.tts.format,
            instructions: CONFIG.tts.instructions
          })
        });

        if (!response.ok) {
          const errorText = await response.text();
          throw new Error(`OpenAI TTS API error: ${response.status} - ${errorText}`);
        }

        const audioBuffer = await response.arrayBuffer();
        const fileName = `audio_${Date.now()}.${CONFIG.tts.format}`;

        // Calculate approximate duration based on script length and voice speed
        // Average speaking rate is ~150 words per minute, adjusted for voice speed
        const wordCount = script.split(' ').length;
        const baseDurationSeconds = (wordCount / 150) * 60; // Base duration at normal speed
        const adjustedDurationSeconds = baseDurationSeconds / CONFIG.tts.speed;

        return {
          audioBuffer,
          fileName,
          fileSize: audioBuffer.byteLength,
          durationSeconds: Math.round(adjustedDurationSeconds)
        };

      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        console.warn(`TTS attempt ${attempt} failed:`, lastError.message);
        
        if (attempt < CONFIG.tts.retries) {
          await this.delay(CONFIG.tts.retryDelay * attempt); // Exponential backoff
        }
      }
    }

    throw new Error(`TTS generation failed after ${CONFIG.tts.retries} attempts: ${lastError?.message}`);
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
} 