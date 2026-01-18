---
title: "Request Binding"
linkTitle: "Request Binding"
weight: 70
description: >
  Parse and bind request data to Go structs.
---

Request binding parses request data (query parameters, URL parameters, form data, JSON) into Go structs.

{{% alert title="Two Approaches" color="info" %}}
The router provides **basic strict JSON binding** directly on Context. For **full binding capabilities** (query, form, headers, cookies), use the separate [binding package](/reference/packages/binding/).
{{% /alert %}}

## Router Context Methods

The router Context provides basic binding and data access methods.

### Strict JSON Binding

`BindStrict()` binds JSON with strict validation:

```go
r.POST("/users", func(c *router.Context) {
    var req CreateUserRequest
    if err := c.BindStrict(&req, router.BindOptions{MaxBytes: 1 << 20}); err != nil {
        return // Error response already written
    }
    c.JSON(201, req)
})
```

**Features:**
- Rejects unknown fields (catches typos)
- Enforces request body size limits
- Returns appropriate HTTP status codes (400 for malformed, 422 for type errors)

### Manual Parameter Access

For simple cases, access parameters directly:

```go
// Query parameters
r.GET("/search", func(c *router.Context) {
    query := c.Query("q")
    limit := c.QueryDefault("limit", "10")
    
    c.JSON(200, map[string]string{
        "query": query,
        "limit": limit,
    })
})

// URL parameters
r.GET("/users/:id", func(c *router.Context) {
    userID := c.Param("id")
    c.JSON(200, map[string]string{"user_id": userID})
})

// Form data
r.POST("/login", func(c *router.Context) {
    username := c.FormValue("username")
    password := c.FormValue("password")
    // ...
})
```

### Content Type Validation

Validate content type before binding:

```go
r.POST("/users", func(c *router.Context) {
    if !c.RequireContentTypeJSON() {
        return // 415 Unsupported Media Type already sent
    }
    
    var req CreateUserRequest
    if err := c.BindStrict(&req, router.BindOptions{}); err != nil {
        return
    }
    c.JSON(201, req)
})
```

### Streaming Large Payloads

For large arrays, stream instead of loading into memory:

```go
// Stream JSON array items
r.POST("/bulk/users", func(c *router.Context) {
    err := router.StreamJSONArray(c, func(user User) error {
        return processUser(user)
    }, 10000) // Max 10k items
    
    if err != nil {
        return
    }
    c.NoContent()
})

// Stream NDJSON (newline-delimited JSON)
r.POST("/import", func(c *router.Context) {
    err := router.StreamNDJSON(c, func(item Record) error {
        return importRecord(item)
    })
    
    if err != nil {
        return
    }
    c.NoContent()
})
```

## Binding Package (Full Features)

For comprehensive binding with struct tags, use the [binding package](/guides/binding/):

```go
import "rivaas.dev/binding"

// Bind query parameters to struct
type SearchRequest struct {
    Query string `query:"q"`
    Limit int    `query:"limit" default:"10"`
    Page  int    `query:"page" default:"1"`
}

r.GET("/search", func(c *router.Context) {
    var req SearchRequest
    if err := binding.Query(c.Request, &req); err != nil {
        c.JSON(400, map[string]string{"error": err.Error()})
        return
    }
    c.JSON(200, req)
})
```

### Binding Methods (binding package)

```go
binding.Query(r *http.Request, dst any) error    // Query parameters
binding.Params(params map[string]string, dst any) error  // URL parameters
binding.JSON(r *http.Request, dst any) error     // JSON body
binding.Form(r *http.Request, dst any) error     // Form data
binding.Headers(r *http.Request, dst any) error  // Request headers
binding.Cookies(r *http.Request, dst any) error  // Cookies
```

### Supported Types

**Primitives:**

```go
type Example struct {
    String  string  `query:"string"`
    Int     int     `query:"int"`
    Int64   int64   `query:"int64"`
    Float64 float64 `query:"float64"`
    Bool    bool    `query:"bool"`
}
```

**Time and Duration:**

```go
type Example struct {
    Time     time.Time     `query:"time"`      // RFC3339, ISO8601, etc.
    Duration time.Duration `query:"duration"`  // "5m", "1h30m", etc.
}
```

**Network Types:**

```go
type Example struct {
    IP     net.IP     `query:"ip"`      // "192.168.1.1"
    IPNet  net.IPNet  `query:"ipnet"`   // "192.168.1.0/24"
    URL    url.URL    `query:"url"`     // "https://example.com"
}
```

**Slices:**

```go
type Example struct {
    Tags  []string `query:"tags"`   // ?tags=a&tags=b&tags=c
    IDs   []int    `query:"ids"`    // ?ids=1&ids=2&ids=3
}
```

**Maps:**

```go
type Example struct {
    // Dot notation: ?metadata.key1=value1&metadata.key2=value2
    Metadata map[string]string `query:"metadata"`
    
    // Bracket notation: ?filters[status]=active&filters[type]=post
    Filters map[string]string `query:"filters"`
}
```

### Struct Tags

**`enum` - Enum Validation:**

```go
type Request struct {
    Status string `query:"status" enum:"active,inactive,pending"`
}
```

**`default` - Default Values:**

```go
type Request struct {
    Limit int    `query:"limit" default:"10"`
    Sort  string `query:"sort" default:"desc"`
}
```

**Combined:**

```go
type Request struct {
    Status string `query:"status" enum:"active,inactive" default:"active"`
    Limit  int    `query:"limit" default:"10"`
}
```

## Complete Example

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
    "rivaas.dev/binding"
)

type CreateUserRequest struct {
    Name     string            `json:"name"`
    Email    string            `json:"email"`
    Age      int               `json:"age"`
    Tags     []string          `json:"tags"`
    Metadata map[string]string `json:"metadata"`
}

type SearchRequest struct {
    Query  string `query:"q"`
    Limit  int    `query:"limit" default:"10"`
    Status string `query:"status" enum:"active,inactive,all" default:"all"`
}

func main() {
    r := router.MustNew()
    
    // Strict JSON binding (built-in)
    r.POST("/users", func(c *router.Context) {
        var req CreateUserRequest
        if err := c.BindStrict(&req, router.BindOptions{MaxBytes: 1 << 20}); err != nil {
            return // Error already written
        }
        c.JSON(201, req)
    })
    
    // Query binding (using binding package)
    r.GET("/search", func(c *router.Context) {
        var req SearchRequest
        if err := binding.Query(c.Request, &req); err != nil {
            c.JSON(400, map[string]string{"error": err.Error()})
            return
        }
        c.JSON(200, req)
    })
    
    // Simple parameter access
    r.GET("/users/:id", func(c *router.Context) {
        userID := c.Param("id")
        includeDeleted := c.QueryDefault("include_deleted", "false")
        
        c.JSON(200, map[string]string{
            "user_id":         userID,
            "include_deleted": includeDeleted,
        })
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Next Steps

- **Binding Package**: Full binding documentation at [binding guide](/guides/binding/)
- **Validation**: Learn about [request validation](../validation/)
- **Examples**: See [complete examples](../examples/) with binding
- **API Reference**: Check [binding API reference](/reference/packages/binding/)
