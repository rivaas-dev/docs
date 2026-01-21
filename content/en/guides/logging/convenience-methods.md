---
title: "Convenience Methods"
description: "Use helper methods for common logging patterns like HTTP requests and errors"
weight: 6
keywords:
  - logging convenience
  - helper methods
  - logging patterns
---

This guide covers convenience methods that simplify common logging patterns with pre-structured fields.

## Overview

The logging package provides helper methods for frequently-used logging scenarios:

- **LogRequest** - HTTP request logging with standard fields
- **LogError** - Error logging with context
- **LogDuration** - Operation timing with automatic duration calculation
- **ErrorWithStack** - Critical error logging with stack traces

## LogRequest - HTTP Request Logging

Automatically log HTTP requests with standard fields.

### Basic Usage

```go
func handleRequest(w http.ResponseWriter, r *http.Request) {
    start := time.Now()
    
    // Process request...
    status := 200
    bytesWritten := 1024
    
    logger.LogRequest(r, 
        "status", status,
        "duration_ms", time.Since(start).Milliseconds(),
        "bytes", bytesWritten,
    )
}
```

**Output:**
```json
{
  "level": "INFO",
  "msg": "http request",
  "method": "GET",
  "path": "/api/users",
  "remote": "192.168.1.1:54321",
  "user_agent": "Mozilla/5.0...",
  "status": 200,
  "duration_ms": 45,
  "bytes": 1024
}
```

### Standard Fields Included

`LogRequest` automatically includes:

| Field | Description | Example |
|-------|-------------|---------|
| `method` | HTTP method | `GET`, `POST`, `PUT` |
| `path` | Request path (without query) | `/api/users` |
| `remote` | Client remote address | `192.168.1.1:54321` |
| `user_agent` | Client User-Agent header | `Mozilla/5.0...` |
| `query` | Query string (only if non-empty) | `page=1&limit=10` |

### Additional Fields

Pass additional fields as key-value pairs:

```go
logger.LogRequest(r,
    "status", statusCode,
    "duration_ms", elapsed,
    "bytes_written", bytesWritten,
    "user_id", userID,
    "cached", wasCached,
)
```

### With Router Middleware

`LogRequest` is particularly useful in custom middleware:

```go
func loggingMiddleware(logger *logging.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            
            // Wrap response writer to capture status/size
            wrapped := &responseWriter{ResponseWriter: w}
            
            next.ServeHTTP(wrapped, r)
            
            logger.LogRequest(r,
                "status", wrapped.status,
                "duration_ms", time.Since(start).Milliseconds(),
                "bytes", wrapped.written,
            )
        })
    }
}
```

**Note:** The Rivaas router includes built-in access log middleware. See [Router Integration](../router-integration/).

## LogError - Error Logging with Context

Convenient error logging with automatic error field.

### Basic Usage

```go
if err := db.Insert(user); err != nil {
    logger.LogError(err, "database operation failed",
        "operation", "INSERT",
        "table", "users",
        "user_id", user.ID,
    )
    return err
}
```

**Output:**
```json
{
  "level": "ERROR",
  "msg": "database operation failed",
  "error": "connection timeout: unable to reach database",
  "operation": "INSERT",
  "table": "users",
  "user_id": "123"
}
```

### Why Use LogError?

**Instead of:**
```go
log.Error("database operation failed", "error", err.Error(), "table", "users")
```

**Use:**
```go
logger.LogError(err, "database operation failed", "table", "users")
```

**Benefits:**
- Shorter, cleaner code
- Consistent error field naming
- Automatic error message extraction
- Clear intent (logging an error condition)

### With Retry Logic

```go
func connectWithRetry(maxRetries int) error {
    for i := 0; i < maxRetries; i++ {
        if err := connect(); err != nil {
            logger.LogError(err, "connection failed",
                "attempt", i+1,
                "max_retries", maxRetries,
            )
            time.Sleep(backoff(i))
            continue
        }
        return nil
    }
    return errors.New("max retries exceeded")
}
```

## LogDuration - Operation Timing

Track operation duration automatically.

### Basic Usage

```go
start := time.Now()

result, err := processData(data)

logger.LogDuration("data processing completed", start,
    "rows_processed", result.Count,
    "errors", result.Errors,
)
```

**Output:**
```json
{
  "level": "INFO",
  "msg": "data processing completed",
  "duration_ms": 1543,
  "duration": "1.543s",
  "rows_processed": 1000,
  "errors": 0
}
```

### Included Fields

`LogDuration` automatically adds:

| Field | Description | Example |
|-------|-------------|---------|
| `duration_ms` | Duration in milliseconds (for filtering/alerting) | `1543` |
| `duration` | Human-readable duration string | `"1.543s"` |

### Why Two Duration Fields?

- **`duration_ms`** - Numeric value for:
  - Filtering: `duration_ms > 1000`
  - Alerting: Alert on slow operations
  - Aggregation: Average, percentiles, etc.

