---
title: "Basic Usage"
description: "Learn the fundamentals of binding request data to Go structs"
weight: 3
keywords:
  - binding basic usage
  - json binding
  - form binding
  - getting started
---

This guide covers the essential operations for working with the binding package. Learn how to bind from different sources, understand the API variants, and handle errors.

## Generic API vs Non-Generic API

The binding package provides two API styles:

### Generic API (Recommended)

Use the generic API when you know the type at compile time:

```go
// Type is specified as a type parameter
user, err := binding.JSON[CreateUserRequest](body)
params, err := binding.Query[ListParams](r.URL.Query())
```

**Benefits:**
- Compile-time type safety.
- Cleaner syntax.
- Better IDE support.
- No need to pre-allocate the struct.

### Non-Generic API

Use the non-generic API when the type comes from a variable or when working with interfaces:

```go
var user CreateUserRequest
err := binding.JSONTo(body, &user)

var params ListParams
err := binding.QueryTo(r.URL.Query(), &params)
```

**Use when:**
- Type is determined at runtime.
- Working with reflection.
- Integrating with older codebases.

## Binding from Different Sources

### JSON Body

```go
type CreateUserRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
    Age   int    `json:"age"`
}

// Read body from request
body, err := io.ReadAll(r.Body)
if err != nil {
    // Handle error
}
defer r.Body.Close()

// Bind JSON to struct
user, err := binding.JSON[CreateUserRequest](body)
if err != nil {
    // Handle binding error
}
```

### Query Parameters

```go
type ListParams struct {
    Page   int      `query:"page" default:"1"`
    Limit  int      `query:"limit" default:"20"`
    Search string   `query:"search"`
    Tags   []string `query:"tags"`
}

params, err := binding.Query[ListParams](r.URL.Query())
```

### Path Parameters

```go
type UserIDParam struct {
    UserID int `path:"user_id"`
}

// Path params typically come from your router
// Example with common router pattern:
pathParams := map[string]string{
    "user_id": "123",
}

params, err := binding.Path[UserIDParam](pathParams)
```

### Form Data

```go
type LoginForm struct {
    Username string `form:"username"`
    Password string `form:"password"`
    Remember bool   `form:"remember"`
}

// Parse form first
if err := r.ParseForm(); err != nil {
    // Handle parse error
}

form, err := binding.Form[LoginForm](r.Form)
```

### Headers

```go
type RequestHeaders struct {
    Auth        string `header:"Authorization"`
    ContentType string `header:"Content-Type"`
    UserAgent   string `header:"User-Agent"`
}

headers, err := binding.Header[RequestHeaders](r.Header)
```

### Cookies

```go
type SessionCookies struct {
    SessionID string `cookie:"session_id"`
    CSRF      string `cookie:"csrf_token"`
}

cookies, err := binding.Cookie[SessionCookies](r.Cookies())
```

## Error Handling Basics

All binding functions return an error that provides context about what went wrong:

```go
user, err := binding.JSON[CreateUserRequest](body)
if err != nil {
    // Check for specific error types
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        fmt.Printf("Field %s: %v\n", bindErr.Field, bindErr.Err)
    }
    
    // Or just use the error message
    http.Error(w, err.Error(), http.StatusBadRequest)
    return
}
```

**Common error types:**
- `BindError` - Field-level binding error with context
- `UnknownFieldError` - Unknown fields in strict mode
- `MultiError` - Multiple errors when using `WithAllErrors()`

See [Error Handling](../error-handling/) for detailed information.

## Default Values

Use the `default` tag to specify fallback values:

```go
type Config struct {
    Port    int    `query:"port" default:"8080"`
    Host    string `query:"host" default:"localhost"`
    Debug   bool   `query:"debug" default:"false"`
    Timeout string `query:"timeout" default:"30s"`
}

// If query params don't include these values, defaults are used
cfg, err := binding.Query[Config](r.URL.Query())
```

## Working with Pointers

Use pointers to distinguish between "not set" and "set to zero value":

```go
type UpdateUserRequest struct {
    Name  *string `json:"name"`   // nil = not updating, "" = clear value
    Email *string `json:"email"`
    Age   *int    `json:"age"`    // nil = not updating, 0 = set to zero
}

user, err := binding.JSON[UpdateUserRequest](body)

// Check if field was provided
if user.Name != nil {
    // Update name to *user.Name
}
if user.Age != nil {
    // Update age to *user.Age
}
```

## Common Patterns

### API Handler Pattern

```go
func CreateUserHandler(w http.ResponseWriter, r *http.Request) {
    // Read body
    body, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "Failed to read body", http.StatusBadRequest)
        return
    }
    defer r.Body.Close()
    
    // Bind request
    req, err := binding.JSON[CreateUserRequest](body)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Process request
    user := createUser(req)
    
    // Send response
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}
```

### Query + Path Parameters

```go
type GetUserRequest struct {
    UserID int    `path:"user_id"`
    Format string `query:"format" default:"json"`
}

func GetUserHandler(w http.ResponseWriter, r *http.Request) {
    req, err := binding.Bind[GetUserRequest](
        binding.FromPath(pathParams),  // From router
        binding.FromQuery(r.URL.Query()),
    )
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    user := getUserByID(req.UserID)
    // Format response according to req.Format
}
```

### Form with CSRF Token

```go
type EditForm struct {
    Title   string `form:"title"`
    Content string `form:"content"`
    CSRF    string `form:"csrf_token"`
}

func EditHandler(w http.ResponseWriter, r *http.Request) {
    if err := r.ParseForm(); err != nil {
        http.Error(w, "Invalid form", http.StatusBadRequest)
        return
    }
    
    form, err := binding.Form[EditForm](r.Form)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Verify CSRF token
    if !verifyCRSF(form.CSRF) {
        http.Error(w, "Invalid CSRF token", http.StatusForbidden)
        return
    }
    
    // Process form
}
```

## Type Conversion

The binding package automatically converts string values to appropriate types:

```go
type Request struct {
    // String to int
    Page int `query:"page"`           // "123" -> 123
    
    // String to bool
    Active bool `query:"active"`      // "true" -> true
    
    // String to float
    Price float64 `query:"price"`     // "19.99" -> 19.99
    
    // String to time.Duration
    Timeout time.Duration `query:"timeout"`  // "30s" -> 30 * time.Second
    
    // String to time.Time
    CreatedAt time.Time `query:"created"`   // "2025-01-01" -> time.Time
    
    // String to slice
    Tags []string `query:"tags"`      // "go,rust,python" -> []string
}
```

See [Type Support](../type-support/) for complete type conversion details.

## Performance Tips

1. **Reuse request bodies**: Binding consumes the body, so read it once and reuse
2. **Use defaults**: Struct tags with defaults avoid unnecessary error checking
3. **Cache reflection**: Happens automatically, but avoid dynamic struct generation
4. **Stream large payloads**: Use `JSONReader` for bodies > 1MB

## Next Steps

- Learn about [Query Parameters](../query-parameters/) in detail
- Explore [JSON Binding](../json-binding/) for request bodies
- See [Multi-Source](../multi-source/) for combining data
- Master [Struct Tags](../struct-tags/) syntax and options

For complete API documentation, see [API Reference](/reference/packages/binding/api-reference/).
