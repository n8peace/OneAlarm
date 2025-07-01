-- Fix audio logging trigger to only log audio_not_cached_in_time for expiring audio
-- This prevents logging for persistent user-specific audio files

CREATE OR REPLACE FUNCTION log_offline_issue()
RETURNS TRIGGER AS $$
BEGIN
  -- Log when audio wasn't cached in time (status ready but not cached)
  -- Only log for audio files that have an expiration date
  IF NEW.status = 'ready' AND NEW.cache_status = 'pending' AND NEW.expires_at IS NOT NULL THEN
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'audio_not_cached_in_time',
      NEW.user_id,
      jsonb_build_object(
        'audio_id', NEW.id,
        'alarm_id', NEW.alarm_id,
        'audio_type', NEW.audio_type,
        'generated_at', NEW.generated_at,
        'expires_at', NEW.expires_at
      )
    );
  END IF;
  
  -- Log when audio expires without being cached
  IF NEW.status = 'expired' AND NEW.cache_status = 'pending' THEN
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'audio_expired_uncached',
      NEW.user_id,
      jsonb_build_object(
        'audio_id', NEW.id,
        'alarm_id', NEW.alarm_id,
        'audio_type', NEW.audio_type,
        'generated_at', NEW.generated_at,
        'expires_at', NEW.expires_at
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
