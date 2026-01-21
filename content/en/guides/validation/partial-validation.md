---
title: "Partial Validation"
description: "Validate only provided fields in PATCH requests"
weight: 6
keywords:
  - partial validation
  - selective validation
  - field groups
  - patch validation
---

Partial validation is essential for PATCH requests. Only provided fields should be validated. Absent fields are ignored even if they have "required" constraints.

## The Problem

Consider a user update endpoint:

```go
type UpdateUserRequest struct {
    Email string `validate:"required,email"`
    Name  string `validate:"required,min=2"`
    Age   int    `validate:"min=18"`
}
```

With normal validation, a PATCH request like `{"email": "new@example.com"}` would fail. The `name` field is required but not provided. Partial validation solves this.

## PresenceMap

A `PresenceMap` tracks which fields are present in the request:

```go
type PresenceMap map[string]bool
```

Keys are JSON field paths (e.g., `"email"`, `"address.city"`, `"items.0.name"`).

## Computing Presence

Use `ComputePresence` to analyze raw JSON:

```go
rawJSON := []byte(`{"email": "new@example.com"}`)

presence, err := validation.ComputePresence(rawJSON)
if err != nil {
    return fmt.Errorf("failed to compute presence: %w", err)
}

// presence = {"email": true}
```

## ValidatePartial

Use `ValidatePartial` to validate only present fields:

```go
func UpdateUserHandler(w http.ResponseWriter, r *http.Request) {
    // Read raw body
    rawJSON, _ := io.ReadAll(r.Body)
    
    // Compute presence
    presence, _ := validation.ComputePresence(rawJSON)
    
    // Parse into struct
    var req UpdateUserRequest
    json.Unmarshal(rawJSON, &req)
    
    // Validate only present fields
    err := validation.ValidatePartial(ctx, &req, presence)
    if err != nil {
        // Handle validation error
    }
}
```

## Complete PATCH Example

```go
type UpdateUserRequest struct {
    Email *string `json:"email" validate:"omitempty,email"`
    Name  *string `json:"name" validate:"omitempty,min=2"`
    Age   *int    `json:"age" validate:"omitempty,min=18"`
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
        var verr *validation.Error
        if errors.As(err, &verr) {
            // Return field errors
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusUnprocessableEntity)
            json.NewEncoder(w).Encode(verr)
            return
        }
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Update user with provided fields
    updateUser(ctx, req)
    
    w.WriteHeader(http.StatusOK)
}
```

## Nested Structures

Presence tracking works with nested objects and arrays:

```go
type UpdateOrderRequest struct {
    Status string  `json:"status"`
    Items  []Item  `json:"items"`
    Address Address `json:"address"`
}

type Item struct {
    ProductID int `json:"product_id"`
    Quantity  int `json:"quantity"`
}

type Address struct {
    Street string `json:"street"`
    City   string `json:"city"`
    Zip    string `json:"zip"`
}

rawJSON := []byte(`{
    "status": "confirmed",
    "items": [
        {"product_id": 123, "quantity": 2}
    ],
    "address": {
        "city": "San Francisco"
    }
}`)

presence, _ := validation.ComputePresence(rawJSON)
// presence = {
//     "status": true,
//     "items": true,
//     "items.0": true,
//     "items.0.product_id": true,
//     "items.0.quantity": true,
//     "address": true,
//     "address.city": true,
// }
```

Only `address.city` was provided, so `address.street` and `address.zip` won't be validated.

## Using WithPresence Option

You can also use the `WithPresence` option directly:

```go
presence, _ := validation.ComputePresence(rawJSON)

err := validation.Validate(ctx, &req,
    validation.WithPartial(true),
    validation.WithPresence(presence),
)
```

## PresenceMap Methods

### Has

Check if an exact path is present:

```go
if presence.Has("email") {
    // Email field was provided
}
```

### HasPrefix

Check if any nested path exists:

```go
if presence.HasPrefix("address") {
    // At least one address field was provided
    // (e.g., "address.city" or "address.street")
}
```

### LeafPaths

Get only the deepest paths (no parent paths):

```go
presence := PresenceMap{
    "address": true,
    "address.city": true,
    "address.street": true,
}

leaves := presence.LeafPaths()
// returns: ["address.city", "address.street"]
// "address" is excluded (it has children)
```

