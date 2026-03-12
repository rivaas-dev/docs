---
title: "Struct Tags"
description: "Validate structs using go-playground/validator tags"
weight: 3
keywords:
  - validation tags
  - field validation
  - go-playground validator
  - struct tags
---

Use struct tags with go-playground/validator syntax to validate your structs. This is the most common validation strategy in the Rivaas validation package.

## Basic Syntax

Add `validate` tags to struct fields:

```go
type User struct {
    Email    string `validate:"required,email"`
    Age      int    `validate:"min=18,max=120"`
    Username string `validate:"required,min=3,max=20"`
}
```

Tags are comma-separated constraints. Each constraint is evaluated, and all must pass for validation to succeed.

## Common Validation Tags

### Required Fields

```go
type User struct {
    Email string `validate:"required"`      // Must be non-zero value
    Name  string `validate:"required"`      // Must be non-empty string
    Age   int    `validate:"required"`      // Must be non-zero number
}
```

### String Constraints

```go
type User struct {
    // Length constraints
    Username string `validate:"min=3,max=20"`
    Bio      string `validate:"max=500"`
    
    // Format constraints
    Email    string `validate:"email"`
    URL      string `validate:"url"`
    UUID     string `validate:"uuid"`
    
    // Character constraints
    AlphaOnly string `validate:"alpha"`
    AlphaNum  string `validate:"alphanum"`
    Numeric   string `validate:"numeric"`
}
```

### Number Constraints

```go
type Product struct {
    Price    float64 `validate:"min=0"`
    Quantity int     `validate:"min=1,max=1000"`
    Rating   float64 `validate:"gte=0,lte=5"`  // Greater/less than or equal
}
```

### Comparison Operators

| Tag | Description |
|-----|-------------|
| `min=N` | Minimum value (numbers) or length (strings/slices) |
| `max=N` | Maximum value (numbers) or length (strings/slices) |
| `eq=N` | Equal to N |
| `ne=N` | Not equal to N |
| `gt=N` | Greater than N |
| `gte=N` | Greater than or equal to N |
| `lt=N` | Less than N |
| `lte=N` | Less than or equal to N |

### Enum Values

```go
type Order struct {
    Status string `validate:"oneof=pending confirmed shipped delivered"`
}
```

Multiple values separated by spaces.

### Collection Constraints

```go
type Request struct {
    Tags   []string `validate:"min=1,max=10,dive,min=2,max=20"`
    //                         ^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^
    //                         Array rules   Element rules
    
    Emails []string `validate:"required,dive,email"`
}
```

Use `dive` to validate elements inside slices/arrays/maps.

### Nested Structs

```go
type Address struct {
    Street string `validate:"required"`
    City   string `validate:"required"`
    Zip    string `validate:"required,numeric,len=5"`
}

type User struct {
    Name    string  `validate:"required"`
    Address Address `validate:"required"` // Validates nested struct
}
```

### Pointer Fields

```go
type User struct {
    Email *string `validate:"omitempty,email"`
    //                      ^^^^^^^^^ Skip validation if nil
}
```

Use `omitempty` to skip validation when the field is nil or zero-value.

## Format Validation Tags

### Email and Web

```go
type Contact struct {
    Email     string `validate:"email"`
    Website   string `validate:"url"`
    Hostname  string `validate:"hostname"`
    IPAddress string `validate:"ip"`
    IPv4      string `validate:"ipv4"`
    IPv6      string `validate:"ipv6"`
}
```

### File Paths

```go
type Config struct {
    DataFile string `validate:"file"`      // Must be existing file
    DataDir  string `validate:"dir"`       // Must be existing directory
    FilePath string `validate:"filepath"`  // Valid file path syntax
}
```

### Identifiers

```go
type Resource struct {
    ID       string `validate:"uuid"`
    UUID4    string `validate:"uuid4"`
    ISBN     string `validate:"isbn"`
    CreditCard string `validate:"credit_card"`
}
```

## Cross-Field Validation

### Field Comparison

```go
type Registration struct {
    Password        string `validate:"required,min=8"`
    ConfirmPassword string `validate:"required,eqfield=Password"`
    //                                         ^^^^^^^^^^^^^^^^
    //                                         Must equal Password field
}
```

### Conditional Validation

```go
type User struct {
    Type  string `validate:"oneof=personal business"`
    TaxID string `validate:"required_if=Type business"`
    //                      ^^^^^^^^^^^^^^^^^^^^^^^^
    //                      Required when Type is "business"
}
```

