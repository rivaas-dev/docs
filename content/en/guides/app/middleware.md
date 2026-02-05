---
title: "Middleware"
linkTitle: "Middleware"
weight: 6
keywords:
  - app middleware
  - request handling
  - interceptors
  - cross-cutting concerns
  - middleware chain
description: >
  Add cross-cutting concerns with built-in and custom middleware.
---

## Overview

Middleware functions execute before and after route handlers. They add cross-cutting concerns like logging, authentication, and rate limiting.

The app package provides access to high-quality middleware from the `router/middleware` subpackages.

## Using Middleware

### Global Middleware

Apply middleware to all routes:

```go
a := app.MustNew()

a.Use(requestid.New())
a.Use(cors.New(cors.WithAllowAllOrigins(true)))

// All routes registered after Use() will have this middleware
a.GET("/users", handler)
a.POST("/orders", handler)
```

### Middleware During Initialization

Add middleware when creating the app:

```go
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithMiddleware(
        requestid.New(),
        cors.New(cors.WithAllowAllOrigins(true)),
    ),
)
```

### Default Middleware

The app package automatically includes recovery middleware by default in both development and production modes.

To disable default middleware:

```go
a, err := app.New(
    app.WithoutDefaultMiddleware(),
    app.WithMiddleware(myCustomRecovery), // Add your own
)
```

## Built-in Middleware

### Request ID

Generate unique request IDs for tracing:

```go
import "rivaas.dev/router/middleware/requestid"

a.Use(requestid.New())

// Access in handler
a.GET("/", func(c *app.Context) {
    reqID := c.Response.Header().Get("X-Request-ID")
    c.JSON(http.StatusOK, map[string]string{
        "request_id": reqID,
    })
})
```

**Options:**

```go
requestid.New(
    requestid.WithRequestIDHeader("X-Correlation-ID"),
    requestid.WithGenerator(customGenerator),
)
```

### CORS

Handle Cross-Origin Resource Sharing:

```go
import "rivaas.dev/router/middleware/cors"

// Allow all origins (development)
a.Use(cors.New(cors.WithAllowAllOrigins(true)))

// Specific origins (production)
a.Use(cors.New(
    cors.WithAllowedOrigins([]string{"https://example.com"}),
    cors.WithAllowCredentials(true),
    cors.WithAllowedMethods([]string{"GET", "POST", "PUT", "DELETE"}),
    cors.WithAllowedHeaders([]string{"Content-Type", "Authorization"}),
))
```

### Recovery

Recover from panics gracefully (included by default):

```go
import "rivaas.dev/router/middleware/recovery"

a.Use(recovery.New(
    recovery.WithStackTrace(true),
))
```

### Access Logging

