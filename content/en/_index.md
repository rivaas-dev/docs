---
title: Documentation
linkTitle: Docs
type: docs
no_list: true
keywords:
  - go web framework
  - golang http
  - api development
  - opentelemetry
  - cloud native
  - rest api
  - microservices
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

Welcome to the **Rivaas** documentation! Rivaas is a web framework for Go. It includes high-performance routing, request binding and validation, automatic OpenAPI generation, and OpenTelemetry observability.

## What is Rivaas?

Rivaas is a modular Go web framework for building production-ready APIs and web applications. The name comes from **ریواس (Rivās)**, a wild rhubarb plant from the mountains of Iran. This plant grows in harsh conditions at high altitudes.

Like its namesake, Rivaas is:

- **🛡️ Resilient** — Built for production. Includes graceful shutdown, health checks, and panic recovery.
- **⚡ Lightweight** — Minimal overhead (119ns latency, 16 bytes/request). No loss of features.
- **🔧 Adaptive** — Works locally, in containers, or across distributed systems.
- **📦 Self-sufficient** — Integrated observability. No external dependencies to add.

## Key Features

- **High Performance** — 8.4M+ requests/sec. Uses radix tree router and Bloom filter optimization.
- **Production-Ready** — Includes graceful shutdown, health endpoints, panic recovery, and mTLS support.
- **Cloud-Native** — Built with OpenTelemetry. Supports Prometheus, OTLP, and Jaeger.
- **Modular Architecture** — Each package works alone. No need for the full framework.
- **Developer-Friendly** — Sensible defaults. Progressive disclosure. Functional options pattern.
- **Type-Safe** — Request binding and validation with clear error messages.

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

    if err := a.Start(ctx); err != nil {
        log.Fatal(err)
    }
}
```

## Documentation Structure

### Getting Started
New to Rivaas? Start here. Learn the basics and get your first application running.

### Guides
Step-by-step tutorials for common tasks. Learn how to set up observability, configure middleware, and deploy to production. Each package guide includes practical examples.

### Reference
Detailed API documentation. Covers all packages, configuration options, and advanced features.

## Package Overview

Rivaas is organized into independent, standalone packages:

### Core Packages

{{% cardpane %}}
{{% card header="**App**" %}}
Web framework with integrated observability, lifecycle management, and graceful shutdown.

[Learn more →](/reference/packages/app/)
{{% /card %}}
{{% card header="**Router**" %}}
High-performance HTTP router. Handles 8.4M+ requests/sec with 119ns latency.

[Learn more →](/reference/packages/router/)
{{% /card %}}
{{% /cardpane %}}

### Configuration

{{% cardpane %}}
{{% card header="**Config**" %}}
Configuration management. Supports files, environment variables, Consul, and built-in validation.

[Learn more →](/reference/packages/config/)
{{% /card %}}
{{% /cardpane %}}

### Data Handling

{{% cardpane %}}
{{% card header="**Binding**" %}}
Request binding from multiple sources. Supports JSON, XML, YAML, TOML, MessagePack, and Protocol Buffers.

[Learn more →](/reference/packages/binding/)
{{% /card %}}
{{% card header="**Validation**" %}}
Struct validation with tags, JSON Schema, and custom interfaces.

[Learn more →](/reference/packages/validation/)
{{% /card %}}
{{% /cardpane %}}

### Observability

{{% cardpane %}}
{{% card header="**Logging**" %}}
Structured logging with Go's standard log/slog. Includes trace correlation and sensitive data redaction.

[Learn more →](/reference/packages/logging/)
{{% /card %}}
{{% card header="**Metrics**" %}}
OpenTelemetry metrics collection. Supports Prometheus, OTLP, and stdout exporters.

[Learn more →](/reference/packages/metrics/)
{{% /card %}}
{{% card header="**Tracing**" %}}
Distributed tracing with OpenTelemetry. Supports OTLP, Jaeger, and stdout.

[Learn more →](/reference/packages/tracing/)
{{% /card %}}
{{% /cardpane %}}

### API & Errors

{{% cardpane %}}
{{% card header="**OpenAPI**" %}}
Automatic OpenAPI 3.0/3.1 specification generation from Go code. Includes Swagger UI support.

[Learn more →](/reference/packages/openapi/)
{{% /card %}}
{{% card header="**Errors**" %}}
Error formatting. Supports RFC 9457 (Problem Details) and JSON:API specifications.

[Learn more →](/reference/packages/errors/)
{{% /card %}}
{{% /cardpane %}}

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

## Learn More

- **[About Rivaas →](/about/)** — Learn about our design philosophy and principles
- **[Contributing →](/contributing/)** — Help improve Rivaas with your contributions

## Next Steps

- **[Installation Guide →](/getting-started/)** — Install Rivaas and start building
- **[App Guide →](/guides/app/)** — Learn the framework architecture
- **[API Reference →](/reference/)** — Browse the complete API documentation
