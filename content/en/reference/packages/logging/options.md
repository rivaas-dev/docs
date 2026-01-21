---
title: "Options Reference"
description: "Complete reference for all logger configuration options"
keywords:
  - logging options
  - configuration
  - options reference
  - functional options
weight: 3
---

Complete reference for all configuration options available in the logging package.

## Handler Options

Configure the output format for logs.

### WithHandlerType

```go
func WithHandlerType(t HandlerType) Option
```

Sets the logging handler type directly.

**Parameters:**
- `t` - Handler type. Use JSONHandler, TextHandler, or ConsoleHandler.

**Example:**
```go
logging.WithHandlerType(logging.JSONHandler)
```

### WithJSONHandler

```go
func WithJSONHandler() Option
```

Uses JSON structured logging. This is the default. Best for production and log aggregation.

**Example:**
```go
logger := logging.MustNew(logging.WithJSONHandler())
```

**Output format:**
```json
{"time":"2024-01-15T10:30:45.123Z","level":"INFO","msg":"test","key":"value"}
```

### WithTextHandler

```go
func WithTextHandler() Option
```

Uses text key=value logging. Good for systems that prefer this format.

**Example:**
```go
logger := logging.MustNew(logging.WithTextHandler())
```

**Output format:**
```
time=2024-01-15T10:30:45.123Z level=INFO msg=test key=value
```

### WithConsoleHandler

```go
func WithConsoleHandler() Option
```

Uses human-readable console logging with colors. Best for development.

**Example:**
```go
logger := logging.MustNew(logging.WithConsoleHandler())
```

**Output format:**
```
10:30:45.123 INFO  test key=value
```

## Level Options

Configure the minimum log level.

### WithLevel

```go
func WithLevel(level Level) Option
```

Sets the minimum log level.

**Parameters:**
- `level` - Minimum level (LevelDebug, LevelInfo, LevelWarn, LevelError)

**Example:**
```go
logger := logging.MustNew(
    logging.WithLevel(logging.LevelInfo),
)
```

### WithDebugLevel

```go
func WithDebugLevel() Option
```

Convenience function to enable debug logging. Equivalent to `WithLevel(LevelDebug)`.

**Example:**
```go
logger := logging.MustNew(logging.WithDebugLevel())
```

## Output Options

Configure where logs are written.

### WithOutput

```go
func WithOutput(w io.Writer) Option
```

Sets the output destination for logs.

**Parameters:**
- `w` - io.Writer to write logs to

**Default:** `os.Stdout`

**Example:**
```go
logFile, _ := os.OpenFile("app.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
logger := logging.MustNew(
    logging.WithOutput(logFile),
)
```

**Multiple outputs:**
```go
logger := logging.MustNew(
    logging.WithOutput(io.MultiWriter(os.Stdout, logFile)),
)
```

## Service Metadata Options

Configure service identification fields automatically added to every log entry.

### WithServiceName

```go
func WithServiceName(name string) Option
```

Sets the service name, automatically added to all log entries as `service` field.

**Parameters:**
- `name` - Service name

**Example:**
```go
logger := logging.MustNew(
    logging.WithServiceName("payment-api"),
)
```

### WithServiceVersion

```go
func WithServiceVersion(version string) Option
```

Sets the service version, automatically added to all log entries as `version` field.

**Parameters:**
- `version` - Service version

**Example:**
```go
logger := logging.MustNew(
    logging.WithServiceVersion("v2.1.0"),
)
```

### WithEnvironment

```go
func WithEnvironment(env string) Option
```

Sets the environment, automatically added to all log entries as `env` field.

**Parameters:**
- `env` - Environment name

**Example:**
```go
logger := logging.MustNew(
    logging.WithEnvironment("production"),
)
```

**Combined example:**
```go
logger := logging.MustNew(
    logging.WithServiceName("payment-api"),
    logging.WithServiceVersion("v2.1.0"),
    logging.WithEnvironment("production"),
)
// All logs include: "service":"payment-api","version":"v2.1.0","env":"production"
```

## Feature Options

Enable additional logging features.

### WithSource

```go
func WithSource(enabled bool) Option
```

Enables source code location (file and line number) in logs.

**Parameters:**
- `enabled` - Whether to include source location

**Default:** `false`

**Example:**
```go
logger := logging.MustNew(
    logging.WithSource(true),
)
// Output includes: "source":{"file":"main.go","line":42}
```

**Note:** Source location adds overhead. Use only for debugging.

### WithDebugMode

```go
func WithDebugMode(enabled bool) Option
```

Enables verbose debugging mode. Automatically enables debug level and source location.

