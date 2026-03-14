---
title: "API Reference"
linkTitle: "API Reference"
keywords:
  - app api
  - app reference
  - api documentation
  - type reference
weight: 1
description: >
  Complete API reference for the App package.
---

## Core Functions

### New

```go
func New(opts ...Option) (*App, error)
```

Creates a new App instance with the given options. Returns an error if configuration is invalid.

**Parameters:**
- `opts` - Configuration options

**Returns:**
- `*App` - The app instance
- `error` - Configuration validation errors

**Example:**

```go
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithServiceVersion("v1.0.0"),
)
if err != nil {
    log.Fatal(err)
}
```

### MustNew

```go
func MustNew(opts ...Option) *App
```

Creates a new App instance or panics on error. Use for initialization in `main()` functions.

**Parameters:**
- `opts` - Configuration options

**Returns:**
- `*App` - The app instance

**Panics:** If configuration is invalid

**Example:**

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
)
```

## App Methods

### HTTP Method Shortcuts

```go
func (a *App) GET(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
func (a *App) POST(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
func (a *App) PUT(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
func (a *App) DELETE(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
func (a *App) PATCH(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
func (a *App) HEAD(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
func (a *App) OPTIONS(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
func (a *App) Any(path string, handler HandlerFunc, opts ...RouteOption) *route.Route
```

Register routes for HTTP methods. Supported methods are **GET**, **POST**, **PUT**, **DELETE**, **PATCH**, **HEAD**, and **OPTIONS**. Registering a route with any other method (e.g. CONNECT, TRACE, or a typo) causes a **panic** with a clear message (fail-fast). The same applies to routes registered via Group and VersionGroup (e.g. `Group.GET`, `VersionGroup.POST`).

### Middleware

```go
func (a *App) Use(middleware ...HandlerFunc)
```

Adds middleware to the app. Middleware executes for all routes registered after `Use()`.

### Route Groups

```go
func (a *App) Group(prefix string, middleware ...HandlerFunc) *Group
func (a *App) Version(version string) *VersionGroup
```

Create route groups and version groups.

### Static Files

```go
func (a *App) Static(prefix, root string)
func (a *App) File(path, filepath string)
func (a *App) StaticFS(prefix string, fs http.FileSystem)
func (a *App) NoRoute(handler HandlerFunc)
```

Serve static files and set custom 404 handler.

### Server Management

```go
func (a *App) Start(ctx context.Context) error
```

Starts the server with graceful shutdown. The server runs HTTP, HTTPS, or mTLS depending on configuration: use [WithTLS](options/#withtls) or [WithMTLS](options/#withmtls) at construction to serve over TLS; otherwise plain HTTP is used.

### Lifecycle Hooks

```go
func (a *App) OnStart(fn func(context.Context) error)
func (a *App) OnReady(fn func())
func (a *App) OnShutdown(fn func(context.Context))
func (a *App) OnStop(fn func())
func (a *App) OnRoute(fn func(*route.Route))
```

Register lifecycle hooks. See [Lifecycle Hooks](lifecycle-hooks/) for details.

### Accessors

```go
func (a *App) Router() *router.Router
func (a *App) Metrics() *metrics.Recorder
func (a *App) Tracing() *tracing.Tracer
func (a *App) Readiness() *ReadinessManager
func (a *App) ServiceName() string
func (a *App) ServiceVersion() string
func (a *App) Environment() string
```

Access underlying components and configuration.

### Route Management

```go
func (a *App) Route(name string) (*route.Route, bool)
func (a *App) Routes() []*route.Route
func (a *App) URLFor(routeName string, params map[string]string, query map[string][]string) (string, error)
func (a *App) MustURLFor(routeName string, params map[string]string, query map[string][]string) string
```

Route lookup and URL generation. Router must be frozen (after `Start()`).

### Metrics

```go
func (a *App) GetMetricsHandler() (http.Handler, error)
func (a *App) GetMetricsServerAddress() string
```

Access metrics handler and server address.

### Logging

```go
func (a *App) BaseLogger() *slog.Logger
```

Returns the application's base logger. Never returns nil.

### Testing

```go
func (a *App) Test(req *http.Request, opts ...TestOption) (*http.Response, error)
func (a *App) TestJSON(method, path string, body any, opts ...TestOption) (*http.Response, error)
```

Test routes without starting a server.

## Helper Functions

### ExpectJSON

```go
func ExpectJSON(t testingT, resp *http.Response, statusCode int, out any)
```

Test helper that asserts response status and decodes JSON.

### Generic Binding

```go
func Bind[T any](c *Context, opts ...BindOption) (T, error)
func MustBind[T any](c *Context, opts ...BindOption) (T, bool)
func BindOnly[T any](c *Context, opts ...BindOption) (T, error)
func BindPatch[T any](c *Context, opts ...BindOption) (T, error)
func MustBindPatch[T any](c *Context, opts ...BindOption) (T, bool)
func BindStrict[T any](c *Context, opts ...BindOption) (T, error)
func MustBindStrict[T any](c *Context, opts ...BindOption) (T, bool)
```

Type-safe binding with generics. These functions provide a more concise API compared to the Context methods.

## Context observability methods

When observability is enabled, `app.Context` provides these methods (all no-op when metrics/tracing are not configured):

| Method | Description |
|--------|-------------|
| `TraceID()` | Current trace ID from the request span. |
| `SpanID()` | Current span ID. |
| `SetSpanAttribute(key, value)` | Add attribute to the current span. |
| `AddSpanEvent(name, attrs...)` | Add event to the current span. |
| `TraceContext()` | Request context (for logging, etc.). |
| `Span()` | Current span from context. |
| `StartSpan(name, opts...)` | Start a child span; returns `(context.Context, trace.Span)`. Use with `defer c.FinishSpan(span, statusCode)`. |
| `FinishSpan(span, statusCode)` | End a child span. |
| `Tracer()` | Returns `*tracing.Tracer`; **advanced use only** (e.g. pass to another library). |
| `RecordHistogram(name, value, attrs...)` | Record a histogram sample. |
| `IncrementCounter(name, attrs...)` | Increment a counter by 1. |
| `AddCounter(name, value, attrs...)` | Add to a counter by an arbitrary amount. |
| `SetGauge(name, value, attrs...)` | Set a gauge value. |

See the [observability guide](/docs/guides/app/observability/) and [context guide](/docs/guides/app/context/) for usage and examples.

## Types

### HandlerFunc

```go
type HandlerFunc func(*Context)
```

Handler function that receives an app Context.

### TestOption

```go
type TestOption func(*testConfig)

func WithTimeout(d time.Duration) TestOption
func WithContext(ctx context.Context) TestOption
```

Options for testing.

## Next Steps

- [Options](options/) - Configuration options reference
- [Context API](context-api/) - Context methods reference
- [Lifecycle Hooks](lifecycle-hooks/) - Hook APIs reference
