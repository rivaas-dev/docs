---
title: "Error Handling"
description: "Master error handling patterns for robust request validation and debugging"
weight: 9
keywords:
  - binding errors
  - validation errors
  - error messages
  - error handling
---

Comprehensive guide to error handling in the binding package. This includes error types, validation patterns, and debugging strategies.

## Error Types

The binding package provides structured error types for detailed error handling:

```go
// BindError represents a field-specific binding error
type BindError struct {
    Field  string // Field name that failed.
    Source string // Source like "query", "json", "header".
    Err    error  // Underlying error.
}

// ValidationError represents a validation failure
type ValidationError struct {
    Field   string // Field name that failed validation.
    Value   interface{} // The invalid value.
    Rule    string // Validation rule that failed.
    Message string // Human-readable message.
}
```

### Enhanced Error Messages

The binding package now provides helpful hints when type conversion fails. These hints suggest what might have gone wrong and how to fix it.

**Example error messages with hints:**

```go
type Request struct {
    Age   int       `query:"age"`
    Price float64   `query:"price"`
    When  time.Time `query:"when"`
    Active bool     `query:"active"`
}

// URL: ?age=10.5
// Error: cannot bind field "Age" from query: strconv.ParseInt: parsing "10.5": invalid syntax
//        Hint: value looks like a floating-point number; use float32 or float64 instead

// URL: ?price=twenty
// Error: cannot bind field "Price" from query: strconv.ParseFloat: parsing "twenty": invalid syntax
//        Hint: value "twenty" doesn't look like a number

// URL: ?when=yesterday
// Error: cannot bind field "When" from query: unable to parse time "yesterday" (tried 8 layouts)
//        Hint: common formats: "2006-01-02T15:04:05Z07:00", "2006-01-02", "01/02/2006"

// URL: ?active=maybe
// Error: cannot bind field "Active" from query: strconv.ParseBool: parsing "maybe": invalid syntax
//        Hint: use one of: true, false, 1, 0, t, f, yes, no, y, n
```

These contextual hints make it easier to understand what went wrong and fix the issue quickly.

## Basic Error Handling

### Simple Pattern

```go
user, err := binding.JSON[CreateUserRequest](r.Body)
if err != nil {
    http.Error(w, err.Error(), http.StatusBadRequest)
    return
}
```

### Detailed Pattern

```go
user, err := binding.JSON[CreateUserRequest](r.Body)
if err != nil {
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        // Field-specific error
        log.Printf("Failed to bind field %s from %s: %v",
            bindErr.Field, bindErr.Source, bindErr.Err)
    }
    
    http.Error(w, "Invalid request", http.StatusBadRequest)
    return
}
```

## Common Error Patterns

### Type Conversion Errors

```go
type Params struct {
    Age int `query:"age"`
}

// URL: ?age=invalid
// Error: BindError{
//   Field: "Age",
//   Source: "query",
//   Err: strconv.NumError{...}
// }
```

### Missing Required Fields

```go
type Request struct {
    APIKey string `header:"X-API-Key" binding:"required"`
}

// Missing header
// Error: BindError{
//   Field: "APIKey",
//   Source: "header",
//   Err: errors.New("required field missing")
// }
```

### JSON Syntax Errors

```go
// Malformed JSON: {"name": "test"
// Error: json.SyntaxError{...}

// Unknown field (with WithDisallowUnknownFields)
// Error: json.UnmarshalTypeError{...}
```

### Size Limit Errors

```go
req, err := binding.JSON[Request](
    r.Body,
    binding.WithMaxBytes(1024*1024),
)

// Request > 1MB
// Error: http.MaxBytesError{...}
```

## Error Response Patterns

### Basic JSON Error

```go
func handleError(w http.ResponseWriter, err error) {
    type ErrorResponse struct {
        Error string `json:"error"`
    }
    
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusBadRequest)
    json.NewEncoder(w).Encode(ErrorResponse{
        Error: err.Error(),
    })
}

// Usage
req, err := binding.JSON[Request](r.Body)
if err != nil {
    handleError(w, err)
    return
}
```

