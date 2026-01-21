---
title: "Tracing Providers"
description: "Choose and configure trace exporters for your application"
weight: 3
keywords:
  - tracing providers
  - jaeger
  - otlp
  - stdout
---

The tracing package supports multiple providers for exporting traces. Choose the provider that best fits your environment and infrastructure.

## Available Providers

| Provider | Use Case | Network Required | Best For |
|----------|----------|------------------|----------|
| **Noop** | Default, no traces | No | Testing, disabled tracing |
| **Stdout** | Console output | No | Development, debugging |
| **OTLP (gRPC)** | OpenTelemetry collector | Yes | Production (preferred) |
| **OTLP (HTTP)** | OpenTelemetry collector | Yes | Production (alternative) |

## Basic Configuration

{{< tabpane persist=header >}}
{{< tab header="Noop" lang="go" >}}
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithNoop(),
)
defer tracer.Shutdown(context.Background())
{{< /tab >}}
{{< tab header="Stdout" lang="go" >}}
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(),
)
defer tracer.Shutdown(context.Background())
{{< /tab >}}
{{< tab header="OTLP (gRPC)" lang="go" >}}
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithServiceVersion("v1.0.0"),
    tracing.WithOTLP("localhost:4317"),
)
if err := tracer.Start(context.Background()); err != nil {
    log.Fatal(err)
}
defer tracer.Shutdown(context.Background())
{{< /tab >}}
{{< tab header="OTLP (HTTP)" lang="go" >}}
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithServiceVersion("v1.0.0"),
    tracing.WithOTLPHTTP("http://localhost:4318"),
)
if err := tracer.Start(context.Background()); err != nil {
    log.Fatal(err)
}
defer tracer.Shutdown(context.Background())
{{< /tab >}}
{{< /tabpane >}}

## Noop Provider

The noop provider doesn't export any traces. It's the default when no provider is configured.

### When to Use

- Testing environments where tracing isn't needed
- Temporarily disabling tracing without code changes
- Safe default for new projects

### Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithNoop(),
)
defer tracer.Shutdown(context.Background())
```

Or simply omit the provider option (noop is the default):

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    // No provider = Noop
)
```

### Behavior

- Spans are created but not recorded
- No network calls or file I/O
- Minimal performance overhead
- Safe for production if tracing is disabled

## Stdout Provider

The stdout provider prints traces to standard output in a human-readable format.

### When to Use

- Local development and debugging
- Troubleshooting span creation and attributes
- Testing trace propagation
- Quick validation of tracing logic

### Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(),
)
defer tracer.Shutdown(context.Background())
```

### Output Format

Traces are printed as pretty-printed JSON to stdout:

```json
{
  "Name": "GET /api/users",
  "SpanContext": {
    "TraceID": "3f3c5e4d...",
    "SpanID": "a1b2c3d4...",
    "TraceFlags": "01"
  },
  "Parent": {
    "TraceID": "3f3c5e4d...",
    "SpanID": "e5f6g7h8..."
  },
  "SpanKind": "Server",
  "StartTime": "2025-01-18T10:15:30.123Z",
  "EndTime": "2025-01-18T10:15:30.456Z",
  "Attributes": [
    {
      "Key": "http.method",
      "Value": {"Type": "STRING", "Value": "GET"}
    }
  ]
}
```

### Limitations

- **Not for production**: Output can be noisy and slow
- **No persistence**: Traces are only printed, not stored
- **No visualization**: Use an actual backend for trace visualization

## OTLP Provider (gRPC)

The OTLP gRPC provider exports traces to an OpenTelemetry collector using the gRPC protocol.

### When to Use

- Production environments
- OpenTelemetry collector infrastructure
- Jaeger, Zipkin, or other OTLP-compatible backends
- Best performance and reliability

### Basic Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithServiceVersion("v1.0.0"),
    tracing.WithOTLP("localhost:4317"),
)

// Start is required for OTLP providers
if err := tracer.Start(context.Background()); err != nil {
    log.Fatal(err)
}

defer tracer.Shutdown(context.Background())
```

### Secure Connection (TLS)

By default, OTLP uses TLS:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("collector.example.com:4317"),
    // TLS is enabled by default
)
```

### Insecure Connection (Development)

For local development without TLS:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317", tracing.OTLPInsecure()),
)
```

