# Shared Utilities

This directory contains shared utilities, types, and constants that are used across all Supabase Edge Functions.

## Structure

```
_shared/
├── types/           # TypeScript type definitions
├── utils/           # Utility functions
├── services/        # Service clients and configurations
├── constants/       # Application constants
└── templates/       # Function templates
```

## Usage

### Importing Shared Types

```typescript
import type { BaseResponse, User, LogEntry } from '../_shared/types/common.ts';
import type { Database } from '../_shared/types/database.ts';
```

### Using Shared Utilities

```typescript
import { logEvent, getUserById } from '../_shared/utils/database.ts';
import { logFunctionStart, logFunctionEnd } from '../_shared/utils/logging.ts';
```

### Using Shared Constants

```typescript
import { CONFIG, EVENT_TYPES } from '../_shared/constants/config.ts';
```

## Available Utilities

### Database Utils (`utils/database.ts`)

- `supabase` - Pre-configured Supabase client
- `logEvent()` - Log events to the database
- `getUserById()` - Get user by ID
- `getDailyContentByUserId()` - Get daily content for user
- `getAudioFilesByUserId()` - Get audio files for user
- `deleteExpiredAudioFiles()` - Clean up expired audio files

### Logging Utils (`utils/logging.ts`)

- `log()` - Generic logging function
- `logDebug()`, `logInfo()`, `logWarn()`, `logError()` - Level-specific logging
- `logFunctionStart()`, `logFunctionEnd()`, `logFunctionError()` - Function lifecycle logging

### Configuration (`constants/config.ts`)

- `CONFIG` - Application configuration constants
- `EVENT_TYPES` - Standardized event type constants

## Creating New Functions

1. Copy the template from `templates/function-template.ts`
2. Update the function name and interfaces
3. Implement your function logic
4. Use shared utilities for common operations

## Best Practices

1. **Always use shared types** for consistency
2. **Log function lifecycle** using the logging utilities
3. **Use configuration constants** instead of hardcoded values
4. **Handle errors consistently** using the error constants
5. **Log events** to the database for monitoring

## Adding New Shared Utilities

1. Create the utility in the appropriate directory
2. Export it from an index file if needed
3. Update this README with usage examples
4. Ensure it follows the established patterns 