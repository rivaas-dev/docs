---
title: "Troubleshooting"
description: "Common issues and solutions"
keywords:
  - openapi troubleshooting
  - common issues
  - debugging
  - faq
weight: 6
---

Common issues and solutions for the openapi package.

## Schema Name Collisions

### Problem

Types with the same name in different packages may collide in the generated specification.

### Solution

The package automatically uses `pkgname.TypeName` format for schema names:

```go
// In package "api"
type User struct { ... }  // Becomes "api.User"

// In package "models"  
type User struct { ... }  // Becomes "models.User"
```

If you need custom schema names, use the `openapi` struct tag:

```go
type User struct {
    ID   int    `json:"id" openapi:"name=CustomUser"`
    Name string `json:"name"`
}
```

## Extension Validation

### Problem

Custom extensions are rejected or filtered out.

### Solution

Extensions must follow OpenAPI rules:

**Valid:**

```go
openapi.WithExtension("x-custom", "value")
openapi.WithExtension("x-api-version", "v2")
```

**Invalid:**

```go
// Missing x- prefix
openapi.WithExtension("custom", "value") // Error

// Reserved prefix in 3.1.x
openapi.WithExtension("x-oai-custom", "value") // Filtered out in 3.1.x
openapi.WithExtension("x-oas-custom", "value") // Filtered out in 3.1.x
```

## Version Compatibility

### Problem

Using OpenAPI 3.1 features with a 3.0 target generates warnings or errors.

### Solution

When using OpenAPI 3.0.x target, some 3.1.x features are automatically down-leveled:

| Feature | 3.0 Behavior |
|---------|--------------|
| `info.summary` | Dropped (warning) |
| `license.identifier` | Dropped (warning) |
| `const` in schemas | Converted to `enum` with single value |
| `examples` (multiple) | Converted to single `example` |
| `webhooks` | Dropped (warning) |
| `mutualTLS` security | Dropped (warning) |

**Options:**

1. **Accept warnings** (default):

```go
api := openapi.MustNew(
    openapi.WithVersion(openapi.V30x),
    openapi.WithInfoSummary("Summary"), // Generates warning
)

result, err := api.Generate(context.Background(), ops...)
// Check result.Warnings
```

2. **Enable strict mode** (error on 3.1 features):

```go
api := openapi.MustNew(
    openapi.WithVersion(openapi.V30x),
    openapi.WithStrictDownlevel(true), // Error on 3.1 features
    openapi.WithInfoSummary("Summary"), // Causes error
)
```

3. **Use 3.1 target**:

```go
api := openapi.MustNew(
    openapi.WithVersion(openapi.V31x), // All features available
    openapi.WithInfoSummary("Summary"), // No warning
)
```

## Parameters Not Discovered

### Problem

Parameters are not appearing in the generated specification.

### Solution

Ensure struct tags are correct:

**Common Issues:**

```go
// Wrong tag name
type Request struct {
    ID int `params:"id"` // Should be "path", "query", "header", or "cookie"
}

// Missing tag
type Request struct {
    ID int // No tag - won't be discovered
}

// Wrong location
type Request struct {
    ID int `query:"id"` // Should be "path" for path parameters
}
```

**Correct:**

```go
type Request struct {
    // Path parameters
    ID int `path:"id" doc:"User ID"`
    
    // Query parameters
    Page int `query:"page" doc:"Page number"`
    
    // Header parameters
    Auth string `header:"Authorization" doc:"Auth token"`
    
    // Cookie parameters
    Session string `cookie:"session_id" doc:"Session ID"`
}
```

## Validation Errors

### Problem

Generated specification fails validation.

### Solution

Enable validation to get detailed error messages:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithValidation(true), // Enable validation
)

result, err := api.Generate(context.Background(), ops...)
if err != nil {
    log.Printf("Validation failed: %v\n", err)
}
```

**Common validation errors:**

1. **Missing required fields:**

```go
// Missing version
openapi.MustNew(
    openapi.WithTitle("My API", ""), // Version required
)
```

2. **Invalid URLs:**

```go
// Invalid server URL
openapi.WithServer("not-a-url", "Server")
```

3. **Invalid enum values:**

```go
type Request struct {
    Status string `json:"status" enum:"active"` // Missing comma-separated values
}
```

## Performance Issues

### Problem

Specification generation is slow.

### Solution

**Typical performance:**
- First generation per type: ~500ns (reflection)
- Subsequent generations: ~50ns (cached)
- Validation overhead: 10-20ms first time, 1-5ms subsequent

**Optimization tips:**

1. **Disable validation in production:**

```go
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithValidation(false), // Disable for production
)
```

2. **Generate once, cache result:**

```go
var cachedSpec []byte
var once sync.Once

