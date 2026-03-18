---
title: "API Reference"
description: "Complete API reference for types, functions, and methods"
keywords:
  - openapi api
  - openapi reference
  - api documentation
  - type reference
weight: 1
---

Complete reference for all types, functions, and methods in the openapi package.

## Key Types

### API

```go
type API struct {
    // contains filtered or unexported fields
}
```

Main API configuration container. Holds the OpenAPI specification metadata and configuration. Configuration is read-only after creation; use the getters below to read values.

**Created by:**
- `New(...Option) (*API, error)` - With error handling.
- `MustNew(...Option) *API` - Panics on error.

**Methods:**
- `Spec(ctx context.Context) (*Result, error)` - Generate OpenAPI specification from current config and operations.
- `AddOperation(ops ...Operation)` - Add operations (e.g. from [WithGET], [WithPOST]) for inclusion in the spec.
- `Validate() error` - Check if the API configuration is valid.
- `UI() UISnapshot` - Read-only snapshot of Swagger UI configuration for rendering (e.g. use [UISnapshot.ToJSON] to embed in HTML).
- `Info() model.Info` - API metadata (title, version, description, etc.).
- `Servers() []model.Server` - Server list.
- `Tags() []model.Tag` - Tags.
- `SecuritySchemes() map[string]*model.SecurityScheme` - Security schemes.
- `DefaultSecurity() []model.SecurityRequirement` - Default security requirements.
- `ExternalDocs() *model.ExternalDocs` - External documentation link.
- `Extensions() map[string]any` - Root-level extensions.
- `Version() Version` - Target OpenAPI version (V30x or V31x).
- `StrictDownlevel() bool` - Whether 3.1-only features error when targeting 3.0.
- `SpecPath() string` - HTTP path for the spec JSON.
- `UIPath() string` - HTTP path for Swagger UI.
- `ServeUI() bool` - Whether Swagger UI is enabled.
- `ValidateSpec() bool` - Whether spec validation is enabled.

### Operation

```go
type Operation struct {
    // contains filtered or unexported fields
}
```

Represents an HTTP operation with method, path, and configuration.

**Created by operation builders:**
- `WithGET(path string, ...OperationOption) (Operation, error)`
- `WithPOST(path string, ...OperationOption) (Operation, error)`
- `WithPUT(path string, ...OperationOption) (Operation, error)`
- `WithPATCH(path string, ...OperationOption) (Operation, error)`
- `WithDELETE(path string, ...OperationOption) (Operation, error)`
- `WithHEAD(path string, ...OperationOption) (Operation, error)`
- `WithOPTIONS(path string, ...OperationOption) (Operation, error)`
- `WithTRACE(path string, ...OperationOption) (Operation, error)`
- `WithOp(method, path string, ...OperationOption) (Operation, error)` - Custom method

### Result

```go
type Result struct {
    JSON     []byte
    YAML     []byte
    Warnings Warnings
}
```

Result of specification generation.

**Fields:**
- `JSON` - OpenAPI specification as JSON bytes.
- `YAML` - OpenAPI specification as YAML bytes.
- `Warnings` - Collection of generation warnings. Check [Diagnostics](diagnostics/) for details.

### Version

```go
type Version int

const (
    V30x Version = iota  // OpenAPI 3.0.x (generates 3.0.4)
    V31x                 // OpenAPI 3.1.x (generates 3.1.2)
)
```

Type-safe OpenAPI version selection. Use with `WithVersion()` option.

**Constants:**
- `V30x` - Target OpenAPI 3.0.x family. Generates 3.0.4 specification.
- `V31x` - Target OpenAPI 3.1.x family. Generates 3.1.2 specification.

### UISnapshot

```go
type UISnapshot interface {
    ToJSON(specPath string) (string, error)
}
```

Read-only view of Swagger UI configuration returned by [API.UI]. Use it for rendering (e.g. embed JSON in HTML); do not use for construction. Configuration is done via [UIOption] and [New] or [MustNew].

### Option

```go
type Option func(*config)
```

Functional option for configuring the API. See [Options](options/) for all available options.

### OperationOption

```go
type OperationOption func(*operationDoc)
```

Functional option for configuring operations. See [Operation Options](operation-options/) for all available options.

## Functions

### New

```go
func New(opts ...Option) (*API, error)
```

Creates a new API configuration with error handling.

**Parameters:**
- `opts` - Variable number of Option functions

**Returns:**
- `*API` - Configured API instance
- `error` - Configuration error if any

**Example:**

```go
api, err := openapi.New(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithServer("http://localhost:8080", "Development"),
)
if err != nil {
    log.Fatal(err)
}
```

### MustNew

```go
func MustNew(opts ...Option) *API
```

Creates a new API configuration. Panics if configuration fails.

**Parameters:**
- `opts` - Variable number of Option functions

