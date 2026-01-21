---
title: "Installation"
linkTitle: "Installation"
weight: 1
keywords:
  - app installation
  - install
  - go get
  - setup
  - requirements
description: >
  Install the Rivaas App package and set up your development environment.
---

## Requirements

- **Go 1.25 or later** - The app package requires Go 1.25 or higher. It uses the latest language features and standard library.
- **Module support** - Your project must use Go modules. It needs a `go.mod` file.

## Installation

Install the app package using `go get`:

```bash
go get rivaas.dev/app
```

This downloads the app package and all its dependencies. These include:

- `rivaas.dev/router` - High-performance HTTP router.
- `rivaas.dev/binding` - Request binding and parsing.
- `rivaas.dev/validation` - Request validation.
- `rivaas.dev/errors` - Error formatting.
- `rivaas.dev/logging` - Structured logging (optional).
- `rivaas.dev/metrics` - Metrics collection (optional).
- `rivaas.dev/tracing` - OpenTelemetry tracing (optional).
- `rivaas.dev/openapi` - OpenAPI generation (optional).

## Verify Installation

Create a simple `main.go` to verify the installation:

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
            "message": "Installation successful!",
        })
    })

    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    log.Println("Server starting on :8080")
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}
```

Run the application:

```bash
go run main.go
```

Test the endpoint:

```bash
curl http://localhost:8080/
```

You should see:

```json
{"message":"Installation successful!"}
```

## Project Structure

A typical Rivaas app project structure:

```
myapp/
├── go.mod
├── go.sum
├── main.go              # Application entry point
├── handlers/            # HTTP handlers
│   ├── users.go
│   └── orders.go
├── middleware/          # Custom middleware
│   └── auth.go
├── models/              # Data models
│   └── user.go
├── services/            # Business logic
│   └── user_service.go
└── config/              # Configuration
    └── config.yaml
```

## Development Tools

### Hot Reload (Optional)

For development, you can use a hot reload tool like [air](https://github.com/cosmtrek/air):

```bash
# Install air
go install github.com/cosmtrek/air@latest

# Initialize air in your project
air init

# Run with hot reload
air
```

### Testing Tools

The app package includes built-in testing utilities. No additional tools required:

```go
package main

import (
    "net/http/httptest"
    "testing"
)

func TestHome(t *testing.T) {
    a, _ := app.New()
    a.GET("/", homeHandler)
    
    req := httptest.NewRequest("GET", "/", nil)
    resp, err := a.Test(req)
    if err != nil {
        t.Fatal(err)
    }
    
    if resp.StatusCode != 200 {
        t.Errorf("expected 200, got %d", resp.StatusCode)
    }
}
```

## Optional Dependencies

### Observability

If you plan to use observability features, you may want to configure exporters:

```bash
# For Prometheus metrics (default, no additional setup needed)

# For OTLP metrics/tracing (to send to Jaeger, Tempo, etc.)
# No additional packages needed - built into the tracing package
```

### OpenAPI

If you plan to use OpenAPI spec generation:

```bash
# No additional packages needed - included in app
```

## Next Steps

- [Basic Usage](../basic-usage/) - Learn how to create your first app
- [Configuration](../configuration/) - Configure your application
- [Examples](../examples/) - Explore complete working examples

## Troubleshooting

### Import Errors

If you see import errors:

```
cannot find package "rivaas.dev/app"
```

Make sure you've run `go get rivaas.dev/app` and your Go version is 1.25+:

```bash
go version  # Should show go1.25 or later
go mod tidy  # Clean up dependencies
```

### Module Issues

If you see module-related errors, ensure your project is using Go modules:

```bash
# Initialize a new module (if not already done)
go mod init myapp

# Download dependencies
go mod download
```

### Version Conflicts

If you encounter version conflicts with other Rivaas packages:

```bash
# Update all Rivaas packages to latest versions
go get -u rivaas.dev/app
go get -u rivaas.dev/router
go get -u rivaas.dev/binding
go mod tidy
```
