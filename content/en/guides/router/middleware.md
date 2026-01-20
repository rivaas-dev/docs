---
title: "Middleware"
linkTitle: "Middleware"
weight: 50
description: >
  Add cross-cutting concerns like logging, authentication, and error handling with middleware.
---

Middleware functions execute before route handlers. They perform cross-cutting concerns like authentication, logging, and rate limiting.

## Basic Usage

Middleware is a function that wraps your handlers:

```go
func Logger() router.HandlerFunc {
    return func(c *router.Context) {
        start := time.Now()
        path := c.Request.URL.Path
        
        c.Next() // Continue to next handler
        
        duration := time.Since(start)
        fmt.Printf("[%s] %s - %v\n", c.Request.Method, path, duration)
    }
}

func main() {
    r := router.MustNew()
    
    // Apply middleware globally
    r.Use(Logger())
    
    r.GET("/", handler)
    http.ListenAndServe(":8080", r)
}
```

**Key concepts:**

- `c.Next()` - Continues to the next middleware or handler.
- Call `c.Next()` to proceed. Don't call it to stop the chain.
- Middleware runs in registration order.

## Middleware Scope

### Global Middleware

Applied to all routes:

```go
r := router.MustNew()

// These apply to ALL routes
r.Use(Logger())
r.Use(Recovery())
r.Use(CORS())

r.GET("/", handler)
r.GET("/users", usersHandler)
```

### Group Middleware

Applied only to routes in a group:

```go
r := router.MustNew()
r.Use(Logger()) // Global

// Public routes - no auth
public := r.Group("/api/public")
public.GET("/status", statusHandler)

// Private routes - auth required
private := r.Group("/api/private")
private.Use(AuthRequired()) // Group-level
private.GET("/profile", profileHandler)
```

### Route-Specific Middleware

Applied to individual routes:

```go
r := router.MustNew()
r.Use(Logger()) // Global

// Auth only for this route
r.GET("/admin", AdminAuth(), adminHandler)

// Multiple middleware for one route
r.POST("/upload", RateLimit(), ValidateFile(), uploadHandler)
```

## Built-in Middleware

The router includes production-ready middleware in sub-packages. See the [Middleware Reference](/reference/packages/router/middleware/) for complete options.

### Security

#### Security Headers

```go
import "rivaas.dev/router/middleware/security"

r.Use(security.New(
    security.WithHSTS(true),
    security.WithFrameDeny(true),
    security.WithContentTypeNosniff(true),
))
```

#### CORS

```go
import "rivaas.dev/router/middleware/cors"

r.Use(cors.New(
    cors.WithAllowedOrigins("https://example.com"),
    cors.WithAllowedMethods("GET", "POST", "PUT", "DELETE"),
    cors.WithAllowedHeaders("Content-Type", "Authorization"),
    cors.WithAllowCredentials(true),
))
```

#### Basic Auth

```go
import "rivaas.dev/router/middleware/basicauth"

admin := r.Group("/admin")
admin.Use(basicauth.New(
    basicauth.WithCredentials("admin", "secret"),
))
```

### Observability

#### Access Log

```go
import (
    "log/slog"
    "rivaas.dev/router/middleware/accesslog"
)

logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
r.Use(accesslog.New(
    accesslog.WithLogger(logger),
    accesslog.WithExcludePaths("/health", "/metrics"),
    accesslog.WithSlowThreshold(500 * time.Millisecond),
))
```

#### Request ID

```go
import "rivaas.dev/router/middleware/requestid"

r.Use(requestid.New(
    requestid.WithHeader("X-Request-ID"),
    requestid.WithGenerator(requestid.UUIDGenerator),
))

// Later in handlers:
func handler(c *router.Context) {
    id := requestid.Get(c)
    fmt.Println("Request ID:", id)
}
```

### Reliability

#### Recovery

```go
import "rivaas.dev/router/middleware/recovery"

r.Use(recovery.New(
    recovery.WithPrintStack(true),
    recovery.WithLogger(logger),
))
```

#### Timeout

