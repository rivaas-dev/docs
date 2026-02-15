---
title: Configuration
description: Configure your Rivaas application
weight: 3
keywords:
  - configuration
  - setup
  - options
  - environment
  - functional options
  - settings
---

## Overview

Rivaas uses the **functional options pattern** for configuration. This provides a clean, self-documenting API. It's backward-compatible. This guide covers basic configuration options.

💡 **First Time?** Focus on sections marked with ⭐. Skip advanced topics for now.

## Configuration Philosophy

- **Sensible Defaults**: Works out of the box.
- **Progressive Disclosure**: Start simple. Add complexity as needed.
- **Type Safety**: Configuration errors are caught at startup.
- **Environment Aware**: Different defaults for dev and prod.

---

## ⭐ Basic Configuration

### Service Metadata

Set your service name and version:

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithServiceVersion("v1.2.3"),
    app.WithEnvironment("production"),
)
```

These values are sent to all observability components. This includes logging, metrics, and tracing.

## Advanced: Server Configuration

⚠️ **Advanced Topic**: Most applications don't need custom server configuration. The defaults work for production.

### Timeouts

Configure server timeouts to protect against slow clients:

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithServerConfig(
        app.WithReadTimeout(10 * time.Second),
        app.WithWriteTimeout(15 * time.Second),
        app.WithIdleTimeout(60 * time.Second),
        app.WithShutdownTimeout(30 * time.Second),
    ),
)
```

**Timeout Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `WithReadTimeout` | Maximum time to read request | 10s |
| `WithWriteTimeout` | Maximum time to write response | 10s |
| `WithIdleTimeout` | Maximum idle connection time | 60s |
| `WithReadHeaderTimeout` | Maximum time to read headers | 2s |
| `WithShutdownTimeout` | Graceful shutdown timeout | 30s |

### Request Limits

Configure request size limits:

```go
app.WithServerConfig(
    app.WithMaxHeaderBytes(1 << 20), // 1MB
)
```

## ⭐ Environment Modes

Rivaas supports two environment modes with different defaults:

### Development Mode (Default)

```go
a := app.MustNew(
    app.WithEnvironment("development"),
)
```

Features:
- Verbose logging enabled
- Access logging for all requests
- Development-friendly error messages
- Pretty-printed JSON logs

### Production Mode

```go
a := app.MustNew(
    app.WithEnvironment("production"),
)
```

Features:
- Error-only logging
- JSON structured logs
- Minimal overhead
- Production-ready defaults

## Observability

💡 **Note**: This section covers observability setup. For detailed observability patterns, see the [Observability Guide](/guides/app/observability/).

Enable logging, metrics, and tracing:

```go
import (
    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/metrics"
    "rivaas.dev/tracing"
)

a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
        app.WithMetrics(),
        app.WithTracing(tracing.WithStdout()),
    ),
)
```

### Logging Options

```go
app.WithLogging(
    logging.WithJSONHandler(),              // JSON output
    logging.WithLevel(logging.LevelInfo),   // Log level
)

// Or use console handler (development)
app.WithLogging(logging.WithConsoleHandler())
```

### Metrics Options

```go
// Prometheus metrics (default)
app.WithMetrics()

// Custom Prometheus endpoint
app.WithMetrics(
    metrics.WithPrometheus(":9090", "/metrics"),
)

// OTLP metrics
app.WithMetrics(
    metrics.WithOTLP("localhost:4317"),
)
```

### Tracing Options

```go
// Stdout tracing (development)
app.WithTracing(tracing.WithStdout())

// OTLP tracing (production)
app.WithTracing(
    tracing.WithOTLP("jaeger:4317"),
    tracing.WithSampleRate(0.1), // Sample 10% of requests
)
```

### Exclude Paths from Observability

Exclude health checks and static paths from logging/metrics/tracing:

```go
app.WithObservability(
    app.WithLogging(),
    app.WithMetrics(),
    app.WithTracing(),
    app.WithExcludePaths("/livez", "/readyz", "/metrics"),
    app.WithExcludePrefixes("/static", "/assets"),
)
```

## ⭐ Health Endpoints

Add Kubernetes-compatible health endpoints:

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithHealthEndpoints(
        app.WithLivenessCheck("process", func(ctx context.Context) error {
            return nil // Process is alive
        }),
        app.WithReadinessCheck("database", func(ctx context.Context) error {
            return db.PingContext(ctx) // Check DB connection
        }),
    ),
)
```

This registers:
- `GET /livez` — Liveness probe
- `GET /readyz` — Readiness probe

### Custom Health Paths

```go
app.WithHealthEndpoints(
    app.WithHealthPrefix("/_system"),       // Prefix: /_system/livez
    app.WithLivezPath("/live"),             // Custom path: /_system/live
    app.WithReadyzPath("/ready"),           // Custom path: /_system/ready
    app.WithHealthTimeout(500 * time.Millisecond),
)
```

## Advanced: Debug Endpoints

⚠️ **Security Critical**: Only enable pprof in controlled environments.

Enable pprof for profiling (use with caution):

```go
// Enable conditionally (recommended for production)
app.WithDebugEndpoints(
    app.WithPprofIf(os.Getenv("PPROF_ENABLED") == "true"),
)

