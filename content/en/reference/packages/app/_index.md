---
title: "App"
linkTitle: "App"
weight: 10
description: >
  API reference for the Rivaas App package - a batteries-included web framework with integrated observability.
---

## Overview

The App package provides a high-level, opinionated framework built on top of the Rivaas router. It includes:

- Integrated observability (metrics, tracing, logging)
- Lifecycle management with hooks
- Graceful shutdown handling
- Health and debug endpoints
- OpenAPI spec generation
- Request binding and validation

## Package Information

- **Import Path:** `rivaas.dev/app`
- **Go Version:** 1.25+
- **License:** Apache 2.0

## Architecture

```
┌─────────────────────────────────────────┐
│           Application Layer             │
│  (app package)                          │
│                                         │
│  • Configuration Management             │
│  • Lifecycle Hooks                      │
│  • Observability Integration            │
│  • Server Management                    │
│  • Request Binding/Validation           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│           Router Layer                  │
│  (router package)                       │
│                                         │
│  • HTTP Routing                         │
│  • Middleware Chain                     │
│  • Request Context                      │
│  • Path Parameters                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│        Standard Library                 │
│  (net/http)                             │
└─────────────────────────────────────────┘
```

## Quick Reference

### Core Types

- [App](#app-type) - Main application type
- [Context](#context-type) - Request context with app-level features
- [HandlerFunc](#handlerfunc) - Handler function type

### Key Functions

- [New()](#new) - Create a new app (returns error)
- [MustNew()](#mustnew) - Create a new app (panics on error)

### Configuration

- [Options](options/) - App-level configuration options
- [Server Options](server-options/) - Server configuration
- [Observability Options](observability-options/) - Metrics, tracing, logging
- [Health Options](health-options/) - Health endpoint configuration
- [Debug Options](debug-options/) - Debug endpoint configuration

### API Reference

- [API Reference](api-reference/) - Core types and methods
- [Context API](context-api/) - Context methods for request handling
- [Lifecycle Hooks](lifecycle-hooks/) - Hook APIs and execution order

### Resources

- [Troubleshooting](troubleshooting/) - Common issues and solutions
- [pkg.go.dev](https://pkg.go.dev/rivaas.dev/app) - Full API documentation

## App Type

The main application type that wraps the router with app-level features.

```go
type App struct {
    // contains filtered or unexported fields
}
```

### Creating Apps

```go
// Returns (*App, error) for error handling
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithServiceVersion("v1.0.0"),
)
if err != nil {
    log.Fatal(err)
}

// Panics on error (like regexp.MustCompile)
a := app.MustNew(
    app.WithServiceName("my-api"),
)
```

### HTTP Methods

Register routes for HTTP methods:

```go
a.GET(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
a.POST(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
a.PUT(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
a.DELETE(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
a.PATCH(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
a.HEAD(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
a.OPTIONS(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
a.Any(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
```

### Server Management

```go
a.Start(ctx context.Context, addr string) error
a.StartTLS(ctx context.Context, addr, certFile, keyFile string) error
a.StartMTLS(ctx context.Context, addr string, cert tls.Certificate, opts ...MTLSOption) error
```

### Lifecycle Hooks

```go
a.OnStart(fn func(context.Context) error)
a.OnReady(fn func())
a.OnShutdown(fn func(context.Context))
a.OnStop(fn func())
a.OnRoute(fn func(*route.Route))
```

See [Lifecycle Hooks](lifecycle-hooks/) for details.

## Context Type

Request context that extends `router.Context` with app-level features.

```go
type Context struct {
    *router.Context
    // contains filtered or unexported fields
}
```

### Request Binding

```go
c.Bind(out any) error
c.BindJSONStrict(out any) error
c.BindAndValidate(out any, opts ...validation.Option) error
c.BindAndValidateStrict(out any, opts ...validation.Option) error
c.MustBindAndValidate(out any, opts ...validation.Option) bool
```

### Error Handling

```go
c.Error(err error)
c.ErrorStatus(err error, status int)
c.NotFound(message string)
c.BadRequest(message string)
c.Unauthorized(message string)
c.Forbidden(message string)
c.InternalError(err error)
```

### Logging

```go
c.Logger() *slog.Logger
```

See [Context API](context-api/) for complete reference.

## HandlerFunc

Handler function type that receives an app Context.

```go
type HandlerFunc func(*Context)
```

Example:

```go
func handler(c *app.Context) {
    c.JSON(http.StatusOK, data)
}

a.GET("/", handler)
```

## Next Steps

- [API Reference](api-reference/) - Complete API documentation
- [Options](options/) - Configuration options reference
- [Troubleshooting](troubleshooting/) - Common issues and solutions
- [User Guide](/guides/app/) - Learn how to use the app package
