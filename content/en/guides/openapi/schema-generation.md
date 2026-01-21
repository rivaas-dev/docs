---
title: "Schema Generation"
description: "Understand how Go types are converted to OpenAPI schemas"
weight: 7
keywords:
  - openapi schema
  - type generation
  - models
  - schema generation
---

Learn how the package automatically converts Go types to OpenAPI schemas.

## Overview

The package uses reflection to convert Go types into OpenAPI schemas. This eliminates the need to manually define schemas in the specification.

## Supported Go Types

### Primitive Types

| Go Type | OpenAPI Type | OpenAPI Format |
|---------|--------------|----------------|
| `string` | `string` | - |
| `bool` | `boolean` | - |
| `int`, `int32` | `integer` | `int32` |
| `int64` | `integer` | `int64` |
| `uint`, `uint32` | `integer` | `int32` |
| `uint64` | `integer` | `int64` |
| `float32` | `number` | `float` |
| `float64` | `number` | `double` |
| `byte` | `string` | `byte` |

### String Types

```go
type User struct {
    Name  string `json:"name"`
    Email string `json:"email"`
}
```

Generates:

```yaml
type: object
properties:
  name:
    type: string
  email:
    type: string
```

### Integer Types

```go
type Product struct {
    ID       int   `json:"id"`
    Quantity int32 `json:"quantity"`
    Stock    int64 `json:"stock"`
}
```

Generates:

```yaml
type: object
properties:
  id:
    type: integer
    format: int32
  quantity:
    type: integer
    format: int32
  stock:
    type: integer
    format: int64
```

### Floating-Point Types

```go
type Product struct {
    Price   float64 `json:"price"`
    Weight  float32 `json:"weight"`
}
```

Generates:

```yaml
type: object
properties:
  price:
    type: number
    format: double
  weight:
    type: number
    format: float
```

### Boolean Types

```go
type User struct {
    Active   bool `json:"active"`
    Verified bool `json:"verified"`
}
```

Generates:

```yaml
type: object
properties:
  active:
    type: boolean
  verified:
    type: boolean
```

## Pointer Types

Pointer types are nullable and optional:

```go
type User struct {
    Name  string `json:"name"`
    Age   *int   `json:"age,omitempty"`
    Email *string `json:"email,omitempty"`
}
```

In OpenAPI 3.1.x, pointers generate `nullable: true`. In OpenAPI 3.0.x, they're optional fields.

## Slices and Arrays

Slices become OpenAPI arrays:

```go
type User struct {
    Tags   []string `json:"tags"`
    Scores []int    `json:"scores"`
    Posts  []Post   `json:"posts"`
}
```

Generates:

```yaml
type: object
properties:
  tags:
    type: array
    items:
      type: string
  scores:
    type: array
    items:
      type: integer
  posts:
    type: array
    items:
      $ref: '#/components/schemas/Post'
```

## Maps

Maps become OpenAPI objects with `additionalProperties`:

```go
type User struct {
    Metadata map[string]string `json:"metadata"`
    Scores   map[string]int    `json:"scores"`
}
```

Generates:

```yaml
type: object
properties:
  metadata:
    type: object
    additionalProperties:
      type: string
  scores:
    type: object
    additionalProperties:
      type: integer
```

## Nested Structs

Nested structs are converted to nested schemas or references:

```go
type User struct {
    ID      int     `json:"id"`
    Name    string  `json:"name"`
    Address Address `json:"address"`
}

type Address struct {
    Street  string `json:"street"`
    City    string `json:"city"`
    ZipCode string `json:"zip_code"`
}
```

Generates component schemas with references:

```yaml
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        address:
          $ref: '#/components/schemas/Address'
    Address:
      type: object
      properties:
        street:
          type: string
        city:
          type: string
        zip_code:
          type: string
```

## Embedded Structs

Embedded struct fields are flattened into the parent:

```go
type Timestamps struct {
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
    Timestamps
}
```

Generates:

```yaml
type: object
properties:
  id:
    type: integer
  name:
    type: string
  created_at:
    type: string
    format: date-time
  updated_at:
    type: string
    format: date-time
```

## Time Types

`time.Time` becomes a string with `date-time` format:

```go
type User struct {
    CreatedAt time.Time  `json:"created_at"`
    UpdatedAt *time.Time `json:"updated_at,omitempty"`
}
```

