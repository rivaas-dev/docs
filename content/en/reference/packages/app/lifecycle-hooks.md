---
title: "Lifecycle Hooks"
linkTitle: "Lifecycle Hooks"
keywords:
  - lifecycle hooks
  - startup hooks
  - shutdown hooks
  - reload hooks
  - SIGHUP
  - lifecycle events
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

Called after shutdown completes. Hooks run in best-effort mode and panics are caught.

**Use for:** Final cleanup that doesn't need timeout.

### OnRoute

```go
func (a *App) OnRoute(fn func(*route.Route))
```

Called when a route is registered. Disabled after router freeze.

**Use for:** Route validation, logging, documentation generation.

### OnReload

```go
func (a *App) OnReload(fn func(context.Context) error)
```

Called when the application receives a reload signal (SIGHUP) or when `Reload()` is called programmatically. SIGHUP signal handling is automatically enabled when you register this hook.

If no OnReload hooks are registered, SIGHUP is ignored on Unix so the process keeps running (e.g. `kill -HUP` does not terminate it).

Hooks run sequentially and stop on first error. Errors are logged but don't crash the server.

**Use for:** Reloading configuration, rotating certificates, flushing caches, updating runtime settings.

**Platform:** SIGHUP works on Unix/Linux/macOS. On Windows, use programmatic `Reload()`.

### Reload

```go
func (a *App) Reload(ctx context.Context) error
```

Manually triggers all registered OnReload hooks. Useful for admin endpoints or Windows where SIGHUP isn't available.

Returns an error if any hook fails, but the server continues running with the old configuration.

## Execution Flow

```
1. app.Start(ctx) called
2. OnStart hooks execute (sequential, stop on error)
3. Server starts listening
4. OnReady hooks execute (async, non-blocking)
5. Server handles requests...
   → OnReload hooks execute when SIGHUP received (sequential, logged on error)
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
| OnReload | Sequential | Stop on first error, logged | No | No |
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

// OnReload: Reload configuration (sequential, logged on error)
a.OnReload(func(ctx context.Context) error {
    cfg, err := loadConfig("config.yaml")
    if err != nil {
        return err
    }
    applyConfig(cfg)
    return nil
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