```go
import "rivaas.dev/router/middleware/timeout"

r.Use(timeout.New(
    timeout.WithDuration(30 * time.Second),
    timeout.WithMessage("Request timeout"),
))
```

#### Rate Limit

```go
import "rivaas.dev/router/middleware/ratelimit"

r.Use(ratelimit.New(
    ratelimit.WithRequestsPerSecond(1000),
    ratelimit.WithBurst(100),
    ratelimit.WithKeyFunc(func(c *router.Context) string {
        return c.ClientIP() // Rate limit by IP
    }),
))
```

#### Body Limit

```go
import "rivaas.dev/router/middleware/bodylimit"

r.Use(bodylimit.New(
    bodylimit.WithLimit(10 * 1024 * 1024), // 10MB
))
```

### Performance

#### Compression

```go
import "rivaas.dev/router/middleware/compression"

r.Use(compression.New(
    compression.WithLevel(compression.DefaultCompression),
    compression.WithMinSize(1024), // Don't compress <1KB
))
```

## Middleware Ordering

The order in which middleware is applied matters. Recommended order:

```go
r := router.MustNew()

// 1. Request ID - Generate early for logging/tracing
r.Use(requestid.New())

// 2. AccessLog - Log all requests including failed ones
r.Use(accesslog.New())

// 3. Recovery - Catch panics from all other middleware
r.Use(recovery.New())

// 4. Security/CORS - Set security headers early
r.Use(security.New())
r.Use(cors.New())

// 5. Body Limit - Reject large requests before processing
r.Use(bodylimit.New())

// 6. Rate Limit - Reject excessive requests before processing
r.Use(ratelimit.New())

// 7. Timeout - Set time limits for downstream processing
r.Use(timeout.New())

// 8. Authentication - Verify identity after rate limiting
r.Use(auth.New())

// 9. Compression - Compress responses (last)
r.Use(compression.New())

// 10. Your application routes
r.GET("/", handler)
```

**Why this order?**

1. **RequestID first** - Generates a unique ID that other middleware can use
2. **Logger early** - Captures all activity including errors
3. **Recovery early** - Catches panics to prevent crashes
4. **Security/CORS** - Applies security policies before business logic
5. **BodyLimit** - Prevents reading excessive request bodies (DoS protection)
6. **RateLimit** - Blocks excessive requests before expensive operations
7. **Timeout** - Sets deadlines for request processing
8. **Auth** - Authenticates after rate limiting but before business logic
9. **Compression** - Compresses response bodies (should be last)

## Writing Custom Middleware

### Basic Middleware Pattern

```go
func MyMiddleware() router.HandlerFunc {
    return func(c *router.Context) {
        // Before request processing
        fmt.Println("Before handler")
        
        c.Next() // Execute next middleware/handler
        
        // After request processing
        fmt.Println("After handler")
    }
}
```

### Middleware with Configuration

```go
func RateLimit(requestsPerSecond int) router.HandlerFunc {
    // Setup (runs once when middleware is created)
    limiter := rate.NewLimiter(rate.Limit(requestsPerSecond), requestsPerSecond)
    
    return func(c *router.Context) {
        // Per-request logic
        if !limiter.Allow() {
            c.JSON(429, map[string]string{
                "error": "Too many requests",
            })
            return // Don't call c.Next() - stop the chain
        }
        c.Next()
    }
}

// Usage
r.Use(RateLimit(100)) // 100 requests per second
```

### Middleware with Dependencies

```go
func Auth(db *Database) router.HandlerFunc {
    return func(c *router.Context) {
        token := c.Request.Header.Get("Authorization")
        
        user, err := db.ValidateToken(token)
        if err != nil {
            c.JSON(401, map[string]string{
                "error": "Unauthorized",
            })
            return
        }
        
        // Store user in request context for handlers
        ctx := context.WithValue(c.Request.Context(), "user", user)
        c.Request = c.Request.WithContext(ctx)
        c.Next()
    }
}

// Usage
db := NewDatabase()
r.Use(Auth(db))
```

### Conditional Middleware

