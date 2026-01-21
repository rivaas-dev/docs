---
title: "Error Handling"
description: "Work with structured validation errors"
weight: 7
keywords:
  - validation errors
  - error messages
  - error formatting
  - error handling
---

Validation errors in the Rivaas validation package are structured and detailed. They provide field-level error information with codes, messages, and metadata.

## Error Types

### validation.Error

The main validation error type containing multiple field errors:

```go
type Error struct {
    Fields    []FieldError // List of field errors.
    Truncated bool         // True if errors were truncated due to maxErrors limit.
}
```

### FieldError

Individual field error with detailed information:

```go
type FieldError struct {
    Path    string         // JSON path like "items.2.price".
    Code    string         // Stable code like "tag.required", "schema.type".
    Message string         // Human-readable message.
    Meta    map[string]any // Additional metadata like tag, param, value.
}
```

## Checking for Validation Errors

Use `errors.As` to extract structured errors:

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

## Error Codes

Error codes follow a consistent pattern for programmatic handling:

### Struct Tag Errors

Format: `tag.<tagname>`

```go
Code: "tag.required"     // Required field missing
Code: "tag.email"        // Email format invalid
Code: "tag.min"          // Below minimum value/length
Code: "tag.max"          // Above maximum value/length
Code: "tag.oneof"        // Value not in enum
```

### JSON Schema Errors

Format: `schema.<constraint>`

```go
Code: "schema.type"      // Type mismatch
Code: "schema.required"  // Missing required field
Code: "schema.minimum"   // Below minimum value
Code: "schema.pattern"   // Pattern mismatch
Code: "schema.format"    // Format validation failed
```

### Interface Method Errors

Custom codes from your validation methods:

```go
Code: "validation_error" // Generic validation error
Code: "custom_code"      // Your custom code
```

## Accessing Field Errors

### Iterate Over All Errors

```go
var verr *validation.Error
if errors.As(err, &verr) {
    for _, fieldErr := range verr.Fields {
        log.Printf("Field: %s, Code: %s, Message: %s",
            fieldErr.Path,
            fieldErr.Code,
            fieldErr.Message,
        )
    }
}
```

### Check for Specific Field

```go
var verr *validation.Error
if errors.As(err, &verr) {
    if verr.Has("email") {
        fmt.Println("Email field has an error")
    }
}
```

### Get First Error for Field

```go
var verr *validation.Error
if errors.As(err, &verr) {
    fieldErr := verr.GetField("email")
    if fieldErr != nil {
        fmt.Printf("Email error: %s\n", fieldErr.Message)
    }
}
```

### Check for Specific Error Code

```go
var verr *validation.Error
if errors.As(err, &verr) {
    if verr.HasCode("tag.required") {
        fmt.Println("Some required fields are missing")
    }
}
```

## Error Metadata

Errors may include additional metadata:

```go
var verr *validation.Error
if errors.As(err, &verr) {
    for _, fieldErr := range verr.Fields {
        fmt.Printf("Path: %s\n", fieldErr.Path)
        fmt.Printf("Code: %s\n", fieldErr.Code)
        fmt.Printf("Message: %s\n", fieldErr.Message)
        
        // Access metadata
        if tag, ok := fieldErr.Meta["tag"].(string); ok {
            fmt.Printf("Tag: %s\n", tag)
        }
        if param, ok := fieldErr.Meta["param"].(string); ok {
            fmt.Printf("Param: %s\n", param)
        }
        if value := fieldErr.Meta["value"]; value != nil {
            fmt.Printf("Value: %v\n", value)
        }
    }
}
```

Common metadata fields:
- `tag` - The validation tag that failed (struct tags)
- `param` - Tag parameter (e.g., "18" for `min=18`)
- `value` - The actual value (may be redacted)
- `expected` - Expected value for comparison errors
- `actual` - Actual value for comparison errors

## Error Messages

### Default Messages

The package provides clear default messages:

```go
"is required"
"must be a valid email address"
"must be at least 18"
"must be one of: pending, confirmed, shipped"
```

### Custom Messages

Customize error messages when creating a validator:

```go
validator := validation.MustNew(
    validation.WithMessages(map[string]string{
        "required": "cannot be empty",
        "email":    "invalid email format",
        "min":      "too small",
    }),
)
```

### Dynamic Messages

Use `WithMessageFunc` for parameterized tags:

```go
validator := validation.MustNew(
    validation.WithMessageFunc("min", func(param string, kind reflect.Kind) string {
        if kind == reflect.String {
            return fmt.Sprintf("must be at least %s characters", param)
        }
        return fmt.Sprintf("must be at least %s", param)
    }),
)
```

## Limiting Errors

### Max Errors

Limit the number of errors returned:

```go
err := validation.Validate(ctx, &req,
    validation.WithMaxErrors(5),
)

var verr *validation.Error
if errors.As(err, &verr) {
    if verr.Truncated {
        fmt.Println("More errors exist (showing first 5)")
    }
}
```

### Fail Fast

Stop at the first error:

```go
err := validation.Validate(ctx, &req,
    validation.WithMaxErrors(1),
)
```

## Sorting Errors

Sort errors for consistent output:

```go
var verr *validation.Error
if errors.As(err, &verr) {
    verr.Sort() // Sort by path, then by code
    
    for _, fieldErr := range verr.Fields {
        fmt.Printf("%s: %s\n", fieldErr.Path, fieldErr.Message)
    }
}
```

## HTTP Error Responses

### JSON Error Response

