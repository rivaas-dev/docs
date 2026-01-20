---
title: "Tracer Options"
description: "All configuration options for Tracer initialization"
weight: 2
---

Complete reference for all `Option` functions used to configure the `Tracer`.

## Option Type

```go
type Option func(*Tracer)
```

Configuration option function type used with `New()` and `MustNew()`. Options are applied during Tracer creation.

## Service Configuration Options

### WithServiceName

```go
func WithServiceName(name string) Option
```

Sets the service name for tracing. This name appears in span attributes as `service.name`.

**Parameters:**
- `name`: Service identifier like `"user-api"` or `"order-service"`.

**Default:** `"rivaas-service"`

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("user-api"),
)
```

### WithServiceVersion

```go
func WithServiceVersion(version string) Option
```

Sets the service version for tracing. This version appears in span attributes as `service.version`.

**Parameters:**
- `version`: Service version like `"v1.2.3"` or `"dev"`.

**Default:** `"1.0.0"`

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("user-api"),
    tracing.WithServiceVersion("v1.2.3"),
)
```

## Provider Options

Only one provider can be configured at a time. Configuring multiple providers results in a validation error.

### WithNoop

```go
func WithNoop() Option
```

Configures noop provider. This is the default. No traces are exported. Use for testing or when tracing is disabled.

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithNoop(),
)
```

### WithStdout

```go
func WithStdout() Option
```

Configures stdout provider for development/debugging. Traces are printed to standard output in pretty-printed JSON format.

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(),
)
```

### WithOTLP

```go
func WithOTLP(endpoint string, opts ...OTLPOption) Option
```

Configures OTLP gRPC provider with endpoint. Use this for production deployments with OpenTelemetry collectors.

**Parameters:**
- `endpoint`: OTLP endpoint in format `"host:port"` (e.g., `"localhost:4317"`)
- `opts`: Optional OTLP-specific options (e.g., `OTLPInsecure()`)

**Requires:** Call `tracer.Start(ctx)` before tracing

**Example:**

```go
// Secure (TLS enabled by default)
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("collector.example.com:4317"),
)

// Insecure (local development)
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317", tracing.OTLPInsecure()),
)
```

### WithOTLPHTTP

```go
func WithOTLPHTTP(endpoint string) Option
```

Configures OTLP HTTP provider with endpoint. Use this when gRPC is not available or HTTP is preferred.

**Parameters:**
- `endpoint`: OTLP HTTP endpoint with protocol (e.g., `"http://localhost:4318"`, `"https://collector:4318"`)

**Requires:** Call `tracer.Start(ctx)` before tracing

**Example:**

```go
// HTTP (insecure - development)
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLPHTTP("http://localhost:4318"),
)

// HTTPS (secure - production)
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLPHTTP("https://collector.example.com:4318"),
)
```

## OTLP Options

### OTLPInsecure

```go
func OTLPInsecure() OTLPOption
```

