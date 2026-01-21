---
title: "Migration"
linkTitle: "Migration"
weight: 150
keywords:
  - router migration
  - upgrading
  - breaking changes
  - gin migration
  - echo migration
description: >
  Migrate from Gin, Echo, or http.ServeMux to Rivaas Router.
---

This guide helps you migrate from other popular Go routers.

## Route Registration

{{< tabpane text=true >}}
{{% tab header="Gin" %}}

```go
gin := gin.Default()
gin.GET("/users/:id", getUserHandler)
gin.POST("/users", createUserHandler)
```

{{% /tab %}}
{{% tab header="Echo" %}}

```go
e := echo.New()
e.GET("/users/:id", getUserHandler)
e.POST("/users", createUserHandler)
```

{{% /tab %}}
{{% tab header="http.ServeMux" %}}

```go
mux := http.NewServeMux()
mux.HandleFunc("/users/", usersHandler)
mux.HandleFunc("/posts/", postsHandler)
```

{{% /tab %}}
{{% tab header="Rivaas Router" %}}

```go
r := router.MustNew()
r.GET("/users/:id", getUserHandler)
r.POST("/users", createUserHandler)
```

{{% /tab %}}
{{< /tabpane >}}

## Context Usage

{{< tabpane text=true >}}
{{% tab header="Gin" %}}

```go
func ginHandler(c *gin.Context) {
    id := c.Param("id")
    c.JSON(200, gin.H{"user_id": id})
}
```

{{% /tab %}}
{{% tab header="Echo" %}}

```go
func echoHandler(c echo.Context) error {
    id := c.Param("id")
    return c.JSON(200, map[string]string{"user_id": id})
}
```

{{% /tab %}}
{{% tab header="http.ServeMux" %}}

```go
func usersHandler(w http.ResponseWriter, r *http.Request) {
    path := strings.TrimPrefix(r.URL.Path, "/users/")
    userID := strings.Split(path, "/")[0]
    // Manual parameter extraction
}
```

{{% /tab %}}
{{% tab header="Rivaas Router" %}}

```go
func rivaasHandler(c *router.Context) {
    id := c.Param("id")
    c.JSON(200, map[string]string{"user_id": id})
}
```

{{% /tab %}}
{{< /tabpane >}}

## Middleware

{{< tabpane text=true >}}
{{% tab header="Gin" %}}

```go
gin.Use(gin.Logger(), gin.Recovery())
```

{{% /tab %}}
{{% tab header="Echo" %}}

```go
e.Use(middleware.Logger())
e.Use(middleware.Recover())
```

{{% /tab %}}
{{% tab header="http.ServeMux" %}}

```go
// Manual middleware chaining
handler := Logger(Recovery(mux))
http.ListenAndServe(":8080", handler)
```

{{% /tab %}}
{{% tab header="Rivaas Router" %}}

```go
r.Use(Logger(), Recovery())
```

{{% /tab %}}
{{< /tabpane >}}

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
