---
title: "OpenAPI Package"
linkTitle: "OpenAPI"
description: "API reference for rivaas.dev/openapi - Automatic OpenAPI specification generation"
weight: 6
no_list: true
keywords:
  - openapi api
  - openapi package
  - rivaas.dev/openapi
  - spec generation
---

{{% pageinfo %}}
This is the API reference for the `rivaas.dev/openapi` package. For learning-focused documentation, see the [OpenAPI Guide](/docs/guides/openapi/).
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
- Operation builders - `WithGET()`, `WithPOST()`, `WithPUT()`, etc.
- Operation options - `WithRequest()`, `WithResponse()`, `WithSecurity()`, etc.
- `WithOperations()` - Declarative operations at construction
- `API.AddOperation()` - Add operations after construction (returns error if invalid)
- `API.Spec(ctx)` - Specification generation

### Example sub-package (`rivaas.dev/openapi/example`)

Named examples for request/response bodies:
- `Example` type - OpenAPI Example Object
- `New(name, value, opts...)` / `NewExternal(name, url, opts...)` - Create inline or external examples
- `WithSummary()` / `WithDescription()` - Optional metadata
- Pass results to `WithRequest()` or `WithResponse()` for named examples in the spec

### Sub-package (`rivaas.dev/openapi/diag`)

Type-safe warning diagnostics:
- `Warning` interface - Individual warning
- `Warnings` type - Warning collection
- `WarningCode` type - Type-safe warning codes
- `WarningCategory` type - Warning categories

### Validator (`rivaas.dev/openapi/validate`)

Standalone specification validator:
- `Validator` type - Validates OpenAPI specifications
- `New(opts ...Option) (*Validator, error)` / `MustNew(opts ...Option) *Validator` - Create a validator (options optional; construction currently cannot fail)
- `WithVersions(versions ...Version)` - Restrict which OpenAPI versions are accepted (default: both 3.0 and 3.1)
- `Validate()` - Validate against specific version
- `ValidateAuto()` - Auto-detect version from spec and validate

## Quick API Index

### API Creation

```go
api, err := openapi.New(options...)     // With error handling
api := openapi.MustNew(options...)      // Panics on error
```

### Specification Generation

```go
if err := api.AddOperation(op1, op2); err != nil {
    log.Fatal(err)
}
result, err := api.Spec(ctx)        // or use WithOperations at construction
```

### Operation Builders

```go
openapi.WithGET(path, ...opts) (Operation, error)
openapi.WithPOST(path, ...opts) (Operation, error)
openapi.WithPUT(path, ...opts) (Operation, error)
openapi.WithPATCH(path, ...opts) (Operation, error)
openapi.WithDELETE(path, ...opts) (Operation, error)
openapi.WithHEAD(path, ...opts) (Operation, error)
openapi.WithOPTIONS(path, ...opts) (Operation, error)
openapi.WithTRACE(path, ...opts) (Operation, error)
openapi.WithOp(method, path, ...opts) (Operation, error)
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

[View →](/docs/guides/openapi/)
{{% /card %}}
{{% /cardpane %}}

## Type Reference

### API

```go
type API struct {
    // contains filtered or unexported fields
}
```

Main API configuration container. Created via `New()` or `MustNew()` with functional options. Configuration is read-only after creation; use getters such as `Info()`, `SpecPath()`, `UIPath()`, `ServeUI()`, `ValidateSpec()`, and `Version()` to read values.

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

Functional option for API configuration. Options apply to an internal config; the constructor builds the API from the validated config. Options must not be nil; passing a nil option results in an error (or panic with MustNew).

### OperationOption

```go
type OperationOption func(*Operation) error
```

Functional option for operation configuration.

## Common Patterns

### Basic Generation

```go
api := openapi.MustNew(openapi.WithTitle("My API", "1.0.0"))
op, _ := openapi.WithGET("/users/:id", openapi.WithSummary("Get user"), openapi.WithResponse(200, User{}))
if err := api.AddOperation(op); err != nil {
    log.Fatal(err)
}
result, err := api.Spec(context.Background())
```

### With Security

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
)
op, _ := openapi.WithGET("/users/:id", openapi.WithSecurity("bearerAuth"), openapi.WithResponse(200, User{}))
if err := api.AddOperation(op); err != nil {
    log.Fatal(err)
}
result, err := api.Spec(context.Background())
```

### With Validation

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithValidateSpec(true),
)
result, err := api.Spec(context.Background())
// Fails if spec is invalid
```

### With Diagnostics

```go
import "rivaas.dev/openapi/diag"

result, err := api.Spec(context.Background())
if err != nil {
    log.Fatal(err)
}

if result.Warnings.Has(diag.WarnDownlevelInfoSummary) {
    log.Warn("info.summary was dropped")
}
```

## Thread Safety

The `API` type is safe for concurrent use:
- Multiple goroutines can call `Spec()` and `AddOperation()` (operations slice is protected)
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

For learning-focused guides, see the [OpenAPI Guide](/docs/guides/openapi/).
