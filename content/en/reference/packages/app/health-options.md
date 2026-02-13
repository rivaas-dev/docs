---
title: "Health Options"
linkTitle: "Health Options"
keywords:
  - health options
  - health checks
  - liveness
  - readiness
weight: 5
description: >
  Health endpoint configuration options reference.
---

## Health Options

These options are used with `WithHealthEndpoints()`:

```go
app.WithHealthEndpoints(
    app.WithReadinessCheck("database", dbCheck),
    app.WithHealthTimeout(800 * time.Millisecond),
)
```

## Path Configuration

### WithHealthPrefix

```go
func WithHealthPrefix(prefix string) HealthOption
```

Mounts health endpoints under a prefix.

**Default:** `""` (root)

### WithLivezPath

```go
func WithLivezPath(path string) HealthOption
```

Custom liveness probe path.

**Default:** `"/livez"`

### WithReadyzPath

```go
func WithReadyzPath(path string) HealthOption
```

Custom readiness probe path.

**Default:** `"/readyz"`

## Check Configuration

### WithHealthTimeout

```go
func WithHealthTimeout(d time.Duration) HealthOption
```

Timeout for each health check.

**Default:** `1s`

### WithLivenessCheck

```go
func WithLivenessCheck(name string, fn CheckFunc) HealthOption
```

Adds a liveness check. Liveness checks should be dependency-free and fast.

### WithReadinessCheck

```go
func WithReadinessCheck(name string, fn CheckFunc) HealthOption
```

Adds a readiness check. Readiness checks verify external dependencies.

## CheckFunc

```go
type CheckFunc func(context.Context) error
```

Health check function that returns nil if healthy, error if unhealthy.

## Example

```go
app.WithHealthEndpoints(
    app.WithHealthPrefix("/_system"),
    app.WithHealthTimeout(800 * time.Millisecond),
    app.WithLivenessCheck("process", func(ctx context.Context) error {
        return nil
    }),
    app.WithReadinessCheck("database", func(ctx context.Context) error {
        return db.PingContext(ctx)
    }),
)

// Endpoints:
// GET /_system/livez - Liveness (200 if all checks pass)
// GET /_system/readyz - Readiness (204 if all checks pass)
```
