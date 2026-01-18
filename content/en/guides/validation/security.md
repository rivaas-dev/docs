---
title: "Security"
description: "Protect sensitive data and prevent validation attacks"
weight: 9
---

The validation package includes built-in security features to protect sensitive data and prevent various attacks through validation.

## Sensitive Data Redaction

Protect sensitive data in error messages with redactors:

```go
redactor := func(path string) bool {
    return strings.Contains(path, "password") ||
           strings.Contains(path, "token") ||
           strings.Contains(path, "secret") ||
           strings.Contains(path, "api_key")
}

validator := validation.MustNew(
    validation.WithRedactor(redactor),
)
```

### How Redaction Works

When a field is redacted, its value in error messages is replaced with `[REDACTED]`:

```go
type User struct {
    Email    string `validate:"required,email"`
    Password string `validate:"required,min=8"`
}

user := User{
    Email:    "invalid",
    Password: "secret123",
}

err := validator.Validate(ctx, &user)
// Error: email: must be valid email (value: "invalid")
// Error: password: too short (value: "[REDACTED]")
```

### Pattern-Based Redaction

```go
func sensitiveFieldRedactor(path string) bool {
    sensitive := []string{
        "password",
        "token",
        "secret",
        "api_key",
        "credit_card",
        "ssn",
        "private_key",
    }
    
    pathLower := strings.ToLower(path)
    for _, keyword := range sensitive {
        if strings.Contains(pathLower, keyword) {
            return true
        }
    }
    return false
}

validator := validation.MustNew(
    validation.WithRedactor(sensitiveFieldRedactor),
)
```

### Path-Specific Redaction

```go
func pathRedactor(path string) bool {
    redactedPaths := map[string]bool{
        "user.password":          true,
        "user.security_question": true,
        "payment.card_number":    true,
        "payment.cvv":            true,
        "auth.refresh_token":     true,
    }
    return redactedPaths[path]
}
```

### Redacting Nested Fields

```go
type Payment struct {
    CardNumber string `json:"card_number" validate:"required,credit_card"`
    CVV        string `json:"cvv" validate:"required,len=3"`
}

type Order struct {
    Payment Payment `json:"payment"`
}

redactor := func(path string) bool {
    // Redact payment.card_number and payment.cvv
    return strings.HasPrefix(path, "payment.card_number") ||
           strings.HasPrefix(path, "payment.cvv")
}
```

## Security Limits

### Maximum Nesting Depth

The package protects against stack overflow from deeply nested structures:

```go
// Built-in protection: max depth = 100 levels
const maxRecursionDepth = 100
```

This applies to:
- `ComputePresence()` - Presence map computation
- Nested struct validation
- Recursive data structures

### Maximum Fields

Limit fields processed in partial validation:

```go
validator := validation.MustNew(
    validation.WithMaxFields(5000), // Default: 10000
)
```

Prevents attacks with extremely large JSON objects:

```json
{
  "field1": "value",
  "field2": "value",
  // ... 100,000 more fields
}
```

### Maximum Errors

Limit errors returned to prevent memory exhaustion:

```go
validator := validation.MustNew(
    validation.WithMaxErrors(100), // Default: unlimited
)
```

When limit is reached, `Truncated` flag is set:

```go
var verr *validation.Error
if errors.As(err, &verr) {
    if verr.Truncated {
        log.Warn("more validation errors exist (truncated)")
    }
}
```

### Schema Cache Size

Limit JSON Schema cache to prevent memory exhaustion:

```go
validator := validation.MustNew(
    validation.WithMaxCachedSchemas(2048), // Default: 1024
)
```

Uses LRU eviction - oldest schemas are removed when limit is reached.

## Input Validation Security

### Prevent Injection Attacks

Always validate input format before using in queries or commands:

```go
type SearchRequest struct {
    Query string `validate:"required,max=100,alphanum"`
}

// Safe from SQL injection (alphanumeric only)
err := validator.Validate(ctx, &req)
```

### Sanitize HTML

```go
import "html"

type CreatePostRequest struct {
    Title   string `validate:"required,max=200"`
    Content string `validate:"required,max=10000"`
}

func (r *CreatePostRequest) Validate() error {
    // Sanitize HTML
    r.Title = html.EscapeString(r.Title)
    r.Content = html.EscapeString(r.Content)
    return nil
}
```

### Validate File Paths

```go
import "path/filepath"

type UploadRequest struct {
    Filename string `validate:"required"`
}

func (r *UploadRequest) Validate() error {
    // Prevent path traversal attacks
    cleaned := filepath.Clean(r.Filename)
    if strings.Contains(cleaned, "..") {
        return errors.New("invalid filename: path traversal detected")
    }
    r.Filename = cleaned
    return nil
}
```

## Rate Limiting

Combine validation with rate limiting to prevent abuse:

```go
import "golang.org/x/time/rate"

var limiter = rate.NewLimiter(rate.Every(time.Second), 10)

func ValidateWithRateLimit(ctx context.Context, req any) error {
    // Check rate limit first (fast)
    if !limiter.Allow() {
        return errors.New("rate limit exceeded")
    }
    
    // Then validate (slower)
    return validation.Validate(ctx, req)
}
```

## Denial of Service Prevention

### Request Size Limits

```go
func Handler(w http.ResponseWriter, r *http.Request) {
    // Limit request body size
    r.Body = http.MaxBytesReader(w, r.Body, 1*1024*1024) // 1MB max
    
    rawJSON, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "request too large", http.StatusRequestEntityTooLarge)
        return
    }
    
    // Continue with validation
}
```

