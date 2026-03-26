---
title: Next Steps
description: Continue learning Rivaas
weight: 5
keywords:
  - next steps
  - learning path
  - advanced topics
  - further reading
  - continue learning
---

You've completed the Getting Started guide. You now know how to install Rivaas, build applications, configure them, and add middleware.

## What You've Learned

✅ **Installation** — Set up Rivaas and verified it works  
✅ **First Application** — Built a REST API with routes and JSON responses  
✅ **Configuration** — Configured service metadata, health checks, and observability  
✅ **Middleware** — Added functionality like CORS and authentication

## Choose Your Path

### 🚀 Building Production APIs

Learn advanced routing, error handling, and API patterns:

- **[Routing Guide](/docs/guides/router/)** — Advanced routing patterns, groups, and constraints
- **[Request Binding](/docs/guides/binding/)** — Bind and validate JSON, XML, YAML, and form data
- **[OpenAPI Documentation](/docs/guides/openapi/)** — Auto-generate API specs
- **[Validation Guide](/docs/guides/validation/)** — Input validation strategies

**Recommended Example:** [Blog API](https://github.com/rivaas-dev/rivaas/tree/main/app/examples/02-blog) — Full-featured blog with CRUD operations, validation, and testing.

### 📊 Observability & Monitoring

Understand your application in production:

- **[Logging Guide](/docs/guides/logging/)** — Structured logging with slog
- **[Metrics Guide](/docs/guides/metrics/)** — Prometheus metrics and custom instrumentation
- **[Tracing Guide](/docs/guides/tracing/)** — Distributed tracing with OpenTelemetry
- **[Health Endpoints](/docs/guides/app/health-endpoints/)** — Kubernetes-compatible liveness/readiness

**Key Pattern:** The observability trinity (logs, metrics, traces) works together. They provide complete visibility into your application.

### 🔒 Security & Best Practices

Secure your APIs:

- **[Validation Guide](/docs/guides/validation/)** — Input validation and sanitization
- **[Validation Security](/docs/guides/validation/security/)** — Security considerations for validation
- **[Router Middleware](/docs/guides/router/middleware/)** — Security middleware (basic auth, rate limiting)

**Security Checklist:**
- ✅ Use HTTPS in production
- ✅ Validate all inputs
- ✅ Implement authentication
- ✅ Add rate limiting
- ✅ Enable security headers

### ☁️ Deployment & Operations

Deploy your application to production:

- **[App Configuration](/docs/guides/app/configuration/)** — Environment-based config
- **[Server Configuration](/docs/guides/app/server/)** — Timeouts and graceful shutdown
- **[Health Endpoints](/docs/guides/app/health-endpoints/)** — Kubernetes-compatible probes
- **[Debug Endpoints](/docs/guides/app/debug-endpoints/)** — pprof for profiling

**Production Checklist:**
- ✅ Set up health endpoints
- ✅ Configure timeouts
- ✅ Enable observability
- ✅ Use environment variables
- ✅ Implement graceful shutdown

### 🎯 Advanced Topics

Deep dive into framework internals:

- **[Router Middleware](/docs/guides/router/middleware/)** — Build reusable middleware
- **[App Testing](/docs/guides/app/testing/)** — Unit, integration, and E2E tests
- **[Lifecycle Hooks](/docs/reference/packages/app/lifecycle-hooks/)** — Application lifecycle management

## Example Applications

Learn from complete, production-ready examples:

### Quick Start Example
**Path:** `/app/examples/01-quick-start`  
**Complexity:** Beginner  
**Shows:** Minimal setup, basic routing, health checks

```bash
cd app/examples/01-quick-start
go run main.go
```

### Blog API Example
**Path:** `/app/examples/02-blog`  
**Complexity:** Intermediate  
**Shows:** CRUD operations, validation, OpenAPI, testing, configuration

```bash
cd app/examples/02-blog
go run main.go
# Visit http://localhost:8080/docs for Swagger UI
```

**Features:**
- Complete REST API (posts, authors, comments)
- Method-based validation
- OpenAPI documentation
- Comprehensive tests
- Configuration management
- Observability setup

### More Examples

- **[Middleware Examples](https://github.com/rivaas-dev/rivaas/tree/main/router/middleware/examples)** — All 12 middleware with curl commands
- **[Router Examples](https://github.com/rivaas-dev/rivaas/tree/main/router/examples)** — Low-level router usage

## Framework Packages

Rivaas is modular — use any package independently:

### Core Packages

| Package | Description | Go Reference |
|---------|-------------|--------------|
| **app** | Batteries-included framework | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/app) |
| **router** | High-performance HTTP router | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/router) |

### Data Handling

| Package | Description | Go Reference |
|---------|-------------|--------------|
| **binding** | Request binding (JSON, XML, YAML, etc.) | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/binding) |
| **validation** | Struct validation with JSON Schema | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/validation) |

