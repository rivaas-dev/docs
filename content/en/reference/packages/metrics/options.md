---
title: "Configuration Options"
description: "Complete reference of all configuration options"
keywords:
  - metrics options
  - configuration
  - options reference
  - functional options
weight: 2
---

Complete reference for all `Option` functions used to configure the `Recorder`.

## Provider Options

Only one provider option can be used per `Recorder`. Using multiple provider options results in a validation error.

### WithPrometheus

```go
func WithPrometheus(port, path string) Option
```

Configures Prometheus provider with HTTP endpoint.

**Parameters**:
- `port string` - Listen address like `:9090` or `localhost:9090`.
- `path string` - Metrics path like `/metrics`.

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)
```

**Behavior**:
- Initializes immediately in `New()`.
- Starts HTTP server when `Start()` is called.
- Metrics available at `http://localhost:9090/metrics`.

**Related Options**:
- `WithStrictPort()` - Fail if port unavailable.
- `WithServerDisabled()` - Manage HTTP server manually.

### WithOTLP

```go
func WithOTLP(endpoint string) Option
```

Configures OTLP (OpenTelemetry Protocol) provider for sending metrics to a collector.

**Parameters**:
- `endpoint string` - OTLP collector HTTP endpoint like `http://localhost:4318`.

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithServiceName("my-service"),
)
```

**Behavior**:
- Defers initialization until `Start()` is called.
- Uses lifecycle context for network connections.
- **Important**: Must call `Start()` before recording metrics.

**Related Options**:
- `WithExportInterval()` - Configure export frequency.

### WithStdout

```go
func WithStdout() Option
```

Configures stdout provider for printing metrics to console.

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("dev-service"),
)
```

**Behavior**:
- Initializes immediately in `New()`
- Works without calling `Start()` (but safe to call)
- Prints metrics to stdout periodically

**Use Cases**:
- Development and debugging
- CI/CD pipelines
- Unit tests

**Related Options**:
- `WithExportInterval()` - Configure print frequency

## Service Configuration Options

### WithServiceName

```go
func WithServiceName(name string) Option
```

Sets the service name for metrics identification.

**Parameters**:
- `name string` - Service name

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("payment-api"),
)
```

**Where It Appears**:

The service name shows up in two places in your metrics output:

1. **Metric labels** - Every metric gets a `service_name` label:
   ```
   http_requests_total{service_name="payment-api",method="GET"} 42
   ```

2. **Target info** - OpenTelemetry resource metadata:
   ```
   target_info{service_name="payment-api",service_version="1.0.0"} 1
   ```

**Best Practices**:
- Use lowercase with hyphens: `user-service`, `payment-api`
- Be consistent across services
- Avoid changing names in production

### WithServiceVersion

```go
func WithServiceVersion(version string) Option
```

Sets the service version for metrics.

**Parameters**:
- `version string` - Service version

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
    metrics.WithServiceVersion("v1.2.3"),
)
```

**Best Practices**:
- Use semantic versioning: `v1.2.3`
- Automate from CI/CD build information

## Prometheus-Specific Options

### WithStrictPort

```go
func WithStrictPort() Option
```

Requires the metrics server to use the exact port specified. Fails if port is unavailable.

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithStrictPort(),  // Fail if 9090 unavailable
    metrics.WithServiceName("my-api"),
)
```

**Default Behavior**: Automatically searches up to 100 ports if requested port is unavailable.

**With Strict Mode**: Returns error if exact port is not available.

**Production Recommendation**: Always use `WithStrictPort()` for predictable behavior.

### WithServerDisabled

```go
func WithServerDisabled() Option
```

Disables automatic metrics server startup. Use `Handler()` to get metrics handler for manual serving.

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServerDisabled(),
    metrics.WithServiceName("my-api"),
)

handler, err := recorder.Handler()
if err != nil {
    log.Fatal(err)
}

// Serve on your own server
http.Handle("/metrics", handler)
http.ListenAndServe(":8080", nil)
```

**Use Cases**:
- Serve metrics on same port as application
- Custom server configuration
- Integration with existing HTTP servers

## Histogram Bucket Options

### WithDurationBuckets

```go
func WithDurationBuckets(buckets ...float64) Option
```

Sets custom histogram bucket boundaries for duration metrics (in seconds).

**Parameters**:
- `buckets ...float64` - Bucket boundaries in seconds

**Default**: `0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10`

**Example**:

```go
// Fast API (most requests < 100ms)
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithDurationBuckets(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.5, 1),
    metrics.WithServiceName("fast-api"),
)

// Slow operations (seconds to minutes)
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithDurationBuckets(1, 5, 10, 30, 60, 120, 300, 600),
    metrics.WithServiceName("batch-processor"),
)
```

**Trade-offs**:
- More buckets = better resolution, higher memory/storage
- Fewer buckets = lower overhead, coarser resolution

### WithSizeBuckets

```go
func WithSizeBuckets(buckets ...float64) Option
```

Sets custom histogram bucket boundaries for size metrics (in bytes).

**Parameters**:
- `buckets ...float64` - Bucket boundaries in bytes

**Default**: `100, 1000, 10000, 100000, 1000000, 10000000`

**Example**:

```go
// Small JSON API (< 10KB)
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithSizeBuckets(100, 500, 1000, 5000, 10000, 50000),
    metrics.WithServiceName("json-api"),
)

// File uploads (KB to MB)
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithSizeBuckets(1024, 10240, 102400, 1048576, 10485760, 104857600),
    metrics.WithServiceName("file-service"),
)
```

