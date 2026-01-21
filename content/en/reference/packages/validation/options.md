---
title: "Options"
description: "Configuration options for validators"
keywords:
  - validation options
  - configuration
  - options reference
  - functional options
weight: 2
---

Complete reference for all configuration options (`With*` functions) available in the validation package.

## Option Types

Options can be used in two ways:

1. **Validator Creation**: Pass to `New()` or `MustNew()`. Applies to all validations.
2. **Per-Call**: Pass to `Validate()` or `ValidatePartial()`. Applies to that call only.

```go
// Validator creation options
validator := validation.MustNew(
    validation.WithMaxErrors(10),
    validation.WithRedactor(redactor),
)

// Per-call options (override validator config)
err := validator.Validate(ctx, &req,
    validation.WithMaxErrors(5), // Overrides the 10 from creation
    validation.WithStrategy(validation.StrategyTags),
)
```

## Strategy Options

### WithStrategy

```go
func WithStrategy(strategy Strategy) Option
```

Sets the validation strategy to use.

**Values:**
- `StrategyAuto` - Automatically select best strategy. This is the default.
- `StrategyTags` - Use struct tags only.
- `StrategyJSONSchema` - Use JSON Schema only.
- `StrategyInterface` - Use interface methods only.

**Example:**

```go
err := validation.Validate(ctx, &req,
    validation.WithStrategy(validation.StrategyTags),
)
```

### WithRunAll

```go
func WithRunAll(runAll bool) Option
```

Runs all applicable validation strategies and aggregates errors. By default, validation stops at the first successful strategy.

**Example:**

```go
err := validation.Validate(ctx, &req,
    validation.WithRunAll(true),
)
```

### WithRequireAny

```go
func WithRequireAny(require bool) Option
```

When used with `WithRunAll(true)`, succeeds if at least one strategy passes (OR logic).

**Example:**

```go
// Pass if ANY strategy succeeds
err := validation.Validate(ctx, &req,
    validation.WithRunAll(true),
    validation.WithRequireAny(true),
)
```

## Partial Validation Options

### WithPartial

```go
func WithPartial(partial bool) Option
```

Enables partial validation mode for PATCH requests. Validates only present fields and ignores "required" constraints for absent fields.

**Example:**

```go
err := validation.Validate(ctx, &req,
    validation.WithPartial(true),
    validation.WithPresence(presenceMap),
)
```

### WithPresence

```go
func WithPresence(presence PresenceMap) Option
```

Sets the presence map for partial validation. Tracks which fields were provided in the request body.

**Example:**

```go
presence, _ := validation.ComputePresence(rawJSON)
err := validation.Validate(ctx, &req,
    validation.WithPresence(presence),
    validation.WithPartial(true),
)
```

## Error Limit Options

### WithMaxErrors

```go
func WithMaxErrors(maxErrors int) Option
```

Limits the number of errors returned. Set to 0 for unlimited errors (default).

**Example:**

```go
// Return at most 5 errors
err := validation.Validate(ctx, &req,
    validation.WithMaxErrors(5),
)

var verr *validation.Error
if errors.As(err, &verr) {
    if verr.Truncated {
        fmt.Println("More errors exist")
    }
}
```

### WithMaxFields

```go
func WithMaxFields(maxFields int) Option
```

Sets the maximum number of fields to validate in partial mode. Prevents pathological inputs with extremely large presence maps. Set to 0 to use the default (10000).

**Example:**

```go
validator := validation.MustNew(
    validation.WithMaxFields(5000),
)
```

## Cache Options

### WithMaxCachedSchemas

```go
func WithMaxCachedSchemas(maxCachedSchemas int) Option
```

Sets the maximum number of JSON schemas to cache. Uses LRU eviction when limit is reached. Set to 0 to use the default (1024).

**Example:**

```go
validator := validation.MustNew(
    validation.WithMaxCachedSchemas(2048),
)
```

## Security Options

### WithRedactor

```go
func WithRedactor(redactor Redactor) Option
```

Sets a redactor function to hide sensitive values in error messages. The redactor returns true if the field at the given path should be redacted.

**Example:**

```go
redactor := func(path string) bool {
    return strings.Contains(path, "password") ||
           strings.Contains(path, "token") ||
           strings.Contains(path, "secret")
}

validator := validation.MustNew(
    validation.WithRedactor(redactor),
)
```

### WithDisallowUnknownFields

```go
func WithDisallowUnknownFields(disallow bool) Option
```

Rejects JSON with unknown fields (typo detection). When enabled, causes strict JSON binding to reject requests with fields not defined in the struct.

**Example:**

```go
err := validation.Validate(ctx, &req,
    validation.WithDisallowUnknownFields(true),
)
```

## Context Options

### WithContext

```go
func WithContext(ctx context.Context) Option
```

Overrides the context used for validation. Useful when you need a different context than the one passed to `Validate()`.

**Note**: In most cases, you should pass the context directly to `Validate()`. This option exists for advanced use cases.