Generates:

```yaml
type: object
properties:
  created_at:
    type: string
    format: date-time
  updated_at:
    type: string
    format: date-time
```

## JSON Tags

The package respects `json` struct tags:

```go
type User struct {
    ID        int    `json:"id"`
    FirstName string `json:"first_name"`
    LastName  string `json:"last_name"`
    Internal  string `json:"-"`           // Ignored
    Optional  string `json:"opt,omitempty"` // Optional
}
```

- **`json:"name"`** - Sets the property name
- **`json:"-"`** - Field is ignored
- **`json:",omitempty"`** - Field is optional (not required)

## Schema Naming

Component schema names use the format `pkgname.TypeName` to prevent collisions:

```go
// In package "api"
type User struct { ... }  // Becomes "api.User"

// In package "models"
type User struct { ... }  // Becomes "models.User"
```

This prevents naming collisions when the same type name exists in different packages.

### Custom Schema Names

If you need custom schema names, use the `openapi` struct tag:

```go
type User struct {
    ID   int    `json:"id" openapi:"name=CustomUser"`
    Name string `json:"name"`
}
```

## Validation Tags

Validation tags affect the OpenAPI schema:

```go
type CreateUserRequest struct {
    Name  string `json:"name" validate:"required"`
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"min=0,max=150"`
}
```

- **`required`** - Adds field to `required` array
- **`min/max`** - Sets `minimum/maximum` for numbers
- **`email`** - Sets `format: email` for strings

## Documentation Tags

Use `doc` and `example` tags to enhance schemas:

```go
type User struct {
    ID    int    `json:"id" doc:"Unique user identifier" example:"123"`
    Name  string `json:"name" doc:"User's full name" example:"John Doe"`
    Email string `json:"email" doc:"User's email address" example:"john@example.com"`
}
```

Generates:

```yaml
type: object
properties:
  id:
    type: integer
    description: Unique user identifier
    example: 123
  name:
    type: string
    description: User's full name
    example: John Doe
  email:
    type: string
    description: User's email address
    example: john@example.com
```

## Enum Types

Use `enum` tag to specify allowed values:

```go
type User struct {
    Role   string `json:"role" enum:"admin,user,guest"`
    Status string `json:"status" enum:"active,inactive,pending"`
}
```

Generates:

```yaml
type: object
properties:
  role:
    type: string
    enum: [admin, user, guest]
  status:
    type: string
    enum: [active, inactive, pending]
```

## Complete Schema Example

Here's a comprehensive example using all features:

```go
package main

import (
    "time"
)

type User struct {
    // Basic types
    ID       int    `json:"id" doc:"Unique user identifier" example:"123"`
    Name     string `json:"name" doc:"User's full name" example:"John Doe" validate:"required"`
    Email    string `json:"email" doc:"Email address" example:"john@example.com" validate:"required,email"`
    
    // Optional field
    Bio *string `json:"bio,omitempty" doc:"User biography"`
    
    // Numeric types
    Age    int     `json:"age" doc:"User's age" validate:"min=0,max=150"`
    Score  float64 `json:"score" doc:"User score" example:"95.5"`
    
    // Boolean
    Active bool `json:"active" doc:"Whether user is active" example:"true"`
    
    // Enum
    Role string `json:"role" doc:"User role" enum:"admin,user,guest"`
    
    // Arrays
    Tags   []string `json:"tags" doc:"User tags"`
    Scores []int    `json:"scores" doc:"Test scores"`
    
    // Map
    Metadata map[string]string `json:"metadata" doc:"Additional metadata"`
    
    // Nested struct
    Address Address `json:"address" doc:"User address"`
    
    // Time
    CreatedAt time.Time  `json:"created_at" doc:"Creation timestamp"`
    UpdatedAt *time.Time `json:"updated_at,omitempty" doc:"Last update timestamp"`
    
    // Ignored field
    Internal string `json:"-"`
}

type Address struct {
    Street  string `json:"street" validate:"required"`
    City    string `json:"city" validate:"required"`
    State   string `json:"state"`
    ZipCode string `json:"zip_code" validate:"required"`
    Country string `json:"country" validate:"required"`
}
```

## Next Steps

- Learn about [Operations](../operations/) to use your schemas in API endpoints
- Explore [Validation](../validation/) to validate generated specifications
- See [Examples](../examples/) for complete schema patterns
