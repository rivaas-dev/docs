---
title: "Diagnostics"
description: "Warning system reference with codes and categories"
weight: 5
---

Complete reference for the warning diagnostics system in `rivaas.dev/openapi/diag`.

## Package Import

```go
import "rivaas.dev/openapi/diag"
```

## Warning Interface

```go
type Warning interface {
    Code() WarningCode
    Message() string
    Path() string
    Category() WarningCategory
}
```

Individual warning with diagnostic information.

**Methods:**
- `Code()` - Returns type-safe warning code
- `Message()` - Returns human-readable message
- `Path()` - Returns location in spec (e.g., "info.summary")
- `Category()` - Returns warning category

## Warnings Collection

```go
type Warnings []Warning
```

Collection of warnings with helper methods.

### Has

```go
func (w Warnings) Has(code WarningCode) bool
```

Checks if collection contains a specific warning code.

**Example:**

```go
if result.Warnings.Has(diag.WarnDownlevelInfoSummary) {
    log.Warn("info.summary was dropped")
}
```

### HasAny

```go
func (w Warnings) HasAny(codes ...WarningCode) bool
```

Checks if collection contains any of the specified warning codes.

**Example:**

```go
if result.Warnings.HasAny(
    diag.WarnDownlevelMutualTLS,
    diag.WarnDownlevelWebhooks,
) {
    log.Warn("Some 3.1 security features were dropped")
}
```

### Filter

```go
func (w Warnings) Filter(code WarningCode) Warnings
```

Returns warnings matching the specified code.

**Example:**

```go
licenseWarnings := result.Warnings.Filter(diag.WarnDownlevelLicenseIdentifier)
```

### FilterCategory

```go
func (w Warnings) FilterCategory(category WarningCategory) Warnings
```

Returns warnings in the specified category.

**Example:**

```go
downlevelWarnings := result.Warnings.FilterCategory(diag.CategoryDownlevel)
```

### Exclude

```go
func (w Warnings) Exclude(codes ...WarningCode) Warnings
```

Returns warnings excluding the specified codes.

**Example:**

```go
expected := []diag.WarningCode{
    diag.WarnDownlevelInfoSummary,
}
unexpected := result.Warnings.Exclude(expected...)
```

## Warning Codes

### WarningCode Type

```go
type WarningCode string
```

Type-safe warning code constant.

### Downlevel Warning Codes

Warnings generated when using 3.1 features with a 3.0 target:

