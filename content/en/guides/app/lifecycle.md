---
title: "Lifecycle"
linkTitle: "Lifecycle"
weight: 8
keywords:
  - app lifecycle
  - hooks
  - startup
  - shutdown
  - reload
  - SIGHUP
  - lifecycle events
description: >
  Use lifecycle hooks for initialization, cleanup, reload, and event handling.
---

## Overview

The app package provides lifecycle hooks for managing application state:

- **OnStart** - Called before server starts. Runs sequentially. Stops on first error.
- **OnReady** - Called when server is ready to accept connections. Runs async. Non-blocking.
- **OnReload** - Called when SIGHUP is received or `Reload()` is called. Runs sequentially. Errors logged.
- **OnShutdown** - Called during graceful shutdown. LIFO order.
- **OnStop** - Called after shutdown completes. Best-effort.
- **OnRoute** - Called when a route is registered. Synchronous.

## OnStart Hook

### Basic Usage

Initialize resources before the server starts:

```go
a := app.MustNew()

a.OnStart(func(ctx context.Context) error {
    log.Println("Connecting to database...")
    return db.Connect(ctx)
})

a.OnStart(func(ctx context.Context) error {
    log.Println("Running migrations...")
    return db.Migrate(ctx)
})

// Start server - hooks execute before listening
a.Start(ctx)
```

### Error Handling

OnStart hooks run sequentially and stop on first error:

```go
a.OnStart(func(ctx context.Context) error {
    if err := db.Connect(ctx); err != nil {
        return fmt.Errorf("database connection failed: %w", err)
    }
    return nil
})

// If this hook fails, server won't start
if err := a.Start(ctx); err != nil {
    log.Fatalf("Startup failed: %v", err)
}
```

### Common Use Cases

```go
// Database connection
a.OnStart(func(ctx context.Context) error {
    return db.PingContext(ctx)
})

// Load configuration
a.OnStart(func(ctx context.Context) error {
    return config.Load("config.yaml")
})

// Initialize caches
a.OnStart(func(ctx context.Context) error {
    return cache.Warmup(ctx)
})

// Check external dependencies
a.OnStart(func(ctx context.Context) error {
    return checkExternalServices(ctx)
})
```

## OnReady Hook

### Basic Usage

Execute tasks after the server starts listening:

```go
a.OnReady(func() {
    log.Println("Server is ready!")
    log.Printf("Listening on :8080")
})

a.OnReady(func() {
    // Register with service discovery
    consul.Register("my-service", ":8080")
})
```

### Async Execution

OnReady hooks run asynchronously and don't block startup:

```go
a.OnReady(func() {
    // Long-running warmup task
    time.Sleep(5 * time.Second)
    cache.Preload()
})

// Server accepts connections immediately, warmup runs in background
```

### Error Handling

Panics in OnReady hooks are caught and logged:

```go
a.OnReady(func() {
    // If this panics, it's logged but doesn't crash the server
    doSomethingRisky()
})
```

## OnReload Hook

### What is it?

The OnReload hook lets you reload your app's configuration without stopping the server. When you register this hook, your app automatically listens for SIGHUP signals on Unix systems (Linux, macOS). No extra setup needed!

### Basic Usage

Here's how to reload configuration when you get a SIGHUP signal:

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
)

// Register a reload hook - SIGHUP is now automatically enabled!
a.OnReload(func(ctx context.Context) error {
    log.Println("Reloading configuration...")
    
    // Load new config
    newConfig, err := loadConfig("config.yaml")
    if err != nil {
        return fmt.Errorf("failed to load config: %w", err)
    }
    
    // Apply new config
    applyConfig(newConfig)
    return nil
})

// Start server
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()
a.Start(ctx)
```

Now you can reload without restarting:

```bash
# Send SIGHUP to reload
kill -HUP <pid>

