---
title: Documentation
linkTitle: Docs
type: docs
# menu: { main: { weight: 20 } }
cascade:
  - _target:
      path: "/**"
      kind: "page"
    type: "docs"
  - _target:
      path: "/**"
      kind: "section"
    type: "docs"
---

Welcome to the **Rivaas** documentation! Rivaas is a batteries-included, cloud-native web framework for Go featuring high-performance routing, comprehensive request binding & validation, automatic OpenAPI generation, and OpenTelemetry-native observability.

## What is Rivaas?

Rivaas is a modular Go web framework designed for building production-ready APIs and web applications. The name comes from **ریواس (Rivās)** — a wild rhubarb plant native to the mountains of Iran that thrives in harsh conditions at high altitudes.

Like its namesake, Rivaas is:

- **🛡️ Resilient** — Built for production with graceful shutdown, health checks, and panic recovery
- **⚡ Lightweight** — Minimal overhead (119ns latency, 16 bytes/request) without sacrificing features
- **🔧 Adaptive** — Works locally, in containers, or across distributed systems
- **📦 Self-sufficient** — Integrated observability instead of bolted-on dependencies

## Key Features

- **High Performance** — 8.4M+ req/sec with radix tree router and Bloom filter optimization
- **Production-Ready** — Graceful shutdown, health endpoints, panic recovery, mTLS support
- **Cloud-Native** — OpenTelemetry-native with Prometheus, OTLP, and Jaeger support
- **Modular Architecture** — Each package works standalone without the full framework
- **Developer-Friendly** — Sensible defaults, progressive disclosure, functional options pattern
- **Type-Safe** — Comprehensive request binding and validation with clear error messages

## Quick Start

**Installation** (requires Go 1.25+):

```bash
go get rivaas.dev/app
```

**Hello World:**

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"

    "rivaas.dev/app"
)

func main() {
    a, err := app.New()
    if err != nil {
        log.Fatal(err)
    }

    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello from Rivaas!",
        })
    })

    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}
```

## Documentation Structure

### Getting Started
New to Rivaas? Start here to learn the basics and get your first application running.

### Guides
Step-by-step tutorials covering common tasks like setting up observability, configuring middleware, and deploying to production. Each package guide includes practical examples.

### Reference
Detailed API documentation for all packages, configuration options, and advanced features.

## Package Overview

Rivaas is organized into independent, standalone packages:

### Core Packages

{{< cardpane >}}
{{< card header="**App**" >}}
Batteries-included web framework with integrated observability, lifecycle management, and graceful shutdown.

[Learn more →](/reference/packages/app/)
{{< /card >}}
{{< card header="**Router**" >}}
High-performance HTTP router with 8.4M+ req/s throughput and 119ns latency.

[Learn more →](/reference/packages/router/)
{{< /card >}}
{{< /cardpane >}}

### Configuration

{{< cardpane >}}
{{< card header="**Config**" >}}
Configuration management supporting files, environment variables, Consul, and built-in validation.

[Learn more →](/reference/packages/config/)
{{< /card >}}
{{< /cardpane >}}

### Data Handling

{{< cardpane >}}
{{< card header="**Binding**" >}}
Request binding from multiple sources: JSON, XML, YAML, TOML, MessagePack, Protocol Buffers.

[Learn more →](/reference/packages/binding/)
{{< /card >}}
{{< card header="**Validation**" >}}
Struct validation with tags, JSON Schema, and custom interfaces for flexible validation strategies.

[Learn more →](/reference/packages/validation/)
{{< /card >}}
{{< /cardpane >}}

### Observability

{{< cardpane >}}
{{< card header="**Logging**" >}}
Structured logging with Go's standard log/slog, featuring trace correlation and sensitive data redaction.

[Learn more →](/reference/packages/logging/)
{{< /card >}}
{{< card header="**Metrics**" >}}
OpenTelemetry metrics collection with Prometheus, OTLP, and stdout exporters.

[Learn more →](/reference/packages/metrics/)
{{< /card >}}
{{< card header="**Tracing**" >}}
Distributed tracing with OpenTelemetry, supporting OTLP, Jaeger, and stdout.

[Learn more →](/reference/packages/tracing/)
{{< /card >}}
{{< /cardpane >}}

### API & Errors

{{< cardpane >}}
{{< card header="**OpenAPI**" >}}
Automatic OpenAPI 3.0/3.1 specification generation from Go code with Swagger UI support.

[Learn more →](/reference/packages/openapi/)
{{< /card >}}
{{< card header="**Errors**" >}}
Error formatting supporting RFC 9457 (Problem Details) and JSON:API specifications.

[Learn more →](/reference/packages/errors/)
{{< /card >}}
{{< /cardpane >}}

## Philosophy

Every package in Rivaas follows these design principles:

1. **Developer Experience First** — Sensible defaults, discoverable APIs, clear errors
2. **Functional Options Pattern** — Backward-compatible, self-documenting configuration
3. **Standalone Packages** — Use any package without the full framework
4. **Separation of Concerns** — Each package has a single, well-defined responsibility

## Community & Support

- **GitHub Repository:** [github.com/rivaas-dev/rivaas](https://github.com/rivaas-dev/rivaas)
- **Issue Tracker:** [Report bugs or request features](https://github.com/rivaas-dev/rivaas/issues)
- **License:** Apache License 2.0

## Next Steps

- **[Installation Guide →](/getting-started/)** — Get Rivaas up and running
- **[App Guide →](/guides/app/)** — Understand the framework architecture
- **[API Reference →](/reference/)** — Explore the complete API documentation
