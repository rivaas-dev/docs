---
title: "Installation"
description: "Install and set up the validation package"
weight: 1
keywords:
  - validation installation
  - install
  - go get
  - setup
---

Get started with the Rivaas validation package by installing it in your Go project.

## Requirements

- **Go 1.25 or later**
- A Go module-enabled project (with `go.mod`)

## Installation

Install the validation package using `go get`:

```bash
go get rivaas.dev/validation
```

This will add the package to your `go.mod` file and download all necessary dependencies.

## Dependencies

The validation package depends on:

- **[go-playground/validator](https://github.com/go-playground/validator)** - For struct tag validation
- **Standard library** - For JSON Schema validation

All dependencies are managed automatically by Go modules.

## Verify Installation

Create a simple test file to verify the installation:

```go
package main

import (
    "context"
    "fmt"
    "rivaas.dev/validation"
)

type User struct {
    Email string `validate:"required,email"`
    Age   int    `validate:"min=18"`
}

func main() {
    ctx := context.Background()
    user := User{Email: "test@example.com", Age: 25}
    
    if err := validation.Validate(ctx, &user); err != nil {
        fmt.Println("Validation failed:", err)
        return
    }
    
    fmt.Println("Validation passed!")
}
```

Run the test:

```bash
go run main.go
# Output: Validation passed!
```

## Import Paths

The validation package uses a simple import path:

```go
import "rivaas.dev/validation"
```

There are no sub-packages to import - all functionality is in the main package.

## Version Management

The validation package follows semantic versioning. To use a specific version:

```bash
# Install latest version
go get rivaas.dev/validation@latest

# Install specific version
go get rivaas.dev/validation@v1.2.3

# Install specific commit
go get rivaas.dev/validation@abc123
```

## Upgrading

To upgrade to the latest version:

```bash
go get -u rivaas.dev/validation
```

To upgrade all dependencies:

```bash
go get -u ./...
```

## Workspace Setup

If using Go workspaces, ensure the validation module is in your workspace:

```bash
# Add to workspace
go work use /path/to/rivaas/validation

# Verify workspace
go work sync
```

## Next Steps

Now that the package is installed, learn how to use it:

- [**Basic Usage**](../basic-usage/) - Start validating structs
- [**Struct Tags**](../struct-tags/) - Learn go-playground/validator syntax
- [**API Reference**](/reference/packages/validation/) - Explore all functions and types

## Troubleshooting

### Cannot find module

If you see:

```
go: finding module for package rivaas.dev/validation
```

Ensure you have a valid `go.mod` file and run:

```bash
go mod tidy
```

### Version conflicts

If you encounter version conflicts with dependencies:

```bash
# Update go.mod
go mod tidy

# Verify dependencies
go mod verify
```

### Build errors

If you encounter build errors after installation:

```bash
# Clean module cache
go clean -modcache

# Re-download dependencies
go mod download
```

For more help, see the [Troubleshooting](/reference/packages/validation/troubleshooting/) reference.
