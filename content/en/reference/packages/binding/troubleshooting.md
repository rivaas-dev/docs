---
title: "Troubleshooting"
description: "Common issues, solutions, and FAQs"
weight: 5
---

Solutions to common issues, frequently asked questions, and debugging strategies for the binding package.

## Common Issues

### Field Not Binding

**Problem**: Field remains zero value after binding.

**Possible Causes:**

1. **Field is unexported**
   ```go
   // Wrong - unexported field
   type Request struct {
       name string `json:"name"`  // Won't bind
   }
   
   // Correct
   type Request struct {
       Name string `json:"name"`
   }
   ```

2. **Tag name doesn't match source key**
   ```go
   // JSON: {"username": "alice"}
   type Request struct {
       Name string `json:"name"`  // Wrong tag name
   }
   
   // Correct
   type Request struct {
       Name string `json:"username"`  // Matches JSON key
   }
   ```

3. **Wrong tag type for source**
   ```go
   // Binding from query parameters
   type Request struct {
       Name string `json:"name"`  // Wrong - should be `query:"name"`
   }
   
   // Correct
   type Request struct {
       Name string `query:"name"`
   }
   ```

4. **Source doesn't contain the key**
   ```go
   // URL: ?page=1
   type Params struct {
       Page  int    `query:"page"`
       Limit int    `query:"limit"`  // Missing in URL
   }
   
   // Solution: Use default
   type Params struct {
       Page  int `query:"page" default:"1"`
       Limit int `query:"limit" default:"20"`
   }
   ```

### Type Conversion Errors

**Problem**: Error like "cannot unmarshal string into int".

**Solutions:**

1. **Check source data type**
   ```go
   // JSON: {"age": "30"}  <- string instead of number
   type User struct {
       Age int `json:"age"`
   }
   
   // Error: cannot unmarshal string into int
   ```
   
   **Fix**: Ensure JSON sends number: `{"age": 30}`

2. **Use string type and convert manually**
   ```go
   type User struct {
       AgeStr string `json:"age"`
   }
   
   user, err := binding.JSON[User](data)
   age, _ := strconv.Atoi(user.AgeStr)
   ```

3. **Register custom converter**
   ```go
   binder := binding.MustNew(
       binding.WithConverter[MyType](parseMyType),
   )
   ```

### Slice Not Parsing

**Problem**: Slice remains empty or has unexpected values

**Cause**: Wrong slice mode for input format

```go
// URL: ?tags=go,rust,python
type Params struct {
    Tags []string `query:"tags"`
}

// With default mode (SliceRepeat)
params, _ := binding.Query[Params](values)
// Result: Tags = ["go,rust,python"]  <- Wrong!
```

**Solution**: Use CSV mode
```go
params, err := binding.Query[Params](values,
    binding.WithSliceMode(binding.SliceCSV))
// Result: Tags = ["go", "rust", "python"]  <- Correct!
```

Or use repeated parameters:
```
// URL: ?tags=go&tags=rust&tags=python
params, _ := binding.Query[Params](values)  // Default mode works
```

### JSON Parsing Errors

**Problem**: "unexpected end of JSON input" or "invalid character"

**Causes:**

1. **Malformed JSON**
   ```json
   {"name": "test"  // Missing closing brace
   ```
   
   **Solution**: Validate JSON syntax

2. **Empty body**
   ```go
   // Body is empty but expecting JSON
   user, err := binding.JSON[User](r.Body)
   // Error: unexpected end of JSON input
   ```
   
   **Solution**: Check if body is empty first
   ```go
   body, err := io.ReadAll(r.Body)
   if len(body) == 0 {
       return errors.New("empty body")
   }
   user, err := binding.JSON[User](body)
   ```

3. **Body already consumed**
   ```go
   body, _ := io.ReadAll(r.Body)  // Consumes body
   // ... some code ...
   user, err := binding.JSON[User](r.Body)  // Error: body empty
   ```
   
   **Solution**: Restore body
   ```go
   body, _ := io.ReadAll(r.Body)
   r.Body = io.NopCloser(bytes.NewReader(body))
   user, err := binding.JSON[User](body)
   ```

### Unknown Field Errors

**Problem**: Error in strict mode for valid JSON

**Cause**: JSON contains fields not in struct

```go
// JSON: {"name": "alice", "extra": "field"}
type User struct {
    Name string `json:"name"`
}

user, err := binding.JSON[User](data, binding.WithStrictJSON())
// Error: json: unknown field "extra"
```

**Solutions:**

1. **Add field to struct**
   ```go
   type User struct {
       Name  string `json:"name"`
       Extra string `json:"extra"`
   }
   ```

2. **Remove strict mode**
   ```go
   user, err := binding.JSON[User](data)  // Ignores extra fields
   ```

3. **Use interface{} for unknown fields**
   ```go
   type User struct {
       Name  string                 `json:"name"`
       Extra map[string]interface{} `json:"-"`
   }
   ```

### Pointer vs Value Confusion

**Problem**: Can't distinguish between "not provided" and "zero value"

