// GPT service for generating combined audio scripts

import { CONFIG } from '../config.ts';
import type { WeatherData, UserPreferences, DailyContent, DailyContentResult, GPTResponse, Alarm } from '../types.ts';

export class GPTService {
  private apiKey: string;
  private baseUrl = 'https://api.openai.com/v1/chat/completions';

  constructor() {
    const apiKey = Deno.env.get('OPENAI_API_KEY');
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY environment variable is required');
    }
    this.apiKey = apiKey;
  }

  async generateCombinedScript(
    alarm: Alarm,
    weatherData: WeatherData | null, 
    userPreferences: UserPreferences | null, 
    dailyContentResults: DailyContentResult[]
  ): Promise<string> {
    const prompt = this.buildCombinedPrompt(alarm, weatherData, userPreferences, dailyContentResults);
    
    const response = await this.callGPT(prompt, CONFIG.gpt.maxTokens.combined);
    
    return response.script;
  }

  private async callGPT(prompt: string, maxTokens: number): Promise<GPTResponse> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= CONFIG.gpt.retries; attempt++) {
      try {
        const response = await fetch(this.baseUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: CONFIG.gpt.model,
            messages: [
              {
                role: 'system',
                content: CONFIG.prompts.system
              },
              {
                role: 'user',
                content: prompt
              }
            ],
            temperature: CONFIG.gpt.temperature,
            max_tokens: maxTokens,
            response_format: { type: 'json_object' }
          })
        });

        if (!response.ok) {
          const errorText = await response.text();
          throw new Error(`OpenAI API error: ${response.status} - ${errorText}`);
        }

        const data = await response.json();
        const content = data.choices[0]?.message?.content;
        
        if (!content) {
          throw new Error('No content received from GPT');
        }

        // Parse JSON response
        const parsed = JSON.parse(content);
        
        if (!parsed.script) {
          throw new Error('Invalid response format from GPT - missing script');
        }

        return {
          script: parsed.script,
          estimated_duration_seconds: parsed.estimated_duration_seconds || 30
        };

      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        console.warn(`GPT attempt ${attempt} failed:`, lastError.message);
        
        if (attempt < CONFIG.gpt.retries) {
          await this.delay(CONFIG.gpt.retryDelay * attempt); // Exponential backoff
        }
      }
    }

    throw new Error(`GPT generation failed after ${CONFIG.gpt.retries} attempts: ${lastError?.message}`);
  }

  private buildCombinedPrompt(
    alarm: Alarm,
    weatherData: WeatherData | null, 
    userPreferences: UserPreferences | null, 
    dailyContentResults: DailyContentResult[]
  ): string {
    const tone = 'calm and encouraging'; // Fixed tone for all users
    const name = userPreferences?.preferred_name || 'there';
    
    // Calculate the local date for the alarm
    let alarmDateInfo = 'Date information not available.';
    let alarmTimeInfo = '';
    if (alarm.alarm_date && alarm.alarm_timezone && alarm.alarm_time_local) {
      try {
        // Format date
        const localDate = new Date(`${alarm.alarm_date}T12:00:00`).toLocaleDateString('en-US', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          timeZone: alarm.alarm_timezone
        });
        alarmDateInfo = `Today is ${localDate}.`;
        // Format time
        const [hour, minute] = alarm.alarm_time_local.split(":");
        const localTime = new Date(`${alarm.alarm_date}T${alarm.alarm_time_local}:00Z`);
        const formattedTime = localTime.toLocaleTimeString('en-US', {
          hour: '2-digit',
          minute: '2-digit',
          hour12: true,
          timeZone: alarm.alarm_timezone
        });
        alarmTimeInfo = `Alarm Time: ${formattedTime}`;
      } catch (error) {
        console.warn('Failed to format alarm date/time:', error);
        alarmDateInfo = 'Date information not available.';
        alarmTimeInfo = '';
      }
    }
    
    // Build weather section
    const weatherSection = this.formatWeatherSummary(weatherData);
    
    // Build content sections
    const newsItems = this.extractNewsItems(dailyContentResults);
    const stockData = this.extractStockData(dailyContentResults, userPreferences);
    
    let contentInfo = 'No daily content available.';
    if (dailyContentResults.length > 0) {
      const availableContent = dailyContentResults.filter(result => result.success && result.content);
      
      if (availableContent.length > 0) {
        // Get the first available content row (should be the same for all categories now)
        const contentRow = availableContent[0].content;
        
        contentInfo = availableContent.map(result => {
          // Extract the headline for this specific category
          const headlineColumn = `${result.news_category}_headlines` as keyof typeof contentRow;
          const categoryHeadline = (contentRow?.[headlineColumn] as string) || 'No news available';
          
          return `
**${result.news_category.charAt(0).toUpperCase() + result.news_category.slice(1)} News:**
- Headline: ${categoryHeadline}
- Sports: ${contentRow?.sports_summary || 'No sports available'}
- Stocks: ${contentRow?.stocks_summary || 'No market data available'}
- Holidays: ${contentRow?.holidays || 'No holidays today'}`;
        }).join('\n\n');
      }
    }

    const userInfo = userPreferences ? `
**User Preferences:**
- Name: ${userPreferences.preferred_name || 'there'}
- News Categories: ${dailyContentResults.map(result => result.news_category).join(', ')}
- Sports Team: ${userPreferences.sports_team || 'none specified'}
- Stocks: ${userPreferences.stocks?.join(', ') || 'none specified'}
- Content Duration: 300 seconds` : 'No user preferences available.';

    return `${CONFIG.prompts.combined}

**Alarm Date:** ${alarmDateInfo}
${alarmTimeInfo ? `\n**${alarmTimeInfo}**` : ''}

${weatherSection}

${contentInfo}

${userInfo}

Respond in this JSON format:
{
  "script": "the full spoken content as a string",
  "estimated_duration_seconds": estimated_duration_when_spoken
}`;
  }

  private formatWeatherSummary(weatherData: WeatherData | null): string {
    if (!weatherData) {
      return '**Weather:** No weather data available.';
    }

    let forecast = '';
    if (weatherData.high_temp && weatherData.low_temp) {
      forecast += `High of ${weatherData.high_temp}°F`;
      if (weatherData.current_temp) {
        forecast += `, currently ${weatherData.current_temp}°F`;
      }
    } else if (weatherData.current_temp) {
      forecast += `Currently ${weatherData.current_temp}°F`;
    }
    
    if (weatherData.condition) {
      forecast += `, ${weatherData.condition.toLowerCase()}`;
    }

    return `**Weather for ${weatherData.location}:**
- Forecast: ${forecast}
- Sunrise: ${weatherData.sunrise_time || 'Not available'}
- Sunset: ${weatherData.sunset_time || 'Not available'}`;
  }

  private extractNewsItems(dailyContentResults: DailyContentResult[]): string[] {
    const availableContent = dailyContentResults.filter(result => result.success && result.content);
    return availableContent.map(result => {
      // Extract the headline for this specific category
      const headlineColumn = `${result.news_category}_headlines` as keyof typeof result.content;
      return (result.content?.[headlineColumn] as string) || 'No news available';
    });
  }

  private extractStockData(dailyContentResults: DailyContentResult[], userPreferences: UserPreferences | null): Array<{ticker: string, price: number, change: string}> {
    // This would parse stock data from dailyContent.stocks_summary
    // For now, return empty array as the actual parsing logic would depend on the format
    return [];
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
} 