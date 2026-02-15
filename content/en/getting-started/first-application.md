---
title: Your First Application
description: Build a complete REST API quickly
weight: 2
keywords:
  - first application
  - hello world
  - tutorial
  - beginner
  - rest api
  - getting started
---

Build a simple REST API to learn Rivaas basics. You'll create a working application with multiple routes, JSON responses, and graceful shutdown.

## Create Your Project

Create a new directory and initialize a Go module:

```bash
mkdir hello-rivaas
cd hello-rivaas
go mod init example.com/hello-rivaas
```

## Install Rivaas

```bash
go get rivaas.dev/app
```

## Write Your Application

Create a file named `main.go`:

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
    // Create a new Rivaas application
    a := app.MustNew(
        app.WithServiceName("hello-rivaas"),
        app.WithServiceVersion("v1.0.0"),
    )

    // Define routes
    a.GET("/", handleRoot)
    a.GET("/hello/:name", handleHello)
    a.POST("/echo", handleEcho)

    // Setup graceful shutdown
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    // Start the server
    log.Println("🚀 Starting server on http://localhost:8080")
    if err := a.Start(ctx); err != nil {
        log.Fatal(err)
    }
}

// handleRoot returns a welcome message
func handleRoot(c *app.Context) {
    c.JSON(http.StatusOK, map[string]string{
        "message": "Welcome to Rivaas!",
        "version": "v1.0.0",
    })
}

// handleHello greets a user by name
func handleHello(c *app.Context) {
    name := c.Param("name")
    c.JSON(http.StatusOK, map[string]string{
        "message": "Hello, " + name + "!",
    })
}

// handleEcho echoes back the request body
func handleEcho(c *app.Context) {
    var body map[string]any
    if err := c.Bind(&body); err != nil {
        c.JSON(http.StatusBadRequest, map[string]string{
            "error": "Invalid JSON",
        })
        return
    }

    c.JSON(http.StatusOK, map[string]any{
        "echo": body,
    })
}
```

## Run Your Application

Start the server:

```bash
go run main.go
```

You should see output like:

```
🚀 Starting server on http://localhost:8080
```

## Test Your API

Open a new terminal and test the endpoints:

### Test the root endpoint

```bash
curl http://localhost:8080/
```

Response:
```json
{
  "message": "Welcome to Rivaas!",
  "version": "v1.0.0"
}
```

### Test the greeting endpoint

```bash
curl http://localhost:8080/hello/World
```

Response:
```json
{
  "message": "Hello, World!"
}
```

### Test the echo endpoint

```bash
curl -X POST http://localhost:8080/echo \
  -H "Content-Type: application/json" \
  -d '{"name": "Rivaas", "type": "framework"}'
```

Response:
```json
{
  "echo": {
    "name": "Rivaas",
    "type": "framework"
  }
}
```

## Understanding the Code

Here's what each part does:

### 1. Creating the Application

```go
a := app.MustNew(
    app.WithServiceName("hello-rivaas"),
    app.WithServiceVersion("v1.0.0"),
)
```

- `MustNew()` creates a new application. Panics on error. Use in `main()` functions.
- `WithServiceName()` sets the service name.
- `WithServiceVersion()` sets the version.

### 2. Defining Routes

```go
a.GET("/", handleRoot)
a.GET("/hello/:name", handleHello)
a.POST("/echo", handleEcho)
```

- `GET()` and `POST()` register route handlers.
- `:name` is a path parameter. Access it with `c.Param("name")`.
- Handler functions receive an `*app.Context` with all request data.

### 3. Graceful Shutdown

```go
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()

if err := a.Start(ctx); err != nil {
    log.Fatal(err)
}
```

- `signal.NotifyContext()` creates a context that cancels on SIGINT (Ctrl+C) or SIGTERM.
- `Start()` starts the server and blocks until the context is canceled.
- The server shuts down gracefully. It finishes active requests before stopping.

### 4. Handler Functions

```go
func handleRoot(c *app.Context) {
    c.JSON(http.StatusOK, map[string]string{
        "message": "Welcome to Rivaas!",
    })
}
```

- Handlers receive an `*app.Context`.
- `c.JSON()` sends a JSON response.
- `c.Param()` gets path parameters.
- `c.Bind()` parses request bodies. It auto-detects JSON, form, and other formats.

## Common Patterns

### Path Parameters

```go
// Route: /users/:id/posts/:postId
a.GET("/users/:id/posts/:postId", func(c *app.Context) {
    userID := c.Param("id")
    postID := c.Param("postId")
    
    c.JSON(http.StatusOK, map[string]string{
        "user_id": userID,
        "post_id": postID,
    })
})
```

### Query Parameters

```go
// Route: /search?q=rivaas&limit=10
a.GET("/search", func(c *app.Context) {
    query := c.Query("q")
    limit := c.QueryDefault("limit", "20")
    
    c.JSON(http.StatusOK, map[string]string{
        "query": query,
        "limit": limit,
    })
})
```

### Request Headers

```go
a.GET("/headers", func(c *app.Context) {
    userAgent := c.Request.Header.Get("User-Agent")
    
    c.JSON(http.StatusOK, map[string]string{
        "user_agent": userAgent,
    })
})
```

### Different Status Codes

```go
a.GET("/not-found", func(c *app.Context) {
    c.JSON(http.StatusNotFound, map[string]string{
        "error": "Resource not found",
    })
})

