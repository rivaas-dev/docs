---
title: "Testing"
description: "Test utilities for metrics collection"
weight: 7
---

This guide covers testing utilities provided by the metrics package.

## Testing Utilities

The metrics package provides utilities for testing without port conflicts or complex setup.

## TestingRecorder

Create a test recorder with stdout provider. No network is required.

```go
package myapp_test

import (
    "testing"
    "rivaas.dev/metrics"
)

func TestHandler(t *testing.T) {
    t.Parallel()
    
    // Create test recorder (uses stdout, avoids port conflicts)
    recorder := metrics.TestingRecorder(t, "test-service")
    
    // Use recorder in tests...
    handler := NewHandler(recorder)
    
    // Test your handler
    req := httptest.NewRequest("GET", "/", nil)
    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)
    
    // Assertions...
    // Cleanup is automatic via t.Cleanup()
}

// With additional options
func TestWithOptions(t *testing.T) {
    recorder := metrics.TestingRecorder(t, "test-service",
        metrics.WithMaxCustomMetrics(100),
    )
    // ...
}
```

### Signature

```go
func TestingRecorder(tb testing.TB, serviceName string, opts ...Option) *Recorder
```

**Parameters**:
- `tb testing.TB` - Test or benchmark instance.
- `serviceName string` - Service name for metrics.
- `opts ...Option` - Optional additional configuration options.

### Features

- **No port conflicts**: Uses stdout provider, no network required.
- **Automatic cleanup**: Registers cleanup via `t.Cleanup()`.
- **Parallel safe**: Safe to use in parallel tests.
- **Simple setup**: One-line initialization.
- **Works with benchmarks**: Accepts `testing.TB` (both `*testing.T` and `*testing.B`).

### Example

```go
func TestMetricsCollection(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorder(t, "test-service")
    
    // Record some metrics
    ctx := context.Background()
    err := recorder.IncrementCounter(ctx, "test_counter")
    if err != nil {
        t.Errorf("Failed to record counter: %v", err)
    }
    
    err = recorder.RecordHistogram(ctx, "test_duration", 1.5)
    if err != nil {
        t.Errorf("Failed to record histogram: %v", err)
    }
    
    // Test passes if no errors
}
```

## TestingRecorderWithPrometheus

Create a test recorder with Prometheus provider (for endpoint testing):

```go
func TestPrometheusEndpoint(t *testing.T) {
    t.Parallel()
    
    // Create test recorder with Prometheus (dynamic port)
    recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")
    
    // Wait for server to be ready
    err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
    if err != nil {
        t.Fatal(err)
    }
    
    // Test metrics endpoint (note: ServerAddress returns port like ":9090")
    resp, err := http.Get("http://localhost" + recorder.ServerAddress() + "/metrics")
    if err != nil {
        t.Fatal(err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }
}
```

### Signature

```go
func TestingRecorderWithPrometheus(tb testing.TB, serviceName string, opts ...Option) *Recorder
```

**Parameters**:
- `tb testing.TB` - Test or benchmark instance
- `serviceName string` - Service name for metrics
- `opts ...Option` - Optional additional configuration options

### Features

- **Dynamic port allocation**: Automatically finds available port
- **Real Prometheus endpoint**: Test actual HTTP metrics endpoint
- **Server readiness check**: Use `WaitForMetricsServer` to wait for startup
- **Automatic cleanup**: Shuts down server via `t.Cleanup()`
- **Works with benchmarks**: Accepts `testing.TB` (both `*testing.T` and `*testing.B`)

## WaitForMetricsServer

Wait for Prometheus metrics server to be ready:

```go
func TestMetricsEndpoint(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")
    
    // Wait up to 5 seconds for server to start
    err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
    if err != nil {
        t.Fatalf("Metrics server not ready: %v", err)
    }
    
    // Server is ready, make requests (note: ServerAddress returns port like ":9090")
    resp, err := http.Get("http://localhost" + recorder.ServerAddress() + "/metrics")
    // ... test response
}
```

### Signature

```go
func WaitForMetricsServer(tb testing.TB, address string, timeout time.Duration) error
```

### Parameters

- `tb testing.TB`: Test or benchmark instance for logging
- `address string`: Server address (e.g., `:9090`)
- `timeout time.Duration`: Maximum wait time

### Returns

