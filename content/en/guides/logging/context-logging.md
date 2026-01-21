---
title: "Context-Aware Logging"
description: "Add trace correlation and contextual information to logs with ContextLogger"
weight: 5
keywords:
  - context logging
  - request id
  - trace correlation
  - contextual logging
---

This guide covers context-aware logging with automatic trace correlation for distributed tracing integration.

## Overview

Context-aware logging automatically extracts trace and span IDs from OpenTelemetry contexts, enabling correlation between logs and distributed traces.

**Why context-aware logging:**
- Correlate logs with distributed traces.
- Track requests across service boundaries.
- Debug multi-service workflows.
- Include trace IDs automatically without manual passing.

## ContextLogger Basics

`ContextLogger` wraps a standard `Logger` and automatically extracts trace information from context.

### Creating a ContextLogger

```go
import (
    "context"
    "rivaas.dev/logging"
    "rivaas.dev/tracing"
)

// Create base logger
log := logging.MustNew(logging.WithJSONHandler())

// In a request handler with traced context
func handler(ctx context.Context) {
    // Create context logger
    cl := logging.NewContextLogger(ctx, log)
    
    cl.Info("processing request", "user_id", "123")
    // Output includes: "trace_id":"abc123...", "span_id":"def456..."
}
```

### With OpenTelemetry Tracing

Full integration with OpenTelemetry:

```go
package main

import (
    "context"
    "rivaas.dev/logging"
    "rivaas.dev/tracing"
)

func main() {
    // Initialize tracing
    tracer := tracing.MustNew(
        tracing.WithOTLP("localhost:4317"),
        tracing.WithServiceName("my-api"),
    )
    defer tracer.Shutdown(context.Background())

    // Initialize logging
    log := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithServiceName("my-api"),
    )

    // Start a trace
    ctx, span := tracer.Start(context.Background(), "operation")
    defer span.End()

    // Create context logger
    cl := logging.NewContextLogger(ctx, log)
    
    cl.Info("operation started")
    // Automatically includes trace_id and span_id
}
```

**Output:**
```json
{
  "time": "2024-01-15T10:30:45.123Z",
  "level": "INFO",
  "msg": "operation started",
  "service": "my-api",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7"
}
```

## Automatic Trace Correlation

When a context contains an active OpenTelemetry span, `ContextLogger` automatically extracts:

- **trace_id** - Unique identifier for the entire trace
- **span_id** - Unique identifier for this operation

### Field Names

The logger uses OpenTelemetry semantic conventions:

```json
{
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7"
}
```

These field names match standard observability tools (Jaeger, Tempo, Honeycomb).

## Using ContextLogger Methods

`ContextLogger` provides the same logging methods as `Logger`.

### Logging at Different Levels

```go
cl := logging.NewContextLogger(ctx, log)

cl.Debug("debugging info", "detail", "value")
cl.Info("informational message", "status", "ok")
cl.Warn("warning condition", "threshold", 100)
cl.Error("error occurred", "error", err)
```

All methods automatically include trace and span IDs if available.

### Adding Additional Context

Use `With()` to add persistent fields:

```go
// Add fields that persist across log calls
requestLogger := cl.With(
    "request_id", "req-123",
    "user_id", "user-456",
)

requestLogger.Info("validation started")
requestLogger.Info("validation completed")
// Both logs include request_id, user_id, trace_id, span_id
```

## Accessing Trace Information

Retrieve trace IDs programmatically:

```go
cl := logging.NewContextLogger(ctx, log)

traceID := cl.TraceID()   // "4bf92f3577b34da6a3ce929d0e0e4736"
spanID := cl.SpanID()     // "00f067aa0ba902b7"

if traceID != "" {
    // Context has active trace
    log.Info("traced operation", "trace_id", traceID)
}
```

**Use cases:**
- Include trace ID in API responses
- Add to custom headers
- Pass to external systems

## Without Active Trace

If context has no active span, `ContextLogger` behaves like a normal logger:

```go
ctx := context.Background()  // No span
cl := logging.NewContextLogger(ctx, log)

cl.Info("message")
// Output: No trace_id or span_id fields
```

This makes `ContextLogger` safe to use everywhere, whether tracing is enabled or not.

## Structured Context

Combine context logging with grouped attributes for clean organization.

