---
title: "API Reference"
description: "Complete API documentation for the Tracer type and all methods"
keywords:
  - tracing api
  - tracing reference
  - api documentation
  - type reference
weight: 1
---

Complete API reference for the `Tracer` type and all tracing methods.

## Tracer Type

```go
type Tracer struct {
    // contains filtered or unexported fields
}
```

The main entry point for distributed tracing. Holds OpenTelemetry tracing configuration and runtime state. All operations on `Tracer` are thread-safe.

### Important Notes

- **Immutable**: Tracer is immutable after creation via `New()`. All configuration must be done through functional options.
- **Thread-safe**: All methods are safe for concurrent use.
- **Global state**: By default, does NOT set the global OpenTelemetry tracer provider. Use `WithGlobalTracerProvider()` option if needed.

## Constructor Functions

### New

```go
func New(opts ...Option) (*Tracer, error)
```

Creates a new Tracer with the given options. Returns an error if the tracing provider fails to initialize. When using OTLP options (`WithOTLP`, `WithOTLPHTTP`), you must call `Start(ctx)` before traces are exported; otherwise no traces are exported and no error is returned—only a one-time log warning when the first span is created.

**Default configuration:**
- Service name: `"rivaas-service"`.
- Service version: `"1.0.0"`.
- Sample rate: `1.0` (100%).
- Provider: `NoopProvider`.

**Example:**

```go
tracer, err := tracing.New(
    tracing.WithServiceName("my-api"),
    tracing.WithOTLP("localhost:4317"),
    tracing.WithSampleRate(0.1),
)
if err != nil {
    log.Fatal(err)
}
defer tracer.Shutdown(context.Background())
```

### MustNew

```go
func MustNew(opts ...Option) *Tracer
```

Creates a new Tracer with the given options. Panics **with an error** if the tracing provider fails to initialize. Callers that recover from the panic get an error they can unwrap with `errors.As` / `errors.Is`; the error message describes the failure. Use this when you want to panic on initialization errors.

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithServiceName("my-api"),
    tracing.WithStdout(),
)
defer tracer.Shutdown(context.Background())
```

## Middleware constructors

### Middleware

```go
func Middleware(tracer *Tracer, opts ...MiddlewareOption) (func(http.Handler) http.Handler, error)
```

Creates HTTP middleware for standalone request tracing. Returns the middleware function and an error if the tracer is nil or any option is invalid (e.g. nil option, invalid regex in path exclusion). Use for config-driven setup or when you need to handle errors.

**Example:**

```go
handler, err := tracing.Middleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics"),
    tracing.WithHeaders("X-Request-ID"),
)
if err != nil {
    log.Fatal(err)
}
http.ListenAndServe(":8080", handler(mux))
```

### MustMiddleware

```go
func MustMiddleware(tracer *Tracer, opts ...MiddlewareOption) func(http.Handler) http.Handler
```

Same as Middleware but panics **with an error** on failure. Callers that recover from the panic get an error they can unwrap with `errors.As` / `errors.Is`. Use when invalid options are a programming error.

**Example:**

```go
handler := tracing.MustMiddleware(tracer,
    tracing.WithExcludePaths("/health", "/metrics"),
)(mux)
http.ListenAndServe(":8080", handler)
```

## Lifecycle Methods

### Start

```go
func (t *Tracer) Start(ctx context.Context) error
```

Initializes OTLP providers that require network connections. When using OTLP, you must call `Start(ctx)` before traces are exported; forgetting it results in no traces and no error at `New`, and a one-time log warning when the first span is created. The context is used for the OTLP connection establishment. This method is idempotent; calling it multiple times is safe.

**Required for:** OTLP (gRPC and HTTP) providers  
**Optional for:** Noop and Stdout providers (they initialize immediately in `New()`)

**Example:**

```go
tracer := tracing.MustNew(
    tracing.WithOTLP("localhost:4317"),
)

