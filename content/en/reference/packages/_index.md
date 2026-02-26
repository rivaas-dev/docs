---
title: "Package Reference"
description: "API reference documentation for Rivaas packages"
weight: 1
no_list: true
keywords:
  - packages
  - modules
  - api
  - library
  - package reference
---

Detailed API reference for all Rivaas packages. Each package reference includes complete documentation of types, methods, options, and technical details.

## Available Packages

### App (`rivaas.dev/app`)

A batteries-included web framework built on top of the Rivaas router. Includes integrated observability (metrics, tracing, logging), lifecycle management with hooks, graceful shutdown handling, health and debug endpoints, and request binding/validation.

[View App Package Reference →](/reference/packages/app/)

### Router (`rivaas.dev/router`)

High-performance HTTP router with radix tree routing, bloom filters, and compiled route tables. Features sub-microsecond routing, built-in middleware support, OpenTelemetry support, API versioning, and content negotiation.

[View Router Package Reference →](/reference/packages/router/)

### Config (`rivaas.dev/config`)

Powerful configuration management for Go applications with support for multiple sources (files, environment variables, remote sources), format-agnostic with built-in JSON/YAML/TOML support, hierarchical configuration merging, and automatic struct binding with validation.

[View Config Package Reference →](/reference/packages/config/)

### Binding (`rivaas.dev/binding`)

High-performance request data binding for Go web applications. Maps values from various sources (query parameters, form data, JSON bodies, headers, cookies, path parameters) into Go structs using struct tags with type-safe generic API.

[View Binding Package Reference →](/reference/packages/binding/)

### Validation (`rivaas.dev/validation`)

Flexible, multi-strategy validation for Go structs with support for struct tags, JSON Schema, and custom interfaces. Features partial validation for PATCH requests, sensitive data redaction, and detailed field-level error reporting.

[View Validation Package Reference →](/reference/packages/validation/)

### Logging (`rivaas.dev/logging`)

Structured logging for Go applications using Go's standard `log/slog` package. Features multiple output formats (JSON, Text, Console), context-aware logging with OpenTelemetry trace correlation, automatic sensitive data redaction, and log sampling.

[View Logging Package Reference →](/reference/packages/logging/)

### Metrics (`rivaas.dev/metrics`)

OpenTelemetry-based metrics collection for Go applications with support for Prometheus, OTLP, and stdout exporters. Includes built-in HTTP metrics middleware, custom metrics (counters, histograms, gauges), and automatic header filtering for security.

[View Metrics Package Reference →](/reference/packages/metrics/)

### Tracing (`rivaas.dev/tracing`)

OpenTelemetry-based distributed tracing for Go applications with support for Stdout, OTLP (gRPC and HTTP), and Noop providers. Includes built-in HTTP middleware for request tracing, manual span management, and context propagation.

[View Tracing Package Reference →](/reference/packages/tracing/)

### OpenAPI (`rivaas.dev/openapi`)

Automatic OpenAPI 3.0.4 and 3.1.2 specification generation from Go code using struct tags and reflection. Features fluent HTTP method constructors, automatic parameter discovery, schema generation, built-in validation, and Swagger UI configuration support.

[View OpenAPI Package Reference →](/reference/packages/openapi/)