func getSpec() []byte {
    once.Do(func() {
        result, _ := api.Generate(context.Background(), ops...)
        cachedSpec = result.JSON
    })
    return cachedSpec
}
```

3. **Pre-generate at build time:**

```bash
# generate-spec.go
go run generate-spec.go > openapi.json
```

## Schema Generation Issues

### Problem

Go types are not converted correctly to OpenAPI schemas.

### Solution

**Supported types:**

```go
type Example struct {
    // Primitives
    String  string  `json:"string"`
    Int     int     `json:"int"`
    Bool    bool    `json:"bool"`
    Float   float64 `json:"float"`
    
    // Pointers (nullable)
    Optional *string `json:"optional,omitempty"`
    
    // Slices
    Tags []string `json:"tags"`
    
    // Maps
    Metadata map[string]string `json:"metadata"`
    
    // Nested structs
    Address Address `json:"address"`
    
    // Time
    CreatedAt time.Time `json:"created_at"`
}
```

**Unsupported types:**

```go
type Unsupported struct {
    Channel chan int        // Not supported
    Func    func()          // Not supported
    Complex complex64       // Not supported
}
```

**Workaround for unsupported types:**

Use custom types or JSON marshaling:

```go
type CustomType struct {
    data interface{}
}

func (c CustomType) MarshalJSON() ([]byte, error) {
    // Custom marshaling logic
}
```

## Context Errors

### Problem

`Generate()` returns "context is nil" error.

### Solution

Always provide a valid context:

```go
// Wrong
result, err := api.Generate(nil, ops...) // Error

// Correct
result, err := api.Generate(context.Background(), ops...)
result, err := api.Generate(ctx, ops...) // With existing context
```

## Common FAQ

### Q: How do I make a parameter optional?

**A:** For query/header/cookie parameters, omit `validate:"required"` tag. For request body fields, use pointer types or `omitempty`:

```go
type Request struct {
    Required string  `json:"required" validate:"required"`
    Optional *string `json:"optional,omitempty"`
}
```

### Q: How do I add multiple examples?

**A:** Pass multiple example instances to `WithRequest()` or `WithResponse()`:

```go
example1 := User{ID: 1, Name: "Alice"}
example2 := User{ID: 2, Name: "Bob"}

openapi.WithResponse(200, User{}, example1, example2)
```

### Q: Can I generate specs for existing handlers?

**A:** Yes, define types that match your handlers and pass them to operations:

```go
// Handler
func GetUser(id int) (*User, error) { ... }

// OpenAPI
openapi.GET("/users/:id",
    openapi.WithResponse(200, User{}),
)
```

### Q: How do I document error responses?

**A:** Use multiple `WithResponse()` calls:

```go
openapi.GET("/users/:id",
    openapi.WithResponse(200, User{}),
    openapi.WithResponse(400, ErrorResponse{}),
    openapi.WithResponse(404, ErrorResponse{}),
    openapi.WithResponse(500, ErrorResponse{}),
)
```

### Q: Can I use this with existing OpenAPI specs?

**A:** Use the `validate` package to validate external specs:

```go
import "rivaas.dev/openapi/validate"

validator := validate.New()
err := validator.ValidateAuto(context.Background(), specJSON)
```

## Getting Help

If you encounter issues not covered here:

1. Check the [pkg.go.dev documentation](https://pkg.go.dev/rivaas.dev/openapi)
2. Review [examples](/guides/openapi/examples/)
3. Search [GitHub issues](https://github.com/rivaas-dev/rivaas/issues)
4. Open a new issue with a minimal reproduction

## Next Steps

- Review [API Reference](api-reference/) for complete API documentation
- Check [Diagnostics](diagnostics/) for warning handling
- See [Examples](/guides/openapi/examples/) for usage patterns