- **`duration`** - Human-readable for:
  - Quick visual inspection
  - Log reading and debugging
  - Formats like `"250ms"`, `"1.5s"`, `"2m30s"`

### Multiple Checkpoints

Track multiple stages:

```go
start := time.Now()

// Stage 1
dataFetched := time.Now()
logger.LogDuration("data fetched", start, "rows", rowCount)

// Stage 2
processData(data)
logger.LogDuration("data processed", dataFetched, "rows", rowCount)

// Overall
logger.LogDuration("operation completed", start, "total_rows", rowCount)
```

### With Error Handling

```go
start := time.Now()
result, err := expensiveOperation()

if err != nil {
    logger.LogError(err, "operation failed")
    logger.LogDuration("operation failed", start, "partial_results", result.Count)
    return err
}

logger.LogDuration("operation succeeded", start, "results", result.Count)
```

## ErrorWithStack - Error with Stack Traces

Log critical errors with stack traces for debugging.

### Basic Usage

```go
if err := criticalOperation(); err != nil {
    logger.ErrorWithStack("critical failure", err, true,
        "user_id", userID,
        "transaction_id", txID,
    )
    // Handle critical error...
}
```

**Output:**
```json
{
  "level": "ERROR",
  "msg": "critical failure",
  "error": "database corruption detected",
  "user_id": "123",
  "transaction_id": "tx-456",
  "stack": "main.processPayment\n\t/app/main.go:42\nmain.handleRequest\n\t/app/main.go:28\n..."
}
```

### When to Use Stack Traces

**✓ Use for:**
- Critical errors requiring debugging
- Unexpected conditions (panics, invariant violations)
- Production incidents that need investigation
- Errors in rarely-executed code paths

**✗ Don't use for:**
- Expected errors (validation failures, not found)
- High-frequency errors (performance impact)
- Errors where context is sufficient
- Non-critical warnings

### Stack Capture Cost

Stack traces have overhead:

```go
// Low overhead - no stack trace
logger.LogError(err, "validation failed", "field", field)

// Higher overhead - captures stack trace
logger.ErrorWithStack("unexpected error", err, true, "field", field)
```

**Performance impact:**
- Stack capture: ~100µs per call
- Stack formatting: ~50µs per call
- Additional log size: ~2-5KB

**Recommendation:** Use `ErrorWithStack(includeStack: true)` sparingly, only for critical errors.

### Conditional Stack Traces

Include stack traces only when needed:

```go
func handleError(err error, critical bool) {
    logger.ErrorWithStack("operation failed", err, critical,
        "severity", map[bool]string{true: "critical", false: "normal"}[critical],
    )
}

// Normal error - no stack
handleError(validationErr, false)

// Critical error - with stack
handleError(dbCorruptionErr, true)
```

### With Panic Recovery

```go
func recoverPanic() {
    if r := recover(); r != nil {
        err := fmt.Errorf("panic: %v", r)
        logger.ErrorWithStack("panic recovered", err, true,
            "panic_value", r,
        )
    }
}

func riskyOperation() {
    defer recoverPanic()
    
    // Operations that might panic...
}
```

## Combining Convenience Methods

Use multiple convenience methods together:

```go
func handleRequest(w http.ResponseWriter, r *http.Request) {
    start := time.Now()
    
    // Process request
    result, err := processRequest(r)
    
    if err != nil {
        // Log error with context
        logger.LogError(err, "request processing failed",
            "path", r.URL.Path,
        )
        
        // Log request details
        logger.LogRequest(r, "status", 500)
        
        http.Error(w, "Internal Server Error", 500)
        return
    }
    
    // Log successful request
    logger.LogRequest(r, 
        "status", 200,
        "items", len(result.Items),
    )
    
    // Log timing
    logger.LogDuration("request completed", start,
        "items_processed", len(result.Items),
    )
    
    json.NewEncoder(w).Encode(result)
}
```

## Performance Considerations

### Pooled Attribute Slices

Convenience methods use pooled slices internally for efficiency:

```go
// No allocations beyond the log entry itself
logger.LogRequest(r, "status", 200, "bytes", 1024)
logger.LogError(err, "failed", "retry", 3)
logger.LogDuration("done", start, "count", 100)
```

**Implementation detail:** Methods use `sync.Pool` for attribute slices, reducing GC pressure.

### Zero Allocations

Standard logging with convenience methods:

```go
// Benchmark: 0 allocs/op for standard use
logger.LogRequest(r, "status", 200)
logger.LogError(err, "failed")
logger.LogDuration("done", start)
```

**Exception:** `ErrorWithStack` allocates for stack trace capture (intentional trade-off).

## Next Steps

- Learn [Log Sampling](../sampling/) to reduce volume
- Explore [Dynamic Log Levels](../dynamic-levels/) for runtime control
- See [Best Practices](../best-practices/) for production patterns
- Review [Router Integration](../router-integration/) for automatic request logging

For API details, see the [API Reference](/reference/packages/logging/api-reference/).
