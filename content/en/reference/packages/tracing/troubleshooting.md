---
title: "Troubleshooting"
description: "Common issues and solutions for the tracing package"
keywords:
  - tracing troubleshooting
  - common issues
  - debugging
  - faq
weight: 4
---

Common issues and solutions when using the tracing package.

## Traces Not Appearing

### Symptom

No traces appear in your tracing backend (Jaeger, Zipkin, etc.) even though tracing is configured.

### Possible Causes & Solutions

#### 1. OTLP Provider Not Started

**Problem:** OTLP providers require calling `Start(ctx)` before tracing.

**Solution:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317"),
)

// ✓ Required for OTLP providers
if err := tracer.Start(context.Background()); err != nil {
    log.Fatal(err)
}
```

#### 2. Sampling Rate Too Low

**Problem:** Sample rate is set too low. For example, 1% sampling means 99% of requests aren't traced.

**Solution:** Increase sample rate or remove sampling for testing.

```go
// Development - trace everything
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithSampleRate(1.0), // 100% sampling
)
```

#### 3. Wrong Provider Configured

**Problem:** Using Noop provider (no traces exported).

**Solution:** Verify provider configuration:

```go
// ✗ Bad - no traces exported
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithNoop(), // No traces!
)

// ✓ Good - traces exported
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317"),
)
```

#### 4. Paths Excluded from Tracing

**Problem:** Paths are excluded via middleware options.

**Solution:** Check middleware exclusions.

```go
// Check if your paths are excluded
handler := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health", "/api/users"), // ← Is this excluding your endpoint?
)(mux)
```

#### 5. Shutdown Called Too Early

**Problem:** Application exits before spans are exported.

**Solution:** Ensure proper shutdown with timeout:

```go
defer func() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    if err := tracer.Shutdown(ctx); err != nil {
        log.Printf("Error shutting down tracer: %v", err)
    }
}()
```

#### 6. OTLP Endpoint Unreachable

**Problem:** OTLP collector is not running or unreachable.

**Solution:** Verify collector is running:

```bash
# Check if collector is listening
nc -zv localhost 4317  # OTLP gRPC
nc -zv localhost 4318  # OTLP HTTP
```

Check logs for connection errors:

```go
logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
}))

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317"),
    tracing.WithLogger(logger), // See connection errors
)
```

## Context Propagation Issues

### Symptom

Services create separate traces instead of one distributed trace.

### Possible Causes & Solutions

#### 1. Context Not Propagated

**Problem:** Context is not passed through the call chain.

**Solution:** Always pass context:

```go
// ✓ Good - context propagates
func handler(ctx context.Context) {
    result := doWork(ctx)  // Pass context
}

// ✗ Bad - context lost
func handler(ctx context.Context) {
    result := doWork(context.Background())  // Lost!
}
```

#### 2. Trace Context Not Injected

**Problem:** Trace context not injected into outgoing requests.

**Solution:** Always inject before making requests:

```go
req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)

// ✓ Required - inject trace context
tracer.InjectTraceContext(ctx, req.Header)

resp, _ := http.DefaultClient.Do(req)
```

#### 3. Trace Context Not Extracted

**Problem:** Incoming requests don't extract trace context.

**Solution:** Middleware automatically extracts, or do it manually:

```go
// Automatic (with middleware)
handler := tracing.Middleware(tracer)(mux)

