---
title: "Lifecycle"
linkTitle: "Lifecycle"
weight: 8
keywords:
  - app lifecycle
  - hooks
  - startup
  - shutdown
  - lifecycle events
description: >
  Use lifecycle hooks for initialization, cleanup, and event handling.
---

## Overview

The app package provides lifecycle hooks for managing application state:

- **OnStart** - Called before server starts. Runs sequentially. Stops on first error.
- **OnReady** - Called when server is ready to accept connections. Runs async. Non-blocking.
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
a.Start(ctx, ":8080")
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
if err := a.Start(ctx, ":8080"); err != nil {
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
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatalf("Server error: %v", err)
    }
}
```

## Hook Execution Flow

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

## Next Steps

- [Server](../server/) - Learn about server startup and shutdown
- [Health Endpoints](../health-endpoints/) - Configure health checks
- [Examples](../examples/) - See complete working examples
