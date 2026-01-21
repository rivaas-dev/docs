---
title: "Examples"
description: "Complete real-world examples of using the logging package"
weight: 13
keywords:
  - logging examples
  - code samples
  - patterns
  - use cases
---

This guide provides complete, real-world examples of using the logging package in various scenarios.

## Basic Application

Simple application with structured logging.

```go
package main

import (
    "context"
    "os"
    "rivaas.dev/logging"
)

func main() {
    // Create logger
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithLevel(logging.LevelInfo),
        logging.WithServiceName("myapp"),
        logging.WithServiceVersion("v1.0.0"),
    )
    defer logger.Shutdown(context.Background())

    // Application logic
    logger.Info("application started",
        "port", 8080,
        "environment", os.Getenv("ENV"),
    )

    // Simulate work
    processData(logger)

    logger.Info("application stopped")
}

func processData(logger *logging.Logger) {
    logger.Info("processing data", "items", 100)
    // Process logic...
    logger.Info("data processing completed", "processed", 100)
}
```

## HTTP Server

HTTP server with request logging.

```go
package main

import (
    "context"
    "net/http"
    "time"
    "rivaas.dev/logging"
)

func main() {
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithServiceName("api-server"),
    )
    defer logger.Shutdown(context.Background())

    mux := http.NewServeMux()
    
    // Add logging middleware
    mux.HandleFunc("/", loggingMiddleware(logger, handleRoot))
    mux.HandleFunc("/api/users", loggingMiddleware(logger, handleUsers))

    logger.Info("server starting", "port", 8080)
    http.ListenAndServe(":8080", mux)
}

func loggingMiddleware(logger *logging.Logger, next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        // Wrap response writer to capture status
        wrapped := &responseWriter{ResponseWriter: w, statusCode: 200}
        
        next(wrapped, r)
        
        logger.LogRequest(r,
            "status", wrapped.statusCode,
            "duration_ms", time.Since(start).Milliseconds(),
        )
    }
}

type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (w *responseWriter) WriteHeader(code int) {
    w.statusCode = code
    w.ResponseWriter.WriteHeader(code)
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("Hello, World!"))
}

func handleUsers(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte(`{"users": []}`))
}
```

## Router Integration

Full router integration with tracing.

```go
package main

import (
    "context"
    "rivaas.dev/app"
    "rivaas.dev/logging"
    "rivaas.dev/tracing"
    "rivaas.dev/router/middleware/accesslog"
)

func main() {
    // Create app with full observability
    a, err := app.New(
        app.WithServiceName("user-api"),
        app.WithServiceVersion("v2.0.0"),
        app.WithObservability(
            app.WithLogging(
                logging.WithJSONHandler(),
                logging.WithLevel(logging.LevelInfo),
            ),
            app.WithTracing(
                tracing.WithOTLP("localhost:4317"),
            ),
        ),
    )
    if err != nil {
        panic(err)
    }
    defer a.Shutdown(context.Background())

    router := a.Router()
    logger := a.Logger()

    // Add access log middleware
    router.Use(accesslog.New(
        accesslog.WithExcludePaths("/health"),
    ))

    // Health endpoint
    router.GET("/health", func(c *router.Context) {
        c.JSON(200, map[string]string{"status": "healthy"})
    })

    // API endpoints
    api := router.Group("/api/v1")
    {
        api.GET("/users", getUsers(logger))
        api.POST("/users", createUser(logger))
    }

    logger.Info("server starting", "port", 8080)
    a.Run(":8080")
}

func getUsers(logger *logging.Logger) router.HandlerFunc {
    return func(c *router.Context) {
        log := c.Logger()
        log.Info("fetching users")
        
        users := fetchUsers()
        
        log.Info("users fetched", "count", len(users))
        c.JSON(200, users)
    }
}

func createUser(logger *logging.Logger) router.HandlerFunc {
    return func(c *router.Context) {
        log := c.Logger()
        
        var user User
        if err := c.BindJSON(&user); err != nil {
            log.Error("invalid request", "error", err)
            c.JSON(400, map[string]string{"error": "invalid request"})
            return
        }
        
        if err := saveUser(user); err != nil {
            log.Error("failed to save user", "error", err)
            c.JSON(500, map[string]string{"error": "internal error"})
            return
        }
        
        log.Info("user created", "user_id", user.ID)
        c.JSON(201, user)
    }
}
```

