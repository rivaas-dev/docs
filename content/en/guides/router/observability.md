---
title: "Observability"
linkTitle: "Observability"
weight: 120
keywords:
  - router observability
  - tracing
  - metrics
  - opentelemetry
description: >
  OpenTelemetry support via the observability recorder interface, with zero overhead when disabled, plus diagnostic events.
---

The router provides OpenTelemetry support via the observability recorder interface and optional diagnostic events.

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

### Handler-level tracing

When you use the **router** on its own, get the span from the request context and use the **tracing** package helpers:

```go
import "rivaas.dev/tracing"

r.GET("/users/:id", func(c *router.Context) {
    tracing.SetSpanAttributeFromContext(c.RequestContext(), "user.id", c.Param("id"))
    tracing.AddSpanEventFromContext(c.RequestContext(), "fetching_user")
    // ...
})
```

When you use the **app** package, your handlers receive `app.Context`, which has built-in methods: `c.TraceID()`, `c.SpanID()`, `c.SetSpanAttribute()`, `c.AddSpanEvent()`, and more. See the [app observability guide](/guides/app/observability/).

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

3. **Disable parameter recording** for sensitive data:
   ```go
   router.WithTracingDisableParams()
   ```

## Next Steps

- **Static Files**: Learn about [static file serving](../static-files/)
- **Testing**: See [testing patterns](../testing/)
