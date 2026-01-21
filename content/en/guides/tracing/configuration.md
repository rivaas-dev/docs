---
title: "Configuration"
description: "Configure service metadata, sampling, hooks, and logging"
weight: 4
keywords:
  - tracing configuration
  - exporters
  - sampling
  - options
---

Configure your tracer with service information, sampling rates, lifecycle hooks, and logging integration.

## Service Configuration

Set service metadata that appears in every span.

### Service Name

The service name identifies your application in traces:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("user-api"),
    tracing.WithStdout(),
)
```

**Best practices:**
- Use descriptive, consistent names across services.
- Use kebab-case: `user-api`, `order-service`, `payment-gateway`.
- Avoid generic names like `api` or `service`.

### Service Version

Track which version of your service created traces:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("user-api"),
    tracing.WithServiceVersion("v1.2.3"),
    tracing.WithStdout(),
)
```

**Best practices:**
- Use semantic versioning: `v1.2.3`.
- Include in CI/CD builds.
- Track version across deployments.

### Combined Example

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("user-api"),
    tracing.WithServiceVersion("v1.2.3"),
    tracing.WithOTLP("collector:4317"),
)
```

These attributes appear in every span:
- `service.name`: `"user-api"`
- `service.version`: `"v1.2.3"`

## Sampling Configuration

Control which requests are traced to reduce overhead and costs.

### Sample Rate

Set the percentage of requests to trace (0.0 to 1.0):

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSampleRate(0.1), // Trace 10% of requests
    tracing.WithOTLP("collector:4317"),
)
```

**Sample rates:**
- `1.0`: 100% sampling. All requests traced.
- `0.5`: 50% sampling.
- `0.1`: 10% sampling.
- `0.01`: 1% sampling.
- `0.0`: 0% sampling (no traces)

### Sampling Examples

```go
// Development: trace everything
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSampleRate(1.0),
    tracing.WithStdout(),
)

// Production: trace 10% of requests
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSampleRate(0.1),
    tracing.WithOTLP("collector:4317"),
)

// High-traffic: trace 1% of requests
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSampleRate(0.01),
    tracing.WithOTLP("collector:4317"),
)
```

### Sampling Behavior

- **Probabilistic**: Uses deterministic hashing for consistent sampling
- **Request-level**: Decision made once per request, all child spans included
- **Zero overhead**: Non-sampled requests skip span creation entirely

### When to Sample

| Traffic Level | Recommended Sample Rate |
|--------------|-------------------------|
| < 100 req/s | 1.0 (100%) |
| 100-1000 req/s | 0.5 (50%) |
| 1000-10000 req/s | 0.1 (10%) |
| > 10000 req/s | 0.01 (1%) |

Adjust based on:
- Trace backend capacity
- Storage costs
- Desired trace coverage
- Debug vs production needs

## Span Lifecycle Hooks

Add custom logic when spans start or finish.

### Span Start Hook

Execute code when a request span is created:

```go
import (
    "context"
    "net/http"
    
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/trace"
    "rivaas.dev/tracing"
)

startHook := func(ctx context.Context, span trace.Span, req *http.Request) {
    // Add custom attributes
    if tenantID := req.Header.Get("X-Tenant-ID"); tenantID != "" {
        span.SetAttributes(attribute.String("tenant.id", tenantID))
    }
    
    // Add user information
    if userID := req.Header.Get("X-User-ID"); userID != "" {
        span.SetAttributes(attribute.String("user.id", userID))
    }
    
    // Record custom business context
    span.SetAttributes(
        attribute.String("request.region", getRegionFromIP(req)),
        attribute.Bool("request.is_mobile", isMobileRequest(req)),
    )
}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSpanStartHook(startHook),
    tracing.WithOTLP("collector:4317"),
)
```

**Use cases:**
- Add tenant/user identifiers
- Record business context
- Integrate with feature flags
- Custom sampling decisions
- APM tool integration

### Span Finish Hook

Execute code when a request span completes:

```go
import (
    "go.opentelemetry.io/otel/trace"
    "rivaas.dev/tracing"
)

finishHook := func(span trace.Span, statusCode int) {
    // Record custom metrics
    if statusCode >= 500 {
        metrics.IncrementServerErrors()
    }
    
    // Log slow requests
    if span.SpanContext().IsValid() {
        // Calculate duration and log if > threshold
    }
    
    // Send alerts for errors
    if statusCode >= 500 {
        alerting.SendAlert("Server error", statusCode)
    }
}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSpanFinishHook(finishHook),
    tracing.WithOTLP("collector:4317"),
)
```

**Use cases:**
- Record custom metrics
- Log slow requests
- Send error alerts
- Update counters
- Cleanup resources

