---
title: "Middleware Options"
description: "HTTP middleware configuration options reference"
keywords:
  - middleware options
  - http metrics
  - request metrics
  - metrics middleware
weight: 3
---

Complete reference for `MiddlewareOption` functions used to configure the HTTP metrics middleware.

## Overview

Middleware options configure which paths to exclude from metrics collection and which headers to record.

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health", "/metrics"),
    metrics.WithExcludePrefixes("/debug/"),
    metrics.WithExcludePatterns(`^/admin/.*`),
    metrics.WithHeaders("X-Request-ID"),
)(httpHandler)
```

## Path Exclusion Options

### WithExcludePaths

```go
func WithExcludePaths(paths ...string) MiddlewareOption
```

Excludes exact paths from metrics collection.

**Parameters**:
- `paths ...string` - Exact paths to exclude

**Example**:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health", "/metrics", "/ready"),
)(mux)
```

**Use Cases**:
- Health check endpoints.
- Metrics endpoints.
- Readiness and liveness probes.

**Behavior**:
- Matches exact path only.
- Case-sensitive.
- Does not match path prefixes.

**Examples**:

```go
// Excluded paths
/health          ✓ excluded
/metrics         ✓ excluded
/ready           ✓ excluded

// Not excluded (not exact matches)
/health/status   ✗ not excluded
/healthz         ✗ not excluded
/api/metrics     ✗ not excluded
```

### WithExcludePrefixes

```go
func WithExcludePrefixes(prefixes ...string) MiddlewareOption
```

Excludes all paths with specific prefixes from metrics collection.

**Parameters**:
- `prefixes ...string` - Path prefixes to exclude

**Example**:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePrefixes("/debug/", "/internal/", "/_/"),
)(mux)
```

**Use Cases**:
- Debug endpoints (`/debug/pprof/`, `/debug/vars/`)
- Internal APIs (`/internal/`)
- Administrative paths (`/_/`)

**Behavior**:
- Matches any path starting with prefix
- Case-sensitive
- Include trailing slash for directory prefixes

**Examples**:

```go
// With prefix "/debug/"
/debug/pprof/heap      ✓ excluded
/debug/vars            ✓ excluded
/debug/                ✓ excluded

// Not excluded
/debuginfo             ✗ not excluded (no slash)
/api/debug             ✗ not excluded (doesn't start with prefix)
```

### WithExcludePatterns

```go
func WithExcludePatterns(patterns ...string) MiddlewareOption
```

Excludes paths matching regex patterns from metrics collection.

**Parameters**:
- `patterns ...string` - Regular expression patterns

**Example**:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePatterns(
        `^/v[0-9]+/internal/.*`,  // /v1/internal/*, /v2/internal/*
        `^/api/[0-9]+$`,           // /api/123, /api/456
        `^/admin/.*`,              // /admin/*
    ),
)(mux)
```

**Use Cases**:
- Version-specific internal paths
- High-cardinality routes (IDs in path)
- Pattern-based exclusions

**Behavior**:
- Uses Go's `regexp` package
- Matches full path
- Case-sensitive (use `(?i)` for case-insensitive)

**Examples**:

```go
// Pattern: `^/v[0-9]+/internal/.*`
/v1/internal/metrics   ✓ excluded
/v2/internal/debug     ✓ excluded

// Not excluded
/internal/api          ✗ not excluded (no version)
/api/v1/internal       ✗ not excluded (doesn't start with /v)

// Pattern: `^/api/[0-9]+$`
/api/123               ✓ excluded
/api/456               ✓ excluded

// Not excluded
/api/users             ✗ not excluded (not numeric)
/api/123/details       ✗ not excluded (has suffix)
```

**Pattern Tips**:

```go
// Anchors
^      // Start of path
$      // End of path

// Character classes
[0-9]  // Any digit
[a-z]  // Any lowercase letter
.      // Any character
\d     // Any digit

// Quantifiers
*      // Zero or more
+      // One or more
?      // Zero or one
{n}    // Exactly n

// Grouping
(...)  // Group

// Case-insensitive
(?i)pattern  // Case-insensitive match
```

### Combining Exclusions

Use multiple exclusion options together:

```go
handler := metrics.Middleware(recorder,
    // Exact paths
    metrics.WithExcludePaths("/health", "/metrics", "/ready"),
    
    // Prefixes
    metrics.WithExcludePrefixes("/debug/", "/internal/", "/_/"),
    
    // Patterns
    metrics.WithExcludePatterns(
        `^/v[0-9]+/internal/.*`,
        `^/api/users/[0-9]+$`,  // User IDs in path
    ),
)(mux)
```

**Evaluation Order**:
1. Exact paths (`WithExcludePaths`)
2. Prefixes (`WithExcludePrefixes`)
3. Patterns (`WithExcludePatterns`)

If any exclusion matches, the path is excluded.

## Header Recording Options

### WithHeaders

```go
func WithHeaders(headers ...string) MiddlewareOption
```

Records specific HTTP headers as metric attributes.

**Parameters**:
- `headers ...string` - Header names to record

**Example**:

```go
handler := metrics.Middleware(recorder,
    metrics.WithHeaders("X-Request-ID", "X-Correlation-ID", "X-Client-Version"),
)(mux)
```

**Behavior**:
- Headers recorded as metric attributes
- Header names normalized (lowercase, hyphens to underscores)
- Sensitive headers automatically filtered

**Header Normalization**:

```go
// Original header → Metric attribute
X-Request-ID       → x_request_id
X-Correlation-ID   → x_correlation_id
Content-Type       → content_type
User-Agent         → user_agent
```

**Example Metric**:

```
http_requests_total{
    method="GET",
    path="/api/users",
    status="200",
    x_request_id="abc123",
    x_correlation_id="def456"
} 1
```

### Sensitive Header Filtering

The middleware automatically filters sensitive headers, even if explicitly requested.

**Always Filtered Headers**:
- `Authorization`
- `Cookie`
- `Set-Cookie`
- `X-API-Key`
- `X-Auth-Token`
- `Proxy-Authorization`
- `WWW-Authenticate`

**Example**:

```go
// Only X-Request-ID will be recorded
// Authorization and Cookie are automatically filtered
handler := metrics.Middleware(recorder,
    metrics.WithHeaders(
        "Authorization",      // ✗ Filtered (sensitive)
        "X-Request-ID",       // ✓ Recorded
        "Cookie",             // ✗ Filtered (sensitive)
        "X-Correlation-ID",   // ✓ Recorded
    ),
)(mux)
```

**Why Filter?**
- Prevent credential leaks in metrics
- Avoid exposing API keys
- Comply with security policies
- Prevent compliance violations

## Configuration Examples

### Basic Health Check Exclusion

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health", "/ready"),
)(mux)
```

### Development/Debug Exclusion

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health", "/metrics"),
    metrics.WithExcludePrefixes("/debug/", "/_/"),
)(mux)
```

