---
title: "Testing"
linkTitle: "Testing"
weight: 140
keywords:
  - router testing
  - test helpers
  - mock requests
  - httptest
description: >
  Test your routes and middleware with httptest.
---

Testing router-based applications is straightforward using Go's `httptest` package.

## Testing Routes

### Basic Route Test

```go
package main

import (
    "net/http"
    "net/http/httptest"
    "testing"
    
    "rivaas.dev/router"
)

func TestGetUser(t *testing.T) {
    r := router.MustNew()
    r.GET("/users/:id", func(c *router.Context) {
        c.JSON(200, map[string]string{
            "user_id": c.Param("id"),
        })
    })
    
    req := httptest.NewRequest("GET", "/users/123", nil)
    w := httptest.NewRecorder()
    
    r.ServeHTTP(w, req)
    
    if w.Code != http.StatusOK {
        t.Errorf("Expected status 200, got %d", w.Code)
    }
}
```

### Testing JSON Responses

```go
func TestCreateUser(t *testing.T) {
    r := router.MustNew()
    r.POST("/users", func(c *router.Context) {
        c.JSON(201, map[string]string{"id": "123"})
    })
    
    body := strings.NewReader(`{"name":"John"}`)
    req := httptest.NewRequest("POST", "/users", body)
    req.Header.Set("Content-Type", "application/json")
    
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)
    
    if w.Code != 201 {
        t.Errorf("Expected status 201, got %d", w.Code)
    }
    
    var response map[string]string
    if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
        t.Fatal(err)
    }
    
    if response["id"] != "123" {
        t.Errorf("Expected id '123', got %v", response["id"])
    }
}
```

## Testing Middleware

```go
func TestAuthMiddleware(t *testing.T) {
    r := router.MustNew()
    r.Use(AuthRequired())
    r.GET("/protected", func(c *router.Context) {
        c.JSON(200, map[string]string{"message": "success"})
    })
    
    // Test without auth header
    req := httptest.NewRequest("GET", "/protected", nil)
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)
    
    if w.Code != 401 {
        t.Errorf("Expected status 401, got %d", w.Code)
    }
    
    // Test with auth header
    req = httptest.NewRequest("GET", "/protected", nil)
    req.Header.Set("Authorization", "Bearer valid-token")
    w = httptest.NewRecorder()
    r.ServeHTTP(w, req)
    
    if w.Code != 200 {
        t.Errorf("Expected status 200, got %d", w.Code)
    }
}
```

## Table-Driven Tests

```go
func TestRoutes(t *testing.T) {
    r := setupRouter()
    
    tests := []struct {
        name           string
        method         string
        path           string
        expectedStatus int
    }{
        {"Home", "GET", "/", 200},
        {"Users", "GET", "/users", 200},
        {"Not Found", "GET", "/invalid", 404},
        {"Method Not Allowed", "POST", "/", 405},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest(tt.method, tt.path, nil)
            w := httptest.NewRecorder()
            
            r.ServeHTTP(w, req)
            
            if w.Code != tt.expectedStatus {
                t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
            }
        })
    }
}
```

## Helper Functions

```go
func setupRouter() *router.Router {
    r := router.MustNew()
    r.GET("/users", listUsers)
    r.POST("/users", createUser)
    r.GET("/users/:id", getUser)
    return r
}

func makeRequest(r *router.Router, method, path string, body io.Reader) *httptest.ResponseRecorder {
    req := httptest.NewRequest(method, path, body)
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)
    return w
}
```

## Complete Test Example

```go
package main

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    
    "rivaas.dev/router"
)

func setupRouter() *router.Router {
    r := router.MustNew()
    r.GET("/users", listUsers)
    r.POST("/users", createUser)
    r.GET("/users/:id", getUser)
    return r
}

func TestListUsers(t *testing.T) {
    r := setupRouter()
    
    req := httptest.NewRequest("GET", "/users", nil)
    w := httptest.NewRecorder()
    
    r.ServeHTTP(w, req)
    
    if w.Code != 200 {
        t.Errorf("Expected 200, got %d", w.Code)
    }
}

func TestCreateUser(t *testing.T) {
    r := setupRouter()
    
    userData := map[string]string{
        "name":  "John Doe",
        "email": "john@example.com",
    }
    
    body, _ := json.Marshal(userData)
    req := httptest.NewRequest("POST", "/users", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)
    
    if w.Code != 201 {
        t.Errorf("Expected 201, got %d", w.Code)
    }
}

func TestGetUser(t *testing.T) {
    r := setupRouter()
    
    req := httptest.NewRequest("GET", "/users/123", nil)
    w := httptest.NewRecorder()
    
    r.ServeHTTP(w, req)
    
    if w.Code != 200 {
        t.Errorf("Expected 200, got %d", w.Code)
    }
}

// Handlers (simplified for testing)
func listUsers(c *router.Context) {
    c.JSON(200, []string{"user1", "user2"})
}

func createUser(c *router.Context) {
    c.JSON(201, map[string]string{"id": "123"})
}

func getUser(c *router.Context) {
    c.JSON(200, map[string]string{"id": c.Param("id")})
}
```

## Best Practices

1. **Use table-driven tests** for multiple scenarios
2. **Test error cases** not just success paths
3. **Mock dependencies** for unit tests
4. **Use test helpers** to reduce boilerplate
5. **Test middleware** independently from routes

## Next Steps

- **Migration**: See [migration guides](../migration/) from other frameworks
- **Examples**: Browse [complete examples](../examples/)
