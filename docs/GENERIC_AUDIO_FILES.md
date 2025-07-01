# Generic Audio Files

## Overview
Pre-generated audio files available immediately for all voice types, providing instant playback capability for the OneAlarm app.

## 📁 File Details

### Storage Location
- **Path**: `audio-files/generic_audio/`
- **Access**: Public URLs (no authentication required)
- **Format**: AAC files
- **Total Files**: 48 (6 messages × 8 voices)

### Base URL
```
https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/generic_audio/
```

## 🎤 Available Voice Types

| Voice | Description | Example File |
|-------|-------------|--------------|
| `alloy` | Neutral, balanced voice | `alloy_generic_wake_up_message_1.aac` |
| `ash` | Deep, authoritative voice | `ash_generic_wake_up_message_1.aac` |
| `echo` | Warm, friendly voice | `echo_generic_wake_up_message_1.aac` |
| `fable` | Storytelling voice | `fable_generic_wake_up_message_1.aac` |
| `onyx` | Strong, confident voice | `onyx_generic_wake_up_message_1.aac` |
| `nova` | Bright, energetic voice | `nova_generic_wake_up_message_1.aac` |
| `shimmer` | Soft, gentle voice | `shimmer_generic_wake_up_message_1.aac` |
| `verse` | Poetic, melodic voice | `verse_generic_wake_up_message_1.aac` |

## 📝 Available Message Types

| Message ID | Content |
|------------|---------|
| `generic_wake_up_message_1` | "Good morning. It's time to start the day — no rush..." |
| `generic_wake_up_message_2` | "Good morning. Take a moment to just be here..." |
| `generic_wake_up_message_3` | "Hello. Welcome to this new day..." |
| `generic_wake_up_message_4` | "Good morning. The day is waiting..." |
| `generic_wake_up_message_5` | "Rise and shine. A new day is here..." |
| `generic_voice_preview` | "Good morning. I'm here to help you ease into each day..." |

## 🔗 URL Construction

### JavaScript/TypeScript
```javascript
const baseUrl = "https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/generic_audio/";
const fileName = `${ttsVoice}_${messageId}.aac`;
const fullUrl = baseUrl + fileName;

// Example
const url = baseUrl + "nova_generic_wake_up_message_1.aac";
```

### Swift
```swift
let baseUrl = "https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/generic_audio/"
let fileName = "\(ttsVoice)_\(messageId).aac"
let fullUrl = baseUrl + fileName

// Example
let url = baseUrl + "nova_generic_wake_up_message_1.aac"
```

## 📱 App Integration

### Usage Strategy
1. **Instant Playback**: Use generic files for immediate audio response
2. **Fallback Option**: Use when personalized audio is not available
3. **Voice Selection**: Match user's preferred TTS voice
4. **Caching**: Download and cache all 6 messages for user's voice on first launch

### Caching Recommendations
- Download all 6 messages for user's preferred voice on app launch
- Store locally in app's sandboxed file system
- Update cache when user changes voice preference
- Use cached files for offline playback

### File Management
- **No database records**: Generic files are not tracked in the `audio` table
- **Storage only**: Files exist only in Supabase Storage
- **Public access**: No RLS policies apply to generic audio files
- **App responsibility**: iOS app manages caching and playback

## 🧪 Testing

### Test Access
```bash
# Test generic audio access
curl "https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/generic_audio/alloy_generic_wake_up_message_1.aac"

# List all files (if needed)
curl "https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/list/audio-files/generic_audio/"
```

### Verification
- All 48 files are accessible via public URLs
- Files are in AAC format with optimized quality
- File sizes are consistent (~80KB each)
- No authentication required for access

## 📊 File Inventory

### Complete File List
```
alloy_generic_wake_up_message_1.aac
alloy_generic_wake_up_message_2.aac
alloy_generic_wake_up_message_3.aac
alloy_generic_wake_up_message_4.aac
alloy_generic_wake_up_message_5.aac
alloy_generic_voice_preview.aac
ash_generic_wake_up_message_1.aac
ash_generic_wake_up_message_2.aac
ash_generic_wake_up_message_3.aac
ash_generic_wake_up_message_4.aac
ash_generic_wake_up_message_5.aac
ash_generic_voice_preview.aac
echo_generic_wake_up_message_1.aac
echo_generic_wake_up_message_2.aac
echo_generic_wake_up_message_3.aac
echo_generic_wake_up_message_4.aac
echo_generic_wake_up_message_5.aac
echo_generic_voice_preview.aac
fable_generic_wake_up_message_1.aac
fable_generic_wake_up_message_2.aac
fable_generic_wake_up_message_3.aac
fable_generic_wake_up_message_4.aac
fable_generic_wake_up_message_5.aac
fable_generic_voice_preview.aac
onyx_generic_wake_up_message_1.aac
onyx_generic_wake_up_message_2.aac
onyx_generic_wake_up_message_3.aac
onyx_generic_wake_up_message_4.aac
onyx_generic_wake_up_message_5.aac
onyx_generic_voice_preview.aac
nova_generic_wake_up_message_1.aac
nova_generic_wake_up_message_2.aac
nova_generic_wake_up_message_3.aac
nova_generic_wake_up_message_4.aac
nova_generic_wake_up_message_5.aac
nova_generic_voice_preview.aac
shimmer_generic_wake_up_message_1.aac
shimmer_generic_wake_up_message_2.aac
shimmer_generic_wake_up_message_3.aac
shimmer_generic_wake_up_message_4.aac
shimmer_generic_wake_up_message_5.aac
shimmer_generic_voice_preview.aac
verse_generic_wake_up_message_1.aac
verse_generic_wake_up_message_2.aac
verse_generic_wake_up_message_3.aac
verse_generic_wake_up_message_4.aac
verse_generic_wake_up_message_5.aac
verse_generic_voice_preview.aac
```

## 🚀 Benefits

1. **Instant Availability**: No generation delay for immediate app response
2. **Reliability**: Pre-generated files ensure consistent availability
3. **Performance**: Reduces server load and generation costs
4. **User Experience**: Faster app startup and voice selection
5. **Fallback Safety**: Backup option when personalized audio fails

---

**Status**: ✅ **READY FOR APP INTEGRATION**  
**Generated**: June 2025  
**Total Files**: 48/48 ✅ 