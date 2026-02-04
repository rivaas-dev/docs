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

### Error

```go
func (c *Context) Error(err error)
```

Sends a formatted error response using the configured formatter.

### ErrorStatus

```go
func (c *Context) ErrorStatus(err error, status int)
```

Sends an error response with explicit status code.

### NotFound

```go
func (c *Context) NotFound(message string)
```

Sends a 404 Not Found error.

### BadRequest

```go
func (c *Context) BadRequest(message string)
```

Sends a 400 Bad Request error.

### Unauthorized

```go
func (c *Context) Unauthorized(message string)
```

Sends a 401 Unauthorized error.

### Forbidden

```go
func (c *Context) Forbidden(message string)
```

Sends a 403 Forbidden error.

### InternalError

```go
func (c *Context) InternalError(err error)
```

Sends a 500 Internal Server Error.

## Logging

### Logger

```go
func (c *Context) Logger() *slog.Logger
```

Returns the request-scoped logger with automatic context (HTTP metadata, trace IDs, request ID). Never returns nil.

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