### Grouping Related Fields

```go
// Get underlying slog.Logger for grouping
logger := cl.Logger()

requestLogger := logger.WithGroup("request")
requestLogger.Info("received", 
    "method", "POST",
    "path", "/api/users",
)
```

**Output:**
```json
{
  "msg": "received",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "request": {
    "method": "POST",
    "path": "/api/users"
  }
}
```

## Request Handler Pattern

Common pattern for HTTP request handlers:

```go
func (s *Server) handleRequest(w http.ResponseWriter, r *http.Request) {
    // Extract or create traced context
    ctx := r.Context()
    
    // Create context logger
    cl := logging.NewContextLogger(ctx, s.logger)
    
    // Add request-specific fields
    requestLog := cl.With(
        "request_id", generateRequestID(),
        "method", r.Method,
        "path", r.URL.Path,
    )
    
    requestLog.Info("request started")
    
    // Process request...
    
    requestLog.Info("request completed", "status", 200)
}
```

## Performance Considerations

### Trace Extraction Overhead

Trace ID extraction happens once during `NewContextLogger()` creation:

```go
// Trace extraction happens here (one-time cost)
cl := logging.NewContextLogger(ctx, log)

// No additional overhead
cl.Info("message 1")
cl.Info("message 2")
cl.Info("message 3")
```

**Best practice:** Create `ContextLogger` once per request/operation, reuse for all logging.

### Pooling for High Load

For extreme high-load scenarios, consider pooling `ContextLogger` instances:

```go
var contextLoggerPool = sync.Pool{
    New: func() any {
        return &logging.ContextLogger{}
    },
}

func getContextLogger(ctx context.Context, log *logging.Logger) *logging.ContextLogger {
    cl := contextLoggerPool.Get().(*logging.ContextLogger)
    // Reinitialize with new context
    *cl = *logging.NewContextLogger(ctx, log)
    return cl
}

func putContextLogger(cl *logging.ContextLogger) {
    contextLoggerPool.Put(cl)
}
```

**Note:** Only needed for >10k requests/second with extremely tight latency requirements.

## Integration with Router

The Rivaas router automatically provides traced contexts:

```go
import (
    "rivaas.dev/router"
    "rivaas.dev/logging"
)

r := router.MustNew()
logger := logging.MustNew(logging.WithJSONHandler())
r.SetLogger(logger)

r.GET("/api/users", func(c *router.Context) {
    // Context is already traced if tracing is enabled
    cl := logging.NewContextLogger(c.Request.Context(), logger)
    
    cl.Info("fetching users")
    
    // Or use the router's logger directly (already context-aware)
    c.Logger().Info("using router logger")
    
    c.JSON(200, users)
})
```

See [Router Integration](../router-integration/) for more details.

## Complete Example

Putting it all together:

```go
package main

import (
    "context"
    "net/http"
    "rivaas.dev/logging"
    "rivaas.dev/tracing"
)

func main() {
    // Initialize tracing
    tracer := tracing.MustNew(
        tracing.WithOTLP("localhost:4317"),
        tracing.WithServiceName("payment-api"),
    )
    defer tracer.Shutdown(context.Background())

    // Initialize logging
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithServiceName("payment-api"),
        logging.WithServiceVersion("v1.0.0"),
    )
    defer logger.Shutdown(context.Background())

    // HTTP handler
    http.HandleFunc("/process", func(w http.ResponseWriter, r *http.Request) {
        // Start trace
        ctx, span := tracer.Start(r.Context(), "process_payment")
        defer span.End()

        // Create context logger
        cl := logging.NewContextLogger(ctx, logger)
        
        // Add request context
        requestLog := cl.With(
            "request_id", r.Header.Get("X-Request-ID"),
            "user_id", r.Header.Get("X-User-ID"),
        )

        requestLog.Info("payment processing started")

        // Process payment...

        requestLog.Info("payment processing completed", "status", "success")

        w.WriteHeader(http.StatusOK)
    })

    http.ListenAndServe(":8080", nil)
}
```

## Next Steps

- Learn [Convenience Methods](../convenience-methods/) for common patterns
- Explore [Router Integration](../router-integration/) for automatic context
- See [Best Practices](../best-practices/) for production logging

For API details, see the [API Reference](/reference/packages/logging/api-reference/).
