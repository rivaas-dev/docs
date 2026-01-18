---
title: "Custom Metrics"
description: "Create counters, histograms, and gauges with proper naming conventions"
weight: 5
---

This guide covers recording custom metrics beyond the built-in HTTP metrics.

## Metric Types

The metrics package supports three metric types from OpenTelemetry:

| Type | Description | Use Case | Example |
|------|-------------|----------|---------|
| **Counter** | Monotonically increasing value | Counts of events | Requests processed, errors occurred |
| **Histogram** | Distribution of values | Durations, sizes | Query time, response size |
| **Gauge** | Point-in-time value | Current state | Active connections, queue depth |

## Counters

Counters track cumulative totals that only increase.

### Increment Counter

Add 1 to a counter:

```go
// With error handling
if err := recorder.IncrementCounter(ctx, "orders_processed_total",
    attribute.String("status", "success"),
    attribute.String("payment_method", "card"),
); err != nil {
    log.Printf("Failed to record metric: %v", err)
}

// Fire-and-forget (ignore errors)
_ = recorder.IncrementCounter(ctx, "page_views_total")
```

### Add to Counter

Add a specific value to a counter:

```go
// Add multiple items (value is int64)
_ = recorder.AddCounter(ctx, "bytes_processed_total", 1024,
    attribute.String("direction", "inbound"),
)

// Batch processing
itemsProcessed := int64(50)
_ = recorder.AddCounter(ctx, "items_processed_total", itemsProcessed,
    attribute.String("batch_id", batchID),
)
```

**Important**: Counter values must be non-negative integers (`int64`).

### Counter Examples

```go
// Simple event counting
_ = recorder.IncrementCounter(ctx, "user_registrations_total")

// With attributes
_ = recorder.IncrementCounter(ctx, "api_calls_total",
    attribute.String("endpoint", "/api/users"),
    attribute.String("method", "POST"),
    attribute.Int("status_code", 201),
)

// Tracking errors
_ = recorder.IncrementCounter(ctx, "errors_total",
    attribute.String("type", "validation"),
    attribute.String("field", "email"),
)

// Data volume
_ = recorder.AddCounter(ctx, "data_transferred_bytes", float64(len(data)),
    attribute.String("protocol", "https"),
    attribute.String("direction", "upload"),
)
```

## Histograms

Histograms record distributions of values, useful for durations and sizes.

### Record Histogram

```go
startTime := time.Now()
// ... perform operation ...
duration := time.Since(startTime).Seconds()

_ = recorder.RecordHistogram(ctx, "operation_duration_seconds", duration,
    attribute.String("operation", "create_user"),
    attribute.String("status", "success"),
)
```

### Histogram Examples

```go
// Request duration
start := time.Now()
result, err := processRequest(ctx, req)
duration := time.Since(start).Seconds()

_ = recorder.RecordHistogram(ctx, "request_processing_duration_seconds", duration,
    attribute.String("operation", "process_request"),
    attribute.Bool("cache_hit", result.FromCache),
)

// Database query time
start = time.Now()
rows, err := db.QueryContext(ctx, query)
duration = time.Since(start).Seconds()

_ = recorder.RecordHistogram(ctx, "db_query_duration_seconds", duration,
    attribute.String("query_type", "select"),
    attribute.String("table", "users"),
)

// Response size
responseSize := len(responseData)
_ = recorder.RecordHistogram(ctx, "response_size_bytes", float64(responseSize),
    attribute.String("endpoint", "/api/users"),
    attribute.String("format", "json"),
)

// Payment amount
_ = recorder.RecordHistogram(ctx, "payment_amount_usd", amount,
    attribute.String("currency", "USD"),
    attribute.String("payment_method", "credit_card"),
)
```

### Histogram Bucket Configuration

