---
title: "Distributed Tracing"
description: "Learn how to implement distributed tracing with Rivaas tracing package"
weight: 5
sidebar_root_for: self
---

A distributed tracing package for Go applications using OpenTelemetry. This package provides easy-to-use tracing functionality with support for various exporters and seamless integration with HTTP frameworks.

> Tracing is designed to help Go applications implement observability best practices with minimal configuration, providing out-of-the-box request tracing and flexible custom span management.

## Features

- **OpenTelemetry Integration**: Full OpenTelemetry tracing support
- **Context Propagation**: Automatic trace context propagation across services
- **Span Management**: Easy span creation and management with lifecycle hooks
- **HTTP Middleware**: Standalone middleware for any HTTP framework
- **Multiple Providers**: Stdout, OTLP (gRPC and HTTP), and Noop exporters
- **Path Filtering**: Exclude specific paths from tracing via middleware options
- **Consistent API**: Same design patterns as the metrics package
- **Thread-Safe**: All operations safe for concurrent use

## Quick Start

Here's a 30-second example to get you started:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    
    "rivaas.dev/tracing"
)

func main() {
    // Create context for application lifecycle
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create tracer with OTLP provider
    tracer, err := tracing.New(
        tracing.WithServiceName("my-service"),
        tracing.WithServiceVersion("v1.0.0"),
        tracing.WithOTLP("localhost:4317"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Start tracer (required for OTLP providers)
    if err := tracer.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    // Ensure traces are flushed on exit
    defer tracer.Shutdown(context.Background())

    // Create HTTP handler with tracing middleware
    mux := http.NewServeMux()
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"message": "Hello"}`))
    })

    // Wrap with tracing middleware
    handler := tracing.MustMiddleware(tracer,
        tracing.WithExcludePaths("/health", "/metrics"),
        tracing.WithHeaders("X-Request-ID"),
    )(mux)

    log.Fatal(http.ListenAndServe(":8080", handler))
}
```

### How It Works

- **Providers** determine where traces are exported (Stdout, OTLP, Noop)
- **Lifecycle management** ensures proper initialization and graceful shutdown
- **HTTP middleware** automatically creates spans for requests
- **Custom spans** can be created for detailed operation tracing
- **Context propagation** enables distributed tracing across services

## Learning Path

Follow these guides to master distributed tracing with Rivaas:

1. [**Installation**](installation/) - Get started with the tracing package
2. [**Basic Usage**](basic-usage/) - Learn tracer creation and span management
3. [**Providers**](providers/) - Understand Stdout, OTLP, and Noop exporters
4. [**Configuration**](configuration/) - Configure service metadata, sampling, and hooks
5. [**Middleware**](middleware/) - Integrate HTTP tracing with your application
6. [**Context Propagation**](context-propagation/) - Propagate traces across services
7. [**Testing**](testing/) - Test your tracing with provided utilities
8. [**Examples**](examples/) - See real-world usage patterns

## Next Steps

- Start with [Installation](installation/) to set up the tracing package
- Explore the [API Reference](/reference/packages/tracing/) for complete technical details
- Check out [code examples on GitHub](https://github.com/rivaas-dev/rivaas/tree/main/tracing/)
