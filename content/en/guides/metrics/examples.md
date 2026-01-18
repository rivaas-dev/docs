---
title: "Examples"
description: "Real-world examples of metrics collection patterns"
weight: 8
---

This guide provides complete, real-world examples of using the metrics package.

## Simple HTTP Server

Basic HTTP server with Prometheus metrics:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "time"
    
    "rivaas.dev/metrics"
)

func main() {
    // Create lifecycle context
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create metrics recorder
    recorder, err := metrics.New(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("simple-api"),
        metrics.WithServiceVersion("v1.0.0"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Start metrics server
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    defer func() {
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        if err := recorder.Shutdown(shutdownCtx); err != nil {
            log.Printf("Metrics shutdown error: %v", err)
        }
    }()

    // Create HTTP handlers
    mux := http.NewServeMux()
    
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"message": "Hello, World!"}`))
    })
    
    mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    })

    // Wrap with metrics middleware
    handler := metrics.Middleware(recorder,
        metrics.WithExcludePaths("/health", "/metrics"),
    )(mux)

    // Start HTTP server
    server := &http.Server{
        Addr:    ":8080",
        Handler: handler,
    }
    
    go func() {
        log.Printf("Server listening on :8080")
        log.Printf("Metrics available at http://localhost:9090/metrics")
        if err := server.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()
    
    // Wait for interrupt
    <-ctx.Done()
    log.Println("Shutting down gracefully...")
    
    shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    server.Shutdown(shutdownCtx)
}
```

Run and test:

```bash
# Start server
go run main.go

# Make requests
curl http://localhost:8080/

# View metrics
curl http://localhost:9090/metrics
```

## Custom Metrics Example

Application with custom business metrics:

```go
package main

import (
    "context"
    "log"
    "math/rand"
    "os"
    "os/signal"
    "time"
    
    "rivaas.dev/metrics"
    "go.opentelemetry.io/otel/attribute"
)

type OrderProcessor struct {
    recorder *metrics.Recorder
}

func NewOrderProcessor(recorder *metrics.Recorder) *OrderProcessor {
    return &OrderProcessor{recorder: recorder}
}

func (p *OrderProcessor) ProcessOrder(ctx context.Context, orderID string, amount float64) error {
    start := time.Now()
    
    // Simulate processing
    time.Sleep(time.Duration(rand.Intn(100)) * time.Millisecond)
    
    // Record processing duration
    duration := time.Since(start).Seconds()
    _ = p.recorder.RecordHistogram(ctx, "order_processing_duration_seconds", duration,
        attribute.String("order_id", orderID),
    )
    
    // Record order amount
    _ = p.recorder.RecordHistogram(ctx, "order_amount_usd", amount,
        attribute.String("currency", "USD"),
    )
    
    // Increment orders processed counter
    _ = p.recorder.IncrementCounter(ctx, "orders_processed_total",
        attribute.String("status", "success"),
    )
    
    log.Printf("Processed order %s: $%.2f in %.3fs", orderID, amount, duration)
    return nil
}

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Create metrics recorder
    recorder := metrics.MustNew(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("order-processor"),
        metrics.WithDurationBuckets(0.01, 0.05, 0.1, 0.5, 1, 5),
    )
    
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())

    processor := NewOrderProcessor(recorder)
    
    log.Println("Processing orders... (metrics at http://localhost:9090/metrics)")
    
    // Simulate order processing
    ticker := time.NewTicker(1 * time.Second)
    defer ticker.Stop()
    
    orderNum := 0
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            orderNum++
            orderID := fmt.Sprintf("ORD-%d", orderNum)
            amount := 10.0 + rand.Float64()*990.0
            
            if err := processor.ProcessOrder(ctx, orderID, amount); err != nil {
                log.Printf("Error processing order: %v", err)
            }
        }
    }
}
```

## OTLP with OpenTelemetry Collector

Send metrics to OpenTelemetry collector:

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "time"
    
    "rivaas.dev/metrics"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // Get OTLP endpoint from environment
    endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
    if endpoint == "" {
        endpoint = "http://localhost:4318"
    }

    // Create recorder with OTLP
    recorder, err := metrics.New(
        metrics.WithOTLP(endpoint),
        metrics.WithServiceName(os.Getenv("SERVICE_NAME")),
        metrics.WithServiceVersion(os.Getenv("SERVICE_VERSION")),
        metrics.WithExportInterval(10 * time.Second),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Important: Start before recording metrics
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    
    defer func() {
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        recorder.Shutdown(shutdownCtx)
    }()

    log.Printf("Sending metrics to OTLP endpoint: %s", endpoint)
    
    // Record metrics periodically
    ticker := time.NewTicker(2 * time.Second)
    defer ticker.Stop()
    
    count := 0
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            count++
            _ = recorder.IncrementCounter(ctx, "app_ticks_total")
            _ = recorder.SetGauge(ctx, "app_counter", float64(count))
            log.Printf("Tick %d", count)
        }
    }
}
```

OpenTelemetry collector configuration:

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  logging:
    loglevel: debug

service:
  pipelines:
    metrics:
      receivers: [otlp]
      exporters: [prometheus, logging]
```