**Returns:**
- `*API` - Configured API instance

**Panics:**
- If configuration fails

**Example:**

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithServer("http://localhost:8080", "Development"),
)
```

## Operation Builders

Operations are created with `WithGET`, `WithPOST`, etc., and added to the API via [WithOperations] at construction or [API.AddOperation] after. Then call [API.Spec] to generate the spec.

### WithGET

```go
func WithGET(path string, opts ...OperationOption) (Operation, error)
```

Creates a GET operation.

**Example:**

```go
op, err := openapi.WithGET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)
api.AddOperation(op)
```

### WithPOST

```go
func WithPOST(path string, opts ...OperationOption) (Operation, error)
```

Creates a POST operation.

**Example:**

```go
op, err := openapi.WithPOST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)
api.AddOperation(op)
```

### WithPUT, WithPATCH, WithDELETE, WithHEAD, WithOPTIONS, WithTRACE

Same pattern as `WithGET` / `WithPOST` for other HTTP methods.

### WithOp

```go
func WithOp(method, path string, opts ...OperationOption) (Operation, error)
```

Creates an operation with a custom HTTP method.

## Methods

### API.Spec

```go
func (api *API) Spec(ctx context.Context) (*Result, error)
```

Generates an OpenAPI specification from the API's current configuration and operations (from [WithOperations] and/or [API.AddOperation]). No operation list is passed at call time.

**Example:**

```go
api := openapi.MustNew(openapi.WithTitle("My API", "1.0.0"))
op, _ := openapi.WithGET("/users/:id", openapi.WithSummary("Get user"), openapi.WithResponse(200, User{}))
api.AddOperation(op)
result, err := api.Spec(context.Background())
// Or use WithOperations at construction and skip AddOperation
```

### API.AddOperation

```go
func (api *API) AddOperation(ops ...Operation)
```

Adds one or more operations to the API. Call [API.Spec] to generate the spec including these operations.

### API.Version

```go
func (api *API) Version() Version
```

Returns the target OpenAPI version (V30x or V31x).

**Returns:**
- `string` - Version string ("3.0.4" or "3.1.2")

**Example:**

```go
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithVersion(openapi.V31x),
)

fmt.Println(api.Version()) // "3.1.2"
```

## Type Aliases and Constants

### Parameter Locations

```go
const (
    InHeader ParameterLocation = "header"
    InQuery  ParameterLocation = "query"
    InCookie ParameterLocation = "cookie"
)
```

Used with `WithAPIKey()` to specify where the API key is located.

### OAuth2 Flow Types

```go
const (
    FlowAuthorizationCode OAuthFlowType = "authorizationCode"
    FlowImplicit          OAuthFlowType = "implicit"
    FlowPassword          OAuthFlowType = "password"
    FlowClientCredentials OAuthFlowType = "clientCredentials"
)
```

Used with `WithOAuth2()` to specify the OAuth2 flow type.

### Swagger UI Constants

```go
// Document expansion
const (
    DocExpansionList DocExpansion = "list"
    DocExpansionFull DocExpansion = "full"
    DocExpansionNone DocExpansion = "none"
)

// Model rendering
const (
    ModelRenderingExample ModelRendering = "example"
    ModelRenderingModel   ModelRendering = "model"
)

// Operations sorting
const (
    OperationsSorterAlpha  OperationsSorter = "alpha"
    OperationsSorterMethod OperationsSorter = "method"
)

// Tags sorting
const (
    TagsSorterAlpha TagsSorter = "alpha"
)

// Validators (untyped string constants)
const (
    ValidatorLocal = "local"  // Use embedded meta-schema validation
    ValidatorNone  = "none"   // Disable validation
)

// Syntax themes
const (
    SyntaxThemeAgate        SyntaxTheme = "agate"
    SyntaxThemeArta         SyntaxTheme = "arta"
    SyntaxThemeMonokai      SyntaxTheme = "monokai"
    SyntaxThemeNord         SyntaxTheme = "nord"
    SyntaxThemeObsidian     SyntaxTheme = "obsidian"
    SyntaxThemeTomorrowNight SyntaxTheme = "tomorrow-night"
    SyntaxThemeIdea         SyntaxTheme = "idea"
)

// Request snippet languages
const (
    SnippetCurlBash       RequestSnippetLanguage = "curl_bash"
    SnippetCurlPowerShell RequestSnippetLanguage = "curl_powershell"
    SnippetCurlCmd        RequestSnippetLanguage = "curl_cmd"
)

```

See [Swagger UI Options](swagger-ui-options/) for usage.

## Next Steps

- Explore [Options](options/) for all API-level configuration options
- See [Operation Options](operation-options/) for operation-level options
- Check [Diagnostics](diagnostics/) for warning handling
- Review [Troubleshooting](troubleshooting/) for common issues
