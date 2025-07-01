// Database types for Supabase operations

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          email: string | null;
          phone: string | null;
          onboarding_done: boolean | null;
          subscription_status: string | null;
          created_at: string | null;
          is_admin: boolean | null;
          last_login: string | null;
        };
        Insert: {
          id?: string;
          email?: string | null;
          phone?: string | null;
          onboarding_done?: boolean | null;
          subscription_status?: string | null;
          created_at?: string | null;
          is_admin?: boolean | null;
          last_login?: string | null;
        };
        Update: {
          id?: string;
          email?: string | null;
          phone?: string | null;
          onboarding_done?: boolean | null;
          subscription_status?: string | null;
          created_at?: string | null;
          is_admin?: boolean | null;
          last_login?: string | null;
        };
      };
      user_preferences: {
        Row: {
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
        };
        Insert: {
          id?: string;
          user_id?: string | null;
          news_categories?: string[] | null;
          sports_team?: string | null;
          stocks?: string[] | null;
          include_weather?: boolean | null;
          timezone?: string | null;
          updated_at?: string | null;
          preferred_name?: string | null;
          created_at?: string;
          tts_voice?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string | null;
          news_categories?: string[] | null;
          sports_team?: string | null;
          stocks?: string[] | null;
          include_weather?: boolean | null;
          timezone?: string | null;
          updated_at?: string | null;
          preferred_name?: string | null;
          created_at?: string;
          tts_voice?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "user_preferences_user_id_fkey";
            columns: ["user_id"];
            referencedRelation: "users";
            referencedColumns: ["id"];
          }
        ];
      };
      alarms: {
        Row: {
          id: string;
          user_id: string | null;
          alarm_date: string | null;
          alarm_time_local: string;
          alarm_timezone: string;
          next_trigger_at: string | null;
          active: boolean | null;
          updated_at: string | null;
          is_overridden: boolean | null;
        };
        Insert: {
          id?: string;
          user_id?: string | null;
          alarm_date?: string | null;
          alarm_time_local: string;
          alarm_timezone: string;
          next_trigger_at?: string | null;
          active?: boolean | null;
          updated_at?: string | null;
          is_overridden?: boolean | null;
        };
        Update: {
          id?: string;
          user_id?: string | null;
          alarm_date?: string | null;
          alarm_time_local?: string;
          alarm_timezone?: string;
          next_trigger_at?: string | null;
          active?: boolean | null;
          updated_at?: string | null;
          is_overridden?: boolean | null;
        };
      };
      logs: {
        Row: {
          id: string;
          user_id: string | null;
          event_type: string | null;
          meta: Record<string, any> | null;
          created_at: string | null;
        };
        Insert: {
          id?: string;
          user_id?: string | null;
          event_type?: string | null;
          meta?: Record<string, any> | null;
          created_at?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string | null;
          event_type?: string | null;
          meta?: Record<string, any> | null;
          created_at?: string | null;
        };
      };
      daily_content: {
        Row: {
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
        };
        Insert: {
          id?: string;
          date?: string | null;
          general_headlines?: string | null;
          business_headlines?: string | null;
          technology_headlines?: string | null;
          sports_headlines?: string | null;
          sports_summary?: string | null;
          stocks_summary?: string | null;
          holidays?: string | null;
          created_at?: string | null;
        };
        Update: {
          id?: string;
          date?: string | null;
          general_headlines?: string | null;
          business_headlines?: string | null;
          technology_headlines?: string | null;
          sports_headlines?: string | null;
          sports_summary?: string | null;
          stocks_summary?: string | null;
          holidays?: string | null;
          created_at?: string | null;
        };
      };
      audio: {
        Row: {
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
        };
        Insert: {
          id?: string;
          user_id?: string | null;
          alarm_id?: string | null;
          script_text?: string | null;
          audio_url?: string | null;
          generated_at?: string | null;
          error?: string | null;
          audio_type?: string | null;
          duration_seconds?: number | null;
          file_size?: number | null;
          expires_at?: string | null;
          status?: string | null;
          cached_at?: string | null;
          cache_status?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string | null;
          alarm_id?: string | null;
          script_text?: string | null;
          audio_url?: string | null;
          generated_at?: string | null;
          error?: string | null;
          audio_type?: string | null;
          duration_seconds?: number | null;
          file_size?: number | null;
          expires_at?: string | null;
          status?: string | null;
          cached_at?: string | null;
          cache_status?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "audio_user_id_fkey";
            columns: ["user_id"];
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "audio_alarm_id_fkey";
            columns: ["alarm_id"];
            referencedRelation: "alarms";
            referencedColumns: ["id"];
          }
        ];
      };
      weather_data: {
        Row: {
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
        };
        Insert: {
          id?: string;
          user_id: string;
          location: string;
          current_temp?: number | null;
          high_temp?: number | null;
          low_temp?: number | null;
          condition?: string | null;
          sunrise_time?: string | null;
          sunset_time?: string | null;
          updated_at?: string | null;
          created_at?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string;
          location?: string;
          current_temp?: number | null;
          high_temp?: number | null;
          low_temp?: number | null;
          condition?: string | null;
          sunrise_time?: string | null;
          sunset_time?: string | null;
          updated_at?: string | null;
          created_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "weather_data_user_id_fkey";
            columns: ["user_id"];
            referencedRelation: "users";
            referencedColumns: ["id"];
          }
        ];
      };
      audio_generation_queue: {
        Row: {
          id: string;
          alarm_id: string;
          user_id: string;
          scheduled_for: string;
          status: string;
          retry_count: number | null;
          max_retries: number | null;
          error_message: string | null;
          created_at: string | null;
          processed_at: string | null;
          priority: number | null;
        };
        Insert: {
          id?: string;
          alarm_id: string;
          user_id: string;
          scheduled_for: string;
          status?: string;
          retry_count?: number | null;
          max_retries?: number | null;
          error_message?: string | null;
          created_at?: string | null;
          processed_at?: string | null;
          priority?: number | null;
        };
        Update: {
          id?: string;
          alarm_id?: string;
          user_id?: string;
          scheduled_for?: string;
          status?: string;
          retry_count?: number | null;
          max_retries?: number | null;
          error_message?: string | null;
          created_at?: string | null;
          processed_at?: string | null;
          priority?: number | null;
        };
        Relationships: [
          {
            foreignKeyName: "audio_generation_queue_alarm_id_fkey";
            columns: ["alarm_id"];
            referencedRelation: "alarms";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "audio_generation_queue_user_id_fkey";
            columns: ["user_id"];
            referencedRelation: "users";
            referencedColumns: ["id"];
          }
        ];
      };
      user_events: {
        Row: {
          id: string;
          user_id: string | null;
          event_type: string | null;
          created_at: string | null;
        };
        Insert: {
          id?: string;
          user_id?: string | null;
          event_type?: string | null;
          created_at?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string | null;
          event_type?: string | null;
          created_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "user_events_user_id_fkey";
            columns: ["user_id"];
            referencedRelation: "users";
            referencedColumns: ["id"];
          }
        ];
      };
    };
    Views: {
      [_ in never]: never
    }
  };
} 