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

Sets the service name used in observability metadata. This includes metrics, traces, and logs. If empty, config validation fails at startup; the error message includes how to fix it (this option or `RIVAAS_SERVICE_NAME`).

**Default:** `"rivaas-app"`

### WithServiceVersion

```go
func WithServiceVersion(version string) Option
```

Sets the service version used in observability and API documentation. Must be non-empty or config validation fails at startup; the error message includes how to fix it (this option or `RIVAAS_SERVICE_VERSION`).

**Default:** `"1.0.0"`

### WithEnvironment

```go
func WithEnvironment(env string) Option
```

Sets the environment mode. Valid values: `"development"`, `"production"`. Invalid values cause config validation to fail at startup. When access log scope is not set via [WithAccessLogScope](observability-options/#withaccesslogscope), production defaults to errors-only and development to full access logs.

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

## Validation

### WithValidationEngine

```go
func WithValidationEngine(engine *validation.Engine) Option
```

Sets the validation engine used by [Context.Bind](/docs/reference/packages/app/context-api/#bind) and [Context.Validate](/docs/reference/packages/app/context-api/#validate). When set, the app uses this engine instead of the package-level [validation.DefaultEngine](https://pkg.go.dev/rivaas.dev/validation#DefaultEngine). Use for custom validation configuration (e.g. redaction, MaxErrors) or test isolation.

**Example:**

```go
engine := validation.MustNew(validation.WithRedactor(myRedactor))
a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithValidationEngine(engine),
)
```

### Validate options (Context.Validate)

When calling [Context.Validate](/docs/reference/packages/app/context-api/#validate) after `BindOnly()`, use these app-scoped options so your IDE shows them under `app.With...`:

Bind and Validate options must not be nil. Passing a nil option returns an error (e.g. `app: bind option at index N cannot be nil`).

#### WithValidatePartial

```go
func WithValidatePartial() ValidateOption
```

Enables partial validation for this validate call. Only fields present in the request are validated; "required" is ignored for absent fields. Use for PATCH-style flows after `BindOnly()`.

**Example:**

```go
if err := c.BindOnly(&req); err != nil { ... }
if err := c.Validate(&req, app.WithValidatePartial()); err != nil {
    c.Fail(err)
    return
}
```

#### WithValidateStrict

```go
func WithValidateStrict() ValidateOption
```

Disallows unknown fields for this validate call. Use when validating JSON-backed structs and you want to reject unknown keys.

#### WithValidateOptions

```go
func WithValidateOptions(opts ...validation.Option) ValidateOption
```

Passes options directly to the validation package for this validate call. Use for advanced validation (e.g. `validation.WithMaxErrors(5)`) while keeping the call site on app types.

**Example:**

```go
if err := c.Validate(&req,
    app.WithValidatePartial(),
    app.WithValidateOptions(validation.WithMaxErrors(5)),
); err != nil { ... }
```

Note: **WithValidationOptions** as a BindOption (used with `Bind`) applies to the validation step inside `Bind`; **WithValidateOptions** as a ValidateOption applies to `Context.Validate` only.

## OpenAPI

### WithOpenAPI

```go
func WithOpenAPI(opts ...openapi.Option) Option
```

Enables OpenAPI specification generation. Service name and version are automatically injected from app-level configuration.

## Error Formatting

### WithErrorFormatterFor

```go
func WithErrorFormatterFor(mediaType string, opts ...errors.Option) Option
```

Configures an error formatter from options. The app builds the formatter via `errors.New(opts...)`; invalid options are reported during config validation.

- Use **empty** `mediaType` (`""`) for a single formatter for all responses (no content negotiation).
- Use a **non-empty** `mediaType` (e.g. `"application/problem+json"`) to register a formatter for content negotiation; multiple calls accumulate. Use [WithDefaultErrorFormat](#withdefaulterrorformat) to set the fallback when no Accept header matches.

You cannot mix single and content-negotiated modes (config validation fails at startup).

Example — single formatter:

```go
app.WithErrorFormatterFor("", errors.WithRFC9457("https://api.example.com/problems"))
```

Example — content negotiation:

```go
app.WithErrorFormatterFor("application/problem+json", errors.WithRFC9457("https://api.example.com/problems")),
app.WithErrorFormatterFor("application/json", errors.WithSimple()),
app.WithDefaultErrorFormat("application/problem+json"),
```

### WithErrorFormatters

```go
func WithErrorFormatters(formatters map[string]errors.Formatter) Option
```

**Advanced:** Configures multiple error formatters with content negotiation by Accept header. Use when you need to pass pre-built or custom formatters. Prefer [WithErrorFormatterFor](#witherrorformatterfor) for option-based configuration.

### WithDefaultErrorFormat

```go
func WithDefaultErrorFormat(mediaType string) Option
```

Sets the default format when no Accept header matches. Only used when content-negotiated formatters are configured (via [WithErrorFormatterFor](#witherrorformatterfor) with non-empty media types or [WithErrorFormatters](#witherrorformatters)).

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
