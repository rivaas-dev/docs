---
title: "Observability Options"
linkTitle: "Observability Options"
keywords:
  - observability options
  - metrics configuration
  - tracing configuration
  - logging configuration
weight: 4
description: >
  Observability configuration options reference (metrics, tracing, logging).
---

## Observability Options

These options are used with `WithObservability()`:

```go
app.WithObservability(
    app.WithLogging(logging.WithJSONHandler()),
    app.WithMetrics(),
    app.WithTracing(tracing.WithOTLP("localhost:4317")),
)
```

## Component Options

### WithLogging

```go
func WithLogging(opts ...logging.Option) ObservabilityOption
```

Enables structured logging with slog. Service name/version automatically injected.

### WithMetrics

```go
func WithMetrics(opts ...metrics.Option) ObservabilityOption
```

Enables metrics collection (Prometheus by default). Service name/version automatically injected.

### WithTracing

```go
func WithTracing(opts ...tracing.Option) ObservabilityOption
```

Enables distributed tracing. Service name/version automatically injected.

## Metrics Server Options

### WithMetricsOnMainRouter

```go
func WithMetricsOnMainRouter(path string) ObservabilityOption
```

Mounts metrics endpoint on the main HTTP server (default: separate server).

### WithMetricsSeparateServer

```go
func WithMetricsSeparateServer(addr, path string) ObservabilityOption
```

Configures separate metrics server address and path.

**Default:** `:9090/metrics`

## Path Filtering

### WithExcludePaths

```go
func WithExcludePaths(paths ...string) ObservabilityOption
```

Excludes exact paths from observability.

### WithExcludePrefixes

```go
func WithExcludePrefixes(prefixes ...string) ObservabilityOption
```

Excludes path prefixes from observability.

### WithExcludePatterns

```go
func WithExcludePatterns(patterns ...string) ObservabilityOption
```

Excludes paths matching regex patterns from observability.

### WithoutDefaultExclusions

```go
func WithoutDefaultExclusions() ObservabilityOption
```

Disables default path exclusions (`/health*`, `/metrics`, `/debug/*`).

## Access Logging

### WithAccessLogging

```go
func WithAccessLogging(enabled bool) ObservabilityOption
```

Enables or disables access logging.

**Default:** `true`

### WithLogOnlyErrors

```go
func WithLogOnlyErrors() ObservabilityOption
```

Logs only errors and slow requests (reduces log volume).

**Default:** `false` in development, `true` in production

In production, this is automatically enabled to reduce log volume. Normal successful requests are not logged, but errors (status >= 400) and slow requests are always logged.

### WithSlowThreshold

```go
func WithSlowThreshold(d time.Duration) ObservabilityOption
```

Marks requests as slow if they exceed this duration.

**Default:** `1s`

## Example

```go
app.WithObservability(
    // Components
    app.WithLogging(logging.WithJSONHandler()),
    app.WithMetrics(metrics.WithPrometheus(":9090", "/metrics")),
    app.WithTracing(tracing.WithOTLP("localhost:4317")),
    
    // Path filtering
    app.WithExcludePaths("/healthz", "/readyz"),
    app.WithExcludePrefixes("/internal/"),
    
    // Access logging
    app.WithLogOnlyErrors(),
    app.WithSlowThreshold(500 * time.Millisecond),
)
```
