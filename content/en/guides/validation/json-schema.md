---
title: "JSON Schema Validation"
description: "Validate structs using JSON Schema"
weight: 4
keywords:
  - json schema validation
  - schema validation
  - jsonschema
  - json schema
---

Validate structs using JSON Schema. Implement the `JSONSchemaProvider` interface to use this feature. This provides RFC-compliant JSON Schema validation as an alternative to struct tags.

## JSONSchemaProvider Interface

Implement the `JSONSchemaProvider` interface on your struct:

```go
type JSONSchemaProvider interface {
    JSONSchema() (id, schema string)
}
```

The method returns:
- **id**: Unique schema identifier for caching.
- **schema**: JSON Schema as a string in JSON format.

## Basic Example

```go
type User struct {
    Email string `json:"email"`
    Age   int    `json:"age"`
}

func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{
        "type": "object",
        "properties": {
            "email": {"type": "string", "format": "email"},
            "age": {"type": "integer", "minimum": 18}
        },
        "required": ["email"]
    }`
}

// Validation automatically uses the schema
err := validation.Validate(ctx, &user)
```

## JSON Schema Syntax

### Basic Types

```go
func (p Product) JSONSchema() (id, schema string) {
    return "product-v1", `{
        "type": "object",
        "properties": {
            "name": {"type": "string"},
            "price": {"type": "number"},
            "inStock": {"type": "boolean"},
            "tags": {"type": "array", "items": {"type": "string"}},
            "metadata": {"type": "object"}
        }
    }`
}
```

### String Constraints

```go
func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{
        "type": "object",
        "properties": {
            "username": {
                "type": "string",
                "minLength": 3,
                "maxLength": 20,
                "pattern": "^[a-zA-Z0-9_]+$"
            },
            "email": {
                "type": "string",
                "format": "email"
            },
            "website": {
                "type": "string",
                "format": "uri"
            }
        }
    }`
}
```

### Number Constraints

```go
func (p Product) JSONSchema() (id, schema string) {
    return "product-v1", `{
        "type": "object",
        "properties": {
            "price": {
                "type": "number",
                "minimum": 0,
                "exclusiveMinimum": true
            },
            "quantity": {
                "type": "integer",
                "minimum": 0,
                "maximum": 1000
            },
            "rating": {
                "type": "number",
                "minimum": 0,
                "maximum": 5,
                "multipleOf": 0.5
            }
        }
    }`
}
```

### Array Constraints

```go
func (r Request) JSONSchema() (id, schema string) {
    return "request-v1", `{
        "type": "object",
        "properties": {
            "tags": {
                "type": "array",
                "items": {"type": "string"},
                "minItems": 1,
                "maxItems": 10,
                "uniqueItems": true
            }
        }
    }`
}
```

### Enum Values

```go
func (o Order) JSONSchema() (id, schema string) {
    return "order-v1", `{
        "type": "object",
        "properties": {
            "status": {
                "type": "string",
                "enum": ["pending", "confirmed", "shipped", "delivered"]
            }
        }
    }`
}
```

### Nested Objects

```go
type User struct {
    Name    string  `json:"name"`
    Address Address `json:"address"`
}

type Address struct {
    Street string `json:"street"`
    City   string `json:"city"`
    Zip    string `json:"zip"`
}

func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{
        "type": "object",
        "properties": {
            "name": {"type": "string"},
            "address": {
                "type": "object",
                "properties": {
                    "street": {"type": "string"},
                    "city": {"type": "string"},
                    "zip": {"type": "string", "pattern": "^[0-9]{5}$"}
                },
                "required": ["street", "city", "zip"]
            }
        },
        "required": ["name", "address"]
    }`
}
```

## Format Validation

JSON Schema supports various format validators:

```go
func (c Contact) JSONSchema() (id, schema string) {
    return "contact-v1", `{
        "type": "object",
        "properties": {
            "email": {"type": "string", "format": "email"},
            "website": {"type": "string", "format": "uri"},
            "ipAddress": {"type": "string", "format": "ipv4"},
            "createdAt": {"type": "string", "format": "date-time"},
            "birthDate": {"type": "string", "format": "date"}
        }
    }`
}
```

Supported formats:
- `email` - Email address
- `uri` / `url` - URL
- `hostname` - DNS hostname
- `ipv4` / `ipv6` - IP addresses
- `date` - Date (YYYY-MM-DD)
- `date-time` - RFC3339 date-time
- `uuid` - UUID

## Schema Caching

Schemas are cached by ID for performance:

```go
func (u User) JSONSchema() (id, schema string) {
    // ID is used as cache key
    return "user-v1", `{...}`
    //     ^^^^^^^^ Cached after first validation
}
```

Cache is LRU with configurable size:

```go
validator := validation.MustNew(
    validation.WithMaxCachedSchemas(2048), // Default: 1024
)
```

## Override Schema Per-Call

Provide a custom schema for a specific validation:

```go
customSchema := `{
    "type": "object",
    "properties": {
        "email": {"type": "string", "format": "email"}
    },
    "required": ["email"]
}`

