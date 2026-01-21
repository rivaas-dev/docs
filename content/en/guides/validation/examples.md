---
title: "Examples"
description: "Real-world validation patterns and integration examples"
weight: 10
keywords:
  - validation examples
  - code samples
  - patterns
  - integration
---

Complete examples showing how to use the validation package in real-world scenarios.

## Basic REST API

### Create User Endpoint

```go
package main

import (
    "context"
    "encoding/json"
    "net/http"
    
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Username string `json:"username" validate:"required,min=3,max=20,alphanum"`
    Email    string `json:"email" validate:"required,email"`
    Age      int    `json:"age" validate:"required,min=18,max=120"`
    Password string `json:"password" validate:"required,min=8"`
}

var validator = validation.MustNew(
    validation.WithRedactor(func(path string) bool {
        return strings.Contains(path, "password")
    }),
    validation.WithMaxErrors(10),
)

func CreateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }
    
    if err := validator.Validate(ctx, &req); err != nil {
        handleValidationError(w, err)
        return
    }
    
    // Create user
    user, err := createUser(ctx, req)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(user)
}

func handleValidationError(w http.ResponseWriter, err error) {
    var verr *validation.Error
    if !errors.As(err, &verr) {
        http.Error(w, "validation failed", http.StatusBadRequest)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusUnprocessableEntity)
    json.NewEncoder(w).Encode(map[string]any{
        "error":  "validation_failed",
        "fields": verr.Fields,
    })
}
```

### Update User Endpoint (PATCH)

```go
type UpdateUserRequest struct {
    Email *string `json:"email" validate:"omitempty,email"`
    Age   *int    `json:"age" validate:"omitempty,min=18,max=120"`
}

func UpdateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    
    // Read raw body
    rawJSON, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "failed to read body", http.StatusBadRequest)
        return
    }
    
    // Compute which fields are present
    presence, err := validation.ComputePresence(rawJSON)
    if err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }
    
    // Parse into struct
    var req UpdateUserRequest
    if err := json.Unmarshal(rawJSON, &req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }
    
    // Validate only present fields
    if err := validation.ValidatePartial(ctx, &req, presence); err != nil {
        handleValidationError(w, err)
        return
    }
    
    // Update user
    userID := r.PathValue("id")
    if err := updateUser(ctx, userID, req, presence); err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    
    w.WriteHeader(http.StatusOK)
}
```

## Custom Validation Methods

### Order Validation

```go
type CreateOrderRequest struct {
    UserID    int         `json:"user_id"`
    Items     []OrderItem `json:"items"`
    CouponCode string     `json:"coupon_code"`
    Total     float64     `json:"total"`
}

type OrderItem struct {
    ProductID int     `json:"product_id" validate:"required"`
    Quantity  int     `json:"quantity" validate:"required,min=1"`
    Price     float64 `json:"price" validate:"required,min=0"`
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
        // Validate product and price
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
        
        calculatedTotal += item.Price * float64(item.Quantity)
    }
    
    // Validate coupon
    if r.CouponCode != "" {
        discount, err := validateCoupon(ctx, r.CouponCode)
        if err != nil {
            verr.Add("coupon_code", "invalid", err.Error(), nil)
        } else {
            calculatedTotal -= discount
        }
    }
    
    // Validate total
    if math.Abs(r.Total-calculatedTotal) > 0.01 {
        verr.Add(
            "total",
            "mismatch",
            "total does not match calculated amount",
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

## Custom Validation Tags

### Application Validator

```go
package app

import (
    "regexp"
    "unicode"
    
    "github.com/go-playground/validator/v10"
    "rivaas.dev/validation"
)

var (
    phoneRegex    = regexp.MustCompile(`^\+?[1-9]\d{1,14}$`)
    usernameRegex = regexp.MustCompile(`^[a-zA-Z0-9_]{3,20}$`)
)

var Validator = validation.MustNew(
    // Custom tags
    validation.WithCustomTag("phone", validatePhone),
    validation.WithCustomTag("username", validateUsername),
    validation.WithCustomTag("strong_password", validateStrongPassword),
    
    // Security
    validation.WithRedactor(sensitiveFieldRedactor),
    validation.WithMaxErrors(20),
    
    // Custom messages
    validation.WithMessages(map[string]string{
        "required": "is required",
        "email":    "must be a valid email address",
    }),
)