## Advanced Options

### WithExportInterval

```go
func WithExportInterval(interval time.Duration) Option
```

Sets export interval for push-based providers (OTLP and stdout).

**Parameters**:
- `interval time.Duration` - Export interval

**Default**: `30 seconds`

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithExportInterval(10 * time.Second),
    metrics.WithServiceName("my-service"),
)
```

**Applies To**:
- OTLP (push-based)
- Stdout (push-based)

**Does NOT Apply To**:
- Prometheus (pull-based, scraped on-demand)

**Trade-offs**:
- Shorter interval: More timely data, higher overhead
- Longer interval: Lower overhead, delayed visibility

### WithMaxCustomMetrics

```go
func WithMaxCustomMetrics(maxLimit int) Option
```

Sets the maximum number of custom metrics allowed.

**Parameters**:
- `maxLimit int` - Maximum custom metrics

**Default**: `1000`

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithMaxCustomMetrics(5000),
    metrics.WithServiceName("my-api"),
)
```

**Purpose**:
- Prevent unbounded metric cardinality
- Protect against memory exhaustion
- Enforce metric discipline

**Note**: Built-in HTTP metrics do not count toward this limit.

**Monitor Usage**:

```go
count := recorder.CustomMetricCount()
log.Printf("Custom metrics: %d/%d", count, maxLimit)
```

### WithLogger

```go
func WithLogger(logger *slog.Logger) Option
```

Sets the logger for internal operational events.

**Parameters**:
- `logger *slog.Logger` - Logger instance

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithLogger(slog.Default()),
    metrics.WithServiceName("my-api"),
)
```

**Events Logged**:
- Initialization events
- Error messages (metric creation failures)
- Warning messages (port conflicts, limits reached)

**Alternative**: Use `WithEventHandler()` for custom event handling.

### WithEventHandler

```go
func WithEventHandler(handler EventHandler) Option
```

Sets a custom event handler for internal operational events.

**Parameters**:
- `handler EventHandler` - Event handler function

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithEventHandler(func(e metrics.Event) {
        switch e.Type {
        case metrics.EventError:
            sentry.CaptureMessage(e.Message)
        case metrics.EventWarning:
            log.Printf("WARN: %s", e.Message)
        case metrics.EventInfo:
            log.Printf("INFO: %s", e.Message)
        }
    }),
    metrics.WithServiceName("my-api"),
)
```

**Use Cases**:
- Send errors to external monitoring (Sentry, etc.)
- Custom logging formats
- Metric collection about metric collection

**Event Types**:
- `EventError` - Error events
- `EventWarning` - Warning events
- `EventInfo` - Informational events
- `EventDebug` - Debug events

## Advanced Provider Options

### WithMeterProvider

```go
func WithMeterProvider(provider metric.MeterProvider) Option
```

Provides a custom OpenTelemetry meter provider for complete control.

**Parameters**:
- `provider metric.MeterProvider` - Custom meter provider

**Example**:

```go
mp := sdkmetric.NewMeterProvider(...)
recorder := metrics.MustNew(
    metrics.WithMeterProvider(mp),
    metrics.WithServiceName("my-service"),
)
defer mp.Shutdown(context.Background())
```

**Use Cases**:
- Manage meter provider lifecycle yourself
- Multiple independent metrics configurations
- Avoid global state

**Note**: When using `WithMeterProvider`, provider options (`WithPrometheus`, `WithOTLP`, `WithStdout`) are ignored.

### WithGlobalMeterProvider

```go
func WithGlobalMeterProvider() Option
```

Registers the meter provider as the global OpenTelemetry meter provider.

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithGlobalMeterProvider(),  // Register globally
    metrics.WithServiceName("my-service"),
)
```

**Default Behavior**: Meter providers are NOT registered globally.

**When to Use**:
- OpenTelemetry instrumentation libraries need global provider
- Third-party libraries expect global meter provider
- `otel.GetMeterProvider()` should return your provider

**When NOT to Use**:
- Multiple services in same process
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

## Option Validation

The following validation occurs during `New()` or `MustNew()`:

- **Provider Conflicts**: Only one provider option (`WithPrometheus`, `WithOTLP`, `WithStdout`) can be used
- **Service Name**: Cannot be empty (default: `"rivaas-service"`)
- **Service Version**: Cannot be empty (default: `"1.0.0"`)
- **Port Format**: Must be valid address format for Prometheus
- **Custom Metrics Limit**: Must be at least 1

**Defaults**: If no provider is specified, defaults to Prometheus on `:9090/metrics`.

**Validation Errors**:

```go
// Multiple providers - ERROR
recorder, err := metrics.New(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithOTLP("http://localhost:4318"),  // Error: conflicting providers
)

// Empty service name - ERROR
recorder, err := metrics.New(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName(""),  // Error: service name cannot be empty
)

// No options - OK (uses defaults)
recorder, err := metrics.New()  // Uses default Prometheus on :9090/metrics
```

## Next Steps

- See [API Reference](../api-reference/) for method documentation
- Check [Middleware Options](../middleware-options/) for HTTP middleware configuration
- Review [Troubleshooting](../troubleshooting/) for common issues
- Read [Configuration Guide](/guides/metrics/configuration/) for detailed examples
