---
title: "OpenAPI Specification Generation"
description: "Learn how to generate OpenAPI specifications from Go code with automatic parameter discovery and schema generation"
weight: 3
sidebar_root_for: self
---

Automatic OpenAPI 3.0.4 and 3.1.2 specification generation for Go applications.

This package enables automatic generation of OpenAPI specifications from Go code using struct tags and reflection. It provides a clean, type-safe API for building specifications with minimal boilerplate.

## Features

- **Clean API** - Builder-style `API.Generate()` method for specification generation
- **Type-Safe Version Selection** - `V30x` and `V31x` constants with IDE autocomplete
- **Fluent HTTP Method Constructors** - `GET()`, `POST()`, `PUT()`, etc. for clean operation definitions
- **Functional Options** - Consistent `With*` pattern for all configuration
- **Type-Safe Warning Diagnostics** - `diag` package for fine-grained warning control
- **Automatic Parameter Discovery** - Extracts query, path, header, and cookie parameters from struct tags
- **Schema Generation** - Converts Go types to OpenAPI schemas automatically
- **Swagger UI Configuration** - Built-in, customizable Swagger UI settings
- **Semantic Operation IDs** - Auto-generates operation IDs from HTTP methods and paths
- **Security Schemes** - Support for Bearer, API Key, OAuth2, and OpenID Connect
- **Collision-Resistant Naming** - Schema names use `pkgname.TypeName` format to prevent collisions
- **Built-in Validation** - Validates generated specs against official OpenAPI meta-schemas
- **Standalone Validator** - Validate external OpenAPI specs with pre-compiled schemas

## Quick Start

Here's a 30-second example to get you started:

```go
package main

import (
    "context"
    "fmt"
    "log"

    "rivaas.dev/openapi"
)

type User struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

type CreateUserRequest struct {
    Name  string `json:"name" validate:"required"`
    Email string `json:"email" validate:"required,email"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("My API", "1.0.0"),
        openapi.WithInfoDescription("API for managing users"),
        openapi.WithServer("http://localhost:8080", "Local development"),
        openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
    )

    result, err := api.Generate(context.Background(),
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithResponse(200, User{}),
            openapi.WithSecurity("bearerAuth"),
        ),
        openapi.POST("/users",
            openapi.WithSummary("Create user"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(201, User{}),
        ),
        openapi.DELETE("/users/:id",
            openapi.WithSummary("Delete user"),
            openapi.WithResponse(204, nil),
            openapi.WithSecurity("bearerAuth"),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Check for warnings (optional)
    if len(result.Warnings) > 0 {
        fmt.Printf("Generated with %d warnings\n", len(result.Warnings))
    }

    fmt.Println(string(result.JSON))
}
```

### How It Works

- **API configuration** is done through functional options with `With*` prefix
- **Operations** are defined using HTTP method constructors: `GET()`, `POST()`, etc.
- **Types** are automatically converted to OpenAPI schemas using reflection
- **Parameters** are discovered from struct tags: `path`, `query`, `header`, `cookie`
- **Validation** is optional but recommended for production use

## Learning Path

Follow these guides to master OpenAPI specification generation with Rivaas:

1. [**Installation**](installation/) - Get started with the openapi package
2. [**Basic Usage**](basic-usage/) - Learn the fundamentals of generating specifications
3. [**Configuration**](configuration/) - Configure API info, servers, and version selection
4. [**Security**](security/) - Add authentication and authorization schemes
5. [**Operations**](operations/) - Define HTTP operations with methods and options
6. [**Auto-Discovery**](auto-discovery/) - Use struct tags for automatic parameter discovery
7. [**Schema Generation**](schema-generation/) - Understand Go type to OpenAPI schema conversion
8. [**Swagger UI**](swagger-ui/) - Customize the Swagger UI interface
9. [**Validation**](validation/) - Validate generated specifications
10. [**Diagnostics**](diagnostics/) - Handle warnings with type-safe diagnostics
11. [**Advanced Usage**](advanced-usage/) - Extensions, custom operation IDs, and strict mode
12. [**Examples**](examples/) - See real-world usage patterns

## Next Steps

- Start with [Installation](installation/) to set up the openapi package
- Explore the [API Reference](/reference/packages/openapi/) for complete technical details
- Check out [code examples on GitHub](https://github.com/rivaas-dev/rivaas/tree/main/openapi/examples/)
