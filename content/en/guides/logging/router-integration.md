---
title: "Router Integration"
description: "Integrate logging with Rivaas router and the app package for full observability"
weight: 9
keywords:
  - logging router
  - http logging
  - access logs
  - router integration
---

This guide covers integrating the logging package with the Rivaas router and the app package for comprehensive observability.

## Overview

The logging package integrates seamlessly with the Rivaas ecosystem:

- **Router** - Set logger via `SetLogger()` method
- **App package** - Automatic wiring with metrics and tracing
- **Context propagation** - Automatic context-aware logging
- **Middleware** - Access log and custom middleware support

## Basic Router Integration

Set a logger on the router to enable request logging.

### Simple Integration

```go
import (
    "rivaas.dev/router"
    "rivaas.dev/logging"
)

func main() {
    // Create logger
    logger := logging.MustNew(
        logging.WithConsoleHandler(),
        logging.WithDebugLevel(),
    )
    
    // Create router and set logger
    r := router.MustNew()
    r.SetLogger(logger)
    
    r.GET("/", func(c *router.Context) {
        c.Logger().Info("handling request")
        c.JSON(200, map[string]string{"status": "ok"})
    })
    
    r.Run(":8080")
}
```

### Accessing Logger in Handlers

The router context provides a logger instance:

```go
r.GET("/api/users/:id", func(c *router.Context) {
    userID := c.Param("id")
    
    // Get logger from context
    log := c.Logger()
    log.Info("fetching user", "user_id", userID)
    
    user, err := fetchUser(userID)
    if err != nil {
        log.Error("failed to fetch user", "error", err, "user_id", userID)
        c.JSON(500, gin.H{"error": "internal server error"})
        return
    }
    
    c.JSON(200, user)
})
```

## App Package Integration

The app package provides batteries-included observability wiring.

### Full Observability Setup

```go
import (
    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/tracing"
)

func main() {
    a, err := app.New(
        app.WithServiceName("my-api"),
        app.WithObservability(
            app.WithLogging(
                logging.WithJSONHandler(),
                logging.WithLevel(logging.LevelInfo),
            ),
            app.WithMetrics(), // Prometheus is default
            app.WithTracing(
                tracing.WithOTLP("localhost:4317"),
            ),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer a.Shutdown(context.Background())
    
    // Get router with logging, metrics, and tracing configured
    router := a.Router()
    
    router.GET("/api/users", func(c *router.Context) {
        // Logger automatically includes trace_id and span_id
        c.Logger().Info("fetching users")
        c.JSON(200, fetchUsers())
    })
    
    a.Run(":8080")
}
```

**Benefits:**
- Automatic service metadata (name, version, environment)
- Trace correlation (logs include trace_id and span_id)
- Metrics integration (log metrics alongside custom metrics)
- Graceful shutdown handling

### Component Access

Access observability components from the app:

```go
a, _ := app.New(
    app.WithServiceName("my-api"),
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
        app.WithMetrics(),
        app.WithTracing(tracing.WithOTLP("localhost:4317")),
    ),
)

// Access components
logger := a.Logger()
router := a.Router()
tracer := a.Tracer()
metrics := a.Metrics()

// Use logger directly
logger.Info("application started", "port", 8080)
```

## Context-Aware Logging

Router contexts automatically support trace correlation.

### Automatic Trace Correlation

```go
r.GET("/api/process", func(c *router.Context) {
    // Logger from context is automatically trace-aware
    log := c.Logger()
    
    log.Info("processing started")
    // Output includes trace_id and span_id if tracing enabled
    
    result := processData()
    
    log.Info("processing completed", "items", result.Count)
})
```

**Output (with tracing enabled):**
```json
{
  "level": "INFO",
  "msg": "processing started",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "service": "my-api"
}
```

### Manual Context Logger

Create a context logger explicitly:

```go
r.GET("/api/data", func(c *router.Context) {
    // Get base logger
    baseLogger := a.Logger()
    
    // Create context logger with trace info
    cl := logging.NewContextLogger(c.Request.Context(), baseLogger)
    
    cl.Info("processing request")
})
```

## Access Log Middleware

The router includes built-in access log middleware.

