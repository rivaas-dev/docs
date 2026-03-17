---
title: "Troubleshooting"
linkTitle: "Troubleshooting"
keywords:
  - app troubleshooting
  - common issues
  - debugging
  - faq
weight: 9
description: >
  Common issues and solutions for the App package.
---

## Configuration Errors

### Validation Errors

**Problem:** `app.New()` returns validation errors.

**Solution:** Check error message for specific field. Common issues:

- Empty service name or version.
- Invalid environment. Must be "development" or "production".
- ReadTimeout greater than WriteTimeout.
- ShutdownTimeout less than 1 second.
- MaxHeaderBytes less than 1KB.

**Example:**

```go
a, err := app.New(
    app.WithServiceName(""),  // ❌ Empty
)
// Error: "serviceName must not be empty"
```

## Request Binding and Validation

### Validation errors in handlers

**Problem:** Request validation not working or you need to check validation errors in handlers.

Use `app.Context` for binding and validation (not `router.Context` directly). Check validation errors with the **validation** package: `errors.As(err, &validation.Error)` or `errors.Is(err, validation.ErrValidation)`. Do not use the router package for validation sentinel checks.

**Solutions:**

```go
// ✅ Use app.Context for binding and validation
func createUser(c *app.Context) {
    var req CreateUserRequest
    if !c.MustBind(&req) {
        return // Binding or validation failed; response already written
    }
    // Use req...
}

// ✅ Partial validation for PATCH
func updateUser(c *app.Context) {
    req, ok := app.MustBind[UpdateUserRequest](c, app.WithPartial())
    if !ok {
        return
    }
    // Use req...
}

// ✅ Check validation errors programmatically
if err := c.Bind(&req); err != nil {
    var verr *validation.Error
    if errors.As(err, &verr) {
        // Handle field-level errors
    }
}
```

For custom validation tags and validation strategy issues, see the [validation package troubleshooting](/docs/reference/packages/validation/troubleshooting/).

### Error handling in handlers

**Send error response:** Use `c.Fail(err)` to format the error, write the response, and stop the handler chain.

**Collect then respond:** To collect multiple errors (e.g. multi-field validation) and send one response, use `c.Context.CollectError(err)` in handlers, then check `c.Context.HasErrors()` and `c.Context.Errors()` and send your response.

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

**Solution:** Check if port is in use (default is 8080 for HTTP, 8443 for TLS/mTLS):

```bash
lsof -i :8080
# Or for TLS/mTLS
lsof -i :8443
# Or
netstat -an | grep 8080
```

Kill the process or use a different port with `WithPort(n)`.

### Routes Not Registering

**Problem:** Routes return 404 even though registered.

**Solution:**

- Ensure routes registered before `Start()`.
- Check paths match exactly. They are case-sensitive.
- Verify HTTP method matches.
- Router freezes on startup. Can't add routes after.
- Lifecycle hook registration (OnStart, OnReady, OnShutdown, etc.) after freeze returns an error instead of panicking. Check and handle the error (e.g. in `main`) and register all hooks before `Start()`.

### Unsupported HTTP Method Panic

**Problem:** Panic with message like `unsupported HTTP method "…"` or `supported: GET, POST, ...`.

**Solution:** Use only the provided method shortcuts: `a.GET`, `a.POST`, `a.PUT`, `a.DELETE`, `a.PATCH`, `a.HEAD`, `a.OPTIONS`, and the same on `Group` and `VersionGroup`. If the panic appears in tests or custom code that passes a method string, ensure that string is one of: **GET**, **POST**, **PUT**, **DELETE**, **PATCH**, **HEAD**, **OPTIONS**.

### Graceful Shutdown Not Working

**Problem:** Server doesn't shut down cleanly.

**Solution:**

- Increase shutdown timeout: `WithShutdownTimeout(60 * time.Second)`.
- Check OnShutdown hooks complete quickly.
- Verify handlers respect context cancellation.

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

**Problem:** `/livez` or `/readyz` always returns 503.

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

- **Documentation:** [User Guide](/docs/guides/app/)
- **API Docs:** [pkg.go.dev](https://pkg.go.dev/rivaas.dev/app)
- **Examples:** See `examples/` directory in repository
