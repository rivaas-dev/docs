---
title: "Configuration Options"
linkTitle: "Options"
keywords:
  - app options
  - configuration
  - options reference
  - functional options
weight: 2
description: >
  App-level configuration options reference.
---

## Service Configuration

### WithServiceName

```go
func WithServiceName(name string) Option
```

Sets the service name used in observability metadata. This includes metrics, traces, and logs. If empty, validation fails.

**Default:** `"rivaas-app"`

### WithServiceVersion

```go
func WithServiceVersion(version string) Option
```

Sets the service version used in observability and API documentation. Must be non-empty or validation fails.

**Default:** `"1.0.0"`

### WithEnvironment

```go
func WithEnvironment(env string) Option
```

Sets the environment mode. Valid values: `"development"`, `"production"`. Invalid values cause validation to fail. When access log scope is not set via [WithAccessLogScope](observability-options/#withaccesslogscope), production defaults to errors-only and development to full access logs.

**Default:** `"development"`

## Server Configuration

### WithPort

```go
func WithPort(port int) Option
```

Sets the server listen port. Default is **8080** for HTTP; when using WithTLS or WithMTLS the default is **8443**. Override with `WithPort(n)` in all cases. Can be overridden by `RIVAAS_PORT` when [WithEnv](#withenv) is used.

### WithServer

```go
func WithServer(opts ...ServerOption) Option
```

Configures server settings. See [Server Options](server-options/) for sub-options.

## Server Transport

At most one of `WithTLS` or `WithMTLS` may be used. Configure transport at construction; [Start](api-reference/#server-management) then runs the server. Default listen port for TLS/mTLS is **8443** unless overridden by `WithPort` or `RIVAAS_PORT`.

### WithTLS

```go
func WithTLS(certFile, keyFile string) Option
```

Configures the server to serve HTTPS using the given certificate and key files. Both `certFile` and `keyFile` must be non-empty. Default port is 8443 unless overridden. See [Server guide](/docs/guides/app/server/) for examples.

### WithMTLS

```go
func WithMTLS(serverCert tls.Certificate, opts ...MTLSOption) Option
```

Configures the server to serve HTTPS with mutual TLS (mTLS). Requires a server certificate and typically `WithClientCAs` for client verification. Default port is 8443 unless overridden. See [Server guide](/docs/guides/app/server/) for mTLS options and examples.

## Observability

### WithObservability

```go
func WithObservability(opts ...ObservabilityOption) Option
```

Configures all observability components (metrics, tracing, logging). See [Observability Options](observability-options/) for sub-options.

## Endpoints

### WithHealthEndpoints

```go
func WithHealthEndpoints(opts ...HealthOption) Option
```

Enables health endpoints. See [Health Options](health-options/) for sub-options.

### WithDebugEndpoints

```go
func WithDebugEndpoints(opts ...DebugOption) Option
```

Enables debug endpoints. See [Debug Options](debug-options/) for sub-options.

## Middleware

### WithMiddleware

```go
func WithMiddleware(middlewares ...HandlerFunc) Option
```

Adds middleware during app initialization. Multiple calls accumulate.

### WithoutDefaultMiddleware

```go
func WithoutDefaultMiddleware() Option
```

Disables default middleware (recovery). Use when you want full control over middleware.

## Router

### WithRouter

```go
func WithRouter(opts ...router.Option) Option
```

Passes router options to the underlying router. Multiple calls accumulate.

## OpenAPI

### WithOpenAPI

```go
func WithOpenAPI(opts ...openapi.Option) Option
```

Enables OpenAPI specification generation. Service name and version are automatically injected from app-level configuration.

## Error Formatting

### WithErrorFormatter

```go
func WithErrorFormatter(opts ...errors.Option) Option
```

Configures a single error formatter from options. The app builds the formatter via `errors.New(opts...)`; invalid options are reported during config validation. Aligns with `WithRouter` and `WithOpenAPI` (accept options, app performs construction). Example: `app.WithErrorFormatter(errors.WithRFC9457("https://api.example.com/problems"))`.

### WithErrorFormatters

```go
func WithErrorFormatters(formatters map[string]errors.Formatter) Option
```

Configures multiple error formatters with content negotiation based on Accept header.

### WithDefaultErrorFormat

```go
func WithDefaultErrorFormat(mediaType string) Option
```

Sets the default format when no Accept header matches. Only used with `WithErrorFormatters`.

## Complete Example

```go
a, err := app.New(
    // Service
    app.WithServiceName("orders-api"),
    app.WithServiceVersion("v2.0.0"),
    app.WithEnvironment("production"),
    
    // Server
    app.WithServer(
        app.WithReadTimeout(10 * time.Second),
        app.WithWriteTimeout(15 * time.Second),
        app.WithShutdownTimeout(30 * time.Second),
    ),
    
    // Observability
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
        app.WithMetrics(),
        app.WithTracing(tracing.WithOTLP("localhost:4317")),
    ),
    
    // Health endpoints
    app.WithHealthEndpoints(
        app.WithReadinessCheck("database", dbCheck),
    ),
    
    // OpenAPI
    app.WithOpenAPI(
        openapi.WithSwaggerUI(true, "/docs"),
    ),
)
```

## Next Steps

- [Server Options](server-options/) - Server configuration reference
- [Observability Options](observability-options/) - Observability configuration reference
- [API Reference](api-reference/) - Core types and methods
