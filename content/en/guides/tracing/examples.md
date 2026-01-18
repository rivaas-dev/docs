---
title: "Examples"
description: "Real-world tracing configurations and patterns"
weight: 8
---

Explore complete examples and best practices for production-ready tracing configurations.

## Production Configuration

A production-ready tracing setup with all recommended settings.

```go
package main

import (
    "context"
    "log"
    "log/slog"
    "net/http"
    "os"
    "os/signal"
    "time"
    
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/trace"
    "rivaas.dev/tracing"
)

func main() {
    // Create context for graceful shutdown
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create logger for internal events
    logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
        Level: slog.LevelInfo,
    }))

    // Create tracer with production settings
    tracer, err := tracing.New(
        tracing.WithServiceName("user-api"),
        tracing.WithServiceVersion(os.Getenv("VERSION")),
        tracing.WithOTLP(os.Getenv("OTLP_ENDPOINT")),
        tracing.WithSampleRate(0.1), // 10% sampling
        tracing.WithLogger(logger),
        tracing.WithSpanStartHook(enrichSpan),
        tracing.WithSpanFinishHook(recordMetrics),
    )
    if err != nil {
        log.Fatalf("Failed to initialize tracing: %v", err)
    }

    // Start tracer (required for OTLP)
    if err := tracer.Start(ctx); err != nil {
        log.Fatalf("Failed to start tracer: %v", err)
    }

    // Ensure graceful shutdown
    defer func() {
        shutdownCtx, shutdownCancel := context.WithTimeout(
            context.Background(), 5*time.Second)
        defer shutdownCancel()
        
        if err := tracer.Shutdown(shutdownCtx); err != nil {
            log.Printf("Error shutting down tracer: %v", err)
        }
    }()

    // Create HTTP handlers
    mux := http.NewServeMux()
    mux.HandleFunc("/api/users", handleUsers)
    mux.HandleFunc("/api/orders", handleOrders)
    mux.HandleFunc("/health", handleHealth)
    mux.HandleFunc("/metrics", handleMetrics)

    // Wrap with tracing middleware
    handler := tracing.MustMiddleware(tracer,
        // Exclude observability endpoints
        tracing.WithExcludePaths("/health", "/metrics", "/ready", "/live"),
        
        // Exclude debug endpoints
        tracing.WithExcludePrefixes("/debug/", "/internal/"),
        
        // Record correlation headers
        tracing.WithHeaders("X-Request-ID", "X-Correlation-ID"),
        
        // Whitelist safe parameters
        tracing.WithRecordParams("page", "limit", "sort"),
        
        // Blacklist sensitive parameters
        tracing.WithExcludeParams("password", "token", "api_key"),
    )(mux)

    // Start server
    log.Printf("Server starting on :8080")
    if err := http.ListenAndServe(":8080", handler); err != nil {
        log.Fatal(err)
    }
}

// enrichSpan adds custom business context to spans
func enrichSpan(ctx context.Context, span trace.Span, req *http.Request) {
    // Add tenant identifier
    if tenantID := req.Header.Get("X-Tenant-ID"); tenantID != "" {
        span.SetAttributes(attribute.String("tenant.id", tenantID))
    }
    
    // Add user information
    if userID := req.Header.Get("X-User-ID"); userID != "" {
        span.SetAttributes(attribute.String("user.id", userID))
    }
    
    // Add deployment information
    span.SetAttributes(
        attribute.String("deployment.region", os.Getenv("REGION")),
        attribute.String("deployment.environment", os.Getenv("ENVIRONMENT")),
    )
}

// recordMetrics records custom metrics based on span completion
func recordMetrics(span trace.Span, statusCode int) {
    // Record error metrics
    if statusCode >= 500 {
        // metrics.IncrementServerErrors()
    }
    
    // Record slow request metrics
    // Could calculate duration and record if above threshold
}

func handleUsers(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    
    // Add custom span attributes
    tracing.SetSpanAttributeFromContext(ctx, "handler", "users")
    tracing.SetSpanAttributeFromContext(ctx, "operation", "list")
    
    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"users": []}`))
}

func handleOrders(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    
    tracing.SetSpanAttributeFromContext(ctx, "handler", "orders")
    
    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"orders": []}`))
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

func handleMetrics(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/plain")
    w.Write([]byte("# Metrics"))
}
```

## Development Configuration

A development setup with verbose output for debugging.

```go
package main

import (
    "context"
    "log"
    "log/slog"
    "net/http"
    "os"
    
    "rivaas.dev/tracing"
)

func main() {
    // Create logger with debug level
    logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
        Level: slog.LevelDebug,
    }))

    // Create tracer with development settings
    tracer := tracing.MustNew(
        tracing.WithServiceName("user-api"),
        tracing.WithServiceVersion("dev"),
        tracing.WithStdout(),          // Print traces to console
        tracing.WithSampleRate(1.0),   // Trace everything
        tracing.WithLogger(logger),    // Verbose logging
    )
    defer tracer.Shutdown(context.Background())

    // Create simple handler
    mux := http.NewServeMux()
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello, World!"))
    })

    // Minimal middleware - trace everything
    handler := tracing.MustMiddleware(tracer)(mux)

    log.Println("Development server on :8080")
    log.Fatal(http.ListenAndServe(":8080", handler))
}
```

