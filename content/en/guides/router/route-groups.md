---
title: "Route Groups"
linkTitle: "Route Groups"
weight: 40
description: >
  Organize routes with groups, shared prefixes, and group-specific middleware.
---

Route groups help organize related routes. They share a common prefix. They can apply middleware to specific sets of routes.

## Basic Groups

Create a group with a common prefix:

```go
func main() {
    r := router.MustNew()
    r.Use(Logger()) // Global middleware
    
    // API v1 group
    v1 := r.Group("/api/v1")
    v1.GET("/users", listUsersV1)
    v1.POST("/users", createUserV1)
    v1.GET("/users/:id", getUserV1)
    
    http.ListenAndServe(":8080", r)
}
```

**Routes created:**

- `GET /api/v1/users`
- `POST /api/v1/users`
- `GET /api/v1/users/:id`

## Group-Specific Middleware

Apply middleware that only affects routes in the group:

```go
func main() {
    r := router.MustNew()
    r.Use(Logger()) // Global - applies to all routes
    
    // Public API - no auth required
    public := r.Group("/api/public")
    public.GET("/health", healthHandler)
    public.GET("/version", versionHandler)
    
    // Private API - auth required
    private := r.Group("/api/private")
    private.Use(AuthRequired()) // Group middleware
    private.GET("/profile", profileHandler)
    private.POST("/settings", updateSettingsHandler)
    
    http.ListenAndServe(":8080", r)
}

func AuthRequired() router.HandlerFunc {
    return func(c *router.Context) {
        token := c.Request.Header.Get("Authorization")
        if token == "" {
            c.JSON(401, map[string]string{"error": "Unauthorized"})
            return
        }
        c.Next()
    }
}
```

**Middleware execution:**

- `/api/public/health` → Logger only.
- `/api/private/profile` → Logger + AuthRequired.

## Nested Groups

Groups can be nested for hierarchical organization:

```go
func main() {
    r := router.MustNew()
    r.Use(Logger())
    
    api := r.Group("/api")
    {
        v1 := api.Group("/v1")
        v1.Use(RateLimitV1()) // V1-specific rate limiting
        {
            // User endpoints
            users := v1.Group("/users")
            users.Use(UserAuth())
            {
                users.GET("/", listUsers)          // GET /api/v1/users/
                users.POST("/", createUser)        // POST /api/v1/users/
                users.GET("/:id", getUser)         // GET /api/v1/users/:id
                users.PUT("/:id", updateUser)      // PUT /api/v1/users/:id
                users.DELETE("/:id", deleteUser)   // DELETE /api/v1/users/:id
            }
            
            // Admin endpoints
            admin := v1.Group("/admin")
            admin.Use(AdminAuth())
            {
                admin.GET("/stats", getStats)                    // GET /api/v1/admin/stats
                admin.DELETE("/users/:id", adminDeleteUser)      // DELETE /api/v1/admin/users/:id
            }
        }
        
        v2 := api.Group("/v2")
        v2.Use(RateLimitV2()) // V2-specific rate limiting
        {
            v2.GET("/users", listUsersV2)
            v2.POST("/users", createUsersV2)
        }
    }
    
    http.ListenAndServe(":8080", r)
}
```

**Routes created:**

```
GET    /api/v1/users/
POST   /api/v1/users/
GET    /api/v1/users/:id
PUT    /api/v1/users/:id
DELETE /api/v1/users/:id
GET    /api/v1/admin/stats
DELETE /api/v1/admin/users/:id
GET    /api/v2/users
POST   /api/v2/users
```

## Middleware Execution Order

For nested groups, middleware executes from outer to inner:

```go
r.Use(GlobalMiddleware())                   // 1st
api := r.Group("/api", APIMiddleware())     // 2nd
v1 := api.Group("/v1", V1Middleware())      // 3rd
users := v1.Group("/users", UsersMiddleware()) // 4th
users.GET("/:id", RouteMiddleware(), handler)  // 5th → handler

// Execution order:
// GlobalMiddleware → APIMiddleware → V1Middleware → UsersMiddleware → RouteMiddleware → handler
```

**Example with logging:**

```go
func main() {
    r := router.MustNew()
    
    r.Use(func(c *router.Context) {
        fmt.Println("1. Global middleware")
        c.Next()
    })
    
    api := r.Group("/api")
    api.Use(func(c *router.Context) {
        fmt.Println("2. API middleware")
        c.Next()
    })
    
    v1 := api.Group("/v1")
    v1.Use(func(c *router.Context) {
        fmt.Println("3. V1 middleware")
        c.Next()
    })
    
    v1.GET("/test", func(c *router.Context) {
        fmt.Println("4. Handler")
        c.String(200, "OK")
    })
    
    http.ListenAndServe(":8080", r)
}
```

**Request to `/api/v1/test` prints:**

