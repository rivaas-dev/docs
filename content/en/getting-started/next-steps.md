---
title: Next Steps
description: Continue your journey with Rivaas
weight: 5
---

Congratulations! You've completed the Getting Started guide. You now know how to install Rivaas, build applications, configure them, and use middleware.

## What You've Learned

✅ **Installation** — Set up Rivaas and verify it works  
✅ **First Application** — Built a REST API with routes and JSON responses  
✅ **Configuration** — Configured service metadata, health checks, and observability  
✅ **Middleware** — Added cross-cutting functionality like CORS and authentication

## Choose Your Path

### 🚀 Building Production APIs

Learn advanced routing, error handling, and API patterns:

- **[Routing Guide](/guides/routing/)** — Advanced routing patterns, groups, constraints
- **[Error Handling](/guides/errors/)** — RFC 9457 problem details, JSON:API errors
- **[Request Binding](/guides/binding/)** — Bind and validate JSON, XML, YAML, form data
- **[OpenAPI Documentation](/guides/openapi/)** — Auto-generate API documentation

**Recommended Example:** [Blog API](https://github.com/rivaas-dev/rivaas/tree/main/app/examples/02-blog) — Full-featured blog with CRUD operations, validation, and testing.

### 📊 Observability & Monitoring

Understand your application in production:

- **[Logging Guide](/guides/logging/)** — Structured logging with slog
- **[Metrics Guide](/guides/metrics/)** — Prometheus metrics and custom instrumentation
- **[Tracing Guide](/guides/tracing/)** — Distributed tracing with OpenTelemetry
- **[Health Checks](/guides/health-checks/)** — Kubernetes-compatible liveness/readiness

**Key Pattern:** The observability trinity (logs, metrics, traces) works together to give complete visibility.

### 🔒 Security & Authentication

Secure your APIs:

- **[Authentication Guide](/guides/authentication/)** — JWT, OAuth, API keys
- **[Authorization Guide](/guides/authorization/)** — RBAC, permissions
- **[Security Headers](/guides/security/)** — CSP, HSTS, X-Frame-Options
- **[Rate Limiting](/guides/rate-limiting/)** — Protect against abuse

**Security Checklist:**
- ✅ Use HTTPS in production
- ✅ Validate all inputs
- ✅ Implement authentication
- ✅ Add rate limiting
- ✅ Enable security headers

### ☁️ Deployment & Operations

Deploy your application to production:

- **[Docker Deployment](/guides/docker/)** — Containerize your application
- **[Kubernetes Deployment](/guides/kubernetes/)** — Deploy to Kubernetes
- **[Configuration Management](/guides/configuration/)** — Environment-based config
- **[Graceful Shutdown](/guides/shutdown/)** — Handle signals properly

**Production Checklist:**
- ✅ Set up health endpoints
- ✅ Configure timeouts
- ✅ Enable observability
- ✅ Use environment variables
- ✅ Implement graceful shutdown

### 🎯 Advanced Topics

Deep dive into framework internals:

- **[Custom Middleware](/guides/custom-middleware/)** — Build reusable middleware
- **[Performance Tuning](/guides/performance/)** — Optimize your application
- **[Testing Strategies](/guides/testing/)** — Unit, integration, and E2E tests
- **[Framework Architecture](/concepts/architecture/)** — How Rivaas works internally

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

**Learn More:** [Package Documentation](/packages/)

## Reference Documentation

Quick access to API references:

- **[Configuration Options](/reference/configuration-options/)** — All config options
- **[Context Methods](/reference/context/)** — Request/response handling
- **[Middleware Reference](/reference/middleware/)** — All middleware options
- **[Router API](/reference/router/)** — Low-level router API

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
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()
a.Start(ctx, ":8080")
```

### Handle Requests

```go
func handler(c *app.Context) {
    // Get path parameter
    id := c.Param("id")
    
    // Get query parameter
    filter := c.Query("filter")
    
    // Bind JSON body
    var req MyRequest
    if err := c.BindJSON(&req); err != nil {
        c.JSON(400, map[string]string{"error": "Invalid JSON"})
        return
    }
    
    // Send JSON response
    c.JSON(200, map[string]string{"status": "ok"})
}
```

## What's Next?

Pick the topic that interests you most and dive in. The documentation is designed to support both linear reading and jumping to specific topics as needed.

**Happy building with Rivaas! 🚀**

---

**Feedback?** Help improve these docs — [open an issue](https://github.com/rivaas-dev/rivaas/issues) or [submit a PR](https://github.com/rivaas-dev/rivaas/pulls).