// Manual (without middleware)
func myHandler(w http.ResponseWriter, r *http.Request) {
    ctx := tracer.ExtractTraceContext(r.Context(), r.Header)
    // Use extracted context...
}
```

#### 4. Different Propagators

**Problem:** Services use different propagation formats.

**Solution:** Ensure all services use the same propagator (default is W3C Trace Context):

```go
// All services should use default (W3C) or same custom propagator
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    // Default propagator is W3C Trace Context
)
```

## Performance Issues

### Symptom

High CPU usage, increased latency, or memory consumption.

### Possible Causes & Solutions

#### 1. Too Much Sampling

**Problem:** Sampling 100% of high-traffic endpoints.

**Solution:** Reduce sample rate:

```go
// For high-traffic services (> 1000 req/s)
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithSampleRate(0.1), // 10% sampling
)
```

#### 2. Not Excluding High-Frequency Endpoints

**Problem:** Tracing health checks and metrics endpoints.

**Solution:** Exclude them:

```go
handler := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics", "/ready", "/live"),
)(mux)
```

#### 3. Too Many Span Attributes

**Problem:** Adding excessive attributes to every span.

**Solution:** Only add essential attributes:

```go
// ✓ Good - essential attributes
tracer.SetSpanAttribute(span, "user.id", userID)
tracer.SetSpanAttribute(span, "request.id", requestID)

// ✗ Bad - too many attributes
for k, v := range req.Header {
    tracer.SetSpanAttribute(span, k, v) // Don't do this!
}
```

#### 4. Using Regex for Path Exclusion

**Problem:** Regex patterns are slower than exact paths.

**Solution:** Prefer exact paths or prefixes:

```go
// ✓ Faster - O(1) hash lookup
tracing.WithExcludePaths("/health", "/metrics")

// ✗ Slower - O(p) regex matching
tracing.WithExcludePatterns("^/(health|metrics)$")
```

## Configuration Errors

### Multiple Providers Configured

**Error:** `"validation errors: provider: multiple providers configured"`

**Problem:** Attempting to configure multiple providers.

**Solution:** Only configure one provider:

```go
// ✗ Error - multiple providers
tracer, err := tracing.New(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(),
    tracing.WithOTLP("localhost:4317"), // Error!
)

// ✓ Good - one provider
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317"),
)
```

### Empty Service Name

**Error:** `"invalid configuration: serviceName: cannot be empty"`

**Problem:** Service name not provided or empty string.

**Solution:** Always provide a service name:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"), // Required
)
```

### Invalid Regex Pattern

**Error:** Middleware panics with `"middleware validation errors: excludePatterns: invalid regex..."`

**Problem:** Invalid regex pattern in `WithExcludePatterns`.

**Solution:** Validate regex patterns:

```go
// ✗ Invalid regex
tracing.WithExcludePatterns(`[invalid`)

// ✓ Valid regex
tracing.WithExcludePatterns(`^/v[0-9]+/internal/.*`)
```

## OTLP Connection Issues

### TLS Certificate Errors

**Problem:** TLS certificate verification fails.

**Solution:** Use insecure connection for local development:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317", tracing.OTLPInsecure()),
)
```

For production, ensure proper TLS certificates are configured.

### Connection Refused

**Problem:** Cannot connect to OTLP endpoint.

**Solution:**

1. Verify collector is running:
   ```bash
   docker ps | grep otel-collector
   ```

2. Check endpoint is correct:
   ```go
   // Correct format: "host:port"
   tracing.WithOTLP("localhost:4317")
   
   // Not: "http://localhost:4317" (no protocol for gRPC)
   ```

3. Check network connectivity:
   ```bash
   telnet localhost 4317
   ```

### Wrong Endpoint for HTTP

**Problem:** Using gRPC endpoint for HTTP or vice versa.

**Solution:** Use correct provider and endpoint:

```go
// OTLP gRPC (port 4317)
tracing.WithOTLP("localhost:4317")

// OTLP HTTP (port 4318, include protocol)
tracing.WithOTLPHTTP("http://localhost:4318")
```

## Middleware Issues

### Spans Not Created

**Problem:** Middleware doesn't create spans for requests.

**Solution:** Ensure middleware is applied:

```go
mux := http.NewServeMux()
mux.HandleFunc("/api/users", handleUsers)

// ✓ Middleware applied
handler := tracing.Middleware(tracer)(mux)
http.ListenAndServe(":8080", handler)