- `error`: Returns error if server doesn't become ready within timeout

## Testing Middleware

Test HTTP middleware with metrics collection:

```go
func TestMiddleware(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorder(t, "test-service")
    
    // Create test handler
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
    })
    
    // Wrap with metrics middleware
    wrappedHandler := metrics.Middleware(recorder)(handler)
    
    // Make test request
    req := httptest.NewRequest("GET", "/test", nil)
    w := httptest.NewRecorder()
    
    wrappedHandler.ServeHTTP(w, req)
    
    // Assert response
    if w.Code != http.StatusOK {
        t.Errorf("Expected status 200, got %d", w.Code)
    }
    
    if w.Body.String() != "OK" {
        t.Errorf("Expected body 'OK', got %s", w.Body.String())
    }
    
    // Metrics are recorded (visible in test logs if verbose)
}
```

## Testing Custom Metrics

Test custom metric recording:

```go
func TestCustomMetrics(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorder(t, "test-service")
    ctx := context.Background()
    
    tests := []struct {
        name    string
        record  func() error
        wantErr bool
    }{
        {
            name: "valid counter",
            record: func() error {
                return recorder.IncrementCounter(ctx, "test_counter")
            },
            wantErr: false,
        },
        {
            name: "invalid counter name",
            record: func() error {
                return recorder.IncrementCounter(ctx, "__reserved")
            },
            wantErr: true,
        },
        {
            name: "valid histogram",
            record: func() error {
                return recorder.RecordHistogram(ctx, "test_duration", 1.5)
            },
            wantErr: false,
        },
        {
            name: "valid gauge",
            record: func() error {
                return recorder.SetGauge(ctx, "test_gauge", 42)
            },
            wantErr: false,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.record()
            if (err != nil) != tt.wantErr {
                t.Errorf("wantErr=%v, got err=%v", tt.wantErr, err)
            }
        })
    }
}
```

## Testing Error Handling

Test metric recording error handling:

```go
func TestMetricErrors(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorder(t, "test-service")
    ctx := context.Background()
    
    // Test invalid metric name
    err := recorder.IncrementCounter(ctx, "http_invalid")
    if err == nil {
        t.Error("Expected error for reserved prefix, got nil")
    }
    
    // Test reserved prefix
    err = recorder.IncrementCounter(ctx, "__internal")
    if err == nil {
        t.Error("Expected error for reserved prefix, got nil")
    }
    
    // Test valid metric
    err = recorder.IncrementCounter(ctx, "valid_metric")
    if err != nil {
        t.Errorf("Expected no error, got %v", err)
    }
}
```

## Integration Testing

Test complete HTTP server with metrics:

```go
func TestServerWithMetrics(t *testing.T) {
    recorder := metrics.TestingRecorderWithPrometheus(t, "test-api")
    
    // Wait for metrics server
    err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
    if err != nil {
        t.Fatal(err)
    }
    
    // Create test HTTP server
    mux := http.NewServeMux()
    mux.HandleFunc("/api", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte(`{"status": "ok"}`))
    })
    
    handler := metrics.Middleware(recorder)(mux)
    
    server := httptest.NewServer(handler)
    defer server.Close()
    
    // Make requests
    resp, err := http.Get(server.URL + "/api")
    if err != nil {
        t.Fatal(err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }
    
    // Check metrics endpoint (note: ServerAddress returns port like ":9090")
    metricsResp, err := http.Get("http://localhost" + recorder.ServerAddress() + "/metrics")
    if err != nil {
        t.Fatal(err)
    }
    defer metricsResp.Body.Close()
    
    body, _ := io.ReadAll(metricsResp.Body)
    bodyStr := string(body)
    
    // Verify metrics exist
    if !strings.Contains(bodyStr, "http_requests_total") {
        t.Error("Expected http_requests_total metric")
    }
}
```

## Parallel Tests

The testing utilities support parallel test execution:

```go
func TestMetricsParallel(t *testing.T) {
    tests := []struct {
        name string
        path string
    }{
        {"endpoint1", "/api/users"},
        {"endpoint2", "/api/orders"},
        {"endpoint3", "/api/products"},
    }
    
    for _, tt := range tests {
        tt := tt // Capture range variable
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            
            // Each test gets its own recorder
            recorder := metrics.TestingRecorder(t, "test-"+tt.name)
            
            // Test handler
            handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
                w.WriteHeader(http.StatusOK)
            })
            
            wrapped := metrics.Middleware(recorder)(handler)
            
            req := httptest.NewRequest("GET", tt.path, nil)
            w := httptest.NewRecorder()
            wrapped.ServeHTTP(w, req)
            
            if w.Code != http.StatusOK {
                t.Errorf("Expected 200, got %d", w.Code)
            }
        })
    }
}
```

