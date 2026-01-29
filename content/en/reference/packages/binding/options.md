---
title: "Options"
description: "Complete reference for all configuration options"
keywords:
  - binding options
  - configuration
  - options reference
  - functional options
weight: 2
---

Comprehensive reference for all configuration options available in the binding package.

## Option Type

```go
type Option func(*Config)
```

Options configure binding behavior. They can be passed to:
- Package-level functions like `binding.JSON[T](data, opts...)`.
- `Binder` constructor like `binding.MustNew(opts...)`.
- `Binder` methods like `binder.JSON[T](data, opts...)`.

## Security Limits

### WithMaxDepth

```go
func WithMaxDepth(depth int) Option
```

Sets maximum struct nesting depth to prevent stack overflow from deeply nested structures.

**Default**: 32

**Example:**
```go
user, err := binding.JSON[User](data, binding.WithMaxDepth(16))
```

**Use Cases:**
- Protect against malicious deeply nested JSON.
- Limit resource usage.
- Prevent stack overflow.

### WithMaxSliceLen

```go
func WithMaxSliceLen(length int) Option
```

Sets maximum slice length to prevent memory exhaustion from large arrays.

**Default**: 10,000

**Example:**
```go
params, err := binding.Query[Params](values, binding.WithMaxSliceLen(1000))
```

**Use Cases:**
- Protect against memory attacks
- Limit array sizes
- Control memory allocation

### WithMaxMapSize

```go
func WithMaxMapSize(size int) Option
```

Sets maximum map size to prevent memory exhaustion from large objects.

**Default**: 1,000

**Example:**
```go
config, err := binding.JSON[Config](data, binding.WithMaxMapSize(500))
```

**Use Cases:**
- Protect against memory attacks.
- Limit object sizes.
- Control memory allocation.

## Unknown Field Handling

### WithStrictJSON

```go
func WithStrictJSON() Option
```

Convenience function that sets `WithUnknownFields(UnknownError)`. Fails binding if JSON contains fields not in the struct.

**Example:**
```go
user, err := binding.JSON[User](data, binding.WithStrictJSON())
if err != nil {
    var unknownErr *binding.UnknownFieldError
    if errors.As(err, &unknownErr) {
        log.Printf("Unknown fields: %v", unknownErr.Fields)
    }
}
```

**Use Cases:**
- API versioning
- Catch typos in field names
- Enforce strict contracts

### WithUnknownFields

```go
func WithUnknownFields(mode UnknownMode) Option

// Modes
const (
    UnknownIgnore UnknownMode = iota // Ignore unknown fields (default)
    UnknownWarn                       // Log warnings
    UnknownError                      // Return error
)
```

Controls how unknown fields are handled.

**Example:**
```go
user, err := binding.JSON[User](data,
    binding.WithUnknownFields(binding.UnknownWarn))
```

**Modes:**
- `UnknownIgnore`: Silently ignore (default, most flexible)
- `UnknownWarn`: Log warnings (for debugging)
- `UnknownError`: Fail binding (strict contracts)

## Slice Parsing

### WithSliceMode

```go
func WithSliceMode(mode SliceMode) Option

// Modes
const (
    SliceRepeat SliceMode = iota // ?tags=a&tags=b (default)
    SliceCSV                     // ?tags=a,b,c
)
```

Controls how slices are parsed from query/form values.

**Example:**
```go
// URL: ?tags=go,rust,python
params, err := binding.Query[Params](values,
    binding.WithSliceMode(binding.SliceCSV))
```

**Modes:**
- `SliceRepeat`: Repeated parameters (default, standard HTTP)
- `SliceCSV`: Comma-separated values (more compact)

## Error Handling

### WithAllErrors

```go
func WithAllErrors() Option
```

Collects all binding errors instead of failing on the first error.

**Example:**
```go
user, err := binding.JSON[User](data, binding.WithAllErrors())
if err != nil {
    var multi *binding.MultiError
    if errors.As(err, &multi) {
        for _, e := range multi.Errors {
            log.Printf("Field %s: %v", e.Field, e.Err)
        }
    }
}
```

**Use Cases:**
- Show all validation errors to user
- Debugging
- Comprehensive error reporting

## Type Conversion

### WithConverter

```go
func WithConverter[T any](fn func(string) (T, error)) Option
```

