# OneAlarm by SunriseAI

## Phase 2: SwiftUI Integration Guide

This guide provides everything a developer needs to build the OneAlarm iOS app using SwiftUI, fully integrated with the Supabase backend. It covers authentication, user onboarding, preferences, alarm management, audio generation, caching, playback, and real-time updates.

**🚀 Production Ready**: The backend is now fully prepared for SwiftUI integration with enhanced security, combined audio generation, multi-category news support, enhanced sports coverage, and comprehensive real-time features.

# What's New & Key Recommendations

- **Single Combined Audio File**: Each alarm generates one AAC file (3-5 min) with weather, news, sports, markets, and holidays.
- **Multi-Category News**: Users can select from general, business, technology, and sports news categories.
- **Enhanced Sports Coverage**: Two-day sports events with timezone-aware processing, finished games with scores, and upcoming games with local times.
- **Fresh Content**: Audio is generated 58 minutes before alarm time for up-to-date info.
- **Real-Time Subscriptions**: Use Supabase subscriptions for instant updates on audio, alarms, and preferences.
- **Security**: All user data and audio files are protected by Row Level Security (RLS) and secure storage policies.
- **Onboarding**: **User preferences must be explicitly created during onboarding** - no auto-creation triggers.
- **Caching & Offline Playback**: Download and cache audio locally for offline use; update `cache_status` in the `audio` table.
- **Testing**: Use provided scripts (e.g., `test-system.sh`) to validate backend integration.
- **Scaling**: Backend is ready for thousands of users and alarms per day; see docs/SYSTEM_LIMITS.md and docs/SCALING_ROADMAP.md.
- **Performance**: Fixed cascade trigger issue (June 26, 2025) - eliminated duplicate audio generation calls for improved performance.
- **Clean User Creation**: No automatic user_preferences creation - explicit control over user setup process.

---

## Table of Contents

1. Introduction
2. Architecture Overview
3. Enhanced Audio Features
4. Security & Privacy
5. Supabase Setup & Configuration
6. Authentication (Apple Sign-In)
7. User Onboarding Flow
8. User Preferences Management
9. Alarm Creation & Management
10. Audio Generation & Status Tracking
11. Audio Caching & Secure Playback
12. Real-Time Updates & Subscriptions
13. Offline Handling & Issue Logging
14. Example SwiftUI Code Snippets
15. Troubleshooting & FAQ
16. Resources & References

---

## 1. Introduction

Welcome to the OneAlarm SwiftUI integration guide! This document is your complete reference for building a production-grade iOS app that leverages the OneAlarm backend for personalized, AI-powered alarm audio. All backend features are ready for real-time, secure, and seamless integration with your SwiftUI app.

**What you'll learn:**
- How to authenticate users with Apple Sign-In and Supabase
- How to manage user onboarding and preferences
- How to create, update, and delete alarms
- How to trigger and monitor AI-powered audio generation with combined content
- How to securely cache and play audio files with Row Level Security
- How to subscribe to real-time updates for alarms and audio
- How to handle offline scenarios and log issues

**🎵 Enhanced Audio Features:**
- **Single Combined Audio**: One comprehensive file per alarm (3-5 minutes) including weather, news, sports, and market information
- **AAC Format**: Better audio quality with optimized file sizes (~1-2MB per file)
- **TTS Speed**: 0.95 for calmer, more soothing audio delivery
- **Production Security**: Row Level Security (RLS) protecting all user data

Let's get started! 

## 2. Architecture Overview

The OneAlarm iOS app is a SwiftUI client that communicates with a Supabase backend. The backend handles authentication, user preferences, alarm scheduling, audio generation, and secure file storage. Real-time updates are delivered via Supabase subscriptions.

**High-Level Flow:**

1. User signs in with Apple (or email/password, if enabled)
2. App syncs user profile and preferences from Supabase
3. User sets alarms and preferences in the app
4. Alarms trigger audio generation in the backend (58 minutes before alarm time)
5. App receives real-time updates and downloads audio files securely
6. Audio is cached and played back locally

```
sequenceDiagram
    participant App as SwiftUI App
    participant Supabase as Supabase Backend
    participant OpenAI as OpenAI API
    participant Storage as Supabase Storage

    App->>Supabase: Sign in (Apple)
    Supabase-->>App: JWT Session
    App->>Supabase: Fetch/Update Preferences
    App->>Supabase: Create/Update Alarm
    Supabase->>OpenAI: Generate Combined Audio
    Supabase->>Storage: Store Audio File (AAC format)
    Supabase-->>App: Real-time update (audio ready)
    App->>Storage: Download Audio (RLS protected)
    App-->>User: Play Audio
```

