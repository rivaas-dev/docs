---
title: "Design Principles"
description: "Core principles that guide how we build Rivaas"
weight: 10
keywords:
  - design principles
  - philosophy
  - functional options
  - developer experience
  - testability
  - standards
---

This page explains the core ideas behind Rivaas. Understanding these principles helps you use the framework better. If you want to contribute code, these principles guide your work.

For how the packages and modules are structured, see [Architecture](../architecture/). For why we chose specific approaches, see [Design Decisions](../design-decisions/).

## Core Philosophy

### Developer Experience First

We put your experience as a developer first. Every choice we make thinks about how it affects you.

**What this means:**

When you use Rivaas, you should feel like the framework helps you, not fights you. Good defaults mean you can start quickly. Clear errors help you fix problems fast. The API should feel natural.

**In practice:**

- Everything works without configuration
- Simple tasks use simple code
- Error messages tell you what went wrong and how to fix it
- Your IDE can show you all available options

### Example: Sensible Defaults

```go
// This works right away - no setup needed
app := app.MustNew()

// Add configuration when you need it
app := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithEnvironment("production"),
)
```

The first example works perfectly for getting started. The second example shows how to customize when you need to.

### Progressive Disclosure

Simple use cases stay simple. Advanced features exist but don't make basic tasks harder.

**Three levels:**

1. **Basic** — Works immediately with good defaults
2. **Intermediate** — Common changes are easy
3. **Advanced** — Full control when you need it

**Example:**

```go
// Level 1: Basic - just works
logger := logging.MustNew()

// Level 2: Common customization
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelDebug),
)

// Level 3: Advanced - full control
logger := logging.MustNew(
    logging.WithCustomLogger(myCustomLogger),
    logging.WithSamplingInitial(100),
    logging.WithSamplingThereafter(100),
    logging.WithSamplingTick(time.Minute),
)
```

### Discoverable APIs

Your IDE should help you find what you need. When you type `metrics.With...`, your IDE shows all options.

```go
metrics.MustNew(
    metrics.With...  // IDE shows: WithProvider, WithPort, WithPath, etc.
)
```

### Fail Fast with Clear Errors

Configuration errors happen at startup, not during requests. This helps you catch problems early. Error messages tell you what went wrong and how to fix it — for required fields (e.g. service name or version), the error includes which option or environment variable to use.

```go
// Returns a clear error immediately
app, err := app.New(
    app.WithServerTimeout(-1 * time.Second), // Invalid
)
// Error: "server.readTimeout: must be positive"
```

Rivaas constructors never return a non-nil value when they return an error, so you never receive a partially-initialized config.

### Convenience Without Sacrificing Control

We provide two ways to create things:

- `MustNew()` — Panics on error (good for main function)
- `New()` — Returns error (good for tests and libraries)

```go
// In main() - panic is fine
app := app.MustNew(...)

// In tests or libraries - handle errors
app, err := app.New(...)
if err != nil {
    return fmt.Errorf("failed to create app: %w", err)
}
```

### Standards Compliance

Rivaas follows established industry standards instead of inventing its own formats. This means your team and your tools already know how to work with Rivaas output.

- **RFC 9457** — Error responses use the Problem Details standard. Clients can parse errors without knowing Rivaas internals.
- **OpenAPI 3.x** — API documentation uses the OpenAPI specification. Any OpenAPI-compatible tool can read it.
- **OpenTelemetry** — Metrics and tracing use the OpenTelemetry standard. You can send data to any compatible backend.

When a well-adopted standard exists for a problem, we use it. This reduces what you need to learn and makes Rivaas work well with the wider ecosystem.

### Testability

Every design choice should make testing easier, not harder.

The `New()` constructor returns errors that tests can check. Packages provide test helpers (for example, logging has utilities for capturing log output in tests). Because each package works on its own, you can test it with minimal dependencies.

When we design a new feature, we ask: "Can someone test this easily?" If the answer is no, we change the design.

