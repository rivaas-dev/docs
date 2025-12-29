---
title: "Advanced Usage"
description: "Advanced techniques including custom converters, binders, and extension patterns"
weight: 10
---

Explore advanced binding techniques for custom types, sources, and integration patterns.

## Custom Type Converters

Register converters for types not natively supported:

```go
import (
    "github.com/google/uuid"
    "github.com/shopspring/decimal"
    "rivaas.dev/binding"
)

binder := binding.MustNew(
    binding.WithConverter[uuid.UUID](uuid.Parse),
    binding.WithConverter[decimal.Decimal](decimal.NewFromString),
)

type Product struct {
    ID    uuid.UUID       `query:"id"`
    Price decimal.Decimal `query:"price"`
}

// URL: ?id=550e8400-e29b-41d4-a716-446655440000&price=19.99
product, err := binder.Query[Product](values)
```

### Converter Function Signature

```go
type ConverterFunc[T any] func(string) (T, error)

// Example: Custom email type
type Email string

func ParseEmail(s string) (Email, error) {
    if !strings.Contains(s, "@") {
        return "", errors.New("invalid email format")
    }
    return Email(s), nil
}

binder := binding.MustNew(
    binding.WithConverter[Email](ParseEmail),
)
```

## Custom ValueGetter

Implement custom data sources:

```go
// ValueGetter interface
type ValueGetter interface {
    Get(key string) string
    GetAll(key string) []string
    Has(key string) bool
}

// Example: Environment variables getter
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

// Usage
type Config struct {
    APIKey string `env:"API_KEY"`
    Port   int    `env:"PORT" default:"8080"`
}

getter := &EnvGetter{}
config, err := binding.RawInto[Config](getter, "env")
```

### GetterFunc Adapter

Use a function as a ValueGetter:

```go
getter := binding.GetterFunc(func(key string) ([]string, bool) {
    // Custom lookup logic
    if val, ok := customSource[key]; ok {
        return []string{val}, true
    }
    return nil, false
})

result, err := binding.Raw[MyStruct](getter, "custom")
```

### Map-Based Getters

Convenience helpers for simple sources:

```go
// Single-value map
data := map[string]string{"name": "Alice", "age": "30"}
getter := binding.MapGetter(data)
result, err := binding.RawInto[User](getter, "custom")

// Multi-value map (for slices)
multi := map[string][]string{
    "tags": {"go", "rust", "python"},
    "name": {"Alice"},
}
getter := binding.MultiMapGetter(multi)
result, err := binding.RawInto[User](getter, "custom")
```

## Reusable Binders

Create configured binders for shared settings:

```go
var AppBinder = binding.MustNew(
    // Type converters
    binding.WithConverter[uuid.UUID](uuid.Parse),
    binding.WithConverter[decimal.Decimal](decimal.NewFromString),
    
    // Time formats
    binding.WithTimeLayouts("2006-01-02", "01/02/2006"),
    
    // Security limits
    binding.WithMaxDepth(16),
    binding.WithMaxSliceLen(1000),
    binding.WithMaxMapSize(500),
    
    // Error handling
    binding.WithAllErrors(),
    
    // Observability
    binding.WithEvents(binding.Events{
        FieldBound: logFieldBound,
        UnknownField: logUnknownField,
        Done: logBindingStats,
    }),
)

// Use across handlers
func CreateUserHandler(w http.ResponseWriter, r *http.Request) {
    user, err := AppBinder.JSON[CreateUserRequest](r.Body)
    if err != nil {
        handleError(w, err)
        return
    }
    // ...
}
```

## Observability Hooks

Monitor binding operations:

```go
binder := binding.MustNew(
    binding.WithEvents(binding.Events{
        // Called when a field is successfully bound
        FieldBound: func(name, tag string) {
            metrics.Increment("binding.field.bound", "field:"+name, "source:"+tag)
        },
        
        // Called when an unknown field is encountered
        UnknownField: func(name string) {
            slog.Warn("Unknown field in request", "field", name)
            metrics.Increment("binding.field.unknown", "field:"+name)
        },
        
        // Called after binding completes
        Done: func(stats binding.Stats) {
            slog.Info("Binding completed",
                "fields_bound", stats.FieldsBound,
                "errors", stats.ErrorCount,
                "duration", stats.Duration,
            )
            
            metrics.Histogram("binding.duration", stats.Duration.Milliseconds())
            metrics.Gauge("binding.fields.bound", stats.FieldsBound)
        },
    }),
)
```

### Binding Stats

```go
type Stats struct {
    FieldsBound int           // Number of fields successfully bound
    ErrorCount  int           // Number of errors encountered
    Duration    time.Duration // Time taken for binding
}
```

## Custom Struct Tags

Extend binding with custom tag behavior:

```go
// Example: Custom "env" tag handler
type EnvTagHandler struct {
    prefix string
}

func (h *EnvTagHandler) Get(fieldName, tagValue string) (string, bool) {
    envKey := h.prefix + tagValue
    val, exists := os.LookupEnv(envKey)
    return val, exists
}

// Register custom tag handler
binder := binding.MustNew(
    binding.WithTagHandler("env", &EnvTagHandler{prefix: "APP_"}),
)

type Config struct {
    APIKey string `env:"API_KEY"`  // Looks up APP_API_KEY
    Port   int    `env:"PORT"`     // Looks up APP_PORT
}
```

## Streaming for Large Payloads

Use Reader variants for efficient memory usage:

```go
// Instead of reading entire body into memory:
// body, _ := io.ReadAll(r.Body)  // Bad for large payloads
// user, err := binding.JSON[User](body)

// Stream directly from reader:
user, err := binding.JSONReader[User](r.Body)  // Memory-efficient

// Also available for XML, YAML:
doc, err := binding.XMLReader[Document](r.Body)
config, err := yaml.YAMLReader[Config](r.Body)
```

## Nested Struct Binding

### Dot Notation for Query Parameters

```go
type SearchRequest struct {
    Query string `query:"q"`
    Filter struct {
        Category string `query:"filter.category"`
        MinPrice int    `query:"filter.min_price"`
        MaxPrice int    `query:"filter.max_price"`
        Tags     []string `query:"filter.tags"`
    }
}

// URL: ?q=laptop&filter.category=electronics&filter.min_price=100
params, err := binding.Query[SearchRequest](values)
```

### Embedded Structs

```go
type Timestamps struct {
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
    Timestamps  // Embedded - fields promoted
}

// JSON: {
//   "id": 1,
//   "name": "Alice",
//   "created_at": "2025-01-01T00:00:00Z",
//   "updated_at": "2025-01-01T12:00:00Z"
// }
```

## Multi-Source with Priority

Control precedence of multiple sources:

```go
type Request struct {
    UserID int    `query:"user_id" json:"user_id" header:"X-User-ID"`
    Token  string `header:"Authorization" query:"token"`
}

// Last source wins (default)
req, err := binding.Bind[Request](
    binding.FromQuery(r.URL.Query()),  // Lowest priority
    binding.FromJSON(r.Body),          // Medium priority
    binding.FromHeader(r.Header),      // Highest priority
)

// First source wins (explicit)
req, err := binding.Bind[Request](
    binding.WithMergeStrategy(binding.MergeFirstWins),
    binding.FromHeader(r.Header),      // Highest priority
    binding.FromJSON(r.Body),          // Medium priority
    binding.FromQuery(r.URL.Query()),  // Lowest priority
)
```

## Conditional Binding

Bind based on request properties:

```go
func BindRequest[T any](r *http.Request) (T, error) {
    sources := []binding.Source{}
    
    // Always include query params
    sources = append(sources, binding.FromQuery(r.URL.Query()))
    
    // Include body only for certain methods
    if r.Method == "POST" || r.Method == "PUT" || r.Method == "PATCH" {
        contentType := r.Header.Get("Content-Type")
        
        switch {
        case strings.Contains(contentType, "application/json"):
            sources = append(sources, binding.FromJSON(r.Body))
        case strings.Contains(contentType, "application/x-www-form-urlencoded"):
            sources = append(sources, binding.FromForm(r.Body))
        case strings.Contains(contentType, "application/xml"):
            sources = append(sources, binding.FromXML(r.Body))
        }
    }
    
    // Always include headers
    sources = append(sources, binding.FromHeader(r.Header))
    
    return binding.Bind[T](sources...)
}
```

## Partial Updates

Handle PATCH requests with optional fields:

```go
type UpdateUserRequest struct {
    Name     *string `json:"name"`      // nil = don't update
    Email    *string `json:"email"`     // nil = don't update
    Age      *int    `json:"age"`       // nil = don't update
    Active   *bool   `json:"active"`    // nil = don't update
}

func UpdateUser(w http.ResponseWriter, r *http.Request) {
    update, err := binding.JSON[UpdateUserRequest](r.Body)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Only update fields that were provided
    if update.Name != nil {
        user.Name = *update.Name
    }
    if update.Email != nil {
        user.Email = *update.Email
    }
    if update.Age != nil {
        user.Age = *update.Age
    }
    if update.Active != nil {
        user.Active = *update.Active
    }
    
    saveUser(user)
}
```

## Middleware Integration

### Generic Binding Middleware

```go
func BindMiddleware[T any](next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        req, err := binding.JSON[T](r.Body)
        if err != nil {
            http.Error(w, err.Error(), http.StatusBadRequest)
            return
        }
        
        // Store in context
        ctx := context.WithValue(r.Context(), "request", req)
        next(w, r.WithContext(ctx))
    }
}

// Usage
http.HandleFunc("/users",
    BindMiddleware[CreateUserRequest](CreateUserHandler))

func CreateUserHandler(w http.ResponseWriter, r *http.Request) {
    req := r.Context().Value("request").(CreateUserRequest)
    // Use req...
}
```

