---
title: "Router"
linkTitle: "Router"
weight: 50
description: >
  An HTTP router for Go, designed for cloud-native applications with comprehensive routing, middleware, and observability features.
---

{{% pageinfo %}}
The Rivaas Router provides a high-performance, feature-rich routing system with built-in middleware, OpenTelemetry support, and comprehensive request handling capabilities.
{{% /pageinfo %}}

## Overview

The Rivaas Router is a production-ready HTTP router designed for cloud-native applications. It combines exceptional performance (8.4M+ req/s, 119ns/op) with a rich feature set including automatic request binding, comprehensive validation, content negotiation, API versioning, and native OpenTelemetry tracing.

## Key Features

### Core Routing & Request Handling

- **Radix tree routing** - Path matching with bloom filters for static route lookups
- **Compiled route tables** - Pre-compiled routes for static and dynamic path matching
- **Path Parameters**: `/users/:id`, `/posts/:id/:action` - Array-based storage for route parameters
- **Wildcard Routes**: `/files/*filepath` - Catch-all routing for file serving
- **Route Groups**: Organize routes with shared prefixes and middleware
- **Middleware Chain**: Global, group-level, and route-level middleware support
- **Route Constraints**: Numeric, UUID, Alpha, Alphanumeric, Custom regex validation
- **Concurrent Safe**: Thread-safe for use by multiple goroutines

### Request Binding

Automatically bind request data to structs:

- **Router Context**: Built-in `BindStrict()` for strict JSON binding with size limits
- **Binding Package**: Full binding with `binding.Query()`, `binding.JSON()`, `binding.Form()`, `binding.Headers()`, `binding.Cookies()`
- **15+ Type Categories**: Primitives, Time, Network types (net.IP, net.IPNet), Maps, Nested Structs, Slices
- **Advanced Features**: Maps with dot/bracket notation, nested structs in query strings, enum validation, default values

### Request Validation

- **Multiple Strategies**: Interface validation, Tag validation (go-playground/validator), JSON Schema
- **Partial Validation**: PATCH request support (validate only present fields)
- **Structured Errors**: Machine-readable error codes and field paths
- **Context-Aware**: Request-scoped validation rules

### Response Rendering

- **JSON Variants**: Standard, Indented, Pure, Secure, ASCII, JSONP
- **Alternative Formats**: YAML, String, HTML
- **Binary & Streaming**: Zero-copy streaming from io.Reader, file serving

### Content Negotiation - RFC 7231 Compliant

- Media type negotiation with quality values
- Character set, encoding, and language negotiation
- Wildcard support and specificity matching

### API Versioning - Built-in

- **Header-based**: `API-Version: v1`
- **Query-based**: `?version=v1`
- **Custom detection**: Flexible version strategies
- **Version-specific routes**: `r.Version("v1").GET(...)`
- **Lock-free implementation**: Atomic operations

### Middleware (Built-in)

- **AccessLog** - Structured HTTP access logging
- **Recovery** - Panic recovery with graceful errors
- **CORS** - Cross-Origin Resource Sharing
- **Basic Auth** - HTTP Basic Authentication
- **Compression** - Gzip/Brotli response compression
- **Request ID** - X-Request-ID generation
- **Security Headers** - HSTS, CSP, X-Frame-Options
- **Timeout** - Request timeout handling
- **Rate Limit** - Token bucket rate limiting
- **Body Limit** - Request body size limiting

### Observability - OpenTelemetry Native

- **Metrics**: Custom histograms, counters, gauges, automatic request metrics
- **Tracing**: Native OpenTelemetry support with zero overhead when disabled
- **Diagnostics**: Optional diagnostic events for security concerns

### Performance

- **Sub-microsecond routing**: 119ns per operation
- **High throughput**: 8.4M+ requests/second
- **Memory efficient**: 16 bytes per request, 1 allocation
- **Context pooling**: Automatic context reuse
- **Lock-free operations**: Atomic operations for concurrent access

## Quick Start

Get up and running in minutes with this complete example:

