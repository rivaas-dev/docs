---
title: "API Reference"
description: "Complete API reference for all types and methods in the logging package"
keywords:
  - logging api
  - logging reference
  - api documentation
  - type reference
weight: 2
---

Complete API reference for all public types and methods in the logging package.

## Core Functions

### New

```go
func New(opts ...Option) (*Logger, error)
```

Creates a new Logger with the given options. Returns an error if configuration is invalid.

**Parameters:**
- `opts` - Variadic list of configuration options.

**Returns:**
- `*Logger` - Configured logger instance.
- `error` - Configuration error, if any.

**Example:**
```go
logger, err := logging.New(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
)
if err != nil {
    log.Fatalf("failed to create logger: %v", err)
}
```

### MustNew

```go
func MustNew(opts ...Option) *Logger
```

Creates a new Logger or panics on error. Use for initialization where errors are fatal.

**Parameters:**
- `opts` - Variadic list of configuration options

**Returns:**
- `*Logger` - Configured logger instance

**Panics:**
- If configuration is invalid

**Example:**
```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
)
```

## Automatic Trace Correlation

When you create a logger with this package (and optionally set it as the global logger with `WithGlobalLogger()`), trace correlation is automatic. You do not need a special logger type.

Any call to the standard library's context-aware methods — `slog.InfoContext(ctx, ...)`, `slog.ErrorContext(ctx, ...)`, and so on — will automatically get `trace_id` and `span_id` added to the log record if the context contains an active OpenTelemetry span. The logging package wraps the handler with a context-aware layer that reads the span from the context and injects these fields.

**Example (in an HTTP handler):**

```go
// Pass the request context when you log
slog.InfoContext(c.RequestContext(), "processing request", "order_id", orderID)
// Output includes trace_id and span_id when tracing is enabled
```

Use the same pattern with `slog.DebugContext`, `slog.WarnContext`, and `slog.ErrorContext`. No wrapper type or extra API is required.

## Logger Type

### Logging Methods

#### Debug

```go
func (l *Logger) Debug(msg string, args ...any)
```

Logs a debug message with structured attributes.

**Parameters:**
- `msg` - Log message
- `args` - Key-value pairs (must be even number of arguments)

**Example:**
```go
logger.Debug("cache lookup", "key", cacheKey, "hit", true)
```

#### Info

```go
func (l *Logger) Info(msg string, args ...any)
```

Logs an informational message with structured attributes.

**Parameters:**
- `msg` - Log message
- `args` - Key-value pairs

**Example:**
```go
logger.Info("server started", "port", 8080, "version", "v1.0.0")
```

#### Warn

```go
func (l *Logger) Warn(msg string, args ...any)
```

Logs a warning message with structured attributes.

**Parameters:**
- `msg` - Log message
- `args` - Key-value pairs

**Example:**
```go
logger.Warn("high memory usage", "used_mb", 8192, "threshold_mb", 10240)
```

#### Error

```go
func (l *Logger) Error(msg string, args ...any)
```

Logs an error message with structured attributes. Errors bypass log sampling.

**Parameters:**
- `msg` - Log message
- `args` - Key-value pairs

**Example:**
```go
logger.Error("database connection failed", "error", err, "retry_count", 3)
```

### Convenience Methods

#### LogRequest

```go
func (l *Logger) LogRequest(r *http.Request, extra ...any)
```

Logs an HTTP request with standard fields (method, path, remote, user_agent, query).

**Parameters:**
- `r` - HTTP request
- `extra` - Additional key-value pairs

**Example:**
```go
logger.LogRequest(r, "status", 200, "duration_ms", 45)
```

#### LogError

```go
func (l *Logger) LogError(err error, msg string, extra ...any)
```

Logs an error with automatic error field.

**Parameters:**
- `err` - Error to log
- `msg` - Log message
- `extra` - Additional key-value pairs

**Example:**
```go
logger.LogError(err, "operation failed", "operation", "INSERT", "table", "users")
```

#### LogDuration

```go
func (l *Logger) LogDuration(msg string, start time.Time, extra ...any)
```

Logs operation duration with automatic duration_ms and duration fields.

**Parameters:**
- `msg` - Log message
- `start` - Operation start time
- `extra` - Additional key-value pairs

