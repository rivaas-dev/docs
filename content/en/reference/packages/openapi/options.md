---
title: "API Options"
description: "Complete reference for API-level configuration options"
weight: 2
---

Complete reference for all API-level configuration options (functions passed to `New()` or `MustNew()`).

## Info Options

### WithTitle

```go
func WithTitle(title, version string) Option
```

Sets the API title and version. **Required.**

**Parameters:**
- `title` - API title
- `version` - API version (e.g., "1.0.0")

**Example:**

```go
openapi.WithTitle("My API", "1.0.0")
```

### WithInfoDescription

```go
func WithInfoDescription(description string) Option
```

Sets the API description.

**Example:**

```go
openapi.WithInfoDescription("Comprehensive API for managing users and resources")
```

### WithInfoSummary

```go
func WithInfoSummary(summary string) Option
```

Sets a short summary for the API. **OpenAPI 3.1 only.**

Generates warning if used with 3.0 target.

**Example:**

```go
openapi.WithInfoSummary("User Management API")
```

### WithTermsOfService

```go
func WithTermsOfService(url string) Option
```

Sets the terms of service URL.

**Example:**

```go
openapi.WithTermsOfService("https://example.com/terms")
```

### WithContact

```go
func WithContact(name, url, email string) Option
```

Sets contact information.

**Parameters:**
- `name` - Contact name
- `url` - Contact URL
- `email` - Contact email

**Example:**

```go
openapi.WithContact("API Support", "https://example.com/support", "support@example.com")
```

### WithLicense

```go
func WithLicense(name, url string) Option
```

Sets license information.

**Parameters:**
- `name` - License name
- `url` - License URL

**Example:**

```go
openapi.WithLicense("Apache 2.0", "https://www.apache.org/licenses/LICENSE-2.0.html")
```

### WithLicenseIdentifier

```go
func WithLicenseIdentifier(name, identifier string) Option
```

Sets license with SPDX identifier. **OpenAPI 3.1 only.**

**Parameters:**
- `name` - License name
- `identifier` - SPDX license identifier

**Example:**

```go
openapi.WithLicenseIdentifier("Apache 2.0", "Apache-2.0")
```

### WithInfoExtension

```go
func WithInfoExtension(key string, value any) Option
```

Adds a custom extension to the info object.

**Parameters:**
- `key` - Extension key (must start with `x-`)
- `value` - Extension value

**Example:**

```go
openapi.WithInfoExtension("x-api-id", "user-service")
```

## Version Options

### WithVersion

```go
func WithVersion(version Version) Option
```

Sets the target OpenAPI version. Default is `V30x`.

**Parameters:**
- `version` - Either `V30x` or `V31x`

**Example:**

```go
openapi.WithVersion(openapi.V31x)
```

## Server Options

### WithServer

```go
func WithServer(url, description string) Option
```

Adds a server configuration.

**Parameters:**
- `url` - Server URL
- `description` - Server description

**Example:**

```go
openapi.WithServer("https://api.example.com", "Production")
openapi.WithServer("http://localhost:8080", "Development")
```

### WithServerVariable

```go
func WithServerVariable(name, defaultValue string, enumValues []string, description string) Option
```

Adds a server variable for URL templating.

**Parameters:**
- `name` - Variable name
- `defaultValue` - Default value
- `enumValues` - Allowed values
- `description` - Variable description

**Example:**

```go
openapi.WithServer("https://{environment}.example.com", "Environment-based"),
openapi.WithServerVariable("environment", "api", 
    []string{"api", "staging", "dev"},
    "Environment to use",
)
```

## Security Scheme Options

### WithBearerAuth

```go
func WithBearerAuth(name, description string) Option
```

Adds Bearer (JWT) authentication scheme.

**Parameters:**
- `name` - Security scheme name (used in `WithSecurity()`)
- `description` - Scheme description

**Example:**

```go
openapi.WithBearerAuth("bearerAuth", "JWT authentication")
```

### WithAPIKey

```go
func WithAPIKey(name, paramName string, location ParameterLocation, description string) Option
```

Adds API key authentication scheme.

**Parameters:**
- `name` - Security scheme name
- `paramName` - Parameter name (e.g., "X-API-Key", "api_key")
- `location` - Where the key is located: `InHeader`, `InQuery`, or `InCookie`
- `description` - Scheme description

**Example:**

```go
openapi.WithAPIKey("apiKey", "X-API-Key", openapi.InHeader, "API key for authentication")
```

### WithOAuth2

