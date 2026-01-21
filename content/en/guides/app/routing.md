---
title: "Routing"
linkTitle: "Routing"
weight: 7
keywords:
  - app routing
  - routes
  - handlers
  - endpoints
  - route groups
description: >
  Organize routes with groups, versioning, and static files.
---

## Route Registration

### HTTP Method Shortcuts

Register routes using HTTP method shortcuts:

```go
a.GET("/users", handler)
a.POST("/users", handler)
a.PUT("/users/:id", handler)
a.PATCH("/users/:id", handler)
a.DELETE("/users/:id", handler)
a.HEAD("/users", handler)
a.OPTIONS("/users", handler)
```

### Match All Methods

Register a route that matches all HTTP methods:

```go
a.Any("/webhook", webhookHandler)
// Handles GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
```

## Route Groups

### Basic Groups

Organize routes with shared prefixes:

```go
api := a.Group("/api")
api.GET("/users", getUsersHandler)
api.POST("/users", createUserHandler)
// Routes: GET /api/users, POST /api/users
```

### Nested Groups

Create hierarchical route structures:

```go
api := a.Group("/api")
v1 := api.Group("/v1")
v1.GET("/users", getUsersHandler)
// Route: GET /api/v1/users
```

### Groups with Middleware

Apply middleware to all routes in a group:

```go
admin := a.Group("/admin", AuthMiddleware(), AdminOnlyMiddleware())
admin.GET("/users", getUsersHandler)
admin.POST("/users", createUserHandler)
// Both routes have auth and admin middleware
```

## API Versioning

### Version Groups

Create version-specific routes:

```go
v1 := a.Version("v1")
v1.GET("/users", v1GetUsersHandler)

v2 := a.Version("v2")
v2.GET("/users", v2GetUsersHandler)
```

### Version Detection

Configure how versions are detected. This requires router configuration:

```go
a, err := app.New(
    app.WithRouter(
        router.WithVersioning(
            router.WithVersionHeader("API-Version"),
            router.WithVersionQuery("version"),
        ),
    ),
)
```

## Static Files

### Serve Directory

Serve static files from a directory:

```go
a.Static("/static", "./public")
// Files in ./public served at /static/*
```

### Serve Single File

Serve a single file at a specific path:

```go
a.File("/favicon.ico", "./static/favicon.ico")
a.File("/robots.txt", "./static/robots.txt")
```

### Serve from Filesystem

Serve files from an `http.FileSystem`:

```go
//go:embed static
var staticFiles embed.FS

a.StaticFS("/assets", http.FS(staticFiles))
```

## Route Naming

### Named Routes

Name routes for URL generation:

```go
a.GET("/users/:id", getUserHandler).Name("users.get")
a.POST("/users", createUserHandler).Name("users.create")
```

### Generate URLs

Generate URLs from route names:

```go
// After router is frozen (after a.Start())
url, err := a.URLFor("users.get", map[string]string{"id": "123"}, nil)
// Returns: "/users/123"

// With query parameters
url, err := a.URLFor("users.get", 
    map[string]string{"id": "123"},
    map[string][]string{"expand": {"profile"}},
)
// Returns: "/users/123?expand=profile"
```

### Must Generate URLs

Generate URLs and panic on error:

```go
url := a.MustURLFor("users.get", map[string]string{"id": "123"}, nil)
```

## Route Constraints

### Numeric Constraints

Constrain parameters to numeric values:

```go
a.GET("/users/:id", handler).WhereInt("id")
// Only matches /users/123, not /users/abc
```

### UUID Constraints

Constrain parameters to UUIDs:

```go
a.GET("/orders/:id", handler).WhereUUID("id")
// Only matches valid UUIDs
```

### Custom Constraints

Use regex patterns for custom constraints:

```go
a.GET("/posts/:slug", handler).Where("slug", `[a-z\-]+`)
// Only matches lowercase letters and hyphens
```

## Custom 404 Handler

### Set NoRoute Handler

Handle routes that don't match:

```go
a.NoRoute(func(c *app.Context) {
    c.JSON(http.StatusNotFound, map[string]string{
        "error": "route not found",
        "path": c.Request.URL.Path,
    })
})
```

## Complete Example

```go
package main

import (
    "log"
    "net/http"
    
    "rivaas.dev/app"
)

func main() {
    a := app.MustNew(
        app.WithServiceName("api"),
    )
    
    // Root routes
    a.GET("/", homeHandler)
    a.GET("/health", healthHandler)
    
    // API v1
    v1 := a.Group("/api/v1")
    v1.GET("/status", statusHandler)
    
    // Users
    users := v1.Group("/users")
    users.GET("", getUsersHandler).Name("users.list")
    users.POST("", createUserHandler).Name("users.create")
    users.GET("/:id", getUserHandler).Name("users.get").WhereInt("id")
    users.PUT("/:id", updateUserHandler).Name("users.update").WhereInt("id")
    users.DELETE("/:id", deleteUserHandler).Name("users.delete").WhereInt("id")
    
    // Admin routes with authentication
    admin := a.Group("/admin", AuthMiddleware())
    admin.GET("/dashboard", dashboardHandler)
    admin.GET("/users", adminGetUsersHandler)
    
    // Static files
    a.Static("/assets", "./public")
    a.File("/favicon.ico", "./public/favicon.ico")
    
    // Custom 404
    a.NoRoute(func(c *app.Context) {
        c.NotFound("route not found")
    })
    
    // Start server...
}
```

## Next Steps

- [Middleware](../middleware/) - Add middleware to routes and groups
- [Context](../context/) - Access route parameters and query strings
- [Examples](../examples/) - See complete working examples
