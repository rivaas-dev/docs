---
title: "Troubleshooting"
description: "Common issues and solutions for the logging package"
weight: 5
---

Common issues and solutions when using the logging package.

## Logs Not Appearing

### Debug Logs Not Showing

**Problem:** Debug logs don't appear in output.

**Cause:** Log level is set higher than Debug.

**Solution:** Enable debug level:

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithDebugLevel(),  // Enable debug logs
)
```

Or check current level:

```go
currentLevel := logger.Level()
fmt.Printf("Current level: %s\n", currentLevel)
```

### No Logs at All

**Problem:** No logs appear, even errors.

**Possible causes:**

1. **Logger shutdown:** Check if logger was shut down:
```go
if !logger.IsEnabled() {
    fmt.Println("Logger is shut down")
}
```

2. **Wrong output:** Verify output destination:
```go
logger := logging.MustNew(
    logging.WithOutput(os.Stdout),  // Not stderr
)
```

3. **Sampling too aggressive:** Check sampling configuration:
```go
info := logger.DebugInfo()
if sampling, ok := info["sampling"]; ok {
    fmt.Printf("Sampling: %+v\n", sampling)
}
```

### Logs Disappear After Some Time

**Problem:** Logs stop appearing after initial burst.

**Cause:** Log sampling is dropping logs.

**Solution:** Adjust sampling or disable:

```go
// Less aggressive sampling
logger := logging.MustNew(
    logging.WithSampling(logging.SamplingConfig{
        Initial:    1000,
        Thereafter: 10,  // 10% instead of 1%
        Tick:       time.Minute,
    }),
)

// Or disable sampling
logger := logging.MustNew(
    logging.WithJSONHandler(),
    // No WithSampling() call
)
```

## Sensitive Data Issues

### Sensitive Data Not Redacted

**Problem:** Custom sensitive fields not being redacted.

**Cause:** Only built-in fields are automatically redacted.

**Solution:** Add custom redaction:

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithReplaceAttr(func(groups []string, a slog.Attr) slog.Attr {
        // Redact custom fields
        if a.Key == "credit_card" || a.Key == "ssn" {
            return slog.String(a.Key, "***REDACTED***")
        }
        return a
    }),
)
```

**Built-in redacted fields:**
- `password`
- `token`
- `secret`
- `api_key`
- `authorization`

### Too Much Redaction

**Problem:** Fields being redacted unnecessarily.

**Cause:** Field names match redaction patterns.

**Solution:** Rename fields to avoid keywords:

```go
// Instead of "token" (redacted)
log.Info("processing", "request_token_id", tokenID)

// Instead of "secret" (redacted)
log.Info("config", "shared_secret_name", secretName)
```

## Trace Correlation Issues

### No Trace IDs in Logs

**Problem:** Logs don't include `trace_id` and `span_id`.

**Possible causes:**

1. **Tracing not initialized:**
```go
// Initialize tracing
tracer := tracing.MustNew(
    tracing.WithOTLP("localhost:4317"),
)
defer tracer.Shutdown(context.Background())
```

2. **Not using ContextLogger:**
```go
// Wrong - plain logger
logger.Info("message")

// Right - context logger
cl := logging.NewContextLogger(ctx, logger)
cl.Info("message")  // Includes trace_id and span_id
```

3. **Context has no active span:**
```go
// Start a span
ctx, span := tracer.Start(context.Background(), "operation")
defer span.End()

cl := logging.NewContextLogger(ctx, logger)
cl.Info("message")  // Now includes trace IDs
```

### Wrong Trace IDs

**Problem:** Trace IDs don't match distributed trace.

**Cause:** Context not properly propagated.

**Solution:** Ensure context flows through call chain:

```go
func handler(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()  // Get context with trace
    
    // Pass context down
    result := processRequest(ctx)
    
    w.Write(result)
}

func processRequest(ctx context.Context) []byte {
    // Use context
    cl := logging.NewContextLogger(ctx, logger)
    cl.Info("processing")
    
    return data
}
```

## Performance Issues

### High CPU Usage

**Problem:** Logging causes high CPU usage.

**Possible causes:**

1. **Logging in tight loops:**
```go
// Bad - logs thousands of times
for _, item := range items {
    logger.Debug("processing", "item", item)
}

// Good - log summary
logger.Info("processing batch", "count", len(items))
```

2. **Source location enabled in production:**
```go
// Bad for production
logger := logging.MustNew(
    logging.WithSource(true),  // Adds overhead
)

// Good for production
logger := logging.MustNew(
    logging.WithJSONHandler(),
    // No source location
)
```

3. **Debug level in production:**
```go
// Bad - debug logs have overhead even if filtered
logger := logging.MustNew(
    logging.WithDebugLevel(),
)

// Good - appropriate level
logger := logging.MustNew(
    logging.WithLevel(logging.LevelInfo),
)
```

### High Memory Usage

**Problem:** Memory usage grows over time.

**Possible causes:**

1. **No log rotation:** Logs written to file without rotation.

**Solution:** Use external log rotation (logrotate) or rotate in code:
```go
// Use external tool like logrotate
// Or implement rotation
```

2. **Buffered output not flushed:** Buffers growing without flush.

**Solution:** Ensure proper shutdown:
```go
defer func() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    logger.Shutdown(ctx)
}()
```

## Configuration Issues

