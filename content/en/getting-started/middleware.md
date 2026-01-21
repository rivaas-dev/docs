---
title: Using Middleware
description: Add functionality to your application with middleware
weight: 4
keywords:
  - middleware
  - cors
  - authentication
  - request handling
  - interceptors
  - http middleware
---

Middleware functions intercept HTTP requests. They add functionality like logging, authentication, and error recovery to your Rivaas application.

## What is Middleware?

Middleware wraps your route handlers. It runs code before and after the handler. Think of it as layers around your core logic:

```
Request → Middleware 1 → Middleware 2 → Handler → Middleware 2 → Middleware 1 → Response
```

Common uses:
- Log requests and responses
- Authenticate and authorize users
- Recover from errors
- Modify requests and responses
- Limit request rates
- Add CORS headers

## Built-in Middleware

Rivaas includes 12 production-ready middleware packages:

| Middleware | Purpose | Production-Ready |
|------------|---------|------------------|
| `recovery` | Panic recovery | ✅ Auto-included |
| `requestid` | Request ID tracking | ✅ |
| `cors` | Cross-Origin Resource Sharing | ✅ |
| `timeout` | Request timeouts | ✅ |
| `accesslog` | Access logging | ✅ |
| `ratelimit` | Rate limiting | ⚠️ Single-instance only |
| `basicauth` | HTTP Basic Auth | ✅ |
| `bodylimit` | Request size limits | ✅ |
| `compression` | Response compression | ✅ |
| `security` | Security headers | ✅ |
| `methodoverride` | HTTP method override | ✅ |
| `trailingslash` | Trailing slash handling | ✅ |

Check the [Middleware Reference](/reference/packages/router/middleware/) for complete documentation.

## Adding Middleware

### Global Middleware

Apply middleware to all routes:

```go
import (
    "rivaas.dev/app"
    "rivaas.dev/router/middleware/requestid"
    "rivaas.dev/router/middleware/cors"
)

func main() {
    a, err := app.New()
    if err != nil {
        log.Fatal(err)
    }

    // Add middleware before registering routes
    a.Use(requestid.New())
    a.Use(cors.New(cors.WithAllowAllOrigins(true)))

    // Register routes
    a.GET("/", handleRoot)
    
    // Start server
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()
    a.Start(ctx, ":8080")
}
```

### Group Middleware

Apply middleware to specific route groups:

```go
// Public routes - no auth
a.GET("/", handlePublic)

// API routes - with auth
api := a.Group("/api", authMiddleware)
api.GET("/users", getUsers)
api.POST("/users", createUser)

// Admin routes - with admin auth
admin := a.Group("/admin", authMiddleware, adminMiddleware)
admin.GET("/dashboard", getDashboard)
```

### Route-Specific Middleware

Apply middleware to individual routes:

```go
a.GET("/public", publicHandler)
a.GET("/protected", protectedHandler, authMiddleware)
```

## Common Middleware Patterns

### Request ID

Track requests across distributed systems:

```go
import "rivaas.dev/router/middleware/requestid"

a.Use(requestid.New())

// In your handler
a.GET("/", func(c *app.Context) {
    reqID := c.Response.Header().Get("X-Request-ID")
    c.JSON(http.StatusOK, map[string]string{
        "request_id": reqID,
    })
})
```

**Test it:**

```bash
curl -i http://localhost:8080/
# X-Request-ID: 550e8400-e29b-41d4-a716-446655440000
```

### CORS

Enable cross-origin requests:

```go
import "rivaas.dev/router/middleware/cors"

// Development: Allow all origins
a.Use(cors.New(cors.WithAllowAllOrigins(true)))

// Production: Specific origins
a.Use(cors.New(
    cors.WithAllowedOrigins([]string{
        "https://example.com",
        "https://app.example.com",
    }),
    cors.WithAllowedMethods([]string{"GET", "POST", "PUT", "DELETE"}),
    cors.WithAllowCredentials(true),
))
```

### Timeout

Prevent long-running requests:

