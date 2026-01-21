---
title: "API Reference"
description: "Complete API documentation for the Recorder type and methods"
keywords:
  - metrics api
  - metrics reference
  - api documentation
  - type reference
weight: 1
---

Complete API reference for the metrics package core types and methods.

## Recorder Type

The `Recorder` is the main type for collecting metrics. It is thread-safe. You can use it concurrently.

```go
type Recorder struct {
    // contains filtered or unexported fields
}
```

### Creation Functions

#### New

```go
func New(opts ...Option) (*Recorder, error)
```

Creates a new Recorder with the given options. Returns an error if configuration is invalid.

**Parameters**:
- `opts ...Option` - Configuration options.

**Returns**:
- `*Recorder` - Configured recorder.
- `error` - Configuration error, if any.

**Example**:

```go
recorder, err := metrics.New(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)
if err != nil {
    log.Fatal(err)
}
```

**Errors**:
- Multiple provider options specified.
- Invalid service name.
- Invalid port or endpoint configuration.

#### MustNew

```go
func MustNew(opts ...Option) *Recorder
```

Creates a new Recorder with the given options. Panics if configuration is invalid.

**Parameters**:
- `opts ...Option` - Configuration options.

**Returns**:
- `*Recorder` - Configured recorder.

**Panics**: If configuration is invalid.

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)
```

**Use Case**: Applications that should fail fast on invalid metrics configuration.

## Lifecycle Methods

### Start

```go
func (r *Recorder) Start(ctx context.Context) error
```

Starts the metrics recorder. For Prometheus, starts the HTTP server. For OTLP, establishes connection. For stdout, this is a no-op but safe to call.

**Parameters**:
- `ctx context.Context` - Lifecycle context for the recorder

**Returns**:
- `error` - Startup error, if any

**Example**:

```go
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
defer cancel()

if err := recorder.Start(ctx); err != nil {
    log.Fatal(err)
}
```

**Errors**:
- Port already in use (Prometheus with `WithStrictPort`)
- Cannot connect to OTLP endpoint
- Context already canceled

**Provider Behavior**:
- **Prometheus**: Starts HTTP server on configured port
- **OTLP**: Establishes connection to collector
- **Stdout**: No-op, safe to call

### Shutdown

```go
func (r *Recorder) Shutdown(ctx context.Context) error
```

Gracefully shuts down the metrics recorder, flushing any pending metrics.

**Parameters**:
- `ctx context.Context` - Shutdown context with timeout

**Returns**:
- `error` - Shutdown error, if any

**Example**:

```go
shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

if err := recorder.Shutdown(shutdownCtx); err != nil {
    log.Printf("Shutdown error: %v", err)
}
```

**Behavior**:
- Stops accepting new metrics
- Flushes pending metrics
- Closes network connections
- Stops HTTP server (Prometheus)
- Idempotent (safe to call multiple times)

**Best Practice**: Always defer `Shutdown` with a timeout context.

### ForceFlush

```go
func (r *Recorder) ForceFlush(ctx context.Context) error
```

Forces immediate export of all pending metrics. Primarily useful for push-based providers (OTLP, stdout).

**Parameters**:
- `ctx context.Context` - Flush context with timeout

**Returns**:
- `error` - Flush error, if any

**Example**:

```go
// Before critical operation
if err := recorder.ForceFlush(ctx); err != nil {
    log.Printf("Failed to flush metrics: %v", err)
}
```

**Provider Behavior**:
- **OTLP**: Immediately exports all pending metrics
- **Stdout**: Immediately prints all pending metrics
- **Prometheus**: Typically a no-op (pull-based)

**Use Cases**:
- Before deployment or shutdown
- Checkpointing during long operations
- Ensuring metrics visibility

## Custom Metrics Methods

### IncrementCounter

```go
func (r *Recorder) IncrementCounter(ctx context.Context, name string, attrs ...attribute.KeyValue) error
```

Increments a counter metric by 1.

**Parameters**:
- `ctx context.Context` - Context for the operation
- `name string` - Metric name (must be valid)
- `attrs ...attribute.KeyValue` - Optional metric attributes

**Returns**:
- `error` - Error if metric name is invalid or limit reached

**Example**:

```go
err := recorder.IncrementCounter(ctx, "requests_total",
    attribute.String("method", "GET"),
    attribute.String("status", "success"),
)
```

**Naming Rules**:
- Must start with letter
- Can contain letters, numbers, underscores, dots, hyphens
- Cannot use reserved prefixes: `__`, `http_`, `router_`
- Maximum 255 characters

### AddCounter

```go
func (r *Recorder) AddCounter(ctx context.Context, name string, value int64, attrs ...attribute.KeyValue) error
```

Adds a specific value to a counter metric.

**Parameters**:
- `ctx context.Context` - Context for the operation
- `name string` - Metric name (must be valid)
- `value int64` - Amount to add (must be non-negative)
- `attrs ...attribute.KeyValue` - Optional metric attributes

**Returns**:
- `error` - Error if metric name is invalid, value is negative, or limit reached

**Example**:

```go
bytesProcessed := int64(1024)
err := recorder.AddCounter(ctx, "bytes_processed_total", bytesProcessed,
    attribute.String("direction", "inbound"),
)
```

### RecordHistogram

```go
func (r *Recorder) RecordHistogram(ctx context.Context, name string, value float64, attrs ...attribute.KeyValue) error
```

Records a value in a histogram metric.

**Parameters**:
- `ctx context.Context` - Context for the operation
- `name string` - Metric name (must be valid)
- `value float64` - Value to record
- `attrs ...attribute.KeyValue` - Optional metric attributes

**Returns**:
- `error` - Error if metric name is invalid or limit reached

**Example**:

```go
start := time.Now()
// ... operation ...
duration := time.Since(start).Seconds()

