---
title: "Examples"
linkTitle: "Examples"
weight: 15
keywords:
  - app examples
  - code samples
  - use cases
  - working examples
  - sample applications
description: >
  Complete working examples of Rivaas applications.
---

## Quick Start Example

Minimal application to get started.

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
    a, err := app.New()
    if err != nil {
        log.Fatal(err)
    }

    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello from Rivaas!",
        })
    })

    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    if err := a.Start(ctx); err != nil {
        log.Fatal(err)
    }
}
```

## Full-Featured Production App

Complete application with all features.

```go
package main

import (
    "context"
    "database/sql"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
    
    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/metrics"
    "rivaas.dev/tracing"
)

var db *sql.DB

func main() {
    a, err := app.New(
        // Service metadata
        app.WithServiceName("orders-api"),
        app.WithServiceVersion("v2.0.0"),
        app.WithEnvironment("production"),
        
        // Observability: all three pillars
        app.WithObservability(
            app.WithLogging(logging.WithJSONHandler()),
            app.WithMetrics(),
            app.WithTracing(tracing.WithOTLP("localhost:4317")),
            app.WithExcludePaths("/livez", "/readyz", "/metrics"),
            app.WithLogOnlyErrors(),
            app.WithSlowThreshold(1 * time.Second),
        ),
        
        // Health endpoints
        app.WithHealthEndpoints(
            app.WithHealthTimeout(800 * time.Millisecond),
            app.WithReadinessCheck("database", func(ctx context.Context) error {
                return db.PingContext(ctx)
            }),
        ),
        
        // Server configuration
        app.WithServer(
            app.WithReadTimeout(10 * time.Second),
            app.WithWriteTimeout(15 * time.Second),
            app.WithShutdownTimeout(30 * time.Second),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Lifecycle hooks
    a.OnStart(func(ctx context.Context) error {
        log.Println("Connecting to database...")
        var err error
        db, err = sql.Open("postgres", os.Getenv("DATABASE_URL"))
        return err
    })
    
    a.OnShutdown(func(ctx context.Context) {
        log.Println("Closing database connection...")
        db.Close()
    })
    
    // Register routes
    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "service": "orders-api",
            "version": "v2.0.0",
        })
    })
    
    a.GET("/orders/:id", func(c *app.Context) {
        orderID := c.Param("id")
        
        c.Logger().Info("fetching order", "order_id", orderID)
        
        c.JSON(http.StatusOK, map[string]string{
            "order_id": orderID,
            "status":   "completed",
        })
    })
    
    // Start server
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()
    
    log.Println("Server starting on :8080")
    if err := a.Start(ctx); err != nil {
        log.Fatal(err)
    }
}
```

## REST API Example

Complete REST API with CRUD operations:

```go
package main

import (
    "log"
    "net/http"
    
    "rivaas.dev/app"
)

type User struct {
    ID    string `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

type CreateUserRequest struct {
    Name  string `json:"name" validate:"required,min=3"`
    Email string `json:"email" validate:"required,email"`
}

func main() {
    a := app.MustNew(app.WithServiceName("users-api"))
    
    // List users
    a.GET("/users", func(c *app.Context) {
        users := []User{
            {ID: "1", Name: "Alice", Email: "alice@example.com"},
            {ID: "2", Name: "Bob", Email: "bob@example.com"},
        }
        c.JSON(http.StatusOK, users)
    })
    
    // Create user
    a.POST("/users", func(c *app.Context) {
        req, ok := app.MustBind[CreateUserRequest](c)
        if !ok {
            return
        }
        
        user := User{
            ID:    "123",
            Name:  req.Name,
            Email: req.Email,
        }
        
        c.JSON(http.StatusCreated, user)
    })
    
    // Get user
    a.GET("/users/:id", func(c *app.Context) {
        id := c.Param("id")
        user := User{ID: id, Name: "Alice", Email: "alice@example.com"}
        c.JSON(http.StatusOK, user)
    })
    
    // Update user
    a.PUT("/users/:id", func(c *app.Context) {
        id := c.Param("id")
        
        req, ok := app.MustBind[CreateUserRequest](c)
        if !ok {
            return
        }
        
        user := User{ID: id, Name: req.Name, Email: req.Email}
        c.JSON(http.StatusOK, user)
    })
    
    // Delete user
    a.DELETE("/users/:id", func(c *app.Context) {
        c.Status(http.StatusNoContent)
    })
    
    // Start server...
}
```

## More Examples

See the `examples/` directory in the repository for additional examples:

- **01-quick-start/** - Minimal setup (~20 lines)
- **02-blog/** - Complete blog API with database, validation, and testing

## Next Steps

- [Basic Usage](../basic-usage/) - Learn the fundamentals
- [Configuration](../configuration/) - Configure your app
- [Context](../context/) - Handle requests and responses
