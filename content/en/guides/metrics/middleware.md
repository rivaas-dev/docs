---
title: "HTTP Middleware"
description: "Integrate automatic HTTP metrics collection with middleware"
weight: 6
---

This guide covers using the metrics middleware to automatically collect HTTP metrics.

## Overview

The metrics middleware automatically records metrics for HTTP requests:

- Request duration as histogram.
- Request count as counter.
- Active requests as gauge.
- Request and response sizes as histograms.
- Error counts as counter.

## Basic Usage

Wrap your HTTP handler with the metrics middleware:

```go
package main

import (
    "net/http"
    "rivaas.dev/metrics"
)

func main() {
    // Create recorder
    recorder := metrics.MustNew(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
    )
    defer recorder.Shutdown(context.Background())

    // Create your HTTP handlers
    mux := http.NewServeMux()
    mux.HandleFunc("/", homeHandler)
    mux.HandleFunc("/api/users", usersHandler)
    mux.HandleFunc("/health", healthHandler)

    // Wrap with metrics middleware
    handler := metrics.Middleware(recorder)(mux)

    http.ListenAndServe(":8080", handler)
}
```

## Collected Metrics

The middleware automatically collects:

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `http_request_duration_seconds` | Histogram | method, path, status | Request duration distribution |
| `http_requests_total` | Counter | method, path, status | Total request count |
| `http_requests_active` | Gauge | - | Currently active requests |
| `http_request_size_bytes` | Histogram | method, path | Request body size |
| `http_response_size_bytes` | Histogram | method, path, status | Response body size |
| `http_errors_total` | Counter | method, path, status | HTTP error count |

### Metric Labels

Each metric includes relevant labels:

- **method**: HTTP method like GET, POST, PUT, DELETE.
- **path**: Request path like `/api/users`, `/health`.
- **status**: HTTP status code like `200`, `404`, `500`.

## Path Exclusion

Exclude specific paths from metrics collection to reduce noise and cardinality.

### Exact Path Exclusion

Exclude specific paths:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health", "/metrics", "/ready"),
)(mux)
```

**Use Case**: Health checks, metrics endpoints, readiness probes

### Prefix Exclusion

Exclude all paths with specific prefixes:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePrefixes("/debug/", "/internal/", "/_/"),
)(mux)
```

**Use Case**: Debug endpoints, internal APIs, administrative paths

### Pattern Exclusion

Exclude paths matching regex patterns:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePatterns(
        `^/v[0-9]+/internal/.*`,  // /v1/internal/*, /v2/internal/*
        `^/api/[0-9]+$`,           // /api/123, /api/456 (avoid high cardinality)
    ),
)(mux)
```

**Use Case**: Version-specific internal paths, high-cardinality routes

### Combining Exclusions

Use multiple exclusion strategies together:

```go
handler := metrics.Middleware(recorder,
    // Exact paths
    metrics.WithExcludePaths("/health", "/metrics"),
    
    // Prefixes
    metrics.WithExcludePrefixes("/debug/", "/internal/"),
    
    // Patterns
    metrics.WithExcludePatterns(`^/admin/.*`),
)(mux)
```

## Header Recording

Record specific HTTP headers as metric attributes.

### Basic Header Recording

```go
handler := metrics.Middleware(recorder,
    metrics.WithHeaders("X-Request-ID", "X-Correlation-ID"),
)(mux)
```

Headers are recorded as metric attributes:

```
http_requests_total{
    method="GET",
    path="/api/users",
    status="200",
    x_request_id="abc123",
    x_correlation_id="def456"
} 1
```

### Header Name Normalization

Header names are automatically normalized:
- Converted to lowercase
- Hyphens replaced with underscores

Examples:
- `X-Request-ID` → `x_request_id`
- `Content-Type` → `content_type`
- `User-Agent` → `user_agent`

### Multiple Headers

Record multiple headers:

```go
handler := metrics.Middleware(recorder,
    metrics.WithHeaders(
        "X-Request-ID",
        "X-Correlation-ID", 
        "X-Client-Version",
        "X-API-Key",  // This will be filtered out (sensitive)
    ),
)(mux)
```

## Security

The middleware automatically protects sensitive headers.

### Automatic Header Filtering

These headers are **always filtered** and never recorded as metrics, even if explicitly requested:

- `Authorization`
- `Cookie`
- `Set-Cookie`
- `X-API-Key`
- `X-Auth-Token`
- `Proxy-Authorization`
- `WWW-Authenticate`

### Example

```go
// Only X-Request-ID will be recorded
// Authorization and Cookie are automatically filtered
handler := metrics.Middleware(recorder,
    metrics.WithHeaders(
        "Authorization",      // Filtered
        "X-Request-ID",       // Recorded
        "Cookie",             // Filtered
        "X-Correlation-ID",   // Recorded
    ),
)(mux)
```

### Why Filter Sensitive Headers?

Recording sensitive headers in metrics can:
- Leak authentication credentials
- Expose API keys in monitoring systems
- Violate security policies
- Create compliance issues

**Best Practice**: Only record non-sensitive, low-cardinality headers.

## Complete Example

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
    // Create lifecycle context
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create metrics recorder
    recorder, err := metrics.New(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
        metrics.WithServiceVersion("v1.0.0"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    defer func() {
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        recorder.Shutdown(shutdownCtx)
    }()

    // Create HTTP handlers
    mux := http.NewServeMux()
    
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello, World!"))
    })
    
    mux.HandleFunc("/api/users", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"users": []}`))
    })
    
    mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    })

    // Configure middleware with all options
    handler := metrics.Middleware(recorder,
        // Exclude health and metrics endpoints
        metrics.WithExcludePaths("/health", "/metrics"),
        
        // Exclude debug and internal paths
        metrics.WithExcludePrefixes("/debug/", "/internal/"),
        
        // Exclude admin paths
        metrics.WithExcludePatterns(`^/admin/.*`),
        
        // Record tracing headers
        metrics.WithHeaders("X-Request-ID", "X-Correlation-ID"),
    )(mux)

    // Start HTTP server
    server := &http.Server{
        Addr:    ":8080",
        Handler: handler,
    }
    
    go func() {
        log.Printf("Server listening on :8080")
        if err := server.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()
    
    // Wait for interrupt
    <-ctx.Done()
    log.Println("Shutting down...")
    
    // Graceful shutdown
    shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    server.Shutdown(shutdownCtx)
}
```

## Integration Patterns

### Standalone HTTP Server

```go
mux := http.NewServeMux()
mux.HandleFunc("/", handler)

