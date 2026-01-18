---
title: "OpenAPI"
linkTitle: "OpenAPI"
weight: 12
description: >
  Automatically generate OpenAPI specifications and Swagger UI.
---

## Overview

The app package integrates with the `rivaas.dev/openapi` package to automatically generate OpenAPI specifications with Swagger UI.

## Basic Configuration

### Enable OpenAPI

Enable OpenAPI with default configuration:

```go
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithServiceVersion("v1.0.0"),
    app.WithOpenAPI(
        openapi.WithSwaggerUI(true, "/docs"),
    ),
)
```

Service name and version are automatically injected into the OpenAPI spec.

## Configure OpenAPI

### API Information

Configure API metadata:

```go
a, err := app.New(
    app.WithOpenAPI(
        openapi.WithTitle("My API", "1.0.0"),
        openapi.WithDescription("API for managing resources"),
        openapi.WithContact("API Support", "https://example.com/support", "support@example.com"),
        openapi.WithLicense("Apache 2.0", "https://www.apache.org/licenses/LICENSE-2.0"),
    ),
)
```

### Servers

Add server URLs:

```go
a, err := app.New(
    app.WithOpenAPI(
        openapi.WithServer("http://localhost:8080", "Local development"),
        openapi.WithServer("https://api.example.com", "Production"),
    ),
)
```

### Security

Configure security schemes:

```go
a, err := app.New(
    app.WithOpenAPI(
        openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
        openapi.WithAPIKeyAuth("apiKey", "header", "X-API-Key", "API key authentication"),
    ),
)
```

## Document Routes

### WithDoc Option

Document routes inline:

```go
a.GET("/users/:id", getUserHandler,
    app.WithDoc(
        openapi.WithSummary("Get user by ID"),
        openapi.WithDescription("Retrieves a user by their unique identifier"),
        openapi.WithResponse(200, UserResponse{}),
        openapi.WithResponse(404, ErrorResponse{}),
        openapi.WithTags("users"),
    ),
)
```

### Request Bodies

Document request bodies:

```go
a.POST("/users", createUserHandler,
    app.WithDoc(
        openapi.WithSummary("Create user"),
        openapi.WithRequest(CreateUserRequest{}),
        openapi.WithResponse(201, UserResponse{}),
    ),
)
```

### Parameters

Document path and query parameters:

```go
a.GET("/users", listUsersHandler,
    app.WithDoc(
        openapi.WithSummary("List users"),
        openapi.WithQueryParam("page", "integer", "Page number"),
        openapi.WithQueryParam("limit", "integer", "Items per page"),
        openapi.WithResponse(200, UserListResponse{}),
    ),
)
```

## Swagger UI

### Enable Swagger UI

Enable Swagger UI at a specific path:

```go
a, err := app.New(
    app.WithOpenAPI(
        openapi.WithSwaggerUI(true, "/docs"),
    ),
)

// Access Swagger UI at: http://localhost:8080/docs
```

### Configure Swagger UI

Customize Swagger UI appearance:

```go
a, err := app.New(
    app.WithOpenAPI(
        openapi.WithSwaggerUI(true, "/docs"),
        openapi.WithUIDocExpansion(openapi.DocExpansionList),
        openapi.WithUISyntaxTheme(openapi.SyntaxThemeMonokai),
        openapi.WithUIDeepLinking(true),
    ),
)
```

## OpenAPI Endpoints

When OpenAPI is enabled, two endpoints are registered:

- `GET /openapi.json` - OpenAPI specification (JSON)
- `GET /docs` - Swagger UI (if enabled)

### Custom Spec Path

Configure custom spec path:

```go
a, err := app.New(
    app.WithOpenAPI(
        openapi.WithSpecPath("/api/spec.json"),
        openapi.WithSwaggerUI(true, "/api/docs"),
    ),
)
```

## Complete Example

```go
package main

import (
    "log"
    "net/http"
    
    "rivaas.dev/app"
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
    a, err := app.New(
        app.WithServiceName("users-api"),
        app.WithServiceVersion("v1.0.0"),
        
        app.WithOpenAPI(
            openapi.WithDescription("API for managing users"),
            openapi.WithServer("http://localhost:8080", "Development"),
            openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
            openapi.WithSwaggerUI(true, "/docs"),
            openapi.WithTags(
                openapi.Tag("users", "User management"),
            ),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // List users
    a.GET("/users", listUsersHandler,
        app.WithDoc(
            openapi.WithSummary("List users"),
            openapi.WithDescription("Returns a list of all users"),
            openapi.WithResponse(200, []User{}),
            openapi.WithTags("users"),
        ),
    )
    
    // Create user
    a.POST("/users", createUserHandler,
        app.WithDoc(
            openapi.WithSummary("Create user"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(201, User{}),
            openapi.WithResponse(400, map[string]string{}),
            openapi.WithTags("users"),
            openapi.WithSecurity("bearerAuth"),
        ),
    )
    
    // Get user
    a.GET("/users/:id", getUserHandler,
        app.WithDoc(
            openapi.WithSummary("Get user by ID"),
            openapi.WithResponse(200, User{}),
            openapi.WithResponse(404, map[string]string{}),
            openapi.WithTags("users"),
        ),
    )
    
    // Start server
    // OpenAPI spec: http://localhost:8080/openapi.json
    // Swagger UI: http://localhost:8080/docs
}
```

## Next Steps

- [Basic Usage](../basic-usage/) - Learn about route registration
- [Context](../context/) - Document request/response schemas
- See [OpenAPI Guide](/guides/openapi/) for detailed documentation