## 3. Enhanced Audio Features

### Single Combined Audio File

The backend now generates **one comprehensive audio file** per alarm:

- **Combined Content**: Weather (if available), news, sports, stocks, and holidays in one seamless clip
- **Duration**: 3-5 minutes of personalized content
- **Format**: AAC for optimal quality and file size
- **Audio Type**: `'combined'` in database

### Audio Quality Improvements
- **Format**: AAC (Advanced Audio Codec) for better quality
- **Speed**: 0.95 (slightly slower for calming effect)
- **File Sizes**: ~1-2MB per combined file (optimized)
- **Generation Time**: ~30-60 seconds per alarm

### Content Structure
Each combined audio file includes:
1. **Weather Updates** (if available) - Natural, conversational weather with helpful recommendations
2. **News Overview** - Professional news summaries based on user interests
3. **Sports Updates** - Team-specific sports coverage
4. **Market Updates** - Stock and financial information
5. **Holiday Recognition** - Appropriate time allocation based on holiday importance
6. **Gentle Transitions** - Smooth flow between content segments with pauses

### Sports Data
- **Enhanced Coverage**: Two-day sports events with timezone-aware processing
- **Smart Formatting**: Finished games show scores, upcoming games show local times
- **Comprehensive**: Today's Games + Tomorrow's Games sections
- **Local Time Display**: Game times shown in venue's local timezone

## 4. Security & Privacy

### Row Level Security (RLS)
- **Enabled on audio table** for user data protection
- **User isolation**: Users can only access their own audio records
- **Service role access**: Backend functions have full access for automation
- **Production ready**: Secure by default for SwiftUI app integration

### Data Protection
- **48-hour audio expiration**: Automatic cleanup of audio files
- **Secure storage**: Audio files stored in Supabase Storage with access policies
- **User authentication**: All user data protected by Supabase Auth

### Implementation
```swift
// Audio files are automatically protected by RLS
// Users can only access their own audio records
let audio = try await supabase.from("audio")
    .select()
    .eq("user_id", userId) // RLS ensures only user's data
    .execute()
```

## 5. Supabase Setup & Configuration

### Prerequisites
- Supabase project (with Edge Functions enabled)
- Supabase CLI installed
- OpenAI API key
- Apple Developer account (for Sign In with Apple)

### 1. Clone the Repo & Link Project
```bash
supabase link --project-ref <YOUR_PROJECT_REF>
```

### 2. Configure Environment Variables
Set these in your Xcode project and in the Supabase dashboard:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (for client)
- `SUPABASE_SERVICE_ROLE_KEY` (for backend scripts)
- `OPENAI_API_KEY`

All scripts and backend calls use environment variables. Set these in your `.env` file:
```
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
```
Source the shared script config in your scripts:
```bash
source ./scripts/config.sh
```

### 3. Deploy Edge Functions
```bash
supabase functions deploy daily-content
supabase functions deploy generate-audio
supabase functions deploy generate-alarm-audio
```

### 4. Apply Migrations
```bash
supabase db push
```

### 5. Configure Apple Sign-In in Supabase
- Go to Supabase Dashboard → Authentication → Providers
- Enable Apple and fill in your Apple credentials (Client ID, Secret, etc.)
- Add your app's bundle ID and redirect URIs

### 6. Add Redirect URI to Apple Developer Portal
- Add your Supabase Auth redirect URI (e.g., `https://<project>.supabase.co/auth/v1/callback`) to your Apple app identifier

## 6. Authentication (Apple Sign-In)

### Overview
- Users authenticate with Apple using Supabase Auth
- **Automatic User Creation**: On first sign-in, a user row is automatically created in the `public.users` table via database trigger
- **One-Way Sync**: Changes in `auth.users` automatically sync to `public.users`, but not vice versa
- JWT session is used for all subsequent API calls

### User Creation Flow
1. User signs in with Apple → `auth.users` record created
2. Database trigger automatically creates corresponding `public.users` record
3. App can immediately access user data in `public.users` table
4. No manual user creation needed in the app

