---
title: "Struct Tags"
description: "Master struct tag syntax for precise control over data binding"
weight: 7
---

Comprehensive guide to struct tag syntax, options, and conventions for the binding package.

## Overview

Struct tags control how fields are bound from different sources. The binding package supports multiple tag types:

```go
type Example struct {
    Field string `json:"field" query:"field" header:"X-Field" default:"value"`
}
```

## Tag Types

### Source Tags

| Tag | Source | Example |
|-----|--------|---------|
| `json` | JSON body | `json:"field_name"` |
| `query` | URL query params | `query:"field_name"` |
| `form` | Form data | `form:"field_name"` |
| `header` | HTTP headers | `header:"X-Field-Name"` |
| `path` | URL path params | `path:"param_name"` |
| `cookie` | HTTP cookies | `cookie:"cookie_name"` |

### Special Tags

| Tag | Purpose | Example |
|-----|---------|---------|
| `default` | Default value | `default:"value"` |
| `validate` | Validation rules | `validate:"required,email"` |
| `binding` | Control binding | `binding:"-"` or `binding:"required"` |

## Basic Syntax

### Simple Field

```go
type User struct {
    Name string `json:"name"`
}
```

### Multiple Sources

Same field can bind from multiple sources:

```go
type Request struct {
    UserID int `query:"user_id" json:"user_id" header:"X-User-ID"`
}
```

### Field Name Mapping

Map different source names to same field:

```go
type Request struct {
    UserID int `query:"uid" json:"user_id" header:"X-User-ID"`
}
```

## JSON Tags

Standard `encoding/json` tag syntax:

```go
type Product struct {
    // Basic field
    ID int `json:"id"`
    
    // Custom name
    Name string `json:"product_name"`
    
    // Omit if empty
    Description string `json:"description,omitempty"`
    
    // Ignore field
    Internal string `json:"-"`
    
    // Use field name as-is (case-sensitive)
    SKU string `json:"SKU"`
}
```

### JSON Tag Options

```go
type Example struct {
    // Omit if empty/zero value
    Optional string `json:"optional,omitempty"`
    
    // Omit if empty AND keep format
    Field string `json:"field,omitempty,string"`
    
    // Treat as string (for numbers)
    ID int64 `json:"id,string"`
}
```

## Query Tags

URL query parameter binding:

```go
type QueryParams struct {
    // Basic parameter
    Search string `query:"q"`
    
    // With default
    Page int `query:"page" default:"1"`
    
    // Array/slice
    Tags []string `query:"tags"`
    
    // Optional with pointer
    Filter *string `query:"filter"`
}
```

### Query Tag Aliases

Support multiple parameter names:

```go
type Request struct {
    // Accepts any of: user_id, id, uid
    UserID int `query:"user_id,id,uid"`
}
```

## Header Tags

HTTP header binding:

```go
type HeaderParams struct {
    // Standard header
    ContentType string `header:"Content-Type"`
    
    // Custom header
    APIKey string `header:"X-API-Key"`
    
    // Case-insensitive
    UserAgent string `header:"user-agent"`  // Matches User-Agent
    
    // Authorization
    AuthToken string `header:"Authorization"`
}
```

### Header Naming Conventions

Headers are case-insensitive:

```go
type Example struct {
    // All match "X-API-Key", "x-api-key", "X-Api-Key"
    APIKey string `header:"X-API-Key"`
}
```

## Path Tags

URL path parameter binding:

```go
// Route: /users/:id
type PathParams struct {
    UserID int `path:"id"`
}

// Route: /posts/:category/:slug
type PostParams struct {
    Category string `path:"category"`
    Slug     string `path:"slug"`
}
```

## Form Tags

Form data binding:

```go
type FormData struct {
    Username string `form:"username"`
    Email    string `form:"email"`
    Age      int    `form:"age"`
}
```

## Cookie Tags

HTTP cookie binding:

```go
type CookieParams struct {
    SessionID string `cookie:"session_id"`
    Theme     string `cookie:"theme" default:"light"`
}
```

## Default Tag

Specify default values for fields:

```go
type Config struct {
    // String default
    Host string `query:"host" default:"localhost"`
    
    // Integer default
    Port int `query:"port" default:"8080"`
    
    // Boolean default
    Debug bool `query:"debug" default:"false"`
    
    // Duration default
    Timeout time.Duration `query:"timeout" default:"30s"`
}
```