## Benchmarking

Benchmark metrics collection performance:

```go
func BenchmarkMetricsMiddleware(b *testing.B) {
    // Create recorder (use t=nil for benchmarks)
    recorder, err := metrics.New(
        metrics.WithStdout(),
        metrics.WithServiceName("bench-service"),
    )
    if err != nil {
        b.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())
    
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    })
    
    wrapped := metrics.Middleware(recorder)(handler)
    
    req := httptest.NewRequest("GET", "/test", nil)
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        w := httptest.NewRecorder()
        wrapped.ServeHTTP(w, req)
    }
}

func BenchmarkCustomMetrics(b *testing.B) {
    recorder, err := metrics.New(
        metrics.WithStdout(),
        metrics.WithServiceName("bench-service"),
    )
    if err != nil {
        b.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())
    
    ctx := context.Background()
    
    b.Run("Counter", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            _ = recorder.IncrementCounter(ctx, "bench_counter")
        }
    })
    
    b.Run("Histogram", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            _ = recorder.RecordHistogram(ctx, "bench_duration", 1.5)
        }
    })
    
    b.Run("Gauge", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            _ = recorder.SetGauge(ctx, "bench_gauge", 42)
        }
    })
}
```

## Testing Best Practices

### Use Parallel Tests

Enable parallel execution to run tests faster:

```go
func TestSomething(t *testing.T) {
    t.Parallel() // Always use t.Parallel() when safe
    
    recorder := metrics.TestingRecorder(t, "test-service")
    // ... test code
}
```

### Prefer TestingRecorder

Use `TestingRecorder` (stdout) unless you specifically need to test the HTTP endpoint:

```go
// Good - fast, no port allocation
recorder := metrics.TestingRecorder(t, "test-service")

// Only when needed - tests HTTP endpoint
recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")
```

### Wait for Server Ready

Always wait for Prometheus server before making requests:

```go
recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")
err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
if err != nil {
    t.Fatal(err)
}
// Now safe to make requests
```

### Don't Forget Context

Always pass context to metric methods:

```go
ctx := context.Background()
err := recorder.IncrementCounter(ctx, "test_counter")
```

### Test Error Cases

Test both success and error cases:

```go
// Test valid metric
err := recorder.IncrementCounter(ctx, "valid_metric")
if err != nil {
    t.Errorf("Unexpected error: %v", err)
}

// Test invalid metric
err = recorder.IncrementCounter(ctx, "__reserved")
if err == nil {
    t.Error("Expected error for reserved prefix")
}
```

## Example Test Suite

Complete example test suite:

```go
package api_test

import (
    "context"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"
    
    "rivaas.dev/metrics"
    "myapp/api"
)

func TestAPI(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorder(t, "test-api")
    
    server := api.NewServer(recorder)
    
    tests := []struct {
        name       string
        method     string
        path       string
        wantStatus int
    }{
        {"home", "GET", "/", 200},
        {"users", "GET", "/api/users", 200},
        {"not found", "GET", "/invalid", 404},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest(tt.method, tt.path, nil)
            w := httptest.NewRecorder()
            
            server.ServeHTTP(w, req)
            
            if w.Code != tt.wantStatus {
                t.Errorf("Expected status %d, got %d", tt.wantStatus, w.Code)
            }
        })
    }
}

func TestMetricsEndpoint(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorderWithPrometheus(t, "test-api")
    
    err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
    if err != nil {
        t.Fatal(err)
    }
    
    resp, err := http.Get("http://localhost" + recorder.ServerAddress() + "/metrics")
    if err != nil {
        t.Fatal(err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }
}
```

## Next Steps

- See [Examples](../examples/) for complete application examples
- Learn [Custom Metrics](../custom-metrics/) to test your metrics
- Check [Middleware](../middleware/) for HTTP integration testing
- Review [API Reference](/reference/packages/metrics/api-reference/) for method details