### Detailed Error Response

```go
type DetailedErrorResponse struct {
    Error   string                 `json:"error"`
    Details []FieldError           `json:"details,omitempty"`
}

type FieldError struct {
    Field   string `json:"field"`
    Message string `json:"message"`
    Code    string `json:"code,omitempty"`
}

func handleBindError(w http.ResponseWriter, err error) {
    response := DetailedErrorResponse{
        Error: "Invalid request",
    }
    
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        response.Details = []FieldError{
            {
                Field:   bindErr.Field,
                Message: bindErr.Err.Error(),
                Code:    "BIND_ERROR",
            },
        }
    }
    
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusBadRequest)
    json.NewEncoder(w).Encode(response)
}
```

### RFC 7807 Problem Details

```go
type ProblemDetail struct {
    Type     string                 `json:"type"`
    Title    string                 `json:"title"`
    Status   int                    `json:"status"`
    Detail   string                 `json:"detail,omitempty"`
    Instance string                 `json:"instance,omitempty"`
    Errors   map[string]interface{} `json:"errors,omitempty"`
}

func problemDetail(r *http.Request, err error) ProblemDetail {
    pd := ProblemDetail{
        Type:     "https://api.example.com/problems/invalid-request",
        Title:    "Invalid Request",
        Status:   http.StatusBadRequest,
        Instance: r.URL.Path,
        Errors:   make(map[string]interface{}),
    }
    
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        pd.Errors[bindErr.Field] = bindErr.Err.Error()
        pd.Detail = fmt.Sprintf("Field '%s' is invalid", bindErr.Field)
    } else {
        pd.Detail = err.Error()
    }
    
    return pd
}

// Usage
req, err := binding.JSON[Request](r.Body)
if err != nil {
    pd := problemDetail(r, err)
    w.Header().Set("Content-Type", "application/problem+json")
    w.WriteHeader(pd.Status)
    json.NewEncoder(w).Encode(pd)
    return
}
```

## Validation Integration

Combine binding with validation:

```go
import (
    "rivaas.dev/binding"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Username string `json:"username" validate:"required,alphanum,min=3,max=32"`
    Email    string `json:"email" validate:"required,email"`
    Age      int    `json:"age" validate:"required,min=18,max=120"`
}

func CreateUser(w http.ResponseWriter, r *http.Request) {
    // Step 1: Bind request
    req, err := binding.JSON[CreateUserRequest](r.Body)
    if err != nil {
        handleBindError(w, err)
        return
    }
    
    // Step 2: Validate
    if err := validation.Validate(req); err != nil {
        handleValidationError(w, err)
        return
    }
    
    // Process valid request
    user := createUser(req)
    json.NewEncoder(w).Encode(user)
}

func handleValidationError(w http.ResponseWriter, err error) {
    var valErrs validation.Errors
    if errors.As(err, &valErrs) {
        response := DetailedErrorResponse{
            Error: "Validation failed",
        }
        
        for _, valErr := range valErrs {
            response.Details = append(response.Details, FieldError{
                Field:   valErr.Field,
                Message: valErr.Message,
                Code:    valErr.Rule,
            })
        }
        
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusUnprocessableEntity)
        json.NewEncoder(w).Encode(response)
        return
    }
    
    http.Error(w, err.Error(), http.StatusBadRequest)
}
```

## Error Context

Add context to errors for better debugging:

```go
func bindRequest[T any](r *http.Request) (T, error) {
    req, err := binding.JSON[T](r.Body)
    if err != nil {
        return req, fmt.Errorf("binding request from %s: %w", r.RemoteAddr, err)
    }
    return req, nil
}
```

## Error Logging

### Structured Logging

