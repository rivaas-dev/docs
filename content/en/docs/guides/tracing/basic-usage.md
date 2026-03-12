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

For convenience, use `MustNew` which panics if initialization fails:

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

{{< alert color="info" >}}
For Stdout and Noop providers, `Start()` is optional (they initialize immediately in `New()`).
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

### Basic Span Creation

```go
func processData(ctx context.Context, tracer *tracing.Tracer) {
    // Start a span
    ctx, span := tracer.StartSpan(ctx, "process-data")
    defer tracer.FinishSpan(span, http.StatusOK)
    
    // Your code here...
}
```

### Adding Attributes

Add attributes to provide context about the operation:

```go
ctx, span := tracer.StartSpan(ctx, "database-query")
defer tracer.FinishSpan(span, http.StatusOK)

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
defer tracer.FinishSpan(span, http.StatusOK)

// Add an event
tracer.AddSpanEvent(span, "cache_hit",
    attribute.String("key", "user:123"),
    attribute.Int("ttl_seconds", 300),
)
```

### Error Handling

Use the status code to indicate span success or failure:

```go
func fetchUser(ctx context.Context, tracer *tracing.Tracer, userID string) error {
    ctx, span := tracer.StartSpan(ctx, "fetch-user")
    defer func() {
        if err != nil {
            tracer.FinishSpan(span, http.StatusInternalServerError)
        } else {
            tracer.FinishSpan(span, http.StatusOK)
        }
    }()
    
    tracer.SetSpanAttribute(span, "user.id", userID)
    
    // Fetch user logic...
    return nil
}
```

## Context Helpers

Work with spans through the context without direct span references:

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
    defer tracer.FinishSpan(parentSpan, 200)
    
    tracer.SetSpanAttribute(parentSpan, "order.id", "12345")
    
    // Child span 1
    validateOrder(ctx, tracer)
    
    // Child span 2
    chargePayment(ctx, tracer)
    
    log.Println("Order processed successfully")
}

func validateOrder(ctx context.Context, tracer *tracing.Tracer) {
    ctx, span := tracer.StartSpan(ctx, "validate-order")
    defer tracer.FinishSpan(span, 200)
    
    tracer.SetSpanAttribute(span, "validation.status", "passed")
    tracer.AddSpanEvent(span, "validation_complete")
    
    time.Sleep(10 * time.Millisecond) // Simulate work
}

func chargePayment(ctx context.Context, tracer *tracing.Tracer) {
    ctx, span := tracer.StartSpan(ctx, "charge-payment")
    defer tracer.FinishSpan(span, 200)
    
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
defer tracer.FinishSpan(span, http.StatusOK) // Always close
```

### Propagate Context

Always pass the context returned by `StartSpan` to child operations:

```go
ctx, span := tracer.StartSpan(ctx, "parent")
defer tracer.FinishSpan(span, http.StatusOK)

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
defer tracer.FinishSpan(span, statusCode)

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
