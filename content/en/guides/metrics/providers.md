---
title: "Metrics Providers"
description: "Understand Prometheus, OTLP, and stdout metrics exporters"
weight: 3
keywords:
  - metrics providers
  - prometheus
  - otlp
  - stdout
---

The metrics package supports three provider types for exporting metrics. Each provider has different characteristics and use cases.

## Provider Overview

| Provider | Use Case | Network | Push/Pull |
|----------|----------|---------|-----------|
| **Prometheus** | Production monitoring | HTTP server | Pull |
| **OTLP** | OpenTelemetry collectors | HTTP client | Push |
| **Stdout** | Development/debugging | Console output | Push |

**Important**: Only one provider can be used per `Recorder` instance. Using multiple provider options will result in a validation error.

## Basic Configuration

{{< tabpane persist=header >}}
{{< tab header="Prometheus" lang="go" >}}
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-service"),
)
{{< /tab >}}
{{< tab header="OTLP" lang="go" >}}
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithServiceName("my-service"),
    metrics.WithServiceVersion("v1.0.0"),
)
{{< /tab >}}
{{< tab header="Stdout" lang="go" >}}
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("my-service"),
)
{{< /tab >}}
{{< /tabpane >}}

## Prometheus Provider

### Initialization Behavior

The Prometheus provider:
1. Initializes immediately in `New()`
2. Starts the HTTP server when `Start(ctx)` is called
3. Metrics are available immediately after `Start()` returns

```go
recorder, err := metrics.New(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)
if err != nil {
    log.Fatal(err)
}

// HTTP server starts here
if err := recorder.Start(ctx); err != nil {
    log.Fatal(err)
}

// Metrics endpoint is now available at http://localhost:9090/metrics
```

### Port Configuration

By default, if the requested port is unavailable, the server automatically finds the next available port (up to 100 ports searched).

#### Strict Port Mode

For production, use `WithStrictPort()` to ensure the exact port is used:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithStrictPort(),  // Fail if port 9090 is unavailable
    metrics.WithServiceName("my-service"),
)
```

**Production Best Practice**: Always use `WithStrictPort()` to avoid port conflicts.

#### Finding the Actual Port

If not using strict mode, check which port was actually used:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-service"),
)

if err := recorder.Start(ctx); err != nil {
    log.Fatal(err)
}

// Get the actual address (returns port like ":9090")
address := recorder.ServerAddress()
log.Printf("Metrics available at: http://localhost%s/metrics", address)
```

### Manual Server Management

Disable automatic server startup and serve metrics on your own HTTP server:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServerDisabled(),
    metrics.WithServiceName("my-service"),
)

// Get the metrics handler
handler, err := recorder.Handler()
if err != nil {
    log.Fatalf("Failed to get metrics handler: %v", err)
}

// Serve on your own server
mux := http.NewServeMux()
mux.Handle("/metrics", handler)
mux.HandleFunc("/health", healthHandler)

http.ListenAndServe(":8080", mux)
```

**Use Case**: Serve metrics on the same port as your application server.

### Viewing Metrics

Access metrics via HTTP:

```bash
curl http://localhost:9090/metrics
```

Example output:

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/api/users",status="200"} 1543

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",path="/api/users",le="0.005"} 245
http_request_duration_seconds_bucket{method="GET",path="/api/users",le="0.01"} 892
http_request_duration_seconds_sum{method="GET",path="/api/users"} 15.432
http_request_duration_seconds_count{method="GET",path="/api/users"} 1543
```

### Prometheus Scrape Configuration

Configure Prometheus to scrape your service:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /metrics
```

## OTLP Provider

The OTLP (OpenTelemetry Protocol) provider pushes metrics to an OpenTelemetry collector.

### Basic Configuration

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithServiceName("my-service"),
    metrics.WithServiceVersion("v1.0.0"),
)
```

Parameter:
- **Endpoint**: OTLP collector HTTP endpoint (e.g., `http://localhost:4318`)

### Initialization Behavior

The OTLP provider:
1. Defers initialization until `Start(ctx)` is called
2. Uses the lifecycle context for network connections
3. Enables graceful shutdown of connections

**Critical**: You must call `Start(ctx)` before recording metrics, or metrics will be silently dropped.

```go
recorder, err := metrics.New(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithServiceName("my-service"),
)
if err != nil {
    log.Fatal(err)
}

// OTLP connection established here
if err := recorder.Start(ctx); err != nil {
    log.Fatal(err)
}

// Metrics are now exported to collector
_ = recorder.IncrementCounter(ctx, "requests_total")
```

### Why Deferred Initialization?

OTLP initialization is deferred to:
- Use the application lifecycle context for network connections
- Enable proper graceful shutdown
- Avoid establishing connections during configuration

