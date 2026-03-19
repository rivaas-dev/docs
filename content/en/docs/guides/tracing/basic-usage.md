---
title: "Basic Usage"
description: "Learn the fundamentals of creating tracers and managing spans"
weight: 2
keywords:
  - tracing basic usage
  - create spans
  - simple tracing
  - getting started
---

Learn how to create tracers, manage spans, and add tracing to your Go applications.

## Creating a Tracer

The `Tracer` is the main entry point for distributed tracing. Create one using functional options:

### With Error Handling

```go
tracer, err := tracing.New(
    tracing.WithServiceName("my-service"),
    tracing.WithServiceVersion("v1.0.0"),
    tracing.WithStdout(),
)
if err != nil {
    log.Fatalf("Failed to create tracer: %v", err)
}
defer tracer.Shutdown(context.Background())
```

### Panic on Error

For convenience, use `MustNew` which panics if initialization fails (the panic value is an `error` you can recover and unwrap with `errors.As` / `errors.Is`):

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithServiceVersion("v1.0.0"),
    tracing.WithStdout(),
)
defer tracer.Shutdown(context.Background())
```

## Tracer Lifecycle

### Starting the Tracer

For OTLP providers (gRPC and HTTP), you must call `Start()` before tracing:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317"),
)

// Start is required for OTLP providers
if err := tracer.Start(context.Background()); err != nil {
    log.Fatal(err)
}

defer tracer.Shutdown(context.Background())
```

{{< alert color="warning" >}}
With OTLP, forgetting `Start(ctx)` means **no traces** are exported and no error is returned; a one-time log warning is emitted when the first span is created.
{{< /alert >}}

{{< alert color="info" >}}
For Stdout and Noop providers, `Start()` is optional (they initialize immediately in `New()`). Use `tracer.RequiresStart()` and `tracer.IsStarted()` in tests or wiring to assert that Start was used when required.
{{< /alert >}}

### Shutting Down

Always shut down the tracer to flush pending spans:

```go
defer func() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    if err := tracer.Shutdown(ctx); err != nil {
        log.Printf("Error shutting down tracer: %v", err)
    }
}()
```

## Manual Span Management

Create and manage spans manually for detailed tracing:

### Minimal trace example

Copy-paste example: create a tracer, start a span, finish it, and shut down.

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(),
)
defer tracer.Shutdown(context.Background())

ctx, span := tracer.StartSpan(context.Background(), "my-operation")
defer tracer.FinishSpan(span)
// ... use ctx and span ...
```

### Basic Span Creation

Use `FinishSpan(span)` for success (no HTTP status). Use `FinishSpanWithHTTPStatus(span, statusCode)` when you have an HTTP status (e.g. request-level spans).

```go
func processData(ctx context.Context, tracer *tracing.Tracer) {
    ctx, span := tracer.StartSpan(ctx, "process-data")
    defer tracer.FinishSpan(span)
    // Your code here...
}
```

### Adding Attributes

Add attributes to provide context about the operation:

```go
ctx, span := tracer.StartSpan(ctx, "database-query")
defer tracer.FinishSpan(span)

// Add attributes
tracer.SetSpanAttribute(span, "db.system", "postgresql")
tracer.SetSpanAttribute(span, "db.query", "SELECT * FROM users")
tracer.SetSpanAttribute(span, "db.rows_returned", 42)
```

Supported attribute types:
- `string`
- `int`, `int64`
- `float64`
- `bool`
- Other types (converted to string)

### Adding Events

Record significant moments in a span's lifetime:

```go
import "go.opentelemetry.io/otel/attribute"

ctx, span := tracer.StartSpan(ctx, "cache-lookup")
defer tracer.FinishSpan(span)

// Add an event
tracer.AddSpanEvent(span, "cache_hit",
    attribute.String("key", "user:123"),
    attribute.Int("ttl_seconds", 300),
)
```

### Error Handling

When a span fails, use `FinishSpanWithError(span, err)` to record the error and end the span. On success, use `FinishSpan(span)`.

```go
func fetchUser(ctx context.Context, tracer *tracing.Tracer, userID string) error {
    ctx, span := tracer.StartSpan(ctx, "fetch-user")
    defer func() {
        if err != nil {
            tracer.FinishSpanWithError(span, err)
        } else {
            tracer.FinishSpan(span)
        }
    }()
    tracer.SetSpanAttribute(span, "user.id", userID)
    user, err := db.GetUser(ctx, userID)
    if err != nil {
        return err
    }
    // ...
    return nil
}
```

To record an error on the span without ending it (e.g. retry and then finish), use `RecordError`:

```go
if err := step(); err != nil {
    tracer.RecordError(span, err)
}
// ... continue, then later ...
defer tracer.FinishSpan(span)
```

### Propagating trace to goroutines

Use `CopyTraceContext(ctx)` when starting goroutines or background work so new spans link to the same trace:

```go
traceCtx := tracing.CopyTraceContext(r.Context())
go func() {
    _, span := tracer.StartSpan(traceCtx, "async-job")
    defer tracer.FinishSpan(span)
    doAsyncWork(ctx)
}()
```

### WithSpan

Run a function under a span; the span is finished with success or error based on the returned error:

```go
// Standalone
err := tracer.WithSpan(ctx, "process-order", func(ctx context.Context) error {
    order, err := loadOrder(ctx, id)
    if err != nil {
        return err
    }
    return executeOrder(ctx, order)
})

