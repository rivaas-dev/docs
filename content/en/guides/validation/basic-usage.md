---
title: "Basic Usage"
description: "Learn the fundamentals of validating structs"
weight: 2
---

Learn how to validate structs using the validation package. This guide starts from simple package-level functions and progresses to customized validator instances.

## Package-Level Validation

The simplest way to validate is using the package-level `Validate` function:

```go
import (
    "context"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"min=18"`
}

func Handler(ctx context.Context, req CreateUserRequest) error {
    if err := validation.Validate(ctx, &req); err != nil {
        return err
    }
    // Process valid request
    return nil
}
```

### Handling Validation Errors

Validation errors are returned as structured `*validation.Error` values:

```go
err := validation.Validate(ctx, &req)
if err != nil {
    var verr *validation.Error
    if errors.As(err, &verr) {
        // Access structured field errors
        for _, fieldErr := range verr.Fields {
            fmt.Printf("%s: %s\n", fieldErr.Path, fieldErr.Message)
        }
    }
}
```

## Creating a Validator Instance

For more control, create a `Validator` instance with custom configuration:

```go
validator := validation.MustNew(
    validation.WithMaxErrors(10),
    validation.WithRedactor(sensitiveFieldRedactor),
)

// Use in handlers
if err := validator.Validate(ctx, &req); err != nil {
    // Handle validation errors
}
```

### New vs MustNew

There are two constructors:

```go
// New returns an error if configuration is invalid
validator, err := validation.New(
    validation.WithMaxErrors(-1), // Invalid
)
if err != nil {
    return fmt.Errorf("failed to create validator: %w", err)
}

// MustNew panics if configuration is invalid (use in main/init)
validator := validation.MustNew(
    validation.WithMaxErrors(10),
)
```

Use `MustNew` in `main()` or `init()` where panic on startup is acceptable. Use `New` when you need to handle initialization errors gracefully.

## Per-Call Options

Override validator configuration on a per-call basis:

```go
validator := validation.MustNew(
    validation.WithMaxErrors(10),
)

// Override max errors for this call
err := validator.Validate(ctx, &req,
    validation.WithMaxErrors(5),
    validation.WithStrategy(validation.StrategyTags),
)
```

Per-call options don't modify the validator instance - they create a temporary config for that call only.

## Validating Different Types

### Structs

The most common use case:

```go
type User struct {
    Name  string `validate:"required,min=2"`
    Email string `validate:"required,email"`
}

user := User{Name: "A", Email: "invalid"}
err := validation.Validate(ctx, &user)
```

### Pointers

Pass pointers to structs:

```go
user := &User{Name: "Alice", Email: "alice@example.com"}
err := validation.Validate(ctx, user)
```

### Nil Values

Validating nil values returns an error:

```go
var user *User
err := validation.Validate(ctx, user)
// Returns: *validation.Error with code "nil_pointer"
```

## Context Usage

The context is passed to `ValidatorWithContext` implementations:

```go
type User struct {
    Email string
}

func (u *User) ValidateContext(ctx context.Context) error {
    // Access request-scoped data
    tenant := ctx.Value("tenant").(string)
    // Apply tenant-specific validation
    return nil
}

// Context is passed to ValidateContext
err := validation.Validate(ctx, &user)
```

For struct tags and JSON Schema validation, the context is not used (but must be provided for consistency).

## Common Options

### Limit Error Count

Stop validation after N errors:

```go
err := validation.Validate(ctx, &req,
    validation.WithMaxErrors(5),
)
```

### Choose Strategy

Explicitly select a validation strategy:

```go
// Use only struct tags
err := validation.Validate(ctx, &req,
    validation.WithStrategy(validation.StrategyTags),
)

// Use only JSON Schema
err := validation.Validate(ctx, &req,
    validation.WithStrategy(validation.StrategyJSONSchema),
)

// Use only interface methods
err := validation.Validate(ctx, &req,
    validation.WithStrategy(validation.StrategyInterface),
)
```

### Run All Strategies

Run all applicable strategies and aggregate errors:

```go
err := validation.Validate(ctx, &req,
    validation.WithRunAll(true),
)
```

## Thread Safety

Both package-level functions and `Validator` instances are safe for concurrent use:

```go
validator := validation.MustNew(
    validation.WithMaxErrors(10),
)

// Safe to use from multiple goroutines
go func() {
    validator.Validate(ctx, &user1)
}()

go func() {
    validator.Validate(ctx, &user2)
}()
```

## Default Validator

Package-level functions use a shared default validator:

```go
// These both use the same default validator
validation.Validate(ctx, &req1)
validation.Validate(ctx, &req2)
```

The default validator is created with zero configuration. If you need custom options, create your own `Validator` instance.

## Working Example

Here's a complete example showing basic usage:

```go
package main

import (
    "context"
    "fmt"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Username string `validate:"required,min=3,max=20"`
    Email    string `validate:"required,email"`
    Age      int    `validate:"min=18,max=120"`
}

func main() {
    ctx := context.Background()
    
    // Invalid request
    req := CreateUserRequest{
        Username: "ab",           // Too short
        Email:    "not-an-email", // Invalid format
        Age:      15,             // Too young
    }
    
    err := validation.Validate(ctx, &req)
    if err != nil {
        var verr *validation.Error
        if errors.As(err, &verr) {
            fmt.Println("Validation errors:")
            for _, fieldErr := range verr.Fields {
                fmt.Printf("  %s: %s\n", fieldErr.Path, fieldErr.Message)
            }
        }
    }
}
```

Output:

```
Validation errors:
  Username: min constraint failed
  Email: must be a valid email address
  Age: min constraint failed
```

## Next Steps

- [**Struct Tags**](../struct-tags/) - Learn go-playground/validator tag syntax
- [**JSON Schema**](../json-schema/) - Validate with JSON Schema
- [**Custom Interfaces**](../custom-interfaces/) - Implement custom validation methods
- [**Error Handling**](../error-handling/) - Work with structured errors
- [**API Reference**](/reference/packages/validation/api-reference/) - Complete function documentation
