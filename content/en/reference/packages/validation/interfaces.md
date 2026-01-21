---
title: "Interfaces"
description: "Custom validation interfaces"
keywords:
  - validation interfaces
  - validator interface
  - validatable
  - custom validation
weight: 3
---

Complete reference for validation interfaces that can be implemented for custom validation logic.

## ValidatorInterface

```go
type ValidatorInterface interface {
    Validate() error
}
```

Implement this interface for simple custom validation without context.

### When to Use

- Simple validation rules that don't need external data
- Business logic validation
- Cross-field validation within the struct

### Implementation

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
        return errors.New("name must be at least 2 characters")
    }
    return nil
}
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

### Pointer vs Value Receivers

Both are supported:

```go
// Pointer receiver (can modify struct)
func (u *User) Validate() error {
    u.Email = strings.ToLower(u.Email) // Normalize
    return validateEmail(u.Email)
}

// Value receiver (read-only)
func (u User) Validate() error {
    return validateEmail(u.Email)
}
```

Use pointer receivers when you need to modify the struct during validation (normalization, etc.).

## ValidatorWithContext

```go
type ValidatorWithContext interface {
    ValidateContext(context.Context) error
}
```

Implement this interface for context-aware validation that needs access to request-scoped data or external services.

### When to Use

- Database lookups (uniqueness checks, existence validation)
- Tenant-specific validation rules
- Rate limiting or quota checks
- External service calls
- Request-scoped data access

### Implementation

```go
type User struct {
    Username string
    Email    string
    TenantID string
}

func (u *User) ValidateContext(ctx context.Context) error {
    // Get services from context
    db := ctx.Value("db").(*sql.DB)
    tenant := ctx.Value("tenant").(string)
    
    // Tenant validation
    if u.TenantID != tenant {
        return errors.New("user does not belong to this tenant")
    }
    
    // Database validation
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

### Context Values

Access data from context:

```go
func (u *User) ValidateContext(ctx context.Context) error {
    // Database connection
    db := ctx.Value("db").(*sql.DB)
    
    // Current user/tenant
    currentUser := ctx.Value("user_id").(string)
    tenant := ctx.Value("tenant").(string)
    
    // Request metadata
    requestID := ctx.Value("request_id").(string)
    
    // Use in validation logic
    return validateWithContext(db, u, tenant)
}
```

### Cancellation Support

Respect context cancellation for long-running validations:

```go
func (u *User) ValidateContext(ctx context.Context) error {
    // Check cancellation before expensive operation
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
    }
    
    // Expensive validation
    return checkUsernameUniqueness(ctx, u.Username)
}
```

## JSONSchemaProvider

```go
type JSONSchemaProvider interface {
    JSONSchema() (id, schema string)
}
```

Implement this interface to provide a JSON Schema for validation.

### When to Use

- Portable validation rules (shared with frontend/documentation)
- Complex validation logic without code
- RFC-compliant validation
- Schema versioning

### Implementation

```go
type Product struct {
    Name     string  `json:"name"`
    Price    float64 `json:"price"`
    Category string  `json:"category"`
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
                "enum": ["electronics", "clothing", "books"]
            }
        },
        "required": ["name", "price", "category"],
        "additionalProperties": false
    }`
}
```

### Schema ID

The ID is used for caching:

```go
func (p Product) JSONSchema() (id, schema string) {
    return "product-v1", schemaString
    //     ^^^^^^^^^^^ Used as cache key
}
```

Use versioned IDs (e.g., `"product-v1"`, `"product-v2"`) to invalidate cache when schema changes.

### Schema Formats

Supported formats:

- `email` - Email address
- `uri` / `url` - URL
- `hostname` - DNS hostname
- `ipv4` / `ipv6` - IP addresses
- `date` - Date (YYYY-MM-DD)
- `date-time` - RFC3339 date-time
- `uuid` - UUID

### Embedded Schemas

For complex schemas, consider embedding:

```go
import _ "embed"

//go:embed user_schema.json
var userSchemaJSON string

func (u User) JSONSchema() (id, schema string) {
    return "user-v1", userSchemaJSON
}
```

## Redactor

```go
type Redactor func(path string) bool
```

Function that determines if a field should be redacted in error messages.

### When to Use

- Protecting passwords, tokens, secrets
- Hiding credit card numbers, SSNs
- Redacting PII (personally identifiable information)
- Compliance requirements (GDPR, PCI-DSS)

### Implementation

