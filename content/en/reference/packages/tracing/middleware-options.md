---
title: "Middleware Options"
description: "All configuration options for HTTP middleware"
keywords:
  - middleware options
  - http tracing
  - request tracing
  - tracing middleware
weight: 3
---

Complete reference for all `MiddlewareOption` functions used to configure the HTTP tracing middleware.

## MiddlewareOption Type

```go
type MiddlewareOption func(*middlewareConfig)
```

Configuration option function type used with `Middleware()` and `MustMiddleware()`. These options control HTTP request tracing behavior.

## Path Exclusion Options

Exclude specific paths from tracing to reduce noise and overhead.

### WithExcludePaths

```go
func WithExcludePaths(paths ...string) MiddlewareOption
```

Excludes specific paths from tracing. Excluded paths will not create spans or record any tracing data. This is useful for health checks, metrics endpoints, etc.

Maximum of 1000 paths can be excluded to prevent unbounded growth.

**Parameters:**
- `paths`: Exact paths to exclude (e.g., `"/health"`, `"/metrics"`)

**Performance:** O(1) hash map lookup

**Example:**

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics", "/ready", "/live"),
)(mux)
```

### WithExcludePrefixes

```go
func WithExcludePrefixes(prefixes ...string) MiddlewareOption
```

Excludes paths with the given prefixes from tracing. This is useful for excluding entire path hierarchies like `/debug/`, `/internal/`, etc.

**Parameters:**
- `prefixes`: Path prefixes to exclude (e.g., `"/debug/"`, `"/internal/"`)

**Performance:** O(n) where n = number of prefixes

**Example:**

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePrefixes("/debug/", "/internal/", "/.well-known/"),
)(mux)
```

**Matches:**
- `/debug/pprof`
- `/debug/vars`
- `/internal/health`
- `/.well-known/acme-challenge`

### WithExcludePatterns

```go
func WithExcludePatterns(patterns ...string) MiddlewareOption
```

Excludes paths matching the given regex patterns from tracing. The patterns are compiled once during configuration. Returns a validation error if any pattern fails to compile.

**Parameters:**
- `patterns`: Regular expression patterns (e.g., `"^/v[0-9]+/internal/.*"`)

**Performance:** O(p) where p = number of patterns

**Validation:** Invalid regex patterns cause the middleware to panic during initialization.

**Example:**

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePatterns(
        `^/v[0-9]+/internal/.*`,  // Version-prefixed internal routes
        `^/api/health.*`,          // Any health-related endpoint
        `^/debug/.*`,              // All debug routes
    ),
)(mux)
```

**Matches:**
- `/v1/internal/status`
- `/v2/internal/debug`
- `/api/health`
- `/api/health/db`
- `/debug/pprof/heap`

## Header Recording Options

### WithHeaders

```go
func WithHeaders(headers ...string) MiddlewareOption
```

Records specific request headers as span attributes. Header names are case-insensitive. Recorded as `http.request.header.{name}`.

**Security:** Sensitive headers (Authorization, Cookie, etc.) are automatically filtered out to prevent accidental exposure of credentials in traces.

**Parameters:**
- `headers`: Header names to record (case-insensitive)

**Recorded as:** Lowercase header names (`http.request.header.x-request-id`)

**Example:**

```go
handler := tracing.Middleware(tracer,
    tracing.WithHeaders("X-Request-ID", "X-Correlation-ID", "User-Agent"),
)(mux)
```

**Span attributes:**
- `http.request.header.x-request-id`: `"abc123"`
- `http.request.header.x-correlation-id`: `"xyz789"`
- `http.request.header.user-agent`: `"Mozilla/5.0..."`

### Sensitive Header Filtering

The following headers are **automatically filtered** and will never be recorded, even if explicitly included:

- `Authorization`
- `Cookie`
- `Set-Cookie`
- `X-API-Key`
- `X-Auth-Token`
- `Proxy-Authorization`
- `WWW-Authenticate`

**Example:**

```go
// Authorization is automatically filtered
handler := tracing.Middleware(tracer,
    tracing.WithHeaders(
        "X-Request-ID",
        "Authorization", // ← Filtered, won't be recorded
        "X-Correlation-ID",
    ),
)(mux)
```

## Query Parameter Recording Options

### Default Behavior

By default, **all** query parameters are recorded as span attributes.

### WithRecordParams

```go
func WithRecordParams(params ...string) MiddlewareOption
```

Specifies which URL query parameters to record as span attributes. Only parameters in this list will be recorded. This provides fine-grained control over which parameters are traced.

If this option is not used, all query parameters are recorded by default (unless `WithoutParams` is used).

**Parameters:**
- `params`: Parameter names to record

**Recorded as:** `http.request.param.{name}`

**Example:**

```go
handler := tracing.Middleware(tracer,
    tracing.WithRecordParams("user_id", "request_id", "page", "limit"),
)(mux)
```

**Request:** `GET /api/users?page=2&limit=10&user_id=123&secret=xyz`

**Span attributes:**
- `http.request.param.page`: `["2"]`
- `http.request.param.limit`: `["10"]`
- `http.request.param.user_id`: `["123"]`
- `secret` is **not recorded** (not in whitelist)

### WithExcludeParams

```go
func WithExcludeParams(params ...string) MiddlewareOption
```

Specifies which URL query parameters to exclude from tracing. This is useful for blacklisting sensitive parameters while recording all others.

Parameters in this list will never be recorded, even if `WithRecordParams` includes them (blacklist takes precedence).

**Parameters:**
- `params`: Parameter names to exclude

**Example:**

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludeParams("password", "token", "api_key", "secret"),
)(mux)
```

