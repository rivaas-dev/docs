---
title: "Custom Validation Interfaces"
description: "Implement custom validation methods with Validate() and ValidateContext()"
weight: 5
---

Implement custom validation logic by adding `Validate()` or `ValidateContext()` methods to your structs. This provides the most flexible validation approach for complex business rules.

## ValidatorInterface

Implement the `ValidatorInterface` for simple custom validation:

```go
type ValidatorInterface interface {
    Validate() error
}
```

### Basic Example

```go
type User struct {
    Email string
    Name  string
}

func (u *User) Validate() error {
    if !strings.Contains(u.Email, "@") {
        return errors.New("email must contain @")
    }
    if len(u.Name) < 2 {
        return errors.New("name too short")
    }
    return nil
}

// Validation automatically calls u.Validate()
err := validation.Validate(ctx, &user)
```

### Returning Structured Errors

Return `*validation.Error` for detailed field-level errors:

```go
func (u *User) Validate() error {
    var verr validation.Error
    
    if !strings.Contains(u.Email, "@") {
        verr.Add("email", "format", "must contain @", nil)
    }
    
    if len(u.Name) < 2 {
        verr.Add("name", "length", "must be at least 2 characters", nil)
    }
    
    if verr.HasErrors() {
        return &verr
    }
    return nil
}
```

## ValidatorWithContext

Implement `ValidatorWithContext` for context-aware validation:

```go
type ValidatorWithContext interface {
    ValidateContext(context.Context) error
}
```

This is preferred when you need access to request-scoped data.

### Context-Aware Validation

```go
type User struct {
    Email    string
    TenantID string
}

func (u *User) ValidateContext(ctx context.Context) error {
    // Access context values
    tenant := ctx.Value("tenant").(string)
    
    // Tenant-specific validation
    if u.TenantID != tenant {
        return errors.New("user does not belong to this tenant")
    }
    
    // Additional validation
    if !strings.HasSuffix(u.Email, "@"+tenant+".com") {
        return fmt.Errorf("email must be from %s.com domain", tenant)
    }
    
    return nil
}
```

### Database Validation

```go
type User struct {
    Username string
    Email    string
}

func (u *User) ValidateContext(ctx context.Context) error {
    // Get database from context
    db := ctx.Value("db").(*sql.DB)
    
    // Check username uniqueness
    var exists bool
    err := db.QueryRowContext(ctx,
        "SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)",
        u.Username,
    ).Scan(&exists)
    
    if err != nil {
        return fmt.Errorf("failed to check username: %w", err)
    }
    
    if exists {
        return errors.New("username already taken")
    }
    
    return nil
}
```

## Interface Priority

When a type implements `ValidatorInterface` or `ValidatorWithContext`, those methods have the highest priority:

**Priority Order:**
1. `ValidateContext(ctx)` or `Validate()` (highest)
2. Struct tags (`validate:"..."`)
3. JSON Schema (`JSONSchemaProvider`)

```go
type User struct {
    Email string `validate:"required,email"` // Lower priority
}

func (u *User) Validate() error {
    // This runs instead of struct tags
    return customEmailValidation(u.Email)
}
```

Override this behavior by explicitly selecting a strategy:

```go
// Skip interface method, use struct tags
err := validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyTags),
)
```

## Combining with Other Strategies

Run interface validation along with other strategies:

```go
type User struct {
    Email string `validate:"required,email"`
}

func (u *User) Validate() error {
    // Custom business logic
    if isBlacklisted(u.Email) {
        return errors.New("email is blacklisted")
    }
    return nil
}

// Run both interface method AND struct tag validation
err := validation.Validate(ctx, &user,
    validation.WithRunAll(true),
)
```

All errors are aggregated into a single `*validation.Error`.

## Pointer vs Value Receivers

The validation package works with both pointer and value receivers:

### Pointer Receiver (Recommended)

```go
func (u *User) Validate() error {
    // Can modify the struct if needed
    u.Email = strings.ToLower(u.Email)
    return nil
}
```

### Value Receiver

```go
func (u User) Validate() error {
    // Read-only validation
    if u.Email == "" {
        return errors.New("email required")
    }
    return nil
}
```

Use pointer receivers when you need to modify the struct during validation (normalization, etc.).

## Complex Validation Example