```go
func WithOAuth2(name, description string, flows ...OAuth2Flow) Option
```

Adds OAuth2 authentication scheme.

**Parameters:**
- `name` - Security scheme name
- `description` - Scheme description
- `flows` - OAuth2 flow configurations

**Example:**

```go
openapi.WithOAuth2("oauth2", "OAuth2 authentication",
    openapi.OAuth2Flow{
        Type:             openapi.FlowAuthorizationCode,
        AuthorizationURL: "https://example.com/oauth/authorize",
        TokenURL:         "https://example.com/oauth/token",
        Scopes: map[string]string{
            "read":  "Read access",
            "write": "Write access",
        },
    },
)
```

### WithOpenIDConnect

```go
func WithOpenIDConnect(name, openIDConnectURL, description string) Option
```

Adds OpenID Connect authentication scheme.

**Parameters:**
- `name` - Security scheme name
- `openIDConnectURL` - OpenID Connect discovery URL
- `description` - Scheme description

**Example:**

```go
openapi.WithOpenIDConnect("openId", "https://example.com/.well-known/openid-configuration", "OpenID Connect")
```

### WithDefaultSecurity

```go
func WithDefaultSecurity(scheme string, scopes ...string) Option
```

Sets default security requirement at API level (applies to all operations unless overridden).

**Parameters:**
- `scheme` - Security scheme name
- `scopes` - Optional OAuth2 scopes

**Example:**

```go
openapi.WithDefaultSecurity("bearerAuth")
openapi.WithDefaultSecurity("oauth2", "read", "write")
```

## Tag Options

### WithTag

```go
func WithTag(name, description string) Option
```

Adds a tag for organizing operations.

**Parameters:**
- `name` - Tag name
- `description` - Tag description

**Example:**

```go
openapi.WithTag("users", "User management operations")
openapi.WithTag("posts", "Post management operations")
```

## External Documentation

### WithExternalDocs

```go
func WithExternalDocs(url, description string) Option
```

Links to external documentation.

**Parameters:**
- `url` - Documentation URL
- `description` - Documentation description

**Example:**

```go
openapi.WithExternalDocs("https://docs.example.com", "Full API Documentation")
```

## Validation Options

### WithValidation

```go
func WithValidation(enabled bool) Option
```

Enables or disables specification validation. Default is `false`.

**Parameters:**
- `enabled` - Whether to validate generated specs

**Example:**

```go
openapi.WithValidation(true) // Enable validation
```

### WithStrictDownlevel

```go
func WithStrictDownlevel(enabled bool) Option
```

Enables strict downlevel mode. When enabled, using 3.1 features with a 3.0 target causes errors instead of warnings. Default is `false`.

**Parameters:**
- `enabled` - Whether to error on downlevel issues

**Example:**

```go
openapi.WithStrictDownlevel(true) // Error on 3.1 features with 3.0 target
```

### WithSpecPath

```go
func WithSpecPath(path string) Option
```

Sets the path where the OpenAPI specification will be served.

**Parameters:**
- `path` - URL path for the spec (e.g., "/openapi.json")

**Example:**

```go
openapi.WithSpecPath("/api/openapi.json")
```

## Swagger UI Options

### WithSwaggerUI

```go
func WithSwaggerUI(path string, opts ...UIOption) Option
```

Configures Swagger UI at the specified path.

**Parameters:**
- `path` - URL path where Swagger UI is served
- `opts` - Swagger UI configuration options (see [Swagger UI Options](swagger-ui-options/))

**Example:**

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIExpansion(openapi.DocExpansionList),
    openapi.WithUITryItOut(true),
)
```

### WithoutSwaggerUI

```go
func WithoutSwaggerUI() Option
```

Disables Swagger UI.

**Example:**

```go
openapi.WithoutSwaggerUI()
```

## Extension Options

### WithExtension

```go
func WithExtension(key string, value interface{}) Option
```

Adds a custom `x-*` extension to the root of the specification.

**Parameters:**
- `key` - Extension key (must start with `x-`)
- `value` - Extension value (any JSON-serializable type)

**Example:**

```go
openapi.WithExtension("x-api-version", "v2")
openapi.WithExtension("x-custom-config", map[string]interface{}{
    "feature": "enabled",
    "rate-limit": 100,
})
```

## Next Steps

- See [Operation Options](operation-options/) for operation-level configuration
- Check [Swagger UI Options](swagger-ui-options/) for UI customization
- Review [API Reference](api-reference/) for types and methods
