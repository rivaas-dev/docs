---
title: "Request Validation"
linkTitle: "Validation"
description: "Flexible, multi-strategy validation for Go structs with support for struct tags, JSON Schema, and custom interfaces"
weight: 4
---

{{% pageinfo %}}
The Rivaas Validation package provides flexible, multi-strategy validation for Go structs with support for struct tags, JSON Schema, and custom interfaces, including detailed error messages and built-in security features.
{{% /pageinfo %}}

## Features

- **Multiple Validation Strategies**
  - Struct tags via [go-playground/validator](https://github.com/go-playground/validator)
  - JSON Schema (RFC-compliant)
  - Custom interfaces (`Validate()` / `ValidateContext()`)
- **Partial Validation** - For PATCH requests where only provided fields should be validated
- **Thread-Safe** - Safe for concurrent use by multiple goroutines
- **Security** - Built-in protections against deep nesting, memory exhaustion, and sensitive data exposure
- **Standalone** - Can be used independently without the full Rivaas framework
- **Custom Validators** - Easy registration of custom validation tags

## Quick Start

### Basic Validation

The simplest way to use this package is with the package-level `Validate` function:

```go
import "rivaas.dev/validation"

type User struct {
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"min=18"`
}

user := User{Email: "invalid", Age: 15}
if err := validation.Validate(ctx, &user); err != nil {
    var verr *validation.Error
    if errors.As(err, &verr) {
        for _, fieldErr := range verr.Fields {
            fmt.Printf("%s: %s\n", fieldErr.Path, fieldErr.Message)
        }
    }
}
```

### Custom Validator Instance

For more control, create a `Validator` instance with custom options:

```go
validator := validation.MustNew(
    validation.WithRedactor(sensitiveFieldRedactor),
    validation.WithMaxErrors(10),
    validation.WithCustomTag("phone", phoneValidator),
)

if err := validator.Validate(ctx, &user); err != nil {
    // Handle validation errors
}
```

### Partial Validation (PATCH Requests)

For PATCH requests where only provided fields should be validated:

```go
// Compute which fields are present in the JSON
presence, _ := validation.ComputePresence(rawJSON)

// Validate only the present fields
err := validator.ValidatePartial(ctx, &user, presence)
```

## Learning Path

Follow these guides to master validation with Rivaas:

1. [**Installation**](installation/) - Get started with the validation package
2. [**Basic Usage**](basic-usage/) - Learn the fundamentals of validation
3. [**Struct Tags**](struct-tags/) - Use go-playground/validator struct tags
4. [**JSON Schema**](json-schema/) - Validate with JSON Schema
5. [**Custom Interfaces**](custom-interfaces/) - Implement Validate() methods
6. [**Partial Validation**](partial-validation/) - Handle PATCH requests correctly
7. [**Error Handling**](error-handling/) - Work with structured errors
8. [**Custom Validators**](custom-validators/) - Register custom tags and functions
9. [**Security**](security/) - Protect sensitive data and prevent attacks
10. [**Examples**](examples/) - Real-world integration patterns

## Validation Strategies

The package supports three validation strategies that can be used individually or combined:

### 1. Struct Tags (go-playground/validator)

Use struct tags with go-playground/validator syntax:

```go
type User struct {
    Email string `validate:"required,email"`
    Age   int    `validate:"min=18,max=120"`
    Name  string `validate:"required,min=2,max=100"`
}
```

### 2. JSON Schema

Implement the `JSONSchemaProvider` interface:

```go
type User struct {
    Email string `json:"email"`
    Age   int    `json:"age"`
}

func (u User) JSONSchema() (id, schema string) {
    return "user-schema", `{
        "type": "object",
        "properties": {
            "email": {"type": "string", "format": "email"},
            "age": {"type": "integer", "minimum": 18}
        },
        "required": ["email"]
    }`
}
```

### 3. Custom Validation Interface

Implement `ValidatorInterface` for simple validation:

```go
type User struct {
    Email string
}

func (u *User) Validate() error {
    if !strings.Contains(u.Email, "@") {
        return errors.New("email must contain @")
    }
    return nil
}

// validation.Validate will automatically call u.Validate()
err := validation.Validate(ctx, &user)
```

Or implement `ValidatorWithContext` for context-aware validation:

```go
func (u *User) ValidateContext(ctx context.Context) error {
    // Access request-scoped data from context
    tenant := ctx.Value("tenant").(string)
    // Apply tenant-specific validation rules
    return nil
}
```

## Strategy Priority

The package automatically selects the best strategy based on the type:

**Priority Order:**
1. Interface methods (`Validate()` / `ValidateContext()`)
2. Struct tags (`validate:"..."`)
3. JSON Schema (`JSONSchemaProvider`)

You can explicitly choose a strategy:

```go
err := validator.Validate(ctx, &user, validation.WithStrategy(validation.StrategyTags))
```

Or run all applicable strategies:

```go
err := validator.Validate(ctx, &user, validation.WithRunAll(true))
```

## Comparison with Other Libraries

| Feature | rivaas.dev/validation | go-playground/validator | JSON Schema validators |
|---------|----------------------|------------------------|----------------------|
| Struct tags | ✅ | ✅ | ❌ |
| JSON Schema | ✅ | ❌ | ✅ |
| Custom interfaces | ✅ | ❌ | ❌ |
| Partial validation | ✅ | ❌ | ❌ |
| Multi-strategy | ✅ | ❌ | ❌ |
| Context support | ✅ | ❌ | Varies |
| Built-in redaction | ✅ | ❌ | ❌ |
| Thread-safe | ✅ | ✅ | Varies |

## Next Steps

- Start with [Installation](installation/) to set up the validation package
- Explore the [API Reference](/reference/packages/validation/) for complete technical details
- Check out [examples](examples/) for real-world integration patterns

For integration with rivaas/app, the Context provides convenient methods that handle validation automatically.