Customize bucket boundaries for better resolution (see [Configuration](../configuration/#histogram-bucket-configuration)):

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    // Fine-grained buckets for fast operations
    metrics.WithDurationBuckets(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.5),
    metrics.WithServiceName("my-api"),
)
```

## Gauges

Gauges represent point-in-time values that can increase or decrease.

### Set Gauge

```go
// Current connections
activeConnections := connectionPool.Active()
_ = recorder.SetGauge(ctx, "active_connections", float64(activeConnections),
    attribute.String("pool", "database"),
)

// Queue depth
queueSize := queue.Len()
_ = recorder.SetGauge(ctx, "queue_depth", float64(queueSize),
    attribute.String("queue", "tasks"),
)
```

### Gauge Examples

```go
// Memory usage
var m runtime.MemStats
runtime.ReadMemStats(&m)
_ = recorder.SetGauge(ctx, "memory_allocated_bytes", float64(m.Alloc))

// Goroutine count
_ = recorder.SetGauge(ctx, "goroutines_active", float64(runtime.NumGoroutine()))

// Cache size
cacheSize := cache.Len()
_ = recorder.SetGauge(ctx, "cache_entries", float64(cacheSize),
    attribute.String("cache", "users"),
)

// Connection pool
_ = recorder.SetGauge(ctx, "db_connections_active", float64(pool.Stats().InUse),
    attribute.String("database", "postgres"),
)

// Worker pool
_ = recorder.SetGauge(ctx, "worker_pool_idle", float64(workerPool.IdleCount()),
    attribute.String("pool", "background_jobs"),
)

// Temperature (example from IoT)
_ = recorder.SetGauge(ctx, "sensor_temperature_celsius", temperature,
    attribute.String("sensor_id", sensorID),
    attribute.String("location", "datacenter-1"),
)
```

### Gauge Best Practices

**DO**:
- Record current state: active connections, queue depth
- Update regularly with latest values
- Use for resource utilization metrics

**DON'T**:
- Use for cumulative counts (use Counter instead)
- Forget to update when value changes
- Use for values that only increase (use Counter)

## Metric Naming Conventions

Follow OpenTelemetry and Prometheus naming conventions for consistent metrics.

### Valid Metric Names

Metric names must:
- Start with a letter (a-z, A-Z)
- Contain only alphanumeric, underscores, dots, hyphens
- Maximum 255 characters
- Not use reserved prefixes

**Valid Examples**:

```go
_ = recorder.IncrementCounter(ctx, "orders_total")
_ = recorder.RecordHistogram(ctx, "processing_duration_seconds", 1.5)
_ = recorder.SetGauge(ctx, "active_users", 42)
_ = recorder.IncrementCounter(ctx, "api.v1.requests_total")
_ = recorder.RecordHistogram(ctx, "payment-processing-time", 2.0)
```

### Invalid Metric Names

These will return an error:

```go
// Reserved prefix: __
recorder.IncrementCounter(ctx, "__internal_metric")

// Reserved prefix: http_
recorder.RecordHistogram(ctx, "http_custom_duration", 1.0)

// Reserved prefix: router_
recorder.SetGauge(ctx, "router_custom_gauge", 10)

// Starts with number
recorder.IncrementCounter(ctx, "1st_metric")

// Invalid characters
recorder.IncrementCounter(ctx, "my metric!")  // Space and !
recorder.IncrementCounter(ctx, "metric@count")  // @ symbol
```

### Reserved Prefixes

These prefixes are reserved for built-in metrics:

- `__` - Prometheus internal metrics
- `http_` - Built-in HTTP metrics
- `router_` - Built-in router metrics

### Naming Best Practices

**Units in Name**:

```go
// Good - includes unit
_ = recorder.RecordHistogram(ctx, "processing_duration_seconds", 1.5)
_ = recorder.RecordHistogram(ctx, "response_size_bytes", 1024)
_ = recorder.SetGauge(ctx, "temperature_celsius", 25.5)

// Bad - no unit
_ = recorder.RecordHistogram(ctx, "processing_duration", 1.5)
_ = recorder.RecordHistogram(ctx, "response_size", 1024)
```

**Counter Suffix**:

```go
// Good - ends with _total
_ = recorder.IncrementCounter(ctx, "requests_total")
_ = recorder.IncrementCounter(ctx, "errors_total")
_ = recorder.AddCounter(ctx, "bytes_processed_total", 1024)

// Acceptable - clear it's a count
_ = recorder.IncrementCounter(ctx, "request_count")

// Bad - unclear
_ = recorder.IncrementCounter(ctx, "requests")
```

**Descriptive Names**:

```go
// Good - clear and specific
_ = recorder.RecordHistogram(ctx, "db_query_duration_seconds", 0.15)
_ = recorder.IncrementCounter(ctx, "payment_failures_total")
_ = recorder.SetGauge(ctx, "redis_connections_active", 10)

// Bad - too generic
_ = recorder.RecordHistogram(ctx, "duration", 0.15)
_ = recorder.IncrementCounter(ctx, "failures")
_ = recorder.SetGauge(ctx, "connections", 10)
```

**Consistent Style**:

```go
// Good - consistent snake_case
_ = recorder.IncrementCounter(ctx, "user_registrations_total")
_ = recorder.IncrementCounter(ctx, "order_completions_total")

// Avoid mixing styles
_ = recorder.IncrementCounter(ctx, "userRegistrations")  // camelCase
_ = recorder.IncrementCounter(ctx, "order-completions")  // kebab-case
```

## Attributes (Labels)

Attributes add dimensions to metrics for filtering and grouping.

### Using Attributes

```go
import "go.opentelemetry.io/otel/attribute"

_ = recorder.IncrementCounter(ctx, "requests_total",
    attribute.String("method", "GET"),
    attribute.String("path", "/api/users"),
    attribute.Int("status_code", 200),
)
```

### Attribute Types

```go
// String
attribute.String("status", "success")
attribute.String("region", "us-east-1")

// Integer
attribute.Int("status_code", 200)
attribute.Int("retry_count", 3)

// Boolean
attribute.Bool("cache_hit", true)
attribute.Bool("authenticated", false)

// Float
attribute.Float64("error_rate", 0.05)
```

### Attribute Best Practices

**Keep Cardinality Low**:

```go
// Good - low cardinality
attribute.String("status", "success")  // success, error, timeout
attribute.String("method", "GET")      // GET, POST, PUT, DELETE

// Bad - high cardinality (unbounded)
attribute.String("user_id", userID)         // Millions of unique values
attribute.String("request_id", requestID)   // Unique per request
attribute.String("timestamp", time.Now().String())  // Always unique
```

**Use Consistent Names**:

```go
// Good - consistent across metrics
attribute.String("status", "success")
attribute.String("method", "GET")
attribute.String("region", "us-east-1")

// Bad - inconsistent
attribute.String("status", "success")
attribute.String("http_method", "GET")  // Should be "method"
attribute.String("aws_region", "us-east-1")  // Should be "region"
```

**Limit Attribute Count**:

```go
// Good - focused attributes
_ = recorder.IncrementCounter(ctx, "requests_total",
    attribute.String("method", "GET"),
    attribute.String("status", "success"),
)

// Bad - too many attributes
_ = recorder.IncrementCounter(ctx, "requests_total",
    attribute.String("method", "GET"),
    attribute.String("status", "success"),
    attribute.String("user_agent", ua),
    attribute.String("ip_address", ip),
    attribute.String("country", country),
    attribute.String("device", device),
    // ... creates explosion of metric combinations
)
```

## Monitoring Custom Metrics

Track how many custom metrics have been created:

```go
count := recorder.CustomMetricCount()
log.Printf("Custom metrics created: %d/%d", count, maxLimit)

// Expose as a metric
_ = recorder.SetGauge(ctx, "custom_metrics_count", float64(count))
```

### Custom Metric Limit

Default limit: 1000 custom metrics

Increase the limit:

```go
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithMaxCustomMetrics(5000),
    metrics.WithServiceName("my-api"),
)
```

### What Counts as Custom Metric?

**Counts toward limit**:
- Each unique metric name created with `IncrementCounter`, `AddCounter`, `RecordHistogram`, or `SetGauge`

**Does NOT count**:
- Built-in HTTP metrics (`http_requests_total`, etc.)
- Different attribute combinations of same metric name
- Re-recording same metric name

**Example**:

```go
// Creates 1 custom metric
_ = recorder.IncrementCounter(ctx, "orders_total")
_ = recorder.IncrementCounter(ctx, "orders_total", attribute.String("status", "success"))
_ = recorder.IncrementCounter(ctx, "orders_total", attribute.String("status", "failed"))

