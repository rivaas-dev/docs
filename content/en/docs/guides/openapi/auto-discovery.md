---
title: "Auto-Discovery"
description: "Use struct tags for automatic parameter discovery"
weight: 6
keywords:
  - openapi auto discovery
  - route scanning
  - automatic
  - struct tags
---

Learn how the package automatically discovers API parameters from struct tags.

## Overview

The package automatically discovers parameters from struct tags. This eliminates the need to manually define parameters in the OpenAPI specification.

## Supported Parameter Types

The package supports four parameter locations:

- **`path`** - Path parameters. Always required.
- **`query`** - Query parameters.
- **`header`** - Header parameters.
- **`cookie`** - Cookie parameters.

## Basic Parameter Discovery

Define parameters using struct tags:

```go
type GetUserRequest struct {
    ID int `path:"id" doc:"User ID" example:"123"`
}

result, err := api.Generate(context.Background(),
    openapi.GET("/users/:id",
        openapi.WithSummary("Get user"),
        openapi.WithResponse(200, User{}),
    ),
)
```

The package automatically discovers the `id` path parameter from the struct tag.

## Path Parameters

Path parameters are always required and are extracted from the URL path:

```go
type GetUserPostRequest struct {
    UserID int `path:"user_id" doc:"User ID" example:"123"`
    PostID int `path:"post_id" doc:"Post ID" example:"456"`
}

openapi.GET("/users/:user_id/posts/:post_id",
    openapi.WithSummary("Get user's post"),
    openapi.WithResponse(200, Post{}),
)
```

## Query Parameters

Query parameters are extracted from the URL query string:

```go
type ListUsersRequest struct {
    Page     int      `query:"page" doc:"Page number" example:"1" validate:"min=1"`
    PerPage  int      `query:"per_page" doc:"Items per page" example:"20" validate:"min=1,max=100"`
    Sort     string   `query:"sort" doc:"Sort field" enum:"name,created_at"`
    Tags     []string `query:"tags" doc:"Filter by tags"`
    Verified *bool    `query:"verified" doc:"Filter by verification status"`
}

openapi.GET("/users",
    openapi.WithSummary("List users"),
    openapi.WithResponse(200, []User{}),
)
```

## Header Parameters

Header parameters are extracted from HTTP headers:

```go
type GetUserRequest struct {
    ID            int    `path:"id"`
    Accept        string `header:"Accept" doc:"Content type" enum:"application/json,application/xml"`
    IfNoneMatch   string `header:"If-None-Match" doc:"ETag for caching"`
    XRequestID    string `header:"X-Request-ID" doc:"Request correlation ID"`
}

openapi.GET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)
```

## Cookie Parameters

Cookie parameters are extracted from HTTP cookies:

```go
type GetUserRequest struct {
    ID        int    `path:"id"`
    SessionID string `cookie:"session_id" doc:"Session identifier"`
    Theme     string `cookie:"theme" doc:"UI theme preference" enum:"light,dark"`
}

openapi.GET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)
```

## Request Body Fields

Fields in the request body use the `json` tag:

```go
type CreateUserRequest struct {
    Name  string `json:"name" doc:"User's full name" example:"John Doe" validate:"required"`
    Email string `json:"email" doc:"User's email address" example:"john@example.com" validate:"required,email"`
    Age   *int   `json:"age,omitempty" doc:"User's age" example:"30" validate:"min=0,max=150"`
}

openapi.POST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)
```

## Additional Tags

Use these tags to enhance parameter documentation:

### `doc` Tag

Add descriptions to parameters:

```go
type ListUsersRequest struct {
    Page int `query:"page" doc:"Page number for pagination, starting at 1"`
}
```

### `example` Tag

Provide example values:

```go
type GetUserRequest struct {
    ID int `path:"id" doc:"User ID" example:"123"`
}
```

### `enum` Tag

Specify allowed values (comma-separated):

```go
type ListUsersRequest struct {
    Sort   string `query:"sort" doc:"Sort field" enum:"name,email,created_at"`
    Format string `query:"format" doc:"Response format" enum:"json,xml"`
}
```