**Example:**
```go
type UpdateRequest struct {
    Age int `json:"age"`
}

// JSON: {"age": 0}
// Can't tell if: 1) User wants to set age to 0, or 2) Field not provided
```

**Solution**: Use pointers
```go
type UpdateRequest struct {
    Age *int `json:"age"`
}

// JSON: {"age": 0}      -> Age = &0 (explicitly set to zero)
// JSON: {}              -> Age = nil (not provided)
// JSON: {"age": null}   -> Age = nil (explicitly null)
```

### Default Values Not Applied

**Problem**: Default value doesn't work

**Cause**: Defaults only apply when field is missing, not for zero values

```go
type Params struct {
    Page int `query:"page" default:"1"`
}

// URL: ?page=0
params, _ := binding.Query[Params](values)
// Result: Page = 0 (not 1, because 0 was provided)
```

**Solution**: Use pointer to distinguish nil from zero
```go
type Params struct {
    Page *int `query:"page" default:"1"`
}

// URL: ?page=0  -> Page = &0
// URL: (no page) -> Page = &1 (default applied)
```

### Nested Struct Not Binding

**Problem**: Nested struct fields remain zero

**Example:**
```go
// JSON: {"user": {"name": "alice", "age": 30}}
type Request struct {
    User struct {
        Name string `json:"name"`
        Age  int    `json:"age"`
    } `json:"user"`
}

req, err := binding.JSON[Request](data)
// Works correctly
```

For query parameters, use dot notation:
```go
// URL: ?user.name=alice&user.age=30
type Request struct {
    User struct {
        Name string `query:"user.name"`
        Age  int    `query:"user.age"`
    }
}
```

### Time Parsing Errors

**Problem**: "parsing time ... as ...: cannot parse"

**Cause**: Time format doesn't match any default layouts

```go
// JSON: {"created": "01/02/2006"}
type Request struct {
    Created time.Time `json:"created"`
}
// Error: parsing time "01/02/2006"
```

**Solution**: Add custom time layout
```go
binder := binding.MustNew(
    binding.WithTimeLayouts(
        append(binding.DefaultTimeLayouts, "01/02/2006")...,
    ),
)

req, err := binder.JSON[Request](data)
```

### Memory Issues

**Problem**: Out of memory or slow performance

**Causes:**

1. **Large payloads without limits**
   ```go
   // No limit - vulnerable to memory attack
   user, err := binding.JSON[User](r.Body)
   ```
   
   **Solution**: Set size limits
   ```go
   user, err := binding.JSON[User](r.Body,
       binding.WithMaxBytes(1024*1024),  // 1MB limit
       binding.WithMaxSliceLen(1000),
       binding.WithMaxMapSize(500),
   )
   ```

2. **Not using streaming for large data**
   ```go
   // Bad - loads entire body into memory
   body, _ := io.ReadAll(r.Body)
   user, err := binding.JSON[User](body)
   ```
   
   **Solution**: Stream from reader
   ```go
   user, err := binding.JSONReader[User](r.Body)
   ```

### Header Case Sensitivity

**Problem**: Header not binding

**Cause**: HTTP headers are case-insensitive but tag must match exact case

```go
// Header: x-api-key: secret
type Request struct {
    APIKey string `header:"X-API-Key"`  // Still works!
}

// Headers are matched case-insensitively
```

**Note**: The binding package handles case-insensitive header matching automatically.

### Multi-Source Precedence Issues

**Problem**: Wrong source value used

**Example:**
```go
// Query: ?user_id=1
// JSON: {"user_id": 2}
type Request struct {
    UserID int `query:"user_id" json:"user_id"`
}

req, err := binding.Bind[Request](
    binding.FromQuery(values),  // user_id = 1
    binding.FromJSON(body),     // user_id = 2 (overwrites!)
)
// Result: UserID = 2
```

**Solutions:**

1. **Change source order (last wins)**
   ```go
   req, err := binding.Bind[Request](
       binding.FromJSON(body),      // user_id = 2
       binding.FromQuery(values),   // user_id = 1 (overwrites!)
   )
   // Result: UserID = 1
   ```

2. **Use first-wins strategy**
   ```go
   req, err := binding.Bind[Request](
       binding.WithMergeStrategy(binding.MergeFirstWins),
       binding.FromQuery(values),  // user_id = 1 (wins!)
       binding.FromJSON(body),     // user_id = 2 (ignored)
   )
   // Result: UserID = 1
   ```

## Frequently Asked Questions

### Q: How do I validate required fields?

**A:** Use the `rivaas.dev/validation` package after binding:

```go
import "rivaas.dev/validation"

type Request struct {
    Name string `json:"name" validate:"required"`
    Age  int    `json:"age" validate:"required,min=18"`
}

req, err := binding.JSON[Request](data)
if err != nil {
    return err
}

// Validate after binding
if err := validation.Validate(req); err != nil {
    return err
}
```

### Q: Can I bind to non-struct types?

**A:** Yes, but only for certain types:

```go
// Array
type Batch []CreateUserRequest
batch, err := binding.JSON[Batch](data)

// Map
type Config map[string]string
config, err := binding.JSON[Config](data)

// Primitive (less useful)
var count int
err := binding.JSONTo([]byte("42"), &count)
```