// With app context (in a handler)
err := c.WithSpan("fetch-user", func(ctx context.Context) error {
    user, err := fetchUser(ctx, id)
    if err != nil {
        return err
    }
    return c.JSON(http.StatusOK, user)
})
```

## Context Helpers

Work with spans through the context without direct span references. Use these when you only have context (e.g. from the middleware); they are equivalent to the tracer's `SetSpanAttribute` and `AddSpanEvent`.

### Set Attributes from Context

```go
func handleRequest(ctx context.Context) {
    // Add attribute to the current span in context
    tracing.SetSpanAttributeFromContext(ctx, "user.role", "admin")
    tracing.SetSpanAttributeFromContext(ctx, "user.id", 12345)
}
```

### Add Events from Context

```go
func processEvent(ctx context.Context) {
    // Add event to the current span in context
    tracing.AddSpanEventFromContext(ctx, "event_processed",
        attribute.String("event_type", "user_login"),
        attribute.String("ip_address", "192.168.1.1"),
    )
}
```

### Get Trace Information

```go
func logWithTraceInfo(ctx context.Context) {
    traceID := tracing.TraceID(ctx)
    spanID := tracing.SpanID(ctx)
    
    log.Printf("Processing request [trace=%s, span=%s]", traceID, spanID)
}
```

## Complete Example

Here's a complete example showing manual span management:

```go
package main

import (
    "context"
    "log"
    "time"
    
    "go.opentelemetry.io/otel/attribute"
    "rivaas.dev/tracing"
)

func main() {
    tracer := tracing.MustNew(
        tracing.WithServiceName("example-service"),
        tracing.WithStdout(),
    )
    defer tracer.Shutdown(context.Background())
    
    ctx := context.Background()
    
    // Parent span
    ctx, parentSpan := tracer.StartSpan(ctx, "process-order")
    defer tracer.FinishSpan(parentSpan)
    
    tracer.SetSpanAttribute(parentSpan, "order.id", "12345")
    
    // Child span 1
    validateOrder(ctx, tracer)
    
    // Child span 2
    chargePayment(ctx, tracer)
    
    log.Println("Order processed successfully")
}

func validateOrder(ctx context.Context, tracer *tracing.Tracer) {
    ctx, span := tracer.StartSpan(ctx, "validate-order")
    defer tracer.FinishSpan(span)
    
    tracer.SetSpanAttribute(span, "validation.status", "passed")
    tracer.AddSpanEvent(span, "validation_complete")
    
    time.Sleep(10 * time.Millisecond) // Simulate work
}

func chargePayment(ctx context.Context, tracer *tracing.Tracer) {
    ctx, span := tracer.StartSpan(ctx, "charge-payment")
    defer tracer.FinishSpan(span)
    
    tracer.SetSpanAttribute(span, "payment.amount", 99.99)
    tracer.SetSpanAttribute(span, "payment.method", "credit_card")
    
    tracer.AddSpanEvent(span, "payment_authorized",
        attribute.String("authorization_code", "AUTH123"),
    )
    
    time.Sleep(20 * time.Millisecond) // Simulate work
}
```

## Best Practices

### Always Close Spans

Use `defer` to ensure spans are finished even if errors occur:

```go
ctx, span := tracer.StartSpan(ctx, "operation")
defer tracer.FinishSpan(span) // Always close
```

### Propagate Context

Always pass the context returned by `StartSpan` to child operations:

```go
ctx, span := tracer.StartSpan(ctx, "parent")
defer tracer.FinishSpan(span)

// Pass the new context to children
childOperation(ctx) // ✓ Correct
childOperation(oldCtx) // ✗ Wrong - breaks trace chain
```

### Use Descriptive Names

Choose clear, consistent span names:

```go
// Good
tracer.StartSpan(ctx, "database-query")
tracer.StartSpan(ctx, "validate-user-input")
tracer.StartSpan(ctx, "send-email")

// Bad
tracer.StartSpan(ctx, "query")
tracer.StartSpan(ctx, "func1")
tracer.StartSpan(ctx, "DoStuff")
```

### Add Meaningful Attributes

Include relevant information as attributes:

```go
ctx, span := tracer.StartSpan(ctx, "api-call")
defer tracer.FinishSpanWithHTTPStatus(span, statusCode)

tracer.SetSpanAttribute(span, "http.method", "POST")
tracer.SetSpanAttribute(span, "http.url", "/api/users")
tracer.SetSpanAttribute(span, "api.endpoint", "create_user")
tracer.SetSpanAttribute(span, "user.role", "admin")
```

## Next Steps

- Learn about [Providers](../providers/) to choose where traces are exported
- Explore [Configuration](../configuration/) for advanced tracer options
- Set up [Middleware](../middleware/) for automatic HTTP tracing
- Read [Context Propagation](../context-propagation/) for distributed tracing