### Observability

| Package | Description | Go Reference |
|---------|-------------|--------------|
| **logging** | Structured logging with slog | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/logging) |
| **metrics** | OpenTelemetry metrics | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/metrics) |
| **tracing** | Distributed tracing | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/tracing) |

### API & Errors

| Package | Description | Go Reference |
|---------|-------------|--------------|
| **openapi** | OpenAPI 3.0/3.1 generation | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/openapi) |
| **errors** | Error formatting (RFC 9457, JSON:API) | [pkg.go.dev](https://pkg.go.dev/rivaas.dev/errors) |

**Learn More:** [Package Documentation](/docs/reference/packages/)

## Reference Documentation

Quick access to API references:

- **[App Options](/docs/reference/packages/app/options/)** — All configuration options
- **[App Context API](/docs/reference/packages/app/context-api/)** — Request/response handling
- **[Router Middleware](/docs/reference/packages/router/middleware/)** — All middleware options
- **[Router API](/docs/reference/packages/router/api-reference/)** — Low-level router API

## Community & Support

### Get Help

- 💬 **GitHub Discussions** — Ask questions, share ideas
- 🐛 **GitHub Issues** — Report bugs, request features
- 📧 **Email** — security@rivaas.dev (security issues only)

### Contribute

Rivaas is open source and welcomes contributions:

- **[Contributing Guide](https://github.com/rivaas-dev/rivaas/blob/main/CONTRIBUTING.md)** — How to contribute
- **[Design Principles](https://github.com/rivaas-dev/rivaas/blob/main/docs/DESIGN_PRINCIPLES.md)** — Framework philosophy
- **[Testing Standards](https://github.com/rivaas-dev/rivaas/blob/main/docs/TESTING_STANDARDS.md)** — Testing guidelines

### Stay Updated

- ⭐ **[Star on GitHub](https://github.com/rivaas-dev/rivaas)** — Get notified of releases
- 📦 **[Release Notes](https://github.com/rivaas-dev/rivaas/releases)** — What's new
- 🗺️ **[Roadmap](https://github.com/rivaas-dev/rivaas/blob/main/ROADMAP.md)** — Upcoming features

## Quick Reference Card

### Create Application

```go
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithServiceVersion("v1.0.0"),
)
```

### Register Routes

```go
a.GET("/path", handler)
a.POST("/path", handler)
a.PUT("/path/:id", handler)
a.DELETE("/path/:id", handler)
```

### Add Middleware

```go
a.Use(middleware1, middleware2)
api := a.Group("/api", authMiddleware)
```

### Start Server

```go
a.Start(context.Background())
```

### Handle Requests

```go
func handler(c *app.Context) {
    // Get path parameter
    id := c.Param("id")
    
    // Get query parameter
    filter := c.Query("filter")
    
    // Bind request body (auto-detects JSON, form, etc.)
    var req MyRequest
    if err := c.Bind(&req); err != nil {
        c.JSON(400, map[string]string{"error": "Invalid request"})
        return
    }
    
    // Send JSON response
    c.JSON(200, map[string]string{"status": "ok"})
}
```

## What's Next?

Pick the topic that interests you most. The documentation works for both linear reading and jumping to specific topics.

**Happy building with Rivaas!**
