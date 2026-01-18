---
title: "Debug Endpoints"
linkTitle: "Debug Endpoints"
weight: 10
description: >
  Enable pprof profiling endpoints for performance analysis and debugging.
---

## Overview

The app package provides optional debug endpoints for profiling and diagnostics using Go's `net/http/pprof` package.

⚠️ **Security Warning:** Debug endpoints expose sensitive runtime information and should NEVER be enabled in production without proper security measures.

## Basic Configuration

### Enable pprof Unconditionally

Enable pprof endpoints (development only):

```go
a, err := app.New(
    app.WithDebugEndpoints(
        app.WithPprof(),
    ),
)
```

### Enable pprof Conditionally

Enable based on environment variable (recommended):

```go
a, err := app.New(
    app.WithDebugEndpoints(
        app.WithPprofIf(os.Getenv("PPROF_ENABLED") == "true"),
    ),
)
```

### Custom Prefix

Mount debug endpoints under a custom prefix:

```go
a, err := app.New(
    app.WithDebugEndpoints(
        app.WithDebugPrefix("/_internal/debug"),
        app.WithPprof(),
    ),
)
```

## Available Endpoints

When pprof is enabled, the following endpoints are registered:

| Endpoint | Description |
|----------|-------------|
| `GET /debug/pprof/` | Main pprof index |
| `GET /debug/pprof/cmdline` | Command line invocation |
| `GET /debug/pprof/profile` | CPU profile (30s by default) |
| `GET /debug/pprof/symbol` | Symbol lookup |
| `POST /debug/pprof/symbol` | Symbol lookup (POST) |
| `GET /debug/pprof/trace` | Execution trace |
| `GET /debug/pprof/allocs` | Memory allocations profile |
| `GET /debug/pprof/block` | Block profile |
| `GET /debug/pprof/goroutine` | Goroutine profile |
| `GET /debug/pprof/heap` | Heap profile |
| `GET /debug/pprof/mutex` | Mutex profile |
| `GET /debug/pprof/threadcreate` | Thread creation profile |

## Security Considerations

### Development

Safe to enable unconditionally in development:

```go
a, err := app.New(
    app.WithEnvironment("development"),
    app.WithDebugEndpoints(
        app.WithPprof(),
    ),
)
```

### Staging

Enable behind VPN or IP allowlist:

```go
a, err := app.New(
    app.WithEnvironment("staging"),
    app.WithDebugEndpoints(
        app.WithPprofIf(os.Getenv("PPROF_ENABLED") == "true"),
    ),
)

// Use authentication middleware
a.Use(IPAllowlistMiddleware([]string{"10.0.0.0/8"}))
```

### Production

Enable only with proper authentication:

```go
a, err := app.New(
    app.WithEnvironment("production"),
    app.WithDebugEndpoints(
        app.WithDebugPrefix("/_internal/debug"),
        app.WithPprofIf(os.Getenv("PPROF_ENABLED") == "true"),
    ),
)

// Protect debug endpoints with authentication
debugAuth := a.Group("/_internal", AdminAuthMiddleware())
// pprof endpoints are automatically under this group
```

## Using pprof

### CPU Profile

Capture a 30-second CPU profile:

```bash
curl http://localhost:8080/debug/pprof/profile > cpu.prof
go tool pprof cpu.prof
```

### Heap Profile

Capture current heap allocations:

```bash
curl http://localhost:8080/debug/pprof/heap > heap.prof
go tool pprof heap.prof
```

### Goroutine Profile

View current goroutines:

```bash
curl http://localhost:8080/debug/pprof/goroutine > goroutine.prof
go tool pprof goroutine.prof
```

### Interactive Analysis

Analyze profiles interactively:

```bash
# CPU profile
go tool pprof http://localhost:8080/debug/pprof/profile

# Heap profile
go tool pprof http://localhost:8080/debug/pprof/heap

# Goroutine profile
go tool pprof http://localhost:8080/debug/pprof/goroutine
```

### Web UI

View profiles in a web browser:

```bash
go tool pprof -http=:8081 http://localhost:8080/debug/pprof/profile
```

## Complete Example

```go
package main

import (
    "log"
    "os"
    
    "rivaas.dev/app"
)

func main() {
    env := os.Getenv("ENVIRONMENT")
    if env == "" {
        env = "development"
    }
    
    a, err := app.New(
        app.WithServiceName("api"),
        app.WithEnvironment(env),
        
        // Debug endpoints with conditional pprof
        app.WithDebugEndpoints(
            app.WithDebugPrefix("/_internal/debug"),
            app.WithPprofIf(env == "development" || os.Getenv("PPROF_ENABLED") == "true"),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // In production, protect debug endpoints
    if env == "production" {
        // Add authentication middleware to /_internal/* routes
        a.Use(func(c *app.Context) {
            if strings.HasPrefix(c.Request.URL.Path, "/_internal/") {
                // Verify admin token
                if !isAdmin(c) {
                    c.Forbidden("admin access required")
                    return
                }
            }
            c.Next()
        })
    }
    
    // Register routes...
    
    // Start server...
}
```

## Best Practices

1. **Never enable in production without authentication**
2. **Use environment variables for conditional enablement**
3. **Mount under non-obvious path prefix**
4. **Log when pprof is enabled**
5. **Document security requirements in deployment docs**
6. **Consider using separate admin port**

## Next Steps

- [Health Endpoints](../health-endpoints/) - Configure health checks
- [Server](../server/) - Learn about server configuration
- [Observability](../observability/) - Monitor application performance
