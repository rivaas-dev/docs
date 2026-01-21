---
title: "Logging Package"
linkTitle: "Logging"
description: "API reference for rivaas.dev/logging - Structured logging for Go applications"
weight: 3
sidebar_root_for: self
---

{{% pageinfo %}}
This is the API reference for the `rivaas.dev/logging` package. For learning-focused documentation, see the [Logging Guide](/guides/logging/).
{{% /pageinfo %}}

## Package Information

- **Import Path:** `rivaas.dev/logging`
- **Go Version:** 1.25+
- **Documentation:** [pkg.go.dev/rivaas.dev/logging](https://pkg.go.dev/rivaas.dev/logging)
- **Source Code:** [GitHub](https://github.com/rivaas-dev/rivaas/tree/main/logging)

## Package Overview

The logging package provides structured logging for Rivaas applications using Go's standard `log/slog` package, with additional features for production environments.

### Core Features

- Multiple output formats (JSON, Text, Console)
- Context-aware logging with OpenTelemetry trace correlation
- Automatic sensitive data redaction
- Log sampling for high-traffic scenarios
- Dynamic log level changes at runtime
- Convenience methods for common patterns
- Comprehensive testing utilities
- Zero external dependencies (except OpenTelemetry for tracing)

## Architecture

The package is organized around key components:

### Main Types

**Logger** - Main logging type with structured logging methods
```go
type Logger struct {
    // contains filtered or unexported fields
}
```

**ContextLogger** - Context-aware logger with automatic trace correlation
```go
type ContextLogger struct {
    // contains filtered or unexported fields
}
```

**Option** - Functional option for logger configuration
```go
type Option func(*Logger)
```

## Quick API Index

### Logger Creation

```go
logger, err := logging.New(options...)     // With error handling
logger := logging.MustNew(options...)      // Panics on error
```

### Logging Methods

```go
logger.Debug(msg string, args ...any)
logger.Info(msg string, args ...any)
logger.Warn(msg string, args ...any)
logger.Error(msg string, args ...any)
```

### Convenience Methods

```go
logger.LogRequest(r *http.Request, extra ...any)
logger.LogError(err error, msg string, extra ...any)
logger.LogDuration(msg string, start time.Time, extra ...any)
logger.ErrorWithStack(msg string, err error, includeStack bool, extra ...any)
```

### Context-Aware Logging

```go
cl := logging.NewContextLogger(ctx context.Context, logger *Logger)
cl.Info(msg string, args ...any)  // Includes trace_id and span_id
```

### Configuration Methods

```go
logger.SetLevel(level Level) error
logger.Level() Level
logger.Shutdown(ctx context.Context) error
```

## Reference Pages

{{% cardpane %}}
{{% card header="**API Reference**" %}}
Logger and ContextLogger types with all methods.

[View →](api-reference/)
{{% /card %}}
{{% card header="**Options**" %}}
Configuration options for handlers and output.

[View →](options/)
{{% /card %}}
{{% card header="**Testing Utilities**" %}}
Test helpers and mocking utilities.

[View →](testing-utilities/)
{{% /card %}}
{{% /cardpane %}}

{{% cardpane %}}
{{% card header="**Troubleshooting**" %}}
Common logging issues and solutions.

[View →](troubleshooting/)
{{% /card %}}
{{% card header="**User Guide**" %}}
Step-by-step tutorials and examples.

[View →](/guides/logging/)
{{% /card %}}
{{% /cardpane %}}

## Type Reference

### Logger

```go
type Logger struct {
    // contains filtered or unexported fields
}
```

Main logging type. Thread-safe for concurrent access.

**Creation:**
```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
)
```

**Key Methods:**
- `Debug`, `Info`, `Warn`, `Error` - Logging at different levels
- `LogRequest`, `LogError`, `LogDuration` - Convenience methods
- `SetLevel`, `Level` - Dynamic level management
- `Shutdown` - Graceful shutdown

### ContextLogger

```go
type ContextLogger struct {
    // contains filtered or unexported fields
}
```

Context-aware logger with automatic trace correlation.

**Creation:**
```go
cl := logging.NewContextLogger(ctx, logger)
```

**Key Methods:**
- `Debug`, `Info`, `Warn`, `Error` - Logging with trace correlation
- `TraceID`, `SpanID` - Access trace information
- `Logger` - Get underlying slog.Logger

### HandlerType

```go
type HandlerType string

const (
    JSONHandler    HandlerType = "json"
    TextHandler    HandlerType = "text"
    ConsoleHandler HandlerType = "console"
)
```

Output format type.

### Level

```go
type Level = slog.Level

const (
    LevelDebug = slog.LevelDebug  // -4
    LevelInfo  = slog.LevelInfo   // 0
    LevelWarn  = slog.LevelWarn   // 4
    LevelError = slog.LevelError  // 8
)
```

Log level constants.

### SamplingConfig

```go
type SamplingConfig struct {
    Initial    int           // Log first N entries unconditionally
    Thereafter int           // After Initial, log 1 of every M entries
    Tick       time.Duration // Reset sampling counter every interval
}
```

Configuration for log sampling.

## Error Types

The package defines sentinel errors for better error handling:

```go
var (
    ErrNilLogger         = errors.New("custom logger is nil")
    ErrInvalidHandler    = errors.New("invalid handler type")
    ErrLoggerShutdown    = errors.New("logger is shut down")
    ErrInvalidLevel      = errors.New("invalid log level")
    ErrCannotChangeLevel = errors.New("cannot change level on custom logger")
)
```

**Usage:**
```go
if err := logger.SetLevel(level); err != nil {
    if errors.Is(err, logging.ErrCannotChangeLevel) {
        // Handle immutable logger case
    }
}
```

## Common Patterns

### Basic Usage

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
)
defer logger.Shutdown(context.Background())

logger.Info("operation completed", "items", 100)
```

### With Service Metadata

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithServiceName("payment-api"),
    logging.WithServiceVersion("v2.1.0"),
    logging.WithEnvironment("production"),
)
```

### With Context and Tracing

```go
cl := logging.NewContextLogger(ctx, logger)
cl.Info("processing request", "user_id", userID)
// Automatically includes trace_id and span_id
```

### With Sampling

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithSampling(logging.SamplingConfig{
        Initial:    1000,
        Thereafter: 100,
        Tick:       time.Minute,
    }),
)
```

## Thread Safety

The `Logger` type is thread-safe for:
- Concurrent logging operations
- Concurrent `SetLevel` calls (serialized internally)
- Mixed logging and configuration operations

Not thread-safe for:
- Concurrent modification during initialization (use synchronization)

## Performance Notes

- **Logging overhead:** ~500ns per log entry
- **Level checks:** ~5ns per check
- **Sampling overhead:** ~20ns per log entry
- **Zero allocations:** Standard log calls with inline fields
- **Stack traces:** ~150µs capture cost (only when requested)

## Version Compatibility

The logging package follows semantic versioning. The API is stable for the v1 series.

**Minimum Go version:** 1.25

## Next Steps

- Read the [API Reference](api-reference/) for detailed method documentation
- Explore [Options](options/) for all configuration options
- Check [Testing Utilities](testing-utilities/) for test helpers
- Review [Troubleshooting](troubleshooting/) for common issues

For learning-focused guides, see the [Logging Guide](/guides/logging/).
