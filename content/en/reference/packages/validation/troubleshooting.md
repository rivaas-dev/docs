---
title: "Troubleshooting"
description: "Common issues and solutions"
keywords:
  - validation troubleshooting
  - common issues
  - debugging
  - faq
weight: 5
---

Common issues, solutions, and debugging tips for the validation package.

## Validation Not Running

### Issue: Validation passes when it should fail

**Symptom:**

```go
type User struct {
    Email string `validate:"required,email"`
}

user := User{Email: ""} // Should fail
err := validation.Validate(ctx, &user) // err is nil (unexpected)
```

**Possible Causes:**

1. **Struct tags not being checked**

Check if a higher-priority strategy is being used:

```go
func (u *User) Validate() error {
    return nil // This runs instead of tags
}
```

**Solution:** Remove interface method or use `WithStrategy`:

```go
err := validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyTags),
)
```

2. **Wrong tag name**

```go
// Wrong
Email string `validation:"required"` // Should be "validate"

// Correct
Email string `validate:"required"`
```

3. **Validating value instead of pointer**

```go
// May not work with pointer receivers
user := User{} // value
user.Validate() // Method might not be found

// Use pointer
user := &User{} // pointer
validation.Validate(ctx, user)
```

## Partial Validation Issues

### Issue: Required fields failing in PATCH requests

**Symptom:**

```go
type UpdateUser struct {
    Email string `validate:"required,email"`
}

// PATCH with only age
err := validation.ValidatePartial(ctx, &req, presence)
// Error: email is required (but it wasn't provided)
```

**Solution:** Use `omitempty` instead of `required` for PATCH:

```go
type UpdateUser struct {
    Email string `validate:"omitempty,email"` // Not "required"
}
```

### Issue: Presence map not being respected

**Symptom:**

```go
presence, _ := validation.ComputePresence(rawJSON)
err := validation.Validate(ctx, &req, // Missing WithPresence!
    validation.WithPartial(true),
)
```

**Solution:** Always pass presence map:

```go
err := validation.Validate(ctx, &req,
    validation.WithPartial(true),
    validation.WithPresence(presence), // Add this
)
```

## Custom Validation Issues

### Issue: Custom tag not working

**Symptom:**

```go
validator := validation.MustNew(
    validation.WithCustomTag("phone", phoneValidator),
)

type User struct {
    Phone string `validate:"phone"` // Not recognized
}
```

**Possible Causes:**

1. **Tag registered on wrong validator**

```go
// Registered on custom validator
validator := validation.MustNew(
    validation.WithCustomTag("phone", phoneValidator),
)

// But using package-level function (different validator)
validation.Validate(ctx, &user) // Doesn't have custom tag
```

**Solution:** Use the same validator:

```go
validator.Validate(ctx, &user) // Use custom validator
```

2. **Tag function signature wrong**

```go
// Wrong
func phoneValidator(val string) bool { ... }

// Correct
func phoneValidator(fl validator.FieldLevel) bool { ... }
```

### Issue: ValidateContext not being called

**Symptom:**

```go
func (u *User) ValidateContext(ctx context.Context) error {
    fmt.Println("Never prints")
    return nil
}
```

**Possible Causes:**

1. **Wrong receiver type**

```go
// Method defined on value
func (u User) ValidateContext(ctx context.Context) error { ... }

// But validating pointer
user := &User{}
validation.Validate(ctx, user) // Method not found
```

**Solution:** Use pointer receiver:

```go
func (u *User) ValidateContext(ctx context.Context) error { ... }
```

2. **Struct tags have priority**

If auto-selection chooses tags, interface method isn't called.

**Solution:** Explicitly use interface strategy:

```go
validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyInterface),
)
```

## Error Handling Issues

### Issue: Can't access field errors

**Symptom:**

```go
err := validation.Validate(ctx, &user)
// How do I get field-level errors?
```

**Solution:** Use `errors.As`:

```go
var verr *validation.Error
if errors.As(err, &verr) {
    for _, fieldErr := range verr.Fields {
        fmt.Printf("%s: %s\n", fieldErr.Path, fieldErr.Message)
    }
}
```

### Issue: Sensitive data visible in errors

**Symptom:**

```go
// Error message contains password value
email: invalid email (value: "password123")
```

**Solution:** Use redactor:

```go
validator := validation.MustNew(
    validation.WithRedactor(func(path string) bool {
        return strings.Contains(path, "password")
    }),
)
```

## Performance Issues

### Issue: Validation is slow

**Possible Causes:**

1. **Creating validator on every request**

```go
// Bad - creates validator every time
func Handler(w http.ResponseWriter, r *http.Request) {
    validator := validation.MustNew(...) // Slow
    validator.Validate(ctx, &req)
}
```

**Solution:** Create once, reuse:

```go
var validator = validation.MustNew(...)

func Handler(w http.ResponseWriter, r *http.Request) {
    validator.Validate(ctx, &req) // Fast
}
```

2. **JSON Schema not cached**

```go
func (u User) JSONSchema() (id, schema string) {
    return "", `{...}` // Empty ID = no caching
}
```