# Or use killall
killall -HUP my-api
```

### How it works

When you register an `OnReload` hook:
- **On Unix/Linux/macOS**: Your app automatically listens for SIGHUP signals
- **On Windows**: SIGHUP doesn't exist, but you can still call `Reload()` programmatically
- **All platforms**: You can trigger reload from your code using `app.Reload(ctx)`

When no `OnReload` hooks are registered, SIGHUP is ignored on Unix so the process is not terminated (e.g. by `kill -HUP` or terminal disconnect).

### Error Handling

If reload fails, your app keeps running with the old configuration:

```go
a.OnReload(func(ctx context.Context) error {
    cfg, err := loadConfig("config.yaml")
    if err != nil {
        // Error is logged, but server keeps running
        return err
    }
    
    // Validate before applying
    if err := cfg.Validate(); err != nil {
        return fmt.Errorf("invalid config: %w", err)
    }
    
    applyConfig(cfg)
    return nil
})
```

The hooks run one at a time (sequentially) and stop on the first error. This means if you have multiple reload hooks and one fails, the rest won't run.

### Programmatic Reload

You can also trigger reload from your code - useful for admin endpoints:

```go
// Create an admin endpoint to trigger reload
a.POST("/admin/reload", func(c *app.Context) {
    if err := a.Reload(c.Request.Context()); err != nil {
        c.InternalError(err)
        return
    }
    c.JSON(200, map[string]string{"status": "config reloaded"})
})
```

### Multiple Reload Hooks

You can register multiple hooks for different parts of your config:

```go
// Reload database pool settings
a.OnReload(func(ctx context.Context) error {
    log.Println("Reloading database config...")
    return db.ReconfigurePool(ctx)
})

// Reload cache settings
a.OnReload(func(ctx context.Context) error {
    log.Println("Reloading cache config...")
    return cache.Reload(ctx)
})

// Reload log level
a.OnReload(func(ctx context.Context) error {
    log.Println("Reloading log level...")
    return logger.SetLevel(newLevel)
})
```

### Common Use Cases

```go
// Reload TLS certificates
a.OnReload(func(ctx context.Context) error {
    return tlsManager.ReloadCertificates()
})

// Reload feature flags
a.OnReload(func(ctx context.Context) error {
    return features.Reload(ctx)
})

// Reload rate limits
a.OnReload(func(ctx context.Context) error {
    return rateLimiter.UpdateLimits(ctx)
})

// Flush caches
a.OnReload(func(ctx context.Context) error {
    cache.Clear()
    return nil
})
```

### What can't be reloaded?

**Routes and middleware** can't be changed after the server starts - they're frozen for safety. Only reload things like:
- Configuration files
- Database connection settings
- TLS certificates
- Cache contents
- Log levels
- Feature flags

### Platform Differences

- **Unix/Linux/macOS**: SIGHUP works automatically
- **Windows**: SIGHUP isn't available, use `app.Reload(ctx)` instead

### Thread Safety

Don't worry about multiple reload signals at the same time - the framework handles this automatically. If multiple SIGHUPs come in, they'll run one at a time.

## OnShutdown Hook

### Basic Usage

Clean up resources during graceful shutdown:

```go
a.OnShutdown(func(ctx context.Context) {
    log.Println("Shutting down gracefully...")
    db.Close()
})

a.OnShutdown(func(ctx context.Context) {
    log.Println("Flushing metrics...")
    metrics.Flush(ctx)
})
```

### LIFO Execution Order

OnShutdown hooks execute in reverse order (Last In, First Out):

```go
a.OnShutdown(func(ctx context.Context) {
    log.Println("1. First registered")
})

a.OnShutdown(func(ctx context.Context) {
    log.Println("2. Second registered")
})

// During shutdown, prints:
// "2. Second registered"
// "1. First registered"
```

This ensures cleanup happens in reverse dependency order.

### Timeout Handling

OnShutdown hooks must complete within the shutdown timeout:

```go
a, err := app.New(
    app.WithServer(
        app.WithShutdownTimeout(30 * time.Second),
    ),
)

a.OnShutdown(func(ctx context.Context) {
    // This context has a 30s deadline
    select {
    case <-flushComplete:
        log.Println("Flush completed")
    case <-ctx.Done():
        log.Println("Flush timed out")
    }
})
```

### Common Use Cases

```go
// Close database connections
a.OnShutdown(func(ctx context.Context) {
    db.Close()
})