### Default Value Types

```go
type Defaults struct {
    String   string        `default:"text"`
    Int      int           `default:"42"`
    Float    float64       `default:"3.14"`
    Bool     bool          `default:"true"`
    Duration time.Duration `default:"1h30m"`
    Time     time.Time     `default:"2025-01-01T00:00:00Z"`
}
```

## Binding Tag

Control binding behavior:

```go
type Request struct {
    // Skip binding entirely
    Internal string `binding:"-"`
    
    // Required field
    UserID int `binding:"required"`
    
    // Optional field (explicit)
    Email string `binding:"optional"`
}
```

## Validation Tag

Integration with `rivaas.dev/validation`:

```go
type CreateUserRequest struct {
    Username string `json:"username" validate:"required,alphanum,min=3,max=32"`
    Email    string `json:"email" validate:"required,email"`
    Age      int    `json:"age" validate:"required,min=18,max=120"`
    Website  string `json:"website" validate:"omitempty,url"`
}
```

### Common Validation Rules

```go
type ValidationExamples struct {
    // Required
    Required string `validate:"required"`
    
    // Length constraints
    Username string `validate:"min=3,max=32"`
    
    // Format validation
    Email    string `validate:"email"`
    URL      string `validate:"url"`
    UUID     string `validate:"uuid"`
    
    // Numeric constraints
    Age      int     `validate:"min=18,max=120"`
    Price    float64 `validate:"gt=0"`
    
    // Pattern matching
    Phone    string `validate:"regexp=^[0-9]{10}$"`
    
    // Conditional
    Optional string `validate:"omitempty,email"`  // Validate only if present
}
```

## Tag Combinations

### Complete Example

```go
type CompleteRequest struct {
    // Multi-source with default and validation
    UserID int `query:"user_id" json:"user_id" header:"X-User-ID" default:"0" validate:"min=1"`
    
    // Optional with validation
    Email string `json:"email" validate:"omitempty,email"`
    
    // Required with custom name
    APIKey string `header:"X-API-Key" binding:"required"`
    
    // Array with default
    Tags []string `query:"tags" default:"general"`
    
    // Nested struct
    Filters struct {
        Category string `json:"category" validate:"required"`
        MinPrice int    `json:"min_price" validate:"min=0"`
    } `json:"filters"`
}
```

## Embedded Structs

Tags on embedded structs:

```go
type Pagination struct {
    Page     int `query:"page" default:"1"`
    PageSize int `query:"page_size" default:"20"`
}

type SearchRequest struct {
    Query string `query:"q"`
    Pagination  // Embedded - inherits tags
}

// Usage
req, err := binding.Query[SearchRequest](values)
// Can access req.Page, req.PageSize
```

### Embedded with Prefix

```go
type SearchRequest struct {
    Query      string `query:"q"`
    Pagination `query:"pagination"`  // Adds prefix
}

// URL: ?q=test&pagination.page=2&pagination.page_size=50
```

## Pointer Fields

Pointers distinguish "not provided" from "zero value":

```go
type UpdateRequest struct {
    // nil = not provided, &0 = set to zero
    Age *int `json:"age"`
    
    // nil = not provided, &"" = set to empty string
    Bio *string `json:"bio"`
    
    // nil = not provided, &false = set to false
    Active *bool `json:"active"`
}
```

## Tag Naming Conventions

### JSON (snake_case)

```go
type User struct {
    FirstName string `json:"first_name"`
    LastName  string `json:"last_name"`
    EmailAddr string `json:"email_address"`
}
```

### Query (snake_case or kebab-case)

```go
type Params struct {
    UserID   int `query:"user_id"`
    SortBy   string `query:"sort_by"`
    SortOrder string `query:"sort-order"`  // kebab-case also fine
}
```

### Headers (Title-Case)

```go
type Headers struct {
    ContentType string `header:"Content-Type"`
    APIKey      string `header:"X-API-Key"`
    RequestID   string `header:"X-Request-ID"`
}
```

## Ignored Fields

Multiple ways to ignore fields:

```go
type Example struct {
    // Unexported - automatically ignored
    internal string
    
    // Explicitly ignored with json tag
    Debug string `json:"-"`
    
    // Explicitly ignored with binding tag
    Temporary string `binding:"-"`
    
    // Exported but not bound
    Computed int  // No tags
}
```