```
1. Global middleware
2. API middleware
3. V1 middleware
4. Handler
```

## Composing Group Middleware

Create reusable middleware bundles:

```go
// Middleware bundles
func PublicAPI() []router.HandlerFunc {
    return []router.HandlerFunc{
        CORS(),
        RateLimit(1000),
    }
}

func AuthenticatedAPI() []router.HandlerFunc {
    return []router.HandlerFunc{
        CORS(),
        RateLimit(100),
        AuthRequired(),
    }
}

func AdminAPI() []router.HandlerFunc {
    return []router.HandlerFunc{
        CORS(),
        RateLimit(50),
        AuthRequired(),
        AdminOnly(),
    }
}

func main() {
    r := router.MustNew()
    r.Use(Logger(), Recovery())
    
    // Public endpoints
    public := r.Group("/api/public")
    public.Use(PublicAPI()...)
    public.GET("/status", statusHandler)
    
    // User endpoints
    user := r.Group("/api/user")
    user.Use(AuthenticatedAPI()...)
    user.GET("/profile", profileHandler)
    
    // Admin endpoints
    admin := r.Group("/api/admin")
    admin.Use(AdminAPI()...)
    admin.GET("/users", listUsersAdmin)
    
    http.ListenAndServe(":8080", r)
}
```

## Organizing by Resource

Structure your API around resources:

```go
func main() {
    r := router.MustNew()
    r.Use(Logger(), Recovery())
    
    // Setup route groups
    setupUserRoutes(r)
    setupPostRoutes(r)
    setupCommentRoutes(r)
    
    http.ListenAndServe(":8080", r)
}

func setupUserRoutes(r *router.Router) {
    users := r.Group("/api/users")
    users.Use(JSONContentType())
    
    users.GET("/", listUsers)
    users.POST("/", createUser)
    users.GET("/:id", getUser)
    users.PUT("/:id", updateUser)
    users.DELETE("/:id", deleteUser)
}

func setupPostRoutes(r *router.Router) {
    posts := r.Group("/api/posts")
    posts.Use(JSONContentType())
    
    posts.GET("/", listPosts)
    posts.POST("/", AuthRequired(), createPost)
    posts.GET("/:id", getPost)
    posts.PUT("/:id", AuthRequired(), updatePost)
    posts.DELETE("/:id", AuthRequired(), deletePost)
}

func setupCommentRoutes(r *router.Router) {
    comments := r.Group("/api/comments")
    comments.Use(JSONContentType())
    
    comments.GET("/", listComments)
    comments.POST("/", AuthRequired(), createComment)
    comments.GET("/:id", getComment)
    comments.PUT("/:id", AuthRequired(), updateComment)
    comments.DELETE("/:id", AuthRequired(), deleteComment)
}
```

## Versioning with Groups

Organize API versions:

```go
func main() {
    r := router.MustNew()
    r.Use(Logger())
    
    // Version 1 - Stable API
    v1 := r.Group("/api/v1")
    v1.Use(JSONContentType())
    {
        v1.GET("/users", listUsersV1)
        v1.GET("/users/:id", getUserV1)
        v1.GET("/posts", listPostsV1)
    }
    
    // Version 2 - New features
    v2 := r.Group("/api/v2")
    v2.Use(JSONContentType())
    {
        v2.GET("/users", listUsersV2)        // Enhanced user list
        v2.GET("/users/:id", getUserV2)      // Additional fields
        v2.GET("/posts", listPostsV2)        // Pagination support
        v2.GET("/posts/:id/likes", getPostLikesV2) // New endpoint
    }
    
    // Beta features
    beta := r.Group("/api/beta")
    beta.Use(JSONContentType(), BetaWarning())
    {
        beta.GET("/experimental", experimentalFeature)
    }
    
    http.ListenAndServe(":8080", r)
}
```

## Group Configuration Patterns

### Pattern 1: Inline Configuration

```go
api := r.Group("/api")
api.Use(Logger(), Auth())
api.GET("/users", handler)
api.POST("/users", handler)
```

### Pattern 2: Block Scope

```go
api := r.Group("/api")
{
    api.Use(Logger(), Auth())
    api.GET("/users", handler)
    api.POST("/users", handler)
}
```

### Pattern 3: Function-Based Setup

```go
setupAPIRoutes := func(parent *router.Group) {
    api := parent.Group("/api")
    api.Use(Logger(), Auth())
    api.GET("/users", handler)
    api.POST("/users", handler)
}

setupAPIRoutes(r)
```

## Best Practices

### 1. Group Related Routes

```go
// ✅ GOOD: Related routes grouped
users := r.Group("/api/users")
users.GET("/", listUsers)
users.POST("/", createUser)
users.GET("/:id", getUser)

// ❌ BAD: Scattered registration
r.GET("/api/users", listUsers)
r.GET("/api/posts", listPosts)
r.POST("/api/users", createUser)
```

