---
title: "Debug Options"
linkTitle: "Debug Options"
weight: 6
description: >
  Debug endpoint configuration options reference.
---

## Debug Options

These options are used with `WithDebugEndpoints()`:

```go
app.WithDebugEndpoints(
    app.WithPprofIf(os.Getenv("PPROF_ENABLED") == "true"),
)
```

## Path Configuration

### WithDebugPrefix

```go
func WithDebugPrefix(prefix string) DebugOption
```

Mounts debug endpoints under a custom prefix.

**Default:** `"/debug"`

## pprof Options

### WithPprof

```go
func WithPprof() DebugOption
```

Enables pprof endpoints unconditionally.

### WithPprofIf

```go
func WithPprofIf(condition bool) DebugOption
```

Conditionally enables pprof endpoints based on a boolean condition.

## Available Endpoints

When pprof is enabled:

- `GET /debug/pprof/` - Main pprof index
- `GET /debug/pprof/cmdline` - Command line
- `GET /debug/pprof/profile` - CPU profile
- `GET /debug/pprof/symbol` - Symbol lookup
- `GET /debug/pprof/trace` - Execution trace
- `GET /debug/pprof/allocs` - Memory allocations
- `GET /debug/pprof/block` - Block profile
- `GET /debug/pprof/goroutine` - Goroutine profile
- `GET /debug/pprof/heap` - Heap profile
- `GET /debug/pprof/mutex` - Mutex profile
- `GET /debug/pprof/threadcreate` - Thread creation profile

## Security Warning

⚠️ **Never enable pprof in production without proper authentication.** Debug endpoints expose sensitive runtime information.

## Example

```go
// Development: enable unconditionally
app.WithDebugEndpoints(
    app.WithPprof(),
)

// Production: enable conditionally
app.WithDebugEndpoints(
    app.WithDebugPrefix("/_internal/debug"),
    app.WithPprofIf(os.Getenv("PPROF_ENABLED") == "true"),
)
```
