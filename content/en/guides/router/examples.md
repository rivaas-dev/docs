---
title: "Examples"
linkTitle: "Examples"
weight: 160
keywords:
  - router examples
  - code samples
  - patterns
  - use cases
description: >
  Complete working examples and common use cases.
---

This guide provides complete, working examples for common use cases.

## REST API Server

Complete REST API with CRUD operations:

```go
package main

import (
    "encoding/json"
    "net/http"
    "rivaas.dev/router"
)

type User struct {
    ID    string `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

var users = map[string]User{
    "1": {ID: "1", Name: "Alice", Email: "alice@example.com"},
    "2": {ID: "2", Name: "Bob", Email: "bob@example.com"},
}

func main() {
    r := router.MustNew()
    r.Use(Logger(), Recovery(), CORS())
    
    api := r.Group("/api/v1")
    api.Use(JSONContentType())
    {
        api.GET("/users", listUsers)
        api.POST("/users", createUser)
        api.GET("/users/:id", getUser)
        api.PUT("/users/:id", updateUser)
        api.DELETE("/users/:id", deleteUser)
    }
    
    http.ListenAndServe(":8080", r)
}

func listUsers(c *router.Context) {
    userList := make([]User, 0, len(users))
    for _, user := range users {
        userList = append(userList, user)
    }
    c.JSON(200, userList)
}

func getUser(c *router.Context) {
    id := c.Param("id")
    user, exists := users[id]
    if !exists {
        c.JSON(404, map[string]string{"error": "User not found"})
        return
    }
    c.JSON(200, user)
}

func createUser(c *router.Context) {
    var user User
    if err := json.NewDecoder(c.Request.Body).Decode(&user); err != nil {
        c.JSON(400, map[string]string{"error": "Invalid JSON"})
        return
    }
    users[user.ID] = user
    c.JSON(201, user)
}

func updateUser(c *router.Context) {
    id := c.Param("id")
    if _, exists := users[id]; !exists {
        c.JSON(404, map[string]string{"error": "User not found"})
        return
    }
    
    var user User
    if err := json.NewDecoder(c.Request.Body).Decode(&user); err != nil {
        c.JSON(400, map[string]string{"error": "Invalid JSON"})
        return
    }
    
    user.ID = id
    users[id] = user
    c.JSON(200, user)
}

func deleteUser(c *router.Context) {
    id := c.Param("id")
    if _, exists := users[id]; !exists {
        c.JSON(404, map[string]string{"error": "User not found"})
        return
    }
    delete(users, id)
    c.Status(204)
}
```

## Microservice Gateway

API gateway with service routing:

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    r.Use(Logger(), RateLimit(), Tracing())
    
    // Service discovery and routing
    r.GET("/users/*path", proxyToUserService)
    r.GET("/orders/*path", proxyToOrderService)
    r.GET("/payments/*path", proxyToPaymentService)
    
    // Health checks
    r.GET("/health", healthCheck)
    r.GET("/metrics", metricsHandler)
    
    http.ListenAndServe(":8080", r)
}

func proxyToUserService(c *router.Context) {
    path := c.Param("path")
    // Proxy to user service...
    c.JSON(200, map[string]string{"service": "users", "path": path})
}

func proxyToOrderService(c *router.Context) {
    path := c.Param("path")
    // Proxy to order service...
    c.JSON(200, map[string]string{"service": "orders", "path": path})
}

func proxyToPaymentService(c *router.Context) {
    path := c.Param("path")
    // Proxy to payment service...
    c.JSON(200, map[string]string{"service": "payments", "path": path})
}

func healthCheck(c *router.Context) {
    c.JSON(200, map[string]string{"status": "OK"})
}

func metricsHandler(c *router.Context) {
    c.String(200, "# HELP requests_total Total requests\n# TYPE requests_total counter\n")
}
```

## Static File Server with API

Serve static files alongside API routes:

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    
    // Serve static files
    r.Static("/assets", "./public")
    r.StaticFile("/favicon.ico", "./static/favicon.ico")
    
    // API routes
    api := r.Group("/api")
    {
        api.GET("/status", statusHandler)
        api.GET("/users", listUsersHandler)
    }
    
    http.ListenAndServe(":8080", r)
}

func statusHandler(c *router.Context) {
    c.JSON(200, map[string]string{"status": "OK"})
}

func listUsersHandler(c *router.Context) {
    c.JSON(200, []string{"user1", "user2"})
}
```

## Authentication & Authorization

Complete auth example with JWT:

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    r.Use(Logger(), Recovery())
    
    // Public routes
    r.POST("/login", loginHandler)
    r.POST("/register", registerHandler)
    
    // Protected routes
    api := r.Group("/api")
    api.Use(JWTAuth())
    {
        api.GET("/profile", profileHandler)
        api.PUT("/profile", updateProfileHandler)
        
        // Admin routes
        admin := api.Group("/admin")
        admin.Use(RequireAdmin())
        {
            admin.GET("/users", listUsersHandler)
            admin.DELETE("/users/:id", deleteUserHandler)
        }
    }
    
    http.ListenAndServe(":8080", r)
}

func loginHandler(c *router.Context) {
    // Authenticate user and generate JWT...
    c.JSON(200, map[string]string{"token": "jwt-token-here"})
}

func registerHandler(c *router.Context) {
    // Create new user...
    c.JSON(201, map[string]string{"message": "User created"})
}

func profileHandler(c *router.Context) {
    // Get user from context (set by JWT middleware)
    c.JSON(200, map[string]string{"user": "john@example.com"})
}

func updateProfileHandler(c *router.Context) {
    c.JSON(200, map[string]string{"message": "Profile updated"})
}

func listUsersHandler(c *router.Context) {
    c.JSON(200, []string{"user1", "user2"})
}

func deleteUserHandler(c *router.Context) {
    c.Status(204)
}

func JWTAuth() router.HandlerFunc {
    return func(c *router.Context) {
        token := c.Request.Header.Get("Authorization")
        if token == "" {
            c.JSON(401, map[string]string{"error": "Unauthorized"})
            return
        }
        // Validate JWT...
        c.Next()
    }
}

func RequireAdmin() router.HandlerFunc {
    return func(c *router.Context) {
        // Check if user is admin...
        c.Next()
    }
}
```

## Next Steps

- **API Reference**: Check [complete API documentation](/reference/packages/router/)
- **Source Code**: Browse the [example directory](https://github.com/rivaas-dev/rivaas/tree/main/router/examples) for more examples
