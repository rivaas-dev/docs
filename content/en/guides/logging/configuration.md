---
title: "Configuration"
description: "Configure loggers with all available options for production readiness"
weight: 4
keywords:
  - logging configuration
  - log format
  - output
  - log options
---

This guide covers all configuration options available in the logging package. It covers handler selection to service metadata.

## Handler Configuration

Choose the appropriate handler type for your environment.

### Handler Types

```go
// JSON structured logging. Default and best for production.
logging.WithJSONHandler()

// Text key=value logging.
logging.WithTextHandler()

// Human-readable colored console. Best for development.
logging.WithConsoleHandler()
```

See [Basic Usage](../basic-usage/) for detailed handler comparison.

## Log Level Configuration

Control which log messages are output.

### Setting Minimum Level

```go
// Set specific level
logging.WithLevel(logging.LevelDebug)
logging.WithLevel(logging.LevelInfo)
logging.WithLevel(logging.LevelWarn)
logging.WithLevel(logging.LevelError)

// Convenience function for debug
logging.WithDebugLevel()
```

**Example:**
```go
log := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),  // Info, Warn, Error only
)
```

See [Dynamic Log Levels](../dynamic-levels/) to change levels at runtime.

## Output Destination

By default, logs write to `os.Stdout`. Customize the output destination:

### File Output

```go
logFile, err := os.OpenFile("app.log", 
    os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
if err != nil {
    log.Fatal(err)
}
defer logFile.Close()

logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithOutput(logFile),
)
```

### Custom Writer

Any `io.Writer` can be used:

```go
var buf bytes.Buffer
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithOutput(&buf),
)
```

### Multiple Writers

Use `io.MultiWriter` to write to multiple destinations:

```go
logFile, _ := os.OpenFile("app.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)

logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithOutput(io.MultiWriter(os.Stdout, logFile)),
)
```

## Service Information

Add service metadata automatically to every log entry.

### Service Metadata

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithServiceName("my-api"),
    logging.WithServiceVersion("v1.0.0"),
    logging.WithEnvironment("production"),
)

logger.Info("server started", "port", 8080)
```

**Output:**
```json
{
  "level": "INFO",
  "msg": "server started",
  "service": "my-api",
  "version": "v1.0.0",
  "env": "production",
  "port": 8080
}
```

### Why Service Metadata?

- **Filtering:** Query logs by service in aggregation tools
- **Correlation:** Track logs across distributed services
- **Versioning:** Identify which version produced logs
- **Environment:** Distinguish between dev/staging/prod logs

### Reading Service Information

Access configured service info programmatically:

```go
serviceName := logger.ServiceName()
version := logger.ServiceVersion()
env := logger.Environment()
```

## Source Code Location

Add file and line information to log entries for debugging.

### Enable Source Location

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithSource(true),
)

logger.Info("debug message")
```

**Output:**
```json
{
  "level": "INFO",
  "msg": "debug message",
  "source": {
    "file": "main.go",
    "line": 42
  }
}
```

**Performance note:** Source location adds overhead. Enable only for debugging.

## Custom Attribute Replacer

Transform or filter log attributes with a custom function.

### Redacting Custom Fields

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithReplaceAttr(func(groups []string, a slog.Attr) slog.Attr {
        // Redact credit card numbers
        if a.Key == "credit_card" {
            return slog.String(a.Key, "***REDACTED***")
        }
        // Transform time format
        if a.Key == "time" {
            if t, ok := a.Value.Any().(time.Time); ok {
                return slog.String(a.Key, t.Format(time.RFC3339))
            }
        }
        return a
    }),
)
```

### Built-in Redaction

The following fields are automatically redacted:
- `password`
- `token`
- `secret`
- `api_key`
- `authorization`

```go
log.Info("authentication", 
    "username", "john",
    "password", "secret123",  // Automatically redacted
)
// Output: {...,"username":"john","password":"***REDACTED***"}
```

### Dropping Attributes

Return an empty `slog.Attr` to drop an attribute:

```go
logging.WithReplaceAttr(func(groups []string, a slog.Attr) slog.Attr {
    if a.Key == "internal_field" {
        return slog.Attr{}  // Drop this field
    }
    return a
})
```

## Global Logger Registration

By default, loggers are not registered globally, allowing multiple independent logger instances.

### Register as Global Default

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithServiceName("my-api"),
    logging.WithGlobalLogger(),  // Register as slog default
)
defer logger.Shutdown(context.Background())

// Now third-party libraries using slog will use your logger
slog.Info("using global logger", "key", "value")
```

