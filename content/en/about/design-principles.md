---
title: "Design Principles"
description: "Core principles that guide how we build Rivaas"
weight: 10
keywords:
  - design principles
  - philosophy
  - architecture
  - functional options
  - developer experience
---

This page explains the core ideas behind Rivaas. Understanding these principles helps you use the framework better. If you want to contribute code, these principles guide your work.

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
    logging.WithSampling(logging.SamplingConfig{
        Initial:    100,
        Thereafter: 100,
        Tick:       time.Minute,
    }),
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

Configuration errors happen at startup, not during requests. This helps you catch problems early.

```go
// Returns a clear error immediately
app, err := app.New(
    app.WithServerTimeout(-1 * time.Second), // Invalid
)
// Error: "server.readTimeout: must be positive"
```

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

Every package follows this structure:

```go
// Step 1: Define an Option type
type Option func(*Config)

// Step 2: Create constructor that accepts options
func New(opts ...Option) (*Config, error) {
    cfg := defaultConfig()  // Start with defaults
    
    for _, opt := range opts {
        opt(cfg)  // Apply each option
    }
    
    if err := cfg.validate(); err != nil {
        return nil, err
    }
    
    return cfg, nil
}

// Step 3: Convenience constructor that panics on error
func MustNew(opts ...Option) *Config {
    cfg, err := New(opts...)
    if err != nil {
        panic(err)
    }
    return cfg
}
```

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

### Separation of Concerns

Each package does one thing well. This makes the code easier to:

- **Test** — Test each package alone
- **Maintain** — Changes to one package don't affect others
- **Use** — Pick only what you need
- **Understand** — Clear boundaries make the code clearer

**Package responsibilities:**

| Package | What it does |
|---------|--------------|
| `router` | Routes HTTP requests to handlers |
| `metrics` | Collects and exports metrics |
| `tracing` | Tracks requests across services |
| `logging` | Writes structured log messages |
| `binding` | Converts request data to Go structs |
| `validation` | Checks if data is valid |
| `errors` | Formats error messages |
| `openapi` | Generates API documentation |
| `app` | Connects everything together |

**Clear boundaries:**

Packages talk through clean interfaces. They don't know about each other's internal details.

```go
// metrics package has a clean interface
type Recorder struct { ... }
func (r *Recorder) RecordRequest(method, path string, status int, duration time.Duration)

// app package uses the interface without knowing how it works inside
app.metrics.RecordRequest(method, path, status, duration)
```

## Package Architecture

### Standalone Packages

**Every Rivaas package works on its own.** You can use any package without the full framework.

**Benefits:**

- **No lock-in** — Use Rivaas packages with any Go framework
- **Gradual adoption** — Start with one package, add more later
- **Easy testing** — Test with minimal dependencies
- **Flexible** — Different services can use different packages

**Requirements for standalone packages:**

Each package must:

1. Work without the `app` package
2. Have its own `go.mod` file
3. Provide `New()` and `MustNew()` constructors
4. Use functional options
5. Have good defaults
6. Include documentation and examples

**Example: Using metrics with standard library**

```go
package main

import (
    "net/http"
    "rivaas.dev/metrics"
)

func main() {
    // Use metrics without the app framework
    recorder := metrics.MustNew(
        metrics.WithPrometheus(":9090", "/metrics"),
        metrics.WithServiceName("my-api"),
    )
    defer recorder.Shutdown(context.Background())

    // Create middleware for standard http.Handler
    handler := metrics.Middleware(recorder)(myHandler)
    
    http.ListenAndServe(":8080", handler)
}
```

**Example: Using logging standalone**

```go
package main

import "rivaas.dev/logging"

func main() {
    // Use logging anywhere - no framework needed
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithServiceName("background-worker"),
    )
    
    logger.Info("worker started", "queue", "emails")
}
```

**Example: Using binding with any framework**

```go
package main

import "rivaas.dev/binding"

type CreateUserRequest struct {
    Name  string `json:"name" validate:"required"`
    Email string `json:"email" validate:"required,email"`
}

func handler(w http.ResponseWriter, r *http.Request) {
    // Use binding standalone
    var req CreateUserRequest
    if err := binding.JSON(r, &req); err != nil {
        // Handle error
    }
}
```

**All standalone packages:**

