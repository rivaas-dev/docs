---
title: "Diagnostics"
description: "Handle warnings with type-safe diagnostics"
weight: 10
keywords:
  - openapi diagnostics
  - debugging
  - troubleshooting
  - warnings
---

Learn how to work with warnings using the type-safe diagnostics package.

## Overview

The package generates warnings when using version-specific features. For example, using OpenAPI 3.1 features with a 3.0 target generates warnings instead of errors.

## Working with Warnings

Check for warnings in the generation result:

```go
result, err := api.Generate(context.Background(), operations...)
if err != nil {
    log.Fatal(err)
}

// Basic warning check
if len(result.Warnings) > 0 {
    fmt.Printf("Generated with %d warnings\n", len(result.Warnings))
}

// Iterate through warnings
for _, warn := range result.Warnings {
    fmt.Printf("[%s] %s\n", warn.Code(), warn.Message())
}
```

## The diag Package

Import the `diag` package for type-safe warning handling:

```go
import "rivaas.dev/openapi/diag"
```

### Warning Interface

Each warning implements the `Warning` interface:

```go
type Warning interface {
    Code() WarningCode        // Unique warning code
    Message() string          // Human-readable message
    Path() string            // Location in spec (e.g., "info.summary")
    Category() WarningCategory // Warning category
}
```

### Type-Safe Warning Checks

Check for specific warnings using type-safe constants:

```go
import "rivaas.dev/openapi/diag"

result, err := api.Generate(context.Background(), ops...)
if err != nil {
    log.Fatal(err)
}

// Check for specific warning
if result.Warnings.Has(diag.WarnDownlevelWebhooks) {
    log.Warn("webhooks not supported in OpenAPI 3.0")
}

// Check for any of multiple codes
if result.Warnings.HasAny(
    diag.WarnDownlevelMutualTLS,
    diag.WarnDownlevelWebhooks,
) {
    log.Warn("Some 3.1 security features were dropped")
}
```

## Warning Categories

Warnings are organized into categories:

```go
// Filter by category
downlevelWarnings := result.Warnings.FilterCategory(diag.CategoryDownlevel)
fmt.Printf("Downlevel warnings: %d\n", len(downlevelWarnings))

deprecationWarnings := result.Warnings.FilterCategory(diag.CategoryDeprecation)
fmt.Printf("Deprecation warnings: %d\n", len(deprecationWarnings))
```

Available categories:
- `CategoryDownlevel` - 3.1 to 3.0 conversion feature losses
- `CategoryDeprecation` - Deprecated feature usage warnings
- `CategoryUnknown` - Unrecognized warning codes

## Warning Codes

Common warning codes:

### Downlevel Warnings

These occur when using 3.1 features with a 3.0 target:

- `WarnDownlevelWebhooks` - Webhooks dropped
- `WarnDownlevelInfoSummary` - `info.summary` dropped
- `WarnDownlevelLicenseIdentifier` - `license.identifier` dropped
- `WarnDownlevelMutualTLS` - `mutualTLS` security scheme dropped
- `WarnDownlevelConstToEnum` - JSON Schema `const` converted to `enum`
- `WarnDownlevelMultipleExamples` - Multiple examples collapsed to one
- `WarnDownlevelPatternProperties` - `patternProperties` dropped
- `WarnDownlevelUnevaluatedProperties` - `unevaluatedProperties` dropped
- `WarnDownlevelContentEncoding` - `contentEncoding` dropped
- `WarnDownlevelContentMediaType` - `contentMediaType` dropped

### Deprecation Warnings

These occur when using deprecated features:

- `WarnDeprecationExampleSingular` - Using deprecated singular `example` field

## Filtering Warnings

### Filter Specific Warnings

Get only specific warning types:

```go
licenseWarnings := result.Warnings.Filter(diag.WarnDownlevelLicenseIdentifier)
for _, warn := range licenseWarnings {
    fmt.Printf("%s: %s\n", warn.Path(), warn.Message())
}
```