**Parameters:**
- `enabled` - Whether to enable debug mode

**Example:**
```go
logger := logging.MustNew(
    logging.WithDebugMode(true),
)
// Equivalent to:
// WithDebugLevel() + WithSource(true)
```

### WithGlobalLogger

```go
func WithGlobalLogger() Option
```

Registers this logger as the global slog default logger. Allows third-party libraries using `slog` to use your configured logger.

**Example:**
```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithGlobalLogger(),
)
// Now slog.Info() uses this logger
```

**Default:** Not registered globally (allows multiple independent loggers)

### WithSampling

```go
func WithSampling(cfg SamplingConfig) Option
```

Enables log sampling to reduce volume in high-traffic scenarios.

**Parameters:**
- `cfg` - Sampling configuration

**Example:**
```go
logger := logging.MustNew(
    logging.WithSampling(logging.SamplingConfig{
        Initial:    1000,         // First 1000 logs
        Thereafter: 100,          // Then 1% sampling
        Tick:       time.Minute,  // Reset every minute
    }),
)
```

**SamplingConfig fields:**
- `Initial` (int) - Log first N entries unconditionally
- `Thereafter` (int) - After Initial, log 1 of every M entries (0 = log all)
- `Tick` (time.Duration) - Reset counter every interval (0 = never reset)

**Note:** Errors (level >= ERROR) always bypass sampling.

## Advanced Options

Advanced configuration for specialized use cases.

### WithReplaceAttr

```go
func WithReplaceAttr(fn func(groups []string, a slog.Attr) slog.Attr) Option
```

Sets a custom attribute replacer function for transforming or filtering log attributes.

**Parameters:**
- `fn` - Function to transform attributes

**Example - Custom redaction:**
```go
logger := logging.MustNew(
    logging.WithReplaceAttr(func(groups []string, a slog.Attr) slog.Attr {
        if a.Key == "credit_card" {
            return slog.String(a.Key, "***REDACTED***")
        }
        return a
    }),
)
```

**Example - Dropping attributes:**
```go
logger := logging.MustNew(
    logging.WithReplaceAttr(func(groups []string, a slog.Attr) slog.Attr {
        if a.Key == "internal_field" {
            return slog.Attr{}  // Drop this field
        }
        return a
    }),
)
```

**Example - Transforming values:**
```go
logger := logging.MustNew(
    logging.WithReplaceAttr(func(groups []string, a slog.Attr) slog.Attr {
        if a.Key == "time" {
            if t, ok := a.Value.Any().(time.Time); ok {
                return slog.String(a.Key, t.Format(time.RFC3339))
            }
        }
        return a
    }),
)
```

### WithCustomLogger

```go
func WithCustomLogger(customLogger *slog.Logger) Option
```

Uses a custom slog.Logger instead of creating one. For advanced use cases where you need full control over the logger.

**Parameters:**
- `customLogger` - Pre-configured slog.Logger

**Example:**
```go
customLogger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level:     slog.LevelDebug,
    AddSource: true,
}))

logger := logging.MustNew(
    logging.WithCustomLogger(customLogger),
)
```

**Limitations:**
- Dynamic level changes (`SetLevel`) not supported
- Service metadata must be added to custom logger directly

## Configuration Examples

### Development Configuration

```go
logger := logging.MustNew(
    logging.WithConsoleHandler(),
    logging.WithDebugLevel(),
    logging.WithSource(true),
)
```

### Production Configuration

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
    logging.WithServiceName(os.Getenv("SERVICE_NAME")),
    logging.WithServiceVersion(os.Getenv("VERSION")),
    logging.WithEnvironment("production"),
    logging.WithSampling(logging.SamplingConfig{
        Initial:    1000,
        Thereafter: 100,
        Tick:       time.Minute,
    }),
)
```

### Testing Configuration

```go
buf := &bytes.Buffer{}
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithOutput(buf),
    logging.WithLevel(logging.LevelDebug),
)
```

### File Logging Configuration

```go
logFile, _ := os.OpenFile("app.log",
    os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)

logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithOutput(logFile),
    logging.WithServiceName("myapp"),
)
```

### Multiple Output Configuration

```go
logFile, _ := os.OpenFile("app.log",
    os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)

logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithOutput(io.MultiWriter(os.Stdout, logFile)),
)
```

## Next Steps

- See [API Reference](../api-reference/) for all methods
- Check [Testing Utilities](../testing-utilities/) for test helpers
- Review [Troubleshooting](../troubleshooting/) for common issues

For usage guides, see the [Configuration Guide](/guides/logging/configuration/).
