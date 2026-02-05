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

### Binding and Validation

`Bind()` reads your request data and checks if it's valid. It handles JSON, forms, query parameters, and more.

Use `Bind()` for most cases. It automatically validates your data:

```go
type CreateUserRequest struct {
    Name  string `json:"name" validate:"required,min=3"`
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"gte=18"`
}

a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if err := c.Bind(&req); err != nil {
        c.Fail(err) // Handles binding and validation errors
        return
    }
    
    // req is valid and ready to use
})
```

The `Bind()` method does two things: it reads the request data and validates it. If either step fails, you get an error.

### Binding from Multiple Sources

You can bind data from different places at once. Use struct tags to tell Rivaas where to look:

```go
type GetUserRequest struct {
    ID      int    `path:"id"`           // From URL path
    Expand  string `query:"expand"`      // From query string
    APIKey  string `header:"X-API-Key"`  // From HTTP header
    Session string `cookie:"session"`    // From cookie
}

a.GET("/users/:id", func(c *app.Context) {
    var req GetUserRequest
    if err := c.Bind(&req); err != nil {
        c.Fail(err)
        return
    }
    
    // All fields are populated from their sources
})
```

### Binding Without Validation

Sometimes you need to process data before validating it. Use `BindOnly()` for this:

```go
a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if err := c.BindOnly(&req); err != nil {
        c.Fail(err)
        return
    }
    
    // Clean up the data
    req.Email = strings.ToLower(req.Email)
    
    // Now validate
    if err := c.Validate(&req); err != nil {
        c.Fail(err)
        return
    }
})
```

### Multi-Source Binding

Bind from multiple sources in one call. This is useful when your request needs data from different places:

```go
type UpdateUserRequest struct {
    ID    int    `path:"id"`          // From URL path
    Name  string `json:"name"`        // From JSON body
    Token string `header:"X-Token"`   // From header
}

a.PUT("/users/:id", func(c *app.Context) {
    var req UpdateUserRequest
    if err := c.Bind(&req); err != nil {
        c.Fail(err)
        return
    }
    
    // All fields populated: ID from path, Name from JSON, Token from header
})
```

### Multipart Forms with Files

For file uploads, use the `*binding.File` type. The context automatically detects and handles multipart form data:

```go
type UploadRequest struct {
    File        *binding.File `form:"file"`
    Title       string        `form:"title"`
    Description string        `form:"description"`
    // JSON in form fields is automatically parsed
    Settings    struct {
        Quality int    `json:"quality"`
        Format  string `json:"format"`
    } `form:"settings"`
}

a.POST("/upload", func(c *app.Context) {
    var req UploadRequest
    if err := c.Bind(&req); err != nil {
        c.Fail(err)
        return
    }
    
    // Validate file type
    allowedTypes := []string{".jpg", ".png", ".gif"}
    if !slices.Contains(allowedTypes, req.File.Ext()) {
        c.BadRequest(fmt.Errorf("invalid file type"))
        return
    }
    
    // Save the file
    filename := fmt.Sprintf("/uploads/%d_%s", time.Now().Unix(), req.File.Name)
    if err := req.File.Save(filename); err != nil {
        c.InternalError(err)
        return
    }
    
    c.JSON(http.StatusCreated, map[string]interface{}{
        "filename": filepath.Base(filename),
        "size":     req.File.Size,
        "url":      "/uploads/" + filepath.Base(filename),
    })
})
```

**Multiple file uploads:**

```go
type GalleryUpload struct {
    Photos []*binding.File `form:"photos"`
    Title  string          `form:"title"`
}

