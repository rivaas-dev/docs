---
title: "Operation Options"
description: "Complete reference for operation-level configuration options"
keywords:
  - operation options
  - endpoint configuration
  - operation configuration
  - request response
weight: 3
---

Complete reference for all operation-level configuration options (functions passed to HTTP method constructors).

## Metadata Options

### WithSummary

```go
func WithSummary(summary string) OperationOption
```

Sets the operation summary (short description).

**Example:**

```go
openapi.WithSummary("Get user by ID")
```

### WithDescription

```go
func WithDescription(description string) OperationOption
```

Sets the operation description (detailed explanation).

**Example:**

```go
openapi.WithDescription("Retrieves a user by their unique identifier from the database")
```

### WithOperationID

```go
func WithOperationID(operationID string) OperationOption
```

Sets a custom operation ID. By default, operation IDs are auto-generated from method and path.

**Example:**

```go
openapi.WithOperationID("getUserById")
```

## Request and Response Options

### WithRequest

```go
func WithRequest(requestType interface{}, examples ...interface{}) OperationOption
```

Sets the request body type with optional examples.

**Parameters:**
- `requestType` - Go type to convert to schema
- `examples` - Optional example instances

**Example:**

```go
exampleUser := CreateUserRequest{Name: "John", Email: "john@example.com"}
openapi.WithRequest(CreateUserRequest{}, exampleUser)
```

### WithResponse

```go
func WithResponse(statusCode int, responseType interface{}, examples ...interface{}) OperationOption
```

Adds a response type for a specific status code.

**Parameters:**
- `statusCode` - HTTP status code
- `responseType` - Go type to convert to schema (use `nil` for no body)
- `examples` - Optional example instances

**Example:**

```go
openapi.WithResponse(200, User{})
openapi.WithResponse(204, nil) // No response body
openapi.WithResponse(404, ErrorResponse{})
```

## Organization Options

### WithTags

```go
func WithTags(tags ...string) OperationOption
```

Adds tags to the operation for organization.

**Parameters:**
- `tags` - Tag names

**Example:**

```go
openapi.WithTags("users")
openapi.WithTags("users", "admin")
```

## Security Options

### WithSecurity

```go
func WithSecurity(scheme string, scopes ...string) OperationOption
```

Adds a security requirement to the operation.

**Parameters:**
- `scheme` - Security scheme name (defined with `WithBearerAuth`, `WithAPIKey`, etc.)
- `scopes` - Optional OAuth2 scopes

**Example:**

```go
openapi.WithSecurity("bearerAuth")
openapi.WithSecurity("oauth2", "read", "write")
```

Multiple calls create alternative security requirements (OR logic):

```go
openapi.GET("/users/:id",
    openapi.WithSecurity("bearerAuth"),  // Can use bearer auth
    openapi.WithSecurity("apiKey"),      // OR can use API key
    openapi.WithResponse(200, User{}),
)
```

## Content Type Options

### WithConsumes

```go
func WithConsumes(contentTypes ...string) OperationOption
```

Sets accepted content types for the request.

**Parameters:**
- `contentTypes` - MIME types

**Example:**

```go
openapi.WithConsumes("application/json", "application/xml")
```

### WithProduces

```go
func WithProduces(contentTypes ...string) OperationOption
```

Sets returned content types for the response.

**Parameters:**
- `contentTypes` - MIME types

**Example:**

```go
openapi.WithProduces("application/json", "application/xml")
```

## Deprecation

### WithDeprecated

```go
func WithDeprecated() OperationOption
```

Marks the operation as deprecated.

**Example:**

```go
openapi.GET("/users/legacy",
    openapi.WithSummary("Legacy user list"),
    openapi.WithDeprecated(),
    openapi.WithResponse(200, []User{}),
)
```

## Extension Options

### WithOperationExtension

```go
func WithOperationExtension(key string, value interface{}) OperationOption
```

Adds a custom `x-*` extension to the operation.

**Parameters:**
- `key` - Extension key (must start with `x-`)
- `value` - Extension value (any JSON-serializable type)

**Example:**

```go
openapi.WithOperationExtension("x-rate-limit", 100)
openapi.WithOperationExtension("x-cache-ttl", 300)
```

## Composable Options

### WithOptions

```go
func WithOptions(opts ...OperationOption) OperationOption
```

Combines multiple operation options into a single reusable option.

**Parameters:**
- `opts` - Operation options to combine

**Example:**

```go
CommonErrors := openapi.WithOptions(
    openapi.WithResponse(400, ErrorResponse{}),
    openapi.WithResponse(500, ErrorResponse{}),
)

UserEndpoint := openapi.WithOptions(
    openapi.WithTags("users"),
    openapi.WithSecurity("bearerAuth"),
    CommonErrors,
)

// Use in operations
openapi.GET("/users/:id",
    UserEndpoint,
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)
```

## Option Summary Table

| Option | Description |
|--------|-------------|
| `WithSummary(s)` | Set operation summary |
| `WithDescription(s)` | Set operation description |
| `WithOperationID(id)` | Set custom operation ID |
| `WithRequest(type, examples...)` | Set request body type |
| `WithResponse(status, type, examples...)` | Set response type for status code |
| `WithTags(tags...)` | Add tags to operation |
| `WithSecurity(scheme, scopes...)` | Add security requirement |
| `WithDeprecated()` | Mark operation as deprecated |
| `WithConsumes(types...)` | Set accepted content types |
| `WithProduces(types...)` | Set returned content types |
| `WithOperationExtension(key, value)` | Add operation extension |
| `WithOptions(opts...)` | Combine options into reusable set |

## Next Steps

- See [Options](options/) for API-level configuration
- Check [API Reference](api-reference/) for types and methods
- Review [Examples](/guides/openapi/examples/) for usage patterns
