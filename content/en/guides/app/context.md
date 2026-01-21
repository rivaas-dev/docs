---
title: "Context"
linkTitle: "Context"
weight: 5
keywords:
  - app context
  - request context
  - context api
  - request handling
  - response
description: >
  Use the app context for request binding, validation, error handling, and logging.
---

## Overview

The `app.Context` wraps `router.Context` and provides app-level features:

- **Request Binding** - Parse JSON, form, query, path, header, and cookie data automatically
- **Validation** - Comprehensive validation with multiple strategies
- **Error Handling** - Structured error responses with content negotiation
- **Logging** - Request-scoped logger with automatic context

## Request Binding

### Automatic Binding

`Bind()` automatically detects struct tags and binds from all relevant sources:

```go
type GetUserRequest struct {
    ID      int    `path:"id"`           // Path parameter
    Expand  string `query:"expand"`      // Query parameter
    APIKey  string `header:"X-API-Key"`  // HTTP header
    Session string `cookie:"session"`    // Cookie
}

a.GET("/users/:id", func(c *app.Context) {
    var req GetUserRequest
    if err := c.Bind(&req); err != nil {
        c.Error(err)
        return
    }
    
    // req is populated from path, query, headers, and cookies
})
```

### JSON Binding

For JSON request bodies:

```go
type CreateUserRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
    Age   int    `json:"age"`
}

a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if err := c.Bind(&req); err != nil {
        c.Error(err)
        return
    }
    
    // req is populated from JSON body
})
```

### Strict JSON Binding

Reject unknown fields to catch typos and API drift:

```go
a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if err := c.BindJSONStrict(&req); err != nil {
        c.Error(err) // Returns error if unknown fields present
        return
    }
})
```

### Multi-Source Binding

Bind from multiple sources simultaneously:

```go
type UpdateUserRequest struct {
    ID    int    `path:"id"`          // From path
    Name  string `json:"name"`        // From JSON body
    Token string `header:"X-Token"`   // From header
}

a.PUT("/users/:id", func(c *app.Context) {
    var req UpdateUserRequest
    if err := c.Bind(&req); err != nil {
        c.Error(err)
        return
    }
    
    // req.ID from path, req.Name from JSON, req.Token from header
})
```

## Validation

### Bind and Validate

Combine binding and validation in one call:

```go
type CreateUserRequest struct {
    Name  string `json:"name" validate:"required,min=3,max=50"`
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"required,gte=18,lte=120"`
}

a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if err := c.BindAndValidate(&req); err != nil {
        c.Error(err)
        return
    }
    
    // req is validated
})
```

### Strict Bind and Validate

Reject unknown fields AND validate:

```go
a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if err := c.BindAndValidateStrict(&req); err != nil {
        c.Error(err) // Returns error if unknown fields OR validation fails
        return
    }
})
```

### Must Bind and Validate

Automatically send error responses on binding/validation failure:

```go
a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if !c.MustBindAndValidate(&req) {
        return // Error response already sent
    }
    
    // Continue with validated request
})
```

### Generic Bind and Validate

Use generics for type-safe binding:

```go
a.POST("/users", func(c *app.Context) {
    req, err := app.BindAndValidateInto[CreateUserRequest](c)
    if err != nil {
        c.Error(err)
        return
    }
    
    // req is of type CreateUserRequest
})

// Or with automatic error handling
a.POST("/users", func(c *app.Context) {
    req, ok := app.MustBindAndValidateInto[CreateUserRequest](c)
    if !ok {
        return // Error response already sent
    }
    
    // Continue with req
})
```

### Partial Validation (PATCH)

Validate only fields present in the request:

```go
type PatchUserRequest struct {
    Name  *string `json:"name" validate:"omitempty,min=3,max=50"`
    Email *string `json:"email" validate:"omitempty,email"`
}

a.PATCH("/users/:id", func(c *app.Context) {
    var req PatchUserRequest
    if err := c.BindAndValidate(&req, validation.WithPartial(true)); err != nil {
        c.Error(err)
        return
    }
    
    // Only present fields are validated
})
```

### Validation Strategies

Choose different validation strategies:

```go
// Interface validation (default)
c.BindAndValidate(&req)

// Tag validation (go-playground/validator)
c.BindAndValidate(&req, validation.WithStrategy(validation.StrategyTags))

// JSON Schema validation
c.BindAndValidate(&req, validation.WithStrategy(validation.StrategyJSONSchema))
```

## Error Handling

### Basic Error Handling

Send error responses with automatic formatting:

```go
a.GET("/users/:id", func(c *app.Context) {
    id := c.Param("id")
    
    user, err := db.GetUser(id)
    if err != nil {
        c.Error(err)
        return
    }
    
    c.JSON(http.StatusOK, user)
})
```

### Explicit Status Codes

Override error status codes:

```go
a.GET("/users/:id", func(c *app.Context) {
    user, err := db.GetUser(id)
    if err != nil {
        c.ErrorStatus(err, http.StatusNotFound)
        return
    }
    
    c.JSON(http.StatusOK, user)
})
```

### Convenience Error Methods

Use convenience methods for common status codes:

```go
// 404 Not Found
if user == nil {
    c.NotFound("user not found")
    return
}

