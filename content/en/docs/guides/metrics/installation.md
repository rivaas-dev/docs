---
title: "Installation"
description: "How to install and set up the Rivaas metrics package"
weight: 1
keywords:
  - metrics installation
  - install
  - go get
  - setup
---

This guide covers installing the metrics package and verifying your setup.

## Requirements

- **Go 1.25 or later**
- OpenTelemetry dependencies (automatically installed)

## Installation

Install the metrics package using `go get`:

```bash
go get rivaas.dev/metrics
```

The package will automatically install its dependencies, including:

- `go.opentelemetry.io/otel` - OpenTelemetry SDK
- `go.opentelemetry.io/otel/exporters/prometheus` - Prometheus exporter
- `go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp` - OTLP exporter
- `go.opentelemetry.io/otel/exporters/stdout/stdoutmetric` - Stdout exporter

## Verify Installation

Create a simple test file to verify the installation:

```go
package main

import (
    "context"
    "fmt"
    "log"
    
    "rivaas.dev/metrics"
)

func main() {
    // Create a basic metrics recorder
    recorder, err := metrics.New(
        metrics.WithStdout(),
        metrics.WithServiceName("test-service"),
    )
    if err != nil {
        log.Fatalf("Failed to create recorder: %v", err)
    }
    
    // Start the recorder (optional for stdout, but good practice)
    if err := recorder.Start(context.Background()); err != nil {
        log.Fatalf("Failed to start recorder: %v", err)
    }
    defer recorder.Shutdown(context.Background())
    
    fmt.Println("Metrics package installed successfully!")
}
```

Run the test:

```bash
go run main.go
```

You should see output confirming the installation was successful.

## Import Path

Import the metrics package in your code:

```go
import "rivaas.dev/metrics"
```

## Module Setup

If you're starting a new project, initialize a Go module first:

```bash
go mod init your-project-name
go get rivaas.dev/metrics
```

## Dependency Management

The metrics package uses Go modules for dependency management. After installation, your `go.mod` file will include:

```go
require (
    rivaas.dev/metrics v0.1.0
    // OpenTelemetry dependencies added automatically
)
```

Run `go mod tidy` to clean up dependencies:

```bash
go mod tidy
```

## Version Compatibility

The metrics package follows semantic versioning:

- **Stable API**: The public API is stable and follows semantic versioning
- **Breaking Changes**: Only introduced in major version updates
- **Go Version**: Requires Go 1.25 or later

Check the [releases page](https://github.com/rivaas-dev/rivaas/releases) for the latest version.

## Next Steps

- Learn [Basic Usage](../basic-usage/) to start collecting metrics
- Explore [Providers](../providers/) to choose your metrics exporter
- See [Configuration](../configuration/) for advanced setup options

## Troubleshooting

### Import Errors

If you see import errors:

```bash
go mod tidy
go mod download
```

### Version Conflicts

If you have dependency conflicts with OpenTelemetry:

```bash
# Update to latest versions
go get -u rivaas.dev/metrics
go get -u go.opentelemetry.io/otel
go mod tidy
```

### Build Errors

Ensure you're using Go 1.25 or later:

```bash
go version
```

If you need to upgrade Go, visit [golang.org/dl](https://golang.org/dl/).