**Solution:** Use stable ID:

```go
func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{...}` // Cached
}
```

3. **Expensive ValidateContext**

```go
func (u *User) ValidateContext(ctx context.Context) error {
    // Expensive operation on every validation
    return checkWithExternalAPI(u.Email)
}
```

**Solution:** Optimize or cache:

```go
func (u *User) ValidateContext(ctx context.Context) error {
    // Fast checks first
    if !basicValidation(u.Email) {
        return errors.New("invalid format")
    }
    
    // Expensive check last
    return checkWithExternalAPI(u.Email)
}
```

## JSON Schema Issues

### Issue: Schema validation not working

**Symptom:**

```go
func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{...}`
}

// But validation doesn't use schema
```

**Possible Causes:**

1. **Higher priority strategy exists**

```go
type User struct {
    Email string `validate:"email"` // Tags have higher priority
}

func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{...}` // Not used
}
```

**Solution:** Use explicit strategy:

```go
validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyJSONSchema),
)
```

2. **Invalid JSON Schema**

```go
func (u User) JSONSchema() (id, schema string) {
    return "user-v1", `{ invalid json }` // Parse error
}
```

**Solution:** Validate schema syntax:

```go
// Use online validator: https://www.jsonschemavalidator.net/
```

## Context Issues

### Issue: Context values not available

**Symptom:**

```go
func (u *User) ValidateContext(ctx context.Context) error {
    db := ctx.Value("db") // db is nil
    // ...
}
```

**Solution:** Ensure values are in context:

```go
ctx = context.WithValue(ctx, "db", db)
err := validation.Validate(ctx, &user)
```

### Issue: Wrong context being used

**Symptom:**

```go
err := validation.Validate(ctx1, &user,
    validation.WithContext(ctx2), // Overrides ctx1
)
```

**Solution:** Don't use `WithContext` unless necessary:

```go
// Just pass the right context
err := validation.Validate(correctCtx, &user)
```

## Module and Import Issues

### Issue: Cannot find module

```bash
go: finding module for package rivaas.dev/validation
```

**Solution:**

```bash
go mod tidy
go get rivaas.dev/validation
```

### Issue: Version conflicts

```bash
require rivaas.dev/validation v1.0.0
// +incompatible
```

**Solution:** Update to compatible version:

```bash
go get rivaas.dev/validation@latest
go mod tidy
```

## Common Error Messages

### "cannot validate nil value"

**Cause:** Passing nil to `Validate`:

```go
var user *User
validation.Validate(ctx, user) // Error: cannot validate nil value
```

**Solution:** Ensure value is not nil:

```go
user := &User{Email: "test@example.com"}
validation.Validate(ctx, user)
```

### "cannot validate invalid value"

**Cause:** Passing invalid reflect.Value:

```go
var v interface{}
validation.Validate(ctx, v) // Error: cannot validate invalid value
```

**Solution:** Pass actual struct:

```go
user := &User{}
validation.Validate(ctx, user)
```

### "unknown validation strategy"

**Cause:** Invalid strategy value:

```go
validation.Validate(ctx, &user,
    validation.WithStrategy(999), // Invalid
)
```

**Solution:** Use valid strategy constants:

```go
validation.Validate(ctx, &user,
    validation.WithStrategy(validation.StrategyTags),
)
```

## Debugging Tips

### 1. Check which strategy is being used

```go
// Temporarily force each strategy to see which works
strategies := []validation.Strategy{
    validation.StrategyInterface,
    validation.StrategyTags,
    validation.StrategyJSONSchema,
}

for _, strategy := range strategies {
    err := validation.Validate(ctx, &user,
        validation.WithStrategy(strategy),
    )
    fmt.Printf("%v: %v\n", strategy, err)
}
```

### 2. Enable all error reporting

```go
err := validation.Validate(ctx, &user,
    validation.WithMaxErrors(0), // Unlimited
)
```

### 3. Check struct tags

```go
import "reflect"

t := reflect.TypeOf(User{})
for i := 0; i < t.NumField(); i++ {
    field := t.Field(i)
    fmt.Printf("%s: %s\n", field.Name, field.Tag.Get("validate"))
}
```

### 4. Test interface implementation

```go
var _ validation.ValidatorInterface = (*User)(nil) // Compile-time check
var _ validation.ValidatorWithContext = (*User)(nil)
var _ validation.JSONSchemaProvider = (*User)(nil)
```

## Getting Help

If you're still stuck:

1. **Check documentation**: [User Guide](/guides/validation/)
2. **Review examples**: [Examples](/guides/validation/examples/)
3. **Check pkg.go.dev**: [API Documentation](https://pkg.go.dev/rivaas.dev/validation)
4. **GitHub Issues**: [Report a bug](https://github.com/rivaas-dev/rivaas/issues)
5. **Discussions**: [Ask a question](https://github.com/rivaas-dev/rivaas/discussions)

## Next Steps

- [**API Reference**](../api-reference/) - Core types and functions
- [**Options**](../options/) - Configuration options
- [**User Guide**](/guides/validation/) - Learning tutorials