### Enable Access Logging

```go
import "rivaas.dev/router/middleware/accesslog"

r := router.MustNew()
logger := logging.MustNew(logging.WithJSONHandler())
r.SetLogger(logger)

// Enable access logging
r.Use(accesslog.New())

r.GET("/", func(c *router.Context) {
    c.JSON(200, gin.H{"status": "ok"})
})
```

**Output:**
```json
{
  "level": "INFO",
  "msg": "http request",
  "method": "GET",
  "path": "/",
  "status": 200,
  "duration_ms": 5,
  "bytes": 18,
  "remote": "192.168.1.1:54321",
  "user_agent": "Mozilla/5.0..."
}
```

### Customize Access Logs

Exclude specific paths from access logs:

```go
r.Use(accesslog.New(
    accesslog.WithExcludePaths("/health", "/metrics", "/ready"),
))
```

Add custom fields:

```go
r.Use(accesslog.New(
    accesslog.WithFields(func(c *router.Context) map[string]any {
        return map[string]any{
            "api_version": c.GetHeader("X-API-Version"),
            "client_id": c.GetHeader("X-Client-ID"),
        }
    }),
))
```

## Environment Variables

Configure logging via environment variables.

### Standard OpenTelemetry Variables

```bash
# Service identification
export OTEL_SERVICE_NAME=my-api
export OTEL_SERVICE_VERSION=v1.0.0
export RIVAAS_ENVIRONMENT=production
```

The app package automatically reads these:

```go
a, _ := app.New(
    // Service name from OTEL_SERVICE_NAME
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
    ),
)

logger := a.Logger()
logger.Info("service started")
// Automatically includes service="my-api", version="v1.0.0", env="production"
```

### Custom Environment Configuration

```go
func createLogger() *logging.Logger {
    var opts []logging.Option
    
    // Handler based on environment
    switch os.Getenv("ENV") {
    case "development":
        opts = append(opts, logging.WithConsoleHandler())
    default:
        opts = append(opts, logging.WithJSONHandler())
    }
    
    // Level from environment
    logLevel := os.Getenv("LOG_LEVEL")
    switch logLevel {
    case "debug":
        opts = append(opts, logging.WithDebugLevel())
    case "warn":
        opts = append(opts, logging.WithLevel(logging.LevelWarn))
    case "error":
        opts = append(opts, logging.WithLevel(logging.LevelError))
    default:
        opts = append(opts, logging.WithLevel(logging.LevelInfo))
    }
    
    // Service metadata
    opts = append(opts,
        logging.WithServiceName(os.Getenv("SERVICE_NAME")),
        logging.WithServiceVersion(os.Getenv("SERVICE_VERSION")),
        logging.WithEnvironment(os.Getenv("ENV")),
    )
    
    return logging.MustNew(opts...)
}
```

## Custom Middleware

Create custom logging middleware for specialized needs.

### Request ID Middleware

```go
func requestIDMiddleware(logger *logging.Logger) router.HandlerFunc {
    return func(c *router.Context) {
        requestID := c.GetHeader("X-Request-ID")
        if requestID == "" {
            requestID = generateRequestID()
        }
        
        // Add request ID to request context
        ctx := c.Request.Context()
        ctx = context.WithValue(ctx, "request_id", requestID)
        
        // Create logger with request ID
        reqLogger := logger.With("request_id", requestID)
        ctx = context.WithValue(ctx, "logger", reqLogger)
        c.Request = c.Request.WithContext(ctx)
        
        c.Next()
    }
}

// Usage
r.Use(requestIDMiddleware(logger))
```

### User Context Middleware

```go
func userContextMiddleware() router.HandlerFunc {
    return func(c *router.Context) {
        userID := extractUserID(c)
        
        if userID != "" {
            // Add user ID to logger
            log := c.Logger().With("user_id", userID)
            ctx := context.WithValue(c.Request.Context(), "logger", log)
            c.Request = c.Request.WithContext(ctx)
        }
        
        c.Next()
    }
}
```

### Error Logging Middleware

