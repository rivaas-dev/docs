---
title: "Diagnostics"
linkTitle: "Diagnostics"
keywords:
  - router diagnostics
  - debugging
  - diagnostic events
  - troubleshooting
weight: 60
description: >
  Diagnostic event types and handling.
---

The router emits optional diagnostic events for security concerns and configuration issues.

## Event Types

### `DiagXFFSuspicious`

Suspicious X-Forwarded-For chain detected (>10 IPs).

**Fields:**

- `chain` (string) - The full X-Forwarded-For header value
- `count` (int) - Number of IPs in the chain

```go
handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    if e.Kind == router.DiagXFFSuspicious {
        log.Printf("Suspicious XFF chain: %s (count: %d)", 
            e.Fields["chain"], e.Fields["count"])
    }
})
```

### `DiagHeaderInjection`

Header injection attempt blocked and sanitized.

**Fields:**

- `header` (string) - Header name
- `value` (string) - Original value
- `sanitized` (string) - Sanitized value

### `DiagInvalidProto`

Invalid X-Forwarded-Proto value.

**Fields:**

- `proto` (string) - Invalid protocol value

### `DiagHighParamCount`

Route has >8 parameters (uses map storage instead of array).

**Fields:**

- `method` (string) - HTTP method
- `path` (string) - Route path
- `param_count` (int) - Number of parameters

### `DiagH2CEnabled`

H2C enabled (development warning).

**Fields:**

- None

## Enabling Diagnostics

```go
import "log/slog"

handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    slog.Warn(e.Message, "kind", e.Kind, "fields", e.Fields)
})

r := router.New(router.WithDiagnostics(handler))
```

## Handler Examples

### With Logging

```go
import "log/slog"

handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    slog.Warn(e.Message, 
        "kind", e.Kind, 
        "fields", e.Fields,
    )
})
```

### With Metrics

```go
handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    metrics.Increment("router.diagnostics", 
        "kind", string(e.Kind),
    )
})
```

### With OpenTelemetry

```go
import (
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/trace"
)

handler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
    span := trace.SpanFromContext(ctx)
    if span.IsRecording() {
        attrs := []attribute.KeyValue{
            attribute.String("diagnostic.kind", string(e.Kind)),
        }
        for k, v := range e.Fields {
            attrs = append(attrs, attribute.String(k, fmt.Sprint(v)))
        }
        span.AddEvent(e.Message, trace.WithAttributes(attrs...))
    }
})
```

## Complete Example

```go
package main

import (
    "log/slog"
    "net/http"
    "os"
    
    "rivaas.dev/router"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    
    // Diagnostic handler
    diagHandler := router.DiagnosticHandlerFunc(func(e router.DiagnosticEvent) {
        logger.Warn(e.Message,
            "kind", e.Kind,
            "fields", e.Fields,
        )
    })
    
    // Create router with diagnostics
    r := router.New(router.WithDiagnostics(diagHandler))
    
    r.GET("/", func(c *router.Context) {
        c.JSON(200, map[string]string{"message": "Hello"})
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Best Practices

1. **Log diagnostic events** for security monitoring
2. **Track metrics** for diagnostic event frequency
3. **Alert on suspicious patterns** (e.g., repeated XFF warnings)
4. **Don't ignore warnings** - they indicate potential issues

## Next Steps

- **Options**: See [Router options](../options/) for `WithDiagnostics()`
- **Observability**: Learn about [observability features](/guides/router/observability/)
