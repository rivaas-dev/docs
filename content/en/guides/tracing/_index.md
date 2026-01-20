---
title: "Distributed Tracing"
linkTitle: "Tracing"
description: "Learn how to implement distributed tracing with Rivaas tracing package"
weight: 9
---

{{% pageinfo %}}
The Rivaas Tracing package provides OpenTelemetry-based distributed tracing. Supports various exporters and integrates with HTTP frameworks. Enables observability best practices with minimal configuration.
{{% /pageinfo %}}

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

{{< tabpane persist=header >}}
{{< tab header="OTLP (gRPC)" lang="go" >}}
package main

import (
    "context"
    "log"
    "os/signal"
    
    "rivaas.dev/tracing"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    tracer, err := tracing.New(
        tracing.WithServiceName("my-service"),
        tracing.WithServiceVersion("v1.0.0"),
        tracing.WithOTLP("localhost:4317"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    if err := tracer.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer tracer.Shutdown(context.Background())

    // Traces exported via OTLP gRPC
    ctx, span := tracer.StartSpan(ctx, "operation")
    defer tracer.FinishSpan(span, 200)
}
{{< /tab >}}
{{< tab header="OTLP (HTTP)" lang="go" >}}
package main

import (
    "context"
    "log"
    "os/signal"
    
    "rivaas.dev/tracing"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    tracer, err := tracing.New(
        tracing.WithServiceName("my-service"),
        tracing.WithServiceVersion("v1.0.0"),
        tracing.WithOTLPHTTP("http://localhost:4318"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    if err := tracer.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer tracer.Shutdown(context.Background())

    // Traces exported via OTLP HTTP
    ctx, span := tracer.StartSpan(ctx, "operation")
    defer tracer.FinishSpan(span, 200)
}
{{< /tab >}}
{{< tab header="Stdout" lang="go" >}}
package main

import (
    "context"
    
    "rivaas.dev/tracing"
)

func main() {
    tracer := tracing.MustNew(
        tracing.WithServiceName("my-service"),
        tracing.WithStdout(),
    )
    defer tracer.Shutdown(context.Background())

    ctx := context.Background()
    
    // Traces printed to stdout
    ctx, span := tracer.StartSpan(ctx, "operation")
    defer tracer.FinishSpan(span, 200)
}
{{< /tab >}}
{{< /tabpane >}}

### How It Works

- **Providers** determine where traces are exported (Stdout, OTLP, Noop)
- **Lifecycle management** ensures proper initialization and graceful shutdown
- **HTTP middleware** creates spans for requests automatically
- **Custom spans** can be created for detailed operation tracing
- **Context propagation** enables distributed tracing across services

## Learning Path

Follow these guides to learn distributed tracing with Rivaas:

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
