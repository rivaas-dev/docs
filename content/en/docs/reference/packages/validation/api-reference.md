---
title: "API Reference"
description: "Core types, functions, and methods"
keywords:
  - validation api
  - validation reference
  - api documentation
  - type reference
weight: 1
---

Complete API reference for the validation package's core types, functions, and methods.

## Package-Level Functions

### Validate

```go
func Validate(ctx context.Context, v any, opts ...Option) error
```

Validates a value using the default engine. Returns `nil` if validation passes, or `*Error` if validation fails.

**Parameters:**
- `ctx` - Context passed to `ValidatorWithContext` implementations.
- `v` - The value to validate. Typically a pointer to a struct.
- `opts` - Optional per-call configuration options.

**Returns:**
- `nil` on success.
- `*Error` with field-level errors on failure.

**Example:**

```go
err := validation.Validate(ctx, &user)
if err != nil {
    var verr *validation.Error
    if errors.As(err, &verr) {
        // Handle validation errors
    }
}
```

### ValidatePartial

```go
func ValidatePartial(ctx context.Context, v any, pm PresenceMap, opts ...Option) error
```

Validates only fields present in the `PresenceMap`. Useful for PATCH requests where only provided fields should be validated.

**Parameters:**
- `ctx` - Context for validation.
- `v` - The value to validate.
- `pm` - Map of present fields.
- `opts` - Optional configuration options.

**Example:**

```go
presence, _ := validation.ComputePresence(rawJSON)
err := validation.ValidatePartial(ctx, &req, presence)
```

### ComputePresence

```go
func ComputePresence(rawJSON []byte) (PresenceMap, error)
```

Analyzes raw JSON and returns a map of present field paths. Used for partial validation.

**Parameters:**
- `rawJSON` - Raw JSON bytes.

**Returns:**
- `PresenceMap` - Map of field paths to `true`.
- `error` - If JSON is invalid.

**Example:**

```go
rawJSON := []byte(`{"email": "test@example.com", "age": 25}`)
presence, err := validation.ComputePresence(rawJSON)
// presence = {"email": true, "age": true}
```

## Validator Interface