**Request:** `GET /api/users?page=2&password=secret123&user_id=123`

**Span attributes:**
- `http.request.param.page`: `["2"]`
- `http.request.param.user_id`: `["123"]`
- `password` is **not recorded** (blacklisted)

### WithoutParams

```go
func WithoutParams() MiddlewareOption
```

Disables recording URL query parameters as span attributes. By default, all query parameters are recorded. Use this option if parameters may contain sensitive data.

**Example:**

```go
handler := tracing.Middleware(tracer,
    tracing.WithoutParams(),
)(mux)
```

No query parameters will be recorded regardless of the request.

### Parameter Recording Precedence

When multiple parameter options are used:

1. **`WithoutParams()`** - If set, no parameters are recorded
2. **`WithExcludeParams()`** - Blacklist takes precedence over whitelist
3. **`WithRecordParams()`** - Only whitelisted parameters are recorded
4. **Default** - All parameters are recorded

**Example:**

```go
// Whitelist with blacklist
handler := tracing.Middleware(tracer,
    tracing.WithRecordParams("page", "limit", "sort", "api_key"),
    tracing.WithExcludeParams("api_key", "token"), // Blacklist overrides
)(mux)
```

**Result:** `page`, `limit`, and `sort` are recorded, but `api_key` is excluded (blacklist wins).

## Middleware Functions

### Middleware

```go
func Middleware(tracer *Tracer, opts ...MiddlewareOption) func(http.Handler) http.Handler
```

Creates a middleware function for standalone HTTP integration. Panics if any middleware option is invalid (e.g., invalid regex pattern).

**Parameters:**
- `tracer`: Tracer instance
- `opts`: Middleware configuration options

**Returns:** HTTP middleware function

**Panics:** If middleware options are invalid

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithOTLP("localhost:4317"),
)