err := recorder.RecordHistogram(ctx, "operation_duration_seconds", duration,
    attribute.String("operation", "create_user"),
)
```

**Bucket Configuration**: Use `WithDurationBuckets` or `WithSizeBuckets` to customize histogram boundaries.

### SetGauge

```go
func (r *Recorder) SetGauge(ctx context.Context, name string, value float64, attrs ...attribute.KeyValue) error
```

Sets a gauge metric to a specific value.

**Parameters**:
- `ctx context.Context` - Context for the operation
- `name string` - Metric name (must be valid)
- `value float64` - Value to set
- `attrs ...attribute.KeyValue` - Optional metric attributes

**Returns**:
- `error` - Error if metric name is invalid or limit reached

**Example**:

```go
activeConnections := float64(pool.Active())
err := recorder.SetGauge(ctx, "active_connections", activeConnections,
    attribute.String("pool", "database"),
)
```

## Provider-Specific Methods

### ServerAddress

```go
func (r *Recorder) ServerAddress() string
```

Returns the server address (port) for Prometheus provider. Returns empty string for other providers or if server is disabled.

**Returns**:
- `string` - Server address in port format (e.g., `:9090`)

**Example**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)
recorder.Start(ctx)

address := recorder.ServerAddress()
log.Printf("Metrics at: http://localhost%s/metrics", address)
```

**Use Cases**:
- Logging actual port (when not using strict mode)
- Testing with dynamic port allocation
- Health check registration

**Note**: Returns the port string (e.g., `:9090`), not a full hostname. Prepend `localhost` for local access.

### Handler

```go
func (r *Recorder) Handler() (http.Handler, error)
```

Returns the HTTP handler for metrics endpoint. Only works with Prometheus provider.

**Returns**:
- `http.Handler` - Metrics endpoint handler
- `error` - Error if not using Prometheus provider or server disabled

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

http.Handle("/metrics", handler)
http.ListenAndServe(":8080", nil)
```

**Errors**:
- Not using Prometheus provider
- Server not disabled (use `WithServerDisabled`)

### CustomMetricCount

```go
func (r *Recorder) CustomMetricCount() int
```

Returns the number of custom metrics created.

**Returns**:
- `int` - Number of custom metrics

**Example**:

```go
count := recorder.CustomMetricCount()
log.Printf("Custom metrics: %d/%d", count, maxLimit)

// Expose as a metric
_ = recorder.SetGauge(ctx, "custom_metrics_count", float64(count))
```

**Use Cases**:
- Monitoring metric cardinality
- Debugging metric limit issues
- Capacity planning

**Note**: Built-in HTTP metrics do not count toward this total.

## Middleware Function

### Middleware

```go
func Middleware(recorder *Recorder, opts ...MiddlewareOption) func(http.Handler) http.Handler
```

Returns HTTP middleware that automatically collects metrics for requests.

**Parameters**:
- `recorder *Recorder` - Metrics recorder
- `opts ...MiddlewareOption` - Middleware configuration options

**Returns**:
- `func(http.Handler) http.Handler` - Middleware function

**Example**:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health", "/metrics"),
    metrics.WithHeaders("X-Request-ID"),
)(httpHandler)
```

**Collected Metrics**:
- `http_request_duration_seconds` - Request duration histogram
- `http_requests_total` - Request counter
- `http_requests_active` - Active requests gauge
- `http_request_size_bytes` - Request size histogram
- `http_response_size_bytes` - Response size histogram
- `http_errors_total` - Error counter

**Middleware Options**: See [Middleware Options](../middleware-options/) for details.

