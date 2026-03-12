---
title: "Configuration"
description: "Configure API metadata, version selection, servers, and tags"
weight: 3
keywords:
  - openapi configuration
  - spec options
  - metadata
  - api info
---

Learn how to configure your OpenAPI specification with metadata, servers, and version selection.

## Basic Configuration

Configuration is done exclusively through functional options with `With*` prefix:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithInfoDescription("API description"),
    openapi.WithInfoSummary("Short summary"), // 3.1.x only
    openapi.WithTermsOfService("https://example.com/terms"),
)
```

### Required Configuration

Only `WithTitle()` is required when creating an API configuration:

```go
// Minimal configuration
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
)
```

### Contact Information

Add contact information for API support:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithContact(
        "API Support",
        "https://example.com/support",
        "support@example.com",
    ),
)
```

### License Information

Specify the API license:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithLicense(
        "Apache 2.0",
        "https://www.apache.org/licenses/LICENSE-2.0.html",
    ),
)
```

## Version Selection

The package supports two OpenAPI version families:

```go
// Target OpenAPI 3.0.x (generates 3.0.4)
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithVersion(openapi.V30x), // Default
)

// Target OpenAPI 3.1.x (generates 3.1.2)
api := openapi.MustNew(
    openapi.WithTitle("API", "1.0.0"),
    openapi.WithVersion(openapi.V31x),
)
```

The constants `V30x` and `V31x` represent version **families**. Internally they map to specific versions. 3.0.4 and 3.1.2 are used in the generated specification.

### Version-Specific Features

Some features are only available in OpenAPI 3.1.x:

- `WithInfoSummary()` - Short summary for the API
- `WithLicenseIdentifier()` - SPDX license identifier
- Webhooks support
- Mutual TLS authentication

When using these features with a 3.0.x target, the package will generate warnings (see [Diagnostics](../diagnostics/)).

## Servers

Add server configurations to specify where the API is available:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithServer("https://api.example.com", "Production"),
    openapi.WithServer("https://staging.example.com", "Staging"),
    openapi.WithServer("http://localhost:8080", "Local development"),
)
```

### Server Variables

Add variables to server URLs for flexible configuration:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithServer("https://{environment}.example.com", "Environment-based"),
    openapi.WithServerVariable("environment", "api", 
        []string{"api", "staging", "dev"},
        "Environment to use",
    ),
)
```

Multiple variables can be defined for a single server:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithServer("https://{subdomain}.{domain}", "Custom domain"),
    openapi.WithServerVariable("subdomain", "api", 
        []string{"api", "staging"},
        "Subdomain",
    ),
    openapi.WithServerVariable("domain", "example.com", 
        []string{"example.com", "test.com"},
        "Domain",
    ),
)
```

## Tags

Tags help organize operations in the documentation:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithTag("users", "User management operations"),
    openapi.WithTag("posts", "Post management operations"),
    openapi.WithTag("auth", "Authentication operations"),
)
```

Tags are then referenced in operations:

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithTags("users"),
        openapi.WithResponse(200, []User{}),
    ),
    openapi.GET("/posts",
        openapi.WithSummary("List posts"),
        openapi.WithTags("posts"),
        openapi.WithResponse(200, []Post{}),
    ),
)
```

## External Documentation

Link to external documentation:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithExternalDocs(
        "https://docs.example.com",
        "Full API Documentation",
    ),
)
```

## Complete Configuration Example

Here's a complete example with all common configuration options:

```go
package main

import (
    "context"
    "log"

    "rivaas.dev/openapi"
)

func main() {
    api := openapi.MustNew(
        // Basic info
        openapi.WithTitle("User Management API", "2.1.0"),
        openapi.WithInfoDescription("Comprehensive API for managing users and their profiles"),
        openapi.WithTermsOfService("https://example.com/terms"),
        
        // Contact
        openapi.WithContact(
            "API Support Team",
            "https://example.com/support",
            "api-support@example.com",
        ),
        
        // License
        openapi.WithLicense(
            "Apache 2.0",
            "https://www.apache.org/licenses/LICENSE-2.0.html",
        ),
        
        // Version selection
        openapi.WithVersion(openapi.V31x),
        
        // Servers
        openapi.WithServer("https://api.example.com", "Production"),
        openapi.WithServer("https://staging-api.example.com", "Staging"),
        openapi.WithServer("http://localhost:8080", "Local development"),
        
        // Tags
        openapi.WithTag("users", "User management operations"),
        openapi.WithTag("profiles", "User profile operations"),
        openapi.WithTag("auth", "Authentication and authorization"),
        
        // External docs
        openapi.WithExternalDocs(
            "https://docs.example.com/api",
            "Complete API Documentation",
        ),
        
        // Security schemes (covered in detail in Security guide)
        openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
    )

    result, err := api.Generate(context.Background(),
        // ... operations here
    )
    if err != nil {
        log.Fatal(err)
    }

    // Use result...
}
```

## Next Steps

- Learn about [Security](../security/) schemes for authentication
- Explore [Operations](../operations/) to define API endpoints
- See [Swagger UI](../swagger-ui/) for UI customization
- Check [Validation](../validation/) to validate specifications