**Example:**

```go
err := validator.Validate(requestCtx, &req,
    validation.WithContext(backgroundCtx),
)
```

## Custom Validation Options

### WithCustomSchema

```go
func WithCustomSchema(id, schema string) Option
```

Sets a custom JSON Schema for validation. This overrides any schema provided by the `JSONSchemaProvider` interface.

**Example:**

```go
customSchema := `{
    "type": "object",
    "properties": {
        "email": {"type": "string", "format": "email"}
    }
}`

err := validation.Validate(ctx, &req,
    validation.WithCustomSchema("custom-user", customSchema),
)
```

### WithCustomValidator

```go
func WithCustomValidator(fn func(any) error) Option
```

Sets a custom validation function that runs before any other validation strategies.

**Example:**

```go
err := validation.Validate(ctx, &req,
    validation.WithCustomValidator(func(v any) error {
        req := v.(*UserRequest)
        if req.Age < 18 {
            return errors.New("must be 18 or older")
        }
        return nil
    }),
)
```

### WithCustomTag

```go
func WithCustomTag(name string, fn validator.Func) Option
```

Registers a custom validation tag for use in struct tags. Custom tags are registered when the validator is created.

**Example:**

```go
phoneValidator := func(fl validator.FieldLevel) bool {
    return phoneRegex.MatchString(fl.Field().String())
}

validator := validation.MustNew(
    validation.WithCustomTag("phone", phoneValidator),
)

type User struct {
    Phone string `validate:"phone"`
}
```

## Error Message Options

### WithMessages

```go
func WithMessages(messages map[string]string) Option
```

Sets static error messages for validation tags. Messages override the default English messages for specified tags.

**Example:**

```go
validator := validation.MustNew(
    validation.WithMessages(map[string]string{
        "required": "cannot be empty",
        "email":    "invalid email format",
        "min":      "value too small",
    }),
)
```

### WithMessageFunc

```go
func WithMessageFunc(tag string, fn MessageFunc) Option
```

Sets a dynamic message generator for a parameterized tag. Use for tags like "min", "max", "len" that include parameters.

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

## Field Name Options

### WithFieldNameMapper

```go
func WithFieldNameMapper(mapper func(string) string) Option
```

Sets a function to transform field names in error messages. Useful for localization or custom naming conventions.

**Example:**

```go
validator := validation.MustNew(
    validation.WithFieldNameMapper(func(name string) string {
        // Convert snake_case to Title Case
        return strings.Title(strings.ReplaceAll(name, "_", " "))
    }),
)
```

## Options Summary

### Validator Creation Options

Options that should be set when creating a validator (affect all validations):

| Option | Purpose |
|--------|---------|
| `WithMaxErrors` | Limit total errors returned |
| `WithMaxFields` | Limit fields in partial validation |
| `WithMaxCachedSchemas` | Schema cache size |
| `WithRedactor` | Redact sensitive fields |
| `WithCustomTag` | Register custom validation tag |
| `WithMessages` | Custom error messages |
| `WithMessageFunc` | Dynamic error messages |
| `WithFieldNameMapper` | Transform field names |

### Per-Call Options

Options commonly used per-call (override validator config):

| Option | Purpose |
|--------|---------|
| `WithStrategy` | Choose validation strategy |
| `WithRunAll` | Run all strategies |
| `WithRequireAny` | OR logic with WithRunAll |
| `WithPartial` | Enable partial validation |
| `WithPresence` | Set presence map |
| `WithMaxErrors` | Override error limit |
| `WithCustomValidator` | Add custom validator |
| `WithCustomSchema` | Override JSON Schema |
| `WithDisallowUnknownFields` | Reject unknown fields |
| `WithContext` | Override context |

## Usage Patterns

### Creating Configured Validator

```go
validator := validation.MustNew(
    // Security
    validation.WithRedactor(sensitiveRedactor),
    validation.WithMaxErrors(20),
    validation.WithMaxFields(5000),
    
    // Custom validation
    validation.WithCustomTag("phone", phoneValidator),
    validation.WithCustomTag("username", usernameValidator),
    
    // Error messages
    validation.WithMessages(map[string]string{
        "required": "is required",
        "email":    "must be a valid email",
    }),
)
```

### Per-Call Overrides

```go
// Use tags strategy only
err := validator.Validate(ctx, &req,
    validation.WithStrategy(validation.StrategyTags),
    validation.WithMaxErrors(5),
)

// Partial validation
err := validator.Validate(ctx, &req,
    validation.WithPartial(true),
    validation.WithPresence(presence),
)

// Custom validation
err := validator.Validate(ctx, &req,
    validation.WithCustomValidator(complexBusinessLogic),
)
```

## Next Steps

- [**API Reference**](../api-reference/) - Core types and functions
- [**Interfaces**](../interfaces/) - Custom validation interfaces
- [**User Guide**](/guides/validation/) - Learning tutorials
