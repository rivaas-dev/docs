---
title: "Server Options"
linkTitle: "Server Options"
weight: 3
description: >
  Server configuration options reference.
---

## Server Options

These options are used with `WithServer()`:

```go
app.WithServer(
    app.WithReadTimeout(10 * time.Second),
    app.WithWriteTimeout(15 * time.Second),
)
```

## Timeout Options

### WithReadTimeout

```go
func WithReadTimeout(d time.Duration) ServerOption
```

Maximum time to read entire request (including body). Must be positive.

**Default:** `10s`

### WithWriteTimeout

```go
func WithWriteTimeout(d time.Duration) ServerOption
```

Maximum time to write response. Must be positive. Should be >= ReadTimeout.

**Default:** `10s`

### WithIdleTimeout

```go
func WithIdleTimeout(d time.Duration) ServerOption
```

Maximum time to wait for next request on keep-alive connection. Must be positive.

**Default:** `60s`

### WithReadHeaderTimeout

```go
func WithReadHeaderTimeout(d time.Duration) ServerOption
```

Maximum time to read request headers. Must be positive.

**Default:** `2s`

### WithShutdownTimeout

```go
func WithShutdownTimeout(d time.Duration) ServerOption
```

Graceful shutdown timeout. Must be at least 1 second.

**Default:** `30s`

## Size Options

### WithMaxHeaderBytes

```go
func WithMaxHeaderBytes(n int) ServerOption
```

Maximum request header size in bytes. Must be at least 1KB (1024 bytes).

**Default:** `1MB` (1048576 bytes)

## Validation

Configuration is automatically validated:

- All timeouts must be positive
- ReadTimeout should not exceed WriteTimeout
- ShutdownTimeout must be at least 1 second
- MaxHeaderBytes must be at least 1KB

Invalid configuration causes `app.New()` to return an error.