```go
func HandleValidationError(w http.ResponseWriter, err error) {
    var verr *validation.Error
    if errors.As(err, &verr) {
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusUnprocessableEntity)
        json.NewEncoder(w).Encode(map[string]any{
            "error": "validation_failed",
            "fields": verr.Fields,
        })
        return
    }
    
    // Other error types
    http.Error(w, "internal server error", http.StatusInternalServerError)
}
```

Example response:

```json
{
    "error": "validation_failed",
    "fields": [
        {
            "path": "email",
            "code": "tag.email",
            "message": "must be a valid email address",
            "meta": {
                "tag": "email",
                "value": "[REDACTED]"
            }
        },
        {
            "path": "age",
            "code": "tag.min",
            "message": "must be at least 18",
            "meta": {
                "tag": "min",
                "param": "18",
                "value": 15
            }
        }
    ]
}
```

### Problem Details (RFC 7807)

```go
func HandleValidationErrorProblemDetails(w http.ResponseWriter, err error) {
    var verr *validation.Error
    if !errors.As(err, &verr) {
        http.Error(w, "internal server error", http.StatusInternalServerError)
        return
    }
    
    // Convert to Problem Details format
    problems := make([]map[string]any, len(verr.Fields))
    for i, fieldErr := range verr.Fields {
        problems[i] = map[string]any{
            "field":   fieldErr.Path,
            "code":    fieldErr.Code,
            "message": fieldErr.Message,
        }
    }
    
    w.Header().Set("Content-Type", "application/problem+json")
    w.WriteHeader(http.StatusUnprocessableEntity)
    json.NewEncoder(w).Encode(map[string]any{
        "type":     "https://example.com/problems/validation-error",
        "title":    "Validation Error",
        "status":   422,
        "detail":   verr.Error(),
        "instance": r.URL.Path,
        "errors":   problems,
    })
}
```

## Creating Custom Errors

### Adding Errors Manually

```go
var verr validation.Error

verr.Add("email", "invalid", "email is blacklisted", map[string]any{
    "domain": "example.com",
    "reason": "spam",
})

verr.Add("password", "weak", "password is too weak", nil)

if verr.HasErrors() {
    return &verr
}
```

### Combining Errors

```go
var allErrors validation.Error

// Add errors from multiple sources
allErrors.AddError(err1)
allErrors.AddError(err2)
allErrors.AddError(err3)

if allErrors.HasErrors() {
    return &allErrors
}
```

## Error Interface Implementations

The `Error` type implements several interfaces:

### error Interface

```go
err := validation.Validate(ctx, &req)
fmt.Println(err.Error())
// Output: "validation failed: email: must be valid email; age: must be at least 18"
```

### errors.Is

```go
if errors.Is(err, validation.ErrValidation) {
    // This is a validation error
}
```

### rivaas.dev/errors Interfaces

The `Error` type implements additional interfaces for the Rivaas error handling system:

```go
// ErrorType - HTTP status code
func (e Error) HTTPStatus() int {
    return 422 // Unprocessable Entity
}

// ErrorCode - Stable error code
func (e Error) Code() string {
    return "validation_error"
}

// ErrorDetails - Detailed error information
func (e Error) Details() any {
    return e.Fields
}
```

## Nil and Empty Errors

### Nil Pointer Errors

```go
var user *User
err := validation.Validate(ctx, user)
// Returns: *validation.Error with code "nil_pointer"
```

### Invalid Value Errors

```go
var invalid interface{} = nil
err := validation.Validate(ctx, invalid)
// Returns: *validation.Error with code "invalid"
```

## Logging Errors

### Structured Logging

```go
var verr *validation.Error
if errors.As(err, &verr) {
    for _, fieldErr := range verr.Fields {
        log.With(
            "field", fieldErr.Path,
            "code", fieldErr.Code,
            "message", fieldErr.Message,
        ).Warn("validation failed")
    }
}
```

### Summary Logging

```go
var verr *validation.Error
if errors.As(err, &verr) {
    fieldPaths := make([]string, len(verr.Fields))
    for i, fieldErr := range verr.Fields {
        fieldPaths[i] = fieldErr.Path
    }
    
    log.With(
        "error_count", len(verr.Fields),
        "fields", strings.Join(fieldPaths, ", "),
    ).Warn("validation failed")
}
```

## Testing Error Handling

```go
func TestValidationErrors(t *testing.T) {
    req := CreateUserRequest{
        Email: "invalid",
        Age:   15,
    }
    
    err := validation.Validate(context.Background(), &req)
    
    var verr *validation.Error
    if !errors.As(err, &verr) {
        t.Fatal("expected validation.Error")
    }
    
    // Check error count
    if len(verr.Fields) != 2 {
        t.Errorf("expected 2 errors, got %d", len(verr.Fields))
    }
    
    // Check specific field error
    if !verr.Has("email") {
        t.Error("expected email error")
    }
    
    // Check error code
    if !verr.HasCode("tag.email") {
        t.Error("expected tag.email error code")
    }
    
    // Check error message
    emailErr := verr.GetField("email")
    if emailErr == nil {
        t.Fatal("email error not found")
    }
    if !strings.Contains(emailErr.Message, "email") {
        t.Errorf("unexpected message: %s", emailErr.Message)
    }
}
```

## Next Steps

- [**Custom Validators**](../custom-validators/) - Create custom validation logic
- [**Security**](../security/) - Redact sensitive data in errors
- [**API Reference**](/reference/packages/validation/api-reference/) - Complete Error API documentation
