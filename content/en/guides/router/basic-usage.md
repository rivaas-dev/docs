---
title: "Basic Usage"
linkTitle: "Basic Usage"
weight: 20
description: >
  Learn the fundamentals of the Rivaas Router - from your first router to handling requests.
---

This guide introduces the core concepts of the Rivaas Router through progressive examples.

## Your First Router

Let's start with the simplest possible router:

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()  // Panics on invalid config (use at startup)
    
    r.GET("/", func(c *router.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello, Rivaas Router!",
        })
    })
    
    http.ListenAndServe(":8080", r)
}
```

**What's happening here:**

1. `router.MustNew()` creates a new router instance. Panics on invalid config.
2. `r.GET("/", handler)` registers a handler for GET requests to `/`.
3. The handler function receives a `*router.Context` with request and response information.
4. `c.JSON()` sends a JSON response.
5. `http.ListenAndServe()` starts the HTTP server.

Test it:

```bash
curl http://localhost:8080/
# Output: {"message":"Hello, Rivaas Router!"}
```

## Adding Routes with Parameters

Routes can capture dynamic segments from the URL path:

```go
func main() {
    r := router.MustNew()
    
    // Static route
    r.GET("/", func(c *router.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Welcome to Rivaas Router",
        })
    })
    
    // Single parameter
    r.GET("/users/:id", func(c *router.Context) {
        userID := c.Param("id")
        c.JSON(http.StatusOK, map[string]string{
            "user_id": userID,
            "message": "User found",
        })
    })
    
    // Multiple parameters
    r.GET("/users/:id/posts/:post_id", func(c *router.Context) {
        userID := c.Param("id")
        postID := c.Param("post_id")
        c.JSON(http.StatusOK, map[string]string{
            "user_id": userID,
            "post_id": postID,
        })
    })
    
    http.ListenAndServe(":8080", r)
}
```

**Parameter syntax:**

- `:name` - Captures a path segment and stores it under the given name.
- Access with `c.Param("name")`.
- Parameters match any non-slash characters.

Test it:

```bash
curl http://localhost:8080/users/123
# Output: {"user_id":"123","message":"User found"}

curl http://localhost:8080/users/123/posts/456
# Output: {"user_id":"123","post_id":"456"}
```

## HTTP Methods

The router supports all standard HTTP methods:

```go
func main() {
    r := router.MustNew()
    
    r.GET("/users", listUsers)          // List all users
    r.POST("/users", createUser)        // Create a new user
    r.GET("/users/:id", getUser)        // Get a specific user
    r.PUT("/users/:id", updateUser)     // Update a user (full replacement)
    r.PATCH("/users/:id", patchUser)    // Partial update
    r.DELETE("/users/:id", deleteUser)  // Delete a user
    r.HEAD("/users/:id", headUser)      // Check if user exists
    r.OPTIONS("/users", optionsUsers)   // Get available methods
    
    http.ListenAndServe(":8080", r)
}

func listUsers(c *router.Context) {
    c.JSON(200, []string{"user1", "user2"})
}

func createUser(c *router.Context) {
    c.JSON(201, map[string]string{"message": "User created"})
}

func getUser(c *router.Context) {
    c.JSON(200, map[string]string{"user_id": c.Param("id")})
}

func updateUser(c *router.Context) {
    c.JSON(200, map[string]string{"message": "User updated"})
}

func patchUser(c *router.Context) {
    c.JSON(200, map[string]string{"message": "User patched"})
}

func deleteUser(c *router.Context) {
    c.Status(204) // No Content
}

func headUser(c *router.Context) {
    c.Status(200) // OK, no body
}

func optionsUsers(c *router.Context) {
    c.Header("Allow", "GET, POST, OPTIONS")
    c.Status(200)
}
```

## Reading Request Data

### Query Parameters

Access query string parameters with `c.Query()`:

```go
// GET /search?q=golang&limit=10
r.GET("/search", func(c *router.Context) {
    query := c.Query("q")
    limit := c.Query("limit")
    
    c.JSON(200, map[string]string{
        "query": query,
        "limit": limit,
    })
})
```

Test it:

```bash
curl "http://localhost:8080/search?q=golang&limit=10"
# Output: {"query":"golang","limit":"10"}
```

### Form Data

Access POST form data with `c.FormValue()`:

```go
// POST /login with form data
r.POST("/login", func(c *router.Context) {
    username := c.FormValue("username")
    password := c.FormValue("password")
    
    // Validate credentials...
    c.JSON(200, map[string]string{
        "username": username,
        "status": "logged in",
    })
})
```

Test it:

```bash
curl -X POST http://localhost:8080/login \
  -d "username=john" \
  -d "password=secret"