### `validate` Tag

Mark parameters as required or add validation constraints:

```go
type CreateUserRequest struct {
    Name  string `json:"name" validate:"required"`
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"min=0,max=150"`
}
```

The `required` validation affects the `required` field in the OpenAPI spec.

## Complete Struct Tag Example

Here's a comprehensive example using all tag types:

```go
type CreateOrderRequest struct {
    // Path parameter (always required)
    UserID int `path:"user_id" doc:"User ID" example:"123"`
    
    // Query parameters
    Coupon    string `query:"coupon" doc:"Coupon code for discount" example:"SAVE20"`
    SendEmail *bool  `query:"send_email" doc:"Send confirmation email" example:"true"`
    
    // Header parameters
    IdempotencyKey string `header:"Idempotency-Key" doc:"Idempotency key for request" example:"550e8400-e29b-41d4-a716-446655440000"`
    
    // Cookie parameters
    SessionID string `cookie:"session_id" doc:"Session identifier"`
    
    // Request body fields
    Items []OrderItem `json:"items" doc:"Order items" validate:"required,min=1"`
    Total float64     `json:"total" doc:"Order total" example:"99.99" validate:"required,min=0"`
    Notes string      `json:"notes,omitempty" doc:"Additional notes" example:"Please gift wrap"`
}

type OrderItem struct {
    ProductID int     `json:"product_id" validate:"required"`
    Quantity  int     `json:"quantity" validate:"required,min=1"`
    Price     float64 `json:"price" validate:"required,min=0"`
}
```

## Parameter Discovery Rules

### Required vs Optional

- **Path parameters**: Always required
- **Query/Header/Cookie parameters**: 
  - Required if `validate:"required"` tag is present
  - Optional otherwise
- **Request body fields**: 
  - Required if `validate:"required"` tag is present
  - Optional if pointer type or `omitempty` JSON tag

### Type Conversion

The package automatically converts Go types to OpenAPI types:

```go
type Parameters struct {
    // String types
    Name   string `query:"name"`    // type: string
    
    // Integer types
    Count  int    `query:"count"`   // type: integer, format: int32
    BigNum int64  `query:"big"`     // type: integer, format: int64
    
    // Floating-point types
    Price  float64 `query:"price"`  // type: number, format: double
    Rate   float32 `query:"rate"`   // type: number, format: float
    
    // Boolean types
    Active bool `query:"active"`    // type: boolean
    
    // Array types
    Tags []string `query:"tags"`    // type: array, items: string
    IDs  []int    `query:"ids"`     // type: array, items: integer
    
    // Pointer types (optional)
    Size *int `query:"size"`        // type: integer, optional
}
```

## Combining Parameters with Request Bodies

A single struct can contain both parameters and request body fields:

```go
type UpdateUserRequest struct {
    // Path parameter
    ID int `path:"id" doc:"User ID"`
    
    // Query parameter
    Notify bool `query:"notify" doc:"Send notification"`
    
    // Request body fields
    Name  string `json:"name" validate:"required"`
    Email string `json:"email" validate:"required,email"`
}

openapi.PUT("/users/:id",
    openapi.WithSummary("Update user"),
    openapi.WithRequest(UpdateUserRequest{}),
    openapi.WithResponse(200, User{}),
)
```

## Nested Structures

Parameters can be in nested structures:

```go
type GetUserRequest struct {
    ID     int             `path:"id"`
    Filter UserListFilter  `query:",inline"`
}

type UserListFilter struct {
    Active   *bool  `query:"active" doc:"Filter by active status"`
    Role     string `query:"role" doc:"Filter by role" enum:"admin,user,guest"`
    Since    string `query:"since" doc:"Filter by creation date"`
}
```

## Next Steps

- Learn about [Schema Generation](../schema-generation/) for type conversion
- Explore [Operations](../operations/) for complete operation definitions
- See [Examples](../examples/) for real-world usage patterns
