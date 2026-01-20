---
title: "Installation"
linkTitle: "Installation"
weight: 10
description: >
  Install the Rivaas Router in your Go project.
---

## Requirements

- **Go 1.25 or higher**.
- Standard library only. No external dependencies for core routing.

## Install the Router

Add the router to your Go project:

```bash
go get rivaas.dev/router
```

## Verify Installation

Create a simple test file to verify the installation:

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    
    r.GET("/", func(c *router.Context) {
        c.String(http.StatusOK, "Router is working!")
    })
    
    http.ListenAndServe(":8080", r)
}
```

Run the test:

```bash
go run main.go
```

Visit `http://localhost:8080/` in your browser - you should see "Router is working!"

## Optional Dependencies

### Middleware

For built-in middleware like structured logging and metrics:

```bash
# For AccessLog middleware (structured logging)
go get rivaas.dev/logging

# For Metrics middleware
go get rivaas.dev/metrics
```

### OpenTelemetry Tracing

For OpenTelemetry tracing support:

```bash
# Core OpenTelemetry libraries
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/trace
go get go.opentelemetry.io/otel/sdk

# Example: Jaeger exporter
go get go.opentelemetry.io/otel/exporters/jaeger
```

### Validation

For tag-based validation (go-playground/validator):

```bash
go get github.com/go-playground/validator/v10
```

The router automatically detects and uses validator if available.

## Project Structure

Recommended project structure for a router-based application:

```
myapp/
├── main.go                 # Application entry point
├── routes/
│   ├── routes.go          # Route registration
│   ├── users.go           # User routes
│   └── posts.go           # Post routes
├── handlers/
│   ├── users.go           # User handlers
│   └── posts.go           # Post handlers
├── middleware/
│   ├── auth.go            # Authentication middleware
│   └── logging.go         # Custom logging
└── go.mod
```

## Next Steps

- **Basic Usage**: Learn the fundamentals in the [Basic Usage guide](../basic-usage/)
- **Quick Start**: See the [Quick Start example](../#quick-start) for a complete working application
- **Examples**: Browse [working examples](../examples/) for common patterns