### Exclude Expected Warnings

Exclude warnings you expect and want to ignore:

```go
unexpected := result.Warnings.Exclude(
    diag.WarnDownlevelInfoSummary,
    diag.WarnDownlevelLicenseIdentifier,
)

if len(unexpected) > 0 {
    fmt.Printf("Unexpected warnings: %d\n", len(unexpected))
    for _, warn := range unexpected {
        fmt.Printf("[%s] %s\n", warn.Code(), warn.Message())
    }
}
```

## Complete Diagnostics Example

```go
package main

import (
    "context"
    "fmt"
    "log"
    
    "rivaas.dev/openapi"
    "rivaas.dev/openapi/diag"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

func main() {
    // Create API with 3.0 target but use 3.1 features
    api := openapi.MustNew(
        openapi.WithTitle("My API", "1.0.0"),
        openapi.WithVersion(openapi.V30x),
        openapi.WithInfoSummary("Short summary"), // 3.1-only feature
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
    
    // Check for specific warning
    if result.Warnings.Has(diag.WarnDownlevelInfoSummary) {
        fmt.Println("info.summary was dropped (3.1 feature with 3.0 target)")
    }
    
    // Filter by category
    downlevelWarnings := result.Warnings.FilterCategory(diag.CategoryDownlevel)
    if len(downlevelWarnings) > 0 {
        fmt.Printf("\nDownlevel warnings (%d):\n", len(downlevelWarnings))
        for _, warn := range downlevelWarnings {
            fmt.Printf("  [%s] %s at %s\n", 
                warn.Code(), 
                warn.Message(), 
                warn.Path(),
            )
        }
    }
    
    // Check for unexpected warnings
    expected := []diag.WarningCode{
        diag.WarnDownlevelInfoSummary,
    }
    unexpected := result.Warnings.Exclude(expected...)
    
    if len(unexpected) > 0 {
        fmt.Printf("\nUnexpected warnings (%d):\n", len(unexpected))
        for _, warn := range unexpected {
            fmt.Printf("  [%s] %s\n", warn.Code(), warn.Message())
        }
    }
    
    fmt.Printf("\nGenerated %d byte specification with %d warnings\n",
        len(result.JSON), 
        len(result.Warnings),
    )
}
```

## Warning vs Error

The package distinguishes between warnings and errors:

- **Warnings**: The specification is valid but features were dropped or converted
- **Errors**: The specification is invalid or generation failed

```go
result, err := api.Generate(context.Background(), ops...)
if err != nil {
    // Hard error - generation failed
    log.Fatal(err)
}

if len(result.Warnings) > 0 {
    // Soft warnings - generation succeeded with caveats
    for _, warn := range result.Warnings {
        log.Printf("Warning: %s\n", warn.Message())
    }
}
```

## Strict Downlevel Mode

To treat downlevel warnings as errors, enable strict mode (see [Advanced Usage](../advanced-usage/)):

```go
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithVersion(openapi.V30x),
    openapi.WithStrictDownlevel(true), // Error on 3.1 features
    openapi.WithInfoSummary("Summary"), // This will cause an error
)

_, err := api.Generate(context.Background(), ops...)
// err will be non-nil due to strict mode violation
```

## Warning Suppression

Currently, the package does not support per-warning suppression. To handle expected warnings:

1. **Filter them out** after generation
2. **Use strict mode** to error on any warnings
3. **Log and ignore** specific warning codes

```go
// Filter out expected warnings
expected := []diag.WarningCode{
    diag.WarnDownlevelInfoSummary,
    diag.WarnDownlevelLicenseIdentifier,
}

unexpected := result.Warnings.Exclude(expected...)
if len(unexpected) > 0 {
    log.Fatalf("Unexpected warnings: %d", len(unexpected))
}
```

## Next Steps

- Learn about [Advanced Usage](../advanced-usage/) for strict mode
- Explore [Validation](../validation/) for specification validation
- See [Examples](../examples/) for complete patterns
