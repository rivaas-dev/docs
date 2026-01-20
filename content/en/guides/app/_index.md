---
title: "Application Framework"
linkTitle: "App"
weight: 1
description: >
  A complete web framework built on the Rivaas router. Includes integrated observability, lifecycle management, and sensible defaults for production-ready applications.
---

{{% pageinfo %}}
The Rivaas App package provides a high-level framework with pre-configured observability, graceful shutdown, and common middleware for rapid application development.
{{% /pageinfo %}}

## Overview

The App package is a complete web framework built on top of the Rivaas router. It provides a simple API for building web applications. It includes integrated observability with metrics, tracing, and logging. It has lifecycle management, graceful shutdown, and common middleware patterns.

## Key Features

- **Complete Framework** - Pre-configured with sensible defaults for rapid development.
- **Integrated Observability** - Built-in metrics with Prometheus/OTLP, tracing with OpenTelemetry, and structured logging with slog.
- **Request Binding & Validation** - Automatic request parsing with validation strategies.
- **OpenAPI Generation** - Automatic OpenAPI spec generation with Swagger UI.
- **Lifecycle Hooks** - OnStart, OnReady, OnShutdown, OnStop for initialization and cleanup.
- **Health Endpoints** - Kubernetes-compatible liveness and readiness probes.
- **Graceful Shutdown** - Proper server shutdown with configurable timeouts.
- **Environment-Aware** - Development and production modes with appropriate defaults.

## When to Use

### Use App Package When

- **Building a complete web application** - Need a full framework with all features included.
- **Want integrated observability** - Metrics and tracing configured out of the box.
- **Need quick development** - Sensible defaults help you start immediately.
- **Building a REST API** - Pre-configured with common middleware and patterns.
- **Prefer convention over configuration** - Defaults that work well together.

### Use Router Package Directly When

- **Building a library or framework** - Need full control over the routing layer.
- **Have custom observability setup** - Already using specific metrics or tracing solutions.
- **Maximum performance is critical** - Want zero overhead from default middleware.
- **Need complete flexibility** - Don't want any opinions or defaults imposed.
- **Integrating into existing systems** - Need to fit into established patterns.

**Performance Note:** The app package adds about 1-2% latency compared to using router directly. Latency goes from 119ns to about 121-122ns. However, it provides significant development speed and maintainability benefits. This comes through integrated observability and sensible defaults.

## Quick Start

### Simple Application

Create a minimal application with defaults:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
)

func main() {
    // Create app with defaults
    a, err := app.New()
    if err != nil {
        log.Fatalf("Failed to create app: %v", err)
    }

    // Register routes
    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello from Rivaas App!",
        })
    })

    // Setup graceful shutdown
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    // Start server with graceful shutdown
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatalf("Server error: %v", err)
    }
}
```

### Full-Featured Application

Create a production-ready application with full observability:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
    
    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/metrics"
    "rivaas.dev/tracing"
)

func main() {
    // Create app with full observability
    a, err := app.New(
        app.WithServiceName("my-api"),
        app.WithServiceVersion("v1.0.0"),
        app.WithEnvironment("production"),
        // Observability: logging, metrics, tracing
        app.WithObservability(
            app.WithLogging(logging.WithJSONHandler()),
            app.WithMetrics(), // Prometheus is default
            app.WithTracing(tracing.WithOTLP("localhost:4317")),
            app.WithExcludePaths("/healthz", "/readyz", "/metrics"),
        ),
        // Health endpoints: GET /healthz (liveness), GET /readyz (readiness)
        app.WithHealthEndpoints(
            app.WithHealthTimeout(800 * time.Millisecond),
            app.WithReadinessCheck("database", func(ctx context.Context) error {
                return db.PingContext(ctx)
            }),
        ),
        // Server configuration
        app.WithServer(
            app.WithReadTimeout(15 * time.Second),
            app.WithWriteTimeout(15 * time.Second),
        ),
    )
    if err != nil {
        log.Fatalf("Failed to create app: %v", err)
    }

    // Register routes
    a.GET("/users/:id", func(c *app.Context) {
        userID := c.Param("id")
        
        // Request-scoped logger with automatic context
        c.Logger().Info("processing request", "user_id", userID)
        
        c.JSON(http.StatusOK, map[string]any{
            "user_id":    userID,
            "name":       "John Doe",
            "trace_id":   c.TraceID(),
        })
    })

    // Setup graceful shutdown
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    // Start server
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatalf("Server error: %v", err)
    }
}
```

## Learning Path

Follow this structured path to master the Rivaas App framework:

### 1. Getting Started

Start with the basics:

- [Installation](installation/) - Set up the app package in your project
- [Basic Usage](basic-usage/) - Create your first app and register routes
- [Configuration](configuration/) - Configure service name, version, and environment

### 2. Request Handling

Handle requests effectively:

- [Context](context/) - Use the app context for binding, validation, and error handling
- [Routing](routing/) - Organize routes with groups, versioning, and static files
- [Middleware](middleware/) - Add cross-cutting concerns with built-in middleware

### 3. Observability

Monitor your application:

- [Observability](observability/) - Integrate metrics, tracing, and logging
- [Health Endpoints](health-endpoints/) - Configure liveness and readiness probes
- [Debug Endpoints](debug-endpoints/) - Enable pprof for performance profiling

### 4. Production Readiness

Prepare for production:

- [Lifecycle](lifecycle/) - Use lifecycle hooks for initialization and cleanup
- [Server](server/) - Configure HTTP, HTTPS, and mTLS servers with graceful shutdown
- [OpenAPI](openapi/) - Generate OpenAPI specs and Swagger UI automatically

### 5. Testing & Migration

Test and migrate:

- [Testing](testing/) - Test your routes and handlers without starting a server
- [Migration](migration/) - Migrate from the router package to the app package
- [Examples](examples/) - Complete working examples and patterns

## Common Use Cases

The Rivaas App excels in these scenarios:

- **REST APIs** - Full-featured JSON APIs with observability and validation
- **Microservices** - Cloud-native services with health checks and graceful shutdown
- **Web Applications** - Complete web apps with middleware and lifecycle management
- **Production Services** - Production-ready defaults with integrated monitoring

## Next Steps

- **Installation**: [Install the app package](installation/) and set up your first project
- **Basic Usage**: Follow the [Basic Usage guide](basic-usage/) to learn the fundamentals
- **Examples**: Explore [complete examples](examples/) for common patterns
- **API Reference**: Check the [API Reference](/reference/packages/app/) for detailed documentation

## Need Help?

- **Troubleshooting**: See [Common Issues](/reference/packages/app/troubleshooting/)
- **Examples**: Browse [working examples](examples/)
- **API Docs**: Check [pkg.go.dev](https://pkg.go.dev/rivaas.dev/app)
