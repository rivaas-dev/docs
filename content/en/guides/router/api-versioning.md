---
title: "API Versioning"
description: "How to version your API with Rivaas Router"
weight: 110
keywords:
  - api versioning
  - version headers
  - url versioning
  - version detection
  - backward compatibility
---

This guide explains how to add versioning to your API. Versioning lets you change your API without breaking existing clients.

## Why Version APIs?

You need API versioning when:

- **You remove or change fields** — Breaks existing clients
- **You add required fields** — Old clients don't send them
- **You change behavior** — Clients expect the old way
- **You want to test new features** — Test with some users first
- **Clients upgrade slowly** — Different clients use different versions

## Versioning Methods

Rivaas Router supports four ways to detect versions:

### 1. Header-Based Versioning (Recommended)

The version goes in an HTTP header:

```bash
curl -H 'API-Version: v2' https://api.example.com/users
```

**Good for:**

- Public APIs
- RESTful services
- Modern web applications

**Why it's good:**

- URLs stay clean
- Works with CDN caching
- Easy to route
- Standard practice

### 2. Query Parameter Versioning

The version goes in the URL query:

```bash
curl 'https://api.example.com/users?version=v2'
```

**Good for:**

- Developer testing
- Internal APIs
- Simple clients

**Why it's good:**

- Easy to test in browsers
- Simple to document
- No header handling needed

### 3. Path-Based Versioning

The version goes in the URL path:

```bash
curl https://api.example.com/v2/users
```

**Good for:**

- Very different API versions
- Simple routing
- When you want version visible

**Why it's good:**

- Most visible
- Works with all HTTP clients
- Easy infrastructure routing

### 4. Accept Header Versioning

The version goes in the Accept header (content negotiation):

```bash
curl -H 'Accept: application/vnd.myapi.v2+json' https://api.example.com/users
```

**Good for:**

- Hypermedia APIs
- Multiple content types
- Strict REST compliance

**Why it's good:**

- Follows HTTP standards
- Supports content negotiation
- Used by major APIs

## Getting Started

### Basic Setup

Here's how to set up versioning:

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.New(
        router.WithVersioning(
            // Choose your version detection method
            router.WithHeaderVersioning("API-Version"),
            
            // Set default version (when client doesn't specify)
            router.WithDefaultVersion("v2"),
            
            // Optional: Only allow these versions
            router.WithValidVersions("v1", "v2", "v3"),
        ),
    )
    
    // Create version 1 routes
    v1 := r.Version("v1")
    v1.GET("/users", listUsersV1)
    
    // Create version 2 routes
    v2 := r.Version("v2")
    v2.GET("/users", listUsersV2)
    
    http.ListenAndServe(":8080", r)
}
```

### Using Multiple Methods

You can enable multiple detection methods. The router checks them in order:

```go
r := router.New(
    router.WithVersioning(
        router.WithHeaderVersioning("API-Version"),       // Primary
        router.WithQueryVersioning("version"),           // For testing
        router.WithPathVersioning("/v{version}/"),       // Legacy support
        router.WithAcceptVersioning("application/vnd.myapi.v{version}+json"),
        router.WithDefaultVersion("v2"),
    ),
)
```

**Check order (first match wins):**

1. Custom detector (if you made one)
2. Accept header
3. Path parameter
4. HTTP header
5. Query parameter
6. Default version

## Version Detection Methods

### Header-Based

Configure:

```go
router.WithHeaderVersioning("API-Version")
```

Clients use:

```bash
curl -H 'API-Version: v2' https://api.example.com/users
```

### Query Parameter

Configure:

```go
router.WithQueryVersioning("version")
```

Clients use:

```bash
curl 'https://api.example.com/users?version=v2'
```

### Path-Based

Configure:

```go
router.WithPathVersioning("/v{version}/")
```

Routes work with or without path version:

```go
// Accessed as /v2/users or /users (with header/query)
r.Version("v2").GET("/users", handler)
```

Clients use:

```bash
curl https://api.example.com/v2/users
```

### Accept Header

Configure:

```go
router.WithAcceptVersioning("application/vnd.myapi.v{version}+json")
```

Clients use:

```bash
curl -H 'Accept: application/vnd.myapi.v2+json' https://api.example.com/users
```

### Custom Detector

For complex logic, make your own detector:

```go
router.WithCustomVersionDetector(func(req *http.Request) string {
    // Your custom logic
    if isLegacyClient(req) {
        return "v1"
    }
    return extractVersionSomehow(req)
})
```

## Migration Patterns

### Share Business Logic

Keep business logic the same, change only the response format:

```go
// Business logic (shared between versions)
func getUserByID(id string) (*User, error) {
    // Database query, business rules, etc.
    return &User{ID: id, Name: "Alice"}, nil
}

