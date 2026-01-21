---
title: "JSON Binding"
description: "Bind and parse JSON request bodies with automatic type conversion and validation"
weight: 5
keywords:
  - json binding
  - json parsing
  - request body
  - json deserialization
---

Learn how to bind JSON request bodies to Go structs with proper error handling, nested objects, and integration with validators.

## Basic JSON Binding

Bind JSON request bodies directly to structs:

```go
type CreateUserRequest struct {
    Username string `json:"username"`
    Email    string `json:"email"`
    Age      int    `json:"age"`
}

req, err := binding.JSON[CreateUserRequest](r.Body)
if err != nil {
    http.Error(w, err.Error(), http.StatusBadRequest)
    return
}

// Use req.Username, req.Email, req.Age
```

## JSON Tags

The binding package respects standard `json` tags:

```go
type Product struct {
    ID          int       `json:"id"`
    Name        string    `json:"name"`
    Price       float64   `json:"price"`
    CreatedAt   time.Time `json:"created_at"`
    
    // Omit if empty
    Description string    `json:"description,omitempty"`
    
    // Ignore this field
    Internal    string    `json:"-"`
}
```

## Nested Structures

Handle complex nested JSON:

```go
type Order struct {
    ID       string    `json:"id"`
    Customer struct {
        Name    string `json:"name"`
        Email   string `json:"email"`
        Address struct {
            Street  string `json:"street"`
            City    string `json:"city"`
            Country string `json:"country"`
            ZipCode string `json:"zip_code"`
        } `json:"address"`
    } `json:"customer"`
    Items []struct {
        ProductID string  `json:"product_id"`
        Quantity  int     `json:"quantity"`
        Price     float64 `json:"price"`
    } `json:"items"`
    Total float64 `json:"total"`
}

// POST /orders
// {
//   "id": "ORD-12345",
//   "customer": {
//     "name": "John Doe",
//     "email": "john@example.com",
//     "address": {
//       "street": "123 Main St",
//       "city": "New York",
//       "country": "USA",
//       "zip_code": "10001"
//     }
//   },
//   "items": [
//     {"product_id": "PROD-1", "quantity": 2, "price": 29.99}
//   ],
//   "total": 59.98
// }

order, err := binding.JSON[Order](r.Body)
```

## Type Support

JSON binding supports rich type conversion:

```go
type ComplexTypes struct {
    // Basic types
    String  string  `json:"string"`
    Int     int     `json:"int"`
    Float   float64 `json:"float"`
    Bool    bool    `json:"bool"`
    
    // Time types
    Timestamp time.Time     `json:"timestamp"`
    Duration  time.Duration `json:"duration"`
    
    // Slices
    Tags      []string `json:"tags"`
    Numbers   []int    `json:"numbers"`
    
    // Maps
    Metadata  map[string]string      `json:"metadata"`
    Settings  map[string]interface{} `json:"settings"`
    
    // Pointers (nullable)
    Optional  *string `json:"optional"`
    Nullable  *int    `json:"nullable"`
}

// Example JSON:
// {
//   "string": "hello",
//   "int": 42,
//   "float": 3.14,
//   "bool": true,
//   "timestamp": "2025-01-01T00:00:00Z",
//   "duration": "30s",
//   "tags": ["go", "rust"],
//   "numbers": [1, 2, 3],
//   "metadata": {"key": "value"},
//   "optional": null,
//   "nullable": 10
// }
```

## Reading Limits

Protect against large payloads with `WithMaxBytes`:

```go
// Limit to 1MB
req, err := binding.JSON[CreateUserRequest](
    r.Body,
    binding.WithMaxBytes(1024 * 1024),
)
if err != nil {
    http.Error(w, "Request too large", http.StatusRequestEntityTooLarge)
    return
}
```

## Strict JSON Parsing

Reject unknown fields with `WithDisallowUnknownFields`:

```go
type StrictRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
}

// This will error if JSON contains fields not in the struct
req, err := binding.JSON[StrictRequest](
    r.Body,
    binding.WithDisallowUnknownFields(),
)
```

## Optional Fields

Use pointers to distinguish between "not provided" and "zero value":

```go
type UpdateUserRequest struct {
    Username *string `json:"username,omitempty"`
    Email    *string `json:"email,omitempty"`
    Age      *int    `json:"age,omitempty"`
}

// JSON: {"email": "new@example.com"}
req, err := binding.JSON[UpdateUserRequest](r.Body)
// Result: {Username: nil, Email: &"new@example.com", Age: nil}

if req.Email != nil {
    // Update email to *req.Email
}
```

## Array Bodies

Bind arrays directly:

```go
type BatchRequest []struct {
    ID   string `json:"id"`
    Name string `json:"name"`
}

// JSON: [{"id": "1", "name": "A"}, {"id": "2", "name": "B"}]
batch, err := binding.JSON[BatchRequest](r.Body)
```

## Complete HTTP Handler Example

```go
func CreateProductHandler(w http.ResponseWriter, r *http.Request) {
    type CreateProductRequest struct {
        Name        string   `json:"name"`
        Description string   `json:"description"`
        Price       float64  `json:"price"`
        Categories  []string `json:"categories"`
        Stock       int      `json:"stock"`
    }
    
    // 1. Bind JSON
    req, err := binding.JSON[CreateProductRequest](
        r.Body,
        binding.WithMaxBytes(1024*1024),
        binding.WithDisallowUnknownFields(),
    )
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // 2. Validate (using rivaas.dev/validation)
    if err := validation.Validate(req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // 3. Business logic
    product := createProduct(req)
    
    // 4. Response
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(product)
}
```