# Output: {"username":"john","status":"logged in"}
```

### JSON Request Body

Parse JSON request bodies:

```go
r.POST("/users", func(c *router.Context) {
    var req struct {
        Name  string `json:"name"`
        Email string `json:"email"`
    }
    
    if err := json.NewDecoder(c.Request.Body).Decode(&req); err != nil {
        c.JSON(400, map[string]string{"error": "Invalid JSON"})
        return
    }
    
    c.JSON(201, map[string]interface{}{
        "id":    "123",
        "name":  req.Name,
        "email": req.Email,
    })
})
```

Test it:

```bash
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
# Output: {"id":"123","name":"John Doe","email":"john@example.com"}
```

## Error Handling

Always handle errors and provide meaningful responses:

```go
r.GET("/users/:id", func(c *router.Context) {
    userID := c.Param("id")
    
    // Validate user ID
    if userID == "" {
        c.JSON(400, map[string]string{
            "error": "User ID is required",
        })
        return
    }
    
    // Simulate user lookup
    user, err := findUser(userID)
    if err != nil {
        if err == ErrUserNotFound {
            c.JSON(404, map[string]string{
                "error": "User not found",
            })
        } else {
            c.JSON(500, map[string]string{
                "error": "Internal server error",
            })
        }
        return
    }
    
    c.JSON(200, user)
})
```

## Response Types

The router supports multiple response formats:

### JSON Responses

```go
// Standard JSON
r.GET("/json", func(c *router.Context) {
    c.JSON(200, map[string]string{"message": "JSON response"})
})

// Indented JSON (for debugging)
r.GET("/json-pretty", func(c *router.Context) {
    c.IndentedJSON(200, map[string]string{"message": "Pretty JSON"})
})
```

### Plain Text

```go
r.GET("/text", func(c *router.Context) {
    c.String(200, "Plain text response")
})

// With formatting
r.GET("/text-formatted", func(c *router.Context) {
    c.Stringf(200, "Hello, %s!", "World")
})
```

### HTML

```go
r.GET("/html", func(c *router.Context) {
    c.HTML(200, "<h1>Hello, World!</h1>")
})
```

### Status Only

```go
r.DELETE("/users/:id", func(c *router.Context) {
    // Delete user...
    c.Status(204) // No Content
})
```

## Working with Headers

### Reading Headers

```go
r.GET("/headers", func(c *router.Context) {
    userAgent := c.Request.Header.Get("User-Agent")
    contentType := c.Request.Header.Get("Content-Type")
    
    c.JSON(200, map[string]string{
        "user_agent":   userAgent,
        "content_type": contentType,
    })
})
```

### Setting Headers

```go
r.GET("/custom-headers", func(c *router.Context) {
    c.Header("X-Custom-Header", "CustomValue")
    c.Header("Cache-Control", "no-cache")
    c.JSON(200, map[string]string{"message": "Headers set"})
})
```

## Redirects

Redirect to another URL:

```go
r.GET("/old-url", func(c *router.Context) {
    c.Redirect(301, "/new-url") // 301 Permanent Redirect
})

r.GET("/temporary", func(c *router.Context) {
    c.Redirect(302, "/elsewhere") // 302 Temporary Redirect
})
```

## Complete Example

Here's a complete example combining all the concepts:

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
    
    // List all users
    r.GET("/users", func(c *router.Context) {
        userList := make([]User, 0, len(users))
        for _, user := range users {
            userList = append(userList, user)
        }
        c.JSON(200, userList)
    })
    
    // Get a specific user
    r.GET("/users/:id", func(c *router.Context) {
        id := c.Param("id")
        user, exists := users[id]
        if !exists {
            c.JSON(404, map[string]string{
                "error": "User not found",
            })
            return
        }
        c.JSON(200, user)
    })
    
    // Create a new user
    r.POST("/users", func(c *router.Context) {
        var req User
        if err := json.NewDecoder(c.Request.Body).Decode(&req); err != nil {
            c.JSON(400, map[string]string{
                "error": "Invalid JSON",
            })
            return
        }
        
        // Generate ID (simplified)
        req.ID = "3"
        users[req.ID] = req
        
        c.JSON(201, req)
    })
    
    // Update a user
    r.PUT("/users/:id", func(c *router.Context) {
        id := c.Param("id")
        if _, exists := users[id]; !exists {
            c.JSON(404, map[string]string{
                "error": "User not found",
            })
            return
        }
        
        var req User
        if err := json.NewDecoder(c.Request.Body).Decode(&req); err != nil {
            c.JSON(400, map[string]string{
                "error": "Invalid JSON",
            })
            return
        }
        
        req.ID = id
        users[id] = req
        c.JSON(200, req)
    })
    
    // Delete a user
    r.DELETE("/users/:id", func(c *router.Context) {
        id := c.Param("id")
        if _, exists := users[id]; !exists {
            c.JSON(404, map[string]string{
                "error": "User not found",
            })
            return
        }
        
        delete(users, id)
        c.Status(204)
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Next Steps

Now that you understand the basics:

- **Route Patterns**: Learn about [route patterns](../route-patterns/) including wildcards and constraints
- **Route Groups**: Organize routes with [route groups](../route-groups/)
- **Middleware**: Add cross-cutting concerns with [middleware](../middleware/)
- **Request Binding**: Automatically parse requests with [request binding](../request-binding/)