## Multiple Loggers

Different loggers for different purposes.

```go
package main

import (
    "context"
    "os"
    "rivaas.dev/logging"
)

type Application struct {
    appLogger   *logging.Logger
    debugLogger *logging.Logger
    auditLogger *logging.Logger
}

func NewApplication() *Application {
    // Application logger - JSON for production
    appLogger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithLevel(logging.LevelInfo),
        logging.WithServiceName("myapp"),
    )

    // Debug logger - Console with source info
    debugLogger := logging.MustNew(
        logging.WithConsoleHandler(),
        logging.WithDebugLevel(),
        logging.WithSource(true),
    )

    // Audit logger - Separate file for compliance
    auditFile, _ := os.OpenFile("audit.log",
        os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
    auditLogger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithOutput(auditFile),
        logging.WithServiceName("myapp-audit"),
    )

    return &Application{
        appLogger:   appLogger,
        debugLogger: debugLogger,
        auditLogger: auditLogger,
    }
}

func (a *Application) Run() {
    defer a.appLogger.Shutdown(context.Background())
    defer a.debugLogger.Shutdown(context.Background())
    defer a.auditLogger.Shutdown(context.Background())

    // Normal application log
    a.appLogger.Info("application started")

    // Debug information
    a.debugLogger.Debug("initialization complete",
        "config_loaded", true,
        "db_connected", true,
    )

    // Audit event
    a.auditLogger.Info("user action",
        "user_id", "123",
        "action", "login",
        "success", true,
    )
}

func main() {
    app := NewApplication()
    app.Run()
}
```

## Environment-Based Configuration

Configure logging based on environment.

```go
package main

import (
    "os"
    "rivaas.dev/logging"
)

func createLogger() *logging.Logger {
    env := os.Getenv("ENV")
    
    var opts []logging.Option
    
    switch env {
    case "development":
        opts = []logging.Option{
            logging.WithConsoleHandler(),
            logging.WithDebugLevel(),
            logging.WithSource(true),
        }
    case "staging":
        opts = []logging.Option{
            logging.WithJSONHandler(),
            logging.WithLevel(logging.LevelInfo),
            logging.WithServiceName(os.Getenv("SERVICE_NAME")),
            logging.WithEnvironment("staging"),
        }
    case "production":
        opts = []logging.Option{
            logging.WithJSONHandler(),
            logging.WithLevel(logging.LevelWarn),
            logging.WithServiceName(os.Getenv("SERVICE_NAME")),
            logging.WithServiceVersion(os.Getenv("VERSION")),
            logging.WithEnvironment("production"),
            logging.WithSampling(logging.SamplingConfig{
                Initial:    1000,
                Thereafter: 100,
                Tick:       time.Minute,
            }),
        }
    default:
        opts = []logging.Option{
            logging.WithJSONHandler(),
            logging.WithLevel(logging.LevelInfo),
        }
    }
    
    return logging.MustNew(opts...)
}

func main() {
    logger := createLogger()
    defer logger.Shutdown(context.Background())
    
    logger.Info("application started", "environment", os.Getenv("ENV"))
}
```

## Worker Pool with Per-Worker Logging

Logging in concurrent workers.

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"
    "rivaas.dev/logging"
)

type Worker struct {
    id     int
    logger *logging.Logger
}

func NewWorker(id int, baseLogger *logging.Logger) *Worker {
    // Create worker-specific logger
    workerLogger := baseLogger.With("worker_id", id)
    
    return &Worker{
        id:     id,
        logger: baseLogger,
    }
}

