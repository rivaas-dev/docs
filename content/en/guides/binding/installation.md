---
title: "Installation"
description: "Install and set up the Rivaas binding package for your Go application"
weight: 2
keywords:
  - binding installation
  - install
  - go get
  - setup
---

Get started with the Rivaas binding package by installing it in your Go project.

## Prerequisites

- **Go 1.25 or higher** - The binding package requires Go 1.25+
- Basic familiarity with Go generics

## Installation

Install the binding package using `go get`:

```bash
go get rivaas.dev/binding
```

This will add the package to your `go.mod` file and download the dependencies.

## Sub-Packages

The binding package includes optional sub-packages for additional format support:

### YAML

```bash
go get rivaas.dev/binding/yaml
```

### TOML

```bash
go get rivaas.dev/binding/toml
```

### MessagePack

```bash
go get rivaas.dev/binding/msgpack
```

### Protocol Buffers

```bash
go get rivaas.dev/binding/proto
```

## Verify Installation

Create a simple test to verify the installation is working:

```go
package main

import (
    "fmt"
    "net/url"
    "rivaas.dev/binding"
)

type TestParams struct {
    Name string `query:"name"`
    Age  int    `query:"age"`
}

func main() {
    values := url.Values{
        "name": []string{"Alice"},
        "age":  []string{"30"},
    }
    
    params, err := binding.Query[TestParams](values)
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("Binding package installed successfully!\n")
    fmt.Printf("Name: %s, Age: %d\n", params.Name, params.Age)
}
```

Save this as `main.go` and run:

```bash
go run main.go
```

If you see the success message with parsed values, the installation is complete!

## Import Paths

Always import the binding package using:

```go
import "rivaas.dev/binding"
```

For sub-packages:

```go
import (
    "rivaas.dev/binding"
    "rivaas.dev/binding/yaml"
    "rivaas.dev/binding/toml"
)
```

## Common Issues

### Go Version Too Old

If you get an error about Go version:

```
go: rivaas.dev/binding requires go >= 1.25
```

Update your Go installation to version 1.25 or higher:

```bash
go version  # Check current version
```

Visit [golang.org/dl/](https://golang.org/dl/) to download the latest version.

### Module Not Found

If you get a "module not found" error:

```bash
go clean -modcache
go get rivaas.dev/binding
```

### Dependency Conflicts

If you experience dependency conflicts, ensure your `go.mod` is up to date:

```bash
go mod tidy
```

## Next Steps

Now that you have the binding package installed:

- Learn [Basic Usage](../basic-usage/) to bind your first request data
- Explore [Query Parameters](../query-parameters/) for URL query string binding
- See [JSON Binding](../json-binding/) for request body handling

For complete API documentation, visit the [API Reference](/reference/packages/binding/).