```go
import "log/slog"

func handleRequest(w http.ResponseWriter, r *http.Request) {
    req, err := binding.JSON[Request](r.Body)
    if err != nil {
        var bindErr *binding.BindError
        if errors.As(err, &bindErr) {
            slog.Error("Binding error",
                "field", bindErr.Field,
                "source", bindErr.Source,
                "error", bindErr.Err,
                "path", r.URL.Path,
                "method", r.Method,
                "remote", r.RemoteAddr,
            )
        } else {
            slog.Error("Request binding failed",
                "error", err,
                "path", r.URL.Path,
                "method", r.Method,
            )
        }
        
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }
    
    // Process request
}
```

### Error Metrics

```go
import "rivaas.dev/metrics"

var (
    bindErrorsCounter = metrics.NewCounter(
        "binding_errors_total",
        "Total number of binding errors",
        "field", "source", "error_type",
    )
)

func handleBindError(err error) {
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        bindErrorsCounter.Inc(
            bindErr.Field,
            bindErr.Source,
            fmt.Sprintf("%T", bindErr.Err),
        )
    }
}
```

## Multi-Error Handling

Handle multiple errors from multi-source binding:

```go
type MultiError []error

func (me MultiError) Error() string {
    var msgs []string
    for _, err := range me {
        msgs = append(msgs, err.Error())
    }
    return strings.Join(msgs, "; ")
}

func handleMultiError(w http.ResponseWriter, err error) {
    var multiErr MultiError
    if errors.As(err, &multiErr) {
        response := DetailedErrorResponse{
            Error: "Multiple validation errors",
        }
        
        for _, e := range multiErr {
            var bindErr *binding.BindError
            if errors.As(e, &bindErr) {
                response.Details = append(response.Details, FieldError{
                    Field:   bindErr.Field,
                    Message: bindErr.Err.Error(),
                })
            }
        }
        
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(response)
        return
    }
    
    http.Error(w, err.Error(), http.StatusBadRequest)
}
```

## Error Recovery

### Graceful Degradation

```go
func loadConfig(r *http.Request) Config {
    cfg, err := binding.Query[Config](r.URL.Query())
    if err != nil {
        // Log error but use defaults
        slog.Warn("Failed to bind config, using defaults", "error", err)
        return DefaultConfig()
    }
    return cfg
}
```

### Partial Success

```go
func processBatch(items []Item) ([]Result, []error) {
    var results []Result
    var errors []error
    
    for _, item := range items {
        result, err := binding.Unmarshal[ProcessedItem](item.Data)
        if err != nil {
            errors = append(errors, fmt.Errorf("item %s: %w", item.ID, err))
            continue
        }
        results = append(results, Result{ID: item.ID, Data: result})
    }
    
    return results, errors
}
```

## Error Testing

### Unit Tests

```go
func TestBindingError(t *testing.T) {
    type Request struct {
        Age int `json:"age"`
    }
    
    // Test invalid type
    body := strings.NewReader(`{"age": "not a number"}`)
    _, err := binding.JSON[Request](body)
    
    if err == nil {
        t.Fatal("expected error, got nil")
    }
    
    var bindErr *binding.BindError
    if !errors.As(err, &bindErr) {
        t.Fatalf("expected BindError, got %T", err)
    }
    
    if bindErr.Field != "Age" {
        t.Errorf("expected field Age, got %s", bindErr.Field)
    }
}
```

### Integration Tests

```go
func TestErrorResponse(t *testing.T) {
    payload := `{"age": "invalid"}`
    req := httptest.NewRequest("POST", "/users", strings.NewReader(payload))
    req.Header.Set("Content-Type", "application/json")
    
    rec := httptest.NewRecorder()
    CreateUserHandler(rec, req)
    
    if rec.Code != http.StatusBadRequest {
        t.Errorf("expected status 400, got %d", rec.Code)
    }
    
    var response ErrorResponse
    if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
        t.Fatal(err)
    }
    
    if response.Error == "" {
        t.Error("expected error message")
    }
}
```

## Best Practices

### 1. Always Check Errors

```go
// Good
req, err := binding.JSON[Request](r.Body)
if err != nil {
    handleError(w, err)
    return
}

// Bad - ignoring errors
req, _ := binding.JSON[Request](r.Body)
```

### 2. Use Specific Error Types

