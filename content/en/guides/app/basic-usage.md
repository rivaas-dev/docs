---
title: "Basic Usage"
linkTitle: "Basic Usage"
weight: 2
keywords:
  - app basic usage
  - getting started
  - hello world
  - create app
  - first app
description: >
  Learn the fundamentals of creating and running Rivaas applications.
---

## Creating an App

### Using New()

The recommended way to create an app is with `app.New()`. It returns an error if configuration is invalid.

```go
package main

import (
    "log"
    
    "rivaas.dev/app"
)

func main() {
    a, err := app.New()
    if err != nil {
        log.Fatalf("Failed to create app: %v", err)
    }
    
    // Use the app...
}
```

### Using MustNew()

For initialization code where errors should panic (like `main()` functions), use `app.MustNew()`:

```go
package main

import (
    "rivaas.dev/app"
)

func main() {
    a := app.MustNew(
        app.WithServiceName("my-api"),
        app.WithServiceVersion("v1.0.0"),
    )
    
    // Use the app...
}
```

`MustNew()` panics if configuration is invalid. It follows the Go idiom of `Must*` constructors like `regexp.MustCompile()`.

## Registering Routes

### Basic Routes

Register routes using HTTP method shortcuts.

```go
a.GET("/", func(c *app.Context) {
    c.JSON(http.StatusOK, map[string]string{
        "message": "Hello, World!",
    })
})

a.POST("/users", func(c *app.Context) {
    c.JSON(http.StatusCreated, map[string]string{
        "message": "User created",
    })
})

a.PUT("/users/:id", func(c *app.Context) {
    id := c.Param("id")
    c.JSON(http.StatusOK, map[string]string{
        "id": id,
        "message": "User updated",
    })
})

a.DELETE("/users/:id", func(c *app.Context) {
    c.Status(http.StatusNoContent)
})
```

### Path Parameters

Extract path parameters using `c.Param()`:

```go
a.GET("/users/:id", func(c *app.Context) {
    userID := c.Param("id")
    
    c.JSON(http.StatusOK, map[string]string{
        "user_id": userID,
    })
})

a.GET("/posts/:postID/comments/:commentID", func(c *app.Context) {
    postID := c.Param("postID")
    commentID := c.Param("commentID")
    
    c.JSON(http.StatusOK, map[string]string{
        "post_id": postID,
        "comment_id": commentID,
    })
})
```

### Query Parameters

Access query parameters using `c.Query()`:

```go
a.GET("/search", func(c *app.Context) {
    query := c.Query("q")
    page := c.QueryDefault("page", "1")
    
    c.JSON(http.StatusOK, map[string]string{
        "query": query,
        "page": page,
    })
})
```

### Wildcard Routes

Use wildcards to match remaining path segments:

```go
a.GET("/files/*filepath", func(c *app.Context) {
    filepath := c.Param("filepath")
    
    c.JSON(http.StatusOK, map[string]string{
        "filepath": filepath,
    })
})
```

## Request Handlers

### Handler Function Signature

Handlers receive an `*app.Context` which provides access to the request, response, and app features:

```go
func handler(c *app.Context) {
    // Access request
    method := c.Request.Method
    path := c.Request.URL.Path
    
    // Access parameters
    id := c.Param("id")
    query := c.Query("q")
    
    // Send response
    c.JSON(http.StatusOK, map[string]string{
        "method": method,
        "path": path,
        "id": id,
        "query": query,
    })
}

a.GET("/example/:id", handler)
```

### Organizing Handlers

For larger applications, organize handlers in separate files:

```go
// handlers/users.go
package handlers

import (
    "net/http"
    "rivaas.dev/app"
)

func GetUser(c *app.Context) {
    id := c.Param("id")
    // Fetch user from database...
    
    c.JSON(http.StatusOK, map[string]any{
        "id": id,
        "name": "John Doe",
    })
}

func CreateUser(c *app.Context) {
    var req struct {
        Name  string `json:"name"`
        Email string `json:"email"`
    }
    
    if !c.MustBind(&req) {
        return // Error response already sent
    }
    
    // Create user in database...
    
    c.JSON(http.StatusCreated, map[string]any{
        "id": "123",
        "name": req.Name,
        "email": req.Email,
    })
}
```