## Microservices Example

Complete distributed tracing across multiple services.

### Service A (API Gateway)

```go
package main

import (
    "context"
    "io"
    "log"
    "net/http"
    
    "rivaas.dev/tracing"
)

func main() {
    tracer := tracing.MustNew(
        tracing.WithServiceName("api-gateway"),
        tracing.WithServiceVersion("v1.0.0"),
        tracing.WithOTLP("localhost:4317"),
    )
    tracer.Start(context.Background())
    defer tracer.Shutdown(context.Background())

    mux := http.NewServeMux()
    mux.HandleFunc("/api/users", func(w http.ResponseWriter, r *http.Request) {
        ctx := r.Context()
        
        // Call user service
        users, err := callUserService(ctx, tracer)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(users))
    })

    handler := tracing.MustMiddleware(tracer,
        tracing.WithExcludePaths("/health"),
    )(mux)

    log.Fatal(http.ListenAndServe(":8080", handler))
}

func callUserService(ctx context.Context, tracer *tracing.Tracer) (string, error) {
    // Create span for outgoing call
    ctx, span := tracer.StartSpan(ctx, "call-user-service")
    defer tracer.FinishSpan(span, http.StatusOK)
    
    // Create request
    req, err := http.NewRequestWithContext(ctx, "GET", 
        "http://localhost:8081/users", nil)
    if err != nil {
        return "", err
    }
    
    // Inject trace context
    tracer.InjectTraceContext(ctx, req.Header)
    
    // Make request
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    
    body, _ := io.ReadAll(resp.Body)
    return string(body), nil
}
```

### Service B (User Service)

```go
package main

import (
    "context"
    "log"
    "net/http"
    
    "rivaas.dev/tracing"
)

func main() {
    tracer := tracing.MustNew(
        tracing.WithServiceName("user-service"),
        tracing.WithServiceVersion("v1.0.0"),
        tracing.WithOTLP("localhost:4317"),
    )
    tracer.Start(context.Background())
    defer tracer.Shutdown(context.Background())

    mux := http.NewServeMux()
    mux.HandleFunc("/users", func(w http.ResponseWriter, r *http.Request) {
        ctx := r.Context()
        
        // This span is part of the distributed trace
        ctx, span := tracer.StartSpan(ctx, "fetch-users")
        defer tracer.FinishSpan(span, http.StatusOK)
        
        tracer.SetSpanAttribute(span, "db.system", "postgresql")
        
        // Simulate database query
        users := `{"users": [{"id": 1, "name": "Alice"}]}`
        
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(users))
    })

    // Middleware automatically extracts trace context
    handler := tracing.MustMiddleware(tracer)(mux)

    log.Fatal(http.ListenAndServe(":8081", handler))
}
```

## Environment-Based Configuration

Configure tracing based on environment.

```go
package main

import (
    "context"
    "log"
    "log/slog"
    "net/http"
    "os"
    
    "rivaas.dev/tracing"
)

func main() {
    tracer := createTracer(os.Getenv("ENVIRONMENT"))
    defer tracer.Shutdown(context.Background())

    // If OTLP, start the tracer
    if tracer.GetProvider() == tracing.OTLPProvider || 
       tracer.GetProvider() == tracing.OTLPHTTPProvider {
        if err := tracer.Start(context.Background()); err != nil {
            log.Fatal(err)
        }
    }

    mux := http.NewServeMux()
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello"))
    })

    handler := tracing.MustMiddleware(tracer)(mux)
    log.Fatal(http.ListenAndServe(":8080", handler))
}

func createTracer(env string) *tracing.Tracer {
    serviceName := os.Getenv("SERVICE_NAME")
    if serviceName == "" {
        serviceName = "my-api"
    }

    version := os.Getenv("VERSION")
    if version == "" {
        version = "dev"
    }

    opts := []tracing.Option{
        tracing.WithServiceName(serviceName),
        tracing.WithServiceVersion(version),
    }

    switch env {
    case "production":
        opts = append(opts,
            tracing.WithOTLP(os.Getenv("OTLP_ENDPOINT")),
            tracing.WithSampleRate(0.1), // 10% sampling
        )
    case "staging":
        opts = append(opts,
            tracing.WithOTLP(os.Getenv("OTLP_ENDPOINT")),
            tracing.WithSampleRate(0.5), // 50% sampling
        )
    default: // development
        logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
        opts = append(opts,
            tracing.WithStdout(),
            tracing.WithSampleRate(1.0), // 100% sampling
            tracing.WithLogger(logger),
        )
    }

    return tracing.MustNew(opts...)
}
```

