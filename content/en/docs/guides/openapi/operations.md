---
title: "Operations"
description: "Define HTTP operations with methods, options, and composable configurations"
weight: 5
keywords:
  - openapi operations
  - endpoints
  - request response
  - http operations
---

Learn how to define HTTP operations using method constructors and operation options.

## HTTP Method Constructors

The package provides HTTP method constructors for defining operations:

```go
openapi.GET("/users/:id", opts...)
openapi.POST("/users", opts...)
openapi.PUT("/users/:id", opts...)
openapi.PATCH("/users/:id", opts...)
openapi.DELETE("/users/:id", opts...)
openapi.HEAD("/users/:id", opts...)
openapi.OPTIONS("/users", opts...)
openapi.TRACE("/debug", opts...)
```

Each constructor takes a path and optional operation options.

## Operation Options

All operation options follow the `With*` naming convention:

| Function | Description |
|----------|-------------|
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

## Basic Operation Definition

Define a simple GET operation:

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users/:id",
        openapi.WithSummary("Get user by ID"),
        openapi.WithDescription("Retrieves a user by their unique identifier"),
        openapi.WithResponse(200, User{}),
    ),
)
```

## Request Bodies

Use `WithRequest()` to specify the request body type:

```go
type CreateUserRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
}

openapi.POST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)
```

### Request with Examples

Provide example request bodies:

```go
exampleUser := CreateUserRequest{
    Name:  "John Doe",
    Email: "john@example.com",
}

openapi.POST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}, exampleUser),
    openapi.WithResponse(201, User{}),
)
```

## Response Types

Define multiple response types for different status codes:

```go
type ErrorResponse struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
}

openapi.GET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
    openapi.WithResponse(404, ErrorResponse{}),
    openapi.WithResponse(500, ErrorResponse{}),
)
```

### Response with Examples

Provide example responses:

```go
exampleUser := User{
    ID:    123,
    Name:  "John Doe",
    Email: "john@example.com",
}

openapi.GET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}, exampleUser),
)
```

## Tags

Organize operations with tags:

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithTags("users"),
        openapi.WithResponse(200, []User{}),
    ),
    openapi.GET("/posts",
        openapi.WithSummary("List posts"),
        openapi.WithTags("posts"),
        openapi.WithResponse(200, []Post{}),
    ),
)
```

Multiple tags per operation:

```go
openapi.GET("/users/:id/posts",
    openapi.WithSummary("Get user's posts"),
    openapi.WithTags("users", "posts"),
    openapi.WithResponse(200, []Post{}),
)
```

## Security Requirements

Apply security to operations:

```go
// Single security scheme
openapi.GET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithSecurity("bearerAuth"),
    openapi.WithResponse(200, User{}),
)

// OAuth2 with scopes
openapi.POST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithSecurity("oauth2", "read", "write"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)

// Multiple security schemes (OR)
openapi.DELETE("/users/:id",
    openapi.WithSummary("Delete user"),
    openapi.WithSecurity("bearerAuth"),
    openapi.WithSecurity("apiKey"),
    openapi.WithResponse(204, nil),
)
```

## Deprecated Operations

Mark operations as deprecated:

```go
openapi.GET("/users/legacy",
    openapi.WithSummary("Legacy user list"),
    openapi.WithDescription("This endpoint is deprecated. Use /users instead."),
    openapi.WithDeprecated(),
    openapi.WithResponse(200, []User{}),
)
```

## Content Types

Specify content types for requests and responses:

```go
openapi.POST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithConsumes("application/json", "application/xml"),
    openapi.WithProduces("application/json", "application/xml"),
    openapi.WithResponse(201, User{}),
)
```

## Operation Extensions

Add custom `x-*` extensions to operations:

```go
openapi.GET("/users",
    openapi.WithSummary("List users"),
    openapi.WithOperationExtension("x-rate-limit", 100),
    openapi.WithOperationExtension("x-internal-only", false),
    openapi.WithResponse(200, []User{}),
)
```

## Complete Operation Example

Here's a complete example with all options:

```go
openapi.PUT("/users/:id",
    openapi.WithSummary("Update user"),
    openapi.WithDescription("Updates an existing user's information"),
    openapi.WithOperationID("updateUser"),
    openapi.WithRequest(UpdateUserRequest{}),
    openapi.WithResponse(200, User{}),
    openapi.WithResponse(400, ErrorResponse{}),
    openapi.WithResponse(404, ErrorResponse{}),
    openapi.WithResponse(500, ErrorResponse{}),
    openapi.WithTags("users"),
    openapi.WithSecurity("bearerAuth"),
    openapi.WithConsumes("application/json"),
    openapi.WithProduces("application/json"),
    openapi.WithOperationExtension("x-rate-limit", 50),
)
```

## Composable Operation Options

Use `WithOptions()` to create reusable option sets:

```go
// Define reusable option sets
var (
    CommonErrors = openapi.WithOptions(
        openapi.WithResponse(400, ErrorResponse{}),
        openapi.WithResponse(401, ErrorResponse{}),
        openapi.WithResponse(500, ErrorResponse{}),
    )
    
    UserEndpoint = openapi.WithOptions(
        openapi.WithTags("users"),
        openapi.WithSecurity("bearerAuth"),
        CommonErrors,
    )
    
    JSONContent = openapi.WithOptions(
        openapi.WithConsumes("application/json"),
        openapi.WithProduces("application/json"),
    )
)

// Apply to operations
result, err := api.Generate(context.Background(),
    openapi.GET("/users/:id",
        UserEndpoint,
        JSONContent,
        openapi.WithSummary("Get user"),
        openapi.WithResponse(200, User{}),
    ),
    
    openapi.POST("/users",
        UserEndpoint,
        JSONContent,
        openapi.WithSummary("Create user"),
        openapi.WithRequest(CreateUserRequest{}),
        openapi.WithResponse(201, User{}),
    ),
    
    openapi.PUT("/users/:id",
        UserEndpoint,
        JSONContent,
        openapi.WithSummary("Update user"),
        openapi.WithRequest(UpdateUserRequest{}),
        openapi.WithResponse(200, User{}),
    ),
)
```

### Nested Composable Options

Option sets can be nested:

```go
var (
    ErrorResponses = openapi.WithOptions(
        openapi.WithResponse(400, ErrorResponse{}),
        openapi.WithResponse(500, ErrorResponse{}),
    )
    
    AuthRequired = openapi.WithOptions(
        openapi.WithSecurity("bearerAuth"),
        openapi.WithResponse(401, ErrorResponse{}),
        ErrorResponses,
    )
    
    UserAPI = openapi.WithOptions(
        openapi.WithTags("users"),
        AuthRequired,
    )
)
```

## Custom Operation IDs

By default, operation IDs are auto-generated from the HTTP method and path. Override with `WithOperationID()`:

```go
openapi.GET("/users/:id",
    openapi.WithOperationID("getUserById"),
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)
```

Without `WithOperationID()`, the operation ID would be auto-generated as `getUsers_id`.

## Next Steps

- Learn about [Auto-Discovery](../auto-discovery/) for automatic parameter discovery
- Explore [Schema Generation](../schema-generation/) for type conversion
- See [Examples](../examples/) for complete operation patterns
