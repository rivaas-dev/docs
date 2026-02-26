---
title: "Router Package"
linkTitle: "Router"
weight: 40
no_list: true
keywords:
  - router api
  - router package
  - rivaas.dev/router
  - router reference
description: >
  Complete API reference for the rivaas.dev/router package.
---

{{% pageinfo %}}
This is the API reference for the `rivaas.dev/router` package. For learning-focused documentation, see the [Router Guide](/guides/router/).
{{% /pageinfo %}}

## Overview

The `rivaas.dev/router` package provides a high-performance HTTP router with comprehensive features:

- Radix tree routing with bloom filters
- Compiled route tables for performance
- Built-in middleware support
- OpenTelemetry support
- API versioning
- Content negotiation

## Package Structure

```
rivaas.dev/router/
├── router.go          # Core router and route registration
├── context.go         # Request context with pooling
├── route.go           # Route definitions and constraints
├── middleware/        # Built-in middleware
│   ├── accesslog/    # Structured access logging
│   ├── cors/         # CORS handling
│   ├── recovery/     # Panic recovery
│   └── ...           # More middleware
└── ...
```

## Quick API Index

### Core Types

- **[`Router`](api-reference/#router)** - Main router type
- **[`Context`](context-api/)** - Request context
- **[`Route`](api-reference/#route)** - Route definition
- **[`Group`](api-reference/#group)** - Route group

### Route Registration

- **HTTP Methods**: `GET()`, `POST()`, `PUT()`, `DELETE()`, `PATCH()`, `OPTIONS()`, `HEAD()`
- **Route Groups**: `Group(prefix)`, `Version(version)`
- **Middleware**: `Use(middleware...)`
- **Static Files**: `Static()`, `StaticFile()`, `StaticFS()`

### Request Handling

- **Parameters**: `Param()`, `Query()`, `PostForm()`
- **Headers**: `Header()`, `GetHeader()`
- **Cookies**: `Cookie()`, `SetCookie()`

### Response Rendering

- **JSON**: `JSON()`, `PureJSON()`, `IndentedJSON()`, `SecureJSON()`
- **Other**: `YAML()`, `String()`, `HTML()`, `Data()`
- **Files**: `ServeFile()`, `Download()`, `DataFromReader()`

### Configuration

- **Router Options**: See [Options](options/)
- **Route Constraints**: See [Route Constraints](route-constraints/)
- **Middleware Options**: See [Middleware](middleware/)

## Performance

### Routing Performance

- **Sub-microsecond routing** — See [Performance](performance/) for current latency and throughput numbers.
- **Zero allocation** — No allocations for routing and param extraction in typical cases (≤8 path params). See [Performance](performance/) for benchmark details.
- **Memory efficient** — Context pooling and minimal allocations per request.
- **Context pooling**: Automatic context reuse
- **Lock-free operations**: Atomic operations for concurrent access

### Optimization Features

- **Compiled routes**: Pre-compiled routes for static and dynamic paths
- **Bloom filters**: Fast negative lookups for static routes
- **First-segment index**: ASCII-only route narrowing (O(1) lookup)
- **Parameter storage**: Array-based for ≤8 params, map for >8
- **Type caching**: Reflection information cached per struct type

## Thread Safety

All router operations are concurrent-safe:

- Route registration can occur from multiple goroutines
- Route trees use atomic operations for concurrent access
- Context pooling is thread-safe
- Middleware execution is goroutine-safe

## Next Steps

- **API Reference**: See [detailed API documentation](api-reference/)
- **Context API**: Check [Context methods](context-api/)
- **Options**: Review [Router options](options/)
- **Constraints**: Learn about [route constraints](route-constraints/)
- **Troubleshooting**: See [common issues](troubleshooting/)

## External Links

- **pkg.go.dev**: [rivaas.dev/router](https://pkg.go.dev/rivaas.dev/router)
- **Source Code**: [GitHub](https://github.com/rivaas-dev/rivaas/tree/main/router)
- **Examples**: [Router Examples](https://github.com/rivaas-dev/rivaas/tree/main/router/examples)
