---
title: "Testing"
linkTitle: "Testing"
weight: 13
description: >
  Test routes and handlers without starting a server.
---

## Overview

The app package provides built-in testing utilities for testing routes and handlers without starting an HTTP server.

## Test Method

### Basic Testing

Test routes using `app.Test()`:

```go
func TestHome(t *testing.T) {
    a := app.MustNew()
    a.GET("/", homeHandler)
    
    req := httptest.NewRequest("GET", "/", nil)
    resp, err := a.Test(req)
    if err != nil {
        t.Fatal(err)
    }
    
    if resp.StatusCode != 200 {
        t.Errorf("expected 200, got %d", resp.StatusCode)
    }
}
```

### With Timeout

Configure test timeout:

```go
req := httptest.NewRequest("GET", "/slow", nil)
resp, err := a.Test(req, app.WithTimeout(5*time.Second))
```

### With Context

Pass custom context:

```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()

req := httptest.NewRequest("GET", "/", nil)
resp, err := a.Test(req, app.WithContext(ctx))
```

## TestJSON Method

### Basic JSON Testing

Test JSON endpoints easily:

```go
func TestCreateUser(t *testing.T) {
    a := app.MustNew()
    a.POST("/users", createUserHandler)
    
    body := map[string]string{
        "name": "Alice",
        "email": "alice@example.com",
    }
    
    resp, err := a.TestJSON("POST", "/users", body)
    if err != nil {
        t.Fatal(err)
    }
    
    if resp.StatusCode != 201 {
        t.Errorf("expected 201, got %d", resp.StatusCode)
    }
}
```

## ExpectJSON Helper

### Assert JSON Responses

Use `ExpectJSON` for easy JSON assertions:

```go
func TestGetUser(t *testing.T) {
    a := app.MustNew()
    a.GET("/users/:id", getUserHandler)
    
    req := httptest.NewRequest("GET", "/users/123", nil)
    resp, err := a.Test(req)
    if err != nil {
        t.Fatal(err)
    }
    
    var user User
    app.ExpectJSON(t, resp, 200, &user)
    
    if user.ID != "123" {
        t.Errorf("expected ID 123, got %s", user.ID)
    }
}
```

## Complete Test Examples

### Testing Routes

```go
package main

import (
    "net/http"
    "net/http/httptest"
    "testing"
    
    "rivaas.dev/app"
)

func TestHomeRoute(t *testing.T) {
    a := app.MustNew()
    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello, World!",
        })
    })
    
    req := httptest.NewRequest("GET", "/", nil)
    resp, err := a.Test(req)
    if err != nil {
        t.Fatal(err)
    }
    
    if resp.StatusCode != 200 {
        t.Errorf("expected 200, got %d", resp.StatusCode)
    }
    
    var result map[string]string
    app.ExpectJSON(t, resp, 200, &result)
    
    if result["message"] != "Hello, World!" {
        t.Errorf("unexpected message: %s", result["message"])
    }
}
```

### Testing with Dependencies

```go
func TestWithDatabase(t *testing.T) {
    // Setup test database
    db := setupTestDB(t)
    defer db.Close()
    
    a := app.MustNew()
    
    a.GET("/users/:id", func(c *app.Context) {
        id := c.Param("id")
        user, err := db.GetUser(id)
        if err != nil {
            c.NotFound("user not found")
            return
        }
        c.JSON(http.StatusOK, user)
    })
    
    req := httptest.NewRequest("GET", "/users/123", nil)
    resp, err := a.Test(req)
    if err != nil {
        t.Fatal(err)
    }
    
    var user User
    app.ExpectJSON(t, resp, 200, &user)
}
```

### Table-Driven Tests

```go
func TestUserRoutes(t *testing.T) {
    a := app.MustNew()
    a.GET("/users/:id", getUserHandler)
    
    tests := []struct {
        name       string
        id         string
        wantStatus int
    }{
        {"valid ID", "123", 200},
        {"invalid ID", "abc", 400},
        {"not found", "999", 404},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest("GET", "/users/"+tt.id, nil)
            resp, err := a.Test(req)
            if err != nil {
                t.Fatal(err)
            }
            
            if resp.StatusCode != tt.wantStatus {
                t.Errorf("expected %d, got %d", tt.wantStatus, resp.StatusCode)
            }
        })
    }
}
```

## Testing Middleware

```go
func TestAuthMiddleware(t *testing.T) {
    a := app.MustNew()
    
    a.Use(AuthMiddleware())
    a.GET("/protected", protectedHandler)
    
    // Test without token
    req := httptest.NewRequest("GET", "/protected", nil)
    resp, _ := a.Test(req)
    if resp.StatusCode != 401 {
        t.Errorf("expected 401, got %d", resp.StatusCode)
    }
    
    // Test with token
    req = httptest.NewRequest("GET", "/protected", nil)
    req.Header.Set("Authorization", "Bearer valid-token")
    resp, _ = a.Test(req)
    if resp.StatusCode != 200 {
        t.Errorf("expected 200, got %d", resp.StatusCode)
    }
}
```

## Next Steps

- [Basic Usage](../basic-usage/) - Learn about route registration
- [Examples](../examples/) - See complete working examples
- See [Router Testing Guide](/guides/router/testing/) for advanced testing patterns
