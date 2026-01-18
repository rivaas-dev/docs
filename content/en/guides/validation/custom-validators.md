---
title: "Custom Validators"
description: "Register custom validation tags and functions"
weight: 8
---

Extend the validation package with custom validation tags and functions to handle domain-specific validation rules.

## Custom Validation Tags

Register custom tags for use in struct tags with `WithCustomTag`:

```go
import (
    "github.com/go-playground/validator/v10"
    "rivaas.dev/validation"
)

validator := validation.MustNew(
    validation.WithCustomTag("phone", func(fl validator.FieldLevel) bool {
        return phoneRegex.MatchString(fl.Field().String())
    }),
)

type User struct {
    Phone string `validate:"phone"`
}
```

## FieldLevel Interface

Custom tag functions receive a `validator.FieldLevel` with methods to access field information:

```go
type FieldLevel interface {
    Field() reflect.Value         // The field being validated
    FieldName() string             // Field name
    StructFieldName() string       // Struct field name
    Param() string                 // Tag parameter
    GetStructFieldOK() (reflect.Value, reflect.Kind, bool)
    Parent() reflect.Value         // Parent struct
}
```

## Simple Custom Tags

### Phone Number Validation

```go
import "regexp"

var phoneRegex = regexp.MustCompile(`^\+?[1-9]\d{1,14}$`)

validator := validation.MustNew(
    validation.WithCustomTag("phone", func(fl validator.FieldLevel) bool {
        return phoneRegex.MatchString(fl.Field().String())
    }),
)

type Contact struct {
    Phone string `validate:"required,phone"`
}
```

### Username Validation

```go
var usernameRegex = regexp.MustCompile(`^[a-zA-Z0-9_]{3,20}$`)

validator := validation.MustNew(
    validation.WithCustomTag("username", func(fl validator.FieldLevel) bool {
        username := fl.Field().String()
        return usernameRegex.MatchString(username)
    }),
)

type User struct {
    Username string `validate:"required,username"`
}
```

### Slug Validation

```go
var slugRegex = regexp.MustCompile(`^[a-z0-9-]+$`)

validator := validation.MustNew(
    validation.WithCustomTag("slug", func(fl validator.FieldLevel) bool {
        return slugRegex.MatchString(fl.Field().String())
    }),
)

type Article struct {
    Slug string `validate:"required,slug"`
}
```

## Advanced Custom Tags

### Password Strength

```go
import "unicode"

func strongPassword(fl validator.FieldLevel) bool {
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

validator := validation.MustNew(
    validation.WithCustomTag("strong_password", strongPassword),
)

type Registration struct {
    Password string `validate:"required,strong_password"`
}
```

### Parameterized Tags

```go
// Custom tag with parameter: divisible_by=N
func divisibleBy(fl validator.FieldLevel) bool {
    param := fl.Param() // Get parameter value
    divisor, err := strconv.Atoi(param)
    if err != nil {
        return false
    }
    
    value := fl.Field().Int()
    return value%int64(divisor) == 0
}

validator := validation.MustNew(
    validation.WithCustomTag("divisible_by", divisibleBy),
)

type Product struct {
    Quantity int `validate:"required,divisible_by=5"`
}
```

### Cross-Field Validation

```go
// Validate that EndDate is after StartDate
func afterStartDate(fl validator.FieldLevel) bool {
    endDate := fl.Field().Interface().(time.Time)
    
    // Access parent struct
    parent := fl.Parent()
    startDateField := parent.FieldByName("StartDate")
    if !startDateField.IsValid() {
        return false
    }
    
    startDate := startDateField.Interface().(time.Time)
    return endDate.After(startDate)
}

validator := validation.MustNew(
    validation.WithCustomTag("after_start_date", afterStartDate),
)

type Event struct {
    StartDate time.Time `validate:"required"`
    EndDate   time.Time `validate:"required,after_start_date"`
}
```

## Multiple Custom Tags

Register multiple tags at once:

```go
validator := validation.MustNew(
    validation.WithCustomTag("phone", validatePhone),
    validation.WithCustomTag("username", validateUsername),
    validation.WithCustomTag("slug", validateSlug),
    validation.WithCustomTag("strong_password", validateStrongPassword),
)
```

## Custom Validator Functions

Use `WithCustomValidator` for one-off validation logic:

```go
type CreateOrderRequest struct {
    Items []OrderItem
    Total float64
}

err := validator.Validate(ctx, &req,
    validation.WithCustomValidator(func(v any) error {
        req := v.(*CreateOrderRequest)
        
        // Calculate expected total
        var sum float64
        for _, item := range req.Items {
            sum += item.Price * float64(item.Quantity)
        }
        
        // Verify total matches
        if math.Abs(req.Total-sum) > 0.01 {
            return errors.New("total does not match item prices")
        }
        
        return nil
    }),
)
```

### Type Assertion

```go
validation.WithCustomValidator(func(v any) error {
    req, ok := v.(*CreateUserRequest)
    if !ok {
        return errors.New("unexpected type")
    }
    
    // Validate req
    return nil
})
```

### Returning Structured Errors

```go
validation.WithCustomValidator(func(v any) error {
    req := v.(*CreateUserRequest)
    
    var verr validation.Error
    
    if isBlacklisted(req.Email) {
        verr.Add("email", "blacklisted", "email domain is blacklisted", nil)
    }
    
    if !isUnique(req.Username) {
        verr.Add("username", "duplicate", "username already taken", nil)
    }
    
    if verr.HasErrors() {
        return &verr
    }
    return nil
})
```

