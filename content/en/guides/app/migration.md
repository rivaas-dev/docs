---
title: "Migration"
linkTitle: "Migration"
weight: 14
description: >
  Migrate from the router package to the app package.
---

## When to Migrate

Consider migrating from router to app when you need:

- **Integrated observability** - Built-in metrics, tracing, and logging
- **Lifecycle management** - OnStart, OnReady, OnShutdown, OnStop hooks
- **Graceful shutdown** - Automatic shutdown handling with context
- **Health endpoints** - Kubernetes-compatible liveness and readiness probes
- **Sensible defaults** - Pre-configured with production-ready settings

## Key Differences

### Constructor Returns Error

**Router:**
```go
r := router.New()  // No error returned
```

**App:**
```go
a, err := app.New()  // Returns (*App, error)
if err != nil {
    log.Fatal(err)
}

// Or use MustNew() for panic on error
a := app.MustNew()
```

### Context Type

**Router:**
```go
r.GET("/", func(c *router.Context) {
    c.JSON(http.StatusOK, data)
})
```

**App:**
```go
a.GET("/", func(c *app.Context) {  // Different context type
    c.JSON(http.StatusOK, data)
})
```

`app.Context` embeds `router.Context` and adds binding, validation, and error handling methods.

### Server Startup

**Router:**
```go
r := router.New()
http.ListenAndServe(":8080", r)
```

**App:**
```go
a := app.MustNew()
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
defer cancel()
a.Start(ctx, ":8080")  // Includes graceful shutdown
```

## Migration Steps

### 1. Update Imports

```go
// Before
import "rivaas.dev/router"

// After
import "rivaas.dev/app"
```

### 2. Change Constructor

```go
// Before
r := router.New(
    router.WithMetrics(),
    router.WithTracing(),
)

// After
a, err := app.New(
    app.WithServiceName("my-service"),
    app.WithObservability(
        app.WithMetrics(),
        app.WithTracing(),
    ),
)
if err != nil {
    log.Fatal(err)
}
```

### 3. Update Handler Signatures

```go
// Before
func handler(c *router.Context) {
    c.JSON(http.StatusOK, data)
}

// After
func handler(c *app.Context) {  // Change context type
    c.JSON(http.StatusOK, data)
}
```

### 4. Update Server Startup

```go
// Before
http.ListenAndServe(":8080", r)

// After
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()
a.Start(ctx, ":8080")
```

## Complete Migration Example

### Before (Router)

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.New(
        router.WithMetrics(),
        router.WithTracing(),
    )
    
    r.GET("/", func(c *router.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello!",
        })
    })
    
    http.ListenAndServe(":8080", r)
}
```

### After (App)

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
)

func main() {
    a, err := app.New(
        app.WithServiceName("my-service"),
        app.WithServiceVersion("v1.0.0"),
        app.WithObservability(
            app.WithMetrics(),
            app.WithTracing(),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello!",
        })
    })
    
    ctx, cancel := signal.NotifyContext(
        context.Background(),
        os.Interrupt,
        syscall.SIGTERM,
    )
    defer cancel()
    
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}
```

## Accessing Router

If you need router-specific features, access the underlying router:

```go
a := app.MustNew()

// Access router for advanced features
router := a.Router()
router.Freeze()  // Manually freeze router
```

## Gradual Migration

You can migrate gradually:

1. **Start with app constructor** - Change `router.New()` to `app.New()`
2. **Update handlers incrementally** - Change handler signatures one at a time
3. **Add app features** - Add observability, health checks, lifecycle hooks
4. **Update server startup** - Add graceful shutdown last

## Next Steps

- [Basic Usage](../basic-usage/) - Learn app fundamentals
- [Configuration](../configuration/) - Configure the app
- [Examples](../examples/) - See complete working examples