### Performance-Conscious Ergonomics

Rivaas optimises hot paths without making the user API harder to use. The router uses `sync.Pool` to recycle request contexts, compiled route tables with Bloom filters for fast negative lookups, and optional cancellation-check elision for handler chains.

These optimisations happen behind the scenes. As a user, you call the same `MustNew()` and `GET("/path", handler)` — the fast path is the default path.

## Architectural Patterns

### Functional Options Pattern

All Rivaas packages use the same configuration pattern. This keeps the API consistent across packages.

**Benefits:**

- **Backward compatible** — Adding new options doesn't break existing code
- **Good defaults** — You only specify what you want to change
- **Self-documenting** — Option names tell you what they do
- **Easy to combine** — Options work together naturally
- **IDE-friendly** — Autocomplete shows all options

**How it works:**

Every package follows this structure. Options apply to an internal **config** struct (often a private type). The constructor validates the config and then builds the public type from it. When the public type holds runtime state (e.g. Router, Logger, Recorder, Tracer), options must not mutate that type directly; they mutate a config struct, and the constructor builds the public type from the validated config.

```go
// Step 1: Define an Option type (options apply to config, not the public type)
type Option func(*config)

// Step 2: Create constructor that accepts options
func New(opts ...Option) (*PublicType, error) {
    cfg := defaultConfig()  // Start with defaults
    
    for _, opt := range opts {
        opt(cfg)  // Apply each option to config
    }
    
    if err := cfg.validate(); err != nil {
        return nil, err
    }
    
    return newFromConfig(cfg), nil  // Build public type from validated config
}

// Step 3: Convenience constructor that panics on error
func MustNew(opts ...Option) *PublicType {
    t, err := New(opts...)
    if err != nil {
        panic(err)
    }
    return t
}
```

Packages like router, logging, metrics, tracing, and config use a private `config` struct; options apply to `*config`, and `New()` builds the public type (Router, Logger, Recorder, Tracer, Config) from the validated config.

Options must not be nil. Passing a nil option results in a validation error (reported by `New()` or by methods like `ApplyLifecycle` or `Test()` that accept options), not a panic. This applies to both top-level and nested options. Route options (e.g. passed to GET/POST/…) must not be nil; passing nil results in a validation error reported by [ValidateRoutes](/docs/reference/packages/app/api-reference/#validateroutes), not a panic. When using `MustNew`, any error from `New()` (including nil-option validation) causes a panic.

**Naming conventions:**

- `With<Feature>` — Enable or configure something
- `Without<Feature>` — Disable something (when default is enabled)

```go
// Enable features
metrics.WithPrometheus(":9090", "/metrics")
logging.WithJSONHandler()
app.WithServiceName("my-api")

// Disable features
metrics.WithServerDisabled()
app.WithoutDefaultMiddleware()
```

**Examples across packages:**

```go
// Metrics package
recorder := metrics.MustNew(
    metrics.WithPrometheus(":9090", "/metrics"),
    metrics.WithServiceName("my-api"),
)

// Logging package
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
    logging.WithServiceName("my-api"),
)

// Router package
r := router.MustNew(
    router.WithNotFoundHandler(custom404),
    router.WithMethodNotAllowedHandler(custom405),
)
```

## Summary

| Principle | How we implement it |
|-----------|---------------------|
| **DX First** | Good defaults, clear errors, progressive disclosure |
| **Functional Options** | Options apply to internal config; constructor builds public type from validated config |
| **Standards Compliance** | RFC 9457 errors, OpenAPI 3.x docs, OpenTelemetry observability |
| **Testability** | `New()` returns errors for tests; packages provide test helpers; standalone design reduces test dependencies |
| **Performance** | Context pooling, compiled routes, Bloom filters — all behind a simple API |

These principles guide all our development work. When you contribute to Rivaas, make sure your changes follow these principles.

For the package structure and module layout, see [Architecture](../architecture/). For the reasoning behind specific choices, see [Design Decisions](../design-decisions/).
