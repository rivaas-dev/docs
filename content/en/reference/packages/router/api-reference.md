---
title: "API Reference"
linkTitle: "API Reference"
weight: 10
description: >
  Core types and methods for the router package.
---

## Router

### `router.New(opts ...Option) *Router`

Creates a new router instance.

```go
r := router.New()

// With options
r := router.New(
    router.WithTracing(),
    router.WithTracingServiceName("my-api"),
)
```

### HTTP Method Handlers

Register routes for HTTP methods:

```go
r.GET(path string, handlers ...HandlerFunc) *Route
r.POST(path string, handlers ...HandlerFunc) *Route
r.PUT(path string, handlers ...HandlerFunc) *Route
r.DELETE(path string, handlers ...HandlerFunc) *Route
r.PATCH(path string, handlers ...HandlerFunc) *Route
r.OPTIONS(path string, handlers ...HandlerFunc) *Route
r.HEAD(path string, handlers ...HandlerFunc) *Route
```

**Example:**

```go
r.GET("/users", listUsersHandler)
r.POST("/users", createUserHandler)
r.GET("/users/:id", getUserHandler)
```

### Middleware

```go
r.Use(middleware ...HandlerFunc)
```

Adds global middleware to the router.

```go
r.Use(Logger(), Recovery())
```

### Route Groups

```go
r.Group(prefix string, middleware ...HandlerFunc) *Group
```

Creates a new route group with the specified prefix and optional middleware.

```go
api := r.Group("/api/v1")
api.Use(Auth())
api.GET("/users", listUsers)
```

### API Versioning

```go
r.Version(version string) *Group
```

Creates a version-specific route group.

```go
v1 := r.Version("v1")
v1.GET("/users", listUsersV1)
```

### Static Files

```go
r.Static(relativePath, root string)
r.StaticFile(relativePath, filepath string)
r.StaticFS(relativePath string, fs http.FileSystem)
```

**Example:**

```go
r.Static("/assets", "./public")
r.StaticFile("/favicon.ico", "./static/favicon.ico")
```

### Route Introspection

```go
r.Routes() []RouteInfo
```

Returns all registered routes for inspection.

## Route

### Constraints

Apply validation constraints to route parameters:

```go
route.WhereInt(param string) *Route
route.WhereFloat(param string) *Route
route.WhereUUID(param string) *Route
route.WhereDate(param string) *Route
route.WhereDateTime(param string) *Route
route.WhereEnum(param string, values ...string) *Route
route.WhereRegex(param, pattern string) *Route
```

**Example:**

```go
r.GET("/users/:id", getUserHandler).WhereInt("id")
r.GET("/entities/:uuid", getEntityHandler).WhereUUID("uuid")
r.GET("/status/:state", getStatusHandler).WhereEnum("state", "active", "pending")
```

## Group

Route groups support the same methods as Router, with the group's prefix automatically prepended.

```go
group.GET(path string, handlers ...HandlerFunc) *Route
group.POST(path string, handlers ...HandlerFunc) *Route
group.Use(middleware ...HandlerFunc)
group.Group(prefix string, middleware ...HandlerFunc) *Group
```

## HandlerFunc

```go
type HandlerFunc func(*Context)
```

Handler function signature for route handlers and middleware.

**Example:**

```go
func handler(c *router.Context) {
    c.JSON(200, map[string]string{"message": "Hello"})
}
```

## Next Steps

- **Context API**: See [all Context methods](../context-api/)
- **Options**: Review [Router options](../options/)
- **Constraints**: Learn about [route constraints](../route-constraints/)
