---
title: "Best Practices"
description: "Production-ready logging patterns, performance tips, and recommended practices"
weight: 11
---

This guide covers best practices for using the logging package in production environments.

## Structured Logging

Always use structured fields instead of string concatenation.

### Use Structured Fields

**BAD - String concatenation:**
```go
log.Info("User " + userID + " logged in from " + ipAddress)
```

**GOOD - Structured fields:**
```go
log.Info("user logged in",
    "user_id", userID,
    "ip_address", ipAddress,
    "session_id", sessionID,
)
```

**Benefits:**
- Machine-parseable
- Searchable by specific fields
- Type-safe (numbers stay numbers)
- Easier to aggregate and visualize
- Better for log aggregation tools

### Consistent Field Naming

Use consistent field names across your application:

```go
// Good - consistent naming
log.Info("request started", "user_id", userID)
log.Info("database query", "user_id", userID)
log.Info("response sent", "user_id", userID)

// Bad - inconsistent naming
log.Info("request started", "user_id", userID)
log.Info("database query", "userId", userID)      // Different name
log.Info("response sent", "user", userID)         // Different name
```

**Recommended conventions:**
- Use snake_case: `user_id`, `request_id`, `duration_ms`
- Be specific: `http_status` not `status`, `db_host` not `host`
- Use consistent units: `duration_ms`, `size_bytes`, `count`

## Log Appropriate Levels

Choose the right log level for each message.

### Level Guidelines

**DEBUG** - Detailed information for debugging
```go
log.Debug("cache lookup",
    "key", cacheKey,
    "ttl", ttl,
    "hit", hit,
)
```

Use DEBUG for:
- Internal state inspection
- Flow control details
- Cache hits/misses
- Detailed algorithm steps

**INFO** - General informational messages
```go
log.Info("server started",
    "port", 8080,
    "version", version,
)
```

Use INFO for:
- Application lifecycle events (start, stop)
- Significant business events
- Successful operations
- Configuration values

**WARN** - Warning but not an error
```go
log.Warn("high memory usage",
    "used_mb", 8192,
    "total_mb", 16384,
    "percentage", 50,
)
```

Use WARN for:
- Degraded performance
- Using fallback behavior
- Deprecated feature usage
- Resource constraints

**ERROR** - Errors that need attention
```go
log.Error("database connection failed",
    "error", err,
    "host", dbHost,
    "retry_count", retries,
)
```

Use ERROR for:
- Operation failures
- Exception conditions
- Data integrity issues
- External service failures

## Include Context

Always include relevant context with log messages.

### Minimal Context
```go
// Bad - no context
log.Error("failed to save", "error", err)
```

### Better - Includes Context
```go
// Good - includes relevant context
log.Error("failed to save user data",
    "error", err,
    "user_id", user.ID,
    "operation", "update_profile",
    "retry_count", retries,
    "elapsed_ms", elapsed.Milliseconds(),
)
```

**Context checklist:**
- What operation failed?
- Which entity was involved?
- What were the inputs?
- How many times did we retry?
- How long did it take?

## Performance Considerations

Follow these guidelines for high-performance logging.

### Avoid Logging in Tight Loops

**BAD - logs thousands of times:**
```go
for _, item := range items {
    log.Debug("processing item", "item", item)
    process(item)
}
```

**GOOD - log once with summary:**
```go
log.Info("processing batch started", "count", len(items))

for _, item := range items {
    process(item)
}

log.Info("processing batch completed",
    "count", len(items),
    "duration_ms", elapsed.Milliseconds(),
)
```

### Use Appropriate Log Levels in Production

```go
// Production configuration
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),  // Skip debug logs
)
```

**Impact:**
- DEBUG logs have overhead even if not written
- Level checks are fast but not free
- Set INFO or WARN in production

### Defer Expensive Operations

Only compute expensive values if the log will be written:

