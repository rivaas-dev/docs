---
title: "Metrics Collection"
description: "Learn how to collect and export application metrics with Rivaas metrics package"
weight: 4
sidebar_root_for: self
---

A metrics collection package for Go applications using OpenTelemetry. This package provides metrics functionality with support for multiple exporters including Prometheus, OTLP, and stdout.

> Metrics is designed to help Go applications implement observability best practices with minimal configuration, providing out-of-the-box HTTP metrics and flexible custom metrics collection.

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

Here's a 30-second example to get you started:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os/signal"
    "time"
    
    "rivaas.dev/metrics"
)

func main() {
    // Create context for application lifecycle
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create metrics recorder with Prometheus
    recorder, err := metrics.New(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
        metrics.WithServiceVersion("v1.0.0"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Start metrics server (required for Prometheus, OTLP)
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    // Ensure metrics are flushed on exit
    defer func() {
        shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer shutdownCancel()
        if err := recorder.Shutdown(shutdownCtx); err != nil {
            log.Printf("Metrics shutdown error: %v", err)
        }
    }()

    // Create HTTP handler with metrics middleware
    mux := http.NewServeMux()
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"message": "Hello"}`))
    })

    // Wrap with metrics middleware
    handler := metrics.Middleware(recorder,
        metrics.WithExcludePaths("/health", "/metrics"),
    )(mux)

    log.Fatal(http.ListenAndServe(":8080", handler))
}
```

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