```go
type CreateOrderRequest struct {
    UserID    int
    Items     []OrderItem
    CouponCode string
    Total     float64
}

type OrderItem struct {
    ProductID int
    Quantity  int
    Price     float64
}

func (r *CreateOrderRequest) ValidateContext(ctx context.Context) error {
    var verr validation.Error
    
    // Validate user exists
    if !userExists(ctx, r.UserID) {
        verr.Add("user_id", "not_found", "user does not exist", nil)
    }
    
    // Validate items
    if len(r.Items) == 0 {
        verr.Add("items", "required", "at least one item required", nil)
    }
    
    var calculatedTotal float64
    for i, item := range r.Items {
        // Validate product exists and price matches
        product, err := getProduct(ctx, item.ProductID)
        if err != nil {
            verr.Add(
                fmt.Sprintf("items.%d.product_id", i),
                "not_found",
                "product does not exist",
                nil,
            )
            continue
        }
        
        if item.Price != product.Price {
            verr.Add(
                fmt.Sprintf("items.%d.price", i),
                "mismatch",
                "price does not match current product price",
                map[string]any{
                    "expected": product.Price,
                    "actual":   item.Price,
                },
            )
        }
        
        if item.Quantity < 1 {
            verr.Add(
                fmt.Sprintf("items.%d.quantity", i),
                "invalid",
                "quantity must be at least 1",
                nil,
            )
        }
        
        calculatedTotal += item.Price * float64(item.Quantity)
    }
    
    // Validate coupon if provided
    if r.CouponCode != "" {
        discount, err := validateCoupon(ctx, r.CouponCode)
        if err != nil {
            verr.Add("coupon_code", "invalid", err.Error(), nil)
        } else {
            calculatedTotal -= discount
        }
    }
    
    // Validate total matches calculation
    if math.Abs(r.Total-calculatedTotal) > 0.01 {
        verr.Add(
            "total",
            "mismatch",
            "total does not match item prices",
            map[string]any{
                "expected": calculatedTotal,
                "actual":   r.Total,
            },
        )
    }
    
    if verr.HasErrors() {
        return &verr
    }
    return nil
}
```

## Testing Interface Validation

Test your validation methods directly:

```go
func TestUserValidation(t *testing.T) {
    tests := []struct {
        name    string
        user    User
        wantErr bool
    }{
        {
            name:    "valid user",
            user:    User{Email: "test@example.com", Name: "Alice"},
            wantErr: false,
        },
        {
            name:    "invalid email",
            user:    User{Email: "invalid", Name: "Alice"},
            wantErr: true,
        },
        {
            name:    "short name",
            user:    User{Email: "test@example.com", Name: "A"},
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.user.Validate()
            if (err != nil) != tt.wantErr {
                t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

## Best Practices

### 1. Keep Methods Focused

```go
// Good: Focused validation
func (u *User) Validate() error {
    if err := validateEmail(u.Email); err != nil {
        return err
    }
    if err := validateName(u.Name); err != nil {
        return err
    }
    return nil
}

// Bad: Too much logic in one method
func (u *User) Validate() error {
    // 200 lines of validation code...
}
```

### 2. Return Structured Errors

```go
// Good: Structured errors
func (u *User) Validate() error {
    var verr validation.Error
    verr.Add("email", "invalid", "must be valid email", nil)
    return &verr
}

// Bad: Generic errors
func (u *User) Validate() error {
    return errors.New("email invalid")
}
```

### 3. Use Context for External Dependencies

```go
// Good: Dependencies from context
func (u *User) ValidateContext(ctx context.Context) error {
    db := ctx.Value("db").(*sql.DB)
    return checkUsernameUnique(ctx, db, u.Username)
}

// Bad: Global dependencies
var globalDB *sql.DB
func (u *User) Validate() error {
    return checkUsernameUnique(context.Background(), globalDB, u.Username)
}
```

### 4. Consider Performance

```go
// Good: Fast validation first
func (u *User) ValidateContext(ctx context.Context) error {
    // Quick checks first
    if u.Email == "" {
        return errors.New("email required")
    }
    
    // Expensive DB check last
    return checkEmailUnique(ctx, u.Email)
}
```

## Error Metadata

Add metadata to errors for better debugging:

```go
func (u *User) Validate() error {
    var verr validation.Error
    
    verr.Add("email", "blacklisted", "email domain is blacklisted", map[string]any{
        "domain":     extractDomain(u.Email),
        "reason":     "spam",
        "blocked_at": time.Now(),
    })
    
    return &verr
}
```

## Next Steps

- [**Partial Validation**](../partial-validation/) - Handle PATCH requests
- [**Error Handling**](../error-handling/) - Work with validation errors
- [**Struct Tags**](../struct-tags/) - Alternative validation approach
- [**Interfaces Reference**](/reference/packages/validation/interfaces/) - Complete interface documentation