```go
import "rivaas.dev/router/middleware/timeout"

// Global timeout
a.Use(timeout.New(timeout.WithDuration(5 * time.Second)))

// Skip for streaming endpoints
a.Use(timeout.New(
    timeout.WithDuration(5 * time.Second),
    timeout.WithSkipPaths("/stream", "/sse"),
))
```

### Recovery

Automatically recover from panics (included by default):

```go
import "rivaas.dev/router/middleware/recovery"

// Custom recovery with stack traces
a.Use(recovery.New(
    recovery.WithStackTrace(true),
    recovery.WithHandler(func(c *router.Context, err any) {
        log.Printf("Panic recovered: %v", err)
        c.JSON(http.StatusInternalServerError, map[string]string{
            "error": "Internal server error",
        })
    }),
))
```

### Rate Limiting

Limit request rate (single-instance only):

```go
import "rivaas.dev/router/middleware/ratelimit"

// 100 requests per second with burst of 20
a.Use(ratelimit.New(
    ratelimit.WithRequestsPerSecond(100),
    ratelimit.WithBurst(20),
))
```

{{< alert title="Production Note" color="warning" >}}
This uses in-memory storage. For multi-instance deployments, use a distributed rate limiter (Redis, etc.).
{{< /alert >}}

## Middleware Execution Order

Middleware executes in the order it's registered:

```go
a.Use(middleware1)  // Executes first
a.Use(middleware2)  // Executes second
a.Use(middleware3)  // Executes third

a.GET("/", handler) // Executes last (if all middleware calls Next())
```

**Example Flow:**

```
Request
  → middleware1 (before)
    → middleware2 (before)
      → middleware3 (before)
        → handler
      ← middleware3 (after)
    ← middleware2 (after)
  ← middleware1 (after)
Response
```

**Best Practices:**
1. **Recovery** should be first (catches panics from other middleware)
2. **Logging** early (captures all requests)
3. **Auth** before business logic
4. **CORS** early (handles preflight requests)

**Example:**

```go
a.Use(recovery.New())    // 1. Panic recovery
a.Use(requestid.New())   // 2. Request tracking
a.Use(cors.New(...))     // 3. CORS handling
// App-level observability is automatic
// Route handlers execute last
```

## Creating Custom Middleware

Simple middleware example:

```go
func timingMiddleware() app.HandlerFunc {
    return func(c *app.Context) {
        start := time.Now()
        
        // Process request (call next middleware/handler)
        c.Next()
        
        // After handler executes
        duration := time.Since(start)
        log.Printf("%s %s - %v", c.Request.Method, c.Request.URL.Path, duration)
    }
}

// Use it
a.Use(timingMiddleware())
```

**Authentication middleware example:**

```go
func authMiddleware(c *app.Context) {
    token := c.Request.Header.Get("Authorization")
    
    if token == "" {
        c.JSON(http.StatusUnauthorized, map[string]string{
            "error": "Missing authorization token",
        })
        return  // Don't call Next() - stop here
    }
    
    // Validate token (simplified)
    if !isValidToken(token) {
        c.JSON(http.StatusUnauthorized, map[string]string{
            "error": "Invalid token",
        })
        return
    }
    
    // Token is valid - continue to handler
    c.Next()
}

// Use it
api := a.Group("/api", authMiddleware)
```

## Middleware with Configuration

Use functional options for configurable middleware:

```go
type Config struct {
    MaxRequests int
    Window      time.Duration
}

type Option func(*Config)

func WithMaxRequests(max int) Option {
    return func(c *Config) {
        c.MaxRequests = max
    }
}

func New(opts ...Option) app.HandlerFunc {
    cfg := &Config{
        MaxRequests: 100,
        Window:      time.Minute,
    }
    
    for _, opt := range opts {
        opt(cfg)
    }
    
    return func(c *app.Context) {
        // Use cfg.MaxRequests, cfg.Window
        c.Next()
    }
}

// Use it
a.Use(New(
    WithMaxRequests(200),
))
```

## Default Middleware

Rivaas automatically includes some middleware based on environment:

**Development Mode:**
- ✅ Recovery middleware (panic recovery)
- ✅ Access logging via observability recorder

**Production Mode:**
- ✅ Recovery middleware
- ✅ Error-only logging via observability recorder