```go
// Bad - always computes
log.Debug("state", "expensive", expensiveComputation())

// Good - only compute if debug enabled
if log.Logger().Enabled(context.Background(), logging.LevelDebug) {
    log.Debug("state", "expensive", expensiveComputation())
}
```

### Use Log Sampling

For high-volume services:

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithSampling(logging.SamplingConfig{
        Initial:    1000,
        Thereafter: 100,  // 1% sampling
        Tick:       time.Minute,
    }),
)
```

See [Log Sampling](../sampling/) for details.

## Don't Log Sensitive Data

Protect user privacy and security.

### Automatically Redacted Fields

These fields are automatically redacted:
- `password`
- `token`
- `secret`
- `api_key`
- `authorization`

```go
log.Info("authentication attempt",
    "username", "alice",
    "password", "secret123",  // Automatically redacted
)
// Output: {...,"password":"***REDACTED***"}
```

### Custom Sensitive Fields

Add custom redaction:

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithReplaceAttr(func(groups []string, a slog.Attr) slog.Attr {
        // Redact credit cards
        if a.Key == "credit_card" {
            return slog.String(a.Key, "***REDACTED***")
        }
        // Redact email addresses
        if a.Key == "email" {
            return slog.String(a.Key, maskEmail(a.Value.String()))
        }
        return a
    }),
)
```

### What Not to Log

Never log:
- Passwords or password hashes
- Credit card numbers
- Social Security numbers
- API keys and tokens
- Private keys
- Session tokens
- Personal health information (PHI)
- Personally identifiable information (PII) without consent

## Production Configuration

Recommended production setup.

### Production Logger

```go
func NewProductionLogger() *logging.Logger {
    return logging.MustNew(
        logging.WithJSONHandler(),              // Machine-parseable
        logging.WithLevel(logging.LevelInfo),   // No debug spam
        logging.WithServiceName(os.Getenv("SERVICE_NAME")),
        logging.WithServiceVersion(os.Getenv("VERSION")),
        logging.WithEnvironment("production"),
        logging.WithOutput(os.Stdout),          // Stdout for container logs
    )
}
```

### Development Logger

```go
func NewDevelopmentLogger() *logging.Logger {
    return logging.MustNew(
        logging.WithConsoleHandler(),  // Human-readable
        logging.WithDebugLevel(),      // See everything
        logging.WithSource(true),      // File:line info
    )
}
```

### Environment-Based Configuration

```go
func NewLogger() *logging.Logger {
    if os.Getenv("ENV") == "production" {
        return NewProductionLogger()
    }
    return NewDevelopmentLogger()
}
```

## Error Handling Patterns

Best practices for logging errors.

### Always Include Error Details

```go
if err := db.Connect(); err != nil {
    log.Error("database connection failed",
        "error", err,
        "host", dbHost,
        "port", dbPort,
        "database", dbName,
        "retry_count", retries,
    )
    return err
}
```

### Use LogError for Consistency

```go
if err := operation(); err != nil {
    logger.LogError(err, "operation failed",
        "operation", "process_payment",
        "user_id", userID,
    )
    return err
}
```

### Stack Traces for Critical Errors Only

```go
// Normal error - no stack trace
if err := validation(); err != nil {
    logger.LogError(err, "validation failed", "field", field)
    return err
}

// Critical error - with stack trace
if err := criticalOperation(); err != nil {
    logger.ErrorWithStack("critical failure", err, true,
        "operation", "process_payment",
        "amount", amount,
    )
    return err
}
```

## Request Logging

Best practices for HTTP request logging.

### Use Access Log Middleware

```go
import "rivaas.dev/router/middleware/accesslog"

r := router.MustNew()
r.SetLogger(logger)
r.Use(accesslog.New(
    accesslog.WithExcludePaths("/health", "/metrics"),
))
```

**Don't** manually log every request:
```go
// Bad - redundant with access log
r.GET("/api/users", func(c *router.Context) {
    c.Logger().Info("request received")  // Don't do this
    // ... handle request
    c.Logger().Info("request completed") // Don't do this
})
```