### With Validation

```go
func BindAndValidate[T any](next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        req, err := binding.JSON[T](r.Body)
        if err != nil {
            http.Error(w, err.Error(), http.StatusBadRequest)
            return
        }
        
        // Validate
        if err := validation.Validate(req); err != nil {
            http.Error(w, err.Error(), http.StatusUnprocessableEntity)
            return
        }
        
        ctx := context.WithValue(r.Context(), "request", req)
        next(w, r.WithContext(ctx))
    }
}
```

## Batch Binding

Process multiple items with error collection:

```go
type BatchRequest []CreateUserRequest

func ProcessBatch(w http.ResponseWriter, r *http.Request) {
    batch, err := binding.JSON[BatchRequest](r.Body)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    results := make([]Result, len(batch))
    errors := make([]error, 0)
    
    for i, item := range batch {
        user, err := createUser(item)
        if err != nil {
            errors = append(errors, fmt.Errorf("item %d: %w", i, err))
            continue
        }
        results[i] = Result{Success: true, User: user}
    }
    
    response := BatchResponse{
        Results: results,
        Errors:  errors,
    }
    
    json.NewEncoder(w).Encode(response)
}
```

## TextUnmarshaler Integration

Implement custom text unmarshaling:

```go
type Status string

const (
    StatusActive   Status = "active"
    StatusInactive Status = "inactive"
    StatusPending  Status = "pending"
)

func (s *Status) UnmarshalText(text []byte) error {
    str := string(text)
    switch str {
    case "active", "inactive", "pending":
        *s = Status(str)
        return nil
    default:
        return fmt.Errorf("invalid status: %s", str)
    }
}

type User struct {
    ID     int    `json:"id"`
    Name   string `json:"name"`
    Status Status `json:"status"` // Automatically uses UnmarshalText
}
```

## Performance Optimization

### Pre-allocate Slices

```go
type Response struct {
    Items []Item `json:"items"`
}

// With capacity hint
items := make([]Item, 0, expectedSize)
// Bind into pre-allocated slice
```

### Reuse Buffers

```go
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func bindWithPool(r io.Reader) (User, error) {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()
    
    io.Copy(buf, r)
    return binding.JSON[User](buf.Bytes())
}
```

### Avoid Reflection in Hot Paths

```go
// Cache binder instance
var binder = binding.MustNew(
    binding.WithConverter[uuid.UUID](uuid.Parse),
)

// Struct info is cached automatically after first use
// Subsequent bindings have minimal overhead
```

## Testing Helpers

### Mock Requests

```go
func TestBindingJSON(t *testing.T) {
    payload := `{"name": "Alice", "age": 30}`
    body := io.NopCloser(strings.NewReader(payload))
    
    user, err := binding.JSON[User](body)
    if err != nil {
        t.Fatal(err)
    }
    
    if user.Name != "Alice" {
        t.Errorf("expected Alice, got %s", user.Name)
    }
}
```

### Test Different Sources

```go
func TestMultiSource(t *testing.T) {
    req, err := binding.Bind[Request](
        binding.FromQuery(url.Values{
            "page": []string{"1"},
        }),
        binding.FromJSON([]byte(`{"name":"test"}`)),
        binding.FromHeader(http.Header{
            "X-API-Key": []string{"secret"},
        }),
    )
    
    if err != nil {
        t.Fatal(err)
    }
    
    // Assertions...
}
```

## Integration Patterns

### With Rivaas Router

```go
import "rivaas.dev/router"

r := router.New()

r.POST("/users", func(c *router.Context) error {
    user, err := binding.JSON[CreateUserRequest](c.Request().Body)
    if err != nil {
        return c.JSON(http.StatusBadRequest, err)
    }
    
    created := createUser(user)
    return c.JSON(http.StatusCreated, created)
})
```

### With Rivaas App

```go
import "rivaas.dev/app"

a := app.MustNew()

a.POST("/users", func(c *app.Context) error {
    var user CreateUserRequest
    if err := c.Bind(&user); err != nil {
        return err  // Automatically handled
    }
    
    created := createUser(user)
    return c.JSON(http.StatusCreated, created)
})
```

## Next Steps

- Review [Examples](../examples/) for complete patterns
- See [Performance](/reference/packages/binding/performance/) for optimization tips
- Check [Troubleshooting](/reference/packages/binding/troubleshooting/) for common issues
- Explore [API Reference](/reference/packages/binding/api-reference/) for all features

For complete API documentation, see [API Reference](/reference/packages/binding/api-reference/).
