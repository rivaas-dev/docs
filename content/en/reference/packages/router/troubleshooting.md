---
title: "Troubleshooting"
linkTitle: "Troubleshooting"
weight: 70
description: >
  Common issues and solutions for the router package.
---

This guide helps you troubleshoot common issues with the Rivaas Router.

## Quick Reference

| Issue | Solution | Example |
|-------|----------|---------|
| **404 Route Not Found** | Check route syntax and order | `r.GET("/users/:id", handler)` |
| **Middleware Not Running** | Register before routes | `r.Use(middleware); r.GET("/path", handler)` |
| **Parameters Not Working** | Use `:param` syntax | `r.GET("/users/:id", handler)` |
| **CORS Issues** | Add CORS middleware | `r.Use(cors.New())` |
| **Memory Leaks** | Don't store context references | Extract data immediately |
| **Slow Performance** | Use route groups | `api := r.Group("/api")` |

## Common Issues

### Route Not Found (404 errors)

**Problem:** Routes not matching as expected.

**Solutions:**

```go
// ✅ Correct: Use :param syntax
r.GET("/users/:id", handler)

// ❌ Wrong: Don't use {param} syntax
r.GET("/users/{id}", handler)

// ✅ Correct: Static route
r.GET("/users/me", currentUserHandler)

// Check route registration order
r.GET("/users/me", currentUserHandler)      // Register specific routes first
r.GET("/users/:id", getUserHandler)         // Then parameter routes
```

### Middleware Not Executing

**Problem:** Middleware doesn't run for routes.

**Solution:** Register middleware before routes.

```go
// ✅ Correct: Middleware before routes
r.Use(Logger())
r.GET("/api/users", handler)

// ❌ Wrong: Routes before middleware
r.GET("/api/users", handler)
r.Use(Logger()) // Too late!

// ✅ Correct: Group middleware
api := r.Group("/api")
api.Use(Auth())
api.GET("/users", handler)
```

### Parameter Constraints Not Working

**Problem:** Invalid parameters still match routes.

**Solution:** Apply constraints to routes.

```go
// ✅ Correct: Integer constraint
r.GET("/users/:id", handler).WhereInt("id")

// ✅ Correct: Custom regex
r.GET("/files/:name", handler).WhereRegex("name", `[a-zA-Z0-9.-]+`)

// ❌ Wrong: No constraint (matches anything)
r.GET("/users/:id", handler) // Matches "/users/abc"
```

### Memory Leaks

**Problem:** Growing memory usage.

**Solution:** Never store Context references.

```go
// ❌ Wrong: Storing context
var globalContext *router.Context
func handler(c *router.Context) {
    globalContext = c // Memory leak!
}

// ✅ Correct: Extract data immediately
func handler(c *router.Context) {
    userID := c.Param("id")
    // Use userID, not c
    processUser(userID)
}

// ✅ Correct: Copy data for async operations
func handler(c *router.Context) {
    userID := c.Param("id")
    go func(id string) {
        processAsync(id)
    }(userID)
}
```

### CORS Issues

**Problem:** CORS errors in browser.

**Solution:** Add CORS middleware.

```go
import "rivaas.dev/router/middleware/cors"

r.Use(cors.New(
    cors.WithAllowedOrigins("https://example.com"),
    cors.WithAllowedMethods("GET", "POST", "PUT", "DELETE"),
    cors.WithAllowedHeaders("Content-Type", "Authorization"),
))
```

### Slow Performance

**Problem:** Routes are slow.

**Solutions:**

```go
// ✅ Use route groups
api := r.Group("/api")
api.GET("/users", handler)
api.GET("/posts", handler)

// ✅ Minimize middleware
r.Use(Recovery()) // Essential only

// ✅ Apply constraints for parameter validation
r.GET("/users/:id", handler).WhereInt("id")

// ❌ Don't parse parameters manually
func handler(c *router.Context) {
    // id, err := strconv.Atoi(c.Param("id")) // Slow
    id := c.Param("id") // Fast
}
```

### Validation Errors

**Problem:** Validation not working.

**Solutions:**

```go
// ✅ Register custom tags in init()
func init() {
    router.RegisterTag("custom", validatorFunc)
}

// ✅ Use correct strategy
func createUser(c *router.Context) {
    var req CreateUserRequest
    if !c.MustBindAndValidate(&req) {
        return
    }
}

// ✅ Partial validation for PATCH
func updateUser(c *router.Context) {
    var req UpdateUserRequest
    if !c.MustBindAndValidate(&req, router.WithPartial(true)) {
        return
    }
}
```

## FAQ

### Can I use standard HTTP middleware?

Yes! Adapt existing middleware:

```go
func adaptMiddleware(next http.Handler) router.HandlerFunc {
    return func(c *router.Context) {
        next.ServeHTTP(c.Writer, c.Request)
    }
}
```

### Is the router production-ready?

Yes. The router is production-ready with:

- 84.8% code coverage
- Comprehensive test suite
- Zero race conditions
- 8.4M+ req/s throughput

### How do I handle CORS?

Use the built-in CORS middleware:

```go
import "rivaas.dev/router/middleware/cors"

r.Use(cors.New(
    cors.WithAllowedOrigins("*"),
    cors.WithAllowedMethods("GET", "POST", "PUT", "DELETE"),
))
```

### Why are my parameters not working?

Check the parameter syntax:

```go
// ✅ Correct
r.GET("/users/:id", handler)
id := c.Param("id")

// ❌ Wrong syntax
r.GET("/users/{id}", handler) // Use :id instead
```

### How do I debug routing issues?

Use route introspection:

```go
routes := r.Routes()
for _, route := range routes {
    fmt.Printf("%s %s -> %s\n", route.Method, route.Path, route.HandlerName)
}
```

## Getting Help

- **Documentation**: Check the [Router Guide](/guides/router/)
- **Examples**: Browse [working examples](/guides/router/examples/)
- **Source Code**: [GitHub Repository](https://github.com/rivaas-dev/rivaas)
- **API Reference**: [pkg.go.dev](https://pkg.go.dev/rivaas.dev/router)

## Next Steps

- **API Reference**: See [core types](../api-reference/)
- **Context API**: Check [Context methods](../context-api/)
- **Examples**: Browse [complete examples](/guides/router/examples/)