Enables insecure gRPC for OTLP. Default is false (uses TLS). Set to true for local development.

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317", tracing.OTLPInsecure()),
)
```

## Sampling Options

### WithSampleRate

```go
func WithSampleRate(rate float64) Option
```

Sets the sampling rate (0.0 to 1.0). Values outside this range are clamped to valid bounds.

A rate of 1.0 samples all requests, 0.5 samples 50%, and 0.0 samples none. Sampling decisions are made per-request based on the configured rate.

**Parameters:**
- `rate`: Sampling rate between 0.0 and 1.0

**Default:** `1.0` (100% sampling)

**Example:**

```go
// Sample 10% of requests
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithSampleRate(0.1),
)
```

## Hook Options

### WithSpanStartHook

```go
func WithSpanStartHook(hook SpanStartHook) Option
```

Sets a callback that is invoked when a request span is started. The hook receives the context, span, and HTTP request, allowing custom attribute injection, dynamic sampling decisions, or integration with APM tools.

**Type:**
```go
type SpanStartHook func(ctx context.Context, span trace.Span, req *http.Request)
```

**Example:**

```go
startHook := func(ctx context.Context, span trace.Span, req *http.Request) {
    if tenantID := req.Header.Get("X-Tenant-ID"); tenantID != "" {
        span.SetAttributes(attribute.String("tenant.id", tenantID))
    }
}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithSpanStartHook(startHook),
)
```

### WithSpanFinishHook

```go
func WithSpanFinishHook(hook SpanFinishHook) Option
```

Sets a callback that is invoked when a request span is finished. The hook receives the span and HTTP status code, allowing custom metrics recording, logging, or post-processing.

**Type:**
```go
type SpanFinishHook func(span trace.Span, statusCode int)
```

**Example:**

```go
finishHook := func(span trace.Span, statusCode int) {
    if statusCode >= 500 {
        metrics.IncrementServerErrors()
    }
}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithSpanFinishHook(finishHook),
)
```

## Logging Options

### WithLogger

```go
func WithLogger(logger *slog.Logger) Option
```

Sets the logger for internal operational events using the default event handler. This is a convenience wrapper around `WithEventHandler` that logs events to the provided `slog.Logger`.

**Parameters:**
- `logger`: `*slog.Logger` for logging internal events

**Example:**

```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
}))

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithLogger(logger),
)
```

### WithEventHandler

```go
func WithEventHandler(handler EventHandler) Option
```

Sets a custom event handler for internal operational events. Use this for advanced use cases like sending errors to Sentry, custom alerting, or integrating with non-slog logging systems.

**Type:**
```go
type EventHandler func(Event)
```

**Example:**

```go
eventHandler := func(e tracing.Event) {
    switch e.Type {
    case tracing.EventError:
        sentry.CaptureMessage(e.Message)
        myLogger.Error(e.Message, e.Args...)
    case tracing.EventWarning:
        myLogger.Warn(e.Message, e.Args...)
    case tracing.EventInfo:
        myLogger.Info(e.Message, e.Args...)
    case tracing.EventDebug:
        myLogger.Debug(e.Message, e.Args...)
    }
}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithEventHandler(eventHandler),
)
```

## Advanced Options

### WithTracerProvider

```go
func WithTracerProvider(provider trace.TracerProvider) Option
```

Allows you to provide a custom OpenTelemetry TracerProvider. When using this option, the package will NOT set the global `otel.SetTracerProvider()` by default. Use `WithGlobalTracerProvider()` if you want global registration.

**Use cases:**
- Manage tracer provider lifecycle yourself
- Need multiple independent tracing configurations
- Want to avoid global state in your application

**Important:** When using `WithTracerProvider`, provider options (`WithOTLP`, `WithStdout`, etc.) are ignored since you're managing the provider yourself. You are also responsible for calling `Shutdown()` on your provider.

**Example:**

```go
import sdktrace "go.opentelemetry.io/otel/sdk/trace"

tp := sdktrace.NewTracerProvider(
    // Your custom configuration
    sdktrace.WithSampler(sdktrace.AlwaysSample()),
)

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithTracerProvider(tp),
)

// You manage tp.Shutdown() yourself
defer tp.Shutdown(context.Background())
```

### WithCustomTracer

```go
func WithCustomTracer(tracer trace.Tracer) Option
```

Allows using a custom OpenTelemetry tracer. This is useful when you need specific tracer configuration or want to use a tracer from an existing OpenTelemetry setup.

**Example:**

```go
tp := trace.NewTracerProvider(...)
customTracer := tp.Tracer("my-tracer")

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithCustomTracer(customTracer),
)
```

### WithCustomPropagator

```go
func WithCustomPropagator(propagator propagation.TextMapPropagator) Option
```

Allows using a custom OpenTelemetry propagator. This is useful for custom trace context propagation formats. By default, uses the global propagator from `otel.GetTextMapPropagator()` (W3C Trace Context).

**Example:**

```go
import "go.opentelemetry.io/otel/propagation"

