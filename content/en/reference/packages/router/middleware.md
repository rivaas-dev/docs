---
title: "Middleware Reference"
linkTitle: "Middleware"
keywords:
  - router middleware
  - middleware api
  - middleware chain
  - custom middleware
weight: 50
description: >
  Built-in middleware catalog with configuration options.
---

The router includes production-ready middleware in sub-packages. Each middleware uses functional options for configuration.

## Security

### Security Headers

**Package:** `rivaas.dev/router/middleware/security`

```go
import "rivaas.dev/router/middleware/security"

r.Use(security.New(
    security.WithHSTS(true),
    security.WithFrameDeny(true),
    security.WithContentTypeNosniff(true),
    security.WithXSSProtection(true),
))
```

### CORS

**Package:** `rivaas.dev/router/middleware/cors`

```go
import "rivaas.dev/router/middleware/cors"

r.Use(cors.New(
    cors.WithAllowedOrigins("https://example.com"),
    cors.WithAllowedMethods("GET", "POST", "PUT", "DELETE"),
    cors.WithAllowedHeaders("Content-Type", "Authorization"),
    cors.WithAllowCredentials(true),
    cors.WithMaxAge(3600),
))
```

### Basic Auth

**Package:** `rivaas.dev/router/middleware/basicauth`

```go
import "rivaas.dev/router/middleware/basicauth"

admin := r.Group("/admin")
admin.Use(basicauth.New(
    basicauth.WithCredentials("admin", "secret"),
    basicauth.WithRealm("Admin Area"),
))
```

## Observability

### Access Log

**Package:** `rivaas.dev/router/middleware/accesslog`

```go
import (
    "log/slog"
    "rivaas.dev/router/middleware/accesslog"
)

logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
r.Use(accesslog.New(
    accesslog.WithLogger(logger),
    accesslog.WithExcludePaths("/health", "/metrics"),
    accesslog.WithSampleRate(0.1),
    accesslog.WithSlowThreshold(500 * time.Millisecond),
))
```

### Request ID

**Package:** `rivaas.dev/router/middleware/requestid`

Generates unique, time-ordered request IDs for distributed tracing and log correlation.

```go
import "rivaas.dev/router/middleware/requestid"

// UUID v7 by default (36 chars, time-ordered, RFC 9562)
r.Use(requestid.New())

// Use ULID for shorter IDs (26 chars)
r.Use(requestid.New(requestid.WithULID()))

// Custom header name
r.Use(requestid.New(requestid.WithHeader("X-Correlation-ID")))

// Get request ID in handlers
func handler(c *router.Context) {
    id := requestid.Get(c)
}
```

**ID Formats:**
- UUID v7 (default): `018f3e9a-1b2c-7def-8000-abcdef123456`
- ULID: `01ARZ3NDEKTSV4RRFFQ69G5FAV`

## Reliability

### Recovery

**Package:** `rivaas.dev/router/middleware/recovery`

```go
import "rivaas.dev/router/middleware/recovery"

r.Use(recovery.New(
    recovery.WithPrintStack(true),
    recovery.WithLogger(logger),
))
```

### Timeout

**Package:** `rivaas.dev/router/middleware/timeout`

```go
import "rivaas.dev/router/middleware/timeout"

r.Use(timeout.New(
    timeout.WithDuration(30 * time.Second),
    timeout.WithMessage("Request timeout"),
))
```

### Rate Limit

**Package:** `rivaas.dev/router/middleware/ratelimit`

```go
import "rivaas.dev/router/middleware/ratelimit"

r.Use(ratelimit.New(
    ratelimit.WithRequestsPerSecond(1000),
    ratelimit.WithBurst(100),
    ratelimit.WithKeyFunc(func(c *router.Context) string {
        return c.ClientIP() // Rate limit by IP
    }),
    ratelimit.WithLogger(logger),
))
```

### Body Limit

**Package:** `rivaas.dev/router/middleware/bodylimit`

```go
import "rivaas.dev/router/middleware/bodylimit"

r.Use(bodylimit.New(
    bodylimit.WithLimit(10 * 1024 * 1024), // 10MB
))
```

## Performance

### Compression

**Package:** `rivaas.dev/router/middleware/compression`

```go
import "rivaas.dev/router/middleware/compression"

r.Use(compression.New(
    compression.WithLevel(compression.DefaultCompression),
    compression.WithMinSize(1024), // Don't compress <1KB
    compression.WithLogger(logger),
))
```

## Other

### Method Override

**Package:** `rivaas.dev/router/middleware/methodoverride`

```go
import "rivaas.dev/router/middleware/methodoverride"

r.Use(methodoverride.New(
    methodoverride.WithHeader("X-HTTP-Method-Override"),
))
```

### Trailing Slash

**Package:** `rivaas.dev/router/middleware/trailingslash`

```go
import "rivaas.dev/router/middleware/trailingslash"

r.Use(trailingslash.New(
    trailingslash.WithRedirectCode(301),
))
```

## Middleware Ordering

Recommended middleware order:

```go
r := router.New()

// 1. Request ID
r.Use(requestid.New())

// 2. AccessLog
r.Use(accesslog.New())

// 3. Recovery
r.Use(recovery.New())

// 4. Security/CORS
r.Use(security.New())
r.Use(cors.New())

// 5. Body Limit
r.Use(bodylimit.New())

// 6. Rate Limit
r.Use(ratelimit.New())

// 7. Timeout
r.Use(timeout.New())

// 8. Authentication
r.Use(auth.New())

// 9. Compression (last)
r.Use(compression.New())
```

## Complete Example

```go
package main

import (
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
    r := router.New()
    
    // Observability
    r.Use(requestid.New())
    r.Use(accesslog.New(
        accesslog.WithLogger(logger),
        accesslog.WithExcludePaths("/health"),
    ))
    
    // Reliability
    r.Use(recovery.New())
    
    // Security
    r.Use(security.New())
    r.Use(cors.New(
        cors.WithAllowedOrigins("*"),
        cors.WithAllowedMethods("GET", "POST", "PUT", "DELETE"),
    ))
    
    r.GET("/", func(c *router.Context) {
        c.JSON(200, map[string]string{"message": "Hello"})
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Next Steps

- **Middleware Guide**: See [middleware usage](/guides/router/middleware/)
- **Source Code**: Browse [middleware source](https://github.com/rivaas-dev/rivaas/tree/main/router/middleware)
