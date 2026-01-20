---
title: "Route Patterns"
linkTitle: "Route Patterns"
weight: 30
description: >
  Learn about static routes, parameter routes, wildcards, and route matching priority.
---

The Rivaas Router supports multiple route patterns, from simple static routes to dynamic parameters and wildcards.

## Static Routes

Static routes match exact path strings and have the best performance:

```go
r.GET("/", homeHandler)
r.GET("/about", aboutHandler)
r.GET("/api/health", healthHandler)
r.GET("/admin/dashboard", dashboardHandler)
```

**Characteristics:**

- Exact string match required.
- Fastest route type. Sub-microsecond lookups.
- Uses hash table lookups with bloom filters.
- No pattern matching overhead.

```bash
curl http://localhost:8080/about
# Matches: /about
# Does NOT match: /about/, /about/us
```

## Parameter Routes

Routes can capture dynamic segments using the `:param` syntax:

### Single Parameter

```go
// Capture user ID
r.GET("/users/:id", func(c *router.Context) {
    userID := c.Param("id")
    c.JSON(200, map[string]string{"user_id": userID})
})
```

**Matches:**

- `/users/123` → `id="123"`
- `/users/abc` → `id="abc"`
- `/users/uuid-here` → `id="uuid-here"`

**Does NOT match:**

- `/users` - missing parameter
- `/users/` - empty parameter
- `/users/123/posts` - too many segments

### Multiple Parameters

```go
r.GET("/users/:id/posts/:post_id", func(c *router.Context) {
    userID := c.Param("id")
    postID := c.Param("post_id")
    c.JSON(200, map[string]string{
        "user_id": userID,
        "post_id": postID,
    })
})
```

**Matches:**

- `/users/123/posts/456` → `id="123"`, `post_id="456"`
- `/users/alice/posts/hello-world` → `id="alice"`, `post_id="hello-world"`

### Mixed Static and Parameter Segments

```go
r.GET("/api/v1/users/:id/profile", userProfileHandler)
r.GET("/organizations/:org/teams/:team/members", membersHandler)
```

**Example:**

- `/api/v1/users/123/profile` → `id="123"`
- `/organizations/acme/teams/engineering/members` → `org="acme"`, `team="engineering"`

## Wildcard Routes

Wildcard routes capture the rest of the path using `*param`:

```go
// Serve files from any path under /files/
r.GET("/files/*filepath", func(c *router.Context) {
    filepath := c.Param("filepath")
    c.JSON(200, map[string]string{"filepath": filepath})
})
```

**Matches:**

- `/files/images/logo.png` → `filepath="images/logo.png"`
- `/files/docs/api/v1/index.html` → `filepath="docs/api/v1/index.html"`
- `/files/a/b/c/d/e/f.txt` → `filepath="a/b/c/d/e/f.txt"`

**Important:**

- Wildcards match **everything** after their position, including slashes
- Only **one wildcard** per route
- Wildcard must be the **last segment**

```go
// ✅ Valid
r.GET("/static/*filepath", handler)
r.GET("/api/v1/files/*path", handler)

// ❌ Invalid - wildcard must be last
r.GET("/files/*path/metadata", handler) // Won't work

// ❌ Invalid - only one wildcard
r.GET("/files/*path1/other/*path2", handler) // Won't work
```

## Route Matching Priority

When multiple routes could match a request, the router follows this priority order:

### 1. Static Routes (Highest Priority)

Exact matches are evaluated first:

```go
r.GET("/users/me", currentUserHandler)      // Static
r.GET("/users/:id", getUserHandler)         // Parameter
```

**Request:** `GET /users/me`

- ✅ Matches `/users/me` (static) - **Selected**
- ❌ Could match `/users/:id` but static wins

### 2. Parameter Routes

After static routes, parameter routes are checked:

```go
r.GET("/posts/:id", getPostHandler)
r.GET("/posts/*filepath", catchAllHandler)
```

**Request:** `GET /posts/123`

- ❌ No static match
- ✅ Matches `/posts/:id` - **Selected**
- ❌ Could match `/posts/*filepath` but parameter wins

### 3. Wildcard Routes (Lowest Priority)

Wildcards are the catch-all:

```go
r.GET("/files/*filepath", serveFileHandler)
```

**Request:** `GET /files/images/logo.png`

- ❌ No static match
- ❌ No parameter match
- ✅ Matches `/files/*filepath` - **Selected**

### Priority Examples

```go
func main() {
    r := router.MustNew()
    
    // Priority 1: Static
    r.GET("/users/me", func(c *router.Context) {
        c.String(200, "Current user")
    })
    
    // Priority 2: Parameter
    r.GET("/users/:id", func(c *router.Context) {
        c.String(200, "User: "+c.Param("id"))
    })
    
    // Priority 3: Wildcard
    r.GET("/users/*path", func(c *router.Context) {
        c.String(200, "Catch-all: "+c.Param("path"))
    })
    
    http.ListenAndServe(":8080", r)
}
```

**Tests:**

```bash
curl http://localhost:8080/users/me
# Output: "Current user" (static route)

curl http://localhost:8080/users/123
# Output: "User: 123" (parameter route)

curl http://localhost:8080/users/123/posts
# Output: "Catch-all: 123/posts" (wildcard route)
```

## Parameter Design Best Practices

The router optimizes parameter storage for routes with ≤8 parameters using fast array-based storage. Routes with >8 parameters fall back to map-based storage.

### Optimization Threshold

- **≤8 parameters**: Array-based storage (fastest, zero allocations)
- **>8 parameters**: Map-based storage (one allocation per request)

