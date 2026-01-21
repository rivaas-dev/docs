---
title: "Context"
linkTitle: "Context"
weight: 60
keywords:
  - router context
  - request context
  - response writer
  - context api
description: >
  Understand the Context API, request/response methods, and critical memory safety rules.
---

The `router.Context` provides access to the request/response and various utility methods. Understanding its lifecycle is critical for memory safety.

## ⚠️ Memory Safety - CRITICAL

**Context objects are pooled and reused across requests.** You must understand context lifecycle for memory safety.

### CRITICAL RULES

1. **DO NOT retain references to Context objects beyond the request handler lifetime.**
2. **For async operations**, copy needed data from Context before starting goroutines.
3. **The router automatically returns contexts to the pool** after request completion.
4. **DO NOT access Context concurrently**. It is NOT thread-safe.

### Why This Matters

- **Memory leaks**: Retaining references prevents contexts from being garbage collected.
- **Data corruption**: Contexts are reused. Old data may appear in new requests.
- **Security issues**: Sensitive request data may leak to other requests.
- **Undefined behavior**: Use-after-release causes unpredictable bugs.

### Correct Usage

```go
// ✅ CORRECT: Normal handler - context used within handler
func handler(c *router.Context) {
    userID := c.Param("id")
    c.JSON(200, map[string]string{"id": userID})
    // Context automatically returned to pool by router
}

// ✅ CORRECT: Async operation with copied data
func handler(c *router.Context) {
    // Copy needed data before starting goroutine
    userID := c.Param("id")
    go func(id string) {
        // Process async work with copied data...
        processAsync(id)
    }(userID)
}
```

### Incorrect Usage

```go
// ❌ WRONG: Retaining context reference
var globalContext *router.Context

func handler(c *router.Context) {
    globalContext = c // BAD! Memory leak and data corruption
}

// ❌ WRONG: Passing context to goroutine
func handler(c *router.Context) {
    go func(ctx *router.Context) {
        // BAD! Context may be reused by another request
        processAsync(ctx.Param("id"))
    }(c)
}

// ❌ WRONG: Storing context in struct
type Service struct {
    ctx *router.Context // BAD! Never do this
}
```

## Request Information

### Basic Request Data

```go
func handler(c *router.Context) {
    // HTTP method
    method := c.Request.Method // "GET", "POST", etc.
    
    // URL path
    path := c.Request.URL.Path // "/users/123"
    
    // Headers
    userAgent := c.Request.Header.Get("User-Agent")
    contentType := c.Request.Header.Get("Content-Type")
    
    // Remote address
    remoteAddr := c.Request.RemoteAddr // "192.168.1.1:12345"
}
```

### Path Parameters

Extract parameters from the URL path:

```go
// Route: /users/:id/posts/:post_id
r.GET("/users/:id/posts/:post_id", func(c *router.Context) {
    userID := c.Param("id")
    postID := c.Param("post_id")
    
    c.JSON(200, map[string]string{
        "user_id": userID,
        "post_id": postID,
    })
})
```

### Query Parameters

```go
// GET /search?q=golang&limit=10&page=2
r.GET("/search", func(c *router.Context) {
    query := c.Query("q")        // "golang"
    limit := c.Query("limit")    // "10"
    page := c.Query("page")      // "2"
    
    c.JSON(200, map[string]string{
        "query": query,
        "limit": limit,
        "page":  page,
    })
})
```

### Form Data

```go
// POST with form data
r.POST("/login", func(c *router.Context) {
    username := c.FormValue("username")
    password := c.FormValue("password")
    
    c.JSON(200, map[string]string{
        "username": username,
    })
})
```

## Response Methods

### JSON Responses

```go
// Standard JSON (HTML-escaped)
c.JSON(200, data)

// Indented JSON (for debugging)
c.IndentedJSON(200, data)

// Pure JSON (no HTML escaping - 35% faster!)
c.PureJSON(200, data)

// Secure JSON (anti-hijacking prefix)
c.SecureJSON(200, data)

// ASCII JSON (pure ASCII with \uXXXX)
c.AsciiJSON(200, data)

// JSONP (with callback)
c.JSONP(200, data, "callback")
```

### Other Response Formats

```go
// YAML
c.YAML(200, config)

// Plain text
c.String(200, "Hello, World!")
c.Stringf(200, "Hello, %s!", name)

// HTML
c.HTML(200, "<h1>Welcome</h1>")

// Binary data
c.Data(200, "image/png", imageBytes)

// Stream from reader (zero-copy!)
c.DataFromReader(200, size, "video/mp4", file, nil)

// Status only
c.Status(204) // No Content
```

### File Serving

```go
// Serve file
c.ServeFile("/path/to/file.pdf")

// Force download
c.Download("/path/to/file.pdf", "custom-name.pdf")
```

## Request Headers

### Reading Headers

```go
func handler(c *router.Context) {
    userAgent := c.Request.Header.Get("User-Agent")
    auth := c.Request.Header.Get("Authorization")
    contentType := c.Request.Header.Get("Content-Type")
}
```

### Setting Response Headers

```go
func handler(c *router.Context) {
    c.Header("Cache-Control", "no-cache")
    c.Header("X-Custom-Header", "value")
    c.JSON(200, data)
}
```

## Helper Methods

### Content Type Detection