wrappedHandler := metrics.Middleware(recorder)(mux)

http.ListenAndServe(":8080", wrappedHandler)
```

### With Router Middleware Chain

```go
// Apply metrics middleware first in chain
handler := metrics.Middleware(recorder)(
    loggingMiddleware(
        authMiddleware(mux),
    ),
)
```

### Gorilla Mux

```go
import "github.com/gorilla/mux"

r := mux.NewRouter()
r.HandleFunc("/", homeHandler)
r.HandleFunc("/api/users", usersHandler)

// Wrap the router
handler := metrics.Middleware(recorder)(r)

http.ListenAndServe(":8080", handler)
```

### Chi Router

```go
import "github.com/go-chi/chi/v5"

r := chi.NewRouter()
r.Get("/", homeHandler)
r.Get("/api/users", usersHandler)

// Chi router is already http.Handler
handler := metrics.Middleware(recorder)(r)

http.ListenAndServe(":8080", handler)
```

## Path Cardinality

**Warning**: High-cardinality paths can create excessive metrics.

### Problematic Paths

```go
// DON'T: These create unique paths for each request
/api/users/12345       // User ID in path
/api/orders/abc-123    // Order ID in path
/files/document-xyz    // Document ID in path
```

Each unique path creates separate metric series, leading to:
- Excessive memory usage
- Slow query performance
- Storage bloat

### Solutions

#### 1. Exclude High-Cardinality Paths

```go
handler := metrics.Middleware(recorder,
    // Exclude paths with IDs
    metrics.WithExcludePatterns(
        `^/api/users/[^/]+$`,      // /api/users/{id}
        `^/api/orders/[^/]+$`,     // /api/orders/{id}
        `^/files/[^/]+$`,          // /files/{id}
    ),
)(mux)
```

#### 2. Use Path Normalization

Some routers support path normalization:

```go
// Router provides normalized path
// /api/users/123 → /api/users/{id}
```

Check your router documentation for normalization support.

#### 3. Record Fewer Labels

```go
// Instead of recording full path, use endpoint name
// This requires custom instrumentation
```

## Performance Considerations

### Middleware Overhead

The middleware adds minimal overhead:
- ~1-2 microseconds per request
- Safe for production use
- Thread-safe for concurrent requests

### Memory Usage

Memory usage scales with:
- Number of unique paths
- Number of unique label combinations
- Histogram bucket count

**Best Practice**: Exclude high-cardinality paths.

### CPU Impact

Histogram recording is the most CPU-intensive operation. If needed, adjust bucket count:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    // Fewer buckets = lower CPU overhead
    metrics.WithDurationBuckets(0.01, 0.1, 1, 10),
    metrics.WithServiceName("my-api"),
)
```

## Viewing Metrics

Access metrics via the Prometheus endpoint:

```bash
curl http://localhost:9090/metrics
```

Example output:

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/",status="200"} 42
http_requests_total{method="GET",path="/api/users",status="200"} 128
http_requests_total{method="POST",path="/api/users",status="201"} 15

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",path="/",le="0.005"} 10
http_request_duration_seconds_bucket{method="GET",path="/",le="0.01"} 35
http_request_duration_seconds_bucket{method="GET",path="/",le="0.025"} 42
http_request_duration_seconds_sum{method="GET",path="/"} 0.523
http_request_duration_seconds_count{method="GET",path="/"} 42

# HELP http_requests_active Currently active HTTP requests
# TYPE http_requests_active gauge
http_requests_active 3
```

## Middleware Options Reference

| Option | Description |
|--------|-------------|
| `WithExcludePaths(paths...)` | Exclude exact paths from metrics |
| `WithExcludePrefixes(prefixes...)` | Exclude path prefixes from metrics |
| `WithExcludePatterns(patterns...)` | Exclude paths matching regex patterns |
| `WithHeaders(headers...)` | Record specific headers as metric attributes |

See [Middleware Options Reference](/reference/packages/metrics/middleware-options/) for complete details.

## Next Steps

- Learn [Custom Metrics](../custom-metrics/) to record your own metrics
- See [Testing](../testing/) for middleware testing utilities
- Check [Examples](../examples/) for integration patterns
- Review [Configuration](../configuration/) for histogram bucket tuning
