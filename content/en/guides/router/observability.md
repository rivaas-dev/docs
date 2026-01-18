---
title: "Observability"
linkTitle: "Observability"
weight: 120
description: >
  Native OpenTelemetry tracing support with zero overhead when disabled, plus diagnostic events.
---

The router includes native OpenTelemetry tracing support and optional diagnostic events.

## OpenTelemetry Tracing

### Enable Tracing

```go
r := router.New(router.WithTracing())
```

### Configuration Options

```go
r := router.New(
    router.WithTracing(),
    router.WithTracingServiceName("my-api"),
    router.WithTracingServiceVersion("v1.2.3"),
    router.WithTracingSampleRate(0.1), // 10% sampling
    router.WithTracingExcludePaths("/health", "/metrics"),
)
```

### Context Tracing Methods

```go
func handler(c *router.Context) {
    // Get trace/span IDs
    traceID := c.TraceID()
    spanID := c.SpanID()
    
    // Add custom attributes
    c.SetSpanAttribute("user.id", "123")
    c.SetSpanAttribute("operation.type", "database_query")
    
    // Add events
    c.AddSpanEvent("processing_started")
    c.AddSpanEvent("cache_miss", 
        attribute.String("cache.key", "user:123"),
    )
}
```

### Complete Tracing Example

```go
package main

import (
    "context"
    "log"
    "net/http"
    
    "rivaas.dev/router"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/jaeger"
    "go.opentelemetry.io/otel/sdk/trace"
)

func main() {
    // Initialize Jaeger exporter
    exp, err := jaeger.New(jaeger.WithCollectorEndpoint(
        jaeger.WithEndpoint("http://localhost:14268/api/traces"),
    ))
    if err != nil {
        log.Fatal(err)
    }

    tp := trace.NewTracerProvider(
        trace.WithBatcher(exp),
        trace.WithSampler(trace.TraceIDRatioBased(0.1)),
    )
    otel.SetTracerProvider(tp)

    // Create router with tracing
    r := router.New(
        router.WithTracing(),
        router.WithTracingServiceName("my-service"),
    )
    
    r.GET("/", func(c *router.Context) {
        c.SetSpanAttribute("handler", "home")
        c.JSON(200, map[string]string{"message": "Hello"})
    })
    
    defer tp.Shutdown(context.Background())
    log.Fatal(http.ListenAndServe(":8080", r))
}
```

## Diagnostics

Enable diagnostic events for security concerns and configuration issues:

```go
import "log/slog"

handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    slog.Warn(e.Message, "kind", e.Kind, "fields", e.Fields)
})

r := router.New(router.WithDiagnostics(handler))
```

### Diagnostic Event Types

- **`DiagXFFSuspicious`** - Suspicious X-Forwarded-For chain detected
- **`DiagHeaderInjection`** - Header injection attempt blocked
- **`DiagInvalidProto`** - Invalid X-Forwarded-Proto value
- **`DiagHighParamCount`** - Route has >8 parameters (uses map storage)
- **`DiagH2CEnabled`** - H2C enabled (development warning)

### Example with Metrics

```go
handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    metrics.Increment("router.diagnostics", "kind", string(e.Kind))
})

r := router.New(router.WithDiagnostics(handler))
```

## Best Practices

1. **Use path exclusion** for high-frequency endpoints:
   ```go
   router.WithTracingExcludePaths("/health", "/metrics", "/ping")
   ```

2. **Set appropriate sampling rates** in production:
   ```go
   router.WithTracingSampleRate(0.01) // 1% sampling
   ```

3. **Add meaningful attributes** in handlers:
   ```go
   c.SetSpanAttribute("user.id", userID)
   c.SetSpanAttribute("operation.type", "database_query")
   ```

4. **Disable parameter recording** for sensitive data:
   ```go
   router.WithTracingDisableParams()
   ```

## Next Steps

- **Static Files**: Learn about [static file serving](../static-files/)
- **Testing**: See [testing patterns](../testing/)