```go
package main

import (
    "fmt"
    "net/http"
    "time"
    
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()  // Panics on invalid config (use at startup)
    
    // Global middleware
    r.Use(Logger(), Recovery())
    
    // Simple route
    r.GET("/", func(c *router.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello Rivaas!",
            "version": "1.0.0",
        })
    })
    
    // Parameter route
    r.GET("/users/:id", func(c *router.Context) {
        userID := c.Param("id")
        c.JSON(http.StatusOK, map[string]string{
            "user_id": userID,
        })
    })
    
    // POST with strict JSON binding
    r.POST("/users", func(c *router.Context) {
        var req struct {
            Name  string `json:"name"`
            Email string `json:"email"`
        }
        
        if err := c.BindStrict(&req, router.BindOptions{MaxBytes: 1 << 20}); err != nil {
            return // Error response already written
        }
        
        c.JSON(http.StatusCreated, req)
    })
    
    http.ListenAndServe(":8080", r)
}

// Middleware examples
func Logger() router.HandlerFunc {
    return func(c *router.Context) {
        start := time.Now()
        c.Next()
        duration := time.Since(start)
        fmt.Printf("[%s] %s - %v\n", c.Request.Method, c.Request.URL.Path, duration)
    }
}

func Recovery() router.HandlerFunc {
    return func(c *router.Context) {
        defer func() {
            if err := recover(); err != nil {
                c.JSON(http.StatusInternalServerError, map[string]string{
                    "error": "Internal server error",
                })
            }
        }()
        c.Next()
    }
}
```

## Learning Path

Follow this structured path to master the Rivaas Router:

### 1. Getting Started

Start with the basics:

- [Installation](installation/) - Set up the router in your project
- [Basic Usage](basic-usage/) - Create your first router and routes
- [Route Patterns](route-patterns/) - Learn about static, parameter, and wildcard routes

### 2. Core Features

Build upon the fundamentals:

- [Route Groups](route-groups/) - Organize routes with groups and prefixes
- [Middleware](middleware/) - Add cross-cutting concerns like logging and auth
- [Context](context/) - Understand the request context and memory safety

### 3. Request Handling

Handle requests effectively:

- [Request Binding](request-binding/) - Automatically parse request data to structs
- [Validation](validation/) - Validate requests with multiple strategies
- [Response Rendering](response-rendering/) - Render JSON, YAML, HTML, and binary responses

### 4. Advanced Features

Leverage advanced capabilities:

- [Content Negotiation](content-negotiation/) - Handle Accept headers and format negotiation
- [API Versioning](api-versioning/) - Build versioned APIs with built-in support
- [Static Files](static-files/) - Serve static files and directories

### 5. Production Readiness

Prepare for production:

- [Observability](observability/) - Integrate OpenTelemetry tracing and diagnostics
- [Testing](testing/) - Test your routes and middleware
- [Migration](migration/) - Migrate from Gin, Echo, or http.ServeMux

### 6. Examples & Patterns

Learn from real-world examples:

- [Examples](examples/) - Complete working examples and use cases

## Common Use Cases

The Rivaas Router excels in these scenarios:

- **REST APIs** - JSON APIs with comprehensive request/response handling
- **Web Applications** - HTML rendering, forms, sessions, static files
- **Microservices** - OpenTelemetry integration, API versioning, health checks
- **High-Performance Services** - Sub-microsecond routing, 8.4M+ req/s throughput

## Next Steps

- **Installation**: [Install the router](installation/) and set up your first project
- **Basic Usage**: Follow the [Basic Usage guide](basic-usage/) to learn the fundamentals
- **Examples**: Explore [complete examples](examples/) for common patterns
- **API Reference**: Check the [API Reference](/reference/packages/router/) for detailed documentation

## Need Help?

- **Troubleshooting**: See [Common Issues](/reference/packages/router/troubleshooting/)
- **Examples**: Browse [working examples](examples/)
- **API Docs**: Check [pkg.go.dev](https://pkg.go.dev/rivaas.dev/router)