```go
func ConditionalAuth() router.HandlerFunc {
    return func(c *router.Context) {
        // Skip auth for public endpoints
        if c.Request.URL.Path == "/public" {
            c.Next()
            return
        }
        
        // Require auth for other endpoints
        token := c.Request.Header.Get("Authorization")
        if token == "" {
            c.JSON(401, map[string]string{
                "error": "Unauthorized",
            })
            return
        }
        
        c.Next()
    }
}
```

## Middleware Patterns

### Pattern: Error Handling Middleware

```go
func ErrorHandler() router.HandlerFunc {
    return func(c *router.Context) {
        defer func() {
            if err := recover(); err != nil {
                log.Printf("Panic: %v", err)
                c.JSON(500, map[string]string{
                    "error": "Internal server error",
                })
            }
        }()
        
        c.Next()
    }
}
```

### Pattern: Logging Middleware

```go
func Logger() router.HandlerFunc {
    return func(c *router.Context) {
        start := time.Now()
        path := c.Request.URL.Path
        method := c.Request.Method
        
        c.Next()
        
        duration := time.Since(start)
        status := c.Writer.Status()
        
        log.Printf("[%s] %s %s - %d (%v)",
            method,
            path,
            c.ClientIP(),
            status,
            duration,
        )
    }
}
```

### Pattern: Authentication Middleware

```go
func JWTAuth(secret string) router.HandlerFunc {
    return func(c *router.Context) {
        authHeader := c.Request.Header.Get("Authorization")
        if authHeader == "" {
            c.JSON(401, map[string]string{
                "error": "Missing authorization header",
            })
            return
        }
        
        // Extract token (Bearer <token>)
        parts := strings.SplitN(authHeader, " ", 2)
        if len(parts) != 2 || parts[0] != "Bearer" {
            c.JSON(401, map[string]string{
                "error": "Invalid authorization header format",
            })
            return
        }
        
        token := parts[1]
        claims, err := validateJWT(token, secret)
        if err != nil {
            c.JSON(401, map[string]string{
                "error": "Invalid token",
            })
            return
        }
        
        // Store claims in request context
        ctx := c.Request.Context()
        ctx = context.WithValue(ctx, "user_id", claims.UserID)
        ctx = context.WithValue(ctx, "user_email", claims.Email)
        c.Request = c.Request.WithContext(ctx)
        c.Next()
    }
}
```

### Pattern: Request ID Middleware

```go
func RequestID() router.HandlerFunc {
    return func(c *router.Context) {
        // Check for existing request ID
        requestID := c.Request.Header.Get("X-Request-ID")
        if requestID == "" {
            // Generate new UUID
            requestID = uuid.New().String()
        }
        
        // Store in request context and response header
        ctx := context.WithValue(c.Request.Context(), "request_id", requestID)
        c.Request = c.Request.WithContext(ctx)
        c.Header("X-Request-ID", requestID)
        
        c.Next()
    }
}
```

## Best Practices

### 1. Always Call `c.Next()`

Unless you want to stop the middleware chain:

```go
// ✅ GOOD: Calls c.Next() to continue
func Logger() router.HandlerFunc {
    return func(c *router.Context) {
        start := time.Now()
        c.Next() // Continue to handler
        duration := time.Since(start)
        log.Printf("Duration: %v", duration)
    }
}

// ✅ GOOD: Doesn't call c.Next() to stop chain
func Auth() router.HandlerFunc {
    return func(c *router.Context) {
        if !isAuthorized(c) {
            c.JSON(401, map[string]string{"error": "Unauthorized"})
            return // Don't call c.Next()
        }
        c.Next()
    }
}
```

### 2. Keep Middleware Focused

Each middleware should do one thing:

```go
// ✅ GOOD: Single responsibility
func Logger() router.HandlerFunc { ... }
func Auth() router.HandlerFunc { ... }
func RateLimit() router.HandlerFunc { ... }

// ❌ BAD: Does too much
func SuperMiddleware() router.HandlerFunc {
    return func(c *router.Context) {
        // Logging
        // Auth
        // Rate limiting
        // ...
        c.Next()
    }
}
```

### 3. Use Functional Options for Configuration

