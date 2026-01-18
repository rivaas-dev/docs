---
title: "Troubleshooting"
linkTitle: "Troubleshooting"
weight: 9
description: >
  Common issues and solutions for the App package.
---

## Configuration Errors

### Validation Errors

**Problem:** `app.New()` returns validation errors.

**Solution:** Check error message for specific field. Common issues:

- Empty service name or version
- Invalid environment (must be "development" or "production")
- ReadTimeout > WriteTimeout
- ShutdownTimeout < 1 second
- MaxHeaderBytes < 1KB

**Example:**

```go
a, err := app.New(
    app.WithServiceName(""),  // ❌ Empty
)
// Error: "serviceName must not be empty"
```

### Import Errors

**Problem:** Cannot import `rivaas.dev/app`.

**Solution:**

```bash
go get rivaas.dev/app
go mod tidy
```

Ensure Go 1.25+ is installed.

## Server Issues

### Port Already in Use

**Problem:** Server fails to start with "address already in use".

**Solution:** Check if port is in use:

```bash
lsof -i :8080
# Or
netstat -an | grep 8080
```

Kill the process or use a different port.

### Routes Not Registering

**Problem:** Routes return 404 even though registered.

**Solution:**

- Ensure routes registered before `Start()`
- Check paths match exactly (case-sensitive)
- Verify HTTP method matches
- Router freezes on startup - can't add routes after

### Graceful Shutdown Not Working

**Problem:** Server doesn't shut down cleanly.

**Solution:**

- Increase shutdown timeout: `WithShutdownTimeout(60 * time.Second)`
- Check OnShutdown hooks complete quickly
- Verify handlers respect context cancellation

## Observability Issues

### Metrics Not Appearing

**Problem:** Metrics endpoint returns 404.

**Solution:**

- Ensure metrics enabled: `WithMetrics()`
- Check metrics address: `a.GetMetricsServerAddress()`
- Default is separate server on `:9090/metrics`
- Use `WithMetricsOnMainRouter("/metrics")` to mount on main router

### Tracing Not Working

**Problem:** No traces appear in backend.

**Solution:**

- Verify tracing enabled: `WithTracing()`
- Check OTLP endpoint configuration
- Ensure tracing backend is running and accessible
- Verify network connectivity
- Check logs for tracing initialization errors

### Logs Not Appearing

**Problem:** No logs are written.

**Solution:**

- Ensure logging enabled: `WithLogging()`
- Check log level configuration
- Verify logger handler is correct (JSON, Console, etc.)
- Use `c.Logger()` in handlers, not package-level logger

## Middleware Issues

### Middleware Not Executing

**Problem:** Middleware functions aren't being called.

**Solution:**

- Ensure middleware added before routes
- Check middleware calls `c.Next()`
- Verify middleware isn't returning early
- Default recovery middleware is included automatically

### Authentication Failing

**Problem:** Auth middleware not working correctly.

**Solution:**

- Check header/token extraction logic
- Verify middleware order (auth should run early)
- Ensure `c.Next()` is called on success
- Test middleware in isolation

## Testing Issues

### Test Hangs

**Problem:** `a.Test()` never returns.

**Solution:**

- Set timeout: `a.Test(req, app.WithTimeout(5*time.Second))`
- Check for infinite loops in handler
- Verify middleware calls `c.Next()`

### Test Fails with Panic

**Problem:** Test panics instead of returning error.

**Solution:**

- Use `recover()` in test or
- Check that handler doesn't panic
- Recovery middleware catches panics in real server

## Health Check Issues

### Health Checks Always Failing

**Problem:** `/healthz` or `/readyz` always returns 503.

**Solution:**

- Check health check functions return nil on success
- Verify dependencies (database, cache) are accessible
- Check health timeout is sufficient
- Test health checks independently

### Health Checks Never Complete

**Problem:** Health checks timeout.

**Solution:**

- Increase timeout: `WithHealthTimeout(2 * time.Second)`
- Check dependencies respond within timeout
- Verify no deadlocks in check functions
- Use context timeout in check functions

## Debugging Tips

### Enable Development Mode

```go
app.WithEnvironment("development")
```

Enables verbose logging and route table display.

### Check Observability Status

```go
if a.Metrics() != nil {
    fmt.Println("Metrics:", a.GetMetricsServerAddress())
}
if a.Tracing() != nil {
    fmt.Println("Tracing enabled")
}
```

### Use Test Helpers

```go
resp, err := a.Test(req)  // Test without starting server
```

### Enable GC Tracing

```bash
GODEBUG=gctrace=1 go run main.go
```

## Getting Help

- **Documentation:** [User Guide](/guides/app/)
- **API Docs:** [pkg.go.dev](https://pkg.go.dev/rivaas.dev/app)
- **Examples:** See `examples/` directory in repository
