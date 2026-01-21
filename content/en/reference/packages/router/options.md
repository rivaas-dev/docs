---
title: "Router Options"
linkTitle: "Options"
keywords:
  - router options
  - configuration
  - options reference
  - functional options
weight: 20
description: >
  Configuration options for Router initialization.
---

Router options are passed to `router.New()` or `router.MustNew()` to configure the router.

## Router Creation

```go
// With error handling
r, err := router.New(opts...)
if err != nil {
    log.Fatalf("Failed to create router: %v", err)
}

// Panics on invalid configuration. Use at startup.
r := router.MustNew(opts...)
```

## Versioning Options

### `WithVersioning(opts ...version.Option)`

Configures API versioning support using functional options from the `version` package.

```go
import "rivaas.dev/router/version"

r := router.MustNew(
    router.WithVersioning(
        version.WithHeaderDetection("X-API-Version"),
        version.WithDefault("v1"),
    ),
)
```

**With multiple detection strategies:**

```go
r := router.MustNew(
    router.WithVersioning(
        version.WithPathDetection("/api/v{version}"),
        version.WithHeaderDetection("X-API-Version"),
        version.WithQueryDetection("v"),
        version.WithDefault("v2"),
        version.WithResponseHeaders(),
        version.WithSunsetEnforcement(),
    ),
)
```

## Diagnostic Options

### `WithDiagnostics(handler DiagnosticHandler)`

Sets a diagnostic handler for informational events like header injection attempts or configuration warnings.

```go
import "log/slog"

handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    slog.Warn(e.Message, "kind", e.Kind, "fields", e.Fields)
})

r := router.MustNew(router.WithDiagnostics(handler))
```

**With metrics:**

```go
handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    metrics.Increment("router.diagnostics", "kind", string(e.Kind))
})
```

## Server Options

### `WithH2C(enable bool)`

Enables HTTP/2 Cleartext (h2c) support.

{{% alert title="Security Warning" color="warning" %}}
Only use in development or behind a trusted load balancer. DO NOT enable on public-facing servers without TLS.
{{% /alert %}}

```go
r := router.MustNew(router.WithH2C(true))
```

### `WithServerTimeouts(readHeader, read, write, idle time.Duration)`

Configures HTTP server timeouts to prevent slowloris attacks and resource exhaustion.

**Defaults (if not set):**
- ReadHeaderTimeout: 5s
- ReadTimeout: 15s
- WriteTimeout: 30s
- IdleTimeout: 60s

```go
r := router.MustNew(router.WithServerTimeouts(
    10*time.Second,  // ReadHeaderTimeout
    30*time.Second,  // ReadTimeout
    60*time.Second,  // WriteTimeout
    120*time.Second, // IdleTimeout
))
```

## Performance Options

### `WithRouteCompilation(enabled bool)` / `WithoutRouteCompilation()`

Controls compiled route matching. When enabled (default), routes are pre-compiled for faster lookup.

```go
// Enabled by default
r := router.MustNew(router.WithRouteCompilation(true))

// Disable for debugging
r := router.MustNew(router.WithoutRouteCompilation())
```

### `WithBloomFilterSize(size uint64)`

Sets the bloom filter size for compiled routes. Larger sizes reduce false positives.

**Default:** 1000  
**Recommended:** 2-3x the number of static routes

```go
r := router.MustNew(router.WithBloomFilterSize(2000)) // For ~1000 routes
```

### `WithBloomFilterHashFunctions(numFuncs int)`

Sets the number of hash functions for bloom filters.

**Default:** 3  
**Range:** 1-10 (clamped)

```go
r := router.MustNew(router.WithBloomFilterHashFunctions(4))
```

### `WithCancellationCheck(enabled bool)` / `WithoutCancellationCheck()`

Controls context cancellation checking in the middleware chain. When enabled (default), the router checks for canceled contexts between handlers.

```go
// Enabled by default
r := router.MustNew(router.WithCancellationCheck(true))

// Disable if you handle cancellation manually
r := router.MustNew(router.WithoutCancellationCheck())
```

## Complete Example

```go
package main

import (
    "log/slog"
    "net/http"
    "os"
    "time"
    
    "rivaas.dev/router"
    "rivaas.dev/router/version"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    
    // Diagnostic handler
    diagHandler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
        logger.Warn(e.Message, "kind", e.Kind, "fields", e.Fields)
    })
    
    // Create router with options
    r := router.MustNew(
        // Versioning
        router.WithVersioning(
            version.WithHeaderDetection("API-Version"),
            version.WithDefault("v1"),
        ),
        
        // Server configuration
        router.WithServerTimeouts(
            10*time.Second,
            30*time.Second,
            60*time.Second,
            120*time.Second,
        ),
        
        // Performance tuning
        router.WithBloomFilterSize(2000),
        
        // Diagnostics
        router.WithDiagnostics(diagHandler),
    )
    
    r.GET("/", func(c *router.Context) {
        c.JSON(200, map[string]string{"message": "Hello"})
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Observability Options

{{% alert title="Note" color="info" %}}
For tracing, metrics, and logging configuration, use the [app package](/reference/packages/app/) which provides `WithObservability()`, `WithTracing()`, `WithMetrics()`, and `WithLogging()` options. These options configure the full observability stack and integrate with the router automatically.
{{% /alert %}}

```go
import (
    "rivaas.dev/app"
    "rivaas.dev/tracing"
    "rivaas.dev/metrics"
)

application := app.New(
    app.WithServiceName("my-api"),
    app.WithObservability(
        app.WithTracing(tracing.WithSampleRate(0.1)),
        app.WithMetrics(metrics.WithPrometheus()),
        app.WithExcludePaths("/health", "/metrics"),
    ),
)
```

## Next Steps

- **API Reference**: See [core types and methods](../api-reference/)
- **Diagnostics**: Learn about [diagnostic events](../diagnostics/)
- **Context API**: Check [Context methods](../context-api/)
- **App Package**: See [app observability options](/reference/packages/app/)