### Export Interval

OTLP exports metrics periodically (default: 30 seconds):

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithExportInterval(10 * time.Second),  // Export every 10s
    metrics.WithServiceName("my-service"),
)
```

### Force Flush

Force immediate export before the next interval:

```go
// Ensure all metrics are sent immediately
if err := recorder.ForceFlush(ctx); err != nil {
    log.Printf("Failed to flush metrics: %v", err)
}
```

Use cases:
- Before deployment or shutdown
- Checkpointing during long operations
- Guaranteeing metric visibility

### OpenTelemetry Collector Setup

Example collector configuration:

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  logging:
    loglevel: debug

service:
  pipelines:
    metrics:
      receivers: [otlp]
      exporters: [prometheus, logging]
```

Run the collector:

```bash
otel-collector --config=otel-collector-config.yaml
```

## Stdout Provider

The stdout provider prints metrics to the console. Ideal for development and debugging.

### Basic Configuration

```go
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("my-service"),
)
```

### Initialization Behavior

The stdout provider:
1. Initializes immediately in `New()`
2. Works without calling `Start()` (but calling it is harmless)
3. Prints metrics to stdout periodically

```go
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("my-service"),
)

// Optional: Start() does nothing for stdout but doesn't hurt
recorder.Start(context.Background())

// Metrics are printed to stdout
_ = recorder.IncrementCounter(ctx, "requests_total")
```

### Export Interval

Configure how often metrics are printed (default: 30 seconds):

```go
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithExportInterval(5 * time.Second),  // Print every 5s
    metrics.WithServiceName("my-service"),
)
```

### Example Output

```json
{
  "Resource": {
    "service.name": "my-service",
    "service.version": "v1.0.0"
  },
  "ScopeMetrics": [
    {
      "Scope": {
        "Name": "rivaas.dev/metrics"
      },
      "Metrics": [
        {
          "Name": "http_requests_total",
          "Data": {
            "DataPoints": [
              {
                "Attributes": {
                  "method": "GET",
                  "path": "/api/users",
                  "status": "200"
                },
                "Value": 42
              }
            ]
          }
        }
      ]
    }
  ]
}
```

### Use Cases

- Local development
- Debugging metric collection
- CI/CD pipeline validation
- Unit tests (with `TestingRecorder`)

## Provider Comparison

### Prometheus

**Pros**:
- Industry standard for metrics
- Rich ecosystem (dashboards, alerting)
- Simple pull-based model
- No external dependencies

**Cons**:
- Requires network port
- Pull-based (can't push on-demand)
- Requires Prometheus server setup

**Best For**: Production services, microservices, containerized applications

### OTLP

**Pros**:
- Vendor-neutral standard
- Flexible routing via collector
- Push-based (immediate export)
- Integrates with OpenTelemetry tracing

**Cons**:
- Requires collector setup
- More complex infrastructure
- Network dependency

**Best For**: OpenTelemetry-native applications, multi-vendor observability, cloud environments

### Stdout

**Pros**:
- No external dependencies
- Immediate visibility
- Simple setup
- Works everywhere

**Cons**:
- Not for production
- No aggregation or visualization
- High output volume
- No persistence

**Best For**: Development, debugging, testing, CI/CD pipelines

## Choosing a Provider

### Development

Use **stdout** for quick feedback:

```go
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("dev-service"),
)
```

### Production (Simple)

Use **Prometheus** for straightforward monitoring:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithStrictPort(),
    metrics.WithServiceName("my-service"),
    metrics.WithServiceVersion("v1.2.3"),
)
```

### Production (OpenTelemetry)

Use **OTLP** for OpenTelemetry-native environments:

```go
recorder := metrics.MustNew(
    metrics.WithOTLP(os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")),
    metrics.WithServiceName("my-service"),
    metrics.WithServiceVersion(version),
)
```

### Testing

Use testing utilities (based on stdout):

```go
func TestHandler(t *testing.T) {
    recorder := metrics.TestingRecorder(t, "test-service")
    // Test code...
}
```

## Multiple Recorder Instances

You can create multiple recorder instances with different providers:

```go
// Development recorder (stdout)
devRecorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("dev-metrics"),
)

// Production recorder (Prometheus)
prodRecorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("prod-metrics"),
)

// Both work independently without conflicts
```

**Note**: By default, recorders do NOT set the global OpenTelemetry meter provider. See [Configuration](../configuration/#global-meter-provider) for details.

## Next Steps

- Learn [Configuration](../configuration/) for advanced provider options
- Explore [Custom Metrics](../custom-metrics/) to record your own data
- See [Testing](../testing/) for provider-specific test utilities
