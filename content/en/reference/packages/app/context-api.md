---
title: "Context API"
linkTitle: "Context API"
keywords:
  - context api
  - request context
  - response methods
  - context methods
weight: 7
description: >
  Context methods for request handling.
---

## Request Binding

### Bind

```go
func (c *Context) Bind(out any, opts ...BindOption) error
```

Binds request data and validates it. This is the main method for handling requests.

Reads data from all sources (path, query, headers, cookies, JSON, forms) based on struct tags. Then validates the data using the configured strategy.

**Returns:** Error if binding or validation fails.

### MustBind

```go
func (c *Context) MustBind(out any, opts ...BindOption) bool
```

Binds and validates, automatically sending error responses on failure.

Use this when you want simple error handling. If binding or validation fails, it sends the error response and returns false.

**Returns:** True if successful, false if error was sent.

### BindOnly

```go
func (c *Context) BindOnly(out any, opts ...BindOption) error
```

Binds request data without validation.

Use this when you need to process data before validating it.

**Returns:** Error if binding fails.

### Validate

```go
func (c *Context) Validate(v any, opts ...validation.Option) error
```

Validates a struct using the configured strategy.

Use this after `BindOnly()` when you need fine-grained control.

**Returns:** Validation error if validation fails.

## Error Handling

All error handling methods automatically format the error response and abort the handler chain. No further handlers will run after calling these methods.

### Fail

```go
func (c *Context) Fail(err error)
```

Sends a formatted error response using the configured formatter. The HTTP status code is determined from the error (if it implements `HTTPStatus() int`) or defaults to 500.

**Parameters:**
- `err`: The error to send. If `nil`, the method returns without doing anything.

**Behavior:**
- Formats the error using content negotiation
- Writes the HTTP response
- Aborts the handler chain

### FailStatus

```go
func (c *Context) FailStatus(status int, err error)
```

Sends an error response with an explicit HTTP status code.

**Parameters:**
- `status`: The HTTP status code to use
- `err`: The error to send

**Behavior:**
- Wraps the error with the specified status code
- Formats and sends the response
- Aborts the handler chain

### NotFound

```go
func (c *Context) NotFound(err error)
```

Sends a 404 Not Found error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Not Found" message

### BadRequest

```go
func (c *Context) BadRequest(err error)
```

Sends a 400 Bad Request error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Bad Request" message

### Unauthorized

```go
func (c *Context) Unauthorized(err error)
```

Sends a 401 Unauthorized error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Unauthorized" message

### Forbidden

```go
func (c *Context) Forbidden(err error)
```

Sends a 403 Forbidden error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Forbidden" message

### Conflict

```go
func (c *Context) Conflict(err error)
```

Sends a 409 Conflict error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Conflict" message

### Gone

```go
func (c *Context) Gone(err error)
```

Sends a 410 Gone error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Gone" message

### UnprocessableEntity

```go
func (c *Context) UnprocessableEntity(err error)
```

Sends a 422 Unprocessable Entity error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Unprocessable Entity" message

### TooManyRequests

```go
func (c *Context) TooManyRequests(err error)
```

Sends a 429 Too Many Requests error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Too Many Requests" message

### InternalError

```go
func (c *Context) InternalError(err error)
```

Sends a 500 Internal Server Error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Internal Server Error" message

### ServiceUnavailable

```go
func (c *Context) ServiceUnavailable(err error)
```

Sends a 503 Service Unavailable error response.

**Parameters:**
- `err`: The error to send, or `nil` for a generic "Service Unavailable" message

## Logging

To log from a handler with trace correlation, pass the request context to the standard library's context-aware logging functions. For example: `slog.InfoContext(c.RequestContext(), "msg", ...)` or `slog.ErrorContext(c.RequestContext(), "msg", ...)`. When the app is configured with observability (logging and tracing), `trace_id` and `span_id` are injected automatically from the active OpenTelemetry span.

## Presence

### Presence

```go
func (c *Context) Presence() validation.PresenceMap
```

Returns the presence map for the current request (tracks which fields were present in JSON).

### ResetBinding

```go
func (c *Context) ResetBinding()
```

Resets binding metadata (useful for testing).

## Router Context

The app Context embeds `router.Context`, providing access to all router features:

- `c.Request` - HTTP request
- `c.Response` - HTTP response writer
- `c.Param(name)` - Path parameter
- `c.Query(name)` - Query parameter
- `c.JSON(status, data)` - Send JSON response
- `c.String(status, text)` - Send text response
- `c.HTML(status, html)` - Send HTML response
- And more...

See [Router Context API](/reference/packages/router/context-api/) for complete router context reference.