**Example:**
```go
start := time.Now()
// ... operation ...
logger.LogDuration("processing completed", start, "items", 100)
```

#### ErrorWithStack

```go
func (l *Logger) ErrorWithStack(msg string, err error, includeStack bool, extra ...any)
```

Logs an error with optional stack trace.

**Parameters:**
- `msg` - Log message
- `err` - Error to log
- `includeStack` - Whether to capture and include stack trace
- `extra` - Additional key-value pairs

**Example:**
```go
logger.ErrorWithStack("critical failure", err, true, "user_id", userID)
```

### Context Methods

#### Logger

```go
func (l *Logger) Logger() *slog.Logger
```

Returns the underlying slog.Logger for advanced usage.

**Returns:**
- `*slog.Logger` - Underlying logger

**Example:**
```go
slogger := logger.Logger()
```

#### With

```go
func (l *Logger) With(args ...any) *slog.Logger
```

Returns a slog.Logger with additional attributes that persist across log calls.

**Parameters:**
- `args` - Key-value pairs to add as persistent attributes

**Returns:**
- `*slog.Logger` - Logger with added attributes

**Example:**
```go
requestLogger := logger.With("request_id", "req-123", "user_id", "user-456")
requestLogger.Info("processing")  // Includes request_id and user_id
```

#### WithGroup

```go
func (l *Logger) WithGroup(name string) *slog.Logger
```

Returns a slog.Logger with a group name for nested attributes.

**Parameters:**
- `name` - Group name

**Returns:**
- `*slog.Logger` - Logger with group

**Example:**
```go
dbLogger := logger.WithGroup("database")
dbLogger.Info("query", "sql", "SELECT * FROM users")
// Output: {...,"database":{"sql":"SELECT * FROM users"}}
```

### Configuration Methods

#### SetLevel

```go
func (l *Logger) SetLevel(level Level) error
```

Dynamically changes the minimum log level at runtime.

**Parameters:**
- `level` - New log level

**Returns:**
- `error` - `ErrCannotChangeLevel` if using custom logger

**Example:**
```go
if err := logger.SetLevel(logging.LevelDebug); err != nil {
    log.Printf("failed to change level: %v", err)
}
```

#### Level

```go
func (l *Logger) Level() Level
```

Returns the current minimum log level.

**Returns:**
- `Level` - Current log level

**Example:**
```go
currentLevel := logger.Level()
fmt.Printf("Current level: %s\n", currentLevel)
```

### Metadata Methods

#### ServiceName

```go
func (l *Logger) ServiceName() string
```

Returns the configured service name.

**Returns:**
- `string` - Service name, or empty if not configured

#### ServiceVersion

```go
func (l *Logger) ServiceVersion() string
```

Returns the configured service version.

**Returns:**
- `string` - Service version, or empty if not configured

#### Environment

```go
func (l *Logger) Environment() string
```

Returns the configured environment.

**Returns:**
- `string` - Environment, or empty if not configured

### Lifecycle Methods

#### IsEnabled

```go
func (l *Logger) IsEnabled() bool
```

Returns true if logging is enabled (not shut down).

**Returns:**
- `bool` - Whether logger is active

#### DebugInfo

```go
func (l *Logger) DebugInfo() map[string]any
```

Returns diagnostic information about logger state.

**Returns:**
- `map[string]any` - Diagnostic information

**Example:**
```go
info := logger.DebugInfo()
fmt.Printf("Handler: %s\n", info["handler_type"])
fmt.Printf("Level: %s\n", info["level"])
```

#### Shutdown

```go
func (l *Logger) Shutdown(ctx context.Context) error
```

Gracefully shuts down the logger, flushing any buffered logs.

**Parameters:**
- `ctx` - Context for timeout control

**Returns:**
- `error` - Shutdown error, if any

**Example:**
```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

if err := logger.Shutdown(ctx); err != nil {
    fmt.Fprintf(os.Stderr, "shutdown error: %v\n", err)
}
```

## Next Steps

- See [Options](../options/) for all configuration options
- Check [Testing Utilities](../testing-utilities/) for test helpers
- Review [Troubleshooting](../troubleshooting/) for common issues

For usage guides, see the [Logging Guide](/guides/logging/).
