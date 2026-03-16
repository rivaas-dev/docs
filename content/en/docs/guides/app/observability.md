---
title: "Observability"
linkTitle: "Observability"
weight: 4
keywords:
  - app observability
  - metrics
  - tracing
  - logging
  - opentelemetry
description: >
  Integrate metrics, tracing, and logging for complete application observability.
---

## Overview

The app package provides unified configuration for the three pillars of observability:

- **Metrics** - Prometheus or OTLP metrics with automatic HTTP instrumentation.
- **Tracing** - OpenTelemetry distributed tracing with context propagation.
- **Logging** - Structured logging with slog that includes request-scoped fields.

All three pillars use the same functional options pattern. They automatically receive service metadata (name and version) from app-level configuration.

## Environment Variable Configuration

You can configure observability using environment variables. This is useful for container deployments and following 12-factor app principles.

See [Environment Variables](../environment-variables/) for the complete guide.

Quick example:

```bash
export RIVAAS_METRICS_EXPORTER=prometheus
export RIVAAS_TRACING_EXPORTER=otlp
export RIVAAS_TRACING_ENDPOINT=localhost:4317
export RIVAAS_LOG_LEVEL=info
export RIVAAS_LOG_FORMAT=json
```

```go
app, err := app.New(
    app.WithServiceName("my-api"),
    app.WithEnv(), // Reads environment variables
)
```

Environment variables override code configuration, making it easy to deploy the same code to different environments.

## Unified Observability Configuration

Configure all three pillars in one place.

```go
a, err := app.New(
    app.WithServiceName("orders-api"),
    app.WithServiceVersion("v1.2.3"),
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
        app.WithMetrics(), // Prometheus is default
        app.WithTracing(tracing.WithOTLP("localhost:4317")),
    ),
)
```

## Logging

### Basic Logging

Enable structured logging with slog:

```go
a, err := app.New(
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
    ),
)
```

When logging is enabled, the app sets the **slog default logger** at startup. All `slog` calls (in handlers and elsewhere) then use your app's configured handler, level, and format. In handlers, pass `c.RequestContext()` for trace correlation; outside handlers, use `slog.Info(...)` or `slog.InfoContext(ctx, ...)`. Use `app.BaseLogger()` when you need the logger instance (e.g. `logger.With("component", "x")`).

### Log Handlers

Choose from different log handlers.

```go
// JSON handler (production)
app.WithLogging(logging.WithJSONHandler())

// Console handler (development)
app.WithLogging(logging.WithConsoleHandler())

// Text handler
app.WithLogging(logging.WithTextHandler())
```

### Log Levels

Configure log level:

```go
app.WithLogging(
    logging.WithJSONHandler(),
    logging.WithLevel(slog.LevelDebug),
)
```

### Request-Scoped Logging

Pass the request context when you log so trace IDs are attached automatically:

```go
a.GET("/orders/:id", func(c *app.Context) {
    orderID := c.Param("id")
    
    slog.InfoContext(c.RequestContext(), "processing order",
        slog.String("order.id", orderID),
    )
    
    slog.DebugContext(c.RequestContext(), "fetching from database")
    
    c.JSON(http.StatusOK, map[string]string{
        "order_id": orderID,
    })
})
```

Handler log lines stay lean: they include `trace_id` and `span_id` (when tracing is enabled) plus whatever attributes you add. HTTP details (method, route, client IP, etc.) are in the access log, not in every handler log.

Example handler log line:

```json
{
  "time": "2024-01-18T10:30:00Z",
  "level": "INFO",
  "msg": "processing order",
  "trace_id": "abc...",
  "span_id": "def...",
  "order.id": "123"
}
```

## Metrics

### Prometheus Metrics (Default)

Enable Prometheus metrics on a separate server:

```go
a, err := app.New(
    app.WithObservability(
        app.WithMetrics(), // Default: Prometheus on :9090/metrics
    ),
)
```

### Custom Prometheus Configuration

Configure Prometheus address and path:

```go
a, err := app.New(
    app.WithObservability(
        app.WithMetrics(metrics.WithPrometheus(":9091", "/custom-metrics")),
    ),
)
```

### Mount Metrics on Main Router

Mount metrics endpoint on the main HTTP server:

```go
a, err := app.New(
    app.WithObservability(
        app.WithMetricsOnMainRouter("/metrics"),
    ),
)
// Metrics available at http://localhost:8080/metrics
```

### OTLP Metrics

Send metrics via OTLP to collectors like Prometheus, Grafana, or Datadog:

```go
a, err := app.New(
    app.WithObservability(
        app.WithMetrics(metrics.WithOTLP("localhost:4317")),
    ),
)
```

### Custom Metrics in Handlers

These methods are part of `app.Context`. They use the metrics and tracing you set up with `app.WithObservability()`. If observability is not configured, the methods simply do nothing (no-ops).

Record custom metrics in your handlers:

```go
a.GET("/orders/:id", func(c *app.Context) {
    orderID := c.Param("id")
    
    // Increment counter by 1
    c.IncrementCounter("order.lookups",
        attribute.String("order.id", orderID),
    )
    
    // Add to counter by an arbitrary amount
    c.AddCounter("bytes_processed", 1024, attribute.String("type", "upload"))
    
    // Record histogram
    c.RecordHistogram("order.processing_time", 0.250,
        attribute.String("order.id", orderID),
    )
    
    c.SetGauge("queue_size", 10)
    
    c.JSON(http.StatusOK, order)
})
```

## Tracing

Request spans use the same semantics as the tracing package: W3C trace context extraction, sampling (e.g. `WithSampleRate`), and standard HTTP attributes (`http.method`, `http.url`, `http.route`, `http.status_code`, `service.name`, etc.).

### OpenTelemetry Tracing

Enable OpenTelemetry tracing with OTLP exporter:

```go
a, err := app.New(
    app.WithObservability(
        app.WithTracing(tracing.WithOTLP("localhost:4317")),
    ),
)
```

### Stdout Tracing (Development)

Use stdout tracing for development:

```go
a, err := app.New(
    app.WithObservability(
        app.WithTracing(tracing.WithStdout()),
    ),
)
```

### Sample Rate

Configure trace sampling:

```go
a, err := app.New(
    app.WithObservability(
        app.WithTracing(
            tracing.WithOTLP("localhost:4317"),
            tracing.WithSampleRate(0.1), // Sample 10% of requests
        ),
    ),
)
```

### Span Attributes in Handlers

Add span attributes and events in your handlers:

```go
a.GET("/orders/:id", func(c *app.Context) {
    orderID := c.Param("id")
    
    // Add span attribute
    c.SetSpanAttribute("order.id", orderID)
    
    // Add span event
    c.AddSpanEvent("order_lookup_started")
    
    // Fetch order...
    
    c.AddSpanEvent("order_lookup_completed")
    
    c.JSON(http.StatusOK, order)
})
```

### Custom child spans

Create child spans (e.g. for a database query or external call) with `StartSpan` and `FinishSpan`—the single, discoverable way to create and end child spans from handlers:

```go
a.GET("/orders/:id", func(c *app.Context) {
    ctx, span := c.StartSpan("db-query")
    defer c.FinishSpan(span, 0)
    // use ctx for the operation so the child span is the active span
    order, err := db.GetByID(ctx, c.Param("id"))
    if err != nil {
        c.InternalError(err)
        return
    }
    c.JSON(http.StatusOK, order)
})
```

Use `Tracer()` only for **advanced** use—for example, when you need to pass the tracer to another library (e.g. a DB driver or HTTP client) or use tracer-specific options (inject/extract).

### Accessing Trace IDs

Get the current trace ID for correlation:

```go
a.GET("/orders/:id", func(c *app.Context) {
    traceID := c.TraceID()
    
    c.JSON(http.StatusOK, map[string]string{
        "order_id": orderID,
        "trace_id": traceID,
    })
})
```

## Service Metadata Injection

Service name and version are automatically injected into all observability components:

```go
a, err := app.New(
    app.WithServiceName("orders-api"),
    app.WithServiceVersion("v1.2.3"),
    app.WithObservability(
        app.WithLogging(),   // Automatically gets service metadata
        app.WithMetrics(),   // Automatically gets service metadata
        app.WithTracing(),   // Automatically gets service metadata
    ),
)
```

You don't need to pass service name/version explicitly - the app injects them automatically.

### Overriding Service Metadata

If needed, you can override service metadata for specific components:

```go
a, err := app.New(
    app.WithServiceName("orders-api"),
    app.WithServiceVersion("v1.2.3"),
    app.WithObservability(
        app.WithLogging(
            logging.WithServiceName("custom-logger"), // Overrides injected value
        ),
    ),
)
```

## Path Filtering

Exclude specific paths from observability (metrics, tracing, logging):

### Exclude Paths

Exclude exact paths:

```go
a, err := app.New(
    app.WithObservability(
        app.WithLogging(),
        app.WithMetrics(),
        app.WithTracing(),
        app.WithExcludePaths("/livez", "/readyz", "/metrics"),
    ),
)
```

### Exclude Prefixes

Exclude path prefixes:

```go
a, err := app.New(
    app.WithObservability(
        app.WithExcludePrefixes("/internal/", "/admin/debug/"),
    ),
)
```

### Exclude Patterns

Exclude paths matching regex patterns:

```go
a, err := app.New(
    app.WithObservability(
        app.WithExcludePatterns(`^/api/v\d+/health$`, `^/debug/.*`),
    ),
)
```

### Default Exclusions

By default, the following paths are excluded:

- `/health`, `/livez`, `/ready`, `/readyz`
- `/ready`, `/readyz`
- `/metrics`
- `/debug/*`

To disable default exclusions:

```go
a, err := app.New(
    app.WithObservability(
        app.WithoutDefaultExclusions(),
        app.WithExcludePaths("/custom-health"), // Add your own
    ),
)
```

## Access Logging

### Enable/Disable Access Logging

Control access logging:

```go
// Enable access logging (default)
a, err := app.New(
    app.WithObservability(
        app.WithAccessLogging(true),
    ),
)

// Disable access logging
a, err := app.New(
    app.WithObservability(
        app.WithAccessLogging(false),
    ),
)
```

### Access Log Scope

Control which requests are logged. When you do not set a scope, **production** defaults to errors-only and **development** to full access logs.

**Errors and slow requests only** (explicit; also the production default when unset):

```go
a, err := app.New(
    app.WithObservability(
        app.WithAccessLogScope(app.AccessLogScopeErrorsOnly),
    ),
)
```

**Full access logs (including production)**

To log every request in production, set scope explicitly. Consider log volume and cost before enabling.

```go
a, err := app.New(
    app.WithEnvironment("production"),
    app.WithObservability(
        app.WithAccessLogScope(app.AccessLogScopeAll),
    ),
)
```

### Slow Request Threshold

Mark requests as slow and log them. Slow requests are always logged regardless of access log scope.

```go
a, err := app.New(
    app.WithObservability(
        app.WithAccessLogScope(app.AccessLogScopeErrorsOnly),
        app.WithSlowThreshold(500 * time.Millisecond),
    ),
)
```

## Complete Example

Production-ready observability configuration:

```go
package main

import (
    "log"
    "time"
    
    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/metrics"
    "rivaas.dev/tracing"
)

func main() {
    a, err := app.New(
        // Service metadata (automatically injected into all components)
        app.WithServiceName("orders-api"),
        app.WithServiceVersion("v2.1.0"),
        app.WithEnvironment("production"),
        
        // Unified observability configuration
        app.WithObservability(
            // Logging: JSON handler for production
            app.WithLogging(
                logging.WithJSONHandler(),
                logging.WithLevel(slog.LevelInfo),
            ),
            
            // Metrics: Prometheus on separate server
            app.WithMetrics(
                metrics.WithPrometheus(":9090", "/metrics"),
            ),
            
            // Tracing: OTLP to Jaeger/Tempo
            app.WithTracing(
                tracing.WithOTLP("jaeger:4317"),
                tracing.WithSampleRate(0.1), // 10% sampling
            ),
            
            // Path filtering
            app.WithExcludePaths("/livez", "/readyz"),
            app.WithExcludePrefixes("/internal/"),
            
            // Access logging: errors and slow requests only (explicit; also production default when unset)
            app.WithAccessLogScope(app.AccessLogScopeErrorsOnly),
            app.WithSlowThreshold(1 * time.Second),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Register routes...
    a.GET("/orders/:id", handleGetOrder)
    
    // Start server...
}
```

## Next Steps

- [Context](../context/) - Use request-scoped logging in handlers
- [Health Endpoints](../health-endpoints/) - Configure health checks
- [Server](../server/) - Start the server and view observability data
