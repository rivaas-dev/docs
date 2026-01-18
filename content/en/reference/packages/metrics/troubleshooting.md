---
title: "Troubleshooting"
description: "Common issues and solutions for the metrics package"
weight: 4
---

Solutions to common issues when using the metrics package.

## Metrics Not Appearing

### OTLP Provider

**Symptoms**:
- Metrics not visible in collector
- No data in monitoring system
- Silent failures

**Solutions**:

#### 1. Call Start() Before Recording

The OTLP provider requires `Start()` to be called before recording metrics:

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithServiceName("my-service"),
)

// IMPORTANT: Call Start() before recording
if err := recorder.Start(ctx); err != nil {
    log.Fatal(err)
}

// Now recording works
_ = recorder.IncrementCounter(ctx, "requests_total")
```

#### 2. Check OTLP Collector Reachability

Verify the collector is accessible:

```bash
# Test connectivity
curl http://localhost:4318/v1/metrics

# Check collector logs
docker logs otel-collector
```

#### 3. Wait for Export Interval

OTLP exports metrics periodically (default: 30s):

```go
// Reduce interval for testing
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithExportInterval(5 * time.Second),
    metrics.WithServiceName("my-service"),
)
```

Or force immediate export:

```go
if err := recorder.ForceFlush(ctx); err != nil {
    log.Printf("Failed to flush: %v", err)
}
```

#### 4. Enable Logging

Add logging to see what's happening:

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithLogger(slog.Default()),
    metrics.WithServiceName("my-service"),
)
```

### Prometheus Provider

**Symptoms**:
- Metrics endpoint returns 404
- Empty metrics output
- Server not accessible

**Solutions**:

#### 1. Call Start() to Start Server

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-service"),
)

// Start the HTTP server
if err := recorder.Start(ctx); err != nil {
    log.Fatal(err)
}
```

#### 2. Check Actual Address

If not using strict mode, server may use different port:

```go
address := recorder.ServerAddress()
log.Printf("Metrics at: http://%s/metrics", address)
```

#### 3. Verify Firewall/Network

Check if port is accessible:

```bash
# Test locally
curl http://localhost:9090/metrics

# Check from another machine
curl http://<server-ip>:9090/metrics
```

### Stdout Provider

**Symptoms**:
- No output to console
- Metrics not visible

**Solutions**:

#### 1. Wait for Export Interval

Stdout exports periodically (default: 30s):

```go
recorder := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithExportInterval(5 * time.Second),  // Shorter interval
    metrics.WithServiceName("my-service"),
)
```

#### 2. Force Flush

```go
if err := recorder.ForceFlush(ctx); err != nil {
    log.Printf("Failed to flush: %v", err)
}
```

## Port Conflicts

### Symptoms

- Error: `address already in use`
- Metrics server fails to start
- Different port than expected

### Solutions

#### 1. Use Strict Port Mode (Production)

Fail explicitly if port unavailable:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithStrictPort(),  // Fail if 9090 unavailable
    metrics.WithServiceName("my-service"),
)
```

#### 2. Check Port Usage

Find what's using the port:

```bash
# Linux/macOS
lsof -i :9090
netstat -tuln | grep 9090

# Windows
netstat -ano | findstr :9090
```

#### 3. Use Dynamic Port (Testing)

Let the system choose an available port:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":0", "/metrics"),  // :0 = any available port
    metrics.WithServiceName("test-service"),
)
recorder.Start(ctx)

// Get actual port
address := recorder.ServerAddress()
log.Printf("Using port: %s", address)
```

#### 4. Use Testing Utilities

For tests, use the testing utilities with automatic port allocation:

```go
func TestMetrics(t *testing.T) {
    t.Parallel()
    recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")
    // Automatically finds available port
}
```

## Custom Metric Limit Reached

### Symptoms

- Error: `custom metric limit reached`
- New metrics not created
- Warning in logs

### Solutions

#### 1. Increase Limit

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithMaxCustomMetrics(5000),  // Increase from default 1000
    metrics.WithServiceName("my-service"),
)
```

#### 2. Monitor Usage

Track how many custom metrics are created:

```go
count := recorder.CustomMetricCount()
log.Printf("Custom metrics: %d/%d", count, maxLimit)

// Expose as a metric
_ = recorder.SetGauge(ctx, "custom_metrics_count", float64(count))
```