## Field Name Mapping

Transform field names in error messages:

```go
validator := validation.MustNew(
    validation.WithFieldNameMapper(func(name string) string {
        // Convert snake_case to Title Case
        return strings.Title(strings.ReplaceAll(name, "_", " "))
    }),
)

type User struct {
    FirstName string `json:"first_name" validate:"required"`
}

// Error message will say "First Name is required" instead of "first_name is required"
```

## Custom Error Messages

### Static Messages

```go
validator := validation.MustNew(
    validation.WithMessages(map[string]string{
        "required": "cannot be empty",
        "email":    "invalid email format",
        "min":      "value too small",
    }),
)
```

### Dynamic Messages

```go
import "reflect"

validator := validation.MustNew(
    validation.WithMessageFunc("min", func(param string, kind reflect.Kind) string {
        if kind == reflect.String {
            return fmt.Sprintf("must be at least %s characters long", param)
        }
        return fmt.Sprintf("must be at least %s", param)
    }),
    validation.WithMessageFunc("max", func(param string, kind reflect.Kind) string {
        if kind == reflect.String {
            return fmt.Sprintf("must be at most %s characters long", param)
        }
        return fmt.Sprintf("must be at most %s", param)
    }),
)
```

## Combining Custom Validators

Mix custom tags, custom validators, and built-in validation:

```go
type CreateUserRequest struct {
    Username string `validate:"required,username"` // Custom tag
    Email    string `validate:"required,email"`    // Built-in tag
    Age      int    `validate:"required,min=18"`   // Built-in tag
}

validator := validation.MustNew(
    validation.WithCustomTag("username", validateUsername),
)

err := validator.Validate(ctx, &req,
    validation.WithCustomValidator(func(v any) error {
        req := v.(*CreateUserRequest)
        // Additional custom validation
        if isBlacklisted(req.Email) {
            return errors.New("email is blacklisted")
        }
        return nil
    }),
    validation.WithRunAll(true), // Run all strategies
)
```

## Testing Custom Validators

### Testing Custom Tags

```go
func TestPhoneValidation(t *testing.T) {
    validator := validation.MustNew(
        validation.WithCustomTag("phone", validatePhone),
    )
    
    tests := []struct {
        name    string
        phone   string
        wantErr bool
    }{
        {"valid US", "+12345678900", false},
        {"valid international", "+441234567890", false},
        {"invalid format", "123", true},
        {"invalid prefix", "0123456789", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            type Test struct {
                Phone string `validate:"phone"`
            }
            
            test := Test{Phone: tt.phone}
            err := validator.Validate(context.Background(), &test)
            
            if (err != nil) != tt.wantErr {
                t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### Testing Custom Validator Functions

```go
func TestCustomValidator(t *testing.T) {
    customValidator := func(v any) error {
        req := v.(*CreateOrderRequest)
        var sum float64
        for _, item := range req.Items {
            sum += item.Price * float64(item.Quantity)
        }
        if math.Abs(req.Total-sum) > 0.01 {
            return errors.New("total mismatch")
        }
        return nil
    }
    
    tests := []struct {
        name    string
        req     CreateOrderRequest
        wantErr bool
    }{
        {
            name: "valid total",
            req: CreateOrderRequest{
                Items: []OrderItem{{Price: 10.0, Quantity: 2}},
                Total: 20.0,
            },
            wantErr: false,
        },
        {
            name: "invalid total",
            req: CreateOrderRequest{
                Items: []OrderItem{{Price: 10.0, Quantity: 2}},
                Total: 25.0,
            },
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validation.Validate(context.Background(), &tt.req,
                validation.WithCustomValidator(customValidator),
            )
            
            if (err != nil) != tt.wantErr {
                t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

## Best Practices

### 1. Name Tags Clearly

```go
// Good
validation.WithCustomTag("phone", validatePhone)
validation.WithCustomTag("strong_password", validateStrongPassword)

// Bad
validation.WithCustomTag("p", validatePhone)
validation.WithCustomTag("pass", validateStrongPassword)
```

### 2. Document Custom Tags

```go
// validatePhone validates phone numbers in E.164 format.
// Examples: +12345678900, +441234567890
func validatePhone(fl validator.FieldLevel) bool {
    return phoneRegex.MatchString(fl.Field().String())
}
```

### 3. Handle Edge Cases

```go
func validateUsername(fl validator.FieldLevel) bool {
    username := fl.Field().String()
    
    // Handle empty strings
    if username == "" {
        return false // Or true if username is optional
    }
    
    // Check length
    if len(username) < 3 || len(username) > 20 {
        return false
    }
    
    // Check format
    return usernameRegex.MatchString(username)
}
```

### 4. Use Validator Instance for Shared Tags

```go
// Create validator once with custom tags
var appValidator = validation.MustNew(
    validation.WithCustomTag("phone", validatePhone),
    validation.WithCustomTag("username", validateUsername),
    validation.WithCustomTag("slug", validateSlug),
)

// Reuse across handlers
func Handler1(ctx context.Context, req Request1) error {
    return appValidator.Validate(ctx, &req)
}

func Handler2(ctx context.Context, req Request2) error {
    return appValidator.Validate(ctx, &req)
}
```

## Next Steps

- [**Security**](../security/) - Protect sensitive data in validation
- [**Examples**](../examples/) - Real-world usage examples
- [**Options Reference**](/reference/packages/validation/options/) - Complete options documentation
- [**go-playground/validator**](https://pkg.go.dev/github.com/go-playground/validator/v10) - Underlying validator docs
