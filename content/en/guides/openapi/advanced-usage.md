---
title: "Advanced Usage"
description: "Custom operation IDs, extensions, and strict downlevel mode"
weight: 11
---

Learn about advanced features including custom operation IDs, extensions, and strict downlevel mode.

## Custom Operation IDs

By default, operation IDs are auto-generated from the HTTP method and path. You can override this behavior.

### Auto-Generated Operation IDs

```go
openapi.GET("/users/:id",
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)
// Generated operation ID: "getUsers_id"

openapi.POST("/users",
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)
// Generated operation ID: "postUsers"
```

### Custom Operation IDs

Override with `WithOperationID()`:

```go
openapi.GET("/users/:id",
    openapi.WithOperationID("getUserById"),
    openapi.WithSummary("Get user"),
    openapi.WithResponse(200, User{}),
)

openapi.POST("/users",
    openapi.WithOperationID("createNewUser"),
    openapi.WithSummary("Create user"),
    openapi.WithRequest(CreateUserRequest{}),
    openapi.WithResponse(201, User{}),
)
```

### Operation ID Best Practices

- **Use camelCase** - Consistent with most API conventions.
- **Be descriptive** - `getUserById` rather than `getUser1`.
- **Avoid conflicts** - Ensure unique IDs across all operations.
- **Consider generation** - Some tools generate client code from operation IDs.

## Extensions

OpenAPI allows custom `x-*` extensions for vendor-specific metadata.

### Root-Level Extensions

Add extensions to the root of the specification:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithExtension("x-api-version", "v2"),
    openapi.WithExtension("x-custom-feature", true),
    openapi.WithExtension("x-rate-limit-config", map[string]interface{}{
        "requests": 100,
        "period": "1m",
    }),
)
```

### Operation Extensions

Add extensions to specific operations.

```go
openapi.GET("/users",
    openapi.WithSummary("List users"),
    openapi.WithOperationExtension("x-rate-limit", 100),
    openapi.WithOperationExtension("x-cache-ttl", 300),
    openapi.WithOperationExtension("x-internal-only", false),
    openapi.WithResponse(200, []User{}),
)
```

### Extension Naming Rules

- **Must start with `x-`** - Required by OpenAPI specification
- **Reserved prefixes** - `x-oai-` and `x-oas-` are reserved in 3.1.x
- **Case-sensitive** - `x-Custom` and `x-custom` are different

### Extension Validation

Extensions are validated:

```go
// Valid
openapi.WithExtension("x-custom", "value")

// Invalid - doesn't start with x-
openapi.WithExtension("custom", "value") // Error

// Invalid - reserved prefix in 3.1.x
openapi.WithExtension("x-oai-custom", "value") // Filtered out in 3.1.x
```

### Common Extension Use Cases

```go
// API versioning
openapi.WithExtension("x-api-version", "2.0")

// Rate limiting
openapi.WithOperationExtension("x-rate-limit", map[string]interface{}{
    "requests": 100,
    "window": "1m",
})

// Caching
openapi.WithOperationExtension("x-cache", map[string]interface{}{
    "ttl": 300,
    "vary": []string{"Authorization", "Accept-Language"},
})

// Internal metadata
openapi.WithOperationExtension("x-internal", map[string]interface{}{
    "team": "platform",
    "cost": "low",
})

// Feature flags
openapi.WithOperationExtension("x-feature-flag", "new-user-flow")

// Code generation hints
openapi.WithOperationExtension("x-codegen", map[string]interface{}{
    "methodName": "customMethodName",
    "packageName": "users",
})
```

## Strict Downlevel Mode

By default, using 3.1 features with a 3.0 target generates warnings. Enable strict mode to error instead:

### Default Behavior (Warnings)

```go
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithVersion(openapi.V30x),
    openapi.WithInfoSummary("Summary"), // 3.1-only feature
)

result, err := api.Generate(context.Background(), ops...)
// err is nil (generation succeeds)
// result.Warnings contains warning about info.summary being dropped
```

### Strict Mode (Errors)

```go
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithVersion(openapi.V30x),
    openapi.WithStrictDownlevel(true), // Enable strict mode
    openapi.WithInfoSummary("Summary"), // This will cause an error
)

