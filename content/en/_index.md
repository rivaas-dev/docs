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
    a := app.MustNew()

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
Step-by-step tutorials covering common tasks like setting up observability, configuring middleware, and deploying to production.

### Reference
Detailed API documentation for all packages, configuration options, and advanced features.

### Examples
Real-world examples and patterns for building production applications.

## Package Overview

Rivaas is organized into independent, standalone packages:

### Core Packages
- **[app](/docs/packages/app/)** — Batteries-included web framework
- **[router](/docs/packages/router/)** — High-performance HTTP router

### Data Handling
- **[binding](/docs/packages/binding/)** — Request binding (JSON, XML, YAML, MsgPack, Proto)
- **[validation](/docs/packages/validation/)** — Struct validation with tags and JSON Schema

### Observability
- **[logging](/docs/packages/logging/)** — Structured logging with slog
- **[metrics](/docs/packages/metrics/)** — OpenTelemetry metrics (Prometheus, OTLP)
- **[tracing](/docs/packages/tracing/)** — Distributed tracing (OTLP, Jaeger, stdout)

### API & Errors
- **[openapi](/docs/packages/openapi/)** — Automatic OpenAPI 3.0/3.1 generation
- **[errors](/docs/packages/errors/)** — Error formatting (RFC 9457, JSON:API)

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
- **[Core Concepts →](/guides/concepts/)** — Understand the framework architecture
- **[API Reference →](/reference/)** — Explore the complete API documentation
