---
title: "Validation"
linkTitle: "Validation"
weight: 80
description: >
  Validate requests with multiple strategies: interface methods, struct tags, or JSON Schema.
---

Request validation ensures incoming data meets your requirements before processing.

{{% alert title="Validation Approaches" color="info" %}}
The router provides strict JSON binding with `BindStrict()`. For comprehensive validation with struct tags and multi-source binding, use the [binding package](/guides/binding/) with the [validation package](/guides/validation/).
{{% /alert %}}

## Validation Strategies

### Strategy Selection

```text
Need complex business logic or request-scoped rules?
├─ Yes → Use Validate/ValidateContext interface methods
└─ No  → Continue ↓

Validating against external/shared schema?
├─ Yes → Use JSON Schema validation
└─ No  → Continue ↓

Simple field constraints (required, min, max, format)?
├─ Yes → Use struct tags (binding package + go-playground/validator)
└─ No  → Use manual validation
```

## Interface Validation

Implement the `Validate` or `ValidateContext` interface on your request structs:

### Basic Validation

```go
type TransferRequest struct {
    FromAccount string  `json:"from_account"`
    ToAccount   string  `json:"to_account"`
    Amount      float64 `json:"amount"`
}

func (t *TransferRequest) Validate() error {
    if t.FromAccount == t.ToAccount {
        return errors.New("cannot transfer to same account")
    }
    if t.Amount > 10000 {
        return errors.New("amount exceeds daily limit")
    }
    return nil
}
```

### Context-Aware Validation

```go
type CreatePostRequest struct {
    Title string   `json:"title"`
    Tags  []string `json:"tags"`
}

func (p *CreatePostRequest) ValidateContext(ctx context.Context) error {
    // Get user tier from context
    tier := ctx.Value("user_tier")
    if tier == "free" && len(p.Tags) > 3 {
        return errors.New("free users can only use 3 tags")
    }
    return nil
}
```

### Handler Integration

```go
func createTransfer(c *router.Context) {
    var req TransferRequest
    if err := c.BindStrict(&req, router.BindOptions{MaxBytes: 1 << 20}); err != nil {
        return // Error response already written
    }
    
    // Call interface validation method
    if err := req.Validate(); err != nil {
        c.JSON(400, map[string]string{"error": err.Error()})
        return
    }
    
    // Process validated request
    c.JSON(200, map[string]string{"status": "success"})
}
```

## Tag Validation with Binding Package

Use the binding package with struct tags for declarative validation:

```go
import (
    "rivaas.dev/binding"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Username string `json:"username" validate:"required,min=3,max=20"`
    Age      int    `json:"age" validate:"required,min=18,max=120"`
}

func createUser(c *router.Context) {
    var req CreateUserRequest
    
    // Bind JSON using binding package
    if err := binding.JSON(c.Request, &req); err != nil {
        c.JSON(400, map[string]string{"error": err.Error()})
        return
    }
    
    // Validate with struct tags
    if err := validation.Validate(&req); err != nil {
        c.JSON(400, map[string]string{"error": err.Error()})
        return
    }
    
    c.JSON(201, req)
}
```

### Common Validation Tags

```go
type Example struct {
    Required string  `validate:"required"`           // Must be present
    Email    string  `validate:"email"`              // Valid email format
    URL      string  `validate:"url"`                // Valid URL
    Min      int     `validate:"min=10"`             // Minimum value
    Max      int     `validate:"max=100"`            // Maximum value
    Range    int     `validate:"min=10,max=100"`     // Range
    Length   string  `validate:"min=3,max=50"`       // String length
    OneOf    string  `validate:"oneof=active pending"` // Enum
    Optional string  `validate:"omitempty,email"`    // Optional but validates if present
}
```

## JSON Schema Validation

Implement the `JSONSchemaProvider` interface for contract-based validation:

```go
type ProductRequest struct {
    Name  string  `json:"name"`
    Price float64 `json:"price"`
    SKU   string  `json:"sku"`
}

func (p *ProductRequest) JSONSchema() (id string, schema string) {
    return "product-v1", `{
        "type": "object",
        "properties": {
            "name": {"type": "string", "minLength": 3},
            "price": {"type": "number", "minimum": 0},
            "sku": {"type": "string", "pattern": "^[A-Z]{3}-[0-9]{6}$"}
        },
        "required": ["name", "price", "sku"]
    }`
}
```

## Combining Binding and Validation

For a complete solution, combine strict binding with interface validation:

```go
type CreateOrderRequest struct {
    CustomerID string       `json:"customer_id"`
    Items      []OrderItem  `json:"items"`
    Notes      string       `json:"notes"`
}

func (r *CreateOrderRequest) Validate() error {
    if len(r.Items) == 0 {
        return errors.New("order must have at least one item")
    }
    for i, item := range r.Items {
        if item.Quantity <= 0 {
            return fmt.Errorf("item %d: quantity must be positive", i)
        }
    }
    return nil
}

func createOrder(c *router.Context) {
    var req CreateOrderRequest
    
    // Strict JSON binding
    if err := c.BindStrict(&req, router.BindOptions{MaxBytes: 1 << 20}); err != nil {
        return // Error already written
    }
    
    // Business logic validation
    if err := req.Validate(); err != nil {
        c.JSON(400, map[string]string{"error": err.Error()})
        return
    }
    
    c.JSON(201, req)
}
```

## Partial Validation (PATCH)

For PATCH requests, use pointer fields and check for presence:

```go
type UpdateUserRequest struct {
    Email    *string `json:"email,omitempty"`
    Username *string `json:"username,omitempty"`
    Bio      *string `json:"bio,omitempty"`
}

func (r *UpdateUserRequest) Validate() error {
    if r.Email != nil && *r.Email == "" {
        return errors.New("email cannot be empty if provided")
    }
    if r.Username != nil && len(*r.Username) < 3 {
        return errors.New("username must be at least 3 characters")
    }
    if r.Bio != nil && len(*r.Bio) > 500 {
        return errors.New("bio cannot exceed 500 characters")
    }
    return nil
}

func updateUser(c *router.Context) {
    var req UpdateUserRequest
    
    if err := c.BindStrict(&req, router.BindOptions{}); err != nil {
        return
    }
    
    if err := req.Validate(); err != nil {
        c.JSON(400, map[string]string{"error": err.Error()})
        return
    }
    
    // Update only non-nil fields
    if req.Email != nil {
        // Update email
    }
    
    c.JSON(200, map[string]string{"status": "updated"})
}
```

## Structured Validation Errors

Return detailed errors for better API usability:

```go
type ValidationError struct {
    Field   string `json:"field"`
    Message string `json:"message"`
}

type ValidationErrors struct {
    Errors []ValidationError `json:"errors"`
}

func (r *CreateUserRequest) Validate() *ValidationErrors {
    var errs []ValidationError
    
    if r.Email == "" {
        errs = append(errs, ValidationError{
            Field:   "email",
            Message: "email is required",
        })
    }
    
    if len(r.Username) < 3 {
        errs = append(errs, ValidationError{
            Field:   "username",
            Message: "username must be at least 3 characters",
        })
    }
    
    if len(errs) > 0 {
        return &ValidationErrors{Errors: errs}
    }
    return nil
}

func createUser(c *router.Context) {
    var req CreateUserRequest
    
    if err := c.BindStrict(&req, router.BindOptions{}); err != nil {
        return
    }
    
    if verrs := req.Validate(); verrs != nil {
        c.JSON(400, verrs)
        return
    }
    
    c.JSON(201, req)
}
```

## Best Practices

**Do:**

- Use interface methods (`Validate()`) for business logic validation
- Use pointer fields (`*string`) for optional PATCH fields
- Return structured errors with field paths
- Validate early, fail fast
- Use `BindStrict()` for size limits and strict JSON parsing

**Don't:**

- Return sensitive data in validation error messages
- Perform expensive validation (DB lookups) in `Validate()` - use `ValidateContext()` for those
- Skip validation for internal endpoints

## Complete Example

```go
package main

import (
    "errors"
    "net/http"
    "rivaas.dev/router"
)

type CreateUserRequest struct {
    Email    string `json:"email"`
    Username string `json:"username"`
    Age      int    `json:"age"`
}

func (r *CreateUserRequest) Validate() error {
    if r.Email == "" {
        return errors.New("email is required")
    }
    if len(r.Username) < 3 {
        return errors.New("username must be at least 3 characters")
    }
    if r.Age < 18 || r.Age > 120 {
        return errors.New("age must be between 18 and 120")
    }
    return nil
}

func main() {
    r := router.MustNew()
    
    r.POST("/users", func(c *router.Context) {
        var req CreateUserRequest
        
        // Bind JSON with strict validation
        if err := c.BindStrict(&req, router.BindOptions{MaxBytes: 1 << 20}); err != nil {
            return // Error response already sent
        }
        
        // Run business validation
        if err := req.Validate(); err != nil {
            c.JSON(400, map[string]string{"error": err.Error()})
            return
        }
        
        c.JSON(201, req)
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Next Steps

- **Binding Package**: Full binding documentation at [binding guide](/guides/binding/)
- **Response Rendering**: Learn about [response rendering](../response-rendering/)
- **Examples**: See [complete examples](../examples/) with validation
