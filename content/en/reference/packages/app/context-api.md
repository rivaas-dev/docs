---
title: "Context API"
linkTitle: "Context API"
weight: 7
description: >
  Context methods for request handling.
---

## Request Binding

### Bind

```go
func (c *Context) Bind(out any) error
```

Automatically binds from all relevant sources based on struct tags (path, query, header, cookie, json, form).

### BindJSONStrict

```go
func (c *Context) BindJSONStrict(out any) error
```

Binds JSON with unknown field rejection.

### BindAndValidate

```go
func (c *Context) BindAndValidate(out any, opts ...validation.Option) error
```

Binds and validates in one call.

### BindAndValidateStrict

```go
func (c *Context) BindAndValidateStrict(out any, opts ...validation.Option) error
```

Binds JSON strictly (rejects unknown fields) and validates.

### MustBindAndValidate

```go
func (c *Context) MustBindAndValidate(out any, opts ...validation.Option) bool
```

Binds and validates, automatically sending error responses on failure. Returns true if successful.

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