handler := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics"),
    tracing.WithHeaders("X-Request-ID"),
)(mux)
```

### MustMiddleware

```go
func MustMiddleware(tracer *Tracer, opts ...MiddlewareOption) func(http.Handler) http.Handler
```

Creates a middleware function for standalone HTTP integration. It panics if any middleware option is invalid (e.g., invalid regex pattern). This is a convenience wrapper around `Middleware` for consistency with `MustNew`.

**Behavior:** Identical to `Middleware()` - both panic on invalid options.

**Example:**

```go
handler := tracing.MustMiddleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics"),
    tracing.WithHeaders("X-Request-ID"),
)(mux)
```

## Complete Examples

### Minimal Middleware

```go
// Trace everything with no filtering
handler := tracing.Middleware(tracer)(mux)
```

### Production Middleware

```go
handler := tracing.Middleware(tracer,
    // Exclude observability endpoints
    tracing.WithExcludePaths("/health", "/metrics", "/ready", "/live"),
    
    // Exclude debug endpoints
    tracing.WithExcludePrefixes("/debug/", "/internal/"),
    
    // Record correlation headers
    tracing.WithHeaders("X-Request-ID", "X-Correlation-ID"),
    
    // Whitelist safe parameters
    tracing.WithRecordParams("page", "limit", "sort", "filter"),
    
    // Blacklist sensitive parameters
    tracing.WithExcludeParams("password", "token", "api_key"),
)(mux)
```

### Development Middleware

```go
handler := tracing.Middleware(tracer,
    // Only exclude metrics
    tracing.WithExcludePaths("/metrics"),
    
    // Record all headers (except sensitive ones)
    tracing.WithHeaders("X-Request-ID", "X-Correlation-ID", "User-Agent"),
)(mux)
```

### High-Security Middleware

```go
handler := tracing.Middleware(tracer,
    // Exclude health checks
    tracing.WithExcludePaths("/health"),
    
    // No headers recorded
    // No query parameters recorded
    tracing.WithoutParams(),
)(mux)
```

## Performance Considerations

### Path Exclusion Performance

| Method | Complexity | Performance |
|--------|-----------|-------------|
| `WithExcludePaths()` | O(1) | ~9ns per request (hash lookup) |
| `WithExcludePrefixes()` | O(n) | ~9ns per request (n prefixes) |
| `WithExcludePatterns()` | O(p) | ~20ns per request (p patterns) |

**Recommendation:** Use exact paths when possible for best performance.

### Memory Usage

- **Path exclusion**: ~100 bytes per path
- **Header recording**: ~50 bytes per header
- **Parameter recording**: ~30 bytes per parameter name

### Limits

- **Maximum excluded paths:** 1000 (enforced by `WithExcludePaths`)
- **No limit on:** Prefixes, patterns, headers, parameters

## Validation Errors

Configuration is validated when calling `Middleware()` or `MustMiddleware()`. Invalid options cause a panic.

### Invalid Regex Pattern

```go
// ✗ Panics: invalid regex
handler := tracing.Middleware(tracer,
    tracing.WithExcludePatterns(`[invalid regex`),
)(mux)
// Panics: "middleware validation errors: excludePatterns: invalid regex..."
```

**Solution:** Ensure regex patterns are valid.

## Option Reference Table

| Option | Description | Default Behavior |
|--------|-------------|------------------|
| `WithExcludePaths(paths...)` | Exclude exact paths | All paths traced |
| `WithExcludePrefixes(prefixes...)` | Exclude by prefix | All paths traced |
| `WithExcludePatterns(patterns...)` | Exclude by regex | All paths traced |
| `WithHeaders(headers...)` | Record headers | No headers recorded |
| `WithRecordParams(params...)` | Whitelist params | All params recorded |
| `WithExcludeParams(params...)` | Blacklist params | No params excluded |
| `WithoutParams()` | Disable params | All params recorded |

## Best Practices

### Always Exclude Health Checks

```go
tracing.WithExcludePaths("/health", "/metrics", "/ready", "/live")
```

Health checks are high-frequency and low-value for tracing.

### Use Exact Paths for Common Exclusions

```go
// ✓ Good - fastest
tracing.WithExcludePaths("/health", "/metrics")

// ✗ Less optimal - slower
tracing.WithExcludePatterns("^/(health|metrics)$")
```

### Blacklist Sensitive Parameters

```go
tracing.WithExcludeParams(
    "password", "token", "api_key", "secret",
    "credit_card", "ssn", "access_token",
)
```

### Record Correlation Headers

```go
tracing.WithHeaders("X-Request-ID", "X-Correlation-ID", "X-Trace-ID")
```

Helps correlate traces with logs and other observability data.

### Combine Exclusion Methods

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics"),      // Exact
    tracing.WithExcludePrefixes("/debug/", "/internal/"), // Prefix
    tracing.WithExcludePatterns(`^/v[0-9]+/internal/.*`), // Regex
)(mux)
```

## Next Steps

- Review [Options](../options/) for Tracer configuration
- Check [API Reference](../api-reference/) for all methods
- See the [Middleware Guide](/guides/tracing/middleware/) for usage examples