## Testing Functions

### TestingRecorder

```go
func TestingRecorder(tb testing.TB, serviceName string, opts ...Option) *Recorder
```

Creates a test recorder with stdout provider. Automatically registers cleanup via `t.Cleanup()`.

**Parameters**:
- `tb testing.TB` - Test or benchmark instance
- `serviceName string` - Service name for metrics
- `opts ...Option` - Optional additional configuration options

**Returns**:
- `*Recorder` - Test recorder

**Example**:

```go
func TestHandler(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorder(t, "test-service")
    
    // Use recorder in tests...
    // Cleanup is automatic
}

// With additional options
func TestWithOptions(t *testing.T) {
    recorder := metrics.TestingRecorder(t, "test-service",
        metrics.WithMaxCustomMetrics(100),
    )
}
```

**Features**:
- No port conflicts (uses stdout)
- Automatic cleanup
- Parallel test safe
- Works with both `*testing.T` and `*testing.B`

### TestingRecorderWithPrometheus

```go
func TestingRecorderWithPrometheus(tb testing.TB, serviceName string, opts ...Option) *Recorder
```

Creates a test recorder with Prometheus provider and dynamic port allocation. Automatically registers cleanup via `t.Cleanup()`.

**Parameters**:
- `tb testing.TB` - Test or benchmark instance
- `serviceName string` - Service name for metrics
- `opts ...Option` - Optional additional configuration options

**Returns**:
- `*Recorder` - Test recorder with Prometheus

**Example**:

```go
func TestMetricsEndpoint(t *testing.T) {
    t.Parallel()
    
    recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")
    
    // Wait for server
    err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
    if err != nil {
        t.Fatal(err)
    }
    
    // Test metrics endpoint...
}
```

**Features**:
- Dynamic port allocation
- Real Prometheus endpoint
- Automatic cleanup
- Works with both `*testing.T` and `*testing.B`

### WaitForMetricsServer

```go
func WaitForMetricsServer(tb testing.TB, address string, timeout time.Duration) error
```

Waits for Prometheus metrics server to be ready.

**Parameters**:
- `tb testing.TB` - Test or benchmark instance for logging
- `address string` - Server address (e.g., `:9090`)
- `timeout time.Duration` - Maximum wait time

**Returns**:
- `error` - Error if server not ready within timeout

**Example**:

```go
recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")

err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
if err != nil {
    t.Fatalf("Server not ready: %v", err)
}

// Server is ready, make requests
```

## Event Types

### EventType

```go
type EventType int

const (
    EventError   EventType = iota // Error events
    EventWarning                   // Warning events
    EventInfo                      // Informational events
    EventDebug                     // Debug events
)
```

Severity levels for internal operational events.

### Event

```go
type Event struct {
    Type    EventType
    Message string
    Args    []any // slog-style key-value pairs
}
```

Internal operational event from the metrics package.

**Example**:

```go
metrics.WithEventHandler(func(e metrics.Event) {
    switch e.Type {
    case metrics.EventError:
        sentry.CaptureMessage(e.Message)
    case metrics.EventWarning:
        log.Printf("WARN: %s", e.Message)
    case metrics.EventInfo:
        log.Printf("INFO: %s", e.Message)
    }
})
```

### EventHandler

```go
type EventHandler func(Event)
```

Function type for handling internal operational events.

**Example**:

```go
handler := func(e metrics.Event) {
    slog.Default().Info(e.Message, e.Args...)
}

recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithEventHandler(handler),
)
```

## Error Handling

All metric recording methods return `error`. Common error types:

### Invalid Metric Name

```go
err := recorder.IncrementCounter(ctx, "__reserved")
// Error: metric name uses reserved prefix "__"
```

### Metric Limit Reached

```go
err := recorder.IncrementCounter(ctx, "new_metric_1001")
// Error: custom metric limit reached (1000/1000)
```

### Provider Not Started

```go
recorder := metrics.MustNew(metrics.WithOTLP("http://localhost:4318"))
err := recorder.IncrementCounter(ctx, "metric")
// Error: OTLP provider not started (call Start first)
```

## Thread Safety

All methods are thread-safe and can be called concurrently:

```go
// Safe to call from multiple goroutines
go func() {
    _ = recorder.IncrementCounter(ctx, "worker_1")
}()

go func() {
    _ = recorder.IncrementCounter(ctx, "worker_2")
}()
```

## Next Steps

- See [Options](../options/) for all configuration options
- Check [Middleware Options](../middleware-options/) for HTTP middleware
- Review [Troubleshooting](../troubleshooting/) for common issues
- Read [Guides](/guides/metrics/) for usage patterns
