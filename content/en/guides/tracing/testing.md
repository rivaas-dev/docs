---
title: "Testing"
description: "Test your tracing implementation with provided utilities"
weight: 7
keywords:
  - tracing testing
  - test helpers
  - span assertions
  - testing
---

The tracing package provides testing utilities to help you write tests for traced applications.

## Testing Utilities

Three helper functions are provided for testing:

| Function | Purpose | Provider |
|----------|---------|----------|
| `TestingTracer()` | Create tracer for tests. | Noop |
| `TestingTracerWithStdout()` | Create tracer with output. | Stdout |
| `TestingMiddleware()` | Create test middleware. | Noop |

## TestingTracer

Create a tracer configured for unit tests.

### Basic Usage

```go
import (
    "testing"
    "rivaas.dev/tracing"
)

func TestSomething(t *testing.T) {
    t.Parallel()
    
    tracer := tracing.TestingTracer(t)
    // Use tracer in test...
}
```

### Features

- **Noop provider**: No actual tracing, minimal overhead.
- **Automatic cleanup**: `Shutdown()` called via `t.Cleanup()`.
- **Safe for parallel tests**: Each test gets its own tracer.
- **Default configuration**:
  - Service name: `"test-service"`.
  - Service version: `"v1.0.0"`.
  - Sample rate: `1.0` (100%).

### With Custom Options

Override defaults with your own options.

```go
func TestWithCustomConfig(t *testing.T) {
    tracer := tracing.TestingTracer(t,
        tracing.WithServiceName("my-test-service"),
        tracing.WithSampleRate(0.5),
    )
    // Use tracer...
}
```

### Complete Test Example

```go
func TestProcessOrder(t *testing.T) {
    t.Parallel()
    
    tracer := tracing.TestingTracer(t)
    ctx := context.Background()
    
    // Test your traced function
    result, err := processOrder(ctx, tracer, "order-123")
    
    assert.NoError(t, err)
    assert.Equal(t, "success", result)
}

func processOrder(ctx context.Context, tracer *tracing.Tracer, orderID string) (string, error) {
    ctx, span := tracer.StartSpan(ctx, "process-order")
    defer tracer.FinishSpan(span, 200)
    
    tracer.SetSpanAttribute(span, "order.id", orderID)
    
    return "success", nil
}
```

## TestingTracerWithStdout

Create a tracer that prints traces to stdout for debugging.

### When to Use

- Debugging test failures
- Verifying span creation
- Checking span attributes and events
- Understanding trace structure

### Basic Usage

```go
func TestWithDebugOutput(t *testing.T) {
    tracer := tracing.TestingTracerWithStdout(t)
    
    ctx := context.Background()
    ctx, span := tracer.StartSpan(ctx, "test-operation")
    defer tracer.FinishSpan(span, 200)
    
    tracer.SetSpanAttribute(span, "test.value", "debug")
}
```

### Output

When run, you'll see pretty-printed JSON traces:

```json
{
  "Name": "test-operation",
  "SpanContext": {
    "TraceID": "3f3c5e4d...",
    "SpanID": "a1b2c3d4..."
  },
  "Attributes": [
    {
      "Key": "test.value",
      "Value": {"Type": "STRING", "Value": "debug"}
    }
  ]
}
```

### With Custom Options

```go
func TestDebugWithOptions(t *testing.T) {
    tracer := tracing.TestingTracerWithStdout(t,
        tracing.WithServiceName("debug-service"),
        tracing.WithSampleRate(1.0),
    )
    // Use tracer...
}
```

## TestingMiddleware

Create HTTP middleware for testing traced handlers.

### Basic Usage

```go
import (
    "net/http"
    "net/http/httptest"
    "testing"
    
    "rivaas.dev/tracing"
)

func TestHTTPHandler(t *testing.T) {
    t.Parallel()
    
    // Create test middleware
    middleware := tracing.TestingMiddleware(t)
    
    // Wrap your handler
    handler := middleware(http.HandlerFunc(myHandler))
    
    // Test the handler
    req := httptest.NewRequest("GET", "/api/users", nil)
    rec := httptest.NewRecorder()
    
    handler.ServeHTTP(rec, req)
    
    assert.Equal(t, http.StatusOK, rec.Code)
}

func myHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}
```

### With Middleware Options

```go
func TestWithMiddlewareOptions(t *testing.T) {
    middleware := tracing.TestingMiddleware(t,
        tracing.WithExcludePaths("/health"),
        tracing.WithHeaders("X-Request-ID"),
    )
    
    handler := middleware(http.HandlerFunc(myHandler))
    // Test...
}
```

