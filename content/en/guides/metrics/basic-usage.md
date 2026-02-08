---
title: "Basic Usage"
description: "Learn the fundamentals of metrics collection with Rivaas"
weight: 2
keywords:
  - metrics basic usage
  - counters
  - gauges
  - histograms
---

This guide covers the basic patterns for using the metrics package in your Go applications.

## Creating a Metrics Recorder

The core of the metrics package is the `Recorder` type. Create a recorder by choosing a provider and configuring it:

```go
package main

import (
    "context"
    "log"
    "os/signal"
    
    "rivaas.dev/metrics"
)

func main() {
    // Create context for application lifecycle
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create recorder with error handling
    recorder, err := metrics.New(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
        metrics.WithServiceVersion("v1.0.0"),
    )
    if err != nil {
        log.Fatalf("Failed to create recorder: %v", err)
    }
    
    // Start metrics server
    if err := recorder.Start(ctx); err != nil {
        log.Fatalf("Failed to start metrics: %v", err)
    }
    
    // Your application code here...
}
```

### Using MustNew

For applications that should fail fast on configuration errors:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)
// Panics if configuration is invalid
```

## Lifecycle Management

Proper lifecycle management ensures metrics are properly initialized and flushed on shutdown.

### Start and Shutdown

```go
func main() {
    // Create lifecycle context
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    recorder := metrics.MustNew(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
    )
    
    // Start with lifecycle context
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    // Ensure graceful shutdown
    defer func() {
        shutdownCtx, shutdownCancel := context.WithTimeout(
            context.Background(),
            5*time.Second,
        )
        defer shutdownCancel()
        
        if err := recorder.Shutdown(shutdownCtx); err != nil {
            log.Printf("Metrics shutdown error: %v", err)
        }
    }()
    
    // Your application code...
}
```

### Why Start() is Important

Different providers require `Start()` for different reasons:

- **OTLP**: Requires lifecycle context for network connections and graceful shutdown
- **Prometheus**: Starts the HTTP metrics server
- **Stdout**: Works without `Start()`, but calling it is harmless

**Best Practice**: Always call `Start(ctx)` with a lifecycle context, regardless of provider.

### Force Flush

For push-based providers (OTLP, stdout), you can force immediate export of pending metrics:

```go
// Before critical operation or deployment
if err := recorder.ForceFlush(ctx); err != nil {
    log.Printf("Failed to flush metrics: %v", err)
}
```

This is useful for:
- Ensuring metrics are exported before deployment
- Checkpointing during long-running operations
- Guaranteeing metrics visibility before shutdown

**Note**: For Prometheus (pull-based), this is typically a no-op as metrics are collected on-demand.

## Standalone Usage

Use the recorder directly without HTTP middleware:

```go
package main

import (
    "context"
    "log"
    "os/signal"
    
    "rivaas.dev/metrics"
    "go.opentelemetry.io/otel/attribute"
)

