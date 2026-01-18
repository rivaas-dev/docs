---
title: "Configuration"
linkTitle: "Configuration"
weight: 3
description: >
  Configure your application with service metadata, environment modes, and server settings.
---

## Service Configuration

### Service Name

Set the service name used in observability metadata (metrics, traces, logs):

```go
a, err := app.New(
    app.WithServiceName("orders-api"),
)
```

The service name must be non-empty or validation will fail. Default: `"rivaas-app"`.

### Service Version

Set the service version for observability and API documentation:

```go
a, err := app.New(
    app.WithServiceVersion("v1.2.3"),
)
```

The service version must be non-empty or validation will fail. Default: `"1.0.0"`.

### Complete Service Metadata

Configure both service name and version:

```go
a, err := app.New(
    app.WithServiceName("payments-api"),
    app.WithServiceVersion("v2.0.0"),
)
```

These values are automatically injected into:

- **Metrics** - Service name/version labels on all metrics
- **Tracing** - Service name/version attributes on all spans
- **Logging** - Service name/version fields in all log entries
- **OpenAPI** - API title and version in the specification

## Environment Modes

### Development Mode

Development mode enables verbose logging and developer-friendly features:

```go
a, err := app.New(
    app.WithEnvironment("development"),
)
```

**Development mode features:**

- Verbose access logging (all requests)
- Route table displayed in startup banner
- More detailed error messages
- Terminal colors enabled

### Production Mode

Production mode optimizes for performance and security:

```go
a, err := app.New(
    app.WithEnvironment("production"),
)
```

**Production mode features:**

- Error-only access logging (reduces log volume)
- Minimal startup banner
- Sanitized error messages
- Terminal colors stripped (for log aggregation)

### Environment from Environment Variables

Use environment variables for configuration:

```go
env := os.Getenv("ENVIRONMENT")
if env == "" {
    env = "development"
}

a, err := app.New(
    app.WithEnvironment(env),
)
```

**Valid values:** `"development"`, `"production"`. Invalid values cause validation to fail.

## Server Configuration

### Timeouts

Configure server timeouts for safety and performance:

```go
a, err := app.New(
    app.WithServer(
        app.WithReadTimeout(10 * time.Second),
        app.WithWriteTimeout(15 * time.Second),
        app.WithIdleTimeout(60 * time.Second),
        app.WithReadHeaderTimeout(2 * time.Second),
    ),
)
```

**Timeout descriptions:**

- **ReadTimeout** - Maximum time to read entire request (including body)
- **WriteTimeout** - Maximum time to write response
- **IdleTimeout** - Maximum time to wait for next request on keep-alive connection
- **ReadHeaderTimeout** - Maximum time to read request headers

**Default values:**

- ReadTimeout: `10s`
- WriteTimeout: `10s`
- IdleTimeout: `60s`
- ReadHeaderTimeout: `2s`

### Header Size Limits

Configure maximum request header size:

```go
a, err := app.New(
    app.WithServer(
        app.WithMaxHeaderBytes(2 << 20), // 2MB
    ),
)
```

Default: `1MB` (1048576 bytes). Must be at least `1KB` or validation fails.

### Shutdown Timeout

Configure graceful shutdown timeout:

```go
a, err := app.New(
    app.WithServer(
        app.WithShutdownTimeout(30 * time.Second),
    ),
)
```

Default: `30s`. Must be at least `1s` or validation fails.

The shutdown timeout controls how long the server waits for:

1. In-flight requests to complete
2. OnShutdown hooks to execute
3. Observability components to flush
4. Connections to close gracefully

### Validation Rules

Server configuration is automatically validated:

**Timeout validation:**

- All timeouts must be positive
- ReadTimeout should not exceed WriteTimeout (common misconfiguration)
- ShutdownTimeout must be at least 1 second

**Size validation:**

- MaxHeaderBytes must be at least 1KB (1024 bytes)

**Invalid configuration example:**

