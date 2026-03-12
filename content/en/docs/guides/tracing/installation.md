---
title: "Installation"
description: "Install and set up the tracing package"
weight: 1
keywords:
  - tracing installation
  - install
  - go get
  - setup
---

Get started with the Rivaas tracing package by installing it in your Go project.

## Requirements

- **Go 1.25 or higher** - The tracing package uses modern Go features
- **OpenTelemetry dependencies** - Automatically installed via `go get`

## Install the Package

Add the tracing package to your Go module:

```bash
go get rivaas.dev/tracing
```

This will download the package and its OpenTelemetry dependencies.

## Verify Installation

Create a simple test file to verify the installation:

```go
package main

import (
    "context"
    "log"
    
    "rivaas.dev/tracing"
)

func main() {
    tracer, err := tracing.New(
        tracing.WithServiceName("test-service"),
        tracing.WithStdout(),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer tracer.Shutdown(context.Background())
    
    log.Println("Tracing initialized successfully!")
}
```

Run the test:

```bash
go run main.go
```

You should see a success message with no errors.

## Dependencies

The tracing package depends on:

- `go.opentelemetry.io/otel` - OpenTelemetry API
- `go.opentelemetry.io/otel/sdk` - OpenTelemetry SDK
- `go.opentelemetry.io/otel/exporters/stdout/stdouttrace` - Stdout exporter
- `go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc` - OTLP gRPC exporter
- `go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp` - OTLP HTTP exporter

These are automatically installed when you run `go get rivaas.dev/tracing`.

## Module Setup

If you're starting a new project, initialize a Go module first:

```bash
mkdir my-traced-app
cd my-traced-app
go mod init example.com/my-traced-app
go get rivaas.dev/tracing
```

## Next Steps

Now that you have the package installed:

- Learn [Basic Usage](../basic-usage/) to create your first tracer
- Explore [Providers](../providers/) to choose the right exporter
- Set up [Middleware](../middleware/) for automatic HTTP tracing
