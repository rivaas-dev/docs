---
title: "Lifecycle Hooks"
linkTitle: "Lifecycle Hooks"
weight: 8
description: >
  Lifecycle hook APIs and execution order.
---

## Hook Methods

### OnStart

```go
func (a *App) OnStart(fn func(context.Context) error)
```

Called before server starts. Hooks run sequentially and stop on first error.

**Use for:** Database connections, migrations, initialization that must succeed.

### OnReady

```go
func (a *App) OnReady(fn func())
```

Called after server starts listening. Hooks run asynchronously and don't block startup.

**Use for:** Warmup tasks, service discovery registration.

### OnShutdown

```go
func (a *App) OnShutdown(fn func(context.Context))
```

Called during graceful shutdown. Hooks run in LIFO order with shutdown timeout.

**Use for:** Closing connections, flushing buffers, cleanup that must complete within timeout.

### OnStop

```go
func (a *App) OnStop(fn func())
```

Called after shutdown completes. Hooks run in best-effort mode (panics caught).

**Use for:** Final cleanup that doesn't need timeout.

### OnRoute

```go
func (a *App) OnRoute(fn func(*route.Route))
```

Called when a route is registered. Disabled after router freeze.

**Use for:** Route validation, logging, documentation generation.

## Execution Flow

```
1. app.Start(ctx, ":8080") called
2. OnStart hooks execute (sequential, stop on error)
3. Server starts listening
4. OnReady hooks execute (async, non-blocking)
5. Server handles requests...
6. Context canceled (SIGTERM/SIGINT)
7. OnShutdown hooks execute (LIFO order, with timeout)
8. Server shutdown complete
9. OnStop hooks execute (best-effort, no timeout)
10. Process exits
```

## Hook Characteristics

| Hook | Order | Error Handling | Timeout | Async |
|------|-------|----------------|---------|-------|
| OnStart | Sequential | Stop on first error | No | No |
| OnReady | - | Panic caught and logged | No | Yes |
| OnShutdown | LIFO | Errors ignored | Yes (shutdown timeout) | No |
| OnStop | - | Panic caught and logged | No | No |
| OnRoute | Sequential | - | No | No |

## Example

```go
a := app.MustNew()

// OnStart: Initialize (sequential, stops on error)
a.OnStart(func(ctx context.Context) error {
    return db.Connect(ctx)
})

// OnReady: Post-startup (async, non-blocking)
a.OnReady(func() {
    consul.Register("my-service", ":8080")
})

// OnShutdown: Graceful cleanup (LIFO, with timeout)
a.OnShutdown(func(ctx context.Context) {
    db.Close()
})

// OnStop: Final cleanup (best-effort)
a.OnStop(func() {
    cleanupTempFiles()
})
```
