---
title: "Validation"
description: "Validate OpenAPI specifications against official meta-schemas"
weight: 9
keywords:
  - openapi validation
  - request validation
  - schema validation
  - spec validation
---

Learn how to validate OpenAPI specifications using built-in validation against official meta-schemas.

## Overview

The package provides built-in validation against official OpenAPI meta-schemas for both 3.0.x and 3.1.x specifications.

## Enabling Validation

Validation is disabled by default for performance. Enable it during development or in CI/CD pipelines:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithValidation(true), // Enable validation
)

result, err := api.Generate(context.Background(), operations...)
if err != nil {
    log.Fatal(err) // Will fail if spec is invalid
}
```

## Why Validation is Disabled by Default

Validation has a performance cost:
- Schema compilation on first use.
- JSON schema validation for every generation.
- Not necessary for production spec generation.

**When to enable:**
- During development.
- In CI/CD pipelines.
- When debugging specification issues.
- When accepting external specifications.

**When to disable:**
- Production spec generation.
- When performance is critical.
- After spec validation is confirmed.

## Validation Errors

When validation fails, you'll receive a detailed error:

```go
result, err := api.Generate(context.Background(), operations...)
if err != nil {
    // Error contains validation details
    fmt.Printf("Validation failed: %v\n", err)
}
```

Common validation errors:
- Missing required fields like `info`, `openapi`, `paths`.
- Invalid field types.
- Invalid format values.
- Schema constraint violations.
- Invalid references.

## Validating External Specifications

The package includes a standalone validator for external OpenAPI specifications:

```go
import "rivaas.dev/openapi/validate"

// Read external spec
specJSON, err := os.ReadFile("external-api.json")
if err != nil {
    log.Fatal(err)
}

// Create validator
validator := validate.New()

// Validate against OpenAPI 3.0.x
err = validator.Validate(context.Background(), specJSON, validate.V30)
if err != nil {
    log.Printf("Validation failed: %v\n", err)
}

// Or validate against OpenAPI 3.1.x
err = validator.Validate(context.Background(), specJSON, validate.V31)
if err != nil {
    log.Printf("Validation failed: %v\n", err)
}
```

### Auto-Detection

The validator can auto-detect the OpenAPI version:

```go
validator := validate.New()

// Auto-detects version from the spec
err := validator.ValidateAuto(context.Background(), specJSON)
if err != nil {
    log.Printf("Validation failed: %v\n", err)
}
```

## Swagger UI Validation

Configure validation in Swagger UI:

### Local Validation (Recommended)

Use the built-in validator (no external calls):

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithSwaggerUI("/docs",
        openapi.WithUIValidator(openapi.ValidatorLocal),
    ),
)
```

### External Validator

Use an external validation service:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithSwaggerUI("/docs",
        openapi.WithUIValidator("https://validator.swagger.io/validator"),
    ),
)
```

### Disable Validation

Disable validation in Swagger UI:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithSwaggerUI("/docs",
        openapi.WithUIValidator(openapi.ValidatorNone),
    ),
)
```

## Validation in CI/CD

Add validation to your CI/CD pipeline:

```bash
# generate-openapi.go
package main

import (
    "context"
    "log"
    "os"
    
    "rivaas.dev/openapi"
)

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("My API", "1.0.0"),
        openapi.WithValidation(true), // Enable for CI/CD
    )
    
    result, err := api.Generate(context.Background(),
        // ... operations
    )
    if err != nil {
        log.Fatalf("Validation failed: %v", err)
    }
    
    // Write to file
    if err := os.WriteFile("openapi.json", result.JSON, 0644); err != nil {
        log.Fatal(err)
    }
    
    log.Println("Valid OpenAPI specification generated")
}
```

In your CI pipeline:

```yaml
# .github/workflows/validate-openapi.yml
name: Validate OpenAPI

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.25'
      - run: go run generate-openapi.go
```

## Validation Performance

Validation performance characteristics:

- **First validation**: ~10-20ms (schema compilation)
- **Subsequent validations**: ~1-5ms (using cached schema)
- **External spec validation**: Depends on spec size

For high-performance scenarios, consider:
- Validate once during build/deployment
- Cache validated specifications
- Disable validation in production spec generation

## Complete Validation Example

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    
    "rivaas.dev/openapi"
    "rivaas.dev/openapi/validate"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

func main() {
    // Generate with validation enabled
    api := openapi.MustNew(
        openapi.WithTitle("User API", "1.0.0"),
        openapi.WithValidation(true),
    )
    
    result, err := api.Generate(context.Background(),
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithResponse(200, User{}),
        ),
    )
    if err != nil {
        log.Fatalf("Generation/validation failed: %v", err)
    }
    
    fmt.Println("Generated valid OpenAPI 3.0.4 specification")
    
    // Write to file
    if err := os.WriteFile("openapi.json", result.JSON, 0644); err != nil {
        log.Fatal(err)
    }
    
    // Validate external spec (e.g., from a file)
    externalSpec, err := os.ReadFile("external-api.json")
    if err != nil {
        log.Fatal(err)
    }
    
    validator := validate.New()
    if err := validator.ValidateAuto(context.Background(), externalSpec); err != nil {
        log.Printf("External spec validation failed: %v\n", err)
    } else {
        fmt.Println("External spec is valid")
    }
}
```

## Validation vs Warnings

It's important to distinguish between validation errors and warnings:

- **Validation errors**: The specification violates OpenAPI schema requirements
- **Warnings**: The specification is valid but uses version-specific features (see [Diagnostics](../diagnostics/))

```go
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithVersion(openapi.V30x),
    openapi.WithInfoSummary("Summary"), // 3.1-only feature
    openapi.WithValidation(true),
)

result, err := api.Generate(context.Background(), ops...)
// err is nil (spec is valid)
// result.Warnings contains warning about info.summary being dropped
```

## Next Steps

- Learn about [Diagnostics](../diagnostics/) for handling warnings
- Explore [Advanced Usage](../advanced-usage/) for strict mode
- See [Examples](../examples/) for complete patterns