Useful for validating only actual data fields, not parent objects.

## Pointer Fields for PATCH

Use pointers to distinguish between "not provided" and "zero value":

```go
type UpdateUserRequest struct {
    Email *string `json:"email"`
    Age   *int    `json:"age"`
    Active *bool  `json:"active"`
}

// Email: not provided
// Age: 0
// Active: false
rawJSON := []byte(`{"age": 0, "active": false}`)
```

With presence tracking:
- `email` not in presence map → skip validation
- `age` and `active` in presence map → validate even though they're zero values

## Struct Tag Strategy

For partial validation with struct tags, use `omitempty` instead of `required`:

```go
// Good for PATCH
type UpdateUserRequest struct {
    Email string `json:"email" validate:"omitempty,email"`
    Age   int    `json:"age" validate:"omitempty,min=18"`
}

// Bad for PATCH
type UpdateUserRequest struct {
    Email string `json:"email" validate:"required,email"` // Will fail if not provided
    Age   int    `json:"age" validate:"required,min=18"`  // Will fail if not provided
}
```

## Custom Interface with Partial Validation

Access the presence map in custom validation:

```go
type UpdateOrderRequest struct {
    Items []OrderItem
}

func (r *UpdateOrderRequest) ValidateContext(ctx context.Context) error {
    // Get presence from context (if available)
    presence := ctx.Value("presence").(validation.PresenceMap)
    
    // Only validate items if provided
    if presence.HasPrefix("items") {
        if len(r.Items) == 0 {
            return errors.New("items cannot be empty when provided")
        }
    }
    
    return nil
}

// Pass presence via context
ctx = context.WithValue(ctx, "presence", presence)
err := validation.ValidatePartial(ctx, &req, presence)
```

## Performance Considerations

- `ComputePresence` parses JSON once (fast)
- Presence map is cached per request
- No reflection overhead for presence checks
- Memory usage: ~100 bytes per field path

## Limitations

### Deep Nesting

`ComputePresence` has a maximum nesting depth of 100 to prevent stack overflow:

```go
// This will stop at depth 100
deeplyNested := generateDeeplyNestedJSON(150)
presence, _ := validation.ComputePresence(deeplyNested)
// Only tracks first 100 levels
```

### Maximum Fields

For security, limit the number of fields in partial validation:

```go
validator := validation.MustNew(
    validation.WithMaxFields(5000), // Default: 10000
)
```

## Testing Partial Validation

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
            name:    "empty body",
            json:    `{}`,
            wantErr: false, // No fields to validate
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

## Best Practices

### 1. Always Use Pointers for Optional Fields

```go
// Good
type UpdateUserRequest struct {
    Email *string `json:"email" validate:"omitempty,email"`
    Age   *int    `json:"age" validate:"omitempty,min=18"`
}

// Bad - can't distinguish between "not provided" and "zero value"
type UpdateUserRequest struct {
    Email string `json:"email" validate:"omitempty,email"`
    Age   int    `json:"age" validate:"omitempty,min=18"`
}
```

### 2. Compute Presence Once

```go
// Good
presence, _ := validation.ComputePresence(rawJSON)
err1 := validation.ValidatePartial(ctx, &req1, presence)
err2 := validation.ValidatePartial(ctx, &req2, presence)

// Bad - recomputes presence
validation.ValidatePartial(ctx, &req1, computePresence(rawJSON))
validation.ValidatePartial(ctx, &req2, computePresence(rawJSON))
```

### 3. Handle Empty Bodies

```go
rawJSON, _ := io.ReadAll(r.Body)

if len(rawJSON) == 0 {
    http.Error(w, "empty body", http.StatusBadRequest)
    return
}

presence, _ := validation.ComputePresence(rawJSON)
```

### 4. Use omitempty Instead of required

```go
// Good for PATCH
validate:"omitempty,email"

// Bad for PATCH
validate:"required,email"
```

## Next Steps

- [**Error Handling**](../error-handling/) - Handle validation errors
- [**Custom Validators**](../custom-validators/) - Custom validation logic
- [**API Reference**](/reference/packages/validation/api-reference/) - PresenceMap API details
