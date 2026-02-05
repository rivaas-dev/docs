---
title: "Configuration"
description: "Configure service metadata, histograms, and advanced options"
weight: 4
keywords:
  - metrics configuration
  - exporters
  - providers
  - options
---

This guide covers all configuration options for the metrics package beyond basic provider setup.

## Service Configuration

Service metadata helps identify your application in metrics dashboards and monitoring systems.

### Service Name

Required metadata that identifies your service:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)
```

The service name appears in two places in your metrics output:

**1. Metric labels** - Every metric includes the service name:

```
http_requests_total{service_name="my-api",method="GET"} 42
```

**2. Target info metric** - OpenTelemetry resource information:

```
target_info{service_name="my-api",service_version="v1.2.3"} 1
```

The `target_info` metric is useful for service discovery and correlating metrics across your infrastructure.

**Best Practices**:
- Use lowercase with hyphens: `user-service`, `payment-api`.
- Be consistent across services.
- Avoid changing names in production.

### Service Version

Optional version metadata for tracking deployments:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
    metrics.WithServiceVersion("v1.2.3"),
)
```

Use cases:
- Track metrics across deployments.
- Compare performance between versions.
- Debug version-specific issues.

**Best Practices**:
- Use semantic versioning: `v1.2.3`.
- Include in all production deployments.
- Automate from CI/CD pipelines:

```go
var Version = "dev" // Set by build flags

recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
    metrics.WithServiceVersion(Version),
)
```

## Prometheus-Specific Options

### Strict Port Mode

Fail immediately if the configured port is unavailable:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithStrictPort(),  // Production recommendation
    metrics.WithServiceName("my-api"),
)
```

**Default Behavior**: If port is unavailable, automatically searches up to 100 ports.

**With Strict Mode**: Fails with error if exact port is unavailable.

**Production Best Practice**: Always use `WithStrictPort()` to ensure predictable port allocation.

### Server Disabled

Disable automatic metrics server and manage it yourself:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServerDisabled(),
    metrics.WithServiceName("my-api"),
)

// Get the metrics handler
handler, err := recorder.Handler()
if err != nil {
    log.Fatalf("Failed to get handler: %v", err)
}

// Serve on your own HTTP server
http.Handle("/metrics", handler)
http.ListenAndServe(":8080", nil)
```

**Use Cases**:
- Serve metrics on same port as application
- Custom server configuration
- Integration with existing HTTP servers

**Note**: `Handler()` only works with Prometheus provider.

## Histogram Bucket Configuration

Customize histogram bucket boundaries for better resolution in specific ranges.

### Duration Buckets

Configure buckets for duration metrics (in seconds):

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithDurationBuckets(0.001, 0.01, 0.1, 0.5, 1, 5, 10),
    metrics.WithServiceName("my-api"),
)
```

**Default Buckets**: `0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10` seconds

**When to Customize**:
- Most requests < 100ms: Use finer buckets at low end
- Slow operations (seconds): Use coarser buckets
- Specific SLA requirements

**Examples**:

```go
// Fast API (most requests < 100ms)
metrics.WithDurationBuckets(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.5, 1)

// Slow batch operations (seconds to minutes)
metrics.WithDurationBuckets(1, 5, 10, 30, 60, 120, 300, 600)

// Mixed workload
metrics.WithDurationBuckets(0.01, 0.1, 0.5, 1, 5, 10, 30, 60)
```

### Size Buckets

Configure buckets for size metrics (in bytes):

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithSizeBuckets(100, 1000, 10000, 100000, 1000000),
    metrics.WithServiceName("my-api"),
)
```

**Default Buckets**: `1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576` bytes

**When to Customize**:
- Small payloads (< 10KB): Use finer buckets
- Large payloads (MB+): Use coarser buckets
- Specific size requirements

**Examples**:

```go
// Small JSON API (< 10KB)
metrics.WithSizeBuckets(100, 500, 1000, 5000, 10000, 50000)

// File uploads (KB to MB)
metrics.WithSizeBuckets(1024, 10240, 102400, 1048576, 10485760, 104857600)

// Mixed sizes
metrics.WithSizeBuckets(100, 1000, 10000, 100000, 1000000, 10000000)
```

### Impact on Cardinality

**Important**: More buckets = higher metric cardinality = more storage.

```go
// 7 buckets (lower cardinality)
metrics.WithDurationBuckets(0.01, 0.1, 0.5, 1, 5, 10)

// 15 buckets (higher cardinality, better resolution)
metrics.WithDurationBuckets(
    0.001, 0.005, 0.01, 0.025, 0.05,
    0.1, 0.25, 0.5, 1, 2.5,
    5, 10, 30, 60, 120,
)
```

**Best Practice**: Use the minimum number of buckets that provide sufficient resolution for your use case.

## Advanced Options

### Logging

Configure how internal events are logged:

```go
import "log/slog"

recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithLogger(slog.Default()),
    metrics.WithServiceName("my-api"),
)
```

The logger receives:
- Initialization events
- Error messages (metric creation failures, etc.)
- Warning messages (port conflicts, etc.)

**Example Output**:

```
INFO metrics server started on :9090
WARN custom metric limit reached (1000/1000)
ERROR failed to create metric: invalid name "__reserved"
```