// Use W3C Trace Context explicitly
prop := propagation.TraceContext{}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithCustomPropagator(prop),
)
```

**Using B3 propagation:**

```go
import "go.opentelemetry.io/contrib/propagators/b3"

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithCustomPropagator(b3.New()),
)
```

### WithGlobalTracerProvider

```go
func WithGlobalTracerProvider() Option
```

Registers the tracer provider as the global OpenTelemetry tracer provider via `otel.SetTracerProvider()`. By default, tracer providers are not registered globally to allow multiple tracing configurations to coexist in the same process.

**Use when:**
- You want `otel.GetTracerProvider()` to return your tracer
- Integrating with libraries that use the global tracer
- Single tracer for entire application

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317"),
    tracing.WithGlobalTracerProvider(), // Register globally
)
```

## Option Combinations

### Development Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithServiceVersion("dev"),
    tracing.WithStdout(),
    tracing.WithSampleRate(1.0),
    tracing.WithLogger(slog.Default()),
)
```

### Production Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("user-api"),
    tracing.WithServiceVersion(os.Getenv("VERSION")),
    tracing.WithOTLP(os.Getenv("OTLP_ENDPOINT")),
    tracing.WithSampleRate(0.1),
    tracing.WithSpanStartHook(enrichSpan),
    tracing.WithSpanFinishHook(recordMetrics),
)
```

### Testing Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("test-service"),
    tracing.WithServiceVersion("v1.0.0"),
    tracing.WithNoop(),
    tracing.WithSampleRate(1.0),
)
```

## Validation Errors

Configuration is validated when calling `New()` or `MustNew()`. Common validation errors:

### Multiple Providers

```go
// ✗ Error: multiple providers configured
tracer, err := tracing.New(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(),
    tracing.WithOTLP("localhost:4317"), // Error!
)
// Returns: "validation errors: provider: multiple providers configured"
```

**Solution:** Only configure one provider.

### Empty Service Name

```go
// ✗ Error: service name cannot be empty
tracer, err := tracing.New(
    tracing.WithServiceName(""),
)
// Returns: "invalid configuration: serviceName: cannot be empty"
```

**Solution:** Always provide a service name.

### Invalid Sample Rate

```go
// Values are automatically clamped
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithSampleRate(1.5), // Clamped to 1.0
)
```

Sample rates outside 0.0-1.0 are automatically clamped to valid bounds.

## Complete Option Reference

| Option | Description | Default |
|--------|-------------|---------|
| `WithServiceName(name)` | Set service name | `"rivaas-service"` |
| `WithServiceVersion(version)` | Set service version | `"1.0.0"` |
| `WithNoop()` | Noop provider | Yes (default) |
| `WithStdout()` | Stdout provider | - |
| `WithOTLP(endpoint, opts...)` | OTLP gRPC provider | - |
| `WithOTLPHTTP(endpoint)` | OTLP HTTP provider | - |
| `WithSampleRate(rate)` | Sampling rate (0.0-1.0) | `1.0` |
| `WithSpanStartHook(hook)` | Span start callback | - |
| `WithSpanFinishHook(hook)` | Span finish callback | - |
| `WithLogger(logger)` | Set slog logger | - |
| `WithEventHandler(handler)` | Custom event handler | - |
| `WithTracerProvider(provider)` | Custom tracer provider | - |
| `WithCustomTracer(tracer)` | Custom tracer | - |
| `WithCustomPropagator(prop)` | Custom propagator | W3C Trace Context |
| `WithGlobalTracerProvider()` | Register globally | No |

## Next Steps

- Review [Middleware Options](../middleware-options/) for HTTP middleware configuration
- Check [API Reference](../api-reference/) for all methods
- See the [Configuration Guide](/guides/tracing/configuration/) for usage examples