Registers a custom type converter for type `T`.

**Example:**
```go
import "github.com/google/uuid"

binder := binding.MustNew(
    binding.WithConverter[uuid.UUID](uuid.Parse),
)

type User struct {
    ID uuid.UUID `query:"id"`
}

user, err := binder.Query[User](values)
```

**Use Cases:**
- Custom types (UUID, decimal, etc.)
- Domain-specific types
- Third-party types

### Converter Factories

The binding package provides ready-to-use converter factories for common patterns. These are functions that return converter functions you can use with `WithConverter`.

#### TimeConverter

```go
func TimeConverter(layouts ...string) func(string) (time.Time, error)
```

Creates a converter that parses time strings using the provided date formats. Tries each format in order until one succeeds.

**Example:**
```go
binder := binding.MustNew(
    // Try ISO format first, then US format
    binding.WithConverter(binding.TimeConverter(
        "2006-01-02",
        "01/02/2006",
    )),
)

type Event struct {
    Date time.Time `query:"date"`
}

// Works with: ?date=2026-01-28 or ?date=01/28/2026
event, err := binder.Query[Event](values)
```

**Common layouts:**
- `"2006-01-02"` - ISO date (YYYY-MM-DD)
- `"01/02/2006"` - US format (MM/DD/YYYY)
- `"02-Jan-2006"` - Short month name
- `"2006-01-02 15:04:05"` - DateTime with seconds

#### DurationConverter

```go
func DurationConverter(aliases map[string]time.Duration) func(string) (time.Duration, error)
```

Creates a converter that parses duration strings. Supports both standard Go duration format (like `"30m"`, `"2h30m"`) and custom aliases you define.

**Example:**
```go
binder := binding.MustNew(
    binding.WithConverter(binding.DurationConverter(map[string]time.Duration{
        "quick":   5 * time.Minute,
        "normal":  30 * time.Minute,
        "long":    2 * time.Hour,
    })),
)

type Config struct {
    Timeout time.Duration `query:"timeout"`
}

// All of these work:
// ?timeout=quick      → 5 minutes
// ?timeout=30m        → 30 minutes
// ?timeout=2h30m      → 2 hours 30 minutes
config, err := binder.Query[Config](values)
```

**Use Cases:**
- User-friendly duration aliases
- Cache TTL presets
- Timeout configurations
- Fallback to standard durations

#### EnumConverter

```go
func EnumConverter[T ~string](allowed ...T) func(string) (T, error)
```

Creates a converter that validates string values against a set of allowed options. Matching is case-insensitive.

**Example:**
```go
type Status string

const (
    StatusActive   Status = "active"
    StatusPending  Status = "pending"
    StatusDisabled Status = "disabled"
)

binder := binding.MustNew(
    binding.WithConverter(binding.EnumConverter(
        StatusActive,
        StatusPending,
        StatusDisabled,
    )),
)

type User struct {
    Status Status `query:"status"`
}

// ?status=active   ✓ OK
// ?status=ACTIVE   ✓ OK (case-insensitive)
// ?status=invalid  ✗ Error: must be one of: active, pending, disabled
user, err := binder.Query[User](values)
```

**Use Cases:**
- String enums with validation
- Status fields
- Category/type fields
- Prevent invalid values

#### BoolConverter

```go
func BoolConverter(truthy, falsy []string) func(string) (bool, error)
```

Creates a converter that parses boolean values using custom truthy and falsy strings. Matching is case-insensitive.

**Example:**
```go
binder := binding.MustNew(
    binding.WithConverter(binding.BoolConverter(
        []string{"yes", "on", "enabled", "1"},   // truthy
        []string{"no", "off", "disabled", "0"},  // falsy
    )),
)

type Settings struct {
    Notifications bool `query:"notifications"`
}

// ?notifications=yes       → true
// ?notifications=enabled   → true
// ?notifications=OFF       → false (case-insensitive)
// ?notifications=0         → false
settings, err := binder.Query[Settings](values)
```

**Use Cases:**
- User-friendly boolean inputs
- Feature flags
- Toggle settings
- Forms with yes/no options

### Combining Converters

You can use multiple converters together, including both factories and custom converters:

```go
binder := binding.MustNew(
    // Time with custom formats
    binding.WithConverter(binding.TimeConverter("01/02/2006", "2006-01-02")),
    
    // Duration with friendly names
    binding.WithConverter(binding.DurationConverter(map[string]time.Duration{
        "short": 5 * time.Minute,
        "long":  1 * time.Hour,
    })),
    
    // Status enum
    binding.WithConverter(binding.EnumConverter("active", "pending", "disabled")),
    
    // Boolean with custom values
    binding.WithConverter(binding.BoolConverter(
        []string{"yes", "on"},
        []string{"no", "off"},
    )),
    
    // Third-party types
    binding.WithConverter[uuid.UUID](uuid.Parse),
    binding.WithConverter[decimal.Decimal](decimal.NewFromString),
)
```

### WithTimeLayouts

```go
func WithTimeLayouts(layouts ...string) Option
```

Sets custom time parsing layouts. Replaces default layouts.

**Default Layouts**: See `binding.DefaultTimeLayouts`

**Example:**
```go
binder := binding.MustNew(
    binding.WithTimeLayouts(
        "2006-01-02",           // Date only
        "01/02/2006",           // US format
        "2006-01-02 15:04:05",  // DateTime
    ),
)
```

**Tip**: Extend defaults instead of replacing:
```go
binder := binding.MustNew(
    binding.WithTimeLayouts(
        append(binding.DefaultTimeLayouts, "01/02/2006", "02-Jan-2006")...,
    ),
)
```

## Observability

### WithEvents

```go
func WithEvents(events Events) Option

type Events struct {
    FieldBound   func(name, tag string)
    UnknownField func(name string)
    Done         func(stats Stats)
}

type Stats struct {
    FieldsBound int
    ErrorCount  int
    Duration    time.Duration
}
```

Registers event handlers for observing binding operations.

**Example:**
```go
binder := binding.MustNew(
    binding.WithEvents(binding.Events{
        FieldBound: func(name, tag string) {
            metrics.Increment("binding.field.bound",
                "field:"+name, "source:"+tag)
        },
        UnknownField: func(name string) {
            log.Warn("Unknown field", "name", name)
        },
        Done: func(stats binding.Stats) {
            metrics.Histogram("binding.duration",
                stats.Duration.Milliseconds())
            metrics.Gauge("binding.fields", stats.FieldsBound)
        },
    }),
)
```

**Use Cases:**
- Metrics collection
- Debugging
- Performance monitoring
- Audit logging

## Multi-Source Options

### WithMergeStrategy

```go
func WithMergeStrategy(strategy MergeStrategy) Option

// Strategies
const (
    MergeLastWins  MergeStrategy = iota // Last source wins (default)
    MergeFirstWins                       // First source wins
)
```

Controls precedence when binding from multiple sources.

**Example:**
```go
// First source wins
req, err := binding.Bind[Request](
    binding.WithMergeStrategy(binding.MergeFirstWins),
    binding.FromHeader(r.Header),      // Highest priority
    binding.FromQuery(r.URL.Query()),  // Lower priority
)
```

**Strategies:**
- `MergeLastWins`: Last source overwrites (default)
- `MergeFirstWins`: First non-empty value wins

## JSON-Specific Options

### WithDisallowUnknownFields

```go
func WithDisallowUnknownFields() Option
```

Equivalent to `WithStrictJSON()`. Provided for clarity when explicitly disallowing unknown fields.

**Example:**
```go
user, err := binding.JSON[User](data,
    binding.WithDisallowUnknownFields())
```

### WithMaxBytes

```go
func WithMaxBytes(bytes int64) Option
```

Limits the size of JSON/XML data to prevent memory exhaustion.

**Example:**
```go
user, err := binding.JSON[User](data,
    binding.WithMaxBytes(1024 * 1024)) // 1MB limit
```

**Use Cases:**
- Protect against large payloads
- API rate limiting
- Resource management

## Custom Options

### WithTagHandler

```go
func WithTagHandler(tagName string, handler TagHandler) Option

type TagHandler interface {
    Get(fieldName, tagValue string) (string, bool)
}
```

Registers a custom struct tag handler.