#### 3. Review Metric Cardinality

Check if you're creating too many unique metrics:

```go
// BAD: High cardinality (unique per user)
_ = recorder.IncrementCounter(ctx, "user_"+userID+"_requests")

// GOOD: Low cardinality (use labels)
_ = recorder.IncrementCounter(ctx, "user_requests_total",
    attribute.String("user_type", userType),
)
```

#### 4. Consolidate Metrics

Combine similar metrics:

```go
// BAD: Many separate metrics
_ = recorder.IncrementCounter(ctx, "get_requests_total")
_ = recorder.IncrementCounter(ctx, "post_requests_total")
_ = recorder.IncrementCounter(ctx, "put_requests_total")

// GOOD: One metric with label
_ = recorder.IncrementCounter(ctx, "requests_total",
    attribute.String("method", "GET"),
)
```

### What Counts as Custom Metric?

**Counts**:
- Each unique metric name created with `IncrementCounter`, `AddCounter`, `RecordHistogram`, `SetGauge`

**Does NOT count**:
- Built-in HTTP metrics
- Different label combinations of same metric
- Re-recording same metric name

## Metrics Server Not Starting

### Symptoms

- `Start()` returns error
- Server not accessible
- No metrics endpoint

### Solutions

#### 1. Check Context

Ensure context is not canceled:

```go
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
defer cancel()

// Use context with Start
if err := recorder.Start(ctx); err != nil {
    log.Fatal(err)
}
```

#### 2. Check Port Availability

See [Port Conflicts](#port-conflicts) section.

#### 3. Enable Logging

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithLogger(slog.Default()),
    metrics.WithServiceName("my-service"),
)
```

#### 4. Check Permissions

Ensure your process has permission to bind to the port (< 1024 requires root on Linux).

## Invalid Metric Names

### Symptoms

- Error: `invalid metric name`
- Metrics not recorded
- Reserved prefix error

### Solutions

#### 1. Check Naming Rules

Metric names must:
- Start with letter (a-z, A-Z)
- Contain only: letters, numbers, underscores, dots, hyphens
- Not use reserved prefixes: `__`, `http_`, `router_`
- Maximum 255 characters

**Valid**:

```go
_ = recorder.IncrementCounter(ctx, "orders_total")
_ = recorder.IncrementCounter(ctx, "api.v1.requests")
_ = recorder.IncrementCounter(ctx, "payment-success")
```

**Invalid**:

```go
_ = recorder.IncrementCounter(ctx, "__internal")      // Reserved prefix
_ = recorder.IncrementCounter(ctx, "http_custom")     // Reserved prefix
_ = recorder.IncrementCounter(ctx, "router_gauge")    // Reserved prefix
_ = recorder.IncrementCounter(ctx, "1st_metric")      // Starts with number
_ = recorder.IncrementCounter(ctx, "my metric!")      // Invalid characters
```

#### 2. Handle Errors

Check for naming errors:

```go
if err := recorder.IncrementCounter(ctx, metricName); err != nil {
    log.Printf("Invalid metric name %q: %v", metricName, err)
}
```

## High Memory Usage

### Symptoms

- Excessive memory consumption
- Out of memory errors
- Slow performance

### Solutions

#### 1. Reduce Metric Cardinality

Limit unique label combinations:

```go
// BAD: High cardinality
_ = recorder.IncrementCounter(ctx, "requests_total",
    attribute.String("user_id", userID),        // Millions of values
    attribute.String("request_id", requestID),  // Always unique
)

// GOOD: Low cardinality
_ = recorder.IncrementCounter(ctx, "requests_total",
    attribute.String("user_type", userType),    // Few values
    attribute.String("region", region),          // Few values
)
```

#### 2. Exclude High-Cardinality Paths

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePatterns(
        `^/api/users/[0-9]+$`,      // User IDs
        `^/api/orders/[a-z0-9-]+$`, // Order IDs
    ),
)(mux)
```

#### 3. Reduce Histogram Buckets

```go
// BAD: Too many buckets (15)
metrics.WithDurationBuckets(
    0.001, 0.005, 0.01, 0.025, 0.05,
    0.1, 0.25, 0.5, 1, 2.5,
    5, 10, 30, 60, 120,
)

// GOOD: Fewer buckets (7)
metrics.WithDurationBuckets(0.01, 0.1, 0.5, 1, 5, 10)
```