## Complex Types

### Time Fields

```go
type TimeFields struct {
    // RFC3339 format
    CreatedAt time.Time `json:"created_at"`
    
    // Unix timestamp (as integer)
    UpdatedAt time.Time `json:"updated_at,unix"`
    
    // Duration
    Timeout time.Duration `json:"timeout"`  // "30s", "1h", etc.
}
```

### Map Fields

```go
type Config struct {
    // String map
    Metadata map[string]string `json:"metadata"`
    
    // Nested map
    Settings map[string]interface{} `json:"settings"`
    
    // Typed map
    Counters map[string]int `json:"counters"`
}
```

### Interface Fields

```go
type Flexible struct {
    // Any JSON value
    Data interface{} `json:"data"`
    
    // Strongly typed when possible
    Config map[string]interface{} `json:"config"`
}
```

## Tag Best Practices

### 1. Be Consistent

```go
// Good - consistent naming
type User struct {
    UserID    int    `json:"user_id"`
    FirstName string `json:"first_name"`
    LastName  string `json:"last_name"`
}

// Bad - inconsistent naming
type User struct {
    UserID    int    `json:"userId"`
    FirstName string `json:"first_name"`
    LastName  string `json:"LastName"`
}
```

### 2. Use Defaults for Common Values

```go
type Pagination struct {
    Page     int `query:"page" default:"1"`
    PageSize int `query:"page_size" default:"20"`
}
```

### 3. Validate After Binding

```go
// Separate binding from validation
type Request struct {
    Email string `json:"email" validate:"required,email"`
}

// Bind first
req, err := binding.JSON[Request](r.Body)
// Then validate
err = validation.Validate(req)
```

### 4. Document Complex Tags

```go
// UserRequest represents a user creation request.
// The user_id can come from query, JSON, or X-User-ID header.
// If not provided, defaults to 0 (anonymous user).
type UserRequest struct {
    UserID int `query:"user_id" json:"user_id" header:"X-User-ID" default:"0"`
}
```

## Tag Parsing Rules

1. **Tag precedence**: Last source wins (unless using first-wins strategy)
2. **Case sensitivity**: 
   - JSON: case-sensitive
   - Query: case-sensitive
   - Headers: case-insensitive
3. **Empty values**: Use `omitempty` to skip
4. **Type conversion**: Automatic for supported types
5. **Validation**: Applied after binding

## Common Patterns

### API Versioning

```go
type VersionedRequest struct {
    APIVersion string `header:"X-API-Version" query:"api_version" default:"v1"`
    Data       interface{} `json:"data"`
}
```

### Tenant Isolation

```go
type TenantRequest struct {
    TenantID string `header:"X-Tenant-ID" binding:"required"`
    Data     interface{} `json:"data"`
}
```

### Audit Fields

```go
type AuditableRequest struct {
    RequestID string    `header:"X-Request-ID"`
    UserAgent string    `header:"User-Agent"`
    ClientIP  string    `header:"X-Forwarded-For"`
    Timestamp time.Time `binding:"-"`  // Set by server
}
```

## Troubleshooting

### Field Not Binding

Check that:
1. Field is exported (starts with uppercase)
2. Tag name matches source key
3. Tag type matches source (e.g., `query` for query params)

```go
// Wrong
type Bad struct {
    name string `json:"name"`  // Unexported
}

// Correct
type Good struct {
    Name string `json:"name"`
}
```

### Type Conversion Failing

Ensure source data matches field type:

```go
// URL: ?age=twenty
type Params struct {
    Age int `query:"age"`  // Will error - can't convert "twenty" to int
}
```

### Default Not Applied

Defaults only apply when field is missing, not for zero values:

```go
type Params struct {
    Page int `query:"page" default:"1"`
}

// ?page=0 -> Page = 0 (not 1, zero was provided)
// (no page param) -> Page = 1 (default applied)
```

## Next Steps

- Learn about [Type Support](../type-support/) for all supported types
- Explore [Error Handling](../error-handling/) for validation
- See [Advanced Usage](../advanced-usage/) for custom tags
- Review [Examples](../examples/) for real-world patterns

For complete API details, see [API Reference](/reference/packages/binding/api-reference/).