result, err := api.Generate(context.Background(), ops...)
// err is non-nil (generation fails)
```

### When to Use Strict Mode

Use strict mode when:
- **Enforcing version compliance** - Prevent accidental 3.1 feature usage
- **CI/CD validation** - Fail builds on version violations
- **Team standards** - Ensure consistent OpenAPI version usage
- **Client compatibility** - Target clients require strict 3.0 compliance

Don't use strict mode when:
- **Graceful degradation** - You're okay with features being dropped
- **Development** - Exploring features without hard errors
- **Flexible deployments** - Different environments support different versions

### Features Affected by Strict Mode

3.1-only features that trigger strict mode:

- `WithInfoSummary()` - Short API summary
- `WithLicenseIdentifier()` - SPDX license identifier
- Webhooks - Webhook definitions
- Mutual TLS - `mutualTLS` security scheme
- `const` in schemas - JSON Schema `const` keyword
- Multiple `examples` - Multiple schema examples

## Complete Advanced Example

```go
package main

import (
    "context"
    "fmt"
    "log"
    
    "rivaas.dev/openapi"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

type CreateUserRequest struct {
    Name string `json:"name" validate:"required"`
}

func main() {
    api := openapi.MustNew(
        // Basic configuration
        openapi.WithTitle("Advanced API", "1.0.0"),
        openapi.WithVersion(openapi.V30x),
        
        // Root-level extensions
        openapi.WithExtension("x-api-version", "v2"),
        openapi.WithExtension("x-environment", "production"),
        openapi.WithExtension("x-service-info", map[string]interface{}{
            "team": "platform",
            "repository": "github.com/example/api",
        }),
        
        // Strict mode (optional)
        openapi.WithStrictDownlevel(false), // Allow graceful degradation
    )
    
    result, err := api.Generate(context.Background(),
        // Custom operation IDs
        openapi.GET("/users/:id",
            openapi.WithOperationID("getUserById"),
            openapi.WithSummary("Get user by ID"),
            
            // Operation extensions
            openapi.WithOperationExtension("x-rate-limit", 100),
            openapi.WithOperationExtension("x-cache-ttl", 300),
            openapi.WithOperationExtension("x-internal-team", "users"),
            
            openapi.WithResponse(200, User{}),
        ),
        
        openapi.POST("/users",
            openapi.WithOperationID("createUser"),
            openapi.WithSummary("Create a new user"),
            
            // Different extensions per operation
            openapi.WithOperationExtension("x-rate-limit", 10),
            openapi.WithOperationExtension("x-feature-flag", "new-user-flow"),
            openapi.WithOperationExtension("x-mutation", true),
            
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(201, User{}),
        ),
        
        openapi.PUT("/users/:id",
            openapi.WithOperationID("updateUser"),
            openapi.WithSummary("Update user"),
            
            openapi.WithOperationExtension("x-rate-limit", 50),
            openapi.WithOperationExtension("x-mutation", true),
            
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(200, User{}),
        ),
        
        openapi.DELETE("/users/:id",
            openapi.WithOperationID("deleteUser"),
            openapi.WithSummary("Delete user"),
            
            openapi.WithOperationExtension("x-rate-limit", 10),
            openapi.WithOperationExtension("x-mutation", true),
            openapi.WithOperationExtension("x-dangerous", true),
            
            openapi.WithResponse(204, nil),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Check for warnings
    if len(result.Warnings) > 0 {
        fmt.Printf("Generated with %d warnings:\n", len(result.Warnings))
        for _, warn := range result.Warnings {
            fmt.Printf("  - %s\n", warn.Message())
        }
    }
    
    fmt.Printf("Generated %d byte specification\n", len(result.JSON))
}
```

## Best Practices

### Operation IDs

1. **Be consistent** - Use the same naming convention across all operations
2. **Make them unique** - Avoid duplicate operation IDs
3. **Consider clients** - Generated client libraries use these names
4. **Document the convention** - Help team members follow the pattern

### Extensions

1. **Use sparingly** - Only add extensions when necessary
2. **Document them** - Explain what custom extensions mean
3. **Validate format** - Ensure extensions follow your schema
4. **Version them** - Consider versioning extension formats
5. **Tool compatibility** - Check if tools support your extensions

### Strict Mode

1. **Enable in CI/CD** - Catch version issues early
2. **Document the choice** - Explain why strict mode is enabled/disabled
3. **Test both modes** - Ensure graceful degradation works if disabled
4. **Communicate clearly** - Make version requirements explicit

## Next Steps

- See [Examples](../examples/) for complete usage patterns
- Review [Diagnostics](../diagnostics/) for warning handling
- Check [Validation](../validation/) for specification validation
