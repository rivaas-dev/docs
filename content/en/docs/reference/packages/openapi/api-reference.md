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

Main API configuration container. Holds the OpenAPI specification metadata and configuration.

**Created by:**
- `New(...Option) (*API, error)` - With error handling.
- `MustNew(...Option) *API` - Panics on error.

**Methods:**
- `Generate(ctx context.Context, ...Operation) (*Result, error)` - Generate OpenAPI specification.
- `Version() string` - Get target OpenAPI version like "3.0.4" or "3.1.2".

### Operation

```go
type Operation struct {
    // contains filtered or unexported fields
}
```

Represents an HTTP operation with method, path, and configuration.

**Created by HTTP method constructors:**
- `GET(path string, ...OperationOption) Operation`
- `POST(path string, ...OperationOption) Operation`
- `PUT(path string, ...OperationOption) Operation`
- `PATCH(path string, ...OperationOption) Operation`
- `DELETE(path string, ...OperationOption) Operation`
- `HEAD(path string, ...OperationOption) Operation`
- `OPTIONS(path string, ...OperationOption) Operation`
- `TRACE(path string, ...OperationOption) Operation`

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

### Option

```go
type Option func(*API) error
```

Functional option for configuring the API. See [Options](options/) for all available options.

### OperationOption

```go
type OperationOption func(*Operation) error
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

## HTTP Method Constructors

### GET

```go
func GET(path string, opts ...OperationOption) Operation
```

Creates a GET operation.

**Parameters:**
- `path` - URL path (use `:param` syntax for path parameters)
- `opts` - Variable number of OperationOption functions

**Returns:**
- `Operation` - Configured operation

**Example:**

```go
openapi.GET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)
```

### POST

```go
func POST(path string, opts ...OperationOption) Operation
```

Creates a POST operation.

**Parameters:**
- `path` - URL path
- `opts` - Variable number of OperationOption functions

**Returns:**
- `Operation` - Configured operation

**Example:**

```go
openapi.POST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)
```

### PUT

```go
func PUT(path string, opts ...OperationOption) Operation
```

Creates a PUT operation.

### PATCH

```go
func PATCH(path string, opts ...OperationOption) Operation
```

Creates a PATCH operation.

### DELETE

```go
func DELETE(path string, opts ...OperationOption) Operation
```

Creates a DELETE operation.

**Example:**

```go
openapi.DELETE("/users/:id",
    openapi.WithSummary("Delete user"),
    openapi.WithResponse(204, nil),
)
```

### HEAD

```go
func HEAD(path string, opts ...OperationOption) Operation
```

Creates a HEAD operation.

### OPTIONS

```go
func OPTIONS(path string, opts ...OperationOption) Operation
```

Creates an OPTIONS operation.

### TRACE

```go
func TRACE(path string, opts ...OperationOption) Operation
```

Creates a TRACE operation.

## Methods

### API.Generate

```go
func (api *API) Generate(ctx context.Context, operations ...Operation) (*Result, error)
```

Generates an OpenAPI specification from the configured API and operations.

**Parameters:**
- `ctx` - Context for cancellation
- `operations` - Variable number of Operation instances

**Returns:**
- `*Result` - Generation result with JSON, YAML, and warnings
- `error` - Generation or validation error if any

**Errors:**
- Returns error if context is nil
- Returns error if generation fails
- Returns error if validation is enabled and spec is invalid

**Example:**

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users/:id",
        openapi.WithSummary("Get user"),
        openapi.WithResponse(200, User{}),
    ),
    openapi.POST("/users",
        openapi.WithSummary("Create user"),
        openapi.WithRequest(CreateUserRequest{}),
        openapi.WithResponse(201, User{}),
    ),
)
if err != nil {
    log.Fatal(err)
}

// Use result.JSON or result.YAML
fmt.Println(string(result.JSON))
```

### API.Version

```go
func (api *API) Version() string
```

Returns the target OpenAPI version as a string.

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