```go
// Good - check specific error types
var bindErr *binding.BindError
if errors.As(err, &bindErr) {
    // Handle binding error specifically
}

// Bad - generic error handling
if err != nil {
    http.Error(w, "error", 500)
}
```

### 3. Log for Debugging

```go
// Good - structured logging
slog.Error("Binding failed",
    "error", err,
    "path", r.URL.Path,
    "user", getUserID(r),
)

// Bad - no logging
if err != nil {
    http.Error(w, "error", 400)
    return
}
```

### 4. Return Helpful Messages

```go
// Good - specific error message
type ErrorResponse struct {
    Error  string       `json:"error"`
    Field  string       `json:"field,omitempty"`
    Detail string       `json:"detail,omitempty"`
}

// Bad - generic message
http.Error(w, "bad request", 400)
```

### 5. Separate Binding from Validation

```go
// Good - clear separation
req, err := binding.JSON[Request](r.Body)
if err != nil {
    return handleBindError(err)
}

if err := validation.Validate(req); err != nil {
    return handleValidationError(err)
}

// Bad - mixing concerns
if err := bindAndValidate(r.Body); err != nil {
    // Can't tell binding from validation errors
}
```

## Error Middleware

Create reusable error handling middleware:

```go
type ErrorHandler func(http.ResponseWriter, *http.Request) error

func (fn ErrorHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    if err := fn(w, r); err != nil {
        handleError(w, r, err)
    }
}

func handleError(w http.ResponseWriter, r *http.Request, err error) {
    // Log error
    slog.Error("Request error",
        "error", err,
        "path", r.URL.Path,
        "method", r.Method,
    )
    
    // Determine status code
    status := http.StatusInternalServerError
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        status = http.StatusBadRequest
    }
    
    // Send response
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(map[string]string{
        "error": err.Error(),
    })
}

// Usage
http.Handle("/users", ErrorHandler(func(w http.ResponseWriter, r *http.Request) error {
    req, err := binding.JSON[CreateUserRequest](r.Body)
    if err != nil {
        return err
    }
    
    // Process request
    return nil
}))
```

## Common Error Scenarios

### Scenario 1: Type Mismatch

```go
// Request: {"age": "twenty"}
// Expected: {"age": 20}
// Error: cannot unmarshal string into int
```

**Solution**: Validate input format, provide clear error message

### Scenario 2: Missing Required Field

```go
// Request: {}
// Expected: {"api_key": "secret"}
// Error: required field 'api_key' missing
```

**Solution**: Use `binding:"required"` tag or validation

### Scenario 3: Invalid JSON

```go
// Request: {"name": "test"
// Error: unexpected EOF
```

**Solution**: Check Content-Type header, validate JSON syntax

### Scenario 4: Request Too Large

```go
// Request: 10MB payload
// Limit: 1MB
// Error: http: request body too large
```

**Solution**: Set appropriate `WithMaxBytes()` limit

## Debugging Tips

### 1. Enable Debug Logging

```go
import "log/slog"

slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
})))
```

### 2. Inspect Raw Request

```go
// Save body for debugging
body, _ := io.ReadAll(r.Body)
r.Body = io.NopCloser(bytes.NewReader(body))

slog.Debug("Raw request body", "body", string(body))

req, err := binding.JSON[Request](r.Body)
```

### 3. Check Headers

```go
slog.Debug("Request headers",
    "content-type", r.Header.Get("Content-Type"),
    "content-length", r.Header.Get("Content-Length"),
)
```

### 4. Use Error Wrapping

```go
if err != nil {
    return fmt.Errorf("processing request from %s: %w", r.RemoteAddr, err)
}
```

## Next Steps

- Explore [Advanced Usage](../advanced-usage/) for custom error handlers
- See [Examples](../examples/) for complete error handling patterns
- Review [Troubleshooting](/reference/packages/binding/troubleshooting/) for common issues
- Check [API Reference](/reference/packages/binding/api-reference/) for error types

For complete error type documentation, see [API Reference](/reference/packages/binding/api-reference/).