### Combined Hooks Example

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithSpanStartHook(func(ctx context.Context, span trace.Span, req *http.Request) {
        // Enrich span with business context
        span.SetAttributes(
            attribute.String("tenant.id", extractTenant(req)),
            attribute.String("feature.flags", getFeatureFlags(req)),
        )
    }),
    tracing.WithSpanFinishHook(func(span trace.Span, statusCode int) {
        // Record completion metrics
        recordRequestMetrics(statusCode)
    }),
    tracing.WithOTLP("collector:4317"),
)
```

## Logging Integration

Integrate tracing with your logging infrastructure.

### Using slog

Use Go's standard `log/slog` package:

```go
import (
    "log/slog"
    "os"
    
    "rivaas.dev/tracing"
)

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
}))

tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithLogger(logger),
    tracing.WithOTLP("collector:4317"),
)
```

The logger receives internal tracing events:
- Tracer initialization
- Provider startup/shutdown
- Configuration warnings
- Error conditions

### Event Levels

Events are logged at appropriate levels:

| Event Type | Log Level | Example |
|------------|-----------|---------|
| Error | `ERROR` | "Failed to export spans" |
| Warning | `WARN` | "OTLP endpoint not specified" |
| Info | `INFO` | "Tracing initialized" |
| Debug | `DEBUG` | "Request not sampled" |

### Custom Event Handler

For non-slog logging or custom event handling:

```go
import "rivaas.dev/tracing"

eventHandler := func(e tracing.Event) {
    switch e.Type {
    case tracing.EventError:
        // Send to error tracking (e.g., Sentry)
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
    tracing.WithServiceName("my-api"),
    tracing.WithEventHandler(eventHandler),
    tracing.WithOTLP("collector:4317"),
)
```

**Use cases:**
- Integrate with non-slog loggers (zap, zerolog, logrus)
- Send errors to Sentry/Rollbar
- Custom alerting
- Audit logging
- Metrics from events

### No Logging

To disable all internal logging:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    // No WithLogger or WithEventHandler = no logging
    tracing.WithOTLP("collector:4317"),
)
```

## Advanced Configuration

### Custom Propagator

Use a custom trace context propagation format:

```go
import (
    "go.opentelemetry.io/otel/propagation"
    "rivaas.dev/tracing"
)

// Use B3 propagation format (Zipkin)
b3Propagator := propagation.NewCompositeTextMapPropagator(
    propagation.B3{},
)

tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithCustomPropagator(b3Propagator),
    tracing.WithOTLP("collector:4317"),
)
```

### Custom Tracer Provider

Provide your own OpenTelemetry tracer provider:

```go
import (
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    "rivaas.dev/tracing"
)

// Create custom tracer provider
tp := sdktrace.NewTracerProvider(
    // Your custom configuration
    sdktrace.WithSampler(sdktrace.AlwaysSample()),
)

tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithTracerProvider(tp),
)

// You manage tp.Shutdown() yourself
defer tp.Shutdown(context.Background())
```

**Note**: When using `WithTracerProvider`, you're responsible for shutting down the provider.

### Global Tracer Provider

Register as the global OpenTelemetry tracer provider:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithOTLP("collector:4317"),
    tracing.WithGlobalTracerProvider(), // Register globally
)
```

By default, tracers are **not** registered globally. Use this option when:
- You want `otel.GetTracerProvider()` to return your tracer
- Integrating with libraries that use the global tracer
- Single tracer for entire application

## Configuration Patterns

### Development Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithServiceVersion("dev"),
    tracing.WithStdout(),
    tracing.WithSampleRate(1.0), // Trace everything
    tracing.WithLogger(slog.Default()),
)
```

### Production Configuration

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("user-api"),
    tracing.WithServiceVersion(version), // From build
    tracing.WithOTLP(otlpEndpoint),      // From env
    tracing.WithSampleRate(0.1),         // 10% sampling
    tracing.WithSpanStartHook(enrichSpan),
    tracing.WithSpanFinishHook(recordMetrics),
)
```

### Environment-Based Configuration

```go
func createTracer(env string) *tracing.Tracer {
    opts := []tracing.Option{
        tracing.WithServiceName("my-api"),
        tracing.WithServiceVersion(getVersion()),
    }
    
    switch env {
    case "production":
        opts = append(opts,
            tracing.WithOTLP(os.Getenv("OTLP_ENDPOINT")),
            tracing.WithSampleRate(0.1),
        )
    case "staging":
        opts = append(opts,
            tracing.WithOTLP(os.Getenv("OTLP_ENDPOINT")),
            tracing.WithSampleRate(0.5),
        )
    default: // development
        opts = append(opts,
            tracing.WithStdout(),
            tracing.WithSampleRate(1.0),
            tracing.WithLogger(slog.Default()),
        )
    }
    
    return tracing.MustNew(opts...)
}
```

## Next Steps

- Set up [Middleware](../middleware/) for automatic HTTP tracing
- Learn [Context Propagation](../context-propagation/) for distributed traces
- Explore [Examples](../examples/) for complete configurations
- Check [API Reference](/reference/packages/tracing/options/) for all options