func validatePhone(fl validator.FieldLevel) bool {
    return phoneRegex.MatchString(fl.Field().String())
}

func validateUsername(fl validator.FieldLevel) bool {
    return usernameRegex.MatchString(fl.Field().String())
}

func validateStrongPassword(fl validator.FieldLevel) bool {
    password := fl.Field().String()
    
    if len(password) < 8 {
        return false
    }
    
    var hasUpper, hasLower, hasDigit, hasSpecial bool
    for _, c := range password {
        switch {
        case unicode.IsUpper(c):
            hasUpper = true
        case unicode.IsLower(c):
            hasLower = true
        case unicode.IsDigit(c):
            hasDigit = true
        case unicode.IsPunct(c) || unicode.IsSymbol(c):
            hasSpecial = true
        }
    }
    
    return hasUpper && hasLower && hasDigit && hasSpecial
}

func sensitiveFieldRedactor(path string) bool {
    pathLower := strings.ToLower(path)
    return strings.Contains(pathLower, "password") ||
           strings.Contains(pathLower, "token") ||
           strings.Contains(pathLower, "secret") ||
           strings.Contains(pathLower, "card") ||
           strings.Contains(pathLower, "cvv")
}
```

### Using Custom Tags

```go
type Registration struct {
    Username string `validate:"required,username"`
    Phone    string `validate:"required,phone"`
    Password string `validate:"required,strong_password"`
}

func Register(w http.ResponseWriter, r *http.Request) {
    var req Registration
    json.NewDecoder(r.Body).Decode(&req)
    
    if err := app.Validator.Validate(r.Context(), &req); err != nil {
        handleValidationError(w, err)
        return
    }
    
    // Process registration
}
```

## JSON Schema Validation

```go
type Product struct {
    Name        string  `json:"name"`
    Price       float64 `json:"price"`
    Category    string  `json:"category"`
    InStock     bool    `json:"in_stock"`
    Tags        []string `json:"tags"`
}

func (p Product) JSONSchema() (id, schema string) {
    return "product-v1", `{
        "$schema": "http://json-schema.org/draft-07/schema#",
        "type": "object",
        "properties": {
            "name": {
                "type": "string",
                "minLength": 1,
                "maxLength": 100
            },
            "price": {
                "type": "number",
                "minimum": 0,
                "exclusiveMinimum": true
            },
            "category": {
                "type": "string",
                "enum": ["electronics", "clothing", "books", "food"]
            },
            "in_stock": {
                "type": "boolean"
            },
            "tags": {
                "type": "array",
                "items": {"type": "string"},
                "minItems": 1,
                "maxItems": 10,
                "uniqueItems": true
            }
        },
        "required": ["name", "price", "category"],
        "additionalProperties": false
    }`
}

func CreateProduct(w http.ResponseWriter, r *http.Request) {
    var product Product
    json.NewDecoder(r.Body).Decode(&product)
    
    // Validates using JSON Schema
    if err := validation.Validate(r.Context(), &product); err != nil {
        handleValidationError(w, err)
        return
    }
    
    // Save product
}
```

## Multi-Strategy Validation

```go
type User struct {
    Email    string `json:"email" validate:"required,email"`
    Username string `json:"username" validate:"required,min=3,max=20"`
}

// Add JSON Schema
func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{
        "type": "object",
        "properties": {
            "email": {"type": "string", "format": "email"},
            "username": {"type": "string", "minLength": 3, "maxLength": 20}
        }
    }`
}

// Add custom validation
func (u *User) ValidateContext(ctx context.Context) error {
    // Check username uniqueness
    if usernameExists(ctx, u.Username) {
        return errors.New("username already taken")
    }
    return nil
}

// Run all strategies
err := validation.Validate(ctx, &user,
    validation.WithRunAll(true),
)
```

## Testing

### Testing Validation

