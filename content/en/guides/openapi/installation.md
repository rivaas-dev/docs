---
title: "Installation"
description: "Install and set up the OpenAPI package for Go"
weight: 1
keywords:
  - openapi installation
  - install
  - go get
  - setup
---

Get started with the OpenAPI package by adding it to your Go project.

## Prerequisites

- **Go 1.25 or higher** - The package requires Go 1.25+
- **Go modules** - Your project should use Go modules for dependency management

## Installation

Install the package using `go get`:

```bash
go get rivaas.dev/openapi
```

This will download the latest version of the package and add it to your `go.mod` file.

## Verifying Installation

Create a simple test file to verify the installation:

```go
package main

import (
    "context"
    "fmt"
    "log"

    "rivaas.dev/openapi"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("Test API", "1.0.0"),
    )

    result, err := api.Generate(context.Background(),
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithResponse(200, User{}),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println("OpenAPI spec generated successfully!")
    fmt.Printf("JSON spec: %d bytes\n", len(result.JSON))
}
```

Run the test:

```bash
go run main.go
```

If you see "OpenAPI spec generated successfully!", the package is installed correctly.

## Sub-packages

The OpenAPI package includes two sub-packages that are automatically available when you install the main package:

### Diagnostics (`diag`)

Type-safe warning handling:

```go
import "rivaas.dev/openapi/diag"
```

### Validator (`validate`)

Standalone specification validator for validating external OpenAPI specs:

```go
import "rivaas.dev/openapi/validate"
```

## Updating

To update to the latest version:

```bash
go get -u rivaas.dev/openapi
```

## Next Steps

- Continue to [Basic Usage](../basic-usage/) to learn how to generate specifications
- Explore [Configuration](../configuration/) to customize your API settings
- Check the [API Reference](/reference/packages/openapi/) for complete documentation
