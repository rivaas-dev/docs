---
title: "Environment Variables"
linkTitle: "Environment Variables"
weight: 5
keywords:
  - environment variables
  - app configuration
  - 12-factor
  - docker
  - containers
description: >
  Configure your app using environment variables for easier deployment.
---

## Overview

Want to configure your app without changing code? Use environment variables. This is helpful when you deploy to containers or cloud platforms.

The app package supports environment variables through the `WithEnv()` option. Just add it to your app setup, and you can control settings like port, logging, metrics, and tracing using environment variables.

This follows the [12-factor app](https://12factor.net/config) approach, which means your code stays the same across different environments. You just change the environment variables.

## Quick Start

Here's a simple example. First, set some environment variables:

```bash
export RIVAAS_PORT=3000
export RIVAAS_LOG_LEVEL=debug
export RIVAAS_METRICS_EXPORTER=prometheus
```

Then create your app with `WithEnv()`:

```go
app, err := app.New(
    app.WithServiceName("my-api"),
    app.WithEnv(), // This reads environment variables
)
if err != nil {
    log.Fatal(err)
}

// Your app now runs on port 3000 with debug logging and Prometheus metrics
```

That's it! No need to set these in code anymore.

## Environment Variables Reference

All environment variables start with the `RIVAAS_` prefix. You can also use a custom prefix with `WithEnvPrefix()`.

### Server Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RIVAAS_PORT` | Port number to listen on | `8080` | `3000` |
| `RIVAAS_HOST` | Host address to bind to | `0.0.0.0` | `127.0.0.1` |

### Logging Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RIVAAS_LOG_LEVEL` | Log level to use | `info` | `debug`, `info`, `warn`, `error` |
| `RIVAAS_LOG_FORMAT` | Log output format | `json` | `json`, `text`, `console` |

### Metrics Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RIVAAS_METRICS_EXPORTER` | Type of metrics exporter | - | `prometheus`, `otlp`, `stdout` |
| `RIVAAS_METRICS_ADDR` | Prometheus server address | `:9090` | `:9000`, `0.0.0.0:9090` |
| `RIVAAS_METRICS_PATH` | Prometheus metrics path | `/metrics` | `/custom-metrics` |
| `RIVAAS_METRICS_ENDPOINT` | OTLP endpoint for metrics | - | `http://localhost:4318` |

### Tracing Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RIVAAS_TRACING_EXPORTER` | Type of tracing exporter | - | `otlp`, `otlp-http`, `stdout` |
| `RIVAAS_TRACING_ENDPOINT` | OTLP endpoint for traces | - | `localhost:4317` |

### Debug Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RIVAAS_PPROF_ENABLED` | Enable pprof endpoints | `false` | `true`, `false` |

## Metrics Configuration

You can set up metrics using just environment variables. No need to write code for it.

### Prometheus (Default)

The simplest way to get metrics:

```bash
export RIVAAS_METRICS_EXPORTER=prometheus
```

This starts a Prometheus server on `:9090/metrics`. Your app will expose metrics there.

### Custom Prometheus Settings

Want to use a different port or path?

```bash
export RIVAAS_METRICS_EXPORTER=prometheus
export RIVAAS_METRICS_ADDR=:9000
export RIVAAS_METRICS_PATH=/custom-metrics
```

Now your metrics are at `http://localhost:9000/custom-metrics`.

### OTLP Metrics

Need to send metrics to an OTLP collector (like Grafana, Datadog, or Prometheus)?

```bash
export RIVAAS_METRICS_EXPORTER=otlp
export RIVAAS_METRICS_ENDPOINT=http://localhost:4318
```

Make sure to set the endpoint. The app will fail to start if you forget it.

### Stdout Metrics (Development)

For local development, you can print metrics to stdout:

```bash
export RIVAAS_METRICS_EXPORTER=stdout
```

This shows all metrics in your terminal. Good for debugging.

## Tracing Configuration

Set up distributed tracing using environment variables.

### OTLP Tracing (gRPC)

This is the most common way to send traces:

```bash
export RIVAAS_TRACING_EXPORTER=otlp
export RIVAAS_TRACING_ENDPOINT=localhost:4317
```

This works with Jaeger, Tempo, and other tracing backends that support OTLP over gRPC.

### OTLP Tracing (HTTP)

Prefer HTTP instead of gRPC?

```bash
export RIVAAS_TRACING_EXPORTER=otlp-http
export RIVAAS_TRACING_ENDPOINT=http://localhost:4318
```

This is useful when your tracing backend only supports HTTP.

### Stdout Tracing (Development)

For local development, print traces to your terminal:

```bash
export RIVAAS_TRACING_EXPORTER=stdout
```

You'll see all traces in your console. Great for testing.

## Logging Configuration

Control how your app logs messages.

### Log Level

Set the minimum log level:

```bash
export RIVAAS_LOG_LEVEL=debug  # Show everything
export RIVAAS_LOG_LEVEL=info   # Normal logging (default)
export RIVAAS_LOG_LEVEL=warn   # Only warnings and errors
export RIVAAS_LOG_LEVEL=error  # Only errors
```

### Log Format

Choose how logs look:

```bash
export RIVAAS_LOG_FORMAT=json     # JSON format (good for production)
export RIVAAS_LOG_FORMAT=text     # Simple text format
export RIVAAS_LOG_FORMAT=console  # Colored output (good for development)
```

## Common Patterns

Here are some typical setups for different environments.

### Development Setup

For local development, you want to see everything:

```bash
export RIVAAS_PORT=3000
export RIVAAS_LOG_LEVEL=debug
export RIVAAS_LOG_FORMAT=console
export RIVAAS_METRICS_EXPORTER=stdout
export RIVAAS_TRACING_EXPORTER=stdout
```

This gives you:
- Port 3000 (so you can run multiple apps)
- Debug logging with colors
- Metrics and traces in your terminal

### Production Setup

For production, you want structured logs and proper observability:

```bash
export RIVAAS_PORT=8080
export RIVAAS_LOG_LEVEL=info
export RIVAAS_LOG_FORMAT=json
export RIVAAS_METRICS_EXPORTER=prometheus
export RIVAAS_TRACING_EXPORTER=otlp
export RIVAAS_TRACING_ENDPOINT=jaeger:4317
```

This gives you:
- Standard port 8080
- JSON logs (easy to parse)
- Prometheus metrics on `:9090`
- Traces sent to Jaeger

### Docker Setup

For Docker containers, you often need to bind to all addresses:

```bash
export RIVAAS_HOST=0.0.0.0
export RIVAAS_PORT=8080
export RIVAAS_METRICS_EXPORTER=prometheus
export RIVAAS_METRICS_ADDR=0.0.0.0:9090
```

This makes sure your app is reachable from outside the container.

## Custom Prefix

Don't like the `RIVAAS_` prefix? You can change it:

```go
app, err := app.New(
    app.WithServiceName("my-api"),
    app.WithEnvPrefix("MYAPP_"), // Use MYAPP_ instead of RIVAAS_
)
```

Now you can use variables like:
```bash
export MYAPP_PORT=3000
export MYAPP_LOG_LEVEL=debug
```

## Environment Variables Override Code

Environment variables always win. If you set something in code and in an environment variable, the environment variable is used.

```go
app, err := app.New(
    app.WithPort(8080), // Set port in code
    app.WithEnv(),      // But environment variable overrides it
)
```

If you set `RIVAAS_PORT=3000`, your app uses port 3000, not 8080.

This is by design. It follows the 12-factor app principle where configuration comes from the environment.

## Error Messages

The app checks your environment variables at startup. If something is wrong, it tells you clearly.

### Missing Required Endpoint

If you set an OTLP exporter but forget the endpoint:

```bash
export RIVAAS_METRICS_EXPORTER=otlp
# Forgot to set RIVAAS_METRICS_ENDPOINT
```

You get this error:
```
RIVAAS_METRICS_EXPORTER=otlp requires RIVAAS_METRICS_ENDPOINT to be set
```

The app won't start. This is good! It prevents wrong configurations in production.

### Invalid Exporter Type

If you use a wrong exporter name:

```bash
export RIVAAS_METRICS_EXPORTER=datadog  # Not supported
```

You get:
```
RIVAAS_METRICS_EXPORTER must be one of: prometheus, otlp, stdout (got: datadog)
```

### Invalid Port

If you set a bad port number:

```bash
export RIVAAS_PORT=99999  # Too high
```

You get:
```
invalid port: must be between 1 and 65535
```

These clear error messages help you fix problems quickly.

## Complete Example

Here's a full example showing everything together:

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    
    "rivaas.dev/app"
)

func main() {
    // Create app with environment variable support
    a, err := app.New(
        app.WithServiceName("orders-api"),
        app.WithServiceVersion("v1.0.0"),
        app.WithEnv(), // Read RIVAAS_* environment variables
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Register routes
    a.GET("/orders/:id", func(c *app.Context) {
        c.JSON(200, map[string]string{
            "order_id": c.Param("id"),
        })
    })
    
    // Start server
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()
    
    if err := a.Start(ctx); err != nil {
        log.Fatal(err)
    }
}
```

Now you can configure this app without changing the code:

```bash
# Development
export RIVAAS_PORT=3000
export RIVAAS_LOG_LEVEL=debug
export RIVAAS_LOG_FORMAT=console

# Production
export RIVAAS_PORT=8080
export RIVAAS_LOG_LEVEL=info
export RIVAAS_LOG_FORMAT=json
export RIVAAS_METRICS_EXPORTER=prometheus
export RIVAAS_TRACING_EXPORTER=otlp
export RIVAAS_TRACING_ENDPOINT=jaeger:4317
```

## Next Steps

- Learn more about [Observability](../observability/) with metrics and tracing
- Check out [Server Configuration](../server/) for more server settings
- See [Health Endpoints](../health-endpoints/) to add health checks