```go
func TestUserValidation(t *testing.T) {
    tests := []struct {
        name    string
        user    CreateUserRequest
        wantErr bool
        errCode string
    }{
        {
            name: "valid user",
            user: CreateUserRequest{
                Username: "alice",
                Email:    "alice@example.com",
                Age:      25,
                Password: "SecurePass123!",
            },
            wantErr: false,
        },
        {
            name: "invalid email",
            user: CreateUserRequest{
                Username: "alice",
                Email:    "invalid",
                Age:      25,
                Password: "SecurePass123!",
            },
            wantErr: true,
            errCode: "tag.email",
        },
        {
            name: "underage",
            user: CreateUserRequest{
                Username: "alice",
                Email:    "alice@example.com",
                Age:      15,
                Password: "SecurePass123!",
            },
            wantErr: true,
            errCode: "tag.min",
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validator.Validate(context.Background(), &tt.user)
            
            if tt.wantErr {
                if err == nil {
                    t.Error("expected error, got nil")
                    return
                }
                
                var verr *validation.Error
                if !errors.As(err, &verr) {
                    t.Error("expected validation.Error")
                    return
                }
                
                if tt.errCode != "" && !verr.HasCode(tt.errCode) {
                    t.Errorf("expected error code %s", tt.errCode)
                }
            } else {
                if err != nil {
                    t.Errorf("unexpected error: %v", err)
                }
            }
        })
    }
}
```

### Testing Partial Validation

```go
func TestPartialValidation(t *testing.T) {
    tests := []struct {
        name    string
        json    string
        wantErr bool
    }{
        {
            name:    "valid email update",
            json:    `{"email": "new@example.com"}`,
            wantErr: false,
        },
        {
            name:    "invalid email update",
            json:    `{"email": "invalid"}`,
            wantErr: true,
        },
        {
            name:    "valid age update",
            json:    `{"age": 25}`,
            wantErr: false,
        },
        {
            name:    "underage update",
            json:    `{"age": 15}`,
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            presence, _ := validation.ComputePresence([]byte(tt.json))
            
            var req UpdateUserRequest
            json.Unmarshal([]byte(tt.json), &req)
            
            err := validation.ValidatePartial(context.Background(), &req, presence)
            
            if (err != nil) != tt.wantErr {
                t.Errorf("ValidatePartial() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

## Integration with rivaas/router

```go
import "rivaas.dev/router"

func Handler(c *router.Context) error {
    var req CreateUserRequest
    if err := c.BindJSON(&req); err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{
            "error": "invalid JSON",
        })
    }
    
    if err := validator.Validate(c.Request().Context(), &req); err != nil {
        var verr *validation.Error
        if errors.As(err, &verr) {
            return c.JSON(http.StatusUnprocessableEntity, map[string]any{
                "error":  "validation_failed",
                "fields": verr.Fields,
            })
        }
        return err
    }
    
    // Process request
    return c.JSON(http.StatusOK, createUser(req))
}
```

## Integration with rivaas/app

```go
import "rivaas.dev/app"

func Handler(c *app.Context) error {
    var req CreateUserRequest
    if err := c.Bind(&req); err != nil {
        return err // Automatically handled
    }
    
    // Validation happens automatically with app.Context
    // But you can also validate manually:
    if err := validator.Validate(c.Context(), &req); err != nil {
        return err // Automatically converted to proper HTTP response
    }
    
    return c.JSON(http.StatusOK, createUser(req))
}
```

## Performance Tips

### Reuse Validator Instances

```go
// Good - create once
var appValidator = validation.MustNew(
    validation.WithMaxErrors(10),
)

func Handler1(ctx context.Context, req Request1) error {
    return appValidator.Validate(ctx, &req)
}

func Handler2(ctx context.Context, req Request2) error {
    return appValidator.Validate(ctx, &req)
}

// Bad - create every time (slow)
func Handler(ctx context.Context, req Request) error {
    validator := validation.MustNew()
    return validator.Validate(ctx, &req)
}
```

### Use Package-Level Functions for Simple Cases

```go
// Simple validation - use package-level function
err := validation.Validate(ctx, &req)

// Complex validation - create validator instance
validator := validation.MustNew(
    validation.WithCustomTag("phone", validatePhone),
    validation.WithRedactor(redactor),
)
err := validator.Validate(ctx, &req)
```

## Next Steps

- [**Installation**](../installation/) - Set up the validation package
- [**Basic Usage**](../basic-usage/) - Learn validation fundamentals
- [**API Reference**](/reference/packages/validation/) - Complete API documentation
