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

You can also configure observability using environment variables. See [Environment Variables Guide](/docs/guides/app/environment-variables/) for details.

## Component Options

### WithLogging

```go
func WithLogging(opts ...logging.Option) ObservabilityOption
```

Enables structured logging with slog. Service name/version automatically injected.

**Environment variable alternative:**
```bash
export RIVAAS_LOG_LEVEL=info      # debug, info, warn, error
export RIVAAS_LOG_FORMAT=json     # json, text, console
```

### WithMetrics

```go
func WithMetrics(opts ...metrics.Option) ObservabilityOption
```

Enables metrics collection (Prometheus by default). Service name/version automatically injected.

**Environment variable alternative:**
```bash
export RIVAAS_METRICS_EXPORTER=prometheus  # or otlp, stdout
export RIVAAS_METRICS_ADDR=:9090          # Optional: custom Prometheus address
export RIVAAS_METRICS_PATH=/metrics        # Optional: custom Prometheus path
```

### WithTracing

```go
func WithTracing(opts ...tracing.Option) ObservabilityOption
```

Enables distributed tracing. Service name/version automatically injected.

**Environment variable alternative:**
```bash
export RIVAAS_TRACING_EXPORTER=otlp        # or otlp-http, stdout
export RIVAAS_TRACING_ENDPOINT=localhost:4317  # Required for otlp/otlp-http
```

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

### WithAccessLogScope

```go
func WithAccessLogScope(scope AccessLogScope) ObservabilityOption
```

Sets which requests are logged as access logs. Valid values are `app.AccessLogScopeAll` and `app.AccessLogScopeErrorsOnly`. Invalid values cause validation to fail at startup.

**Scope values:**

- `AccessLogScopeAll` — Log every request (including 2xx). Use in production only if you need full request logs; consider log volume and cost.
- `AccessLogScopeErrorsOnly` — Log only errors (status >= 400) and slow requests. Reduces log volume.

**Access log scope and environment defaults**

When you do not call `WithAccessLogScope`, the effective scope is determined by environment:

| User choice | Production | Development |
| ----------- | ---------- | ----------- |
| None | Errors-only (default) | Full access logs (default) |
| `WithAccessLogScope(AccessLogScopeErrorsOnly)` | Errors-only | Errors-only |
| `WithAccessLogScope(AccessLogScopeAll)` | Full access logs | Full access logs |

Slow requests are always logged regardless of scope. See [WithSlowThreshold](#withslowthreshold).

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
    app.WithExcludePaths("/livez", "/readyz"),
    app.WithExcludePrefixes("/internal/"),
    
    // Access logging
    app.WithAccessLogScope(app.AccessLogScopeErrorsOnly),
    app.WithSlowThreshold(500 * time.Millisecond),
)
```