if err := tracer.Start(context.Background()); err != nil {
    log.Fatal(err)
}
```

### RequiresStart

```go
func (t *Tracer) RequiresStart() bool
```

Returns true if the tracer uses an OTLP provider and therefore requires `Start(ctx)` to be called before traces are exported. Use in tests or wiring code to assert that Start must be called.

**Example:**

```go
if tracer.RequiresStart() && !tracer.IsStarted() {
    log.Fatal("OTLP tracer must be started before use")
}
```

### IsStarted

```go
func (t *Tracer) IsStarted() bool
```

Returns true after `Start()` has been called. Use in tests or wiring code to assert that the tracer was started when required (e.g. when `RequiresStart()` is true).

**Example:**

```go
tracer, _ := tracing.New(tracing.WithOTLP("localhost:4317"))
require.True(t, tracer.RequiresStart())
require.False(t, tracer.IsStarted())
require.NoError(t, tracer.Start(ctx))
require.True(t, tracer.IsStarted())
```

### Shutdown

```go
func (t *Tracer) Shutdown(ctx context.Context) error
```

Gracefully shuts down the tracing system, flushing any pending spans. This should be called before the application exits to ensure all spans are exported. This method is idempotent - calling it multiple times is safe and will only perform shutdown once.

**Example:**

```go
defer func() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    if err := tracer.Shutdown(ctx); err != nil {
        log.Printf("Error shutting down tracer: %v", err)
    }
}()
```

## Span Management Methods

### StartSpan

```go
func (t *Tracer) StartSpan(ctx context.Context, name string, opts ...trace.SpanStartOption) (context.Context, trace.Span)
```

Starts a new span with the given name and options. Returns a new context with the span attached and the span itself.

If tracing is disabled, returns the original context and a non-recording span. The returned span should always be ended, even if tracing is disabled.

**Parameters:**
- `ctx`: Parent context
- `name`: Span name (should be descriptive)
- `opts`: Optional OpenTelemetry span start options

**Returns:**
- New context with span attached
- The created span

**Example:**

```go
ctx, span := tracer.StartSpan(ctx, "database-query")
defer tracer.FinishSpan(span)

tracer.SetSpanAttribute(span, "db.query", "SELECT * FROM users")
```

### FinishSpan

```go
func (t *Tracer) FinishSpan(span trace.Span)
```

Ends the span with status Ok. Use for child spans that complete successfully and have no HTTP status. Safe to call multiple times; subsequent calls are no-ops.

**Example:**

```go
defer tracer.FinishSpan(span)
```

### FinishSpanWithHTTPStatus

```go
func (t *Tracer) FinishSpanWithHTTPStatus(span trace.Span, statusCode int)
```

Ends the span and sets status from the HTTP status code: 2xx-3xx → Ok, 4xx-5xx → Error. Use for request-level spans or when you have an HTTP status. Safe to call multiple times.

**Example:**

```go
defer tracer.FinishSpanWithHTTPStatus(span, rw.Status())
```

### FinishSpanWithError

```go
func (t *Tracer) FinishSpanWithError(span trace.Span, err error)
```

Marks the span as failed with the given error, sets standard error attributes (`exception.type`, `exception.message`, `error`), and ends the span. Status description is `err.Error()`. Safe to call multiple times.

**Example:**

```go
if err != nil {
    tracer.FinishSpanWithError(span, err)
    return err
}
tracer.FinishSpan(span)
```

### RecordError

```go
func (t *Tracer) RecordError(span trace.Span, err error)
```

Records an error on the span without ending it. Sets exception attributes and span status to Error. Use when an error occurs mid-span and you want to record it but continue (e.g. retry). Call `FinishSpan` or `FinishSpanWithError` when the span ends.

**Example:**

```go
if err := step(); err != nil {
    tracer.RecordError(span, err)
}
defer tracer.FinishSpan(span)
```

### WithSpan

```go
func (t *Tracer) WithSpan(ctx context.Context, name string, fn func(context.Context) error) error
```

Runs `fn` under a new span with the given name. The span is finished with success (`FinishSpan`) if `fn` returns nil, or with error (`FinishSpanWithError`) if `fn` returns a non-nil error. Returns the error from `fn`.

**Example:**

```go
err := tracer.WithSpan(ctx, "process-order", func(ctx context.Context) error {
    return processOrder(ctx, id)
})
```

### SetSpanAttribute

```go
func (t *Tracer) SetSpanAttribute(span trace.Span, key string, value any)
```

Adds an attribute to the span with type-safe handling.

**Supported types:**
- `string`, `int`, `int64`, `float64`, `bool`: native OpenTelemetry handling
- Other types: converted to string using `fmt.Sprintf`

This is a no-op if tracing is disabled, span is nil, or span is not recording.

**Parameters:**
- `span`: The span to add the attribute to
- `key`: Attribute key
- `value`: Attribute value

**Example:**

```go
tracer.SetSpanAttribute(span, "user.id", 12345)
tracer.SetSpanAttribute(span, "user.premium", true)
tracer.SetSpanAttribute(span, "user.name", "Alice")
```

### AddSpanEvent

```go
func (t *Tracer) AddSpanEvent(span trace.Span, name string, attrs ...attribute.KeyValue)
```

Adds an event to the span with optional attributes. Events represent important moments in a span's lifetime.

This is a no-op if tracing is disabled, span is nil, or span is not recording.

**Parameters:**
- `span`: The span to add the event to
- `name`: Event name
- `attrs`: Optional event attributes

**Example:**

```go
import "go.opentelemetry.io/otel/attribute"

