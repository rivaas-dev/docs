---
title: "Context Propagation"
description: "Propagate traces across service boundaries"
weight: 6
---

Learn how to propagate trace context across service boundaries for distributed tracing.

## What is Context Propagation?

Context propagation transmits trace information between services so that related operations appear in the same trace, even across network boundaries.

### Why It Matters

Without context propagation:
- Each service creates independent traces
- No visibility into end-to-end request flow
- Can't trace requests across microservices

With context propagation:
- All services contribute to the same trace
- Complete visibility of distributed transactions
- Track requests across service boundaries

## W3C Trace Context

The tracing package uses **W3C Trace Context** format by default, which is:

- **Standard**: Widely supported across languages and tools
- **Propagated via HTTP headers**:
  - `traceparent`: Contains trace ID, span ID, trace flags
  - `tracestate`: Contains vendor-specific trace data
- **Compatible**: Works with Jaeger, Zipkin, OpenTelemetry, and more

## Extracting Trace Context

Extract trace context from incoming HTTP requests.

### Automatic Extraction (Middleware)

The middleware automatically extracts trace context:

```go
handler := tracing.Middleware(tracer)(mux)
// Context extraction is automatic
```

No additional code needed - spans automatically become part of the parent trace.

### Manual Extraction

For manual span creation or custom HTTP handlers:

```go
func handleRequest(w http.ResponseWriter, r *http.Request) {
    // Extract trace context from request headers
    ctx := tracer.ExtractTraceContext(r.Context(), r.Header)
    
    // Create span with propagated context
    ctx, span := tracer.StartSpan(ctx, "process-request")
    defer tracer.FinishSpan(span, http.StatusOK)
    
    // Span is now part of the distributed trace
}
```

### What Gets Extracted

```http
GET /api/users HTTP/1.1
Host: api.example.com
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
tracestate: vendor1=value1,vendor2=value2
```

The `ExtractTraceContext` method reads these headers and links the new span to the parent trace.

## Injecting Trace Context

Inject trace context into outgoing HTTP requests.

### Manual Injection

When making HTTP calls to other services:

```go
func callDownstreamService(ctx context.Context, tracer *tracing.Tracer) error {
    // Create outgoing request
    req, err := http.NewRequestWithContext(ctx, "GET", "http://downstream/api", nil)
    if err != nil {
        return err
    }
    
    // Inject trace context into request headers
    tracer.InjectTraceContext(ctx, req.Header)
    
    // Make the request
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    return nil
}
```

### What Gets Injected

The `InjectTraceContext` method adds headers to propagate the trace:

```go
// Before injection
req.Header: {}

// After injection
req.Header: {
    "Traceparent": ["00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01"],
    "Tracestate": ["vendor1=value1"],
}
```

## Complete Distributed Tracing Example

Here's a complete example showing service-to-service tracing:

### Service A (Frontend)

```go
package main

import (
    "context"
    "io"
    "log"
    "net/http"
    
    "rivaas.dev/tracing"
)

func main() {
    tracer := tracing.MustNew(
        tracing.WithServiceName("frontend-api"),
        tracing.WithOTLP("localhost:4317"),
    )
    tracer.Start(context.Background())
    defer tracer.Shutdown(context.Background())

    mux := http.NewServeMux()
    
    // Handler that calls downstream service
    mux.HandleFunc("/api/process", func(w http.ResponseWriter, r *http.Request) {
        ctx := r.Context()
        
        // Create span for this service's work
        ctx, span := tracer.StartSpan(ctx, "frontend-process")
        defer tracer.FinishSpan(span, http.StatusOK)
        
        // Call downstream service with trace propagation
        result, err := callBackendService(ctx, tracer)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        
        w.Write([]byte(result))
    })
    
    handler := tracing.Middleware(tracer)(mux)
    log.Fatal(http.ListenAndServe(":8080", handler))
}

func callBackendService(ctx context.Context, tracer *tracing.Tracer) (string, error) {
    // Create span for outgoing call
    ctx, span := tracer.StartSpan(ctx, "call-backend-service")
    defer tracer.FinishSpan(span, http.StatusOK)
    
    // Create HTTP request
    req, err := http.NewRequestWithContext(ctx, "GET", 
        "http://localhost:8081/api/data", nil)
    if err != nil {
        return "", err
    }
    
    // Inject trace context for propagation
    tracer.InjectTraceContext(ctx, req.Header)
    
    // Make the request
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    
    body, _ := io.ReadAll(resp.Body)
    return string(body), nil
}
```