Log HTTP requests (when not using app's built-in observability):

```go
import "rivaas.dev/router/middleware/accesslog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

a.Use(accesslog.New(
    accesslog.WithLogger(logger),
    accesslog.WithSkipPaths([]string{"/health", "/metrics"}),
))
```

**Note:** The app package automatically configures access logging through its unified observability when `WithLogging()` is used.

### Timeout

Add request timeout handling:

```go
import "rivaas.dev/router/middleware/timeout"

// Default timeout (30s)
a.Use(timeout.New())

// Custom timeout
a.Use(timeout.New(
    timeout.WithDuration(5 * time.Second),
    timeout.WithSkipPaths("/stream"),
    timeout.WithSkipPrefix("/admin"),
))
```

### Rate Limiting

Rate limit requests (single-instance only):

```go
import "rivaas.dev/router/middleware/ratelimit"

// 100 requests per minute
a.Use(ratelimit.New(100, time.Minute))
```

**Note:** This is in-memory rate limiting suitable for single-instance deployments only. For production with multiple instances, use a distributed rate limiting solution.

### Compression

Compress responses with gzip or brotli:

```go
import "rivaas.dev/router/middleware/compression"

a.Use(compression.New(
    compression.WithLevel(compression.BestSpeed),
    compression.WithMinSize(1024), // Only compress responses > 1KB
))
```

### Body Limit

Limit request body size:

```go
import "rivaas.dev/router/middleware/bodylimit"

a.Use(bodylimit.New(
    bodylimit.WithMaxBytes(5 << 20), // 5MB max
))
```

### Security Headers

Add security headers (HSTS, CSP, etc.):

```go
import "rivaas.dev/router/middleware/securityheaders"

a.Use(securityheaders.New(
    securityheaders.WithHSTS(true),
    securityheaders.WithContentSecurityPolicy("default-src 'self'"),
    securityheaders.WithXFrameOptions("DENY"),
))
```

### Basic Auth

HTTP Basic Authentication:

```go
import "rivaas.dev/router/middleware/basicauth"

a.Use(basicauth.New(
    basicauth.WithUsers(map[string]string{
        "admin": "password123",
    }),
    basicauth.WithRealm("Admin Area"),
))
```

## Custom Middleware

### Writing Custom Middleware

Create custom middleware as functions:

```go
func AuthMiddleware() app.HandlerFunc {
    return func(c *app.Context) {
        token := c.Request.Header.Get("Authorization")
        
        if token == "" {
            c.Unauthorized(fmt.Errorf("missing authorization token"))
            return
        }
        
        // Validate token...
        if !isValid(token) {
            c.Unauthorized(fmt.Errorf("invalid token"))
            return
        }
        
        // Continue to next middleware/handler
        c.Next()
    }
}

// Use it
a.Use(AuthMiddleware())
```

### Middleware with Configuration

Create configurable middleware:

```go
type AuthConfig struct {
    TokenHeader string
    SkipPaths   []string
}

func AuthWithConfig(config AuthConfig) app.HandlerFunc {
    return func(c *app.Context) {
        // Skip authentication for certain paths
        for _, path := range config.SkipPaths {
            if c.Request.URL.Path == path {
                c.Next()
                return
            }
        }
        
        token := c.Request.Header.Get(config.TokenHeader)
        
        if token == "" || !isValid(token) {
            c.Unauthorized(fmt.Errorf("authentication failed"))
            return
        }
        
        c.Next()
    }
}

// Use it
a.Use(AuthWithConfig(AuthConfig{
    TokenHeader: "X-API-Key",
    SkipPaths:   []string{"/health", "/public"},
}))
```

### Middleware with State

Share state across requests:

```go
type RateLimiter struct {
    requests map[string]int
    mu       sync.Mutex
}

func NewRateLimiter() *RateLimiter {
    return &RateLimiter{
        requests: make(map[string]int),
    }
}

func (rl *RateLimiter) Middleware() app.HandlerFunc {
    return func(c *app.Context) {
        clientIP := c.ClientIP()
        
        rl.mu.Lock()
        count := rl.requests[clientIP]
        rl.requests[clientIP]++
        rl.mu.Unlock()
        
        if count > 100 {
            c.Status(http.StatusTooManyRequests)
            return
        }
        
        c.Next()
    }
}

// Use it
limiter := NewRateLimiter()
a.Use(limiter.Middleware())
```

## Route-Specific Middleware

### Per-Route Middleware

Apply middleware to specific routes:

```go
// Using WithBefore option
a.GET("/admin", adminHandler,
    app.WithBefore(AuthMiddleware()),
)

// Multiple middleware
a.GET("/admin/users", handler,
    app.WithBefore(
        AuthMiddleware(),
        AdminOnlyMiddleware(),
    ),
)
```

### After Middleware

Execute middleware after the handler:

```go
a.GET("/orders/:id", handler,
    app.WithAfter(AuditLogMiddleware()),
)
```

### Combined Middleware

Combine before and after middleware:

```go
a.POST("/orders", handler,
    app.WithBefore(AuthMiddleware(), RateLimitMiddleware()),
    app.WithAfter(AuditLogMiddleware()),
)
```

## Group Middleware

Apply middleware to route groups:

```go
// Admin routes with auth middleware
admin := a.Group("/admin", AuthMiddleware(), AdminOnlyMiddleware())
admin.GET("/users", getUsersHandler)
admin.POST("/users", createUserHandler)

// API routes with rate limiting
api := a.Group("/api", RateLimitMiddleware())
api.GET("/status", statusHandler)
api.GET("/version", versionHandler)
```

## Middleware Execution Order

Middleware executes in the order it's registered:

```go
a.Use(Middleware1())  // Executes first
a.Use(Middleware2())  // Executes second
a.Use(Middleware3())  // Executes third

a.GET("/", handler)   // Handler executes last

// Execution order:
// 1. Middleware1
// 2. Middleware2
// 3. Middleware3
// 4. handler
// 5. Middleware3 (after c.Next())
// 6. Middleware2 (after c.Next())
// 7. Middleware1 (after c.Next())
```

## Complete Example

```go
package main

import (
    "log"
    "net/http"
    "time"
    
    "rivaas.dev/app"
    "rivaas.dev/router/middleware/requestid"
    "rivaas.dev/router/middleware/cors"
    "rivaas.dev/router/middleware/timeout"
)

func main() {
    a, err := app.New(
        app.WithServiceName("api"),
        app.WithMiddleware(
            requestid.New(),
            cors.New(cors.WithAllowAllOrigins(true)),
            timeout.New(timeout.WithDuration(30 * time.Second)),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Custom middleware
    a.Use(LoggingMiddleware())
    a.Use(AuthMiddleware())
    
    // Public routes (no auth)
    a.GET("/health", healthHandler)
    
    // Protected routes (with auth)
    a.GET("/users", usersHandler)
    
    // Admin routes (with auth + admin check)
    admin := a.Group("/admin", AdminOnlyMiddleware())
    admin.GET("/dashboard", dashboardHandler)
    
    // Start server...
}

func LoggingMiddleware() app.HandlerFunc {
    return func(c *app.Context) {
        start := time.Now()
        
        c.Next()
        
        duration := time.Since(start)
        c.Logger().Info("request completed",
            "method", c.Request.Method,
            "path", c.Request.URL.Path,
            "duration", duration,
        )
    }
}

func AuthMiddleware() app.HandlerFunc {
    return func(c *app.Context) {
        // Skip auth for health check
        if c.Request.URL.Path == "/health" {
            c.Next()
            return
        }
        
        token := c.Request.Header.Get("Authorization")
        if token == "" {
            c.Unauthorized(fmt.Errorf("missing authorization token"))
            return
        }
        
        c.Next()
    }
}

func AdminOnlyMiddleware() app.HandlerFunc {
    return func(c *app.Context) {
        // Check if user is admin...
        if !isAdmin() {
            c.Forbidden(fmt.Errorf("admin access required"))
            return
        }
        
        c.Next()
    }
}
```

## Next Steps

- [Routing](../routing/) - Organize routes with groups and versioning
- [Context](../context/) - Access request and response in middleware
- [Examples](../examples/) - See complete working examples