Types that implement the [Validator](https://pkg.go.dev/rivaas.dev/validation#Validator) interface are validated by calling their `Validate() error` method. The config package uses the same contract ([config.Validator](https://pkg.go.dev/rivaas.dev/config#Validator)); one implementation works for both.

```go
type Validator interface {
    Validate() error
}
```

## Engine Type

The [Engine](https://pkg.go.dev/rivaas.dev/validation#Engine) is the validation runner returned by [New](https://pkg.go.dev/rivaas.dev/validation#New) and [MustNew](https://pkg.go.dev/rivaas.dev/validation#MustNew). It holds configuration and runs validation (struct tags, JSON Schema, or custom [Validator](https://pkg.go.dev/rivaas.dev/validation#Validator) / [ValidatorWithContext](https://pkg.go.dev/rivaas.dev/validation#ValidatorWithContext) implementations).

### New

```go
func New(opts ...Option) (*Engine, error)
```

Creates a new [Engine](https://pkg.go.dev/rivaas.dev/validation#Engine) with the given options. Returns an error if configuration is invalid.

**Parameters:**
- `opts` - Configuration options

**Returns:**
- `*Engine` - Configured engine instance
- `error` - If configuration is invalid

**Example:**

```go
engine, err := validation.New(
    validation.WithMaxErrors(10),
    validation.WithRedactor(redactor),
)
if err != nil {
    return fmt.Errorf("failed to create engine: %w", err)
}
```

### MustNew

```go
func MustNew(opts ...Option) *Engine
```

Creates a new [Engine](https://pkg.go.dev/rivaas.dev/validation#Engine) with the given options. Panics if configuration is invalid. Use in `main()` or `init()` where panic on startup is acceptable.

**Parameters:**
- `opts` - Configuration options

**Returns:**
- `*Engine` - Configured engine instance

**Panics:**
- If configuration is invalid

**Example:**

```go
var engine = validation.MustNew(
    validation.WithMaxErrors(10),
    validation.WithRedactor(redactor),
)
```

### Engine.Validate

```go
func (v *Engine) Validate(ctx context.Context, val any, opts ...Option) error
```

Validates a value using this engine's configuration. Per-call options override the engine's base configuration.

**Parameters:**
- `ctx` - Context for validation
- `val` - The value to validate
- `opts` - Optional per-call configuration overrides

**Returns:**
- `nil` on success
- `*Error` on failure

**Example:**

```go
err := engine.Validate(ctx, &user,
    validation.WithMaxErrors(5), // Override base config
)
```

### Engine.ValidatePartial

```go
func (v *Engine) ValidatePartial(ctx context.Context, val any, pm PresenceMap, opts ...Option) error
```

Validates only fields present in the `PresenceMap` using this engine's configuration.

**Parameters:**
- `ctx` - Context for validation
- `val` - The value to validate
- `pm` - Map of present fields
- `opts` - Optional configuration overrides

**Returns:**
- `nil` on success
- `*Error` on failure

## Error Types

### Error

```go
type Error struct {
    Fields    []FieldError
    Truncated bool
}
```

Main validation error type containing multiple field errors.

**Fields:**
- `Fields` - Slice of field-level errors
- `Truncated` - True if errors were truncated due to `maxErrors` limit

**Methods:**

```go
func (e Error) Error() string
func (e Error) Unwrap() error                    // Returns ErrValidation
func (e Error) HTTPStatus() int                  // Returns 422
func (e Error) Code() string                     // Returns "validation_error"
func (e Error) Details() any                     // Returns Fields
func (e *Error) Add(path, code, message string, meta map[string]any)
func (e *Error) AddError(err error)
func (e Error) HasErrors() bool
func (e Error) HasCode(code string) bool
func (e Error) Has(path string) bool
func (e Error) GetField(path string) *FieldError
func (e *Error) Sort()
```

**Example:**

```go
var verr *validation.Error
if errors.As(err, &verr) {
    fmt.Printf("Found %d errors\n", len(verr.Fields))
    
    if verr.Truncated {
        fmt.Println("(more errors exist)")
    }
    
    if verr.Has("email") {
        fmt.Println("Email field has an error")
    }
}
```

### FieldError

```go
type FieldError struct {
    Path    string
    Code    string
    Message string
    Meta    map[string]any
}
```

Individual field validation error.

**Fields:**
- `Path` - JSON path to the field (e.g., `"items.2.price"`)
- `Code` - Stable error code (e.g., `"tag.required"`, `"schema.type"`)
- `Message` - Human-readable error message
- `Meta` - Additional metadata (tag, param, value, etc.)

**Methods:**

```go
func (e FieldError) Error() string    // Returns "path: message"
func (e FieldError) Unwrap() error    // Returns ErrValidation
func (e FieldError) HTTPStatus() int  // Returns 422
```

**Example:**

```go
for _, fieldErr := range verr.Fields {
    fmt.Printf("Field: %s\n", fieldErr.Path)
    fmt.Printf("Code: %s\n", fieldErr.Code)
    fmt.Printf("Message: %s\n", fieldErr.Message)
    
    if tag, ok := fieldErr.Meta["tag"].(string); ok {
        fmt.Printf("Tag: %s\n", tag)
    }
}
```

## PresenceMap Type

```go
type PresenceMap map[string]bool
```

Tracks which fields are present in a request body. Keys are JSON field paths.

**Methods:**

```go
func (pm PresenceMap) Has(path string) bool
func (pm PresenceMap) HasPrefix(prefix string) bool
func (pm PresenceMap) LeafPaths() []string
```

**Example:**

```go
presence := PresenceMap{
    "email": true,
    "address": true,
    "address.city": true,
}

if presence.Has("email") {
    // Email was provided
}

if presence.HasPrefix("address") {
    // At least one address field was provided
}

leaves := presence.LeafPaths()
// Returns: ["email", "address.city"]
// (address is excluded as it has children)
```

## Strategy Type

```go
type Strategy int

const (
    StrategyAuto Strategy = iota
    StrategyTags
    StrategyJSONSchema
    StrategyInterface
)
```

Defines the validation approach to use.

**Constants:**
- `StrategyAuto` - Automatically select best strategy (default)
- `StrategyTags` - Use struct tag validation
- `StrategyJSONSchema` - Use JSON Schema validation
- `StrategyInterface` - Use interface methods (`Validate()` / `ValidateContext()`)

**Example:**

```go
err := validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyTags),
)
```

## Sentinel Errors

These are the **single source of truth** for validation sentinels. When handling errors from the router (e.g. `c.Bind` or `c.Validate`), use this package for `errors.Is` and `errors.As` checks.

```go
var (
    ErrValidation                 = errors.New("validation")
    ErrCannotValidateNilValue     = errors.New("cannot validate nil value")
    ErrCannotValidateInvalidValue = errors.New("cannot validate invalid value")
    ErrUnknownValidationStrategy  = errors.New("unknown validation strategy")
    ErrValidationFailed           = errors.New("validation failed")
    ErrInvalidType                = errors.New("invalid type")
)
```

Sentinel errors for error checking with `errors.Is`.

**Example:**

```go
if errors.Is(err, validation.ErrValidation) {
    // This is a validation error
}
```

## Type Definitions

### Option

```go
type Option func(*config)
```

Functional option for configuring validation. See [Options](../options/) for all available options.

### Redactor

```go
type Redactor func(path string) bool
```

Function that determines if a field should be redacted in error messages. Returns `true` if the field at the given path should have its value hidden.

**Example:**

```go
redactor := func(path string) bool {
    return strings.Contains(path, "password") ||
           strings.Contains(path, "token")
}

validator := validation.MustNew(
    validation.WithRedactor(redactor),
)
```

### MessageFunc

```go
type MessageFunc func(param string, kind reflect.Kind) string
```

Generates dynamic error messages for parameterized validation tags. Receives the tag parameter and field's `reflect.Kind`.

**Example:**

```go
minMessage := func(param string, kind reflect.Kind) string {
    if kind == reflect.String {
        return fmt.Sprintf("must be at least %s characters", param)
    }
    return fmt.Sprintf("must be at least %s", param)
}

validator := validation.MustNew(
    validation.WithMessageFunc("min", minMessage),
)
```

## Constants

```go
const (
    defaultMaxCachedSchemas = 1024
    maxRecursionDepth      = 100
)
```

- `defaultMaxCachedSchemas` - Default JSON Schema cache size
- `maxRecursionDepth` - Maximum nesting depth for `ComputePresence`

## Thread Safety

All types and functions in the validation package are safe for concurrent use by multiple goroutines:

- [Engine](https://pkg.go.dev/rivaas.dev/validation#Engine) instances are thread-safe
- Package-level functions use a shared thread-safe default engine
- `PresenceMap` is read-only after creation (safe for concurrent reads)

## Performance

- **First validation** of a type: ~500ns overhead for reflection
- **Subsequent validations**: ~50ns overhead (cache lookup)
- **Schema compilation**: Cached with LRU eviction
- **Path computation**: Cached per type
- **Zero allocations**: For cached types

## Next Steps

- [**Options**](../options/) - All configuration options
- [**Interfaces**](../interfaces/) - Custom validation interfaces
- [**Strategies**](../strategies/) - Strategy selection details
- [**User Guide**](/docs/guides/validation/) - Learning tutorials