### Service B (Backend)

```go
package main

import (
    "context"
    "log"
    "net/http"
    
    "rivaas.dev/tracing"
)

func main() {
    tracer := tracing.MustNew(
        tracing.WithServiceName("backend-api"),
        tracing.WithOTLP("localhost:4317"),
    )
    tracer.Start(context.Background())
    defer tracer.Shutdown(context.Background())

    mux := http.NewServeMux()
    
    // Handler automatically receives trace context via middleware
    mux.HandleFunc("/api/data", func(w http.ResponseWriter, r *http.Request) {
        ctx := r.Context()
        
        // This span is automatically part of the distributed trace
        ctx, span := tracer.StartSpan(ctx, "fetch-data")
        defer tracer.FinishSpan(span, http.StatusOK)
        
        tracer.SetSpanAttribute(span, "data.source", "database")
        
        // Simulate work
        data := fetchFromDatabase(ctx, tracer)
        
        w.Write([]byte(data))
    })
    
    // Middleware automatically extracts trace context
    handler := tracing.Middleware(tracer)(mux)
    log.Fatal(http.ListenAndServe(":8081", handler))
}

func fetchFromDatabase(ctx context.Context, tracer *tracing.Tracer) string {
    // Nested span - all part of the same trace
    ctx, span := tracer.StartSpan(ctx, "database-query")
    defer tracer.FinishSpan(span, http.StatusOK)
    
    tracer.SetSpanAttribute(span, "db.system", "postgresql")
    tracer.SetSpanAttribute(span, "db.query", "SELECT * FROM data")
    
    return "data from database"
}
```

### Resulting Trace

The trace will show the complete flow:

```
frontend-api: GET /api/process
├─ frontend-api: frontend-process
│  └─ frontend-api: call-backend-service
│     └─ backend-api: GET /api/data
│        └─ backend-api: fetch-data
│           └─ backend-api: database-query
```

## Context Helper Functions

Work with trace context without direct span references.

### Get Trace Information

Retrieve trace and span IDs from context:

```go
func logWithTraceInfo(ctx context.Context) {
    traceID := tracing.TraceID(ctx)
    spanID := tracing.SpanID(ctx)
    
    log.Printf("[trace=%s span=%s] Processing request", traceID, spanID)
}
```

Returns empty string if no active span.

### Set Attributes from Context

Add attributes to the current span:

```go
func processOrder(ctx context.Context, orderID string) {
    // Add attributes to current span in context
    tracing.SetSpanAttributeFromContext(ctx, "order.id", orderID)
    tracing.SetSpanAttributeFromContext(ctx, "order.status", "processing")
}
```

No-op if no active span.

### Add Events from Context

Add events to the current span:

```go
import "go.opentelemetry.io/otel/attribute"

func validatePayment(ctx context.Context, amount float64) {
    // Add event to current span
    tracing.AddSpanEventFromContext(ctx, "payment_validated",
        attribute.Float64("amount", amount),
        attribute.String("currency", "USD"),
    )
}
```

### Get Trace Context

The context already contains trace information:

```go
func passContextToWorker(ctx context.Context) {
    // Context already has trace info - just pass it
    go processInBackground(ctx)
}

func processInBackground(ctx context.Context) {
    // Trace context is preserved
    traceID := tracing.TraceID(ctx)
    log.Printf("Background work [trace=%s]", traceID)
}
```

## Custom Propagators

Use alternative trace context formats.

### B3 Propagation (Zipkin)

```go
import "go.opentelemetry.io/contrib/propagators/b3"

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithCustomPropagator(b3.New()),
    tracing.WithOTLP("localhost:4317"),
)
```