### Event Handler

For advanced use cases, handle events programmatically:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithEventHandler(func(e metrics.Event) {
        switch e.Type {
        case metrics.EventError:
            // Send to error tracking
            sentry.CaptureMessage(e.Message)
        case metrics.EventWarning:
            // Log warnings
            log.Printf("WARN: %s", e.Message)
        case metrics.EventInfo:
            // Log info
            log.Printf("INFO: %s", e.Message)
        }
    }),
    metrics.WithServiceName("my-api"),
)
```

**Event Types**:
- `EventInfo` - Informational messages
- `EventWarning` - Non-critical warnings
- `EventError` - Error conditions

**Use Cases**:
- Send errors to external monitoring
- Custom logging formats
- Metric collection about metric collection

### Custom Metrics Limit

Set maximum number of custom metrics that can be created:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithMaxCustomMetrics(5000),  // Default: 1000
    metrics.WithServiceName("my-api"),
)
```

**Why Limit Metrics?**
- Prevent unbounded cardinality
- Protect against memory exhaustion
- Enforce metric discipline

**Built-in Metrics Don't Count**: HTTP metrics are always available.

**Monitor Usage**:

```go
count := recorder.CustomMetricCount()
log.Printf("Custom metrics: %d/%d", count, maxLimit)
```

**What Happens at Limit?**
- New metric creation returns an error
- Existing metrics continue to work
- Error is logged via logger/event handler

### Export Interval

Configure how often metrics are exported (OTLP and stdout only):

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithExportInterval(10 * time.Second),  // Default: 30s
    metrics.WithServiceName("my-api"),
)
```

**Applies To**: OTLP (push), Stdout (push)

**Does NOT Apply To**: Prometheus (pull-based, scraped on-demand)

**Trade-offs**:
- Shorter interval: More timely data, higher overhead
- Longer interval: Lower overhead, delayed visibility

**Best Practices**:
- Development: 5-10 seconds
- Production: 15-30 seconds
- High-volume: 30-60 seconds

## Global Meter Provider

By default, the metrics package does NOT set the global OpenTelemetry meter provider.

### Default Behavior (Recommended)

Multiple independent recorder instances work without conflicts:

```go
// Create independent recorders (no global state!)
recorder1 := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("service-1"),
)

recorder2 := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("service-2"),
)

// Both work independently without conflicts
```

### Opt-in to Global Registration

Explicitly set the global meter provider:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-service"),
    metrics.WithGlobalMeterProvider(),  // Explicit opt-in
)
```

**When to Use**:
- OpenTelemetry instrumentation libraries need global provider
- Third-party libraries expect `otel.GetMeterProvider()`
- Centralized metrics collection across libraries

**When NOT to Use**:
- Multiple services in same process (e.g., tests)
- Avoid global state
- Custom meter provider management

## Configuration Examples

### Production API

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithStrictPort(),
    metrics.WithServiceName("payment-api"),
    metrics.WithServiceVersion(version),
    metrics.WithLogger(slog.Default()),
    metrics.WithDurationBuckets(0.01, 0.1, 0.5, 1, 5, 10),
    metrics.WithMaxCustomMetrics(2000),
)
```

### Development

```go
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("dev-api"),
    metrics.WithExportInterval(5 * time.Second),
)
```

### OpenTelemetry Native

```go
recorder := metrics.MustNew(
    metrics.WithOTLP(os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")),
    metrics.WithServiceName(os.Getenv("SERVICE_NAME")),
    metrics.WithServiceVersion(os.Getenv("SERVICE_VERSION")),
    metrics.WithExportInterval(15 * time.Second),
    metrics.WithLogger(slog.Default()),
)
```

### Embedded Metrics Server

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServerDisabled(),
    metrics.WithServiceName("api"),
)

handler, _ := recorder.Handler()

// Serve on application port
mux := http.NewServeMux()
mux.Handle("/metrics", handler)
mux.HandleFunc("/", appHandler)
http.ListenAndServe(":8080", mux)
```

## Configuration from Environment

Load configuration from environment variables:

```go
func configFromEnv() []metrics.Option {
    opts := []metrics.Option{
        metrics.WithServiceName(os.Getenv("SERVICE_NAME")),
    }
    
    if version := os.Getenv("SERVICE_VERSION"); version != "" {
        opts = append(opts, metrics.WithServiceVersion(version))
    }
    
    switch os.Getenv("METRICS_PROVIDER") {
    case "prometheus":
        addr := os.Getenv("METRICS_ADDR")
        if addr == "" {
            addr = ":9090"
        }
        opts = append(opts, 
            metrics.WithPrometheus(addr, "/metrics"),
            metrics.WithStrictPort(),
        )
    case "otlp":
        endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
        opts = append(opts, metrics.WithOTLP(endpoint))
    default:
        opts = append(opts, metrics.WithStdout())
    }
    
    return opts
}

recorder := metrics.MustNew(configFromEnv()...)
```

## Next Steps

- Learn [Custom Metrics](../custom-metrics/) to record your own data
- Explore [Middleware](../middleware/) for HTTP integration
- See [Testing](../testing/) for test utilities
- Check [Reference](/reference/packages/metrics/options/) for all options