**Disable defaults:**

```go
a, err := app.New(
    app.WithMiddleware(), // Empty = no defaults
)
// Now add only what you need
a.Use(recovery.New())
a.Use(requestid.New())
```

## Complete Example

Here's a production-ready middleware setup:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "rivaas.dev/app"
    "rivaas.dev/router/middleware/cors"
    "rivaas.dev/router/middleware/recovery"
    "rivaas.dev/router/middleware/requestid"
    "rivaas.dev/router/middleware/timeout"
)

func main() {
    a, err := app.New(
        app.WithServiceName("my-api"),
        app.WithEnvironment("production"),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Global middleware (order matters!)
    a.Use(recovery.New(recovery.WithStackTrace(true)))
    a.Use(requestid.New())
    a.Use(cors.New(cors.WithAllowedOrigins([]string{"https://example.com"})))
    a.Use(timeout.New(timeout.WithDuration(30 * time.Second)))

    // Public routes
    a.GET("/", handlePublic)
    a.GET("/health", handleHealth)

    // Protected API
    api := a.Group("/api", authMiddleware)
    api.GET("/users", getUsers)
    api.POST("/users", createUser)

    // Admin routes
    admin := a.Group("/admin", authMiddleware, adminMiddleware)
    admin.GET("/dashboard", getDashboard)

    // Start server
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}

func handlePublic(c *app.Context) {
    c.JSON(http.StatusOK, map[string]string{"status": "ok"})
}

func handleHealth(c *app.Context) {
    c.JSON(http.StatusOK, map[string]string{"status": "healthy"})
}

func authMiddleware(c *app.Context) {
    token := c.Request.Header.Get("Authorization")
    if token == "" || !isValidToken(token) {
        c.JSON(http.StatusUnauthorized, map[string]string{"error": "Unauthorized"})
        return
    }
    c.Next()
}

func adminMiddleware(c *app.Context) {
    // Check if user is admin (simplified)
    if !isAdmin(c.Request.Header.Get("Authorization")) {
        c.JSON(http.StatusForbidden, map[string]string{"error": "Forbidden"})
        return
    }
    c.Next()
}

func getUsers(c *app.Context) {
    c.JSON(http.StatusOK, []string{"user1", "user2"})
}

func createUser(c *app.Context) {
    c.JSON(http.StatusCreated, map[string]string{"status": "created"})
}

func getDashboard(c *app.Context) {
    c.JSON(http.StatusOK, map[string]string{"dashboard": "data"})
}

func isValidToken(token string) bool {
    // Implement your token validation
    return token != ""
}

func isAdmin(token string) bool {
    // Implement your admin check
    return true
}
```

## Troubleshooting

### Middleware Not Executing

**Problem:** Middleware doesn't run.

**Solutions:**
- Ensure middleware is added **before** routes: `a.Use(...)` then `a.GET(...)`
- Check if middleware calls `c.Next()` to continue the chain
- Verify middleware isn't returning early without calling `c.Next()`

### Middleware Running in Wrong Order

**Problem:** Authentication runs after handler.

**Solution:** Add middleware in the correct order - they execute top to bottom:

```go
a.Use(recovery.New())  // First
a.Use(authMiddleware)  // Second
a.GET("/", handler)    // Last
```

### CORS Preflight Failing

**Problem:** OPTIONS requests return 404.

**Solution:** Add CORS middleware before routes, and ensure it handles OPTIONS:

```go
a.Use(cors.New(
    cors.WithAllowedMethods([]string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}),
))
```

## Next Steps

- **[Complete Configuration →](../configuration/)** — Advanced configuration options
- **[Next Steps →](../next-steps/)** — Continue your learning journey
- **[Middleware Reference →](/reference/packages/router/middleware/)** — All 12 middleware with examples
- **[Router Middleware Guide →](/guides/router/middleware/)** — Build your own middleware

## Learn More

- [Middleware Catalog](https://github.com/rivaas-dev/rivaas/tree/main/router/middleware) — Source code and tests
- [Middleware Examples](https://github.com/rivaas-dev/rivaas/tree/main/router/middleware/examples) — Working examples with curl commands

