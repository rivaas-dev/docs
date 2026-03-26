---
title: "Design Decisions"
description: "Why we chose specific approaches when building Rivaas"
weight: 30
keywords:
  - design decisions
  - architecture decisions
  - functional options
  - standalone packages
  - OpenTelemetry
  - RFC 9457
---

This page explains why we made certain choices. Each section describes the decision, the reasoning, and (where helpful) a short code comparison. For the principles behind these decisions, see [Design Principles](../design-principles/). For the resulting structure, see [Architecture](../architecture/).

## Why functional options over config structs?

**Decision:** Use functional options instead of configuration structs.

**Reason:**

- New options don't break existing code
- Defaults are built in, not set by you
- Option names tell you what they do
- Your IDE can show all options
- Options can validate values when you apply them

**Example of the benefit:**

```go
// With config struct: Adding new fields breaks code
type Config struct {
    ServiceName string
    Port        int
    NewFeature  bool // New field — all code must be checked
}

// With functional options: Adding options doesn't break anything
metrics.MustNew(
    metrics.WithServiceName("api"),
    // New option added — old code still works
)
```

## Why standalone packages?

**Decision:** Every package works independently.

**Reason:**

- You can try packages one at a time
- No vendor lock-in to the framework
- Testing is easier with fewer dependencies
- Library authors can use specific features
- Follows Go's philosophy of composition

## Why a separate app package?

**Decision:** Provide an `app` package that connects standalone packages.

**Reason:**

- Most users want everything to work together
- Connection code doesn't pollute standalone packages
- Central place for lifecycle management
- Single place for shared concerns (service name, version)
- Consistent configuration across packages

## Why New() and MustNew()?

**Decision:** Provide both error-returning and panic-on-error constructors.

**Reason:**

- `New()` for libraries and code that needs error handling
- `MustNew()` for `main()` where panic is acceptable
- Follows standard library patterns (`regexp.Compile` vs `regexp.MustCompile`)
- Less boilerplate for common cases while keeping flexibility

## Why multi-module over single module?

**Decision:** Structure the repository as many independent Go modules connected by `go.work`, instead of one large module.

**Reason:**

- **Independent versioning** — A bug fix in `logging` doesn't force a new release of `metrics`
- **Minimal downloads** — `go get rivaas.dev/logging` pulls only what `logging` needs, not the full framework
- **Compiler-enforced boundaries** — If a standalone package accidentally imports `app`, the build fails immediately. The dependency rules are checked by the Go toolchain, not just by convention.
- **Fits Go's module model** — Go modules are designed for this. Each module declares exactly what it needs.

The trade-off is more `go.mod` files to maintain, but the boundary enforcement and smaller dependency graphs are worth it.

## Why OpenTelemetry for observability?

**Decision:** Use OpenTelemetry for metrics and tracing instead of building a custom observability layer.

**Reason:**

- **Vendor-neutral** — OpenTelemetry is a CNCF standard. You can send data to Prometheus, Jaeger, Datadog, Grafana, or any compatible backend.
- **Single API** — One set of APIs covers both metrics and tracing. You don't learn two different systems.
- **Wide ecosystem** — Client libraries, auto-instrumentation, and exporters already exist for most languages and platforms.
- **Future-proof** — As the industry converges on OpenTelemetry, Rivaas stays aligned without migration work.

We didn't build our own because observability standards are hard to get right, and the ecosystem benefits of a shared standard outweigh any framework-specific advantage.

## Why private config structs?

**Decision:** Options apply to a private `config` struct. The public type is built from the validated config.

**Reason:**

- **No mutation after construction** — Once `New()` returns, the configuration is sealed. Callers can't change it from outside.
- **Validation at the gate** — All checks happen in one place (the constructor). You never get a half-valid object.
- **Small public surface** — Users see `Option` functions and the public type, not the internal config fields. This keeps the API clean and lets us change internals without breaking anyone.

```go
// Options mutate the private config
type Option func(*config)

// Constructor validates and builds the public type
func New(opts ...Option) (*PublicType, error) {
    cfg := defaultConfig()
    for _, opt := range opts {
        opt(cfg)
    }
    if err := cfg.validate(); err != nil {
        return nil, err
    }
    return newFromConfig(cfg), nil
}
```

## Why router.HandlerFunc as the sole handler type?

**Decision:** Use a single handler type (`router.HandlerFunc`) throughout the framework — for middleware, route groups, version groups, and the app layer.

**Reason:**

- **One type, one mental model** — You write handlers and middleware the same way everywhere. No adapters, no conversion functions.
- **Composable** — Middleware, groups, and the app layer all chain the same type. This makes handler chains predictable.
- **Less boilerplate** — Frameworks that use multiple handler types need adapter functions at every boundary. Rivaas doesn't.

## Why context pooling?

**Decision:** Use `sync.Pool` to recycle `Context` objects in the router.

**Reason:**

- **Hot-path allocation reduction** — Every HTTP request needs a context. Allocating one per request puts pressure on the garbage collector. Pooling reuses contexts so the GC handles fewer allocations.
- **Per-P caches** — Go's `sync.Pool` already optimises for multi-core CPUs with per-processor caches. We get low-contention recycling without extra complexity.
- **Transparent to users** — You never see the pool. You call `GET("/path", handler)` and the router manages context lifecycle for you.

The trade-off is that handlers must not hold references to the context after the handler returns. This is documented and follows the same pattern as `net/http` request handling.

## Why RFC 9457 for errors?

**Decision:** Use RFC 9457 Problem Details as the default error response format.

**Reason:**

- **Industry standard** — RFC 9457 defines a machine-readable format for HTTP error responses. Clients that understand this format can parse Rivaas errors without any framework-specific knowledge.
- **Structured and extensible** — The format includes standard fields (`type`, `title`, `status`, `detail`, `instance`) and supports custom extensions. You get structure without losing flexibility.
- **Consistent across APIs** — When all your services use the same error format, client-side error handling becomes simpler and more predictable.

```json
{
  "type": "https://api.example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The 'email' field must be a valid email address",
  "instance": "/users"
}
```

We chose RFC 9457 over custom formats because it's well-defined, widely supported by HTTP tooling, and reduces what API consumers need to learn.

## Why config bridge structs for file-based loading?

**Decision:** Export `ObservabilityConfig`, `TracingConfig`, `MetricsConfig`, and `LoggingConfig` as DTOs, even though the general rule is "no user-facing config structs".

**Reason:**

Applications often load configuration from YAML or JSON files at startup. Functional options work well in code, but they don't have a natural text format for file-based configuration. A bridge struct solves this without giving up the functional options API:

1. The user populates the struct by unmarshalling a config file.
2. The user passes it to `WithObservabilityFromConfig`, which converts it to functional options internally.
3. The rest of the API stays functional-options-only.

This is different from replacing functional options with structs. These structs are DTOs — Data Transfer Objects — used only to move data from files into the options API. Users never mutate them to configure the app; they only pass them to one function. The functional options API (`WithObservability`, `WithTracing`, etc.) remains the primary way to configure observability in code.

```go
// File-based config loading (uses the bridge struct)
var cfg AppConfig
yaml.Unmarshal(data, &cfg)
app.New(app.WithObservabilityFromConfig(cfg.Observability))

// Code-based config (uses functional options directly — same result)
app.New(app.WithObservability(
    app.WithTracing(tracing.WithOTLP("localhost:4317")),
    app.WithMetrics(metrics.WithPrometheus(":9090")),
))
```

The trade-off is that exporting these structs creates a surface that could be misused. We accept this because the structs are simple, well-documented, and the only entry point is `WithObservabilityFromConfig`.