### Per-Request Context

Add request-specific fields:

```go
r.Use(func(c *router.Context) {
    reqLogger := c.Logger().With(
        "request_id", c.GetHeader("X-Request-ID"),
        "user_id", extractUserID(c),
    )
    ctx := context.WithValue(c.Request.Context(), "logger", reqLogger)
        c.Request = c.Request.WithContext(ctx)
    c.Next()
})
```

## Graceful Shutdown

Always shut down loggers gracefully.

### With Context Timeout

```go
func main() {
    logger := logging.MustNew(logging.WithJSONHandler())
    defer func() {
        ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        
        if err := logger.Shutdown(ctx); err != nil {
            fmt.Fprintf(os.Stderr, "logger shutdown error: %v\n", err)
        }
    }()
    
    // Application logic...
}
```

### With Signal Handling

```go
func main() {
    logger := logging.MustNew(logging.WithJSONHandler())
    
    // Setup signal handling
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
    
    go func() {
        <-sigChan
        logger.Info("shutting down...")
        
        ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        logger.Shutdown(ctx)
        
        os.Exit(0)
    }()
    
    // Application logic...
}
```

## Testing Considerations

Make logging testable.

### Inject Loggers

```go
// Good - logger injected
type Service struct {
    logger *logging.Logger
}

func NewService(logger *logging.Logger) *Service {
    return &Service{logger: logger}
}

// In tests
func TestService(t *testing.T) {
    th := logging.NewTestHelper(t)
    svc := NewService(th.Logger)
    // Test and verify logs
}
```

**Don't** use global loggers:
```go
// Bad - global logger
var log = logging.MustNew(logging.WithJSONHandler())

type Service struct{}

func (s *Service) DoSomething() {
    log.Info("doing something")  // Can't test
}
```

## Common Anti-Patterns

Avoid these common mistakes.

### String Formatting in Log Calls

```go
// Bad - string formatting
log.Info(fmt.Sprintf("User %s did %s", user, action))

// Good - structured fields
log.Info("user action", "user", user, "action", action)
```

### Logging in Library Code

```go
// Bad - library logging directly
func LibraryFunction() {
    log.Info("library function called")
}

// Good - library returns errors
func LibraryFunction() error {
    if err := something(); err != nil {
        return fmt.Errorf("library operation failed: %w", err)
    }
    return nil
}

// Caller logs
if err := LibraryFunction(); err != nil {
    log.Error("library call failed", "error", err)
}
```

### Ignoring Shutdown Errors

```go
// Bad - ignoring shutdown
defer logger.Shutdown(context.Background())

// Good - handling shutdown errors
defer func() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    if err := logger.Shutdown(ctx); err != nil {
        fmt.Fprintf(os.Stderr, "shutdown error: %v\n", err)
    }
}()
```

## Monitoring and Alerting

Set up log-based monitoring.

### Log Metrics

Track log volumes by level:

```go
var logMetrics = struct {
    debugCount, infoCount, warnCount, errorCount atomic.Int64
}{}

// Periodically export metrics
go func() {
    ticker := time.NewTicker(time.Minute)
    for range ticker.C {
        metricsLogger.Info("log metrics",
            "debug_count", logMetrics.debugCount.Swap(0),
            "info_count", logMetrics.infoCount.Swap(0),
            "warn_count", logMetrics.warnCount.Swap(0),
            "error_count", logMetrics.errorCount.Swap(0),
        )
    }
}()
```

### Alert on Error Rates

Configure alerts in your logging system:
- Alert if ERROR count > 100/minute
- Alert if ERROR rate increases >50% baseline
- Alert on specific error patterns

## Next Steps

- Review [Migration](../migration/) for switching from other loggers
- See [Examples](../examples/) for complete patterns
- Explore [Testing](../testing/) for test utilities

For complete API details, see the [API Reference](/reference/packages/logging/api-reference/).