**Example:**
```go
type EnvTagHandler struct {
    prefix string
}

func (h *EnvTagHandler) Get(fieldName, tagValue string) (string, bool) {
    envKey := h.prefix + tagValue
    val, exists := os.LookupEnv(envKey)
    return val, exists
}

binder := binding.MustNew(
    binding.WithTagHandler("env", &EnvTagHandler{prefix: "APP_"}),
)

type Config struct {
    APIKey string `env:"API_KEY"`  // Looks up APP_API_KEY
}
```

## Option Combinations

### Production Configuration

```go
var ProductionBinder = binding.MustNew(
    // Security
    binding.WithMaxDepth(16),
    binding.WithMaxSliceLen(1000),
    binding.WithMaxMapSize(500),
    binding.WithMaxBytes(10 * 1024 * 1024), // 10MB
    
    // Strict validation
    binding.WithStrictJSON(),
    
    // Custom types
    binding.WithConverter[uuid.UUID](uuid.Parse),
    binding.WithConverter[decimal.Decimal](decimal.NewFromString),
    
    // Time formats
    binding.WithTimeLayouts(append(
        binding.DefaultTimeLayouts,
        "2006-01-02",
        "01/02/2006",
    )...),
    
    // Observability
    binding.WithEvents(binding.Events{
        FieldBound:   logFieldBound,
        UnknownField: logUnknownField,
        Done:         recordMetrics,
    }),
)
```

### Development Configuration

```go
var DevBinder = binding.MustNew(
    // Lenient limits
    binding.WithMaxDepth(32),
    binding.WithMaxSliceLen(10000),
    
    // Warnings instead of errors
    binding.WithUnknownFields(binding.UnknownWarn),
    
    // Collect all errors for debugging
    binding.WithAllErrors(),
    
    // Verbose logging
    binding.WithEvents(binding.Events{
        FieldBound: func(name, tag string) {
            log.Printf("[DEBUG] Bound %s from %s", name, tag)
        },
        UnknownField: func(name string) {
            log.Printf("[WARN] Unknown field: %s", name)
        },
        Done: func(stats binding.Stats) {
            log.Printf("[DEBUG] Binding: %d fields, %d errors, %v",
                stats.FieldsBound, stats.ErrorCount, stats.Duration)
        },
    }),
)
```

### Testing Configuration

```go
var TestBinder = binding.MustNew(
    // Strict validation
    binding.WithStrictJSON(),
    
    // Fail fast
    // (don't use WithAllErrors in tests)
    
    // Smaller limits for test data
    binding.WithMaxDepth(8),
    binding.WithMaxSliceLen(100),
)
```

## Option Precedence

When options are provided to both `MustNew()` and individual functions:

1. Function-level options override binder-level options
2. Options are applied in order (last wins for same option)

**Example:**
```go
binder := binding.MustNew(
    binding.WithMaxDepth(32),  // Binder default
)

// This call uses maxDepth=16 (overrides binder default)
user, err := binder.JSON[User](data,
    binding.WithMaxDepth(16))
```

## Best Practices

### 1. Use Binders for Shared Configuration

```go
// Good - shared configuration
var AppBinder = binding.MustNew(
    binding.WithConverter[uuid.UUID](uuid.Parse),
    binding.WithMaxDepth(16),
)

func Handler1(r *http.Request) {
    user, err := AppBinder.JSON[User](r.Body)
}

func Handler2(r *http.Request) {
    params, err := AppBinder.Query[Params](r.URL.Query())
}
```

### 2. Set Security Limits

```go
// Good - protect against attacks
user, err := binding.JSON[User](data,
    binding.WithMaxDepth(16),
    binding.WithMaxSliceLen(1000),
    binding.WithMaxBytes(1024*1024),
)
```

### 3. Use Strict Mode for APIs

```go
// Good - catch client errors early
user, err := binding.JSON[User](data, binding.WithStrictJSON())
```

### 4. Collect All Errors for Forms

```go
// Good - show all validation errors to user
form, err := binding.Form[Form](r.PostForm, binding.WithAllErrors())
if err != nil {
    var multi *binding.MultiError
    if errors.As(err, &multi) {
        // Show all errors to user
        for _, e := range multi.Errors {
            addError(e.Field, e.Err.Error())
        }
    }
}
```

## See Also

- **[API Reference](../api-reference/)** - Core functions and types
- **[Performance](../performance/)** - Optimization guide
- **[Troubleshooting](../troubleshooting/)** - Common issues

For usage examples, see the [Binding Guide](/guides/binding/).