```go
a, err := app.New(
    app.WithServer(
        app.WithReadTimeout(15 * time.Second),
        app.WithWriteTimeout(10 * time.Second), // ❌ Invalid: read > write
        app.WithShutdownTimeout(100 * time.Millisecond), // ❌ Invalid: too short
        app.WithMaxHeaderBytes(512), // ❌ Invalid: too small
    ),
)
// err contains all validation errors
```

**Valid configuration example:**

```go
a, err := app.New(
    app.WithServer(
        app.WithReadTimeout(10 * time.Second),
        app.WithWriteTimeout(15 * time.Second), // ✅ Valid: write >= read
        app.WithShutdownTimeout(5 * time.Second), // ✅ Valid: >= 1s
        app.WithMaxHeaderBytes(2048), // ✅ Valid: >= 1KB
    ),
)
```

## Partial Configuration

You can set only the options you need - unset fields use defaults:

```go
// Only override read and write timeouts
a, err := app.New(
    app.WithServer(
        app.WithReadTimeout(15 * time.Second),
        app.WithWriteTimeout(15 * time.Second),
        // Other fields use defaults: IdleTimeout=60s, etc.
    ),
)
```

## Configuration from Environment

Load configuration from environment variables:

```go
package main

import (
    "log"
    "os"
    "strconv"
    "time"
    
    "rivaas.dev/app"
)

func main() {
    // Parse timeouts from environment
    readTimeout := parseDuration("READ_TIMEOUT", 10*time.Second)
    writeTimeout := parseDuration("WRITE_TIMEOUT", 10*time.Second)
    
    a, err := app.New(
        app.WithServiceName(getEnv("SERVICE_NAME", "my-api")),
        app.WithServiceVersion(getEnv("SERVICE_VERSION", "v1.0.0")),
        app.WithEnvironment(getEnv("ENVIRONMENT", "development")),
        app.WithServer(
            app.WithReadTimeout(readTimeout),
            app.WithWriteTimeout(writeTimeout),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // ...
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func parseDuration(key string, defaultValue time.Duration) time.Duration {
    if value := os.Getenv(key); value != "" {
        if d, err := time.ParseDuration(value); err == nil {
            return d
        }
    }
    return defaultValue
}
```

## Configuration Validation

All configuration is validated when calling `app.New()`:

```go
a, err := app.New(
    app.WithServiceName(""),  // ❌ Empty service name
    app.WithEnvironment("staging"),  // ❌ Invalid environment
)
if err != nil {
    // Handle validation errors
    log.Fatalf("Configuration error: %v", err)
}
```

Validation errors are structured and include all issues:

```
validation errors (2):
  1. configuration error in serviceName: must not be empty
  2. configuration error in environment: must be "development" or "production", got "staging"
```

## Complete Configuration Example

```go
package main

import (
    "log"
    "os"
    "time"
    
    "rivaas.dev/app"
)

func main() {
    a, err := app.New(
        // Service metadata
        app.WithServiceName("orders-api"),
        app.WithServiceVersion("v2.1.0"),
        app.WithEnvironment("production"),
        
        // Server configuration
        app.WithServer(
            app.WithReadTimeout(10 * time.Second),
            app.WithWriteTimeout(15 * time.Second),
            app.WithIdleTimeout(120 * time.Second),
            app.WithReadHeaderTimeout(3 * time.Second),
            app.WithMaxHeaderBytes(2 << 20), // 2MB
            app.WithShutdownTimeout(30 * time.Second),
        ),
    )
    if err != nil {
        log.Fatalf("Failed to create app: %v", err)
    }
    
    // Register routes...
    
    // Start server...
}
```

## Next Steps

- [Observability](../observability/) - Configure metrics, tracing, and logging
- [Server](../server/) - Learn about HTTP, HTTPS, and mTLS servers
- [Lifecycle](../lifecycle/) - Use lifecycle hooks for initialization and cleanup
