---
title: "Basic Usage"
description: "Learn the fundamentals of structured logging with handler types and output formats"
weight: 3
keywords:
  - logging basic usage
  - log messages
  - simple logging
  - getting started
---

This guide covers the essential operations for working with the logging package. Learn to choose handler types, set log levels, and produce structured log output.

## Handler Types

The logging package supports three output formats, each optimized for different use cases.

### JSON Handler (Production)

JSON format is ideal for production environments and log aggregation systems:

```go
log := logging.MustNew(
    logging.WithJSONHandler(),
)

log.Info("user action", "user_id", "123", "action", "login")
```

**Output:**
```json
{"time":"2024-01-15T10:30:45.123Z","level":"INFO","msg":"user action","user_id":"123","action":"login"}
```

**Use cases:**
- Production environments.
- Log aggregation systems like ELK, Splunk, Datadog.
- Machine-parseable logs.
- Cloud logging services.

### Text Handler

Text format outputs key=value pairs, readable but still parseable:

```go
log := logging.MustNew(
    logging.WithTextHandler(),
)

log.Info("request processed", "method", "GET", "path", "/api/users")
```

**Output:**
```
time=2024-01-15T10:30:45.123Z level=INFO msg="request processed" method=GET path=/api/users
```

**Use cases:**
- Systems that prefer key=value format
- Legacy log parsers
- Environments where JSON is too verbose

### Console Handler (Development)

Console format provides human-readable colored output for development:

```go
log := logging.MustNew(
    logging.WithConsoleHandler(),
)

log.Info("server starting", "port", 8080)
```

**Output (with colors):**
```
10:30:45.123 INFO  server starting port=8080
```

**Use cases:**
- Local development.
- Debugging.
- Terminal output.
- Interactive troubleshooting.

**Note:** Console handler uses ANSI colors automatically. Colors are optimized for dark terminal themes.

## Log Levels

Control log verbosity with log levels. Each level has a specific purpose.

### Available Levels

```go
// From most to least verbose:
logging.LevelDebug   // Detailed debugging information
logging.LevelInfo    // General informational messages
logging.LevelWarn    // Warning messages (not errors)
logging.LevelError   // Error messages
```

### Setting Log Level

Configure the minimum log level during initialization:

```go
log := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),  // Only Info, Warn, Error
)

log.Debug("this won't appear")  // Filtered out
log.Info("this will appear")    // Logged
log.Error("this will appear")   // Logged
```

### Debug Level Shortcut

Enable debug logging with a convenience function:

```go
log := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithDebugLevel(),  // Same as WithLevel(logging.LevelDebug)
)
```

### Level Usage Guidelines

**DEBUG** - Detailed information for debugging
```go
log.Debug("cache hit", "key", cacheKey, "ttl", ttl)
```

**INFO** - General informational messages
```go
log.Info("server started", "port", 8080)
```

**WARN** - Warning but not an error
```go
log.Warn("high memory usage", "used_mb", 8192, "total_mb", 16384)
```

**ERROR** - Errors that need attention
```go
log.Error("database connection failed", "error", err, "retry_count", retries)
```

## Structured Logging

The logging package uses structured logging with key-value pairs, not string concatenation.

### Basic Structured Fields

```go
log.Info("user logged in",
    "user_id", userID,
    "ip_address", ipAddress,
    "session_id", sessionID,
)
```

**Output (JSON):**
```json
{
  "time": "2024-01-15T10:30:45.123Z",
  "level": "INFO",
  "msg": "user logged in",
  "user_id": "123",
  "ip_address": "192.168.1.1",
  "session_id": "abc-xyz"
}
```

### Why Structured Logging?

**BAD - String concatenation:**
```go
log.Info("User " + userID + " logged in from " + ipAddress)
```

**GOOD - Structured fields:**
```go
log.Info("user logged in",
    "user_id", userID,
    "ip_address", ipAddress,
)
```

**Benefits:**
- Machine-parseable
- Searchable by field
- Type-safe (numbers stay numbers)
- Easier to aggregate and analyze

### Type Support

The logger handles various types automatically:

```go
log.Info("operation details",
    "name", "process_data",           // string
    "count", 1024,                     // int
    "enabled", true,                   // bool
    "duration", 250*time.Millisecond,  // duration
    "rate", 99.5,                      // float64
    "timestamp", time.Now(),           // time
    "error", err,                      // error
)
```

## Complete Example

Putting it all together:

```go
package main

import (
    "rivaas.dev/logging"
)

func main() {
    // Create logger for development
    log := logging.MustNew(
        logging.WithConsoleHandler(),
        logging.WithDebugLevel(),
    )

    // Log at different levels
    log.Debug("application starting", "version", "v1.0.0")
    log.Info("server listening", "port", 8080, "env", "development")
    log.Warn("high latency detected", "latency_ms", 250, "threshold_ms", 200)
    log.Error("database connection failed", "error", "connection timeout")
}
```

## Common Patterns

### Logging with Context

Add related fields that persist across multiple log calls:

```go
// Create a logger with persistent fields
requestLog := log.With(
    "request_id", "req-123",
    "user_id", "user-456",
)

requestLog.Info("validation started")
requestLog.Info("validation completed")
// Both logs include request_id and user_id
```

### Logging Errors

Always include the error:

```go
if err := db.Connect(); err != nil {
    log.Error("database connection failed",
        "error", err,
        "host", dbHost,
        "port", dbPort,
        "retry_count", retries,
    )
}
```

### Avoid Logging in Tight Loops

```go
// BAD - logs thousands of times
for _, item := range items {
    log.Debug("processing", "item", item)
    process(item)
}

// GOOD - log once with summary
log.Info("processing batch", "count", len(items))
for _, item := range items {
    process(item)
}
log.Info("batch completed", "processed", len(items))
```

## Next Steps

- Learn [Configuration](../configuration/) to customize logger behavior
- Explore [Context Logging](../context-logging/) for trace correlation
- See [Convenience Methods](../convenience-methods/) for common patterns
- Review [Best Practices](../best-practices/) for production use

For complete API details, see the [API Reference](/reference/packages/logging/api-reference/).