## Error Handling

The binding package provides detailed error information:

```go
req, err := binding.JSON[CreateUserRequest](r.Body)
if err != nil {
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        // Field-specific error
        log.Printf("Failed to bind field %s: %v", bindErr.Field, bindErr.Err)
        http.Error(w, 
            fmt.Sprintf("Invalid field: %s", bindErr.Field),
            http.StatusBadRequest)
        return
    }
    
    // Generic error (malformed JSON, etc.)
    http.Error(w, "Invalid JSON", http.StatusBadRequest)
    return
}
```

## Common Error Types

```go
// Syntax errors
// {"name": "test"  <- missing closing brace
// Error: "unexpected end of JSON input"

// Type mismatch
// {"age": "not a number"}  <- age is int
// Error: "cannot unmarshal string into field age of type int"

// Unknown fields (with WithDisallowUnknownFields)
// {"name": "test", "unknown": "value"}
// Error: "json: unknown field \"unknown\""

// Request too large (with WithMaxBytes)
// Payload > limit
// Error: "http: request body too large"
```

## Integration with Validation

Combine with `rivaas.dev/validation` for comprehensive validation:

```go
import (
    "rivaas.dev/binding"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Username string `json:"username" validate:"required,min=3,max=32"`
    Email    string `json:"email" validate:"required,email"`
    Age      int    `json:"age" validate:"required,min=18,max=120"`
}

func CreateUserHandler(w http.ResponseWriter, r *http.Request) {
    // Step 1: Bind JSON structure
    req, err := binding.JSON[CreateUserRequest](r.Body)
    if err != nil {
        http.Error(w, "Invalid JSON", http.StatusBadRequest)
        return
    }
    
    // Step 2: Validate business rules
    if err := validation.Validate(req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Proceed with valid data
    createUser(req)
}
```

## Custom JSON Parsing

For special cases, implement `json.Unmarshaler`:

```go
type Duration time.Duration

func (d *Duration) UnmarshalJSON(b []byte) error {
    var s string
    if err := json.Unmarshal(b, &s); err != nil {
        return err
    }
    
    parsed, err := time.ParseDuration(s)
    if err != nil {
        return err
    }
    
    *d = Duration(parsed)
    return nil
}

type Config struct {
    Timeout Duration `json:"timeout"`
}

// JSON: {"timeout": "30s"}
cfg, err := binding.JSON[Config](r.Body)
```

## Handling Multiple Content Types

Use `binding.Auto()` to handle both JSON and form data:

```go
// Works with both:
// Content-Type: application/json
// Content-Type: application/x-www-form-urlencoded

req, err := binding.Auto[CreateUserRequest](r)
if err != nil {
    http.Error(w, err.Error(), http.StatusBadRequest)
    return
}
```

## Performance Considerations

1. **Use io.LimitReader**: Always set max bytes for untrusted input
2. **Avoid reflection**: Type info is cached automatically
3. **Reuse structs**: Define request types once
4. **Pointer fields**: Only when you need to distinguish nil from zero

## Best Practices

### 1. Separate Request/Response Types

```go
// Request
type CreateUserRequest struct {
    Username string `json:"username"`
    Email    string `json:"email"`
}

// Response
type CreateUserResponse struct {
    ID       string `json:"id"`
    Username string `json:"username"`
    Email    string `json:"email"`
    Created  time.Time `json:"created"`
}
```

### 2. Use Validation Tags

```go
type CreateUserRequest struct {
    Username string `json:"username" validate:"required,alphanum,min=3,max=32"`
    Email    string `json:"email" validate:"required,email"`
}
```

### 3. Document with Examples

```go
// CreateUserRequest represents a new user creation request.
//
// Example JSON:
//
//	{
//	  "username": "johndoe",
//	  "email": "john@example.com",
//	  "age": 30
//	}
type CreateUserRequest struct {
    Username string `json:"username"`
    Email    string `json:"email"`
    Age      int    `json:"age"`
}
```

### 4. Set Limits

```go
const maxRequestSize = 1024 * 1024 // 1MB

req, err := binding.JSON[CreateUserRequest](
    r.Body,
    binding.WithMaxBytes(maxRequestSize),
)
```

## Testing

```go
func TestCreateUserHandler(t *testing.T) {
    payload := `{"username": "test", "email": "test@example.com", "age": 25}`
    
    req := httptest.NewRequest("POST", "/users", strings.NewReader(payload))
    req.Header.Set("Content-Type", "application/json")
    
    rec := httptest.NewRecorder()
    CreateUserHandler(rec, req)
    
    if rec.Code != http.StatusCreated {
        t.Errorf("expected status 201, got %d", rec.Code)
    }
}
```

## Next Steps

- Learn about [Multi-Source](../multi-source/) binding
- Explore [Error Handling](../error-handling/) strategies
- See [Advanced Usage](../advanced-usage/) for custom binders
- Review [Examples](../examples/) for complete applications

For complete API details, see [API Reference](/reference/packages/binding/api-reference/).
