---
title: "Route Constraints"
linkTitle: "Route Constraints"
weight: 40
description: >
  Type-safe parameter validation with route constraints.
---

Route constraints provide parameter validation that maps to OpenAPI schema types.

## Typed Constraints

### `WhereInt(param string) *Route`

Validates parameter as integer (OpenAPI: `type: integer, format: int64`).

```go
r.GET("/users/:id", getUserHandler).WhereInt("id")
```

**Matches:**

- `/users/123` ✅
- `/users/abc` ❌

### `WhereFloat(param string) *Route`

Validates parameter as float (OpenAPI: `type: number, format: double`).

```go
r.GET("/prices/:amount", getPriceHandler).WhereFloat("amount")
```

**Matches:**

- `/prices/19.99` ✅
- `/prices/abc` ❌

### `WhereUUID(param string) *Route`

Validates parameter as UUID (OpenAPI: `type: string, format: uuid`).

```go
r.GET("/entities/:uuid", getEntityHandler).WhereUUID("uuid")
```

**Matches:**

- `/entities/550e8400-e29b-41d4-a716-446655440000` ✅
- `/entities/not-a-uuid` ❌

### `WhereDate(param string) *Route`

Validates parameter as date (OpenAPI: `type: string, format: date`).

```go
r.GET("/orders/:date", getOrderHandler).WhereDate("date")
```

**Matches:**

- `/orders/2024-01-18` ✅
- `/orders/invalid-date` ❌

### `WhereDateTime(param string) *Route`

Validates parameter as date-time (OpenAPI: `type: string, format: date-time`).

```go
r.GET("/events/:timestamp", getEventHandler).WhereDateTime("timestamp")
```

**Matches:**

- `/events/2024-01-18T10:30:00Z` ✅
- `/events/invalid` ❌

### `WhereEnum(param string, values ...string) *Route`

Validates parameter against enum values (OpenAPI: `enum`).

```go
r.GET("/status/:state", getStatusHandler).WhereEnum("state", "active", "pending", "deleted")
```

**Matches:**

- `/status/active` ✅
- `/status/invalid` ❌

## Regex Constraints

### `WhereRegex(param, pattern string) *Route`

Custom regex validation (OpenAPI: `pattern`).

```go
// Alphanumeric only
r.GET("/slugs/:slug", getSlugHandler).WhereRegex("slug", `[a-zA-Z0-9]+`)

// Email validation
r.GET("/users/:email", getUserByEmailHandler).WhereRegex("email", `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`)
```

## Multiple Constraints

Apply multiple constraints to the same route:

```go
r.GET("/posts/:id/:slug", getPostHandler).
    WhereInt("id").
    WhereRegex("slug", `[a-zA-Z0-9-]+`)
```

## Common Patterns

### RESTful IDs

```go
// Integer IDs
r.GET("/users/:id", getUserHandler).WhereInt("id")
r.PUT("/users/:id", updateUserHandler).WhereInt("id")
r.DELETE("/users/:id", deleteUserHandler).WhereInt("id")

// UUID IDs
r.GET("/entities/:uuid", getEntityHandler).WhereUUID("uuid")
```

### Slugs and Identifiers

```go
// Alphanumeric slugs
r.GET("/posts/:slug", getPostBySlugHandler).WhereRegex("slug", `[a-z0-9-]+`)

// Category identifiers
r.GET("/categories/:name", getCategoryHandler).WhereRegex("name", `[a-zA-Z0-9_-]+`)
```

### Status and States

```go
// Enum validation for states
r.GET("/orders/:status", getOrdersByStatusHandler).WhereEnum("status", "pending", "processing", "shipped", "delivered")
```

## Complete Example

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.New()
    
    // Integer constraint
    r.GET("/users/:id", getUserHandler).WhereInt("id")
    
    // UUID constraint
    r.GET("/entities/:uuid", getEntityHandler).WhereUUID("uuid")
    
    // Enum constraint
    r.GET("/status/:state", getStatusHandler).WhereEnum("state", "active", "inactive", "pending")
    
    // Regex constraint
    r.GET("/posts/:slug", getPostHandler).WhereRegex("slug", `[a-z0-9-]+`)
    
    // Multiple constraints
    r.GET("/articles/:id/:slug", getArticleHandler).
        WhereInt("id").
        WhereRegex("slug", `[a-z0-9-]+`)
    
    http.ListenAndServe(":8080", r)
}

func getUserHandler(c *router.Context) {
    c.JSON(200, map[string]string{"user_id": c.Param("id")})
}

func getEntityHandler(c *router.Context) {
    c.JSON(200, map[string]string{"uuid": c.Param("uuid")})
}

func getStatusHandler(c *router.Context) {
    c.JSON(200, map[string]string{"state": c.Param("state")})
}

func getPostHandler(c *router.Context) {
    c.JSON(200, map[string]string{"slug": c.Param("slug")})
}

func getArticleHandler(c *router.Context) {
    c.JSON(200, map[string]string{
        "id":   c.Param("id"),
        "slug": c.Param("slug"),
    })
}
```

## Next Steps

- **API Reference**: See [core types](../api-reference/)
- **Route Patterns**: Learn about [route patterns](/guides/router/route-patterns/)
