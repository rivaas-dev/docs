---
title: "Guides"
description: "Learning-oriented guides for building applications with Rivaas"
weight: 20
sidebar_root_for: self
no_list: true
keywords:
  - guides
  - tutorials
  - how-to
  - learning
  - walkthrough
  - examples
---

Comprehensive guides to help you learn and master Rivaas features. These learning-focused tutorials walk you through practical examples and real-world scenarios.

{{% alert title="New to Rivaas?" color="primary" %}}
Start with the [Application Framework](/guides/app/) guide to learn how to build production-ready applications, then explore the [HTTP Router](/guides/router/) for routing fundamentals.
{{% /alert %}}

---

## Core Framework

Build web applications with integrated observability and production-ready defaults.

### Application Framework

A complete web framework built on the Rivaas router. Includes integrated observability, lifecycle management, graceful shutdown, and sensible defaults for rapid application development.

[Explore App Guide →](/guides/app/)

### HTTP Router

High-performance HTTP routing for cloud-native applications. Features radix tree routing, middleware chains, content negotiation, API versioning, and native OpenTelemetry support.

[Explore Router Guide →](/guides/router/)

---

## Request Processing

Handle incoming requests with type-safe binding and validation.

### Request Data Binding

Bind HTTP request data from various sources (query parameters, form data, JSON bodies, headers, cookies, path parameters) to Go structs with type safety and zero-allocation performance.

[Explore Binding Guide →](/guides/binding/)

### Request Validation

Flexible, multi-strategy validation for Go structs. Supports struct tags via go-playground/validator, JSON Schema, and custom interfaces with detailed error messages.

[Explore Validation Guide →](/guides/validation/)

---

## Configuration & Documentation

Manage application settings and generate API documentation.

### Configuration Management

Configuration management following the Twelve-Factor App methodology. Load from files, environment variables, or Consul with hierarchical merging and struct binding.

[Explore Config Guide →](/guides/config/)

### OpenAPI Specification

Automatic OpenAPI 3.0.4 and 3.1.2 specification generation from Go code. Uses struct tags and reflection with built-in Swagger UI support and security scheme configuration.

[Explore OpenAPI Guide →](/guides/openapi/)

---

## Observability

Monitor, trace, and debug your applications in production.

### Structured Logging

Production-ready structured logging using Go's standard `log/slog`. Features multiple output formats, context-aware logging, sensitive data redaction, log sampling, and dynamic log levels.

[Explore Logging Guide →](/guides/logging/)

### Metrics Collection

OpenTelemetry-based metrics collection with support for Prometheus, OTLP, and stdout exporters. Includes built-in HTTP metrics, custom metrics support, and thread-safe operations.

[Explore Metrics Guide →](/guides/metrics/)

### Distributed Tracing

OpenTelemetry-based distributed tracing with automatic context propagation across services. Supports multiple exporters including OTLP (gRPC and HTTP) with HTTP middleware integration.

[Explore Tracing Guide →](/guides/tracing/)
