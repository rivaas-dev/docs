---
title: Installation
description: Install Rivaas and verify your setup
weight: 1
---

Installing Rivaas is straightforward. You can use it as a complete framework with the `app` package or use individual packages as needed.

## Install the Full Framework

The `app` package provides a batteries-included web framework with everything you need to build production-ready APIs:

```bash
go get rivaas.dev/app
```

This installs the main framework along with all integrated packages (router, logging, metrics, tracing, etc.).

## Install Individual Packages

Rivaas packages can be used independently. Install only what you need:

```bash
# High-performance router only
go get rivaas.dev/router

# Request binding and validation
go get rivaas.dev/binding
go get rivaas.dev/validation

# Observability packages
go get rivaas.dev/logging
go get rivaas.dev/metrics
go get rivaas.dev/tracing

# API documentation and error handling
go get rivaas.dev/openapi
go get rivaas.dev/errors
```

## Verify Installation

Create a simple test file to verify your installation:

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
        log.Fatalf("Failed to create app: %v", err)
    }

    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "✅ Rivaas installed successfully!",
        })
    })

    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    log.Println("Test server running on http://localhost:8080")
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}
```

Run it:

```bash
go run main.go
```

Test it in another terminal:

```bash
curl http://localhost:8080
# Output: {"message":"✅ Rivaas installed successfully!"}
```

Press `Ctrl+C` to stop the server gracefully.

## System Requirements

- **Go Version:** 1.25 or higher
- **Operating Systems:** Linux, macOS, Windows
- **Architecture:** amd64, arm64

## Updating Rivaas

To update to the latest version:

```bash
go get -u rivaas.dev/app
```

To update a specific package:

```bash
go get -u rivaas.dev/router
```

## Development Dependencies

For development, you may want additional tools:

```bash
# Install Go tools (optional but recommended)
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

## Troubleshooting

### Go Version Issues

If you see an error about Go version:

```bash
go: module rivaas.dev/app requires go >= 1.25
```

Update your Go installation to 1.25 or higher from [go.dev/dl](https://go.dev/dl/).

### Module Cache Issues

If installation fails, try cleaning the module cache:

```bash
go clean -modcache
go get rivaas.dev/app
```

### Network Issues

If you're behind a proxy or firewall:

```bash
# Set proxy (if needed)
export GOPROXY=https://proxy.golang.org,direct

# Or use a custom proxy
export GOPROXY=https://goproxy.io,direct
```

## Next Steps

Now that you have Rivaas installed, let's build your first application:

**[Build Your First Application →](../first-application/)**

