---
title: "Migration Guides"
description: "Switch from other popular Go logging libraries to Rivaas logging"
weight: 12
keywords:
  - logging migration
  - upgrading
  - breaking changes
  - migration guide
---

This guide helps you migrate from other popular Go logging libraries to Rivaas logging.

## Overview

Switching to Rivaas logging is straightforward. The package offers better performance and stdlib integration while maintaining familiar patterns.

**Common migrations:**
- [From logrus](#from-logrus)
- [From zap](#from-zap)
- [From zerolog](#from-zerolog)
- [From stdlib log](#from-stdlib-log)

## From logrus

**logrus** is a popular structured logger, but Rivaas logging offers better performance and native Go integration.

### Basic Setup

**BEFORE (logrus):**
```go
import "github.com/sirupsen/logrus"

log := logrus.New()
log.SetFormatter(&logrus.JSONFormatter{})
log.SetLevel(logrus.InfoLevel)
log.SetOutput(os.Stdout)

log.WithFields(logrus.Fields{
    "user_id": "123",
    "action": "login",
}).Info("User logged in")
```

**AFTER (rivaas/logging):**
```go
import "rivaas.dev/logging"

log := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
    logging.WithOutput(os.Stdout),
)

log.Info("User logged in",
    "user_id", "123",
    "action", "login",
)
```

### Key Differences

| Feature | logrus | rivaas/logging |
|---------|--------|----------------|
| Format config | `&logrus.JSONFormatter{}` | `logging.WithJSONHandler()` |
| Fields | `WithFields(logrus.Fields{})` | Inline key-value pairs |
| Level | `logrus.InfoLevel` | `logging.LevelInfo` |
| Performance | ~2000 ns/op | ~500 ns/op |
| Dependencies | Many external | Go stdlib only |

### Migration Steps

1. **Replace import:**
```go
// Old
import "github.com/sirupsen/logrus"

// New
import "rivaas.dev/logging"
```

2. **Update initialization:**
```go
// Old
log := logrus.New()
log.SetFormatter(&logrus.JSONFormatter{})
log.SetLevel(logrus.InfoLevel)

// New
log := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
)
```

3. **Convert WithFields calls:**
```go
// Old
log.WithFields(logrus.Fields{
    "user_id": "123",
    "action": "login",
}).Info("message")

// New
log.Info("message",
    "user_id", "123",
    "action", "login",
)
```

4. **Update log levels:**
```go
// Old
logrus.DebugLevel -> logging.LevelDebug
logrus.InfoLevel  -> logging.LevelInfo
logrus.WarnLevel  -> logging.LevelWarn
logrus.ErrorLevel -> logging.LevelError
```

## From zap

**zap** is very fast, but Rivaas logging offers similar performance with a simpler API.

### Basic Setup

**BEFORE (zap):**
```go
import "go.uber.org/zap"

logger, _ := zap.NewProduction()
defer logger.Sync()

logger.Info("User logged in",
    zap.String("user_id", "123"),
    zap.String("action", "login"),
    zap.Int("status", 200),
)
```

**AFTER (rivaas/logging):**
```go
import "rivaas.dev/logging"

logger := logging.MustNew(logging.WithJSONHandler())
defer logger.Shutdown(context.Background())

logger.Info("User logged in",
    "user_id", "123",
    "action", "login",
    "status", 200,
)
```

### Key Differences

| Feature | zap | rivaas/logging |
|---------|-----|----------------|
| Typed fields | `zap.String("key", val)` | Direct values |
| Shutdown | `logger.Sync()` | `logger.Shutdown(ctx)` |
| API style | Typed wrappers | Native Go types |
| Performance | ~450 ns/op | ~500 ns/op |
| Complexity | High | Low |

### Migration Steps

1. **Replace import:**
```go
// Old
import "go.uber.org/zap"

// New
import "rivaas.dev/logging"
```

2. **Simplify initialization:**
```go
// Old
logger, _ := zap.NewProduction()

// New
logger := logging.MustNew(logging.WithJSONHandler())
```

3. **Remove type wrappers:**
```go
// Old
logger.Info("message",
    zap.String("name", name),
    zap.Int("count", count),
    zap.Bool("enabled", enabled),
)

// New
logger.Info("message",
    "name", name,
    "count", count,
    "enabled", enabled,
)
```

4. **Update shutdown:**
```go
// Old
defer logger.Sync()

// New
defer logger.Shutdown(context.Background())
```

## From zerolog

**zerolog** is very fast, but Rivaas logging is simpler and uses stdlib.

### Basic Setup

**BEFORE (zerolog):**
```go
import "github.com/rs/zerolog"

logger := zerolog.New(os.Stdout).With().
    Str("service", "myapp").
    Str("version", "1.0.0").
    Logger()

logger.Info().
    Str("user_id", "123").
    Str("action", "login").
    Msg("User logged in")
```

**AFTER (rivaas/logging):**
```go
import "rivaas.dev/logging"

logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithServiceName("myapp"),
    logging.WithServiceVersion("1.0.0"),
)

logger.Info("User logged in",
    "user_id", "123",
    "action", "login",
)
```

### Key Differences

| Feature | zerolog | rivaas/logging |
|---------|---------|----------------|
| API style | Chaining | Functional options |
| Context | `.With().Str().Logger()` | `WithServiceName()` |
| Fields | `.Str("k", v).Msg()` | Inline pairs |
| Performance | ~400 ns/op | ~500 ns/op |
| Readability | Medium | High |

### Migration Steps

1. **Replace import:**
```go
// Old
import "github.com/rs/zerolog"

// New
import "rivaas.dev/logging"
```

2. **Simplify initialization:**
```go
// Old
logger := zerolog.New(os.Stdout).With().
    Str("service", "myapp").
    Str("version", "1.0.0").
    Logger()

// New
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithServiceName("myapp"),
    logging.WithServiceVersion("1.0.0"),
)
```

3. **Remove chaining:**
```go
// Old
logger.Info().
    Str("user_id", "123").
    Str("action", "login").
    Msg("User logged in")

// New
logger.Info("User logged in",
    "user_id", "123",
    "action", "login",
)
```

## From stdlib log

**Standard library log** is simple but unstructured. Rivaas logging adds structure while using stdlib slog.

### Basic Setup

**BEFORE (stdlib log):**
```go
import "log"

log.SetOutput(os.Stdout)
log.SetPrefix("[INFO] ")
log.Printf("User %s logged in from %s", userID, ipAddress)
```

**AFTER (rivaas/logging):**
```go
import "rivaas.dev/logging"

logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
)

logger.Info("User logged in",
    "user_id", userID,
    "ip_address", ipAddress,
)
```

### Key Benefits

| Feature | stdlib log | rivaas/logging |
|---------|------------|----------------|
| Structure | No | Yes |
| Log levels | No | Yes |
| Formats | Text only | JSON, Text, Console |
| Performance | Fast | Fast |
| Parsing | Manual | Automatic |

### Migration Steps

1. **Replace import:**
```go
// Old
import "log"

// New
import "rivaas.dev/logging"
```

2. **Update initialization:**
```go
// Old
log.SetOutput(os.Stdout)
log.SetPrefix("[INFO] ")

// New
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
)
```

3. **Convert Printf to structured:**
```go
// Old
log.Printf("User %s logged in from %s", userID, ipAddress)

// New
logger.Info("User logged in",
    "user_id", userID,
    "ip_address", ipAddress,
)
```

## Migration Checklist

Use this checklist when migrating:

- [ ] Replace logger initialization
- [ ] Update all log calls to structured format
- [ ] Replace log level constants
- [ ] Update context/field methods (WithFields → inline)
- [ ] Replace typed field methods (zap.String → direct values)
- [ ] Update error handling (Sync → Shutdown)
- [ ] Test with new logger
- [ ] Update imports
- [ ] Remove old logger dependency from go.mod
- [ ] Update documentation and examples

## Gradual Migration

Migrate gradually to minimize risk.

### Phase 1: Parallel Logging

Run both loggers side-by-side:

```go
// Keep old logger
oldLogger := logrus.New()

// Add new logger
newLogger := logging.MustNew(logging.WithJSONHandler())

// Log to both
func logInfo(msg string, fields map[string]any) {
    // Old logger
    oldLogger.WithFields(logrus.Fields(fields)).Info(msg)
    
    // New logger
    args := make([]any, 0, len(fields)*2)
    for k, v := range fields {
        args = append(args, k, v)
    }
    newLogger.Info(msg, args...)
}
```

### Phase 2: Feature Flag

Use feature flag to switch between loggers:

```go
func getLogger() Logger {
    if os.Getenv("USE_NEW_LOGGER") == "true" {
        return logging.MustNew(logging.WithJSONHandler())
    }
    return logrus.New()
}
```

### Phase 3: Full Migration

Once validated, remove old logger completely.

## Performance Comparison

Benchmark results (lower is better):

| Logger | ns/op | allocs/op | Dependencies |
|--------|-------|-----------|--------------|
| stdlib slog | 450 | 0 | 0 |
| rivaas/logging | 500 | 0 | 1 (OTel) |
| zap | 450 | 0 | Many |
| zerolog | 400 | 0 | Several |
| logrus | 2000 | 5 | Many |

**Note:** rivaas/logging overhead is minimal compared to stdlib slog while adding valuable features.

## Common Migration Issues

### Issue: Missing Fields

**Problem:** Fields not appearing in logs.

**Solution:** Check field names match new format:

```go
// Wrong - using old field format
log.Info("message", logrus.Fields{"key": "value"})

// Right - inline key-value pairs
log.Info("message", "key", "value")
```

### Issue: Log Level Not Working

**Problem:** Debug logs not appearing.

**Solution:** Check log level configuration:

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithDebugLevel(),  // Make sure to set debug level
)
```

### Issue: Performance Regression

**Problem:** Logging slower than expected.

**Solution:** Check for common issues:
- Logging in tight loops
- Source location enabled in production
- Not using appropriate log level

## Getting Help

If you encounter issues during migration:

1. Check the [Troubleshooting](/reference/packages/logging/troubleshooting/) guide
2. Review [Examples](../examples/) for patterns
3. See [Best Practices](../best-practices/) for recommendations
4. Consult the [API Reference](/reference/packages/logging/api-reference/)

## Next Steps

- Review [Best Practices](../best-practices/) for production patterns
- See [Examples](../examples/) for complete patterns
- Explore [Testing](../testing/) for test utilities

For complete API details, see the [API Reference](/reference/packages/logging/api-reference/).