### Testing Path Exclusion

```go
func TestPathExclusion(t *testing.T) {
    middleware := tracing.TestingMiddleware(t,
        tracing.WithExcludePaths("/health"),
    )
    
    handler := middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // This handler should not create a span for /health
        w.WriteHeader(http.StatusOK)
    }))
    
    // Request to excluded path
    req := httptest.NewRequest("GET", "/health", nil)
    rec := httptest.NewRecorder()
    handler.ServeHTTP(rec, req)
    
    assert.Equal(t, http.StatusOK, rec.Code)
}
```

## TestingMiddlewareWithTracer

Use a custom tracer with test middleware.

### When to Use

- Need specific tracer configuration
- Testing with stdout output
- Custom sampling rates
- Specific provider behavior

### Basic Usage

```go
func TestWithCustomTracer(t *testing.T) {
    // Create custom tracer
    tracer := tracing.TestingTracer(t,
        tracing.WithSampleRate(0.5),
    )
    
    // Create middleware with custom tracer
    middleware := tracing.TestingMiddlewareWithTracer(t, tracer,
        tracing.WithExcludePaths("/metrics"),
    )
    
    handler := middleware(http.HandlerFunc(myHandler))
    // Test...
}
```

### With Stdout Output

```go
func TestDebugMiddleware(t *testing.T) {
    // Create tracer with stdout
    tracer := tracing.TestingTracerWithStdout(t)
    
    // Create middleware with that tracer
    middleware := tracing.TestingMiddlewareWithTracer(t, tracer)
    
    handler := middleware(http.HandlerFunc(myHandler))
    
    // Test and see trace output
    req := httptest.NewRequest("GET", "/api/users", nil)
    rec := httptest.NewRecorder()
    handler.ServeHTTP(rec, req)
}
```

## Testing Patterns

### Table-Driven Tests

```go
func TestHandlers(t *testing.T) {
    tests := []struct {
        name       string
        path       string
        wantStatus int
    }{
        {"users endpoint", "/api/users", http.StatusOK},
        {"orders endpoint", "/api/orders", http.StatusOK},
        {"health check", "/health", http.StatusOK},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            
            middleware := tracing.TestingMiddleware(t)
            handler := middleware(http.HandlerFunc(myHandler))
            
            req := httptest.NewRequest("GET", tt.path, nil)
            rec := httptest.NewRecorder()
            
            handler.ServeHTTP(rec, req)
            
            assert.Equal(t, tt.wantStatus, rec.Code)
        })
    }
}
```

### Testing Span Attributes

```go
func TestSpanAttributes(t *testing.T) {
    t.Parallel()
    
    tracer := tracing.TestingTracer(t)
    ctx := context.Background()
    
    // Create span and add attributes
    ctx, span := tracer.StartSpan(ctx, "test-span")
    tracer.SetSpanAttribute(span, "user.id", "123")
    tracer.SetSpanAttribute(span, "user.role", "admin")
    tracer.FinishSpan(span, 200)
    
    // With noop provider, this doesn't record anything,
    // but ensures the code doesn't panic or error
}
```

### Testing Context Propagation

```go
func TestContextPropagation(t *testing.T) {
    t.Parallel()
    
    tracer := tracing.TestingTracer(t)
    ctx := context.Background()
    
    // Create parent span
    ctx, parentSpan := tracer.StartSpan(ctx, "parent")
    defer tracer.FinishSpan(parentSpan, 200)
    
    // Get trace ID
    traceID := tracing.TraceID(ctx)
    assert.NotEmpty(t, traceID)
    
    // Create child span - should have same trace ID
    ctx, childSpan := tracer.StartSpan(ctx, "child")
    defer tracer.FinishSpan(childSpan, 200)
    
    childTraceID := tracing.TraceID(ctx)
    assert.Equal(t, traceID, childTraceID, "child should have same trace ID")
}
```

### Testing Trace Injection/Extraction

