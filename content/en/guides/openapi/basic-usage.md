---
title: "Basic Usage"
description: "Learn the fundamentals of generating OpenAPI specifications"
weight: 2
---

Learn how to generate OpenAPI specifications from Go code using the openapi package.

## Creating an API Configuration

The first step is to create an API configuration using `New()` or `MustNew()`:

```go
import "rivaas.dev/openapi"

// With error handling
api, err := openapi.New(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithInfoDescription("API description"),
)
if err != nil {
    log.Fatal(err)
}

// Without error handling (panics on error)
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithInfoDescription("API description"),
)
```

The `MustNew()` function is convenient for initialization code. Use it where panicking on error is acceptable.

## Generating Specifications

Use `api.Generate()` with a context and variadic operation arguments:

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithResponse(200, []User{}),
    ),
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
```

### The Result Object

The `Generate()` method returns a `Result` object containing:

- **`JSON`** - The OpenAPI specification as JSON bytes.
- **`YAML`** - The OpenAPI specification as YAML bytes.
- **`Warnings`** - Any generation warnings. See [Diagnostics](../diagnostics/) for details.

```go
// Use the JSON specification
fmt.Println(string(result.JSON))

// Or use the YAML specification
fmt.Println(string(result.YAML))

// Check for warnings
if len(result.Warnings) > 0 {
    fmt.Printf("Generated with %d warnings\n", len(result.Warnings))
}
```

## Defining Operations

Operations are defined using HTTP method constructors:

```go
openapi.GET("/path", options...)
openapi.POST("/path", options...)
openapi.PUT("/path", options...)
openapi.PATCH("/path", options...)
openapi.DELETE("/path", options...)
openapi.HEAD("/path", options...)
openapi.OPTIONS("/path", options...)
openapi.TRACE("/path", options...)
```

Each constructor takes a path and optional operation options.

### Path Parameters

Use colon syntax for path parameters:

```go
openapi.GET("/users/:id",
    openapi.WithSummary("Get user by ID"),
    openapi.WithResponse(200, User{}),
)

openapi.GET("/orgs/:orgId/users/:userId",
    openapi.WithSummary("Get user in organization"),
    openapi.WithResponse(200, User{}),
)
```

Path parameters are automatically discovered and marked as required.

## Request and Response Types

Define request and response types using Go structs:

```go
type User struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

type CreateUserRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
}

// Use in operations
openapi.POST("/users",
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)
```

The package automatically converts Go types to OpenAPI schemas.

## Multiple Response Types

Operations can have multiple response types for different status codes:

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

## Empty Responses

For responses with no body, use `nil`:

```go
openapi.DELETE("/users/:id",
    openapi.WithSummary("Delete user"),
    openapi.WithResponse(204, nil),
)
```

## Complete Example

Here's a complete example putting it all together:

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"

    "rivaas.dev/openapi"
)

type User struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

type CreateUserRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
}

type ErrorResponse struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("User API", "1.0.0"),
        openapi.WithInfoDescription("API for managing users"),
        openapi.WithServer("http://localhost:8080", "Local development"),
    )

    result, err := api.Generate(context.Background(),
        openapi.GET("/users",
            openapi.WithSummary("List users"),
            openapi.WithResponse(200, []User{}),
        ),
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithResponse(200, User{}),
            openapi.WithResponse(404, ErrorResponse{}),
        ),
        openapi.POST("/users",
            openapi.WithSummary("Create user"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(201, User{}),
            openapi.WithResponse(400, ErrorResponse{}),
        ),
        openapi.DELETE("/users/:id",
            openapi.WithSummary("Delete user"),
            openapi.WithResponse(204, nil),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Write to file
    if err := os.WriteFile("openapi.json", result.JSON, 0644); err != nil {
        log.Fatal(err)
    }

    fmt.Println("OpenAPI specification written to openapi.json")
}
```

## Next Steps

- Learn about [Configuration](../configuration/) to customize your API settings
- Explore [Operations](../operations/) for advanced operation definitions
- See [Auto-Discovery](../auto-discovery/) to learn about automatic parameter discovery
- Check [Security](../security/) to add authentication schemes