// Version 1 handler
func listUsersV1(c *router.Context) {
    users, _ := getUsersFromDB()
    
    // V1 format: flat structure
    c.JSON(200, map[string]any{
        "users": users,
    })
}

// Version 2 handler
func listUsersV2(c *router.Context) {
    users, _ := getUsersFromDB()
    
    // V2 format: with metadata
    c.JSON(200, map[string]any{
        "data": users,
        "meta": map[string]any{
            "total": len(users),
            "version": "v2",
        },
    })
}
```

### Handle Breaking Changes

Example: Making email field required

**Version 1 (original):**

```go
type UserV1 struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email,omitempty"` // Optional
}
```

**Version 2 (breaking change):**

```go
type UserV2 struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"` // Required now
}

func createUserV2(c *router.Context) {
    var user UserV2
    if err := c.Bind(&user); err != nil {
        c.JSON(400, map[string]string{
            "error": "validation failed",
            "detail": "email is required in API v2",
        })
        return
    }
    
    // Create user...
}
```

### Version-Specific Middleware

Apply different middleware to different versions:

```go
v1 := r.Version("v1")
v1.Use(legacyAuthMiddleware)
v1.GET("/users", listUsersV1)

v2 := r.Version("v2")
v2.Use(jwtAuthMiddleware)  // Different auth method
v2.GET("/users", listUsersV2)
```

### Change Data Structure

Example: Flat to nested structure

```go
// V1: Flat structure
type UserV1 struct {
    ID      int    `json:"id"`
    Name    string `json:"name"`
    City    string `json:"city"`
    Country string `json:"country"`
}

// V2: Nested structure
type UserV2 struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
    Address struct {
        City    string `json:"city"`
        Country string `json:"country"`
    } `json:"address"`
}

// Helper to convert
func convertV1ToV2(v1 UserV1) UserV2 {
    v2 := UserV2{
        ID:   v1.ID,
        Name: v1.Name,
    }
    v2.Address.City = v1.City
    v2.Address.Country = v1.Country
    return v2
}
```

## Deprecation Strategy

### Mark Versions as Deprecated

Tell the router when a version should stop working:

```go
r := router.New(
    router.WithVersioning(
        // Mark v1 as deprecated with end date
        router.WithDeprecatedVersion(
            "v1",
            time.Date(2025, 12, 31, 23, 59, 59, 0, time.UTC),
        ),
        
        // Track version usage
        router.WithVersionObserver(
            router.WithOnDetected(func(version, method string) {
                // Record metrics
                metrics.RecordVersionUsage(version, method)
            }),
            router.WithOnMissing(func() {
                // Client didn't specify version
                log.Warn("client using default version")
            }),
            router.WithOnInvalid(func(attempted string) {
                // Client used invalid version
                metrics.RecordInvalidVersion(attempted)
            }),
        ),
    ),
)
```

### Deprecation Headers

The router automatically adds headers for deprecated versions:

```http
Sunset: Wed, 31 Dec 2025 23:59:59 GMT
Deprecation: true
Link: <https://api.example.com/docs/migration>; rel="deprecation"
```

These tell clients when the version will stop working.

### Deprecation Timeline

**6 months before end:**

1. Announce in release notes
2. Add deprecation header
3. Write migration guide
4. Contact major users

**3 months before end:**

1. Add sunset header with date
2. Email active users
3. Monitor usage (should go down)
4. Offer help with migration

**1 month before end:**

1. Send final warnings
2. Return 410 Gone for deprecated endpoints
3. Link to migration guide

**After end date:**

1. Remove old version code
2. Always return 410 Gone
3. Keep migration documentation

## Best Practices

### 1. Use Semantic Versioning

- **Major (v1, v2, v3):** Breaking changes
- **Minor (v2.1, v2.2):** New features, backward compatible
- **Patch (v2.1.1):** Bug fixes only

### 2. Know When to Version

**Don't version for:**

- Bug fixes
- Performance improvements
- Internal refactoring
- Adding optional fields
- Making validation less strict

**Do version for:**

- Removing fields
- Changing field types
- Making optional field required
- Major behavior changes
- Changing error codes

### 3. Keep Backward Compatibility

```go
// Good: Add optional field
type UserV2 struct {
    ID    int     `json:"id"`
    Name  string  `json:"name"`
    Email string  `json:"email,omitempty"` // New, optional
}

