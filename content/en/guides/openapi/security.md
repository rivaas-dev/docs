---
title: "Security"
description: "Add authentication and authorization schemes to your OpenAPI specification"
weight: 4
---

Learn how to add security schemes to your OpenAPI specification for authentication and authorization.

## Security Scheme Types

The package supports four types of security schemes:

1. **Bearer Authentication** - JWT or token-based authentication.
2. **API Key** - API keys in headers, query parameters, or cookies.
3. **OAuth2** - OAuth 2.0 authorization flows.
4. **OpenID Connect** - OpenID Connect authentication.

## Bearer Authentication

Bearer authentication is commonly used for JWT tokens:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
)
```

### Using Bearer Authentication in Operations

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithSecurity("bearerAuth"),
        openapi.WithResponse(200, []User{}),
    ),
)
```

The generated specification will expect an `Authorization: Bearer <token>` header.

## API Key Authentication

API keys can be placed in headers, query parameters, or cookies:

### Header-Based API Key

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithAPIKey(
        "apiKey",
        "X-API-Key",
        openapi.InHeader,
        "API key for authentication",
    ),
)
```

### Query Parameter API Key

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithAPIKey(
        "apiKey",
        "api_key",
        openapi.InQuery,
        "API key for authentication",
    ),
)
```

### Cookie-Based API Key

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithAPIKey(
        "apiKey",
        "api_key",
        openapi.InCookie,
        "API key for authentication",
    ),
)
```

### Using API Key in Operations

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithSecurity("apiKey"),
        openapi.WithResponse(200, []User{}),
    ),
)
```

## OAuth2

OAuth2 supports multiple flows: authorization code, implicit, password, and client credentials.

### Authorization Code Flow

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithOAuth2(
        "oauth2",
        "OAuth2 authentication",
        openapi.OAuth2Flow{
            Type:             openapi.FlowAuthorizationCode,
            AuthorizationURL: "https://example.com/oauth/authorize",
            TokenURL:         "https://example.com/oauth/token",
            Scopes: map[string]string{
                "read":  "Read access to resources",
                "write": "Write access to resources",
                "admin": "Administrative access",
            },
        },
    ),
)
```

### Implicit Flow

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithOAuth2(
        "oauth2",
        "OAuth2 authentication",
        openapi.OAuth2Flow{
            Type:             openapi.FlowImplicit,
            AuthorizationURL: "https://example.com/oauth/authorize",
            Scopes: map[string]string{
                "read":  "Read access",
                "write": "Write access",
            },
        },
    ),
)
```

### Password Flow

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithOAuth2(
        "oauth2",
        "OAuth2 authentication",
        openapi.OAuth2Flow{
            Type:     openapi.FlowPassword,
            TokenURL: "https://example.com/oauth/token",
            Scopes: map[string]string{
                "read":  "Read access",
                "write": "Write access",
            },
        },
    ),
)
```

### Client Credentials Flow

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithOAuth2(
        "oauth2",
        "OAuth2 authentication",
        openapi.OAuth2Flow{
            Type:     openapi.FlowClientCredentials,
            TokenURL: "https://example.com/oauth/token",
            Scopes: map[string]string{
                "api": "API access",
            },
        },
    ),
)
```

### Using OAuth2 in Operations

Specify which scopes are required for an operation:

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithSecurity("oauth2", "read"),
        openapi.WithResponse(200, []User{}),
    ),
    openapi.POST("/users",
        openapi.WithSummary("Create user"),
        openapi.WithSecurity("oauth2", "read", "write"),
        openapi.WithRequest(CreateUserRequest{}),
        openapi.WithResponse(201, User{}),
    ),
)
```

## OpenID Connect

OpenID Connect provides authentication on top of OAuth2:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithOpenIDConnect(
        "openId",
        "https://example.com/.well-known/openid-configuration",
        "OpenID Connect authentication",
    ),
)
```

### Using OpenID Connect in Operations

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithSecurity("openId"),
        openapi.WithResponse(200, []User{}),
    ),
)
```

## Multiple Security Schemes

You can define multiple security schemes:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
    openapi.WithAPIKey(
        "apiKey",
        "X-API-Key",
        openapi.InHeader,
        "API key authentication",
    ),
)
```

### Alternative Security Requirements (OR)

Allow multiple authentication methods for a single operation:

```go
result, err := api.Generate(context.Background(),
    openapi.GET("/users",
        openapi.WithSummary("List users"),
        openapi.WithSecurity("bearerAuth"),  // Can use bearer auth
        openapi.WithSecurity("apiKey"),      // OR can use API key
        openapi.WithResponse(200, []User{}),
    ),
)
```

This means the client can authenticate using **either** bearer auth **or** an API key.

## Optional vs Required Security

### Required Security

Apply security at the operation level:

```go
openapi.GET("/users",
    openapi.WithSecurity("bearerAuth"),
    openapi.WithResponse(200, []User{}),
)
```

### Optional Security (Public Endpoint)

Omit the `WithSecurity()` option:

```go
openapi.GET("/public/status",
    openapi.WithSummary("Public status endpoint"),
    openapi.WithResponse(200, StatusResponse{}),
)
```

## Complete Security Example

Here's a complete example with multiple security schemes:

```go
package main

import (
    "context"
    "log"

    "rivaas.dev/openapi"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

type CreateUserRequest struct {
    Name string `json:"name"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("Secure API", "1.0.0"),
        
        // Define multiple security schemes
        openapi.WithBearerAuth("bearerAuth", "JWT token authentication"),
        openapi.WithAPIKey(
            "apiKey",
            "X-API-Key",
            openapi.InHeader,
            "API key authentication",
        ),
        openapi.WithOAuth2(
            "oauth2",
            "OAuth2 authentication",
            openapi.OAuth2Flow{
                Type:             openapi.FlowAuthorizationCode,
                AuthorizationURL: "https://example.com/oauth/authorize",
                TokenURL:         "https://example.com/oauth/token",
                Scopes: map[string]string{
                    "read":  "Read access",
                    "write": "Write access",
                },
            },
        ),
    )

    result, err := api.Generate(context.Background(),
        // Public endpoint (no security)
        openapi.GET("/health",
            openapi.WithSummary("Health check"),
            openapi.WithResponse(200, nil),
        ),
        
        // Bearer auth only
        openapi.GET("/users",
            openapi.WithSummary("List users"),
            openapi.WithSecurity("bearerAuth"),
            openapi.WithResponse(200, []User{}),
        ),
        
        // API key or bearer auth (alternative)
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithSecurity("bearerAuth"),
            openapi.WithSecurity("apiKey"),
            openapi.WithResponse(200, User{}),
        ),
        
        // OAuth2 with specific scopes
        openapi.POST("/users",
            openapi.WithSummary("Create user"),
            openapi.WithSecurity("oauth2", "read", "write"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(201, User{}),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Use result...
}
```

## Next Steps

- Learn about [Operations](../operations/) to define API endpoints
- Explore [Auto-Discovery](../auto-discovery/) for parameter discovery
- See [Examples](../examples/) for more security patterns