#### 4. Monitor Custom Metrics

```go
count := recorder.CustomMetricCount()
if count > 500 {
    log.Printf("WARNING: High custom metric count: %d", count)
}
```

## Performance Issues

### HTTP Middleware Overhead

**Symptom**: Slow request handling

**Solution**: Exclude high-traffic paths:

```go
handler := metrics.Middleware(recorder,
    metrics.WithExcludePaths("/health"),  // Called frequently
    metrics.WithExcludePrefixes("/static/"),  // Static assets
)(mux)
```

### Histogram Recording Slow

**Symptom**: High CPU usage

**Solution**: Reduce bucket count (see [High Memory Usage](#high-memory-usage)).

## Global State Issues

### Symptoms

- Multiple recorder instances conflict
- Unexpected behavior with multiple services
- Global meter provider issues

### Solutions

#### 1. Use Default Behavior (Recommended)

By default, recorders do NOT set global meter provider:

```go
// These work independently
recorder1 := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("service-1"),
)

recorder2 := metrics.MustNew(
    metrics.WithStdout(),
    metrics.WithServiceName("service-2"),
)
```

#### 2. Avoid WithGlobalMeterProvider

Only use `WithGlobalMeterProvider()` if you need:
- OpenTelemetry instrumentation libraries to use your provider
- `otel.GetMeterProvider()` to return your provider

```go
// Only if needed
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithGlobalMeterProvider(),  // Explicit opt-in
    metrics.WithServiceName("my-service"),
)
```

## Thread Safety

All `Recorder` methods are thread-safe. No special handling needed for concurrent access:

```go
// Safe to call from multiple goroutines
go func() {
    _ = recorder.IncrementCounter(ctx, "worker_1")
}()

go func() {
    _ = recorder.IncrementCounter(ctx, "worker_2")
}()
```

## Shutdown Issues

### Graceful Shutdown Not Working

**Solution**: Use proper timeout context:

```go
shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

if err := recorder.Shutdown(shutdownCtx); err != nil {
    log.Printf("Shutdown error: %v", err)
}
```

### Metrics Not Flushed on Exit

**Solution**: Always defer `Shutdown()`:

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithServiceName("my-service"),
)
recorder.Start(ctx)

defer func() {
    shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    recorder.Shutdown(shutdownCtx)
}()
```

## Testing Issues

### Port Conflicts in Parallel Tests

**Solution**: Use testing utilities with dynamic ports:

```go
func TestHandler(t *testing.T) {
    t.Parallel()  // Safe with TestingRecorder
    
    // Uses stdout, no port needed
    recorder := metrics.TestingRecorder(t, "test-service")
    
    // Or with Prometheus (dynamic port)
    recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")
}
```

### Server Not Ready

**Solution**: Wait for server:

```go
recorder := metrics.TestingRecorderWithPrometheus(t, "test-service")

err := metrics.WaitForMetricsServer(t, recorder.ServerAddress(), 5*time.Second)
if err != nil {
    t.Fatal(err)
}
```

## Getting Help

If you're still experiencing issues:

1. **Check logs**: Enable logging with `WithLogger(slog.Default())`
2. **Review configuration**: Verify all options are correct
3. **Test connectivity**: Ensure network access to endpoints
4. **Check version**: Update to latest version
5. **File an issue**: [GitHub Issues](https://github.com/rivaas-dev/rivaas/issues)

## Quick Reference

### Common Patterns

**Production Setup**:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithStrictPort(),
    metrics.WithServiceName("my-api"),
    metrics.WithServiceVersion(version),
    metrics.WithLogger(slog.Default()),
)
```

**OTLP Setup**:

```go
recorder := metrics.MustNew(
    metrics.WithOTLP("http://localhost:4318"),
    metrics.WithServiceName("my-service"),
)
// IMPORTANT: Call Start() before recording
recorder.Start(ctx)
```

**Testing Setup**:

```go
func TestMetrics(t *testing.T) {
    t.Parallel()
    recorder := metrics.TestingRecorder(t, "test-service")
    // Test code...
}
```

## Next Steps

- Review [Configuration Guide](/guides/metrics/configuration/) for setup examples
- Check [API Reference](../api-reference/) for method details
- See [Examples](/guides/metrics/examples/) for complete applications
- Read [Basic Usage](/guides/metrics/basic-usage/) for fundamentals