a.POST("/created", func(c *app.Context) {
    c.JSON(http.StatusCreated, map[string]string{
        "message": "Resource created",
    })
})
```

## Testing Your Application

Rivaas provides testing utilities for integration tests:

```go
package main

import (
    "net/http"
    "net/http/httptest"
    "testing"

    "rivaas.dev/app"
)

func TestHelloEndpoint(t *testing.T) {
    // Create test app
    a, err := app.New()
    if err != nil {
        t.Fatalf("Failed to create app: %v", err)
    }

    a.GET("/hello/:name", handleHello)

    // Create test request
    req := httptest.NewRequest(http.MethodGet, "/hello/Gopher", nil)
    
    // Test the request
    resp, err := a.Test(req)
    if err != nil {
        t.Fatalf("Request failed: %v", err)
    }
    defer resp.Body.Close()

    // Check status code
    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }
}
```

**Key Testing Methods:**

- `a.Test(req)` - Execute a request without starting the server
- `a.TestJSON(method, path, body)` - Test JSON endpoints
- `app.ExpectJSON(t, resp, status, target)` - Verify JSON responses

See the [blog example](https://github.com/rivaas-dev/rivaas/tree/main/app/examples/02-blog) for comprehensive testing patterns.

## Common Mistakes

### Forgetting Error Handling

```go
// ❌ Bad: Ignoring errors
a := app.MustNew()  // Panics on error

// ✅ Good: Handle errors properly
a, err := app.New()
if err != nil {
    log.Fatalf("Failed to create app: %v", err)
}
```

### Not Using Context for Shutdown

```go
// ❌ Bad: No graceful shutdown
a.Start(context.Background(), ":8080")

// ✅ Good: Graceful shutdown with signals
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()
a.Start(ctx)
```

### Registering Routes After Start

```go
// ❌ Bad: Routes registered after Start
a.Start(ctx)
a.GET("/late", handler)  // Won't work!

// ✅ Good: Routes before Start
a.GET("/early", handler)
a.Start(ctx)
```

## Production Basics

Before deploying your first application:

- ✅ Use environment-based configuration (see [Configuration](../configuration/))
- ✅ Add health endpoints for Kubernetes/Docker
- ✅ Enable structured logging
- ✅ Set appropriate timeouts
- ✅ Add recovery middleware (included by default)

**Quick Production Setup:**

```go
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithServiceVersion("v1.0.0"),
    app.WithEnvironment("production"),
    app.WithHealthEndpoints(
        app.WithReadinessCheck("ready", func(ctx context.Context) error {
            return nil // Add real checks here
        }),
    ),
)
```

See the [full-featured example](https://github.com/rivaas-dev/rivaas/tree/main/app/examples/02-blog) for production patterns.

## What's Next?

You now have a working Rivaas application. Here are the next steps:

- **[Configuration](../configuration/)** — Learn configuration options
- **[Middleware](../middleware/)** — Add middleware for logging, CORS, etc.
- **[Routing Guide](/guides/router/)** — Advanced routing patterns
- **[Observability Guide](/guides/app/observability/)** — Add logging, metrics, and tracing

## Complete Example

The complete code is available in the [examples repository](https://github.com/rivaas-dev/rivaas/tree/main/app/examples/01-quick-start).

## Troubleshooting

### Port Already in Use

If you see "address already in use":

```bash
# Find what's using port 8080
lsof -i :8080

# Kill the process or use a different port
```

Change the port when creating the app:
```go
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithPort(3000),  // Use port 3000 instead of default 8080
)
// ...
a.Start(ctx)
```

### JSON Binding Errors

If `Bind()` fails for JSON requests, ensure:
1. Content-Type header is set to `application/json`
2. Request body contains valid JSON
3. JSON structure matches your Go struct

**Ready to learn more?** Continue to [Configuration →](../configuration/)