### Array/Slice Limits

```go
type BatchRequest struct {
    Items []Item `validate:"required,min=1,max=100"`
}

// Prevents DoS with extremely large arrays
```

### String Length Limits

```go
type Request struct {
    Description string `validate:"max=10000"`
}

// Prevents memory exhaustion from huge strings
```

### Validation Timeout

```go
import "context"

func ValidateWithTimeout(req any) error {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    return validation.Validate(ctx, req)
}
```

## Security Best Practices

### 1. Always Validate User Input

```go
// Good
func CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    json.NewDecoder(r.Body).Decode(&req)
    
    // ALWAYS validate
    if err := validation.Validate(r.Context(), &req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Safe to use req
}

// Bad
func CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    json.NewDecoder(r.Body).Decode(&req)
    
    // Using unvalidated input - DANGEROUS!
    db.Exec("INSERT INTO users VALUES (?, ?)", req.Username, req.Email)
}
```

### 2. Validate Before Database Operations

```go
func UpdateUser(ctx context.Context, req UpdateUserRequest) error {
    // Validate first
    if err := validation.Validate(ctx, &req); err != nil {
        return err
    }
    
    // Then update database
    return db.UpdateUser(ctx, req)
}
```

### 3. Use Strict Mode for APIs

```go
validator := validation.MustNew(
    validation.WithDisallowUnknownFields(true),
)

// Rejects requests with unexpected fields (typo detection)
```

### 4. Redact All Sensitive Fields

```go
func comprehensiveRedactor(path string) bool {
    pathLower := strings.ToLower(path)
    
    // Passwords and secrets
    if strings.Contains(pathLower, "password") ||
       strings.Contains(pathLower, "secret") ||
       strings.Contains(pathLower, "token") ||
       strings.Contains(pathLower, "key") {
        return true
    }
    
    // Payment information
    if strings.Contains(pathLower, "card") ||
       strings.Contains(pathLower, "cvv") ||
       strings.Contains(pathLower, "credit") {
        return true
    }
    
    // Personal information
    if strings.Contains(pathLower, "ssn") ||
       strings.Contains(pathLower, "social_security") ||
       strings.Contains(pathLower, "tax_id") {
        return true
    }
    
    return false
}
```

### 5. Log Validation Failures

```go
err := validation.Validate(ctx, &req)
if err != nil {
    var verr *validation.Error
    if errors.As(err, &verr) {
        // Log validation failures for security monitoring
        log.With(
            "error_count", len(verr.Fields),
            "fields", getFieldPaths(verr.Fields),
            "ip", getClientIP(r),
        ).Warn("validation failed")
    }
    
    return err
}
```

### 6. Fail Secure

```go
// Good - fail if validation library has issues
validator, err := validation.New(options...)
if err != nil {
    panic("failed to create validator: " + err.Error())
}

// Bad - continue without validation
validator, err := validation.New(options...)
if err != nil {
    log.Warn("validator creation failed, continuing anyway") // DANGEROUS
}
```

## Common Security Vulnerabilities

### SQL Injection

```go
// VULNERABLE
type SearchRequest struct {
    Query string // No validation
}
db.Exec("SELECT * FROM users WHERE name = '" + req.Query + "'")

// SAFE
type SearchRequest struct {
    Query string `validate:"required,max=100,alphanum"`
}
if err := validation.Validate(ctx, &req); err != nil {
    return err
}
db.Exec("SELECT * FROM users WHERE name = ?", req.Query)
```

### Path Traversal

```go
// VULNERABLE
type FileRequest struct {
    Path string // No validation
}
os.ReadFile(req.Path) // Could be "../../etc/passwd"

// SAFE
type FileRequest struct {
    Path string `validate:"required,max=255"`
}

func (r *FileRequest) Validate() error {
    cleaned := filepath.Clean(r.Path)
    if strings.Contains(cleaned, "..") {
        return errors.New("path traversal detected")
    }
    if !strings.HasPrefix(cleaned, "/safe/directory/") {
        return errors.New("path outside allowed directory")
    }
    return nil
}
```

### XXE (XML External Entity)

```go
// VULNERABLE
xml.Unmarshal(req.Body, &data)

// SAFE
decoder := xml.NewDecoder(req.Body)
decoder.Strict = true
decoder.Entity = xml.HTMLEntity // Prevent external entities
err := decoder.Decode(&data)
```

### Mass Assignment

```go
// VULNERABLE
type UpdateUserRequest struct {
    Email string
    Role  string // User shouldn't be able to set this!
}

// SAFE - separate request types
type UpdateUserRequest struct {
    Email string `validate:"required,email"`
}

type AdminUpdateUserRequest struct {
    Email string `validate:"required,email"`
    Role  string `validate:"required,oneof=user admin"`
}
```

## Security Checklist

- [ ] All user input is validated before use
- [ ] Sensitive fields are redacted in errors
- [ ] Request size limits are enforced
- [ ] Array/slice lengths are limited
- [ ] Nesting depth is limited (handled automatically)
- [ ] Unknown fields are rejected in strict mode
- [ ] Validation failures are logged
- [ ] Rate limiting is implemented
- [ ] Timeouts are set for validation
- [ ] SQL queries use parameterized statements
- [ ] File paths are sanitized
- [ ] HTML is escaped before rendering
- [ ] Mass assignment is prevented

## Next Steps

- [**Examples**](../examples/) - Complete security examples
- [**Options Reference**](/reference/packages/validation/options/) - Security-related options
- [**Error Handling**](../error-handling/) - Handle errors securely