| Constant | Code Value | Description |
|----------|------------|-------------|
| `WarnDownlevelWebhooks` | `DOWNLEVEL_WEBHOOKS` | Webhooks dropped (3.0 doesn't support them) |
| `WarnDownlevelInfoSummary` | `DOWNLEVEL_INFO_SUMMARY` | `info.summary` dropped (3.0 doesn't support it) |
| `WarnDownlevelLicenseIdentifier` | `DOWNLEVEL_LICENSE_IDENTIFIER` | `license.identifier` dropped |
| `WarnDownlevelMutualTLS` | `DOWNLEVEL_MUTUAL_TLS` | `mutualTLS` security scheme dropped |
| `WarnDownlevelConstToEnum` | `DOWNLEVEL_CONST_TO_ENUM` | JSON Schema `const` converted to `enum` |
| `WarnDownlevelConstToEnumConflict` | `DOWNLEVEL_CONST_TO_ENUM_CONFLICT` | `const` conflicted with existing `enum` |
| `WarnDownlevelPathItems` | `DOWNLEVEL_PATH_ITEMS` | `$ref` in pathItems was expanded |
| `WarnDownlevelPatternProperties` | `DOWNLEVEL_PATTERN_PROPERTIES` | `patternProperties` dropped |
| `WarnDownlevelUnevaluatedProperties` | `DOWNLEVEL_UNEVALUATED_PROPERTIES` | `unevaluatedProperties` dropped |
| `WarnDownlevelContentEncoding` | `DOWNLEVEL_CONTENT_ENCODING` | `contentEncoding` dropped |
| `WarnDownlevelContentMediaType` | `DOWNLEVEL_CONTENT_MEDIA_TYPE` | `contentMediaType` dropped |
| `WarnDownlevelMultipleExamples` | `DOWNLEVEL_MULTIPLE_EXAMPLES` | Multiple examples collapsed to one |

```go
const (
    WarnDownlevelWebhooks              WarningCode = "DOWNLEVEL_WEBHOOKS"
    WarnDownlevelInfoSummary           WarningCode = "DOWNLEVEL_INFO_SUMMARY"
    WarnDownlevelLicenseIdentifier     WarningCode = "DOWNLEVEL_LICENSE_IDENTIFIER"
    WarnDownlevelMutualTLS             WarningCode = "DOWNLEVEL_MUTUAL_TLS"
    WarnDownlevelConstToEnum           WarningCode = "DOWNLEVEL_CONST_TO_ENUM"
    WarnDownlevelConstToEnumConflict   WarningCode = "DOWNLEVEL_CONST_TO_ENUM_CONFLICT"
    WarnDownlevelPathItems             WarningCode = "DOWNLEVEL_PATH_ITEMS"
    WarnDownlevelPatternProperties     WarningCode = "DOWNLEVEL_PATTERN_PROPERTIES"
    WarnDownlevelUnevaluatedProperties WarningCode = "DOWNLEVEL_UNEVALUATED_PROPERTIES"
    WarnDownlevelContentEncoding       WarningCode = "DOWNLEVEL_CONTENT_ENCODING"
    WarnDownlevelContentMediaType      WarningCode = "DOWNLEVEL_CONTENT_MEDIA_TYPE"
    WarnDownlevelMultipleExamples      WarningCode = "DOWNLEVEL_MULTIPLE_EXAMPLES"
)
```

### Deprecation Warning Codes

Warnings for deprecated feature usage:

| Constant | Code Value | Description |
|----------|------------|-------------|
| `WarnDeprecationExampleSingular` | `DEPRECATION_EXAMPLE_SINGULAR` | Using deprecated singular `example` field |

```go
const (
    WarnDeprecationExampleSingular WarningCode = "DEPRECATION_EXAMPLE_SINGULAR"
)
```

## Warning Categories

### WarningCategory Type

```go
type WarningCategory string
```

Category grouping for warnings.

### Category Constants

| Category | Description |
|----------|-------------|
| `CategoryDownlevel` | 3.1 to 3.0 conversion feature losses (spec is still valid) |
| `CategoryDeprecation` | Deprecated feature usage (feature still works but is discouraged) |
| `CategoryUnknown` | Unrecognized warning codes |

```go
const (
    CategoryDownlevel   WarningCategory = "downlevel"
    CategoryDeprecation WarningCategory = "deprecation"
    CategoryUnknown     WarningCategory = "unknown"
)
```

## Usage Examples

### Check for Specific Warning

```go
import "rivaas.dev/openapi/diag"

result, err := api.Generate(context.Background(), ops...)
if err != nil {
    log.Fatal(err)
}

if result.Warnings.Has(diag.WarnDownlevelInfoSummary) {
    log.Warn("info.summary was dropped (3.1 feature with 3.0 target)")
}
```

### Filter by Category

```go
downlevelWarnings := result.Warnings.FilterCategory(diag.CategoryDownlevel)
if len(downlevelWarnings) > 0 {
    fmt.Printf("Downlevel warnings: %d\n", len(downlevelWarnings))
    for _, warn := range downlevelWarnings {
        fmt.Printf("  [%s] %s at %s\n", 
            warn.Code(), 
            warn.Message(), 
            warn.Path(),
        )
    }
}
```

### Check for Unexpected Warnings

```go
expected := []diag.WarningCode{
    diag.WarnDownlevelInfoSummary,
    diag.WarnDownlevelLicenseIdentifier,
}

unexpected := result.Warnings.Exclude(expected...)
if len(unexpected) > 0 {
    log.Fatalf("Unexpected warnings: %d", len(unexpected))
}
```

### Iterate All Warnings

```go
for _, warn := range result.Warnings {
    fmt.Printf("[%s] %s\n", warn.Code(), warn.Message())
    fmt.Printf("  Location: %s\n", warn.Path())
    fmt.Printf("  Category: %s\n", warn.Category())
}
```

## Complete Example

```go
package main

import (
    "context"
    "fmt"
    "log"
    
    "rivaas.dev/openapi"
    "rivaas.dev/openapi/diag"
)

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("My API", "1.0.0"),
        openapi.WithVersion(openapi.V30x),
        openapi.WithInfoSummary("API Summary"), // 3.1 feature
    )
    
    result, err := api.Generate(context.Background(), operations...)
    if err != nil {
        log.Fatal(err)
    }
    
    // Handle specific warnings
    if result.Warnings.Has(diag.WarnDownlevelInfoSummary) {
        fmt.Println("Note: info.summary was dropped")
    }
    
    // Filter by category
    downlevelWarnings := result.Warnings.FilterCategory(diag.CategoryDownlevel)
    fmt.Printf("Downlevel warnings: %d\n", len(downlevelWarnings))
    
    // Check for unexpected
    expected := []diag.WarningCode{
        diag.WarnDownlevelInfoSummary,
    }
    unexpected := result.Warnings.Exclude(expected...)
    
    if len(unexpected) > 0 {
        fmt.Printf("UNEXPECTED warnings: %d\n", len(unexpected))
        for _, warn := range unexpected {
            fmt.Printf("  [%s] %s\n", warn.Code(), warn.Message())
        }
        log.Fatal("Unexpected warnings found")
    }
    
    fmt.Println("Generation complete")
}
```

## Next Steps

- See [Diagnostics Guide](/guides/openapi/diagnostics/) for detailed usage
- Check [Validation Guide](/guides/openapi/validation/) for validation
- Review [Troubleshooting](troubleshooting/) for common issues