err := validator.Validate(ctx, &user,
    validation.WithCustomSchema("custom-user", customSchema),
)
```

This overrides the `JSONSchemaProvider` for this call only.

## Strategy Selection

By default, JSON Schema has lower priority than struct tags and interface methods. Explicitly select it:

```go
err := validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyJSONSchema),
)
```

Or use automatic strategy selection (default behavior):

```go
// Automatically uses JSON Schema if:
// 1. Type implements JSONSchemaProvider
// 2. No Validate() or ValidateContext() method
// 3. No struct tags present
err := validation.Validate(ctx, &user)
```

## Combining with Other Strategies

Run all strategies and aggregate errors:

```go
type User struct {
    Email string `json:"email" validate:"required,email"` // Struct tag
}

func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{
        "type": "object",
        "properties": {
            "email": {"type": "string", "format": "email"}
        }
    }`
}

// Run both struct tag and JSON Schema validation
err := validation.Validate(ctx, &user,
    validation.WithRunAll(true),
)
```

## Schema Validation Errors

JSON Schema errors are returned as `FieldError` values:

```go
err := validation.Validate(ctx, &user)
if err != nil {
    var verr *validation.Error
    if errors.As(err, &verr) {
        for _, fieldErr := range verr.Fields {
            fmt.Printf("Path: %s\n", fieldErr.Path)
            fmt.Printf("Code: %s\n", fieldErr.Code)       // e.g., "schema.type"
            fmt.Printf("Message: %s\n", fieldErr.Message)
        }
    }
}
```

Error codes follow the pattern `schema.<constraint>`:
- `schema.type` - Type mismatch
- `schema.required` - Missing required field
- `schema.minimum` - Below minimum value
- `schema.pattern` - Pattern mismatch
- `schema.format` - Format validation failed

## Complete Example

```go
package main

import (
    "context"
    "fmt"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Username string `json:"username"`
    Email    string `json:"email"`
    Age      int    `json:"age"`
}

func (r CreateUserRequest) JSONSchema() (id, schema string) {
    return "create-user-v1", `{
        "$schema": "http://json-schema.org/draft-07/schema#",
        "type": "object",
        "properties": {
            "username": {
                "type": "string",
                "minLength": 3,
                "maxLength": 20,
                "pattern": "^[a-zA-Z0-9_]+$"
            },
            "email": {
                "type": "string",
                "format": "email"
            },
            "age": {
                "type": "integer",
                "minimum": 18,
                "maximum": 120
            }
        },
        "required": ["username", "email", "age"],
        "additionalProperties": false
    }`
}

func main() {
    ctx := context.Background()
    
    req := CreateUserRequest{
        Username: "ab",           // Too short
        Email:    "not-an-email", // Invalid format
        Age:      15,             // Below minimum
    }
    
    // Explicitly use JSON Schema strategy
    err := validation.Validate(ctx, &req,
        validation.WithStrategy(validation.StrategyJSONSchema),
    )
    
    if err != nil {
        var verr *validation.Error
        if errors.As(err, &verr) {
            for _, fieldErr := range verr.Fields {
                fmt.Printf("%s: %s\n", fieldErr.Path, fieldErr.Message)
            }
        }
    }
}
```

## Advantages of JSON Schema

- **Standard**: RFC-compliant, widely supported format
- **Portable**: Schema can be shared with frontend/documentation
- **Flexible**: Complex validation logic without code
- **Versioned**: Easy to version schemas with ID

## Disadvantages

- **Verbose**: More code than struct tags
- **Runtime**: Schema parsing has overhead (mitigated by caching)
- **Complexity**: Learning curve for JSON Schema syntax

## When to Use JSON Schema

Use JSON Schema when:
- You need to share validation rules with frontend
- You have complex validation logic
- You want portable, language-independent validation
- You need to version validation rules

Use struct tags when:
- You prefer concise, declarative validation
- You only validate server-side
- You want minimal overhead

## JSON Schema Resources

- [JSON Schema Official Site](https://json-schema.org/)
- [JSON Schema Validator](https://www.jsonschemavalidator.net/)
- [Understanding JSON Schema](https://json-schema.org/understanding-json-schema/)

## Next Steps

- [**Custom Interfaces**](../custom-interfaces/) - Implement custom validation methods
- [**Struct Tags**](../struct-tags/) - Alternative validation with struct tags
- [**Strategies Reference**](/reference/packages/validation/strategies/) - Strategy selection details