Uses Zipkin's B3 headers:
- `X-B3-TraceId`
- `X-B3-SpanId`
- `X-B3-Sampled`

### Jaeger Propagation

```go
import "go.opentelemetry.io/contrib/propagators/jaeger"

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithCustomPropagator(jaeger.Jaeger{}),
    tracing.WithOTLP("localhost:4317"),
)
```

Uses Jaeger's `uber-trace-id` header.

### Composite Propagator

Support multiple formats simultaneously:

```go
import (
    "go.opentelemetry.io/otel/propagation"
    "go.opentelemetry.io/contrib/propagators/b3"
)

composite := propagation.NewCompositeTextMapPropagator(
    propagation.TraceContext{}, // W3C Trace Context
    propagation.Baggage{},      // W3C Baggage
    b3.New(),                   // B3 (Zipkin)
)

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithCustomPropagator(composite),
    tracing.WithOTLP("localhost:4317"),
)
```

## Best Practices

### Always Propagate Context

Pass context through the entire call chain:

```go
// ✓ Good - context propagates
func handler(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    result := doWork(ctx)  // Pass context
}

func doWork(ctx context.Context) string {
    ctx, span := tracer.StartSpan(ctx, "do-work")
    defer tracer.FinishSpan(span, http.StatusOK)
    
    return doMoreWork(ctx)  // Pass context
}

// ✗ Bad - context lost
func handler(w http.ResponseWriter, r *http.Request) {
    result := doWork(context.Background())  // Lost trace context!
}
```

### Use Context for HTTP Clients

Always use `http.NewRequestWithContext`:

```go
// ✓ Good
req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
tracer.InjectTraceContext(ctx, req.Header)

// ✗ Bad - no context
req, _ := http.NewRequest("GET", url, nil)
tracer.InjectTraceContext(ctx, req.Header)  // Won't have span info
```

### Inject Before Making Requests

Always inject trace context before sending requests:

```go
req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)

// Inject trace context
tracer.InjectTraceContext(ctx, req.Header)

// Then make request
resp, _ := http.DefaultClient.Do(req)
```

### Extract in Custom Handlers

If not using middleware, extract context manually:

```go
func customHandler(w http.ResponseWriter, r *http.Request) {
    // Extract trace context
    ctx := tracer.ExtractTraceContext(r.Context(), r.Header)
    
    // Use propagated context
    ctx, span := tracer.StartSpan(ctx, "custom-handler")
    defer tracer.FinishSpan(span, http.StatusOK)
}
```

## Troubleshooting

### Traces Not Connected Across Services

**Problem**: Each service shows separate traces instead of one distributed trace.

**Solutions**:
1. Ensure both services use the same propagator format (default: W3C Trace Context)
2. Verify `InjectTraceContext` is called before making requests
3. Verify `ExtractTraceContext` is called when receiving requests
4. Check that context is passed through the call chain
5. Verify both services send to the same OTLP collector

### Missing Spans in Distributed Trace

**Problem**: Some spans appear but others are missing.

**Solutions**:
1. Check sampling rate - non-sampled requests won't create spans
2. Verify all services have tracing enabled
3. Ensure context is passed to all operations
4. Check for errors in span creation

### Context Lost in Goroutines

**Problem**: Background goroutines don't have trace context.

**Solution**: Pass context explicitly to goroutines:

```go
func handler(ctx context.Context) {
    // ✓ Good - pass context
    go func(ctx context.Context) {
        ctx, span := tracer.StartSpan(ctx, "background-work")
        defer tracer.FinishSpan(span, http.StatusOK)
    }(ctx)
    
    // ✗ Bad - lost context
    go func() {
        ctx := context.Background()  // Lost trace context!
        ctx, span := tracer.StartSpan(ctx, "background-work")
        defer tracer.FinishSpan(span, http.StatusOK)
    }()
}
```

## Next Steps

- Explore [Testing](../testing/) utilities for testing traces
- See [Examples](../examples/) for complete distributed tracing setups
- Check [API Reference](/reference/packages/tracing/api-reference/) for all context methods