```go
type Config struct {
    Limit int
    Burst int
}

type Option func(*Config)

func WithLimit(limit int) Option {
    return func(c *Config) {
        c.Limit = limit
    }
}

func WithBurst(burst int) Option {
    return func(c *Config) {
        c.Burst = burst
    }
}

func RateLimit(opts ...Option) router.HandlerFunc {
    config := &Config{
        Limit: 100,
        Burst: 10,
    }
    for _, opt := range opts {
        opt(config)
    }
    
    limiter := rate.NewLimiter(rate.Limit(config.Limit), config.Burst)
    
    return func(c *router.Context) {
        if !limiter.Allow() {
            c.JSON(429, map[string]string{"error": "Too many requests"})
            return
        }
        c.Next()
    }
}

// Usage
r.Use(RateLimit(
    WithLimit(1000),
    WithBurst(100),
))
```

### 4. Handle Errors Gracefully

```go
func Middleware() router.HandlerFunc {
    return func(c *router.Context) {
        if err := doSomething(c); err != nil {
            // Log error
            log.Printf("Middleware error: %v", err)
            
            // Return error response
            c.JSON(500, map[string]string{
                "error": "Internal server error",
            })
            return // Don't call c.Next()
        }
        c.Next()
    }
}
```

## Complete Example

```go
package main

import (
    "fmt"
    "log"
    "log/slog"
    "net/http"
    "os"
    "time"
    
    "rivaas.dev/router"
    "rivaas.dev/router/middleware/accesslog"
    "rivaas.dev/router/middleware/cors"
    "rivaas.dev/router/middleware/recovery"
    "rivaas.dev/router/middleware/requestid"
    "rivaas.dev/router/middleware/security"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    r := router.MustNew()
    
    // Global middleware (applies to all routes)
    r.Use(requestid.New())
    r.Use(accesslog.New(accesslog.WithLogger(logger)))
    r.Use(recovery.New())
    r.Use(security.New())
    r.Use(cors.New(
        cors.WithAllowedOrigins("*"),
        cors.WithAllowedMethods("GET", "POST", "PUT", "DELETE"),
    ))
    
    // Public routes
    r.GET("/health", healthHandler)
    r.GET("/public", publicHandler)
    
    // API routes with auth
    api := r.Group("/api")
    api.Use(JWTAuth("your-secret-key"))
    {
        api.GET("/profile", profileHandler)
        api.POST("/posts", createPostHandler)
        
        // Admin routes with additional middleware
        admin := api.Group("/admin")
        admin.Use(RequireAdmin())
        {
            admin.GET("/users", listUsersHandler)
            admin.DELETE("/users/:id", deleteUserHandler)
        }
    }
    
    log.Fatal(http.ListenAndServe(":8080", r))
}

// Custom middleware
func JWTAuth(secret string) router.HandlerFunc {
    return func(c *router.Context) {
        token := c.Request.Header.Get("Authorization")
        if token == "" {
            c.JSON(401, map[string]string{"error": "Unauthorized"})
            return
        }
        // Validate token...
        c.Next()
    }
}

func RequireAdmin() router.HandlerFunc {
    return func(c *router.Context) {
        // Check if user is admin...
        c.Next()
    }
}

// Handlers
func healthHandler(c *router.Context) {
    c.JSON(200, map[string]string{"status": "OK"})
}

func publicHandler(c *router.Context) {
    c.JSON(200, map[string]string{"message": "Public endpoint"})
}

func profileHandler(c *router.Context) {
    c.JSON(200, map[string]string{"user": "john@example.com"})
}

func createPostHandler(c *router.Context) {
    c.JSON(201, map[string]string{"message": "Post created"})
}

func listUsersHandler(c *router.Context) {
    c.JSON(200, []string{"user1", "user2"})
}

func deleteUserHandler(c *router.Context) {
    c.Status(204)
}
```

## Next Steps

- **Context API**: Learn about the [Context](../context/) and its lifecycle
- **Middleware Reference**: See all [built-in middleware options](/reference/packages/router/middleware/)
- **Examples**: Browse [working examples](../examples/) with middleware