```go
func handler(c *router.Context) {
    if c.IsJSON() {
        // Request has JSON content-type
    }
    
    if c.AcceptsJSON() {
        c.JSON(200, data)
    } else if c.AcceptsHTML() {
        c.HTML(200, htmlContent)
    }
}
```

### Client Information

```go
func handler(c *router.Context) {
    clientIP := c.ClientIP()       // Real IP (considers X-Forwarded-For)
    isSecure := c.IsHTTPS()       // HTTPS check
}
```

### Redirects

```go
func handler(c *router.Context) {
    c.Redirect(301, "/new-url") // Permanent redirect
    c.Redirect(302, "/temp")    // Temporary redirect
}
```

### Cookies

```go
// Set cookie
c.SetCookie(
    "session_id",    // name
    "abc123",        // value
    3600,            // max age (seconds)
    "/",             // path
    "",              // domain
    false,           // secure
    true,            // httpOnly
)

// Get cookie
sessionID, err := c.GetCookie("session_id")
```

## Passing Values Between Middleware

Use `context.WithValue()` to pass values between middleware and handlers:

```go
// Define context keys to avoid collisions
type contextKey string
const userKey contextKey = "user"

// In middleware - create new request with value
func AuthMiddleware() router.HandlerFunc {
    return func(c *router.Context) {
        user := authenticateUser(c)
        
        // Create new context with value
        ctx := context.WithValue(c.Request.Context(), userKey, user)
        c.Request = c.Request.WithContext(ctx)
        
        c.Next()
    }
}

// In handler - retrieve value from request context
func handler(c *router.Context) {
    user, ok := c.Request.Context().Value(userKey).(*User)
    if !ok || user == nil {
        c.JSON(401, map[string]string{"error": "Unauthorized"})
        return
    }
    
    c.JSON(200, user)
}
```

{{% alert title="Note" color="info" %}}
Use typed keys (like `contextKey`) instead of string keys to avoid collisions between packages.
{{% /alert %}}

## File Uploads

```go
r.POST("/upload", func(c *router.Context) {
    // Single file
    file, err := c.File("avatar")
    if err != nil {
        c.JSON(400, map[string]string{"error": "avatar required"})
        return
    }
    
    // File info
    fmt.Printf("Name: %s, Size: %d, Type: %s\n", 
        file.Name, file.Size, file.ContentType)
    
    // Save file
    if err := file.Save("./uploads/" + file.Name); err != nil {
        c.JSON(500, map[string]string{"error": "failed to save"})
        return
    }
    
    c.JSON(200, map[string]string{"filename": file.Name})
})

// Multiple files
r.POST("/upload-many", func(c *router.Context) {
    files, err := c.Files("documents")
    if err != nil {
        c.JSON(400, map[string]string{"error": "documents required"})
        return
    }
    
    for _, f := range files {
        f.Save("./uploads/" + f.Name)
    }
    
    c.JSON(200, map[string]int{"count": len(files)})
})
```

## Performance Tips

### Extract Data Immediately

```go
// ✅ GOOD: Extract data early
func handler(c *router.Context) {
    userID := c.Param("id")
    query := c.Query("q")
    
    // Use extracted data
    result := processData(userID, query)
    c.JSON(200, result)
}

// ❌ BAD: Don't store context reference
var globalContext *router.Context
func handler(c *router.Context) {
    globalContext = c // Memory leak!
}
```

### Choose the Right Response Method

```go
// Use PureJSON for HTML content (35% faster than JSON)
c.PureJSON(200, dataWithHTMLStrings)

// Use Data() for binary (98% faster than JSON)
c.Data(200, "image/png", imageBytes)

// Avoid YAML in hot paths (9x slower than JSON)
// c.YAML(200, data) // Only for config/admin endpoints
```

## Complete Example

```go
package main

import (
    "encoding/json"
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    
    // Request parameters
    r.GET("/users/:id", func(c *router.Context) {
        id := c.Param("id")
        c.JSON(200, map[string]string{"id": id})
    })
    
    // Query parameters
    r.GET("/search", func(c *router.Context) {
        q := c.Query("q")
        c.JSON(200, map[string]string{"query": q})
    })
    
    // Form data
    r.POST("/login", func(c *router.Context) {
        username := c.FormValue("username")
        c.JSON(200, map[string]string{"username": username})
    })
    
    // JSON request body
    r.POST("/users", func(c *router.Context) {
        var req struct {
            Name  string `json:"name"`
            Email string `json:"email"`
        }
        
        if err := json.NewDecoder(c.Request.Body).Decode(&req); err != nil {
            c.JSON(400, map[string]string{"error": "Invalid JSON"})
            return
        }
        
        c.JSON(201, req)
    })
    
    // Headers and cookies
    r.GET("/info", func(c *router.Context) {
        userAgent := c.Request.Header.Get("User-Agent")
        session, _ := c.GetCookie("session_id")
        
        c.Header("X-Custom", "value")
        c.JSON(200, map[string]string{
            "user_agent": userAgent,
            "session":    session,
        })
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Next Steps

- **Request Binding**: Learn about [automatic request binding](../request-binding/)
- **Validation**: See [request validation strategies](../validation/)
- **Response Rendering**: Explore [response rendering options](../response-rendering/)
- **API Reference**: See [complete Context API](/reference/packages/router/context-api/)
