---
title: "Context API"
linkTitle: "Context API"
keywords:
  - router context
  - context api
  - request handling
  - response methods
weight: 30
description: >
  Complete reference for Context methods.
---

The `Context` provides access to request/response and utility methods.

{{% alert title="Memory Safety" color="warning" %}}
Context objects are pooled and reused. **Never** store references to Context beyond the request handler. Check [Context Guide](/guides/router/context/) for details.
{{% /alert %}}

## Request Information

### URL Parameters

```go
c.Param(key string) string
```

Returns URL parameter value from the route path.

```go
// Route: /users/:id
userID := c.Param("id")
```

```go
c.AllParams() map[string]string
```

Returns all URL path parameters as a map.

### Query Parameters

```go
c.Query(key string) string
c.QueryDefault(key, defaultValue string) string
c.AllQueries() map[string]string
```

```go
// GET /search?q=golang&page=2
query := c.Query("q")           // "golang"
page := c.QueryDefault("page", "1") // "2"
all := c.AllQueries()           // map[string]string{"q": "golang", "page": "2"}
```

### Form Data

```go
c.FormValue(key string) string
c.FormValueDefault(key, defaultValue string) string
```

Returns form parameter from POST request body.

```go
// POST with form data
username := c.FormValue("username")
role := c.FormValueDefault("role", "user")
```

### Headers

```go
c.Request.Header.Get(key string) string
c.RequestHeaders() map[string]string
c.ResponseHeaders() map[string]string
```

## Request Binding

{{% alert title="Note" color="info" %}}
For request binding, use the separate [binding package](/reference/packages/binding/) or the [app package](/guides/app/) for integrated binding with validation.
{{% /alert %}}

### Content Type Validation

```go
c.RequireContentType(allowed ...string) bool
c.RequireContentTypeJSON() bool
```

```go
if !c.RequireContentTypeJSON() {
    return // 415 Unsupported Media Type already sent
}
```

### Streaming

```go
// Stream JSON array items
router.StreamJSONArray[T](c *Context, each func(T) error, maxItems int) error

// Stream NDJSON (newline-delimited JSON)
router.StreamNDJSON[T](c *Context, each func(T) error) error
```

```go
err := router.StreamJSONArray(c, func(item User) error {
    return processUser(item)
}, 10000) // Max 10k items
```

## Response Methods

### JSON Responses

```go
c.JSON(code int, obj any) error
c.IndentedJSON(code int, obj any) error
c.PureJSON(code int, obj any) error      // No HTML escaping
c.SecureJSON(code int, obj any, prefix ...string) error
c.ASCIIJSON(code int, obj any) error     // All non-ASCII escaped
```

### Other Formats

```go
c.YAML(code int, obj any) error
c.String(code int, value string) error
c.Stringf(code int, format string, values ...any) error
c.HTML(code int, html string) error
```

### Binary & Streaming

```go
c.Data(code int, contentType string, data []byte) error
c.DataFromReader(code int, contentLength int64, contentType string, reader io.Reader, extraHeaders map[string]string) error
```

### File Serving

```go
c.ServeFile(filepath string)
```

### Status & No Content

```go
c.Status(code int)
c.NoContent()
```

### Error Responses

```go
c.WriteErrorResponse(status int, message string)
c.NotFound()
c.MethodNotAllowed(allowed []string)
```

## Headers

```go
c.Header(key, value string)
```

Sets a response header with automatic security sanitization (newlines stripped).

## URL Information

```go
c.Hostname() string    // Host without port
c.Port() string        // Port number
c.Scheme() string      // "http" or "https"
c.BaseURL() string     // scheme + host
c.FullURL() string     // Complete URL with query string
```

## Client Information

```go
c.ClientIP() string      // Real client IP (respects trusted proxies)
c.ClientIPs() []string   // All IPs from X-Forwarded-For chain
c.IsHTTPS() bool         // Request over HTTPS
c.IsLocalhost() bool     // Request from localhost
c.IsXHR() bool           // XMLHttpRequest (AJAX)
c.Subdomains(offset ...int) []string
```

## Content Type Detection

```go
c.IsJSON() bool      // Content-Type is application/json
c.IsXML() bool       // Content-Type is application/xml or text/xml
c.AcceptsJSON() bool // Accept header includes application/json
c.AcceptsHTML() bool // Accept header includes text/html
```

## Content Negotiation