func (w *Worker) Process(job Job) {
    start := time.Now()
    
    w.logger.Info("job started",
        "worker_id", w.id,
        "job_id", job.ID,
    )
    
    // Process job
    time.Sleep(100 * time.Millisecond)
    
    w.logger.LogDuration("job completed", start,
        "worker_id", w.id,
        "job_id", job.ID,
    )
}

type Job struct {
    ID int
}

func main() {
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithServiceName("worker-pool"),
    )
    defer logger.Shutdown(context.Background())

    // Create worker pool
    numWorkers := 4
    jobs := make(chan Job, 100)
    var wg sync.WaitGroup

    // Start workers
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        worker := NewWorker(i, logger)
        
        go func() {
            defer wg.Done()
            for job := range jobs {
                worker.Process(job)
            }
        }()
    }

    // Send jobs
    for i := 0; i < 10; i++ {
        jobs <- Job{ID: i}
    }
    close(jobs)

    wg.Wait()
    logger.Info("all jobs completed")
}
```

## Error Handling with Context

Comprehensive error logging.

```go
package main

import (
    "context"
    "errors"
    "time"
    "rivaas.dev/logging"
)

type Service struct {
    logger *logging.Logger
}

func NewService(logger *logging.Logger) *Service {
    return &Service{logger: logger}
}

func (s *Service) ProcessPayment(ctx context.Context, payment Payment) error {
    log := s.logger.With(
        "payment_id", payment.ID,
        "amount", payment.Amount,
    )

    log.Info("processing payment")

    // Validation
    if err := s.validatePayment(payment); err != nil {
        log.LogError(err, "payment validation failed",
            "step", "validation",
        )
        return err
    }

    // Process with retry
    var lastErr error
    for retry := 0; retry < 3; retry++ {
        if err := s.chargePayment(payment); err != nil {
            lastErr = err
            log.LogError(err, "payment charge failed",
                "retry", retry,
                "max_retries", 3,
            )
            time.Sleep(time.Second * time.Duration(retry+1))
            continue
        }
        
        log.Info("payment processed successfully")
        return nil
    }

    // Critical failure - log with stack trace
    s.logger.ErrorWithStack("payment processing failed after retries",
        lastErr, true,
        "payment_id", payment.ID,
        "retries", 3,
    )
    
    return lastErr
}

func (s *Service) validatePayment(payment Payment) error {
    if payment.Amount <= 0 {
        return errors.New("invalid amount")
    }
    return nil
}

func (s *Service) chargePayment(payment Payment) error {
    // Simulate charging
    return nil
}

type Payment struct {
    ID     string
    Amount float64
}
```

## Testing Example

Complete testing setup.

```go
package myservice_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "rivaas.dev/logging"
)

func TestUserService(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    svc := NewUserService(th.Logger)
    
    t.Run("create user", func(t *testing.T) {
        th.Reset()
        
        user, err := svc.CreateUser("alice", "alice@example.com")
        require.NoError(t, err)
        require.NotNil(t, user)
        
        // Verify logging
        th.AssertLog(t, "INFO", "user created", map[string]any{
            "username": "alice",
            "email":    "alice@example.com",
        })
    })
    
    t.Run("duplicate user", func(t *testing.T) {
        th.Reset()
        
        _, err := svc.CreateUser("alice", "alice@example.com")
        require.Error(t, err)
        
        // Verify error logging
        assert.True(t, th.ContainsLog("user creation failed"))
        assert.True(t, th.ContainsAttr("error", "user already exists"))
    })
}
```

## Next Steps

- Review [Best Practices](../best-practices/) for production patterns
- See [Testing](../testing/) for test utilities
- Explore the [API Reference](/reference/packages/logging/api-reference/)

For more examples, check the [examples directory on GitHub](https://github.com/rivaas-dev/rivaas/tree/main/logging/examples/).