### Cannot Change Log Level

**Problem:** `SetLevel` returns error.

**Cause:** Using custom logger.

**Error:**
```go
err := logger.SetLevel(logging.LevelDebug)
if errors.Is(err, logging.ErrCannotChangeLevel) {
    // Custom logger doesn't support dynamic level changes
}
```

**Solution:** Control level in custom logger:
```go
var levelVar slog.LevelVar
levelVar.Set(slog.LevelInfo)

customLogger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: &levelVar,
}))

// Change level directly
levelVar.Set(slog.LevelDebug)
```

### Service Metadata Not Appearing

**Problem:** Service name, version, or environment not in logs.

**Cause:** Not configured or using custom logger.

**Solution:** Configure service metadata:

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithServiceName("my-api"),
    logging.WithServiceVersion("v1.0.0"),
    logging.WithEnvironment("production"),
)
```

For custom logger, add metadata manually:
```go
customLogger := slog.New(handler).With(
    "service", "my-api",
    "version", "v1.0.0",
    "env", "production",
)
```

## Router Integration Issues

### Access Log Not Working

**Problem:** HTTP requests not being logged.

**Possible causes:**

1. **Logger not set on router:**
```go
r := router.MustNew()
logger := logging.MustNew(logging.WithJSONHandler())
r.SetLogger(logger)  // Must set logger
```

2. **Middleware not applied:**
```go
import "rivaas.dev/router/middleware/accesslog"

r.Use(accesslog.New())  // Apply middleware
```

3. **Path excluded:**
```go
r.Use(accesslog.New(
    accesslog.WithExcludePaths("/health", "/metrics"),
))
// /health and /metrics won't be logged
```

### Context Logger Not Working

**Problem:** Router context logger has no trace IDs.

**Cause:** Tracing not initialized or middleware not applied.

**Solution:** Initialize tracing:
```go
a, _ := app.New(
    app.WithServiceName("my-api"),
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
        app.WithTracing(tracing.WithOTLP("localhost:4317")),
    ),
)
```

## Testing Issues

### Test Logs Not Captured

**Problem:** Logs not appearing in test buffer.

**Cause:** Using wrong logger instance.

**Solution:** Use TestHelper or ensure buffer is captured:

```go
func TestMyFunction(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    myFunction(th.Logger)  // Pass test logger
    
    logs, _ := th.Logs()
    assert.Len(t, logs, 1)
}
```

### Parse Errors

**Problem:** `ParseJSONLogEntries` returns error.

**Cause:** Non-JSON output or malformed JSON.

**Solution:** Ensure JSON handler:

```go
th := logging.NewTestHelper(t,
    logging.WithJSONHandler(),  // Must be JSON
)
```

## Error Types

### ErrNilLogger

```go
var ErrNilLogger = errors.New("custom logger is nil")
```

**When:** Providing nil custom logger.

**Solution:**
```go
if customLogger != nil {
    logger := logging.MustNew(
        logging.WithCustomLogger(customLogger),
    )
}
```

### ErrInvalidHandler

```go
var ErrInvalidHandler = errors.New("invalid handler type")
```

**When:** Invalid handler type specified.

**Solution:** Use valid handler types:
```go
logging.WithHandlerType(logging.JSONHandler)
logging.WithHandlerType(logging.TextHandler)
logging.WithHandlerType(logging.ConsoleHandler)
```

### ErrLoggerShutdown

```go
var ErrLoggerShutdown = errors.New("logger is shut down")
```

**When:** Operations after shutdown.

**Solution:** Don't use logger after shutdown:
```go
defer logger.Shutdown(context.Background())
// Don't log after this point
```

### ErrInvalidLevel

```go
var ErrInvalidLevel = errors.New("invalid log level")
```

**When:** Invalid log level provided.

**Solution:** Use valid levels:
```go
logging.LevelDebug
logging.LevelInfo
logging.LevelWarn
logging.LevelError
```

### ErrCannotChangeLevel

```go
var ErrCannotChangeLevel = errors.New("cannot change level on custom logger")
```

**When:** Calling `SetLevel` on custom logger.

**Solution:** Control level in custom logger directly or don't use custom logger.

## Getting Help

If you encounter issues not covered here:

1. Check the [API Reference](../api-reference/) for method details
2. Review [Examples](/guides/logging/examples/) for patterns
3. See [Best Practices](/guides/logging/best-practices/) for recommendations
4. Check the [GitHub issues](https://github.com/rivaas-dev/rivaas/issues)

## Debugging Tips

### Enable Debug Info

```go
info := logger.DebugInfo()
fmt.Printf("Logger state: %+v\n", info)
```

### Check Sampling State

```go
info := logger.DebugInfo()
if sampling, ok := info["sampling"]; ok {
    fmt.Printf("Sampling config: %+v\n", sampling)
}
```

### Verify Configuration

```go
fmt.Printf("Service: %s\n", logger.ServiceName())
fmt.Printf("Version: %s\n", logger.ServiceVersion())
fmt.Printf("Environment: %s\n", logger.Environment())
fmt.Printf("Level: %s\n", logger.Level())
fmt.Printf("Enabled: %v\n", logger.IsEnabled())
```

## Next Steps

- Review [API Reference](../api-reference/) for complete method documentation
- Check [Options](../options/) for configuration details
- See [Best Practices](/guides/logging/best-practices/) for production guidance
