---
title: "OpenAPI Package"
linkTitle: "OpenAPI"
description: "API reference for rivaas.dev/openapi - Automatic OpenAPI specification generation"
weight: 3
sidebar_root_for: self
---

{{% pageinfo %}}
This is the API reference for the `rivaas.dev/openapi` package. For learning-focused documentation, see the [OpenAPI Guide](/guides/openapi/).
{{% /pageinfo %}}

## Package Information

- **Import Path:** `rivaas.dev/openapi`
- **Go Version:** 1.25+
- **Documentation:** [pkg.go.dev/rivaas.dev/openapi](https://pkg.go.dev/rivaas.dev/openapi)
- **Source Code:** [GitHub](https://github.com/rivaas-dev/rivaas/tree/main/openapi)

## Package Overview

The openapi package provides automatic OpenAPI 3.0.4 and 3.1.2 specification generation from Go code using struct tags and reflection.

### Core Features

- Automatic OpenAPI specification generation from Go code
- Support for OpenAPI 3.0.4 and 3.1.2 specifications
- Type-safe version selection with `V30x` and `V31x` constants
- Fluent HTTP method constructors (GET, POST, PUT, etc.)
- Automatic parameter discovery from struct tags
- Schema generation from Go types
- Built-in validation against official meta-schemas
- Type-safe warning diagnostics via `diag` package
- Swagger UI configuration support

## Architecture

The package is organized into two main components:

### Main Package (`rivaas.dev/openapi`)

Core specification generation including:
- `API` struct - Configuration container
- `New()` / `MustNew()` - API initialization
- HTTP method constructors - `GET()`, `POST()`, `PUT()`, etc.
- Operation options - `WithRequest()`, `WithResponse()`, `WithSecurity()`, etc.
- `Generate()` - Specification generation

### Sub-package (`rivaas.dev/openapi/diag`)

Type-safe warning diagnostics:
- `Warning` interface - Individual warning
- `Warnings` type - Warning collection
- `WarningCode` type - Type-safe warning codes
- `WarningCategory` type - Warning categories

### Validator (`rivaas.dev/openapi/validate`)

Standalone specification validator:
- `Validator` type - Validates OpenAPI specifications
- `Validate()` - Validate against specific version
- `ValidateAuto()` - Auto-detect version and validate

## Quick API Index

### API Creation

```go
api, err := openapi.New(options...)     // With error handling
api := openapi.MustNew(options...)      // Panics on error
```

### Specification Generation

```go
result, err := api.Generate(ctx context.Context, operations...)
```

### HTTP Method Constructors

```go
openapi.GET(path, ...opts) Operation
openapi.POST(path, ...opts) Operation
openapi.PUT(path, ...opts) Operation
openapi.PATCH(path, ...opts) Operation
openapi.DELETE(path, ...opts) Operation
openapi.HEAD(path, ...opts) Operation
openapi.OPTIONS(path, ...opts) Operation
openapi.TRACE(path, ...opts) Operation
```

### Result Access

```go
result.JSON      // OpenAPI spec as JSON bytes
result.YAML      // OpenAPI spec as YAML bytes
result.Warnings  // Generation warnings
```

## Reference Pages

{{% cardpane %}}
{{% card header="**API Reference**" %}}
Core types, HTTP method constructors, and generation API.

[View →](api-reference/)
{{% /card %}}
{{% card header="**Options**" %}}
API-level configuration for info, servers, and security.

[View →](options/)
{{% /card %}}
{{% card header="**Operation Options**" %}}
Operation-level configuration for endpoints.

[View →](operation-options/)
{{% /card %}}
{{% /cardpane %}}

{{% cardpane %}}
{{% card header="**Swagger UI Options**" %}}
Customize the Swagger UI interface.

[View →](swagger-ui-options/)
{{% /card %}}
{{% card header="**Diagnostics**" %}}
Warning system and diagnostic codes.

[View →](diagnostics/)
{{% /card %}}
{{% card header="**Troubleshooting**" %}}
Common issues and solutions.

[View →](troubleshooting/)
{{% /card %}}
{{% /cardpane %}}

{{% cardpane %}}
{{% card header="**User Guide**" %}}
Step-by-step tutorials and examples.

[View →](/guides/openapi/)
{{% /card %}}
{{% /cardpane %}}

## Type Reference

### API

```go
type API struct {
    // contains filtered or unexported fields
}
```

Main API configuration container. Created via `New()` or `MustNew()` with functional options.

### Operation

```go
type Operation struct {
    // contains filtered or unexported fields
}
```

Represents an HTTP operation with method, path, and metadata. Created via HTTP method constructors.

### Result

```go
type Result struct {
    JSON     []byte    // OpenAPI spec as JSON
    YAML     []byte    // OpenAPI spec as YAML
    Warnings Warnings  // Generation warnings
}
```

Result of specification generation containing the spec in multiple formats and any warnings.

### Version

```go
type Version int

const (
    V30x Version = iota  // OpenAPI 3.0.x (generates 3.0.4)
    V31x                 // OpenAPI 3.1.x (generates 3.1.2)
)
```

Type-safe OpenAPI version selection.

### Option

```go
type Option func(*API) error
```

Functional option for API configuration.

### OperationOption

```go
type OperationOption func(*Operation) error
```

Functional option for operation configuration.

## Common Patterns

### Basic Generation

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
)

result, err := api.Generate(context.Background(),
    openapi.GET("/users/:id",
        openapi.WithSummary("Get user"),
        openapi.WithResponse(200, User{}),
    ),
)
```

### With Security

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
)

result, err := api.Generate(context.Background(),
    openapi.GET("/users/:id",
        openapi.WithSecurity("bearerAuth"),
        openapi.WithResponse(200, User{}),
    ),
)
```

### With Validation

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithValidation(true),
)

result, err := api.Generate(context.Background(), operations...)
// Fails if spec is invalid
```

### With Diagnostics

```go
import "rivaas.dev/openapi/diag"

result, err := api.Generate(context.Background(), operations...)
if err != nil {
    log.Fatal(err)
}

if result.Warnings.Has(diag.WarnDownlevelInfoSummary) {
    log.Warn("info.summary was dropped")
}
```

## Thread Safety

The `API` type is safe for concurrent use:
- Multiple goroutines can call `Generate()` simultaneously
- Configuration is immutable after creation

Not thread-safe:
- Modifying API configuration during initialization

## Performance Notes

- **Schema generation**: First use per type ~500ns (reflection), subsequent uses ~50ns (cached)
- **Validation**: Adds 10-20ms on first validation (schema compilation), 1-5ms subsequent
- **Generation**: Depends on operation count and complexity

## Version Compatibility

The package follows semantic versioning. The API is stable for the v1 series.

**Minimum Go version:** 1.25

## Next Steps

- Read the [API Reference](api-reference/) for detailed method documentation
- Explore [Options](options/) for all available configuration options
- Check [Diagnostics](diagnostics/) for warning handling
- Review [Troubleshooting](troubleshooting/) for common issues

For learning-focused guides, see the [OpenAPI Guide](/guides/openapi/).