```go
func errorLoggingMiddleware() router.HandlerFunc {
    return func(c *router.Context) {
        c.Next()
        
        // Log errors after handler completes
        if c.HasErrors() {
            log := c.Logger()
            for _, err := range c.Errors() {
                log.Error("request error",
                    "error", err.Error(),
                    "type", err.Type,
                    "path", c.Request.URL.Path,
                )
            }
        }
    }
}
```

## Complete Integration Example

Putting it all together:

```go
package main

import (
    "context"
    "os"
    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/tracing"
    "rivaas.dev/router/middleware/accesslog"
)

func main() {
    // Initialize app with full observability
    a, err := app.New(
        app.WithServiceName("payment-api"),
        app.WithServiceVersion("v2.1.0"),
        app.WithObservability(
            app.WithLogging(
                logging.WithJSONHandler(),
                logging.WithLevel(logging.LevelInfo),
                logging.WithEnvironment(os.Getenv("ENV")),
            ),
            app.WithMetrics(),
            app.WithTracing(
                tracing.WithOTLP("localhost:4317"),
            ),
        ),
    )
    if err != nil {
        panic(err)
    }
    defer a.Shutdown(context.Background())
    
    router := a.Router()
    logger := a.Logger()
    
    // Add middleware
    router.Use(accesslog.New(
        accesslog.WithExcludePaths("/health", "/ready"),
    ))
    
    // Health endpoint (no logging)
    router.GET("/health", func(c *router.Context) {
        c.JSON(200, gin.H{"status": "healthy"})
    })
    
    // API endpoints (with logging and tracing)
    api := router.Group("/api/v1")
    {
        api.POST("/payments", func(c *router.Context) {
            log := c.Logger()
            log.Info("payment request received")
            
            var payment Payment
            if err := c.BindJSON(&payment); err != nil {
                log.Error("invalid payment request", "error", err)
                c.JSON(400, gin.H{"error": "invalid request"})
                return
            }
            
            result, err := processPayment(c.Request.Context(), payment)
            if err != nil {
                log.Error("payment processing failed", 
                    "error", err,
                    "payment_id", payment.ID,
                )
                c.JSON(500, gin.H{"error": "processing failed"})
                return
            }
            
            log.Info("payment processed successfully",
                "payment_id", payment.ID,
                "amount", payment.Amount,
                "status", result.Status,
            )
            
            c.JSON(200, result)
        })
    }
    
    // Start server
    logger.Info("starting server", "port", 8080)
    if err := a.Run(":8080"); err != nil {
        logger.Error("server error", "error", err)
    }
}
```

## Best Practices

### Per-Request Loggers

Create request-scoped loggers with context:

```go
r.GET("/api/data", func(c *router.Context) {
    log := c.Logger().With(
        "request_id", c.GetHeader("X-Request-ID"),
        "user_id", extractUserID(c),
    )
    
    log.Info("request started")
    // All subsequent logs include request_id and user_id
    log.Info("processing")
    log.Info("request completed")
})
```

### Structured Context

Add structured context early in request lifecycle:

```go
func contextMiddleware() router.HandlerFunc {
    return func(c *router.Context) {
        log := c.Logger().With(
            "path", c.Request.URL.Path,
            "method", c.Request.Method,
            "request_id", c.Request.Header.Get("X-Request-ID"),
        )
        ctx := context.WithValue(c.Request.Context(), "logger", log)
        c.Request = c.Request.WithContext(ctx)
        c.Next()
    }
}
```

### Avoid Logging in Hot Paths

Use access log middleware instead of manual logging:

```go
// BAD - manual logging in every handler
r.GET("/api/users", func(c *router.Context) {
    log := c.Logger()
    log.Info("request", "path", c.Request.URL.Path) // Duplicate
    // ... handle request
    log.Info("response", "status", 200) // Use access log instead
})

// GOOD - use access log middleware
r.Use(accesslog.New())
r.GET("/api/users", func(c *router.Context) {
    // Handle request - logging handled by middleware
})
```

## Next Steps

- Learn [Testing](../testing/) for test utilities
- Review [Best Practices](../best-practices/) for production patterns
- Explore [Examples](../examples/) for real-world patterns

For API details, see the [API Reference](/reference/packages/logging/api-reference/).