// 400 Bad Request
if err := validateInput(input); err != nil {
    c.BadRequest("invalid input")
    return
}

// 401 Unauthorized
if !isAuthenticated {
    c.Unauthorized("authentication required")
    return
}

// 403 Forbidden
if !hasPermission {
    c.Forbidden("insufficient permissions")
    return
}

// 500 Internal Server Error
if err := processRequest(); err != nil {
    c.InternalError(err)
    return
}
```

### Error Formatters

Configure error formatting at app level:

```go
// Single formatter
a, err := app.New(
    app.WithErrorFormatter(&errors.RFC9457{
        BaseURL: "https://api.example.com/problems",
    }),
)

// Multiple formatters with content negotiation
a, err := app.New(
    app.WithErrorFormatters(map[string]errors.Formatter{
        "application/problem+json": &errors.RFC9457{},
        "application/json": &errors.Simple{},
    }),
    app.WithDefaultErrorFormat("application/problem+json"),
)
```

## Request-Scoped Logging

### Accessing the Logger

Get the request-scoped logger with automatic context:

```go
a.GET("/orders/:id", func(c *app.Context) {
    orderID := c.Param("id")
    
    // Logger automatically includes:
    // - HTTP metadata (method, route, target, client IP)
    // - Request ID (if present)
    // - Trace/span IDs (if tracing enabled)
    c.Logger().Info("processing order",
        slog.String("order.id", orderID),
    )
    
    c.JSON(http.StatusOK, order)
})
```

### Structured Logging

Use structured logging with key-value pairs:

```go
a.POST("/orders", func(c *app.Context) {
    var req CreateOrderRequest
    if !c.MustBindAndValidate(&req) {
        return
    }
    
    c.Logger().Info("creating order",
        slog.String("customer.id", req.CustomerID),
        slog.Int("item.count", len(req.Items)),
        slog.Float64("order.total", req.Total),
    )
    
    // Process order...
    
    c.Logger().Info("order created successfully",
        slog.String("order.id", orderID),
    )
})
```

### Log Levels

Use different log levels:

```go
c.Logger().Debug("fetching from cache")
c.Logger().Info("request processed successfully")
c.Logger().Warn("cache miss, fetching from database")
c.Logger().Error("failed to save to database", "error", err)
```

### Automatic Context

The logger automatically includes request context:

```json
{
  "time": "2024-01-18T10:30:00Z",
  "level": "INFO",
  "msg": "processing order",
  "http.method": "GET",
  "http.route": "/orders/:id",
  "http.target": "/orders/123",
  "network.client.ip": "203.0.113.1",
  "trace_id": "abc...",
  "span_id": "def...",
  "order.id": "123"
}
```

## Router Context Features

The app context embeds `router.Context`, so all router features are available:

### HTTP Methods

```go
method := c.Request.Method
path := c.Request.URL.Path
headers := c.Request.Header
```

### Response Handling

```go
c.Status(http.StatusOK)
c.Header("Content-Type", "application/json")
c.JSON(http.StatusOK, data)
c.String(http.StatusOK, "text")
c.HTML(http.StatusOK, html)
```

### Content Negotiation

```go
accepts := c.Accepts("application/json", "text/html")
```

## Complete Example

```go
package main

import (
    "log"
    "log/slog"
    "net/http"
    
    "rivaas.dev/app"
    "rivaas.dev/validation"
)

type CreateOrderRequest struct {
    CustomerID string   `json:"customer_id" validate:"required,uuid"`
    Items      []string `json:"items" validate:"required,min=1,dive,required"`
    Total      float64  `json:"total" validate:"required,gt=0"`
}

func main() {
    a := app.MustNew(
        app.WithServiceName("orders-api"),
    )
    
    a.POST("/orders", func(c *app.Context) {
        // Bind and validate
        var req CreateOrderRequest
        if !c.MustBindAndValidate(&req) {
            return // Error response already sent
        }
        
        // Log with context
        c.Logger().Info("creating order",
            slog.String("customer.id", req.CustomerID),
            slog.Int("item.count", len(req.Items)),
            slog.Float64("order.total", req.Total),
        )
        
        // Business logic...
        orderID := "order-123"
        
        // Log success
        c.Logger().Info("order created",
            slog.String("order.id", orderID),
        )
        
        // Return response
        c.JSON(http.StatusCreated, map[string]string{
            "order_id": orderID,
        })
    })
    
    // Start server...
}
```

## Next Steps

- [Middleware](../middleware/) - Add cross-cutting concerns
- [Observability](../observability/) - Configure logging, metrics, and tracing
- [Examples](../examples/) - See complete working examples
