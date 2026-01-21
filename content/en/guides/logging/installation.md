---
title: "Installation"
description: "How to install and set up the Rivaas logging package"
weight: 2
keywords:
  - logging installation
  - install
  - go get
  - setup
---

This guide covers how to install the logging package and understand its dependencies.

## Installation

Install the logging package using `go get`:

```bash
go get rivaas.dev/logging
```

**Requirements:** Go 1.25 or higher

## Dependencies

The logging package has minimal external dependencies to maintain simplicity and avoid bloat.

| Dependency | Purpose | Required |
|------------|---------|----------|
| Go stdlib (`log/slog`) | Core logging | Yes |
| `go.opentelemetry.io/otel/trace` | Trace correlation in `ContextLogger` | Optional* |
| `github.com/stretchr/testify` | Test utilities | Test only |

\* The OpenTelemetry trace dependency is only used by `NewContextLogger()` for automatic trace/span ID extraction. If you don't use context-aware logging with tracing, this dependency has no runtime impact.

## Verifying Installation

Create a simple test to verify the installation:

```go
package main

import (
    "rivaas.dev/logging"
)

func main() {
    log := logging.MustNew(
        logging.WithConsoleHandler(),
    )
    
    log.Info("installation successful", "version", "v1.0.0")
}
```

Run the program:

```bash
go run main.go
```

You should see output like:

```
10:30:45.123 INFO  installation successful version=v1.0.0
```

## Import Statement

Import the logging package in your Go files:

```go
import "rivaas.dev/logging"
```

For context-aware logging with OpenTelemetry:

```go
import (
    "rivaas.dev/logging"
    "go.opentelemetry.io/otel/trace"
)
```

## Module Integration

Add to your `go.mod`:

```go
module example.com/myapp

go 1.25

require (
    rivaas.dev/logging v1.0.0
)
```

Run `go mod tidy` to download dependencies:

```bash
go mod tidy
```

## Next Steps

- Learn [Basic Usage](../basic-usage/) to start logging
- Explore [Configuration](../configuration/) options
- See [Examples](../examples/) for real-world patterns

For complete API details, see the [API Reference](/reference/packages/logging/api-reference/).