### Configuration Options

```go
import "rivaas.dev/tracing"

// Secure (production)
tracing.WithOTLP("collector.example.com:4317")

// Insecure (development)
tracing.WithOTLP("localhost:4317", tracing.OTLPInsecure())
```

## OTLP Provider (HTTP)

The OTLP HTTP provider exports traces to an OpenTelemetry collector using the HTTP protocol.

### When to Use

- Alternative to gRPC when firewalls block gRPC
- Simpler infrastructure without gRPC support
- HTTP-only environments
- Debugging with curl/httpie

### Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithServiceVersion("v1.0.0"),
    tracing.WithOTLPHTTP("http://localhost:4318"),
)

// Start is required for OTLP providers
if err := tracer.Start(context.Background()); err != nil {
    log.Fatal(err)
}

defer tracer.Shutdown(context.Background())
```

### HTTPS Endpoint

Use HTTPS for secure connections:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLPHTTP("https://collector.example.com:4318"),
)
```

### Endpoint Format

The endpoint should include the protocol:

```go
// HTTP (insecure - development only)
tracing.WithOTLPHTTP("http://localhost:4318")

// HTTPS (secure - production)
tracing.WithOTLPHTTP("https://collector.example.com:4318")
```

## Provider Comparison

### Performance

| Provider | Latency | Throughput | CPU | Memory |
|----------|---------|------------|-----|--------|
| Noop | ~10ns | Unlimited | Minimal | Minimal |
| Stdout | ~100µs | Low | Low | Low |
| OTLP (gRPC) | ~1-2ms | High | Low | Medium |
| OTLP (HTTP) | ~2-3ms | Medium | Low | Medium |

### Use Case Matrix

```go
// Development
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithStdout(), // ← See traces in console
)

// Testing
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithNoop(), // ← No tracing overhead
)

// Production (recommended)
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithOTLP("collector:4317"), // ← gRPC to collector
)

// Production (HTTP alternative)
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithOTLPHTTP("https://collector:4318"), // ← HTTP to collector
)
```

## Switching Providers

Only one provider can be configured at a time. Attempting to configure multiple providers results in a validation error:

```go
// ✗ Error: multiple providers configured
tracer, err := tracing.New(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(),
    tracing.WithOTLP("localhost:4317"), // Error!
)
// Returns: "validation errors: provider: multiple providers configured"
```

To switch providers, use environment variables or configuration:

```go
func createTracer(env string) *tracing.Tracer {
    opts := []tracing.Option{
        tracing.WithServiceName("my-service"),
        tracing.WithServiceVersion("v1.0.0"),
    }
    
    switch env {
    case "production":
        opts = append(opts, tracing.WithOTLP("collector:4317"))
    case "development":
        opts = append(opts, tracing.WithStdout())
    default:
        opts = append(opts, tracing.WithNoop())
    }
    
    return tracing.MustNew(opts...)
}
```

## OpenTelemetry Collector Setup

For OTLP providers, you need an OpenTelemetry collector.

### Docker Compose Example

```yaml
version: '3.8'
services:
  otel-collector:
    image: otel/opentelemetry-collector:latest
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "13133:13133" # health_check
```

### Collector Configuration

Basic `otel-collector-config.yaml`:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  logging:
    loglevel: debug
  # Add your backend (Jaeger, Zipkin, etc.)
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging, jaeger]
```

## Provider Selection Guide

### Choose Noop When:
- Tracing is disabled via feature flags
- Running in CI/CD without trace backend
- Performance testing without observability overhead

### Choose Stdout When:
- Developing locally and need to see traces
- Debugging span creation and attributes
- Quick validation of tracing setup

### Choose OTLP (gRPC) When:
- Deploying to production
- Need high throughput and low latency
- Using OpenTelemetry collector
- Standard production setup

### Choose OTLP (HTTP) When:
- gRPC is blocked by firewalls
- Simpler infrastructure requirements
- Need HTTP-friendly debugging
- Backend only supports HTTP

## Next Steps

- Learn [Configuration](../configuration/) options for service metadata and sampling
- Set up [Middleware](../middleware/) for automatic HTTP tracing
- Explore [Examples](../examples/) for production-ready configurations