a.POST("/gallery", func(c *app.Context) {
    var req GalleryUpload
    if err := c.Bind(&req); err != nil {
        c.Fail(err)
        return
    }
    
    // Process each photo
    for i, photo := range req.Photos {
        filename := fmt.Sprintf("/uploads/%s_%d%s", req.Title, i, photo.Ext())
        if err := photo.Save(filename); err != nil {
            c.InternalError(err)
            return
        }
    }
    
    c.JSON(http.StatusCreated, map[string]int{
        "uploaded": len(req.Photos),
    })
})
```

**File security best practices:**
- Always validate file types using `file.Ext()` or check magic bytes
- Limit file sizes (check `file.Size`)
- Generate safe filenames (don't use user-provided names directly)
- Store files outside your web root
- Scan for malware in production environments

See [Multipart Forms](/guides/binding/multipart-forms/) for detailed examples and security patterns.

## Validation

### The Must Pattern

The easiest way to handle requests is with `MustBind()`. It reads the data, validates it, and sends an error response if something is wrong:

```go
type CreateUserRequest struct {
    Name  string `json:"name" validate:"required,min=3,max=50"`
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"required,gte=18,lte=120"`
}

a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if !c.MustBind(&req) {
        return // Error already sent to client
    }
    
    // req is valid, continue with your logic
})
```

This is the recommended approach. It keeps your code clean and handles errors automatically.

### Type-Safe Binding with Generics

If you prefer working with return values instead of pointers, use the generic functions:

```go
a.POST("/users", func(c *app.Context) {
    req, ok := app.MustBind[CreateUserRequest](c)
    if !ok {
        return // Error already sent
    }
    
    // req is type CreateUserRequest, not a pointer
})
```

This approach is more concise. You don't need to declare the variable first.

### Manual Error Handling

When you need more control over error handling, use `Bind()` directly:

```go
a.POST("/users", func(c *app.Context) {
    var req CreateUserRequest
    if err := c.Bind(&req); err != nil {
        // Handle the error your way
        c.Logger().Error("binding failed", "error", err)
        c.Fail(err)
        return
    }
    
    // Continue processing
})
```

Or with generics:

```go
a.POST("/users", func(c *app.Context) {
    req, err := app.Bind[CreateUserRequest](c)
    if err != nil {
        c.Fail(err)
        return
    }
    
    // Continue processing
})
```

### Partial Validation for PATCH Requests

PATCH requests only update some fields. Use `WithPartial()` to validate only the fields that are present:

```go
type UpdateUserRequest struct {
    Name  *string `json:"name" validate:"omitempty,min=3,max=50"`
    Email *string `json:"email" validate:"omitempty,email"`
}

a.PATCH("/users/:id", func(c *app.Context) {
    req, ok := app.MustBind[UpdateUserRequest](c, app.WithPartial())
    if !ok {
        return
    }
    
    // Only fields in the request are validated
})
```

You can also use the shortcut function `BindPatch()`:

```go
a.PATCH("/users/:id", func(c *app.Context) {
    req, ok := app.MustBindPatch[UpdateUserRequest](c)
    if !ok {
        return
    }
    
    // Same as above, but shorter
})
```

### Strict Mode (Reject Unknown Fields)

Catch typos and API mismatches by rejecting unknown fields:

```go
a.POST("/users", func(c *app.Context) {
    req, ok := app.MustBind[CreateUserRequest](c, app.WithStrict())
    if !ok {
        return // Error sent if client sends unknown fields
    }
})
```

Or use the shortcut:

```go
a.POST("/users", func(c *app.Context) {
    req, ok := app.MustBindStrict[CreateUserRequest](c)
    if !ok {
        return
    }
})
```

This is helpful during development to catch mistakes early.

### Binding Options

You can customize how binding and validation work:

| Option | What it does |
|--------|-------------|
| `app.WithStrict()` | Reject unknown JSON fields |
| `app.WithPartial()` | Only validate fields that are present |
| `app.WithoutValidation()` | Skip validation (bind only) |
| `app.WithBindingOptions(...)` | Advanced binding settings |
| `app.WithValidationOptions(...)` | Advanced validation settings |

Example with multiple options:

```go
req, err := app.Bind[Request](c, 
    app.WithStrict(),
    app.WithValidationOptions(validation.WithMaxErrors(10)),
)
```

### Validation Strategies

Choose how validation works:

```go
// Tag validation (default, uses struct tags)
c.Bind(&req)

// Explicit strategy selection
c.Bind(&req, app.WithValidationOptions(
    validation.WithStrategy(validation.StrategyTags),
))

// JSON Schema validation
c.Bind(&req, app.WithValidationOptions(
    validation.WithStrategy(validation.StrategyJSONSchema),
))
```

Most apps use tag validation. It's simple and works well.

## Error Handling

### Basic Error Handling

When something goes wrong in your handler, use `Fail()` to send an error response. This method formats the error, writes the HTTP response, and automatically stops the handler chain so no other handlers run after it:

```go
a.GET("/users/:id", func(c *app.Context) {
    id := c.Param("id")
    
    user, err := db.GetUser(id)
    if err != nil {
        c.Fail(err)
        return
    }
    
    c.JSON(http.StatusOK, user)
})
```

### Explicit Status Codes

When you need a specific HTTP status code for an error, use `FailStatus()`:

```go
a.GET("/users/:id", func(c *app.Context) {
    user, err := db.GetUser(id)
    if err != nil {
        c.FailStatus(http.StatusNotFound, err)
        return
    }
    
    c.JSON(http.StatusOK, user)
})
```

### Convenience Error Methods

Use convenience methods for common HTTP error status codes. These methods automatically format and send the error response, then stop the handler chain:

```go
// 404 Not Found
if user == nil {
    c.NotFound(fmt.Errorf("user not found"))
    return
}

// 400 Bad Request
if err := validateInput(input); err != nil {
    c.BadRequest(fmt.Errorf("invalid input"))
    return
}

// 401 Unauthorized
if !isAuthenticated {
    c.Unauthorized(fmt.Errorf("authentication required"))
    return
}

// 403 Forbidden
if !hasPermission {
    c.Forbidden(fmt.Errorf("insufficient permissions"))
    return
}

// 409 Conflict
if userExists {
    c.Conflict(fmt.Errorf("user already exists"))
    return
}

// 422 Unprocessable Entity
if validationErr != nil {
    c.UnprocessableEntity(validationErr)
    return
}

// 429 Too Many Requests
if rateLimitExceeded {
    c.TooManyRequests(fmt.Errorf("rate limit exceeded"))
    return
}

// 500 Internal Server Error
if err := processRequest(); err != nil {
    c.InternalError(err)
    return
}

// 503 Service Unavailable
if maintenanceMode {
    c.ServiceUnavailable(fmt.Errorf("maintenance mode"))
    return
}
```

You can also pass `nil` to use a generic default message:

```go
c.NotFound(nil)  // Uses "Not Found" as the message
c.BadRequest(nil)  // Uses "Bad Request" as the message
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
    req, ok := app.MustBind[CreateOrderRequest](c)
    if !ok {
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

Here's a complete example showing binding, validation, and logging:

```go
package main

import (
    "log"
    "log/slog"
    "net/http"
    
    "rivaas.dev/app"
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
        // Bind and validate in one step
        req, ok := app.MustBind[CreateOrderRequest](c)
        if !ok {
            return // Error already sent
        }
        
        // Log what's happening
        c.Logger().Info("creating order",
            slog.String("customer.id", req.CustomerID),
            slog.Int("item.count", len(req.Items)),
            slog.Float64("order.total", req.Total),
        )
        
        // Your business logic here...
        orderID := "order-123"
        
        // Log success
        c.Logger().Info("order created",
            slog.String("order.id", orderID),
        )
        
        // Send response
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
