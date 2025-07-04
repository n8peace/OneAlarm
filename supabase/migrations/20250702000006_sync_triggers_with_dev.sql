-- Sync triggers with dev environment
-- Add/update all triggers so production matches dev

-- 1. Timestamp update triggers

-- alarms
DROP TRIGGER IF EXISTS update_alarms_updated_at ON alarms;
CREATE TRIGGER update_alarms_updated_at
  BEFORE UPDATE ON alarms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- audio_files
DROP TRIGGER IF EXISTS update_audio_files_updated_at ON audio_files;
CREATE TRIGGER update_audio_files_updated_at
  BEFORE UPDATE ON audio_files
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- daily_content
DROP TRIGGER IF EXISTS update_daily_content_updated_at ON daily_content;
CREATE TRIGGER update_daily_content_updated_at
  BEFORE UPDATE ON daily_content
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- user_preferences
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER update_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- users
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 2. Audio status change trigger
DROP TRIGGER IF EXISTS on_audio_status_change ON audio;
CREATE TRIGGER on_audio_status_change
  AFTER UPDATE ON audio
  FOR EACH ROW
  EXECUTE FUNCTION log_offline_issue();

-- 3. Sync auth to public user trigger
DROP TRIGGER IF EXISTS trigger_sync_auth_to_public_user ON users;
CREATE TRIGGER trigger_sync_auth_to_public_user
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION sync_auth_to_public_user();

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_sync',
  jsonb_build_object(
    'action', 'sync_triggers_with_dev',
    'timestamp', NOW()
  )
); 