### 2. Apply Middleware at the Right Level

```go
// ✅ GOOD: Auth only where needed
public := r.Group("/api/public")
public.GET("/status", statusHandler)

private := r.Group("/api/private")
private.Use(AuthRequired())
private.GET("/profile", profileHandler)

// ❌ BAD: Auth on everything
r.Use(AuthRequired()) // Public endpoints won't work!
r.GET("/api/status", statusHandler)
```

### 3. Use Descriptive Names

```go
// ✅ GOOD: Clear purpose
adminAPI := r.Group("/admin")
userAPI := r.Group("/user")
publicAPI := r.Group("/public")

// ❌ BAD: Unclear
g1 := r.Group("/api")
g2 := r.Group("/routes")
group := r.Group("/stuff")
```

### 4. Keep Nesting Shallow

```go
// ✅ GOOD: 2-3 levels
api := r.Group("/api")
v1 := api.Group("/v1")
v1.GET("/users", handler)

// ⚠️ OKAY: 4 levels (limit)
api := r.Group("/api")
v1 := api.Group("/v1")
users := v1.Group("/users")
users.GET("/:id", handler)

// ❌ BAD: Too deep (5+ levels)
api := r.Group("/api")
v1 := api.Group("/v1")
orgs := v1.Group("/orgs")
teams := orgs.Group("/:org/teams")
projects := teams.Group("/:team/projects")
projects.GET("/", handler) // /api/v1/orgs/:org/teams/:team/projects/
```

## Complete Example

```go
package main

import (
    "fmt"
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    
    // Global middleware
    r.Use(Logger(), Recovery())
    
    // Public routes (no auth)
    public := r.Group("/api/public")
    public.Use(CORS())
    {
        public.GET("/health", healthHandler)
        public.GET("/version", versionHandler)
    }
    
    // API v1
    v1 := r.Group("/api/v1")
    v1.Use(CORS(), JSONContentType())
    {
        // User routes (auth required)
        users := v1.Group("/users")
        users.Use(AuthRequired())
        {
            users.GET("/", listUsers)
            users.POST("/", createUser)
            users.GET("/:id", getUser)
            users.PUT("/:id", updateUser)
            users.DELETE("/:id", deleteUser)
        }
        
        // Admin routes (admin auth required)
        admin := v1.Group("/admin")
        admin.Use(AuthRequired(), AdminOnly())
        {
            admin.GET("/stats", adminStats)
            admin.GET("/users", adminListUsers)
        }
    }
    
    fmt.Println("Server starting on :8080")
    http.ListenAndServe(":8080", r)
}

// Middleware
func Logger() router.HandlerFunc {
    return func(c *router.Context) {
        fmt.Printf("[%s] %s\n", c.Request.Method, c.Request.URL.Path)
        c.Next()
    }
}

func Recovery() router.HandlerFunc {
    return func(c *router.Context) {
        defer func() {
            if err := recover(); err != nil {
                c.JSON(500, map[string]string{"error": "Internal server error"})
            }
        }()
        c.Next()
    }
}

func CORS() router.HandlerFunc {
    return func(c *router.Context) {
        c.Header("Access-Control-Allow-Origin", "*")
        c.Next()
    }
}

func JSONContentType() router.HandlerFunc {
    return func(c *router.Context) {
        c.Header("Content-Type", "application/json")
        c.Next()
    }
}

func AuthRequired() router.HandlerFunc {
    return func(c *router.Context) {
        token := c.Request.Header.Get("Authorization")
        if token == "" {
            c.JSON(401, map[string]string{"error": "Unauthorized"})
            return
        }
        c.Next()
    }
}

func AdminOnly() router.HandlerFunc {
    return func(c *router.Context) {
        // Check if user is admin...
        c.Next()
    }
}

// Handlers (simplified)
func healthHandler(c *router.Context) { c.String(200, "OK") }
func versionHandler(c *router.Context) { c.String(200, "v1.0.0") }
func listUsers(c *router.Context) { c.JSON(200, []string{"user1", "user2"}) }
func createUser(c *router.Context) { c.JSON(201, map[string]string{"id": "1"}) }
func getUser(c *router.Context) { c.JSON(200, map[string]string{"id": c.Param("id")}) }
func updateUser(c *router.Context) { c.JSON(200, map[string]string{"id": c.Param("id")}) }
func deleteUser(c *router.Context) { c.Status(204) }
func adminStats(c *router.Context) { c.JSON(200, map[string]int{"users": 100}) }
func adminListUsers(c *router.Context) { c.JSON(200, []string{"all", "users"}) }
```

## Next Steps

- **Middleware**: Learn about [middleware](../middleware/) in detail
- **Context**: Understand the [Context API](../context/) for request/response handling
- **Examples**: See [complete examples](../examples/) of group-based organization