tracer.AddSpanEvent(span, "cache_hit",
    attribute.String("key", "user:123"),
    attribute.Int("ttl_seconds", 300),
)
```

## Context Propagation Methods

### ExtractTraceContext

```go
func (t *Tracer) ExtractTraceContext(ctx context.Context, headers http.Header) context.Context
```

Extracts trace context from HTTP request headers. Returns a new context with the extracted trace information.

If no trace context is found in headers, returns the original context. Uses W3C Trace Context format by default.

**Parameters:**
- `ctx`: Base context
- `headers`: HTTP headers to extract from

**Returns:**
- Context with extracted trace information

**Example:**

```go
ctx := tracer.ExtractTraceContext(r.Context(), r.Header)
ctx, span := tracer.StartSpan(ctx, "operation")
defer tracer.FinishSpan(span)
```

### InjectTraceContext

```go
func (t *Tracer) InjectTraceContext(ctx context.Context, headers http.Header)
```

Injects trace context into HTTP headers. This allows trace context to propagate across service boundaries.

Uses W3C Trace Context format by default. This is a no-op if tracing is disabled.

**Parameters:**
- `ctx`: Context containing trace information
- `headers`: HTTP headers to inject into

**Example:**

```go
req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
tracer.InjectTraceContext(ctx, req.Header)
resp, _ := http.DefaultClient.Do(req)
```

## Request Span Methods

These methods are used internally by the middleware but can also be used for custom HTTP handling.

### StartRequestSpan

```go
func (t *Tracer) StartRequestSpan(ctx context.Context, req *http.Request, path string, isStatic bool) (context.Context, trace.Span)
```

Starts a span for an HTTP request. This is used by the middleware to create request spans with standard attributes.

**Parameters:**
- `ctx`: Request context
- `req`: HTTP request
- `path`: Request path
- `isStatic`: Whether this is a static route

**Returns:**
- Context with span
- The created span

### FinishRequestSpan

```go
func (t *Tracer) FinishRequestSpan(span trace.Span, statusCode int)
```

Completes the span for an HTTP request. Sets the HTTP status code attribute and invokes the span finish hook if configured.

**Parameters:**
- `span`: The span to finish
- `statusCode`: HTTP response status code

## Accessor Methods

### IsEnabled

```go
func (t *Tracer) IsEnabled() bool
```

Returns true if tracing is enabled.

### ServiceName

```go
func (t *Tracer) ServiceName() string
```

Returns the service name.

### ServiceVersion

```go
func (t *Tracer) ServiceVersion() string
```

Returns the service version.

### GetTracer

```go
func (t *Tracer) GetTracer() trace.Tracer
```

Returns the OpenTelemetry tracer.

### GetPropagator

```go
func (t *Tracer) GetPropagator() propagation.TextMapPropagator
```

Returns the OpenTelemetry propagator.

### GetProvider

```go
func (t *Tracer) GetProvider() Provider
```

Returns the current tracing provider.

## Context Helper Functions

These are package-level functions for working with spans through context.

### CopyTraceContext

```go
func CopyTraceContext(ctx context.Context) context.Context
```

Returns a new context that carries the current trace (span context) from `ctx` but has no active span. Use when starting goroutines or background work so new spans created in that context are linked to the same trace. If `ctx` has no valid span context, returns `context.Background()`.

**Example:**

```go
traceCtx := tracing.CopyTraceContext(r.Context())
go func() {
    _, span := tracer.StartSpan(traceCtx, "async-job")
    defer tracer.FinishSpan(span)
    doAsyncWork(ctx)
}()
```

### RecordErrorFromContext

```go
func RecordErrorFromContext(ctx context.Context, err error)
```

Records an error on the current span in `ctx` without ending it. Sets exception attributes and span status to Error. No-op if `ctx` has no recording span or `err` is nil.

**Example:**

```go
if err := step(); err != nil {
    tracing.RecordErrorFromContext(ctx, err)
}
```

### TraceID

```go
func TraceID(ctx context.Context) string
```

Returns the current trace ID from the active span in the context. Returns an empty string if no active span or span context is invalid.

**Example:**

```go
traceID := tracing.TraceID(ctx)
log.Printf("Processing request [trace=%s]", traceID)
```

### SpanID

```go
func SpanID(ctx context.Context) string
```

Returns the current span ID from the active span in the context. Returns an empty string if no active span or span context is invalid.

**Example:**

```go
spanID := tracing.SpanID(ctx)
log.Printf("Processing request [span=%s]", spanID)
```

### SetSpanAttributeFromContext

```go
func SetSpanAttributeFromContext(ctx context.Context, key string, value any)
```

Adds an attribute to the current span from context. Convenience for when you only have context (e.g. from the tracing middleware); corresponds to `tracer.SetSpanAttribute(span, key, value)` when you have the tracer and span. This is a no-op if tracing is not active.

**Example:**

```go
func handleRequest(ctx context.Context) {
    tracing.SetSpanAttributeFromContext(ctx, "user.role", "admin")
    tracing.SetSpanAttributeFromContext(ctx, "user.id", 12345)
}
```

### AddSpanEventFromContext

```go
func AddSpanEventFromContext(ctx context.Context, name string, attrs ...attribute.KeyValue)
```

Adds an event to the current span from context. Convenience for when you only have context (e.g. from the tracing middleware); corresponds to `tracer.AddSpanEvent(span, name, attrs...)` when you have the tracer and span. This is a no-op if tracing is not active.

**Example:**

```go
import "go.opentelemetry.io/otel/attribute"