// ✗ Middleware not applied
http.ListenAndServe(":8080", mux) // No tracing!
```

### Context Lost in Handlers

**Problem:** Context doesn't contain trace information.

**Solution:** Use context from request:

```go
func handleUsers(w http.ResponseWriter, r *http.Request) {
    // ✓ Good - use request context
    ctx := r.Context()
    traceID := tracing.TraceID(ctx)
    
    // ✗ Bad - creates new context
    ctx := context.Background() // Lost trace context!
}
```

## Testing Issues

### Tests Fail to Clean Up

**Problem:** Tests hang or don't complete cleanup.

**Solution:** Use testing utilities:

```go
func TestSomething(t *testing.T) {
    // ✓ Good - automatic cleanup
    tracer := tracing.TestingTracer(t)
    
    // ✗ Bad - manual cleanup required
    tracer, _ := tracing.New(tracing.WithNoop())
    defer tracer.Shutdown(context.Background())
}
```

### Race Conditions in Tests

**Problem:** Race detector reports issues in parallel tests.

**Solution:** Use `t.Parallel()` correctly:

```go
func TestParallel(t *testing.T) {
    t.Parallel() // Each test gets its own tracer
    
    tracer := tracing.TestingTracer(t)
    // Use tracer...
}
```

## Debugging Tips

### Enable Debug Logging

See internal events:

```go
logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
}))

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithLogger(logger),
)
```

### Use Stdout Provider

See traces immediately:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithStdout(), // Print traces to console
)
```

### Check Trace IDs

Verify trace context is propagated:

```go
func handleRequest(ctx context.Context) {
    traceID := tracing.TraceID(ctx)
    log.Printf("Processing request [trace=%s]", traceID)
    
    if traceID == "" {
        log.Printf("WARNING: No trace context!")
    }
}
```

### Verify Sampling

Log sampling decisions:

```go
startHook := func(ctx context.Context, span trace.Span, req *http.Request) {
    if span.SpanContext().IsValid() {
        log.Printf("Request sampled: %s", req.URL.Path)
    } else {
        log.Printf("Request not sampled: %s", req.URL.Path)
    }
}

tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithSpanStartHook(startHook),
)
```

## Getting Help

### Check Documentation

- [Tracing Guide](/guides/tracing/) - Learning-focused content
- [API Reference](../api-reference/) - Complete API documentation
- [Options](../options/) - All configuration options
- [Middleware Options](../middleware-options/) - HTTP middleware options

### Check Logs

Enable debug logging to see internal events:

```go
tracing.WithLogger(slog.Default())
```

### Verify Configuration

Print configuration at startup:

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-service"),
    tracing.WithOTLP("localhost:4317"),
    tracing.WithSampleRate(0.1),
)

log.Printf("Tracer configured:")
log.Printf("  Service: %s", tracer.ServiceName())
log.Printf("  Version: %s", tracer.ServiceVersion())
log.Printf("  Provider: %s", tracer.GetProvider())
log.Printf("  Enabled: %v", tracer.IsEnabled())
```

### Common Pitfalls Checklist

- [ ] Called `Start()` for OTLP providers?
- [ ] Shutdown with proper timeout?
- [ ] Context propagated through call chain?
- [ ] Trace context injected into outgoing requests?
- [ ] Sample rate high enough to see traces?
- [ ] Paths not excluded from tracing?
- [ ] OTLP collector running and reachable?
- [ ] All services using same propagator?
- [ ] Only one provider configured?

## Version Compatibility

### Go Version

**Minimum required:** Go 1.25+

**Error:** `go: module requires Go 1.25 or later`

**Solution:** Upgrade Go version:

```bash
go version  # Check current version
# Upgrade to Go 1.25+
```

### OpenTelemetry Version

The tracing package uses OpenTelemetry SDK v1.x. If you have conflicts with other dependencies:

```bash
go mod tidy
go get -u rivaas.dev/tracing
```

## Next Steps

- Review [API Reference](../api-reference/) for detailed method documentation
- Check [Options](../options/) for configuration options
- See [Examples](/guides/tracing/examples/) for working configurations
- Visit [GitHub Issues](https://github.com/rivaas-dev/rivaas/issues) to report bugs