## Database Tracing Example

Trace database operations.

```go
package main

import (
    "context"
    "database/sql"
    "net/http"
    
    "go.opentelemetry.io/otel/attribute"
    "rivaas.dev/tracing"
)

type UserRepository struct {
    db     *sql.DB
    tracer *tracing.Tracer
}

func (r *UserRepository) GetUser(ctx context.Context, userID int) (*User, error) {
    // Create span for database operation
    ctx, span := r.tracer.StartSpan(ctx, "db-get-user")
    defer r.tracer.FinishSpan(span, http.StatusOK)
    
    // Add database attributes
    r.tracer.SetSpanAttribute(span, "db.system", "postgresql")
    r.tracer.SetSpanAttribute(span, "db.operation", "SELECT")
    r.tracer.SetSpanAttribute(span, "db.table", "users")
    r.tracer.SetSpanAttribute(span, "user.id", userID)
    
    // Execute query
    query := "SELECT id, name, email FROM users WHERE id = $1"
    r.tracer.SetSpanAttribute(span, "db.query", query)
    
    var user User
    err := r.db.QueryRowContext(ctx, query, userID).Scan(
        &user.ID, &user.Name, &user.Email)
    if err != nil {
        r.tracer.SetSpanAttribute(span, "error", true)
        r.tracer.SetSpanAttribute(span, "error.message", err.Error())
        return nil, err
    }
    
    // Add event for successful query
    r.tracer.AddSpanEvent(span, "user_found",
        attribute.Int("user.id", user.ID),
    )
    
    return &user, nil
}

type User struct {
    ID    int
    Name  string
    Email string
}
```

## Custom Span Events Example

Record significant events within spans.

```go
func processOrder(ctx context.Context, tracer *tracing.Tracer, order *Order) error {
    ctx, span := tracer.StartSpan(ctx, "process-order")
    defer tracer.FinishSpan(span, http.StatusOK)
    
    tracer.SetSpanAttribute(span, "order.id", order.ID)
    tracer.SetSpanAttribute(span, "order.total", order.Total)
    
    // Event: Order validation started
    tracer.AddSpanEvent(span, "validation_started")
    
    if err := validateOrder(ctx, tracer, order); err != nil {
        tracer.AddSpanEvent(span, "validation_failed",
            attribute.String("error", err.Error()),
        )
        return err
    }
    
    tracer.AddSpanEvent(span, "validation_passed")
    
    // Event: Payment processing started
    tracer.AddSpanEvent(span, "payment_started",
        attribute.Float64("amount", order.Total),
    )
    
    if err := chargePayment(ctx, tracer, order); err != nil {
        tracer.AddSpanEvent(span, "payment_failed",
            attribute.String("error", err.Error()),
        )
        return err
    }
    
    tracer.AddSpanEvent(span, "payment_succeeded",
        attribute.String("transaction_id", "TXN123"),
    )
    
    // Event: Order completed
    tracer.AddSpanEvent(span, "order_completed")
    
    return nil
}
```

## Performance Benchmarks

Actual performance measurements from the tracing package:

```go
// Operation                              Time        Memory      Allocations
// Request overhead (100% sampling)       ~1.6 µs     2.3 KB      23
// Start/Finish span                      ~160 ns     240 B       3
// Set attribute                          ~3 ns       0 B         0
// Path exclusion (100 paths)             ~9 ns       0 B         0
```

### Performance Tips

1. **Use sampling** for high-traffic endpoints:
   ```go
   tracing.WithSampleRate(0.1) // 10% sampling
   ```

2. **Exclude health checks**:
   ```go
   tracing.WithExcludePaths("/health", "/metrics", "/ready")
   ```

3. **Minimize attributes** in hot paths:
   ```go
   // Only add essential attributes in critical code paths
   tracer.SetSpanAttribute(span, "request.id", requestID)
   ```

4. **Use path prefixes** over regex when possible:
   ```go
   tracing.WithExcludePrefixes("/debug/") // Faster than regex
   ```

## Docker Compose Setup

Complete tracing infrastructure with Jaeger:

```yaml
version: '3.8'
services:
  # Your application
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - OTLP_ENDPOINT=otel-collector:4317
      - ENVIRONMENT=development
    depends_on:
      - otel-collector

  # OpenTelemetry Collector
  otel-collector:
    image: otel/opentelemetry-collector:latest
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
    depends_on:
      - jaeger

  # Jaeger for trace visualization
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686" # Jaeger UI
      - "14250:14250" # Model.proto
```

OpenTelemetry Collector configuration (`otel-collector-config.yaml`):

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
    timeout: 10s
    send_batch_size: 1024

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger]
```

## Next Steps

- Review [API Reference](/reference/packages/tracing/) for complete documentation
- Check [Troubleshooting](/reference/packages/tracing/troubleshooting/) for common issues
- Explore the [source code on GitHub](https://github.com/rivaas-dev/rivaas/tree/main/tracing/)