### When to Use Global Registration

**Use global registration when:**
- Third-party libraries use `slog` directly
- You prefer `slog.Info()` over `logger.Info()`
- Migrating from direct `slog` usage

**Don't use global registration when:**
- Running tests with isolated loggers
- Creating libraries (avoid affecting global state)
- Using multiple logging configurations

### Default Behavior

Without `WithGlobalLogger()`, each logger is independent:

```go
logger1 := logging.MustNew(logging.WithJSONHandler())
logger2 := logging.MustNew(logging.WithConsoleHandler())

logger1.Info("from logger1")  // JSON output
logger2.Info("from logger2")  // Console output
slog.Info("from default slog") // Standard slog output (independent)
```

## Custom Logger

Provide your own `slog.Logger` for advanced scenarios.

### Using Custom slog.Logger

```go
customLogger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
    AddSource: true,
}))

logger := logging.MustNew(
    logging.WithCustomLogger(customLogger),
)
```

**Limitations:**
- Dynamic level changes (`SetLevel`) not supported with custom loggers
- Service metadata must be added to custom logger directly

## Debug Mode

Enable comprehensive debugging with a single option.

### Enable Debug Mode

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithDebugMode(true),
)
```

**Automatically enables:**
- Debug log level (`WithDebugLevel()`)
- Source code location (`WithSource(true)`)

**Use cases:**
- Troubleshooting production issues
- Development environments
- Detailed debugging sessions

## Complete Configuration Example

Putting all options together:

```go
package main

import (
    "os"
    "rivaas.dev/logging"
    "log/slog"
)

func main() {
    // Production configuration
    prodLogger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithLevel(logging.LevelInfo),
        logging.WithServiceName("payment-api"),
        logging.WithServiceVersion("v2.1.0"),
        logging.WithEnvironment("production"),
        logging.WithOutput(os.Stdout),
    )
    defer prodLogger.Shutdown(context.Background())

    // Development configuration
    devLogger := logging.MustNew(
        logging.WithConsoleHandler(),
        logging.WithDebugLevel(),
        logging.WithSource(true),
        logging.WithServiceName("payment-api"),
        logging.WithEnvironment("development"),
    )
    defer devLogger.Shutdown(context.Background())

    // Choose based on environment
    var logger *logging.Logger
    if os.Getenv("ENV") == "production" {
        logger = prodLogger
    } else {
        logger = devLogger
    }

    logger.Info("application started")
}
```

## Configuration Best Practices

### Production Settings

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),           // Machine-parseable
    logging.WithLevel(logging.LevelInfo), // No debug spam
    logging.WithServiceName("my-api"),    // Service identification
    logging.WithServiceVersion(version),  // Version tracking
    logging.WithEnvironment("production"), // Environment filtering
)
```

### Development Settings

```go
logger := logging.MustNew(
    logging.WithConsoleHandler(),  // Human-readable
    logging.WithDebugLevel(),      // See everything
    logging.WithSource(true),      // File:line info
)
```

### Testing Settings

```go
buf := &bytes.Buffer{}
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithOutput(buf),
    logging.WithLevel(logging.LevelDebug),
)
// Inspect buf for assertions
```

## Next Steps

- Learn [Context Logging](../context-logging/) for trace correlation
- Explore [Log Sampling](../sampling/) to reduce volume
- See [Dynamic Log Levels](../dynamic-levels/) for runtime changes
- Review [Best Practices](../best-practices/) for production use

For complete option details, see the [Options Reference](/reference/packages/logging/options/).