// Flush metrics and traces
a.OnShutdown(func(ctx context.Context) {
    metrics.Shutdown(ctx)
    tracing.Shutdown(ctx)
})

// Deregister from service discovery
a.OnShutdown(func(ctx context.Context) {
    consul.Deregister("my-service")
})

// Close external connections
a.OnShutdown(func(ctx context.Context) {
    redis.Close()
    messageQueue.Close()
})
```

## OnStop Hook

### Basic Usage

Final cleanup after shutdown completes:

```go
a.OnStop(func() {
    log.Println("Cleanup complete")
    cleanupTempFiles()
})
```

### Best-Effort Execution

OnStop hooks run in best-effort mode - panics are caught and logged:

```go
a.OnStop(func() {
    // Even if this panics, other hooks still run
    cleanupTempFiles()
})
```

### No Timeout

OnStop hooks don't have a timeout constraint:

```go
a.OnStop(func() {
    // This can take as long as needed
    archiveLogs()
})
```

## OnRoute Hook

### Basic Usage

Execute code when routes are registered:

```go
a.OnRoute(func(rt *route.Route) {
    log.Printf("Registered: %s %s", rt.Method(), rt.Path())
})

// Register routes - hook fires for each one
a.GET("/users", handler)
a.POST("/users", handler)
```

### Route Validation

Validate routes during registration:

```go
a.OnRoute(func(rt *route.Route) {
    // Ensure all routes have names
    if rt.Name() == "" {
        log.Printf("Warning: Route %s %s has no name", rt.Method(), rt.Path())
    }
})
```

### Documentation Generation

Use for automatic documentation:

```go
var routes []string

a.OnRoute(func(rt *route.Route) {
    routes = append(routes, fmt.Sprintf("%s %s", rt.Method(), rt.Path()))
})

// After all routes registered
a.OnReady(func() {
    log.Printf("Registered %d routes:", len(routes))
    for _, r := range routes {
        log.Println("  ", r)
    }
})
```

## Complete Example

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
)

var db *Database

func main() {
    a := app.MustNew(
        app.WithServiceName("api"),
        app.WithServer(
            app.WithShutdownTimeout(30 * time.Second),
        ),
    )
    
    // OnStart: Initialize resources
    a.OnStart(func(ctx context.Context) error {
        log.Println("Connecting to database...")
        var err error
        db, err = ConnectDB(ctx)
        if err != nil {
            return fmt.Errorf("database connection failed: %w", err)
        }
        return nil
    })
    
    a.OnStart(func(ctx context.Context) error {
        log.Println("Running migrations...")
        return db.Migrate(ctx)
    })
    
    // OnRoute: Log route registration
    a.OnRoute(func(rt *route.Route) {
        log.Printf("Route registered: %s %s", rt.Method(), rt.Path())
    })
    
    // OnReady: Post-startup tasks
    a.OnReady(func() {
        log.Println("Server is ready!")
        log.Println("Registering with service discovery...")
        consul.Register("api", ":8080")
    })
    
    // OnShutdown: Graceful cleanup
    a.OnShutdown(func(ctx context.Context) {
        log.Println("Deregistering from service discovery...")
        consul.Deregister("api")
    })
    
    a.OnShutdown(func(ctx context.Context) {
        log.Println("Closing database connection...")
        if err := db.Close(); err != nil {
            log.Printf("Error closing database: %v", err)
        }
    })
    
    // OnStop: Final cleanup
    a.OnStop(func() {
        log.Println("Cleanup complete")
    })
    
    // Register routes
    a.GET("/", homeHandler)
    a.GET("/health", healthHandler)
    
    // Setup graceful shutdown
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()
    
    // Start server
    log.Println("Starting server...")
    if err := a.Start(ctx); err != nil {
        log.Fatalf("Server error: %v", err)
    }
}
```

## Hook Execution Flow

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

## Next Steps

- [Server](../server/) - Learn about server startup and shutdown
- [Health Endpoints](../health-endpoints/) - Configure health checks
- [Examples](../examples/) - See complete working examples