Cross-field tags:

| Tag | Description |
|-----|-------------|
| `eqfield=Field` | Must equal another field |
| `nefield=Field` | Must not equal another field |
| `gtfield=Field` | Must be greater than another field |
| `ltfield=Field` | Must be less than another field |
| `required_if=Field Value` | Required when field equals value |
| `required_unless=Field Value` | Required unless field equals value |
| `required_with=Field` | Required when field is present |
| `required_without=Field` | Required when field is absent |

## Advanced Tags

### Regular Expressions

```go
type User struct {
    Phone string `validate:"required,e164"`           // E.164 phone format
    Slug  string `validate:"required,alphanum,min=3"` // URL-safe slug
}
```

### Boolean Logic

```go
type Product struct {
    // Must be numeric OR alpha
    Code string `validate:"numeric|alpha"`
}
```

Use `|` (OR) to allow multiple constraint sets.

### Custom Formats

```go
type Data struct {
    Datetime string `validate:"datetime=2006-01-02"`
    Date     string `validate:"datetime=2006-01-02 15:04:05"`
}
```

## Tag Naming with JSON

By default, validation uses JSON field names in error messages:

```go
type User struct {
    Email string `json:"email_address" validate:"required,email"`
    //            ^^^^^^^^^^^^^^^^^^^ Used in error message
}
```

Error message will reference `email_address`, not `Email`.

## Validation Example

Complete example with various constraints:

```go
package main

import (
    "context"
    "fmt"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    // Required string with length constraints
    Username string `json:"username" validate:"required,min=3,max=20,alphanum"`
    
    // Valid email address
    Email string `json:"email" validate:"required,email"`
    
    // Age range
    Age int `json:"age" validate:"required,min=18,max=120"`
    
    // Password with confirmation
    Password        string `json:"password" validate:"required,min=8"`
    ConfirmPassword string `json:"confirm_password" validate:"required,eqfield=Password"`
    
    // Optional phone (validated if provided)
    Phone string `json:"phone" validate:"omitempty,e164"`
    
    // Enum value
    Role string `json:"role" validate:"required,oneof=user admin moderator"`
    
    // Nested struct
    Address Address `json:"address" validate:"required"`
    
    // Array with constraints
    Tags []string `json:"tags" validate:"min=1,max=10,dive,min=2,max=20"`
}

type Address struct {
    Street  string `json:"street" validate:"required"`
    City    string `json:"city" validate:"required"`
    State   string `json:"state" validate:"required,len=2,alpha"`
    ZipCode string `json:"zip_code" validate:"required,numeric,len=5"`
}

func main() {
    ctx := context.Background()
    
    req := CreateUserRequest{
        Username:        "ab",                // Too short
        Email:           "invalid",           // Invalid email
        Age:             15,                  // Too young
        Password:        "pass",              // Too short
        ConfirmPassword: "different",         // Doesn't match
        Phone:           "123",               // Invalid format
        Role:            "superuser",         // Not in enum
        Address:         Address{},           // Missing required fields
        Tags:            []string{"a", "bb"}, // First tag too short
    }
    
    err := validation.Validate(ctx, &req)
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

## Tag Reference

For a complete list of available tags, see the [go-playground/validator documentation](https://pkg.go.dev/github.com/go-playground/validator/v10).

Common categories:

- **Comparison**: `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `min`, `max`, `len`
- **Strings**: `alpha`, `alphanum`, `numeric`, `email`, `url`, `uuid`, `contains`, `startswith`, `endswith`
- **Numbers**: Range validation, divisibility
- **Network**: `ip`, `ipv4`, `ipv6`, `hostname`, `mac`
- **Files**: `file`, `dir`, `filepath`
- **Cross-field**: `eqfield`, `nefield`, `gtfield`, `ltfield`
- **Conditional**: `required_if`, `required_unless`, `required_with`, `required_without`

## Performance Considerations

- Struct validation tags are cached after first use (fast)
- Tag validator is initialized lazily (only when needed)
- Thread-safe for concurrent validation
- No runtime overhead for unused tags

## Next Steps

- [**JSON Schema**](../json-schema/) - Alternative validation with JSON Schema
- [**Custom Validators**](../custom-validators/) - Register custom validation tags
- [**Error Handling**](../error-handling/) - Handle validation errors
- [**go-playground/validator docs**](https://pkg.go.dev/github.com/go-playground/validator/v10) - Complete tag reference