```go
func sensitiveFieldRedactor(path string) bool {
    pathLower := strings.ToLower(path)
    
    // Password fields
    if strings.Contains(pathLower, "password") {
        return true
    }
    
    // Tokens and secrets
    if strings.Contains(pathLower, "token") ||
       strings.Contains(pathLower, "secret") ||
       strings.Contains(pathLower, "key") {
        return true
    }
    
    // Payment information
    if strings.Contains(pathLower, "card") ||
       strings.Contains(pathLower, "cvv") ||
       strings.Contains(pathLower, "credit") {
        return true
    }
    
    return false
}

validator := validation.MustNew(
    validation.WithRedactor(sensitiveFieldRedactor),
)
```

### Path-Based Redaction

Redact specific paths:

```go
func pathRedactor(path string) bool {
    redactedPaths := map[string]bool{
        "user.password":          true,
        "payment.card_number":    true,
        "payment.cvv":            true,
        "auth.refresh_token":     true,
    }
    return redactedPaths[path]
}
```

### Nested Field Redaction

```go
func nestedRedactor(path string) bool {
    // Redact all fields under payment.*
    if strings.HasPrefix(path, "payment.") {
        return true
    }
    
    // Redact specific nested field
    if strings.HasPrefix(path, "user.credentials.") {
        return true
    }
    
    return false
}
```

## Interface Priority

When multiple interfaces are implemented, they have different priorities:

**Priority Order:**
1. `ValidatorWithContext` / `ValidatorInterface` (highest)
2. Struct tags (`validate:"..."`)
3. `JSONSchemaProvider` (lowest)

```go
type User struct {
    Email string `validate:"required,email"` // Priority 2
}

func (u User) JSONSchema() (id, schema string) {
    // Priority 3 (lowest)
    return "user-v1", `{...}`
}

func (u *User) Validate() error {
    // Priority 1 (highest) - this runs instead of tags/schema
    return customValidation(u.Email)
}
```

Override priority with explicit strategy:

```go
// Skip Validate() method, use tags
err := validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyTags),
)
```

## Combining Interfaces

Run all strategies with `WithRunAll`:

```go
type User struct {
    Email string `validate:"required,email"` // Struct tags
}

func (u User) JSONSchema() (id, schema string) {
    // JSON Schema
    return "user-v1", `{...}`
}

func (u *User) Validate() error {
    // Interface method
    return businessLogic(u)
}

// Run all three strategies
err := validation.Validate(ctx, &user,
    validation.WithRunAll(true),
)
```

## Best Practices

### 1. Choose the Right Interface

```go
// Simple validation - ValidatorInterface
func (u *User) Validate() error {
    return validateEmail(u.Email)
}

// Needs external data - ValidatorWithContext
func (u *User) ValidateContext(ctx context.Context) error {
    db := ctx.Value("db").(*sql.DB)
    return checkUniqueness(ctx, db, u.Email)
}
```

### 2. Return Structured Errors

```go
// Good
func (u *User) Validate() error {
    var verr validation.Error
    verr.Add("email", "invalid", "must be valid email", nil)
    return &verr
}

// Bad
func (u *User) Validate() error {
    return errors.New("email invalid")
}
```

### 3. Use Context Safely

```go
func (u *User) ValidateContext(ctx context.Context) error {
    db, ok := ctx.Value("db").(*sql.DB)
    if !ok {
        return errors.New("database not available in context")
    }
    return validateWithDB(ctx, db, u)
}
```

### 4. Document Custom Validation

```go
// ValidateContext validates the user against business rules:
// - Username must be unique within tenant
// - Email domain must be allowed for tenant
// - User must not exceed account limits
func (u *User) ValidateContext(ctx context.Context) error {
    // Implementation
}
```

## Testing

### Testing ValidatorInterface

```go
func TestUserValidation(t *testing.T) {
    tests := []struct {
        name    string
        user    User
        wantErr bool
    }{
        {"valid", User{Email: "test@example.com"}, false},
        {"invalid", User{Email: "invalid"}, true},
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

### Testing ValidatorWithContext

```go
func TestUserValidationWithContext(t *testing.T) {
    ctx := context.Background()
    ctx = context.WithValue(ctx, "db", mockDB)
    ctx = context.WithValue(ctx, "tenant", "test-tenant")
    
    user := User{Username: "testuser"}
    err := user.ValidateContext(ctx)
    
    if err != nil {
        t.Errorf("ValidateContext() error = %v", err)
    }
}
```

## Next Steps

- [**API Reference**](../api-reference/) - Core types and functions
- [**Options**](../options/) - Configuration options
- [**Custom Interfaces Guide**](/guides/validation/custom-interfaces/) - Detailed usage guide
- [**Examples**](/guides/validation/examples/) - Real-world examples