// Creates 2 more custom metrics (total: 3)
_ = recorder.IncrementCounter(ctx, "payments_total")
_ = recorder.RecordHistogram(ctx, "order_duration_seconds", 1.5)
```

## Error Handling

All metric methods return an error. Choose your handling strategy:

### Check Errors (Critical Metrics)

```go
if err := recorder.IncrementCounter(ctx, "payment_processed_total",
    attribute.String("method", "credit_card"),
); err != nil {
    log.Printf("Failed to record payment metric: %v", err)
    // Alert or handle appropriately
}
```

### Fire-and-Forget (Best Effort)

```go
// Most metrics - don't impact application performance
_ = recorder.IncrementCounter(ctx, "page_views_total")
_ = recorder.RecordHistogram(ctx, "render_time_seconds", duration)
```

### Common Errors

- **Invalid name**: Violates naming rules
- **Reserved prefix**: Uses `__`, `http_`, or `router_`
- **Limit reached**: Custom metric limit exceeded
- **Provider not started**: OTLP provider not initialized

## Built-in Metrics

The package automatically collects these HTTP metrics (when using middleware):

| Metric | Type | Description |
|--------|------|-------------|
| `http_request_duration_seconds` | Histogram | Request duration distribution |
| `http_requests_total` | Counter | Total requests by method, path, status |
| `http_requests_active` | Gauge | Currently active requests |
| `http_request_size_bytes` | Histogram | Request body size distribution |
| `http_response_size_bytes` | Histogram | Response body size distribution |
| `http_errors_total` | Counter | HTTP errors by status code |
| `custom_metric_failures_total` | Counter | Failed custom metric creations |

**Note**: Built-in metrics don't count toward the custom metrics limit.

## Next Steps

- Learn [Middleware](../middleware/) to automatically collect HTTP metrics
- See [Configuration](../configuration/) for histogram bucket customization
- Check [Examples](../examples/) for real-world patterns
- Review [API Reference](/reference/packages/metrics/api-reference/) for method details