### Best Practices

#### 1. Keep Parameter Count ≤8

```go
// ✅ GOOD: 2 parameters
r.GET("/users/:id/posts/:post_id", handler)

// ✅ GOOD: 4 parameters
r.GET("/api/:version/users/:id/posts/:post_id/comments/:comment_id", handler)

// ⚠️ WARNING: 9 parameters (requires map allocation)
r.GET("/a/:p1/b/:p2/c/:p3/d/:p4/e/:p5/f/:p6/g/:p7/h/:p8/i/:p9", handler)
```

#### 2. Use Query Parameters for Additional Data

Instead of many path parameters, use query parameters:

```go
// ❌ BAD: Too many path parameters
r.GET("/search/:category/:subcategory/:type/:status/:sort/:order/:page/:limit", handler)

// ✅ GOOD: Use query parameters for filters
r.GET("/search/:category", handler)
// Query: ?subcategory=electronics&type=product&status=active&sort=price&order=asc&page=1&limit=20
```

#### 3. Use Request Body for Complex Data

For complex operations, use the request body:

```go
// ❌ BAD: Many path parameters
r.POST("/api/:version/:resource/:action/:target/:scope/:context/:mode/:format", handler)

// ✅ GOOD: Use request body
r.POST("/api/v1/operations", handler)
// Body: {"resource": "...", "action": "...", "target": "...", ...}
```

#### 4. Restructure Routes

Flatten hierarchies or consolidate parameters:

```go
// ❌ BAD: 10 parameters in path
r.GET("/:a/:b/:c/:d/:e/:f/:g/:h/:i/:j", handler)

// ✅ GOOD: Flatten hierarchy or use query parameters
r.GET("/items", handler) // Use query: ?a=...&b=...&c=...
```

### Runtime Warnings

The router automatically logs a warning when registering routes with >8 parameters:

```text
WARN: route has more than 8 parameters, using map storage instead of fast array
  method=GET
  path=/api/:v1/:r1/:r2/:r3/:r4/:r5/:r6/:r7/:r8/:r9
  param_count=9
  recommendation=consider restructuring route to use query parameters or request body for additional data
```

### When >8 Parameters Are Acceptable

- Low-frequency endpoints (<100 req/s)
- Legacy API compatibility requirements
- Complex hierarchical resource structures that can't be flattened

### Performance Impact

- **≤8 params**: ~119ns/op, 0 allocations
- **>8 params**: ~119ns/op, 1 allocation (~24 bytes)
- **Real-world impact**: Negligible for most applications (<1% overhead)

## Route Constraints

Add validation to parameters with constraints:

```go
// Integer constraint
r.GET("/users/:id", getUserHandler).WhereInt("id")

// UUID constraint
r.GET("/entities/:uuid", getEntityHandler).WhereUUID("uuid")

// Custom regex
r.GET("/files/:filename", getFileHandler).WhereRegex("filename", `[a-zA-Z0-9.-]+`)

// Enum constraint
r.GET("/status/:state", getStatusHandler).WhereEnum("state", "active", "pending", "deleted")
```

**Learn more:** See the [Route Constraints reference](/reference/packages/router/route-constraints/) for all available constraints.

## Common Patterns

### RESTful Resources

```go
// Standard REST endpoints
r.GET("/users", listUsers)              // List all
r.POST("/users", createUser)            // Create new
r.GET("/users/:id", getUser)            // Get one
r.PUT("/users/:id", updateUser)         // Update (full)
r.PATCH("/users/:id", patchUser)        // Update (partial)
r.DELETE("/users/:id", deleteUser)      // Delete
```

### Nested Resources

```go
// Comments belong to posts
r.GET("/posts/:post_id/comments", listComments)
r.POST("/posts/:post_id/comments", createComment)
r.GET("/posts/:post_id/comments/:id", getComment)
r.PUT("/posts/:post_id/comments/:id", updateComment)
r.DELETE("/posts/:post_id/comments/:id", deleteComment)
```

### Action Routes

```go
// Actions on resources
r.POST("/users/:id/activate", activateUser)
r.POST("/users/:id/deactivate", deactivateUser)
r.POST("/posts/:id/publish", publishPost)
r.POST("/orders/:id/cancel", cancelOrder)
```

### File Serving

```go
// Static file serving
r.GET("/assets/*filepath", serveAssets)
r.GET("/downloads/*filepath", serveDownloads)

func serveAssets(c *router.Context) {
    filepath := c.Param("filepath")
    c.ServeFile("./public/" + filepath)
}
```

## Anti-Patterns

### Avoid Ambiguous Routes

```go
// ❌ BAD: Ambiguous - which route matches /users/delete?
r.GET("/users/:id", getUser)
r.DELETE("/users/:action", performAction)

// ✅ GOOD: Clear distinction
r.GET("/users/:id", getUser)
r.POST("/users/:id/actions/:action", performAction)
```

### Avoid Overly Deep Hierarchies

```go
// ❌ BAD: Too deep
r.GET("/api/v1/organizations/:org/teams/:team/projects/:proj/tasks/:task/comments/:id", handler)

// ✅ GOOD: Flatten or use query parameters
r.GET("/api/v1/comments/:id", handler) // Include org/team/proj/task in query or auth context
```

## Next Steps

- **Route Groups**: Learn to [organize routes](../route-groups/) with groups and prefixes
- **Middleware**: Add [middleware](../middleware/) for authentication, logging, etc.
- **Constraints**: See all [route constraints](/reference/packages/router/route-constraints/) available
