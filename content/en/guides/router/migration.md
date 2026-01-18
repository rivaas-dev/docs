---
title: "Migration"
linkTitle: "Migration"
weight: 150
description: >
  Migrate from Gin, Echo, or http.ServeMux to Rivaas Router.
---

This guide helps you migrate from other popular Go routers.

## Migrating from Gin

### Route Registration

```go
// Gin
gin := gin.Default()
gin.GET("/users/:id", getUserHandler)
gin.POST("/users", createUserHandler)

// Rivaas Router
r := router.MustNew()
r.GET("/users/:id", getUserHandler)
r.POST("/users", createUserHandler)
```

### Context Usage

```go
// Gin
func ginHandler(c *gin.Context) {
    id := c.Param("id")
    c.JSON(200, gin.H{"user_id": id})
}

// Rivaas Router
func rivaasHandler(c *router.Context) {
    id := c.Param("id")
    c.JSON(200, map[string]string{"user_id": id})
}
```

### Middleware

```go
// Gin
gin.Use(gin.Logger(), gin.Recovery())

// Rivaas Router
r.Use(Logger(), Recovery())
```

## Migrating from Echo

### Route Registration

```go
// Echo
e := echo.New()
e.GET("/users/:id", getUserHandler)
e.POST("/users", createUserHandler)

// Rivaas Router
r := router.MustNew()
r.GET("/users/:id", getUserHandler)
r.POST("/users", createUserHandler)
```

### Context Usage

```go
// Echo
func echoHandler(c echo.Context) error {
    id := c.Param("id")
    return c.JSON(200, map[string]string{"user_id": id})
}

// Rivaas Router
func rivaasHandler(c *router.Context) {
    id := c.Param("id")
    c.JSON(200, map[string]string{"user_id": id})
}
```

## Migrating from http.ServeMux

### Basic Routes

```go
// http.ServeMux
mux := http.NewServeMux()
mux.HandleFunc("/users/", usersHandler)
mux.HandleFunc("/posts/", postsHandler)

// Rivaas Router
r := router.MustNew()
r.GET("/users/:id", getUserHandler)
r.GET("/posts/:id", getPostHandler)
```

### Parameter Extraction

```go
// http.ServeMux (manual parsing)
func usersHandler(w http.ResponseWriter, r *http.Request) {
    path := strings.TrimPrefix(r.URL.Path, "/users/")
    userID := strings.Split(path, "/")[0]
    // ...
}

// Rivaas Router (automatic)
func getUserHandler(c *router.Context) {
    userID := c.Param("id")
    // ...
}
```

## Key Differences

### Response Methods

| Feature | Gin | Echo | Rivaas |
|---------|-----|------|--------|
| JSON | `c.JSON()` | `c.JSON()` | `c.JSON()` |
| String | `c.String()` | `c.String()` | `c.String()` |
| HTML | `c.HTML()` | `c.HTML()` | `c.HTML()` |
| Pure JSON | ✅ | ❌ | ✅ |
| Secure JSON | ✅ | ❌ | ✅ |
| YAML | ✅ | ❌ | ✅ |

### Request Binding

| Feature | Gin | Echo | Rivaas |
|---------|-----|------|--------|
| Query binding | ✅ | ✅ | ✅ |
| JSON binding | ✅ | ✅ | ✅ |
| Form binding | ✅ | ✅ | ✅ |
| Maps (dot notation) | ❌ | ❌ | ✅ |
| Maps (bracket notation) | ❌ | ❌ | ✅ |
| Nested structs in query | ❌ | ❌ | ✅ |
| Enum validation | ❌ | ❌ | ✅ |
| Default values | ❌ | ❌ | ✅ |

## Next Steps

- **Basic Usage**: Review [basic usage guide](../basic-usage/)
- **Examples**: See [complete examples](../examples/)
- **API Reference**: Check [API documentation](/reference/packages/router/)