### High-Cardinality Path Exclusion

```go
handler := metrics.Middleware(recorder,
    // Exclude paths with IDs to avoid high cardinality
    metrics.WithExcludePatterns(
        `^/api/users/[0-9]+$`,         // /api/users/123
        `^/api/orders/[a-z0-9-]+$`,    // /api/orders/abc-123
        `^/files/[^/]+$`,              // /files/{id}
    ),
)(mux)
```

### Request Tracing

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health"),
    metrics.WithHeaders("X-Request-ID", "X-Correlation-ID", "X-Trace-ID"),
)(mux)
```

### Production Configuration

```go
handler := metrics.Middleware(recorder,
    // Exclude operational endpoints
    metrics.WithExcludePaths(
        "/health",
        "/ready",
        "/metrics",
        "/favicon.ico",
    ),
    
    // Exclude administrative paths
    metrics.WithExcludePrefixes(
        "/debug/",
        "/internal/",
        "/_/",
    ),
    
    // Exclude high-cardinality routes
    metrics.WithExcludePatterns(
        `^/api/v[0-9]+/internal/.*`,
        `^/api/users/[0-9]+$`,
        `^/api/orders/[a-z0-9-]+$`,
    ),
    
    // Record tracing headers
    metrics.WithHeaders(
        "X-Request-ID",
        "X-Correlation-ID",
        "X-Client-Version",
    ),
)(mux)
```

## Best Practices

### Path Exclusions

**DO**:
- Exclude health and readiness checks
- Exclude metrics endpoints
- Exclude high-cardinality paths (IDs)
- Exclude debug and administrative paths

**DON'T**:
- Over-exclude (you need some metrics!)
- Exclude business-critical endpoints
- Use overly broad patterns

### Header Recording

**DO**:
- Record low-cardinality headers only
- Use headers for request tracing
- Consider privacy implications

**DON'T**:
- Record sensitive headers (automatically filtered)
- Record high-cardinality headers (user IDs, timestamps)
- Record excessive headers (increases metric cardinality)

### Cardinality Management

High cardinality leads to:
- Excessive memory usage
- Slow query performance
- Storage bloat

**Low Cardinality** (Good):

```go
// Headers with limited values
X-Client-Version: v1.0, v1.1, v2.0  (3 values)
X-Region: us-east-1, eu-west-1      (2 values)
```

**High Cardinality** (Bad):

```go
// Headers with unbounded values
X-Request-ID: abc123, def456, ...   (millions of values)
X-Timestamp: 2025-01-18T10:30:00Z   (always unique)
X-User-ID: user123, user456, ...    (millions of values)
```

## Performance Considerations

### Path Evaluation Overhead

- **Exact paths**: O(1) hash lookup
- **Prefixes**: O(n) prefix checks (n = number of prefixes)
- **Patterns**: O(n) regex matches (n = number of patterns)

**Recommendation**: Use exact paths when possible for best performance.

### Header Recording Impact

Each header adds:
- Additional metric attribute
- Increased metric cardinality
- Higher memory usage

**Recommendation**: Only record necessary headers.

## Troubleshooting

### Path Not Excluded

Check:
1. Path is exact match (use `WithExcludePaths`)
2. Prefix includes trailing slash
3. Pattern uses correct regex syntax
4. Pattern is anchored (`^` and `$`)

### Header Not Recorded

Check:
1. Header name is correct (case-insensitive)
2. Header is not in sensitive list
3. Header is present in request

### High Memory Usage

Check:
1. Too many unique paths (exclude high-cardinality routes)
2. Too many header combinations
3. Recording high-cardinality headers

## Next Steps

- See [API Reference](../api-reference/) for middleware function
- Read [Middleware Guide](/guides/metrics/middleware/) for detailed examples
- Check [Configuration](/guides/metrics/configuration/) for histogram tuning
- Review [Troubleshooting](../troubleshooting/) for common issues