| Package | Import Path | What it does |
|---------|-------------|--------------|
| `router` | `rivaas.dev/router` | HTTP routing |
| `metrics` | `rivaas.dev/metrics` | Prometheus/OTLP metrics |
| `tracing` | `rivaas.dev/tracing` | OpenTelemetry tracing |
| `logging` | `rivaas.dev/logging` | Structured logging |
| `binding` | `rivaas.dev/binding` | Request binding |
| `validation` | `rivaas.dev/validation` | Input validation |
| `errors` | `rivaas.dev/errors` | Error formatting |
| `openapi` | `rivaas.dev/openapi` | API documentation |

### The App Package: Integration Layer

The `app` package is the glue that connects standalone packages into a complete framework.

**What app does:**

1. **Connects packages** — Wires standalone packages together
2. **Manages lifecycle** — Handles startup, shutdown, and cleanup
3. **Shares configuration** — Passes service name and version to all packages
4. **Provides defaults** — Sets up everything for production use
5. **Makes it easy** — One entry point for common use cases

**How app connects packages:**

```go
// app/app.go imports and connects standalone packages
import (
    "rivaas.dev/errors"
    "rivaas.dev/logging"
    "rivaas.dev/metrics"
    "rivaas.dev/openapi"
    "rivaas.dev/router"
    "rivaas.dev/tracing"
)

type App struct {
    router  *router.Router
    metrics *metrics.Recorder
    tracing *tracing.Config
    logging *logging.Config
    openapi *openapi.Manager
    // ...
}
```

**Automatic wiring:**

When you use `app`, packages connect automatically:

```go
app := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithObservability(
        app.WithLogging(logging.WithJSONHandler()),
        app.WithMetrics(), // Prometheus is default
        app.WithTracing(tracing.WithOTLP("localhost:4317")),
    ),
)

// Behind the scenes, app:
// 1. Creates logging with service name "my-api"
// 2. Creates metrics with service name "my-api"
// 3. Connects logger to metrics (for error reporting)
// 4. Connects logger to tracing (for error reporting)
// 5. Sets up unified observability
// 6. Configures graceful shutdown for all components
```

**Choose your level:**

**Full framework (recommended for most):**

```go
// Use app for batteries-included experience
app := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithObservability(
        app.WithLogging(),
        app.WithMetrics(),
        app.WithTracing(),
    ),
)
app.GET("/users", handlers.ListUsers)
app.Run(":8080")
```

**Standalone packages (for advanced use):**

```go
// Use packages individually for maximum control
r := router.MustNew()
logger := logging.MustNew()
recorder := metrics.MustNew()

// Wire them yourself
r.Use(loggingMiddleware(logger))
r.Use(metricsMiddleware(recorder))

r.GET("/users", listUsers)
http.ListenAndServe(":8080", r)
```

## Design Decisions

This section explains why we made certain choices.

### Why functional options over config structs?

**Decision:** Use functional options instead of configuration structs.

**Reason:**

- New options don't break existing code
- Defaults are built in, not set by you
- Option names tell you what they do
- Your IDE can show all options
- Options can check values when you use them

**Example of the benefit:**

```go
// With config struct: Adding new fields breaks code
type Config struct {
    ServiceName string
    Port        int
    // New field added - all code must be checked
    NewFeature  bool
}

// With functional options: Adding options doesn't break anything
metrics.MustNew(
    metrics.WithServiceName("api"),
    // New option added - old code still works
)
```

### Why standalone packages?

**Decision:** Every package works independently.

**Reason:**

- You can try packages one at a time
- No vendor lock-in to the framework
- Testing is easier with fewer dependencies
- Library authors can use specific features
- Follows Go's philosophy of composition

### Why a separate app package?

**Decision:** Provide an `app` package that connects standalone packages.

**Reason:**

- Most users want everything to work together
- Connection code doesn't pollute standalone packages
- Central place for lifecycle management
- Single place for shared concerns
- Consistent configuration across packages

### Why New() and MustNew()?

**Decision:** Provide both error-returning and panic-on-error constructors.

**Reason:**

- `New()` for libraries and code that needs error handling
- `MustNew()` for `main()` where panic is acceptable
- Follows standard library patterns (`regexp.Compile` vs `regexp.MustCompile`)
- Less boilerplate for common cases while keeping flexibility

## Summary

| Principle | How we implement it |
|-----------|---------------------|
| **DX First** | Good defaults, clear errors, progressive disclosure |
| **Functional Options** | All packages use `Option func(*Config)` |
| **Separation of Concerns** | Each package does one thing |
| **Standalone Packages** | Every package works without `app` |
| **App as Glue** | Connects packages, manages lifecycle |

These principles guide all our development work. When you contribute to Rivaas, make sure your changes follow these principles.