func main() {
    // Create context for application lifecycle
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create metrics recorder
    recorder := metrics.MustNew(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-service"),
    )
    
    // Start metrics server
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    defer recorder.Shutdown(context.Background())

    // Record custom metrics with error handling
    if err := recorder.RecordHistogram(ctx, "processing_duration", 1.5,
        attribute.String("operation", "create_user"),
    ); err != nil {
        log.Printf("metrics error: %v", err)
    }
    
    // Or fire-and-forget (ignore errors)
    _ = recorder.IncrementCounter(ctx, "requests_total",
        attribute.String("status", "success"),
    )
    
    _ = recorder.SetGauge(ctx, "active_connections", 42)
}
```

## HTTP Integration

Integrate metrics with your HTTP server using middleware:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os/signal"
    "time"
    
    "rivaas.dev/metrics"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create metrics recorder
    recorder, err := metrics.New(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    defer func() {
        shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer shutdownCancel()
        recorder.Shutdown(shutdownCtx)
    }()

    // Create HTTP handlers
    mux := http.NewServeMux()
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"message": "Hello"}`))
    })
    mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    })

    // Wrap with metrics middleware
    handler := metrics.Middleware(recorder,
        metrics.WithExcludePaths("/health", "/metrics"),
    )(mux)

    // Start HTTP server
    server := &http.Server{
        Addr:    ":8080",
        Handler: handler,
    }
    
    go func() {
        if err := server.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()
    
    // Wait for interrupt
    <-ctx.Done()
    
    shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer shutdownCancel()
    server.Shutdown(shutdownCtx)
}
```

## Built-in Metrics

When using the HTTP middleware, the following metrics are automatically collected:

| Metric | Type | Description |
|--------|------|-------------|
| `http_request_duration_seconds` | Histogram | Request duration distribution |
| `http_requests_total` | Counter | Total request count by status, method, path |
| `http_requests_active` | Gauge | Current active requests |
| `http_request_size_bytes` | Histogram | Request body size distribution |
| `http_response_size_bytes` | Histogram | Response body size distribution |
| `http_errors_total` | Counter | HTTP errors by status code |

### Viewing Metrics

With Prometheus provider, metrics are available at the configured endpoint:

```bash
curl http://localhost:9090/metrics
```

Example output:

```
# HELP target_info Target metadata
# TYPE target_info gauge
target_info{service_name="my-api",service_version="v1.0.0"} 1

# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",http_route="/",http_status_code="200"} 42

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",http_route="/",le="0.005"} 10
http_request_duration_seconds_bucket{method="GET",http_route="/",le="0.01"} 25
...
```

The `target_info` metric contains your service metadata. Individual metrics include request-specific labels like `method`, `http_route`, and `http_status_code`.

## Error Handling

The metrics package provides two patterns for error handling:

### Check Errors

For critical metrics where errors matter:

```go
if err := recorder.IncrementCounter(ctx, "critical_operations",
    attribute.String("type", "payment"),
); err != nil {
    log.Printf("Failed to record metric: %v", err)
    // Handle error appropriately
}
```

### Fire-and-Forget

For best-effort metrics where errors can be ignored:

```go
// Ignore errors - metrics are best-effort
_ = recorder.IncrementCounter(ctx, "page_views")
_ = recorder.RecordHistogram(ctx, "query_duration", duration)
```

**Best Practice**: Use fire-and-forget for most metrics to avoid impacting application performance.

## Thread Safety

All `Recorder` methods are thread-safe and can be called concurrently:

```go
// Safe to call from multiple goroutines
go func() {
    _ = recorder.IncrementCounter(ctx, "worker_1")
}()

go func() {
    _ = recorder.IncrementCounter(ctx, "worker_2")
}()
```

## Context Usage

All metrics methods accept a context for cancellation and tracing:

```go
// Use request context for tracing
func handleRequest(w http.ResponseWriter, r *http.Request) {
    // Metrics will inherit trace context from request
    _ = recorder.IncrementCounter(r.Context(), "requests_processed")
}

// Use timeout context
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
_ = recorder.RecordHistogram(ctx, "operation_duration", 1.5)
```

## Common Patterns

### Service Initialization

```go
type Service struct {
    recorder *metrics.Recorder
}

func NewService() (*Service, error) {
    recorder, err := metrics.New(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-service"),
    )
    if err != nil {
        return nil, err
    }
    
    return &Service{recorder: recorder}, nil
}

func (s *Service) Start(ctx context.Context) error {
    return s.recorder.Start(ctx)
}

func (s *Service) Shutdown(ctx context.Context) error {
    return s.recorder.Shutdown(ctx)
}
```

### Dependency Injection

```go
type Handler struct {
    recorder *metrics.Recorder
}

func NewHandler(recorder *metrics.Recorder) *Handler {
    return &Handler{recorder: recorder}
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    _ = h.recorder.IncrementCounter(r.Context(), "handler_calls")
    // Handle request...
}
```

## Next Steps

- Learn about [Providers](../providers/) to choose your metrics exporter
- Explore [Configuration](../configuration/) for advanced setup options
- See [Custom Metrics](../custom-metrics/) to record your own metrics
- Check [Middleware](../middleware/) for HTTP integration details