```go
c.Accepts(offers ...string) string
c.AcceptsCharsets(offers ...string) string
c.AcceptsEncodings(offers ...string) string
c.AcceptsLanguages(offers ...string) string
```

```go
// Accept: application/json, text/html;q=0.9
best := c.Accepts("json", "html", "xml") // "json"

// Accept-Language: en-US, fr;q=0.8
lang := c.AcceptsLanguages("en", "fr", "de") // "en"
```

## Caching

```go
c.IsFresh() bool  // Response still fresh in client cache
c.IsStale() bool  // Client cache is stale
```

```go
if c.IsFresh() {
    c.Status(http.StatusNotModified) // 304
    return
}
```

## Redirects

```go
c.Redirect(code int, location string)
```

```go
c.Redirect(http.StatusFound, "/login")
c.Redirect(http.StatusMovedPermanently, "https://newdomain.com")
```

## Cookies

```go
c.SetCookie(name, value string, maxAge int, path, domain string, secure, httpOnly bool)
c.GetCookie(name string) (string, error)
```

## File Uploads

```go
c.File(name string) (*File, error)
c.Files(name string) ([]*File, error)
```

**File methods:**

```go
file.Bytes() ([]byte, error)
file.Open() (io.ReadCloser, error)
file.Save(dst string) error
file.Ext() string
```

```go
file, err := c.File("avatar")
if err != nil {
    return c.JSON(400, map[string]string{"error": "avatar required"})
}
file.Save("./uploads/" + uuid.New().String() + file.Ext())
```

## Middleware Control

```go
c.Next()           // Execute next handler in chain
c.Abort()          // Stop handler chain
c.IsAborted() bool // Check if chain was aborted
```

## Error Collection

```go
c.Error(err error)      // Collect error without writing response
c.Errors() []error      // Get all collected errors
c.HasErrors() bool      // Check if errors were collected
```

> **Note:** `router.Context.Error()` collects errors without writing a response or aborting the handler chain. This is useful for gathering multiple errors before deciding how to respond.
>
> To send an error response immediately, use `app.Context.Fail()` which formats the error, writes the response, and stops the handler chain.

```go
if err := validateUser(c); err != nil {
    c.Error(err)
}
if err := validateEmail(c); err != nil {
    c.Error(err)
}

if c.HasErrors() {
    c.JSON(400, map[string]any{"errors": c.Errors()})
    return
}
```

## Context Access

```go
c.RequestContext() context.Context  // Request's context.Context
c.TraceContext() context.Context    // OpenTelemetry trace context
```

## Tracing & Metrics

### Tracing

```go
c.TraceID() string
c.SpanID() string
c.Span() trace.Span
c.SetSpanAttribute(key string, value any)
c.AddSpanEvent(name string, attrs ...attribute.KeyValue)
```

### Metrics

```go
c.RecordMetric(name string, value float64, attributes ...attribute.KeyValue)
c.IncrementCounter(name string, attributes ...attribute.KeyValue)
c.SetGauge(name string, value float64, attributes ...attribute.KeyValue)
```

## Versioning

```go
c.Version() string           // Current API version ("v1", "v2", etc.)
c.IsVersion(version string) bool
c.RoutePattern() string      // Matched route pattern ("/users/:id")
```

## Complete Example

```go
func handler(c *router.Context) {
    // Parameters
    id := c.Param("id")
    query := c.Query("q")
    
    // Headers
    auth := c.Request.Header.Get("Authorization")
    c.Header("X-Custom", "value")
    
    // Strict binding (for full binding, use binding package)
    var req CreateRequest
    if err := c.BindStrict(&req, router.BindOptions{MaxBytes: 1 << 20}); err != nil {
        return // Error response already written
    }
    
    // Tracing
    c.SetSpanAttribute("user.id", id)
    
    // Logging (pass request context for trace correlation)
    slog.InfoContext(c.RequestContext(), "processing request", "user_id", id)
    
    // Response
    if err := c.JSON(200, map[string]string{
        "id":    id,
        "query": query,
    }); err != nil {
        slog.ErrorContext(c.RequestContext(), "failed to write response", "error", err)
    }
}
```

## Next Steps

- **API Reference**: See [core types](../api-reference/)
- **Context Guide**: Learn about [Context usage](/guides/router/context/)
- **Binding Package**: For full request binding, see [binding package](/reference/packages/binding/)
