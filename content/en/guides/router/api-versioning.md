---
title: "API Versioning"
linkTitle: "API Versioning"
weight: 110
description: >
  Built-in API versioning with header-based, query-based, and custom detection strategies.
---

The router includes built-in support for API versioning with a lock-free implementation.

## Version Detection Methods

### Header-Based Versioning

```go
r := router.MustNew()

// Default: looks for API-Version header
v1 := r.Version("v1")
v1.GET("/users", listUsersV1)

v2 := r.Version("v2")
v2.GET("/users", listUsersV2)
```

**Request:**

```bash
curl -H "API-Version: v1" http://localhost:8080/users
```

### Query-Based Versioning

```go
// Custom version detector: check query parameter
r := router.New(router.WithVersionDetector(func(req *http.Request) string {
    return req.URL.Query().Get("version")
}))

v1 := r.Version("v1")
v1.GET("/users", listUsersV1)
```

**Request:**

```bash
curl http://localhost:8080/users?version=v1
```

### URL Path Versioning

```go
// Using route groups for path-based versioning
r := router.MustNew()

v1 := r.Group("/api/v1")
v1.GET("/users", listUsersV1)

v2 := r.Group("/api/v2")
v2.GET("/users", listUsersV2)
```

**Request:**

```bash
curl http://localhost:8080/api/v1/users
```

## Version Groups

Organize versioned APIs with groups:

```go
r := router.MustNew()

// Version 1 - Stable API
v1 := r.Version("v1")
{
    users := v1.Group("/users")
    users.GET("/", listUsersV1)
    users.POST("/", createUserV1)
    
    posts := v1.Group("/posts")
    posts.GET("/", listPostsV1)
}

// Version 2 - New features
v2 := r.Version("v2")
{
    users := v2.Group("/users")
    users.GET("/", listUsersV2)        // Enhanced
    users.POST("/", createUserV2)      // New fields
    users.GET("/:id/stats", getUserStatsV2) // New endpoint
}
```

## Version-Specific Middleware

```go
v1 := r.Version("v1")
v1.Use(V1RateLimit())

v2 := r.Version("v2")
v2.Use(V2RateLimit())
v2.Use(V2Auth())
```

## Complete Example

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    
    // Version 1 - Original API
    v1 := r.Version("v1")
    v1.GET("/users", func(c *router.Context) {
        c.JSON(200, map[string]interface{}{
            "version": "v1",
            "users": []map[string]string{
                {"id": "1", "name": "Alice"},
                {"id": "2", "name": "Bob"},
            },
        })
    })
    
    // Version 2 - Enhanced API with pagination
    v2 := r.Version("v2")
    v2.GET("/users", func(c *router.Context) {
        c.JSON(200, map[string]interface{}{
            "version": "v2",
            "users": []map[string]interface{}{
                {"id": "1", "name": "Alice", "email": "alice@example.com"},
                {"id": "2", "name": "Bob", "email": "bob@example.com"},
            },
            "pagination": map[string]int{
                "page":  1,
                "limit": 10,
                "total": 2,
            },
        })
    })
    
    http.ListenAndServe(":8080", r)
}
```

**Test:**

```bash
# Version 1
curl -H "API-Version: v1" http://localhost:8080/users

# Version 2
curl -H "API-Version: v2" http://localhost:8080/users
```

## Best Practices

1. **Use semantic versioning**: v1, v2, v3 (not v1.0, v1.1)
2. **Maintain old versions**: Don't break existing clients
3. **Document changes**: Clear migration guides between versions
4. **Sunset policy**: Announce deprecation timeline

## Next Steps

- **Observability**: Learn about [OpenTelemetry integration](../observability/)
- **Route Groups**: See [route groups](../route-groups/) for organization
