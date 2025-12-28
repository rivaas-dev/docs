---
title: "Installation"
description: "Install and set up the Rivaas config package for your Go application"
weight: 2
---

Get started with the Rivaas config package by installing it in your Go project.

## Prerequisites

- **Go 1.25 or higher** - The config package requires Go 1.25+
- Basic familiarity with Go modules

## Installation

Install the config package using `go get`:

```bash
go get rivaas.dev/config
```

This will add the package to your `go.mod` file and download the dependencies.

## Verify Installation

Create a simple test to verify the installation is working:

```go
package main

import (
    "context"
    "fmt"
    "rivaas.dev/config"
)

func main() {
    cfg := config.MustNew()
    if err := cfg.Load(context.Background()); err != nil {
        panic(err)
    }
    fmt.Println("Config package installed successfully!")
}
```

Save this as `main.go` and run:

```bash
go run main.go
```

If you see "Config package installed successfully!", the installation is complete!

## Import Path

Always import the config package using:

```go
import "rivaas.dev/config"
```

## Additional Packages

Depending on your use case, you may also want to import sub-packages:

```go
import (
    "rivaas.dev/config"
    "rivaas.dev/config/codec"   // For custom codecs
    "rivaas.dev/config/dumper"  // For custom dumpers
    "rivaas.dev/config/source"  // For custom sources
)
```

## Common Issues

### Go Version Too Old

If you get an error about Go version:

```
go: rivaas.dev/config requires go >= 1.25
```

Update your Go installation to version 1.25 or higher:

```bash
go version  # Check current version
```

Visit [golang.org/dl/](https://golang.org/dl/) to download the latest version.

### Module Not Found

If you get a "module not found" error:

```
go: rivaas.dev/config: module rivaas.dev/config: Get "https://rivaas.dev/config": dial tcp: lookup rivaas.dev
```

Make sure you have network connectivity and try:

```bash
go clean -modcache
go get rivaas.dev/config
```

### Dependency Conflicts

If you experience dependency conflicts, ensure your `go.mod` is up to date:

```bash
go mod tidy
```

## Next Steps

Now that you have the config package installed:

- Learn [Basic Usage](../basic-usage/) to load and access configuration
- Explore [configuration sources](../multiple-sources/) for different environments
- See [real-world examples](../examples/) for practical usage patterns

For complete API documentation, visit the [API Reference](/reference/packages/config/).