tracing.AddSpanEventFromContext(ctx, "cache_miss",
    attribute.String("key", "user:123"),
)
```

### TraceContext

```go
func TraceContext(ctx context.Context) context.Context
```

Returns the context as-is (it should already contain trace information). Provided for API consistency.

Internal operational events are logged at the appropriate slog level via the logger passed to [WithLogger]. See [WithLogger](options/#withlogger) in Options.

## App Context (rivaas.dev/app)

When using the [app](/docs/reference/packages/app/) package with tracing enabled, the request context `*app.Context` exposes the same semantics via:

| Method | Description |
|--------|-------------|
| `FinishSpan(span)` | End child span with success. Delegates to `tracing.FinishSpan`. |
| `FinishSpanWithHTTPStatus(span, statusCode)` | End span with HTTP status. Delegates to `tracing.FinishSpanWithHTTPStatus`. |
| `FinishSpanWithError(span, err)` | End span with error. Delegates to `tracing.FinishSpanWithError`. |
| `RecordError(err)` | Record error on request span without ending it. Uses `tracing.RecordErrorFromContext(c.RequestContext(), err)`. |
| `CopyTraceContext()` | New context with same trace for goroutines. Delegates to `tracing.CopyTraceContext(c.RequestContext())`. |
| `WithSpan(name, fn)` | Run `fn` under a span; finish with success or error from return. Uses `c.StartSpan` and `FinishSpan` / `FinishSpanWithError`. |

**Example:**

```go
err := c.WithSpan("fetch-user", func(ctx context.Context) error {
    user, err := fetchUser(ctx, id)
    if err != nil {
        return err
    }
    return c.JSON(http.StatusOK, user)
})
```

## Hook Types

### SpanStartHook

```go
type SpanStartHook func(ctx context.Context, span trace.Span, req *http.Request)
```

Called when a request span is started. It receives the context, span, and HTTP request. This can be used for custom attribute injection, dynamic sampling, or integration with APM tools.

**Example:**

```go
hook := func(ctx context.Context, span trace.Span, req *http.Request) {
    if tenantID := req.Header.Get("X-Tenant-ID"); tenantID != "" {
        span.SetAttributes(attribute.String("tenant.id", tenantID))
    }
}
tracer := tracing.MustNew(
    tracing.WithSpanStartHook(hook),
)
```

### SpanFinishHook

```go
type SpanFinishHook func(span trace.Span, statusCode int)
```

Called when a request span is finished. It receives the span and the HTTP status code. This can be used for custom metrics, logging, or post-processing.

**Example:**

```go
hook := func(span trace.Span, statusCode int) {
    if statusCode >= 500 {
        metrics.IncrementServerErrors()
    }
}
tracer := tracing.MustNew(
    tracing.WithSpanFinishHook(hook),
)
```

## ContextTracing Type

```go
type ContextTracing struct {
    // contains filtered or unexported fields
}
```

A helper type for router context integration that provides convenient access to tracing functionality within HTTP handlers.

### NewContextTracing

```go
func NewContextTracing(ctx context.Context, tracer *Tracer, span trace.Span) *ContextTracing
```

Creates a new context tracing helper. Panics if `ctx`, `tracer`, or `span` is nil with one of: `tracing: nil context passed to NewContextTracing`, `tracing: tracer cannot be nil`, `tracing: span cannot be nil`.

**Parameters:**
- `ctx`: The request context (must not be nil)
- `tracer`: The Tracer instance (must not be nil)
- `span`: The current span (must not be nil)

**Example:**

```go
ct := tracing.NewContextTracing(ctx, tracer, span)
```

### ContextTracing Methods

#### TraceID

```go
func (ct *ContextTracing) TraceID() string
```

Returns the current trace ID. Returns an empty string if no valid span.

#### SpanID

```go
func (ct *ContextTracing) SpanID() string
```

Returns the current span ID. Returns an empty string if no valid span.

#### SetSpanAttribute

```go
func (ct *ContextTracing) SetSpanAttribute(key string, value any)
```

Adds an attribute to the current span. No-op if span is nil or not recording.

#### AddSpanEvent

```go
func (ct *ContextTracing) AddSpanEvent(name string, attrs ...attribute.KeyValue)
```

Adds an event to the current span. No-op if span is nil or not recording.

#### TraceContext

```go
func (ct *ContextTracing) TraceContext() context.Context
```

Returns the trace context.

#### GetSpan

```go
func (ct *ContextTracing) GetSpan() trace.Span
```

Returns the current span.

#### GetTracer

```go
func (ct *ContextTracing) GetTracer() *Tracer
```

Returns the underlying Tracer.

### ContextTracing Example

```go
func handleRequest(w http.ResponseWriter, r *http.Request, tracer *tracing.Tracer) {
    ctx := r.Context()
    span := trace.SpanFromContext(ctx)
    
    // Create context tracing helper
    ct := tracing.NewContextTracing(ctx, tracer, span)
    
    // Use helper methods
    ct.SetSpanAttribute("user.id", "123")
    ct.AddSpanEvent("processing_started")
    
    // Get trace info for logging
    log.Printf("Processing [trace=%s, span=%s]", ct.TraceID(), ct.SpanID())
}
```

## Constants

### Default Values

```go
const (
    DefaultServiceName    = "rivaas-service"
    DefaultServiceVersion = "1.0.0"
    DefaultSampleRate     = 1.0
)
```

Default configuration values used when not explicitly set.

### Provider Types

```go
const (
    NoopProvider     Provider = "noop"
    StdoutProvider   Provider = "stdout"
    OTLPProvider     Provider = "otlp"
    OTLPHTTPProvider Provider = "otlp-http"
)
```

Available tracing providers.

## Next Steps

- Review [Options](../options/) for all configuration options
- Check [Middleware Options](../middleware-options/) for HTTP middleware
- See [Troubleshooting](../troubleshooting/) for common issues
- Explore the [Tracing Guide](/docs/guides/tracing/) for learning-focused content