Run collector:

```bash
otel-collector --config=otel-collector-config.yaml
```

## Worker Pool with Gauges

Track worker pool metrics:

```go
package main

import (
    "context"
    "log"
    "math/rand"
    "os"
    "os/signal"
    "sync"
    "time"
    
    "rivaas.dev/metrics"
    "go.opentelemetry.io/otel/attribute"
)

type WorkerPool struct {
    workers  int
    active   int
    idle     int
    mu       sync.Mutex
    recorder *metrics.Recorder
}

func NewWorkerPool(size int, recorder *metrics.Recorder) *WorkerPool {
    return &WorkerPool{
        workers:  size,
        idle:     size,
        recorder: recorder,
    }
}

func (p *WorkerPool) updateMetrics(ctx context.Context) {
    p.mu.Lock()
    active := p.active
    idle := p.idle
    p.mu.Unlock()
    
    _ = p.recorder.SetGauge(ctx, "worker_pool_active", float64(active))
    _ = p.recorder.SetGauge(ctx, "worker_pool_idle", float64(idle))
    _ = p.recorder.SetGauge(ctx, "worker_pool_total", float64(p.workers))
}

func (p *WorkerPool) DoWork(ctx context.Context, jobID string) {
    p.mu.Lock()
    p.active++
    p.idle--
    p.mu.Unlock()
    
    p.updateMetrics(ctx)
    
    start := time.Now()
    
    // Simulate work
    time.Sleep(time.Duration(rand.Intn(1000)) * time.Millisecond)
    
    duration := time.Since(start).Seconds()
    _ = p.recorder.RecordHistogram(ctx, "job_duration_seconds", duration,
        attribute.String("job_id", jobID),
    )
    _ = p.recorder.IncrementCounter(ctx, "jobs_completed_total")
    
    p.mu.Lock()
    p.active--
    p.idle++
    p.mu.Unlock()
    
    p.updateMetrics(ctx)
}

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    recorder := metrics.MustNew(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("worker-pool"),
    )
    
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())

    pool := NewWorkerPool(10, recorder)
    
    log.Println("Worker pool started (metrics at http://localhost:9090/metrics)")
    
    // Submit jobs
    var wg sync.WaitGroup
    for i := 0; i < 50; i++ {
        wg.Add(1)
        jobID := fmt.Sprintf("job-%d", i)
        
        go func(id string) {
            defer wg.Done()
            pool.DoWork(ctx, id)
        }(jobID)
        
        time.Sleep(100 * time.Millisecond)
    }
    
    wg.Wait()
    log.Println("All jobs completed")
}
```

## Environment-Based Configuration

Load metrics configuration from environment:

```go
package main

import (
    "context"
    "log"
    "os"
    "strconv"
    "time"
    
    "rivaas.dev/metrics"
)

func createRecorder() (*metrics.Recorder, error) {
    var opts []metrics.Option
    
    // Service metadata
    opts = append(opts, metrics.WithServiceName(getEnv("SERVICE_NAME", "my-service")))
    
    if version := os.Getenv("SERVICE_VERSION"); version != "" {
        opts = append(opts, metrics.WithServiceVersion(version))
    }
    
    // Provider selection
    provider := getEnv("METRICS_PROVIDER", "prometheus")
    switch provider {
    case "prometheus":
        addr := getEnv("METRICS_ADDR", ":9090")
        path := getEnv("METRICS_PATH", "/metrics")
        opts = append(opts, metrics.WithPrometheus(addr, path))
        
        if getBoolEnv("METRICS_STRICT_PORT", true) {
            opts = append(opts, metrics.WithStrictPort())
        }
        
    case "otlp":
        endpoint := getEnv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
        opts = append(opts, metrics.WithOTLP(endpoint))
        
        if interval := getDurationEnv("METRICS_EXPORT_INTERVAL", 30*time.Second); interval > 0 {
            opts = append(opts, metrics.WithExportInterval(interval))
        }
        
    case "stdout":
        opts = append(opts, metrics.WithStdout())
        
    default:
        log.Printf("Unknown provider %s, using stdout", provider)
        opts = append(opts, metrics.WithStdout())
    }
    
    // Custom metrics limit
    if limit := getIntEnv("METRICS_MAX_CUSTOM", 1000); limit > 0 {
        opts = append(opts, metrics.WithMaxCustomMetrics(limit))
    }
    
    return metrics.New(opts...)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getBoolEnv(key string, defaultValue bool) bool {
    if value := os.Getenv(key); value != "" {
        b, err := strconv.ParseBool(value)
        if err == nil {
            return b
        }
    }
    return defaultValue
}

func getIntEnv(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        i, err := strconv.Atoi(value)
        if err == nil {
            return i
        }
    }
    return defaultValue
}

func getDurationEnv(key string, defaultValue time.Duration) time.Duration {
    if value := os.Getenv(key); value != "" {
        d, err := time.ParseDuration(value)
        if err == nil {
            return d
        }
    }
    return defaultValue
}

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    recorder, err := createRecorder()
    if err != nil {
        log.Fatal(err)
    }
    
    if err := recorder.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())

    log.Println("Service started with metrics")
    
    // Your application code...
    <-ctx.Done()
}
```

Example `.env` file:

```bash
SERVICE_NAME=my-api
SERVICE_VERSION=v1.2.3
METRICS_PROVIDER=prometheus
METRICS_ADDR=:9090
METRICS_PATH=/metrics
METRICS_STRICT_PORT=true
METRICS_MAX_CUSTOM=2000
```

## Microservices Pattern

Shared metrics setup for microservices:

```go
// pkg/telemetry/metrics.go
package telemetry

import (
    "context"
    "fmt"
    "os"
    
    "rivaas.dev/metrics"
)

type Config struct {
    ServiceName    string
    ServiceVersion string
    MetricsAddr    string
}

func NewMetricsRecorder(cfg Config) (*metrics.Recorder, error) {
    opts := []metrics.Option{
        metrics.WithPrometheus(cfg.MetricsAddr, "/metrics"),
        metrics.WithStrictPort(),
        metrics.WithServiceName(cfg.ServiceName),
    }
    
    if cfg.ServiceVersion != "" {
        opts = append(opts, metrics.WithServiceVersion(cfg.ServiceVersion))
    }
    
    return metrics.New(opts...)
}

// Service-specific metrics helpers
type ServiceMetrics struct {
    recorder *metrics.Recorder
}

func NewServiceMetrics(recorder *metrics.Recorder) *ServiceMetrics {
    return &ServiceMetrics{recorder: recorder}
}

func (m *ServiceMetrics) RecordAPICall(ctx context.Context, endpoint string, duration float64, err error) {
    status := "success"
    if err != nil {
        status = "error"
    }
    
    _ = m.recorder.RecordHistogram(ctx, "api_call_duration_seconds", duration,
        attribute.String("endpoint", endpoint),
        attribute.String("status", status),
    )
    
    _ = m.recorder.IncrementCounter(ctx, "api_calls_total",
        attribute.String("endpoint", endpoint),
        attribute.String("status", status),
    )
}
```

Use in service:

```go
// cmd/user-service/main.go
package main

import (
    "context"
    "log"
    
    "myapp/pkg/telemetry"
)

func main() {
    cfg := telemetry.Config{
        ServiceName:    "user-service",
        ServiceVersion: os.Getenv("VERSION"),
        MetricsAddr:    ":9090",
    }
    
    recorder, err := telemetry.NewMetricsRecorder(cfg)
    if err != nil {
        log.Fatal(err)
    }
    
    if err := recorder.Start(context.Background()); err != nil {
        log.Fatal(err)
    }
    defer recorder.Shutdown(context.Background())
    
    metrics := telemetry.NewServiceMetrics(recorder)
    
    // Use metrics in your service
    // ...
}
```

## Complete Production Example

Full production-ready setup:

```go
package main

import (
    "context"
    "log"
    "log/slog"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
    
    "rivaas.dev/metrics"
)

func main() {
    // Setup structured logging
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    slog.SetDefault(logger)
    
    // Create application context
    ctx, cancel := signal.NotifyContext(
        context.Background(),
        os.Interrupt,
        syscall.SIGTERM,
    )
    defer cancel()

    // Create metrics recorder with production settings
    recorder, err := metrics.New(
        // Provider
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithStrictPort(),
        
        // Service metadata
        metrics.WithServiceName("production-api"),
        metrics.WithServiceVersion(os.Getenv("VERSION")),
        
        // Configuration
        metrics.WithDurationBuckets(0.01, 0.1, 0.5, 1, 5, 10, 30),
        metrics.WithSizeBuckets(100, 1000, 10000, 100000, 1000000),
        metrics.WithMaxCustomMetrics(2000),
        
        // Observability
        metrics.WithLogger(slog.Default()),
    )
    if err != nil {
        slog.Error("Failed to create metrics recorder", "error", err)
        os.Exit(1)
    }
    
    // Start metrics server
    if err := recorder.Start(ctx); err != nil {
        slog.Error("Failed to start metrics", "error", err)
        os.Exit(1)
    }
    
    slog.Info("Metrics server started", "address", recorder.ServerAddress())
    
    // Ensure graceful shutdown
    defer func() {
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
        defer cancel()
        
        if err := recorder.Shutdown(shutdownCtx); err != nil {
            slog.Error("Metrics shutdown error", "error", err)
        } else {
            slog.Info("Metrics shut down successfully")
        }
    }()

    // Create HTTP server
    mux := http.NewServeMux()
    mux.HandleFunc("/", homeHandler)
    mux.HandleFunc("/api/v1/users", usersHandler)
    mux.HandleFunc("/health", healthHandler)
    mux.HandleFunc("/ready", readyHandler)

    // Configure middleware
    handler := metrics.Middleware(recorder,
        metrics.WithExcludePaths("/health", "/ready", "/metrics"),
        metrics.WithExcludePrefixes("/debug/", "/_/"),
        metrics.WithHeaders("X-Request-ID", "X-Correlation-ID"),
    )(mux)

    server := &http.Server{
        Addr:              ":8080",
        Handler:           handler,
        ReadHeaderTimeout: 5 * time.Second,
        ReadTimeout:       10 * time.Second,
        WriteTimeout:      10 * time.Second,
        IdleTimeout:       60 * time.Second,
    }
    
    // Start HTTP server
    go func() {
        slog.Info("HTTP server starting", "address", server.Addr)
        if err := server.ListenAndServe(); err != http.ErrServerClosed {
            slog.Error("HTTP server error", "error", err)
            cancel()
        }
    }()
    
    // Wait for shutdown signal
    <-ctx.Done()
    slog.Info("Shutdown signal received")
    
    // Graceful shutdown
    shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer shutdownCancel()
    
    if err := server.Shutdown(shutdownCtx); err != nil {
        slog.Error("Server shutdown error", "error", err)
    } else {
        slog.Info("Server shut down successfully")
    }
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"status": "ok"}`))
}

func usersHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"users": []}`))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
}
```

## Next Steps

- Review [Basic Usage](../basic-usage/) for fundamentals
- Learn [Custom Metrics](../custom-metrics/) for business metrics
- Check [Configuration](../configuration/) for production settings
- See [Testing](../testing/) for testing strategies