```go
func TestTraceInjection(t *testing.T) {
    t.Parallel()
    
    tracer := tracing.TestingTracer(t)
    ctx := context.Background()
    
    // Create span
    ctx, span := tracer.StartSpan(ctx, "test")
    defer tracer.FinishSpan(span, 200)
    
    // Inject into headers
    headers := http.Header{}
    tracer.InjectTraceContext(ctx, headers)
    
    // Verify headers were set
    assert.NotEmpty(t, headers.Get("Traceparent"))
    
    // Extract from headers
    newCtx := context.Background()
    newCtx = tracer.ExtractTraceContext(newCtx, headers)
    
    // Both contexts should have the same trace ID
    originalTraceID := tracing.TraceID(ctx)
    extractedTraceID := tracing.TraceID(newCtx)
    assert.Equal(t, originalTraceID, extractedTraceID)
}
```

### Integration Test Example

```go
func TestAPIWithTracing(t *testing.T) {
    t.Parallel()
    
    // Create tracer
    tracer := tracing.TestingTracer(t)
    
    // Create test server with tracing
    mux := http.NewServeMux()
    mux.HandleFunc("/api/users", func(w http.ResponseWriter, r *http.Request) {
        ctx := r.Context()
        
        // Add attributes from context
        tracing.SetSpanAttributeFromContext(ctx, "handler", "users")
        
        w.WriteHeader(http.StatusOK)
        w.Write([]byte(`{"users": []}`))
    })
    
    handler := tracing.TestingMiddlewareWithTracer(t, tracer)(mux)
    server := httptest.NewServer(handler)
    defer server.Close()
    
    // Make request
    resp, err := http.Get(server.URL + "/api/users")
    require.NoError(t, err)
    defer resp.Body.Close()
    
    assert.Equal(t, http.StatusOK, resp.StatusCode)
}
```

## Benchmarking

Test tracing overhead in benchmarks:

```go
func BenchmarkTracedHandler(b *testing.B) {
    tracer := tracing.TestingTracer(b)
    
    middleware := tracing.TestingMiddlewareWithTracer(b, tracer)
    handler := middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    }))
    
    req := httptest.NewRequest("GET", "/", nil)
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        rec := httptest.NewRecorder()
        handler.ServeHTTP(rec, req)
    }
}

func BenchmarkUntracedHandler(b *testing.B) {
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    })
    
    req := httptest.NewRequest("GET", "/", nil)
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        rec := httptest.NewRecorder()
        handler.ServeHTTP(rec, req)
    }
}
```

## Best Practices

### Use t.Parallel()

Enable parallel test execution:

```go
func TestSomething(t *testing.T) {
    t.Parallel() // Safe - each test gets its own tracer
    
    tracer := tracing.TestingTracer(t)
    // Test...
}
```

### Don't Call Shutdown Manually

The test utilities handle cleanup automatically:

```go
// ✓ Good - automatic cleanup
func TestGood(t *testing.T) {
    tracer := tracing.TestingTracer(t)
    // No need to call Shutdown()
}

// ✗ Bad - redundant manual cleanup
func TestBad(t *testing.T) {
    tracer := tracing.TestingTracer(t)
    defer tracer.Shutdown(context.Background()) // Unnecessary
}
```

### Use Stdout for Debugging Only

Don't use `TestingTracerWithStdout` for regular tests:

```go
// ✓ Good - stdout only when debugging
func TestDebug(t *testing.T) {
    if testing.Verbose() {
        tracer := tracing.TestingTracerWithStdout(t)
    } else {
        tracer := tracing.TestingTracer(t)
    }
}

// ✗ Bad - noisy test output
func TestRegular(t *testing.T) {
    tracer := tracing.TestingTracerWithStdout(t) // Too verbose
}
```

### Test Error Cases

```go
func TestErrorHandling(t *testing.T) {
    t.Parallel()
    
    tracer := tracing.TestingTracer(t)
    ctx := context.Background()
    
    ctx, span := tracer.StartSpan(ctx, "test-error")
    defer tracer.FinishSpan(span, http.StatusInternalServerError)
    
    tracer.SetSpanAttribute(span, "error", true)
    tracer.SetSpanAttribute(span, "error.message", "test error")
}
```

## Comparison with Other Packages

Testing utilities follow the same pattern:

| Package | Testing Function | Provider |
|---------|-----------------|----------|
| Metrics | `metrics.TestingRecorder()` | Noop |
| Metrics | `metrics.TestingRecorderWithPrometheus()` | Prometheus |
| Tracing | `tracing.TestingTracer()` | Noop |
| Tracing | `tracing.TestingTracerWithStdout()` | Stdout |

## Next Steps

- See [Examples](../examples/) for production-ready configurations
- Check [API Reference](/reference/packages/tracing/api-reference/) for all methods
- Review [Troubleshooting](/reference/packages/tracing/troubleshooting/) for common issues