```go
// main.go
package main

import (
    "myapp/handlers"
    "rivaas.dev/app"
)

func main() {
    a := app.MustNew()
    
    a.GET("/users/:id", handlers.GetUser)
    a.POST("/users", handlers.CreateUser)
    
    // ...
}
```

## Response Rendering

### JSON Responses

Send JSON responses with `c.JSON()`:

```go
a.GET("/users", func(c *app.Context) {
    users := []map[string]string{
        {"id": "1", "name": "Alice"},
        {"id": "2", "name": "Bob"},
    }
    
    c.JSON(http.StatusOK, users)
})
```

### Status Codes

Set status without body using `c.Status()`:

```go
a.DELETE("/users/:id", func(c *app.Context) {
    id := c.Param("id")
    // Delete user from database...
    
    c.Status(http.StatusNoContent)
})
```

### String Responses

Send plain text responses:

```go
a.GET("/health", func(c *app.Context) {
    c.String(http.StatusOK, "OK")
})
```

### HTML Responses

Send HTML responses:

```go
a.GET("/", func(c *app.Context) {
    html := `
    <!DOCTYPE html>
    <html>
    <head><title>Welcome</title></head>
    <body><h1>Welcome to My App</h1></body>
    </html>
    `
    
    c.HTML(http.StatusOK, html)
})
```

## Running the Server

### HTTP Server

Start the HTTP server with graceful shutdown:

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
)

func main() {
    a := app.MustNew()
    
    // Register routes...
    a.GET("/", homeHandler)
    
    // Setup graceful shutdown
    ctx, cancel := signal.NotifyContext(
        context.Background(),
        os.Interrupt,
        syscall.SIGTERM,
    )
    defer cancel()
    
    // Start server
    log.Println("Server starting on :8080")
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatalf("Server error: %v", err)
    }
}
```

### Port Configuration

Specify different ports:

```go
// Development
a.Start(ctx, ":8080")

// Production
a.Start(ctx, ":80")

// Bind to specific interface
a.Start(ctx, "127.0.0.1:8080")

// Use environment variable
port := os.Getenv("PORT")
if port == "" {
    port = "8080"
}
a.Start(ctx, ":"+port)
```

## Complete Example

Here's a complete working example:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
)

func main() {
    // Create app
    a, err := app.New(
        app.WithServiceName("hello-api"),
        app.WithServiceVersion("v1.0.0"),
    )
    if err != nil {
        log.Fatalf("Failed to create app: %v", err)
    }
    
    // Home route
    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Welcome to Hello API",
            "version": "v1.0.0",
        })
    })
    
    // Greet route with parameter
    a.GET("/greet/:name", func(c *app.Context) {
        name := c.Param("name")
        
        c.JSON(http.StatusOK, map[string]string{
            "greeting": "Hello, " + name + "!",
        })
    })
    
    // Echo route with request body
    a.POST("/echo", func(c *app.Context) {
        var req map[string]any
        
        if !c.MustBind(&req) {
            return
        }
        
        c.JSON(http.StatusOK, req)
    })
    
    // Setup graceful shutdown
    ctx, cancel := signal.NotifyContext(
        context.Background(),
        os.Interrupt,
        syscall.SIGTERM,
    )
    defer cancel()
    
    // Start server
    log.Println("Server starting on :8080")
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}
```

Test the endpoints:

```bash
# Home route
curl http://localhost:8080/

# Greet route
curl http://localhost:8080/greet/Alice

# Echo route
curl -X POST http://localhost:8080/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, World!"}'
```

## Next Steps

- [Configuration](../configuration/) - Configure service name, environment, and server settings
- [Context](../context/) - Learn about request binding and validation
- [Routing](../routing/) - Organize routes with groups and middleware
- [Examples](../examples/) - Explore complete working examples