### Q: How do I handle optional vs. required fields?

**A:** Combine binding with validation:

```go
type Request struct {
    Name  string  `json:"name" validate:"required"`
    Email *string `json:"email" validate:"omitempty,email"`
}

// Name is required (validation)
// Email is optional (pointer) but if provided must be valid (validation)
```

### Q: Can I use custom JSON field names?

**A:** Yes, use the `json` tag:

```go
type User struct {
    ID       int    `json:"user_id"`      // Maps to "user_id" in JSON
    FullName string `json:"full_name"`    // Maps to "full_name" in JSON
}
```

### Q: How do I bind from multiple query parameters to one field?

**A:** Use tag aliases:

```go
type Request struct {
    UserID int `query:"user_id,id,uid"`  // Accepts any of these
}

// Works with: ?user_id=123, ?id=123, or ?uid=123
```

### Q: Can I use both JSON and form binding?

**A:** Yes, use multi-source binding:

```go
type Request struct {
    Name string `json:"name" form:"name"`
}

req, err := binding.Bind[Request](
    binding.FromJSON(r.Body),
    binding.FromForm(r.Form),
)
```

### Q: How do I debug binding issues?

**A:** Use event hooks:

```go
binder := binding.MustNew(
    binding.WithEvents(binding.Events{
        FieldBound: func(name, tag string) {
            log.Printf("Bound %s from %s", name, tag)
        },
        UnknownField: func(name string) {
            log.Printf("Unknown field: %s", name)
        },
        Done: func(stats binding.Stats) {
            log.Printf("%d fields, %d errors, %v",
                stats.FieldsBound, stats.ErrorCount, stats.Duration)
        },
    }),
)
```

### Q: Is binding thread-safe?

**A:** Yes, all operations are thread-safe. The struct cache uses lock-free reads and synchronized writes.

### Q: How do I bind custom types?

**A:** Register a converter:

```go
import "github.com/google/uuid"

binder := binding.MustNew(
    binding.WithConverter[uuid.UUID](uuid.Parse),
)
```

Or implement `encoding.TextUnmarshaler`:

```go
type MyType string

func (m *MyType) UnmarshalText(text []byte) error {
    *m = MyType(string(text))
    return nil
}
```

### Q: Can I bind from environment variables?

**A:** Not directly, but you can create a custom getter:

```go
type EnvGetter struct{}

func (g *EnvGetter) Get(key string) string {
    return os.Getenv(key)
}

func (g *EnvGetter) GetAll(key string) []string {
    if val := os.Getenv(key); val != "" {
        return []string{val}
    }
    return nil
}

func (g *EnvGetter) Has(key string) bool {
    _, exists := os.LookupEnv(key)
    return exists
}

// Use with RawInto
config, err := binding.RawInto[Config](&EnvGetter{}, "env")
```

### Q: What's the difference between JSON and JSONReader?

**A:**

- `JSON`: Takes `[]byte`, entire data in memory
- `JSONReader`: Takes `io.Reader`, streams data

Use `JSONReader` for large payloads (>1MB) to reduce memory usage.

### Q: How do I handle API versioning?

**A:** Use different struct types per version:

```go
type CreateUserRequestV1 struct {
    Name string `json:"name"`
}

type CreateUserRequestV2 struct {
    FirstName string `json:"first_name"`
    LastName  string `json:"last_name"`
}

// Route to appropriate handler based on version header
```

## Debugging Strategies

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

log.Printf("Raw body: %s", string(body))
log.Printf("Content-Type: %s", r.Header.Get("Content-Type"))

req, err := binding.JSON[Request](r.Body)
```

### 3. Use Curl to Test

```bash
# Test JSON binding
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name":"alice","age":30}'

# Test query parameters
curl "http://localhost:8080/users?page=2&limit=50"

# Test headers
curl -H "X-API-Key: secret" http://localhost:8080/users
```

### 4. Write Unit Tests

```go
func TestBinding(t *testing.T) {
    payload := `{"name":"test","age":30}`
    
    user, err := binding.JSON[User]([]byte(payload))
    if err != nil {
        t.Fatalf("binding failed: %v", err)
    }
    
    if user.Name != "test" {
        t.Errorf("expected name=test, got %s", user.Name)
    }
}
```

## Getting Help

If you're still stuck:

1. **Check the examples**: [Binding Guide](/guides/binding/examples/)
2. **Review API docs**: [API Reference](../api-reference/)
3. **Search GitHub issues**: [rivaas-dev/rivaas/issues](https://github.com/rivaas-dev/rivaas/issues)
4. **Ask for help**: Open a new issue with:
   - Minimal reproducible example
   - Expected vs. actual behavior
   - Relevant logs/errors

## See Also

- **[API Reference](../api-reference/)** - Complete API documentation
- **[Options](../options/)** - Configuration options
- **[Performance](../performance/)** - Optimization tips
- **[Binding Guide](/guides/binding/)** - Step-by-step tutorials

---

For more examples and patterns, see the [Binding Guide](/guides/binding/).