### Swift Package Setup
Add [supabase-community/supabase-swift](https://github.com/supabase-community/supabase-swift) to your project:

```swift
.package(url: "https://github.com/supabase-community/supabase-swift.git", from: "0.2.0")
```

### Apple Sign-In Flow Example

```swift
import Supabase
import AuthenticationServices

class AuthViewModel: ObservableObject {
    @Published var session: Session?
    let supabase = SupabaseClient(supabaseURL: "<SUPABASE_URL>", supabaseKey: "<SUPABASE_ANON_KEY>")

    func signInWithApple() async throws {
        let result = try await supabase.auth.signInWithIdToken(
            provider: .apple,
            idToken: <YOUR_ID_TOKEN>,
            nonce: <YOUR_NONCE>
        )
        self.session = result.session
        
        // User record is automatically created in public.users via database trigger
        // No need to manually create user record
    }
}
```

- Use `ASAuthorizationAppleIDProvider` to get the ID token and nonce
- Pass them to `supabase.auth.signInWithIdToken`
- On success, store the session and use it for all Supabase calls
- The corresponding `public.users` record is created automatically

### Session Persistence
- Store the session in `@AppStorage` or Keychain
- Restore session on app launch

### Handling Sign-Out
```swift
try await supabase.auth.signOut()
self.session = nil
```

### User Data Access
After authentication, you can immediately access user data:

```swift
// Get current user ID from session
let userId = session?.user.id

// Access user data in public.users table
let user = try await supabase.from("users")
    .select()
    .eq("id", userId)
    .single()
    .execute()

// Access user preferences
let prefs = try await supabase.from("user_preferences")
    .select()
    .eq("user_id", userId)
    .single()
    .execute()
```

## 7. User Onboarding Flow

### Overview
- **User preferences must be explicitly created during onboarding** - no auto-creation triggers
- The app should create a `user_preferences` row for the user during onboarding
- Guide the user through onboarding screens (name, voice, timezone, etc.)
- Update `user_preferences` as the user completes each step
- The `user_preferences` table includes:
  - `tts_voice`, `preferred_name`, `timezone`, `news_categories`, `sports_team`, `stocks`
  - `onboarding_completed` (boolean)
  - `onboarding_step` (string)
  - `created_at`, `updated_at`

### Creating User Preferences (First Time)
```swift
// Create user preferences during onboarding
let userPrefs = [
    "user_id": userId,
    "tts_voice": "alloy",
    "timezone": "America/New_York",
    "news_categories": ["general"],
    "onboarding_completed": false,
    "onboarding_step": "welcome"
]

try await supabase.from("user_preferences")
    .insert(userPrefs)
    .execute()
```

### Fetching Onboarding Status
```swift
let prefs = try await supabase.from("user_preferences")
    .select()
    .eq("user_id", userId)
    .single()
    .execute()

let onboardingCompleted = prefs["onboarding_completed"] as? Bool ?? false
let onboardingStep = prefs["onboarding_step"] as? String ?? "welcome"
```

### Updating Onboarding Step
```swift
try await supabase.from("user_preferences")
    .update(["onboarding_step": "voice_selection"])
    .eq("user_id", userId)
    .execute()
```

### Completing Onboarding
```swift
try await supabase.from("user_preferences")
    .update(["onboarding_completed": true])
    .eq("user_id", userId)
    .execute()
```

## 8. User Preferences Management

### Overview
- Preferences are stored in the `user_preferences` table
- Includes: `tts_voice`, `preferred_name`, `timezone`, `news_categories`, `sports_team`, `stocks`, etc.
- Updating preferences can trigger new audio generation (via trigger)

### Fetching Preferences
```swift
let prefs = try await supabase.from("user_preferences")
    .select()
    .eq("user_id", userId)
    .single()
    .execute()

let ttsVoice = prefs["tts_voice"] as? String ?? "alloy"
let timezone = prefs["timezone"] as? String ?? "America/New_York"
let newsCategories = prefs["news_categories"] as? [String] ?? ["general"]
let preferredName = prefs["preferred_name"] as? String ?? "there"
```

### Updating Preferences
```swift
try await supabase.from("user_preferences")
    .update([
        "tts_voice": "nova",
        "preferred_name": "Alex",
        "timezone": "America/Los_Angeles",
        "news_categories": ["general", "technology"],
        "sports_team": "Lakers",
        "stocks": ["AAPL", "GOOGL", "TSLA"]
    ])
    .eq("user_id", userId)
    .execute()
```

- After updating, listen for real-time updates or poll for new audio status

## 9. Alarm Creation & Management

### Overview
- Alarms are stored in the `alarms` table
- Creating or updating an alarm auto-populates the audio generation queue (via trigger)
- Each alarm has: `alarm_time_local`, `timezone_at_creation`, `label`, etc.
- **One audio file per alarm**: The backend always generates a single combined audio file per alarm (`audio_type: 'combined'`).
- **Real-time updates**: Subscribe to the `audio` table for status changes (`generating` → `ready`).
- **Freshness**: Audio is generated 58 minutes before the alarm time.

### Creating an Alarm
```swift
let alarm = [
    "user_id": userId,
    "alarm_time_local": "07:30:00",
    "timezone_at_creation": "America/New_York",
    "label": "Morning Alarm"
]
let result = try await supabase.from("alarms")
    .insert(alarm)
    .execute()
```

### Updating an Alarm
```swift
try await supabase.from("alarms")
    .update(["alarm_time_local": "08:00:00"])
    .eq("id", alarmId)
    .execute()
```

### Deleting an Alarm
```swift
try await supabase.from("alarms")
    .delete()
    .eq("id", alarmId)
    .execute()
```

### Fetching Alarms
```swift
let alarms = try await supabase.from("alarms")
    .select()
    .eq("user_id", userId)
    .order("alarm_time_local")
    .execute()
```

## 10. Audio Generation & Status Tracking

### Overview
- **Generic Audio Files**: Pre-generated audio files available immediately for all voice types
- **Combined Audio**: Custom audio generated for each alarm with personalized content
- Audio is generated automatically when alarms or preferences change (via triggers)
- Each audio file is tracked in the `audio` table with `status`, `cache_status`, and `file_size`
- Status values: `generating`, `ready`, `failed`, `expired`
- Cache status: `pending`, `downloading`, `cached`, `failed`
- **Real-time status**: Use subscriptions or polling to detect when audio is `ready`.
- **Error handling**: Handle 401 (auth) and 409 (conflict) errors; use PATCH-then-POST logic for upserts.

### Generic Audio Files (Pre-Generated)
**Location**: `audio-files/generic_audio/`

**Available Files** (48 total):
- **6 messages per voice**: 5 wake-up messages + 1 voice preview
- **8 voice types**: alloy, ash, echo, fable, onyx, nova, shimmer, verse
- **File naming**: `{voice}_{message_id}.aac`
- **Examples**: 
  - `alloy_generic_wake_up_message_1.aac`
  - `nova_generic_voice_preview.aac`

**Accessing Generic Audio**:
```swift
// Get user's preferred voice
let ttsVoice = prefs["tts_voice"] as? String ?? "alloy"

// Construct generic audio URL
let genericAudioUrl = "https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/generic_audio/\(ttsVoice)_generic_wake_up_message_1.aac"

// Download and cache generic audio
let (data, _) = try await URLSession.shared.data(from: URL(string: genericAudioUrl)!)
// Save to local cache
```

**Generic Message Types**:
1. `generic_wake_up_message_1` - "Good morning. It's time to start the day — no rush..."
2. `generic_wake_up_message_2` - "Good morning. Take a moment to just be here..."
3. `generic_wake_up_message_3` - "Hello. Welcome to this new day..."
4. `generic_wake_up_message_4` - "Good morning. The day is waiting..."
5. `generic_wake_up_message_5` - "Rise and shine. A new day is here..."
6. `generic_voice_preview` - "Good morning. I'm here to help you ease into each day..."

### Combined Audio (Personalized)
**One combined audio file per alarm**: Always use the latest with `audio_type: 'combined'`.

### Fetching Audio for an Alarm
```swift
let audio = try await supabase.from("audio")
    .select()
    .eq("alarm_id", alarmId)
    .eq("audio_type", "combined")
    .order("generated_at", ascending: false)
    .limit(1)
    .single()
    .execute()

let status = audio["status"] as? String ?? "generating"
let audioUrl = audio["audio_url"] as? String
```

### Monitoring Audio Status
- Poll the `audio` table or use real-time subscriptions (see below)
- When `status` becomes `ready`, the audio file is available for download
- **Expected**: One combined audio file with `audio_type: 'combined'` and AAC format

## 11. Audio Caching & Secure Playback

### Overview
- **Generic Audio**: Pre-generated files available immediately for instant playback
- **Combined Audio**: Personalized files stored in Supabase Storage with RLS (Row Level Security)
- Only the authenticated user can access their personalized audio files
- The app should download and cache audio for offline playback
- **Offline playback**: Cache audio files locally and play with AVAudioPlayer or similar.
- **Update cache status**: After download, update `cache_status` in the `audio` table to `cached`.
- **AAC format** with optimized file sizes (~1-2MB per file)

### Caching Strategy
1. **Generic Audio**: Download and cache all 6 messages for user's preferred voice on first app launch
2. **Combined Audio**: Download and cache personalized alarm audio when `status` becomes `ready`
3. **Fallback**: Use generic audio if combined audio is not available

### Downloading Generic Audio Securely
```swift
// Generic audio files are public, no authentication required
let ttsVoice = prefs["tts_voice"] as? String ?? "alloy"
let genericAudioUrl = "https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/generic_audio/\(ttsVoice)_generic_wake_up_message_1.aac"

let (data, _) = try await URLSession.shared.data(from: URL(string: genericAudioUrl)!)
// Save data to local cache
```

### Downloading Combined Audio Securely
```swift
let audioUrl = audio["audio_url"] as? String ?? ""
let session = supabase.auth.session
var request = URLRequest(url: URL(string: audioUrl)!)
request.setValue("Bearer \(session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

let (data, _) = try await URLSession.shared.data(for: request)
// Save data to local cache
```

### Caching Audio Locally
- Store audio files in the app's sandboxed file system (e.g., `FileManager`)
- Update `cache_status` in the `audio` table to `cached` after successful download

```swift
try await supabase.from("audio")
    .update(["cache_status": "cached"])
    .eq("id", audioId)
    .execute()
```

### Playing Audio
- Use `AVAudioPlayer` or SwiftUI audio libraries to play cached files
- **Generic content**: Pre-generated wake-up messages with calm, gentle tone
- **Combined content**: Single comprehensive file with weather, news, sports, and market information

## 12. Real-Time Updates & Subscriptions

### Overview
- Supabase provides real-time subscriptions for `audio`, `alarms`, and `user_preferences`
- Use these to update the UI instantly when audio is ready, alarms change, or preferences update

### Subscribing to Audio Updates
```swift
import SupabaseRealtime

let channel = supabase.realtime.channel("public:audio:user_id=eq.\(userId)")
channel.on(.postgresChanges, { payload in
    // Handle insert/update/delete events
    print("Audio table changed: \(payload)")
})
channel.subscribe()
```

### Subscribing to Alarm Updates
```swift
let alarmChannel = supabase.realtime.channel("public:alarms:user_id=eq.\(userId)")
alarmChannel.on(.postgresChanges, { payload in
    // Handle alarm changes
})
alarmChannel.subscribe()
```

### Unsubscribing
```swift
channel.unsubscribe()
alarmChannel.unsubscribe()
```

## 13. Offline Handling & Issue Logging

### Overview
- The app should gracefully handle offline scenarios (e.g., no network, failed downloads)
- Log issues to the backend for monitoring and support

### Best Practices
- Cache all audio and alarm data locally (Core Data, SQLite, or file system)
- Queue user actions (alarm changes, preference updates) and sync when online
- Use Reachability/Network framework to detect connectivity

### Logging Issues to Supabase
- Use the `logs` table to record app-side issues (e.g., failed downloads, playback errors)

```swift
let log = [
    "event_type": "audio_download_failed",
    "user_id": userId,
    "meta": [
        "audio_id": audioId,
        "error": error.localizedDescription
    ]
]
try await supabase.from("logs").insert(log).execute()
```

## 14. Testing & Data Operations

### Backend Testing
The backend includes comprehensive testing capabilities for validating the entire system:

#### End-to-End Load Testing
```bash
# Test the complete system with 10 users
bash scripts/test-system.sh load YOUR_SERVICE_ROLE_KEY
```
This script creates 10 complete user setups and validates the entire audio generation pipeline.

#### Idempotent Data Operations
The backend uses PATCH-then-POST upsert logic for reliable data operations:
- **PATCH**: Update existing records by user_id
- **POST**: Create new records if not found (404 response)
- **Safe for Repeated Runs**: Scripts work regardless of existing data

#### Testing Best Practices
- **HTTP Status Handling**: Always check status codes (404 for not found, 409 for conflicts)
- **Graceful Degradation**: Handle missing data or API failures gracefully
- **Comprehensive Logging**: Log all operations and errors for debugging

### iOS App Testing
When testing your SwiftUI app:

#### Data Consistency
- Use real Supabase Auth users for all operations
- Handle both new and existing data gracefully
- Implement proper error handling for 409 conflicts

#### Audio Generation Testing
```bash
# Test audio generation for a specific user
bash scripts/test-system.sh audio YOUR_SERVICE_ROLE_KEY

# Check recent audio files
bash scripts/check-recent-audio.sh YOUR_USER_ID
```

#### Expected Results
- **One combined audio file** per alarm with `audio_type: 'combined'`
- **AAC format** with optimized file sizes (~1-2MB)
- **Real-time updates** via Supabase subscriptions
- **RLS protection** ensuring users only access their own data

---

## 15. Example SwiftUI Code Snippets

### Basic Supabase Client Setup
```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: "<SUPABASE_URL>",
    supabaseKey: "<SUPABASE_ANON_KEY>"
)
```

### Fetching User Preferences
```swift
let prefs = try await supabase.from("user_preferences")
    .select()
    .eq("user_id", userId)
    .single()
    .execute()
```

### Creating an Alarm
```swift
let alarm = [
    "user_id": userId,
    "alarm_time_local": "07:00:00",
    "timezone_at_creation": "America/New_York"
]
try await supabase.from("alarms").insert(alarm).execute()
```

### Downloading and Playing Audio
```swift
let audioUrl = audio["audio_url"] as? String ?? ""
let session = supabase.auth.session
var request = URLRequest(url: URL(string: audioUrl)!)
request.setValue("Bearer \(session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
let (data, _) = try await URLSession.shared.data(for: request)
// Save to file, then play with AVAudioPlayer
```

---

## 16. Troubleshooting & FAQ

**Q: How do I check if the backend functions are healthy?**
- Each Edge Function exposes a health check endpoint:

```bash
curl -H "Authorization: Bearer <service_role_key>" https://<project>.supabase.co/functions/v1/generate-alarm-audio
```
A healthy function returns:
```json
{
  "status": "healthy",
  "timestamp": "...",
  "version": "1.0.0",
  "function": "generate-alarm-audio"
}
```

**Q: Why is audio not being generated after I set an alarm?**
- Check that the alarm is created in the database and the queue is populated
- Ensure the backend Edge Functions are deployed and running
- Check the `audio` table for status (`generating`, `ready`, `failed`)
- **Audio is generated 58 minutes before alarm time** for freshest content

**Q: Why do I get a 401 error when downloading audio?**
- Make sure you include the `Authorization: Bearer <access_token>` header in your request
- Confirm the user is authenticated and the session is valid
- **RLS policies** ensure only authenticated users can access their own audio

**Q: How do I handle errors from backend functions?**
- All backend functions return errors in this format:
```json
{
  "success": false,
  "error": "Error message here"
}
```
Check the `logs` table for more details on backend errors.

**Q: How do I invoke backend functions?**
- All POST requests to Edge Functions require:
  - JSON body (see function docs)
  - `Authorization: Bearer <access_token>` header
- All GET requests for health checks require only the header.

**Q: How many audio files should I expect per alarm?**
- **One combined audio file per alarm**: Includes weather, news, sports, stocks, and holidays
- All files are in **AAC format** with optimized file sizes (~1-2MB)
- Audio type will be `'combined'` in the database

**Q: What's included in the combined audio file?**
- **Weather updates** (if available): Natural, conversational weather with recommendations
- **News overview**: Professional news summaries based on user's selected news categories (general, business, technology, sports)
- **Enhanced Sports updates**: Two-day coverage with timezone-aware processing, finished games with scores, upcoming games with local times
- **Market updates**: Stock and financial information
- **Holiday recognition**: Appropriate time allocation based on holiday importance
- **Gentle transitions**: Smooth flow between content segments with pauses

**Q: How do I handle the combined audio in my app?**
- Display the single combined audio file for each alarm
- Allow users to preview the audio before setting alarms
- Cache the combined file locally for offline playback
- Use real-time subscriptions to know when new audio is ready
- Monitor the `audio_type` field to ensure you're getting `'combined'` files

**Q: How do I test the backend before building my iOS app?**
- Run the end-to-end load test: `bash scripts/test-system.sh load YOUR_SERVICE_ROLE_KEY`
- Test individual functions: `bash scripts/test-system.sh audio YOUR_SERVICE_ROLE_KEY`