// Always enable (development only)
app.WithDebugEndpoints(
    app.WithPprof(),
)
```

⚠️ **Security Warning:** Never expose pprof endpoints in production without proper authentication.

## Advanced: Middleware Configuration

Add middleware during initialization or after app creation:

```go
import (
    "rivaas.dev/router/middleware/cors"
    "rivaas.dev/router/middleware/requestid"
)

a := app.MustNew(
    app.WithServiceName("my-api"),
)

// Add middleware after creation
a.Use(requestid.New())
a.Use(cors.New(
    cors.WithAllowedOrigins([]string{"https://example.com"}),
))
```

Or during initialization:

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithMiddleware(
        requestid.New(),
        cors.New(cors.WithAllowAllOrigins(true)),
    ),
)
```

💡 **Learn More**: See the [Middleware Guide](../middleware/) for detailed middleware usage patterns.

## Complete Example

Here's a production-ready configuration:

```go
package main

import (
    "context"
    "log"
    "os"
    "time"

    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/metrics"
    "rivaas.dev/tracing"
    "rivaas.dev/router/middleware/cors"
    "rivaas.dev/router/middleware/requestid"
)

func main() {
    a := app.MustNew(
        // Service metadata
        app.WithServiceName("my-api"),
        app.WithServiceVersion("v1.0.0"),
        app.WithEnvironment("production"),

        // Server configuration
        app.WithServerConfig(
            app.WithReadTimeout(10 * time.Second),
            app.WithWriteTimeout(15 * time.Second),
            app.WithShutdownTimeout(30 * time.Second),
        ),

        // Observability
        app.WithObservability(
            app.WithLogging(logging.WithJSONHandler()),
            app.WithMetrics(metrics.WithPrometheus(":9090", "/metrics")),
            app.WithTracing(tracing.WithOTLP("jaeger:4317")),
            app.WithExcludePaths("/livez", "/readyz", "/metrics"),
        ),

        // Health checks
        app.WithHealthEndpoints(
            app.WithReadinessCheck("database", checkDatabase),
        ),

        // Debug (conditional)
        app.WithDebugEndpoints(
            app.WithPprofIf(os.Getenv("PPROF_ENABLED") == "true"),
        ),
    )

    // Add middleware
    a.Use(requestid.New())
    a.Use(cors.New(cors.WithAllowedOrigins([]string{
        "https://example.com",
    })))

    // Register routes
    a.GET("/", handleRoot)

    // Start server
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    if err := a.Start(ctx); err != nil {
        log.Fatal(err)
    }
}

func checkDatabase(ctx context.Context) error {
    // Implement your database check
    return nil
}

func handleRoot(c *app.Context) {
    c.JSON(200, map[string]string{"status": "ok"})
}
```

## Advanced: Configuration Validation

Rivaas validates configuration at startup and returns clear errors:

```go
a, err := app.New(
    app.WithServerConfig(
        app.WithReadTimeout(15 * time.Second),
        app.WithWriteTimeout(10 * time.Second), // ❌ Read > Write
    ),
)
if err != nil {
    // Error: "server.readTimeout: read timeout should not exceed write timeout"
}
```

## Advanced: Environment Variables

While Rivaas doesn't directly use environment variables, you can easily integrate them:

```go
import "os"

func getEnv(key, fallback string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return fallback
}

a := app.MustNew(
    app.WithServiceName(getEnv("SERVICE_NAME", "my-api")),
    app.WithServiceVersion(getEnv("SERVICE_VERSION", "v1.0.0")),
    app.WithEnvironment(getEnv("ENVIRONMENT", "development")),
)
```

## Next Steps

Now that you understand configuration, explore these topics:

- **[Middleware Guide](../middleware/)** — Add functionality with middleware
- **[Next Steps](../next-steps/)** — Continue your learning journey
- **[Routing Guide](/guides/router/)** — Advanced routing patterns
- **[Observability Guide](/guides/app/observability/)** — Deep dive into logging, metrics, tracing
- **[Package Documentation](/reference/packages/app/)** — Complete API reference

## Reference

For a complete list of all configuration options, see the [App Options Reference](/reference/packages/app/options/).

