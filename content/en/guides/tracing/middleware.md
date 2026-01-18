---
title: "HTTP Middleware"
description: "Automatically trace HTTP requests with middleware"
weight: 5
---

The tracing package provides HTTP middleware for automatic request tracing with any HTTP framework.

## Basic Usage

Wrap your HTTP handler with tracing middleware:

```go
import (
    "net/http"
    "rivaas.dev/tracing"
)

func main() {
    tracer := tracing.MustNew(
        tracing.WithServiceName("my-api"),
        tracing.WithOTLP("localhost:4317"),
    )
    tracer.Start(context.Background())
    defer tracer.Shutdown(context.Background())

    mux := http.NewServeMux()
    mux.HandleFunc("/api/users", handleUsers)
    
    // Wrap with middleware
    handler := tracing.Middleware(tracer)(mux)
    
    http.ListenAndServe(":8080", handler)
}
```

## Middleware Functions

Two functions are available for creating middleware:

### Middleware (Panics on Error)

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health"),
)(mux)
```

Panics if middleware options are invalid (e.g., invalid regex pattern).

### MustMiddleware (Alias)

```go
handler := tracing.MustMiddleware(tracer,
    tracing.WithExcludePaths("/health"),
)(mux)
```

Identical to `Middleware()` - provided for API consistency with `MustNew()`.

## What Gets Traced

The middleware automatically:

1. **Extracts** trace context from incoming request headers
2. **Creates** a span for the request with standard attributes
3. **Propagates** context to downstream handlers
4. **Records** HTTP method, URL, status code, and duration
5. **Finishes** the span when the request completes

### Standard Attributes

Every traced request includes:

| Attribute | Description | Example |
|-----------|-------------|---------|
| `http.method` | HTTP method | `"GET"` |
| `http.url` | Full URL | `"http://localhost:8080/api/users"` |
| `http.scheme` | URL scheme | `"http"` |
| `http.host` | Host header | `"localhost:8080"` |
| `http.route` | Request path | `"/api/users"` |
| `http.user_agent` | User agent | `"Mozilla/5.0..."` |
| `http.status_code` | Response status | `200` |
| `service.name` | Service name | `"my-api"` |
| `service.version` | Service version | `"v1.0.0"` |

## Path Exclusion

Exclude specific paths from tracing to reduce noise and overhead.

### Exact Path Matching

Exclude specific paths exactly:

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics", "/ready"),
)(mux)
```

Requests to `/health`, `/metrics`, or `/ready` won't create spans.

### Prefix Matching

Exclude all paths with a given prefix:

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePrefixes("/debug/", "/internal/", "/.well-known/"),
)(mux)
```

Excludes:
- `/debug/pprof`
- `/debug/vars`
- `/internal/health`
- `/.well-known/acme-challenge`

### Regex Pattern Matching

Exclude paths matching regex patterns:

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePatterns(
        `^/v[0-9]+/internal/.*`,  // Version-prefixed internal routes
        `^/api/health.*`,          // Any health-related endpoint
    ),
)(mux)
```

**Important**: Invalid regex patterns cause the middleware to panic during initialization.

### Combined Exclusions

Use multiple exclusion types together:

```go
handler := tracing.Middleware(tracer,
    // Exact paths
    tracing.WithExcludePaths("/health", "/metrics"),
    
    // Prefixes
    tracing.WithExcludePrefixes("/debug/", "/internal/"),
    
    // Patterns
    tracing.WithExcludePatterns(`^/v[0-9]+/internal/.*`),
)(mux)
```

### Performance

Path exclusion is highly efficient:

- **Exact paths**: O(1) hash map lookup
- **Prefixes**: O(n) where n = number of prefixes
- **Patterns**: O(p) where p = number of patterns

Even with 100+ excluded paths, overhead is negligible (~9ns per request).

## Header Recording

Record specific request headers as span attributes.

### Basic Header Recording

```go
handler := tracing.Middleware(tracer,
    tracing.WithHeaders("X-Request-ID", "X-Correlation-ID"),
)(mux)
```

Headers are recorded as: `http.request.header.{name}`

Example span attributes:
- `http.request.header.x-request-id`: `"abc123"`
- `http.request.header.x-correlation-id`: `"xyz789"`

### Security

Sensitive headers are **automatically filtered** and never recorded:

- `Authorization`
- `Cookie`
- `Set-Cookie`
- `X-API-Key`
- `X-Auth-Token`
- `Proxy-Authorization`
- `WWW-Authenticate`

This protects against accidental credential exposure in traces.

```go
// This is safe - Authorization header is filtered
handler := tracing.Middleware(tracer,
    tracing.WithHeaders(
        "X-Request-ID",
        "Authorization", // ← Automatically filtered, won't be recorded
        "X-Correlation-ID",
    ),
)(mux)
```

### Header Name Normalization

Header names are case-insensitive and normalized to lowercase:

```go
tracing.WithHeaders("X-Request-ID", "x-correlation-id", "User-Agent")
```

All recorded as lowercase:
- `http.request.header.x-request-id`
- `http.request.header.x-correlation-id`
- `http.request.header.user-agent`

## Query Parameter Recording

Record URL query parameters as span attributes.

### Default Behavior

By default, **all** query parameters are recorded:

```go
handler := tracing.Middleware(tracer)(mux)
// All params recorded by default
```

Request: `GET /api/users?page=2&limit=10&user_id=123`

Span attributes:
- `http.request.param.page`: `["2"]`
- `http.request.param.limit`: `["10"]`
- `http.request.param.user_id`: `["123"]`

### Whitelist Parameters

Record only specific parameters:

```go
handler := tracing.Middleware(tracer,
    tracing.WithRecordParams("page", "limit", "user_id"),
)(mux)
```

Only `page`, `limit`, and `user_id` are recorded. Others are ignored.

### Blacklist Parameters

Exclude sensitive parameters while recording all others:

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludeParams("password", "token", "api_key", "secret"),
)(mux)
```

All parameters recorded **except** `password`, `token`, `api_key`, and `secret`.

### Disable Parameter Recording

Don't record any query parameters:

```go
handler := tracing.Middleware(tracer,
    tracing.WithoutParams(),
)(mux)
```

Useful when parameters may contain sensitive data.

### Combined Parameter Options

```go
// Record only safe parameters, explicitly exclude sensitive ones
handler := tracing.Middleware(tracer,
    tracing.WithRecordParams("page", "limit", "sort"),
    tracing.WithExcludeParams("api_key", "token"), // Takes precedence
)(mux)
```

**Behavior**: Blacklist takes precedence. Even if `api_key` is in the whitelist, it won't be recorded.

## Complete Middleware Example

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    
    "rivaas.dev/tracing"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create tracer
    tracer := tracing.MustNew(
        tracing.WithServiceName("user-api"),
        tracing.WithServiceVersion("v1.2.3"),
        tracing.WithOTLP("localhost:4317"),
        tracing.WithSampleRate(0.1), // 10% sampling
    )
    
    if err := tracer.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer tracer.Shutdown(context.Background())

    // Create HTTP handlers
    mux := http.NewServeMux()
    mux.HandleFunc("/api/users", handleUsers)
    mux.HandleFunc("/api/orders", handleOrders)
    mux.HandleFunc("/health", handleHealth)
    mux.HandleFunc("/metrics", handleMetrics)
    
    // Wrap with tracing middleware
    handler := tracing.MustMiddleware(tracer,
        // Exclude health/metrics endpoints
        tracing.WithExcludePaths("/health", "/metrics", "/ready", "/live"),
        
        // Exclude debug and internal routes
        tracing.WithExcludePrefixes("/debug/", "/internal/"),
        
        // Record correlation headers
        tracing.WithHeaders("X-Request-ID", "X-Correlation-ID", "User-Agent"),
        
        // Whitelist safe parameters
        tracing.WithRecordParams("page", "limit", "sort", "filter"),
        
        // Blacklist sensitive parameters
        tracing.WithExcludeParams("password", "token", "api_key"),
    )(mux)

    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", handler))
}

func handleUsers(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"users": []}`))
}

func handleOrders(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"orders": []}`))
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

func handleMetrics(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/plain")
    w.Write([]byte("# Metrics"))
}
```

## Integration with Custom Context

Access the span from within your handlers:

```go
func handleUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    
    // Add custom attributes to the current span
    tracing.SetSpanAttributeFromContext(ctx, "user.action", "view_profile")
    tracing.SetSpanAttributeFromContext(ctx, "user.id", getUserID(r))
    
    // Add events
    tracing.AddSpanEventFromContext(ctx, "profile_viewed",
        attribute.String("profile_id", "123"),
    )
    
    // Your handler logic...
}
```

## Comparison with Metrics Middleware

The tracing middleware follows the same pattern as the metrics middleware:

| Aspect | Metrics | Tracing |
|--------|---------|---------|
| Main Function | `metrics.Middleware()` | `tracing.Middleware()` |
| Panic Version | `metrics.MustMiddleware()` | `tracing.MustMiddleware()` |
| Path Exclusion | `metrics.WithExcludePaths()` | `tracing.WithExcludePaths()` |
| Prefix Exclusion | `metrics.WithExcludePrefixes()` | `tracing.WithExcludePrefixes()` |
| Regex Exclusion | ✗ Not available | `tracing.WithExcludePatterns()` |
| Header Recording | `metrics.WithHeaders()` | `tracing.WithHeaders()` |
| Parameter Recording | ✗ Not available | `tracing.WithRecordParams()` |

## Performance

| Operation | Time | Memory | Allocations |
|-----------|------|--------|-------------|
| Request overhead (100% sampling) | ~1.6 µs | 2.3 KB | 23 |
| Path exclusion (100 paths) | ~9 ns | 0 B | 0 |
| Start/Finish span | ~160 ns | 240 B | 3 |
| Set attribute | ~3 ns | 0 B | 0 |

## Best Practices

### Always Exclude Health Checks

```go
tracing.WithExcludePaths("/health", "/metrics", "/ready", "/live")
```

Health checks are high-frequency and low-value for tracing.

### Use Sampling for High Traffic

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSampleRate(0.1), // 10% sampling
    tracing.WithOTLP("collector:4317"),
)
```

Reduces overhead and trace storage costs.

### Record Correlation IDs

```go
tracing.WithHeaders("X-Request-ID", "X-Correlation-ID", "X-Trace-ID")
```

Helps correlate traces with logs and other observability data.

### Blacklist Sensitive Parameters

```go
tracing.WithExcludeParams("password", "token", "api_key", "secret", "credit_card")
```

Prevents accidental exposure of credentials in traces.

### Combine with Span Hooks

```go
startHook := func(ctx context.Context, span trace.Span, req *http.Request) {
    // Add business context from request
    if tenantID := extractTenant(req); tenantID != "" {
        span.SetAttributes(attribute.String("tenant.id", tenantID))
    }
}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSpanStartHook(startHook),
    tracing.WithOTLP("collector:4317"),
)
```

## Next Steps

- Learn [Context Propagation](../context-propagation/) for distributed tracing
- Check [Middleware Options](/reference/packages/tracing/middleware-options/) for all options
- See [Examples](../examples/) for production-ready configurations
