---
title: "Health Endpoints"
linkTitle: "Health Endpoints"
weight: 9
description: >
  Configure Kubernetes-compatible liveness and readiness probes.
---

## Overview

The app package provides standard health check endpoints. They work with Kubernetes and other orchestration platforms:

- **Liveness Probe** (`/healthz`) - Shows if the process is alive. Restart if failing.
- **Readiness Probe** (`/readyz`) - Shows if the service can handle traffic.

## Basic Configuration

### Enable Health Endpoints

Enable health endpoints with defaults.

```go
a, err := app.New(
    app.WithHealthEndpoints(),
)

// Endpoints:
// GET /healthz - Liveness probe
// GET /readyz - Readiness probe
```

### Custom Paths

Configure custom health check paths:

```go
a, err := app.New(
    app.WithHealthEndpoints(
        app.WithHealthzPath("/health/live"),
        app.WithReadyzPath("/health/ready"),
    ),
)
```

### Path Prefix

Mount health endpoints under a prefix.

```go
a, err := app.New(
    app.WithHealthEndpoints(
        app.WithHealthPrefix("/_system"),
    ),
)

// Endpoints:
// GET /_system/healthz
// GET /_system/readyz
```

## Liveness Checks

### Basic Liveness Check

Liveness checks should be dependency-free and fast:

```go
a, err := app.New(
    app.WithHealthEndpoints(
        app.WithLivenessCheck("process", func(ctx context.Context) error {
            // Process is alive if we can execute this
            return nil
        }),
    ),
)
```

### Multiple Liveness Checks

Add multiple liveness checks.

```go
a, err := app.New(
    app.WithHealthEndpoints(
        app.WithLivenessCheck("process", func(ctx context.Context) error {
            return nil
        }),
        app.WithLivenessCheck("goroutines", func(ctx context.Context) error {
            if runtime.NumGoroutine() > 10000 {
                return fmt.Errorf("too many goroutines: %d", runtime.NumGoroutine())
            }
            return nil
        }),
    ),
)
```

### Liveness Behavior

- Returns `200 "ok"` if all checks pass
- Returns `503` if any check fails
- If no checks configured, always returns `200`

## Readiness Checks

### Basic Readiness Check

Readiness checks verify external dependencies:

```go
a, err := app.New(
    app.WithHealthEndpoints(
        app.WithReadinessCheck("database", func(ctx context.Context) error {
            return db.PingContext(ctx)
        }),
    ),
)
```

### Multiple Readiness Checks

Check multiple dependencies:

```go
a, err := app.New(
    app.WithHealthEndpoints(
        app.WithReadinessCheck("database", func(ctx context.Context) error {
            return db.PingContext(ctx)
        }),
        app.WithReadinessCheck("cache", func(ctx context.Context) error {
            return redis.Ping(ctx).Err()
        }),
        app.WithReadinessCheck("api", func(ctx context.Context) error {
            return checkUpstreamAPI(ctx)
        }),
    ),
)
```

### Readiness Behavior

- Returns `204` if all checks pass
- Returns `503` if any check fails
- If no checks configured, always returns `204`

## Health Check Timeout

Configure timeout for individual checks:

```go
a, err := app.New(
    app.WithHealthEndpoints(
        app.WithHealthTimeout(800 * time.Millisecond),
        app.WithReadinessCheck("database", func(ctx context.Context) error {
            // This check has 800ms to complete
            return db.PingContext(ctx)
        }),
    ),
)
```

Default timeout: `1s`

## Runtime Readiness Gates

### Readiness Manager

Dynamically manage readiness state at runtime:

```go
type DatabaseGate struct {
    db *sql.DB
}

func (g *DatabaseGate) Ready() bool {
    return g.db.Ping() == nil
}

func (g *DatabaseGate) Name() string {
    return "database"
}

// Register gate at runtime
a.Readiness().Register("db", &DatabaseGate{db: db})

// Unregister during shutdown
a.OnShutdown(func(ctx context.Context) {
    a.Readiness().Unregister("db")
})
```

### Use Cases

Runtime gates are useful for:

- **Connection pools** that manage their own health
- **Circuit breakers** that track upstream failures
- **Dynamic dependencies** that come and go at runtime

## Liveness vs Readiness

### When to Use Liveness

Liveness checks answer: "Should the process be restarted?"

**Use for:**
- Detecting deadlocks
- Detecting infinite loops
- Detecting corrupted state that requires restart

**Don't use for:**
- External dependency failures (use readiness instead)
- Temporary errors that will resolve themselves
- Network connectivity issues

### When to Use Readiness

Readiness checks answer: "Can this instance handle traffic?"

**Use for:**
- Database connectivity
- Cache availability
- Upstream service health
- Initialization completion

**Don't use for:**
- Process-level health (use liveness instead)
- Permanent failures that require restart

## Kubernetes Configuration

### Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: api
        image: my-api:latest
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 1
          failureThreshold: 3
```

## Complete Example

```go
package main

import (
    "context"
    "database/sql"
    "log"
    "time"
    
    "rivaas.dev/app"
)

var db *sql.DB

func main() {
    a, err := app.New(
        app.WithServiceName("api"),
        
        // Health endpoints configuration
        app.WithHealthEndpoints(
            // Custom paths
            app.WithHealthPrefix("/_system"),
            
            // Timeout for checks
            app.WithHealthTimeout(800 * time.Millisecond),
            
            // Liveness: process-level health
            app.WithLivenessCheck("process", func(ctx context.Context) error {
                // Always healthy if we can execute this
                return nil
            }),
            
            // Readiness: dependency health
            app.WithReadinessCheck("database", func(ctx context.Context) error {
                return db.PingContext(ctx)
            }),
            
            app.WithReadinessCheck("cache", func(ctx context.Context) error {
                return checkCache(ctx)
            }),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Initialize database
    a.OnStart(func(ctx context.Context) error {
        var err error
        db, err = sql.Open("postgres", "...")
        return err
    })
    
    // Unregister readiness during shutdown
    a.OnShutdown(func(ctx context.Context) {
        // Mark as not ready before closing connections
        log.Println("Marking service as not ready")
        time.Sleep(100 * time.Millisecond) // Allow load balancer to notice
    })
    
    // Register routes...
    
    // Start server...
    // Endpoints available at:
    // GET /_system/healthz - Liveness
    // GET /_system/readyz - Readiness
}

func checkCache(ctx context.Context) error {
    // Check cache connectivity
    return nil
}
```

## Testing Health Endpoints

### Test Liveness

```bash
curl http://localhost:8080/healthz
# Expected: 200 OK
# Body: "ok"
```

### Test Readiness

```bash
curl http://localhost:8080/readyz
# Expected: 204 No Content (healthy)
# Or: 503 Service Unavailable (unhealthy)
```

### Test with Custom Prefix

```bash
curl http://localhost:8080/_system/healthz
curl http://localhost:8080/_system/readyz
```

## Next Steps

- [Server](../server/) - Start the server and handle shutdown
- [Lifecycle](../lifecycle/) - Use lifecycle hooks for initialization
- [Debug Endpoints](../debug-endpoints/) - Enable pprof for diagnostics