// Bad: Remove field (breaks clients)
type UserV2 struct {
    ID   int    `json:"id"`
    // Name removed - BREAKING CHANGE!
}
```

### 4. Document Version Differences

Keep clear documentation for each version:

```markdown
## API Versions

### v2 (Current)
- Added email field (optional)
- Added address nested object
- Added PATCH support for partial updates

### v1 (Deprecated - Ends 2025-12-31)
- Original API
- Only GET/POST/PUT/DELETE
- Flat structure only
```

### 5. Organize Routes by Version

Group version routes together:

```go
v1 := r.Version("v1")
{
    v1.GET("/users", listUsersV1)
    v1.GET("/users/:id", getUserV1)
    v1.POST("/users", createUserV1)
}

v2 := r.Version("v2")
{
    v2.GET("/users", listUsersV2)
    v2.GET("/users/:id", getUserV2)
    v2.POST("/users", createUserV2)
    v2.PATCH("/users/:id", updateUserV2) // New in v2
}
```

### 6. Validate Versions

Reject invalid versions early:

```go
router.WithVersioning(
    router.WithValidVersions("v1", "v2", "v3", "beta"),
    router.WithVersionObserver(
        router.WithOnInvalid(func(attempted string) {
            log.Warn("invalid API version", "version", attempted)
        }),
    ),
)
```

### 7. Test All Versions

```go
func TestAPIVersions(t *testing.T) {
    r := setupRouter()
    
    tests := []struct{
        version string
        path    string
        want    int
    }{
        {"v1", "/users", 200},
        {"v2", "/users", 200},
        {"v3", "/users", 200},
        {"v99", "/users", 404}, // Invalid
    }
    
    for _, tt := range tests {
        req := httptest.NewRequest("GET", tt.path, nil)
        req.Header.Set("API-Version", tt.version)
        
        w := httptest.NewRecorder()
        r.ServeHTTP(w, req)
        
        assert.Equal(t, tt.want, w.Code)
    }
}
```

## Real-World Examples

### Stripe-Style (Date-Based Versions)

```go
r := router.New(
    router.WithVersioning(
        router.WithHeaderVersioning("Stripe-Version"),
        router.WithDefaultVersion("2024-11-20"),
        router.WithValidVersions(
            "2024-11-20",
            "2024-10-28",
            "2024-09-30",
        ),
    ),
)

// Version by date
v20241120 := r.Version("2024-11-20")
v20241120.GET("/charges", listCharges)
```

### GitHub-Style (Accept Header)

```go
r := router.New(
    router.WithVersioning(
        router.WithAcceptVersioning("application/vnd.github.v{version}+json"),
        router.WithDefaultVersion("v3"),
    ),
)

// Usage: Accept: application/vnd.github.v3+json
```

## Further Reading

- [RFC 7231 - Content Negotiation](https://tools.ietf.org/html/rfc7231#section-5.3)
- [RFC 8594 - Sunset Header](https://tools.ietf.org/html/rfc8594)
- [Semantic Versioning](https://semver.org/)
- [Microsoft API Versioning Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/Guidelines.md#12-versioning)

## Summary

API versioning helps you:

- Make changes without breaking clients
- Support old and new clients at the same time
- Control when to remove old versions
- Track which versions clients use

Choose header-based versioning for most cases. Use query parameters for testing. Document your changes clearly. Give clients time to migrate before removing old versions.
