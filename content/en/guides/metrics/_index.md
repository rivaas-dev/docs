---
title: "Metrics Collection"
linkTitle: "Metrics"
description: "Learn how to collect and export application metrics with Rivaas metrics package"
weight: 8
no_list: true
keywords:
  - metrics
  - prometheus
  - opentelemetry
  - observability
  - monitoring
---

{{% pageinfo %}}
The Rivaas Metrics package provides OpenTelemetry-based metrics collection. Supports multiple exporters including Prometheus, OTLP, and stdout. Enables observability best practices with minimal configuration.
{{% /pageinfo %}}

## Features

- **Multiple Providers**: Prometheus, OTLP, and stdout exporters
- **Built-in HTTP Metrics**: Request duration, count, active requests, and more
- **Custom Metrics**: Support for counters, histograms, and gauges with error handling
- **Thread-Safe**: All methods are safe for concurrent use
- **Context Support**: All metrics methods accept context for cancellation
- **Structured Logging**: Pluggable logger interface for error and warning messages
- **HTTP Middleware**: Integration with any HTTP framework
- **Security**: Automatic filtering of sensitive headers

## Quick Start

{{< tabpane persist=header >}}
{{< tab header="Prometheus" lang="go" >}}
package main

import (
    "context"
    "log"
    "net/http"
    "os/signal"
    
    "rivaas.dev/metrics"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    recorder, err := metrics.New(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
        metrics.WithServiceVersion("v1.0.0"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())

    // Record custom metrics
    _ = recorder.IncrementCounter(ctx, "requests_total")
    
    // Prometheus metrics available at http://localhost:9090/metrics
}
{{< /tab >}}
{{< tab header="OTLP" lang="go" >}}
package main

import (
    "context"
    "log"
    "os/signal"
    
    "rivaas.dev/metrics"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    recorder, err := metrics.New(
        metrics.WithOTLP("http://localhost:4318"),
        metrics.WithServiceName("my-api"),
        metrics.WithServiceVersion("v1.0.0"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())

    // Metrics pushed to OTLP collector
    _ = recorder.IncrementCounter(ctx, "requests_total")
}
{{< /tab >}}
{{< tab header="Stdout" lang="go" >}}
package main

import (
    "context"
    "log"
    
    "rivaas.dev/metrics"
)

func main() {
    recorder := metrics.MustNew(
        metrics.WithStdout(),
        metrics.WithServiceName("my-api"),
    )

    ctx := context.Background()
    
    // Metrics printed to stdout
    _ = recorder.IncrementCounter(ctx, "requests_total")
}
{{< /tab >}}
{{< /tabpane >}}

### How It Works

- **Providers** determine where metrics are exported (Prometheus, OTLP, stdout)
- **Lifecycle management** ensures proper initialization and graceful shutdown
- **HTTP middleware** automatically collects request metrics
- **Custom metrics** can be recorded with type-safe methods
- **Context support** enables cancellation and request tracing

## Learning Path

Follow these guides to master metrics collection with Rivaas:

1. [**Installation**](installation/) - Get started with the metrics package
2. [**Basic Usage**](basic-usage/) - Learn the fundamentals of metrics collection
3. [**Providers**](providers/) - Understand Prometheus, OTLP, and stdout exporters
4. [**Configuration**](configuration/) - Configure service metadata, histograms, and advanced options
5. [**Custom Metrics**](custom-metrics/) - Create counters, histograms, and gauges
6. [**Middleware**](middleware/) - Integrate HTTP metrics with your application
7. [**Testing**](testing/) - Test your metrics with provided utilities
8. [**Examples**](examples/) - See real-world usage patterns

## Next Steps

- Start with [Installation](installation/) to set up the metrics package
- Explore the [API Reference](/reference/packages/metrics/) for complete technical details
- Check out [code examples on GitHub](https://github.com/rivaas-dev/rivaas/tree/main/metrics/)
