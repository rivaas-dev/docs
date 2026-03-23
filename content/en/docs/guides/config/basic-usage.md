---
title: "Basic Usage"
description: "Learn the fundamentals of loading and accessing configuration with Rivaas"
weight: 3
keywords:
  - config basic usage
  - load config
  - simple config
  - getting started
---

This guide covers the essential operations for working with the config package. Learn how to load configuration files, access values, and handle errors.

## Loading Configuration Files

The config package automatically detects file formats based on the file extension. Supported formats include JSON, YAML, and TOML.

### Simple File Loading

```go
package main

import (
    "context"
    "log"
    "rivaas.dev/config"
)

func main() {
    cfg := config.MustNew(
        config.WithFile("config.yaml"),
    )

    if err := cfg.Load(context.Background()); err != nil {
        log.Fatalf("failed to load config: %v", err)
    }
}
```

### Multiple File Formats

You can load multiple configuration files of different formats:

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),  // YAML format
    config.WithFile("config.json"),  // JSON format
    config.WithFile("config.toml"),  // TOML format
)
```

{{< alert color="info" >}}
Files are processed in order. Later files override values from earlier ones, enabling environment-specific overrides.
{{< /alert >}}

### Environment Variables in Paths

You can use environment variables in file paths. This is useful when different environments use different directories:

```go
// Use ${VAR} or $VAR in paths
cfg := config.MustNew(
    config.WithFile("${CONFIG_DIR}/app.yaml"),      // Expands to actual directory
    config.WithFile("${APP_ENV}/overrides.yaml"),   // e.g., "production/overrides.yaml"
)
```

This works with all path-based options: `WithFile`, `WithFileAs`, `WithConsul`, `WithConsulAs`, `WithConsulOptional`, `WithConsulAsOptional`, `WithFileDumper`, and `WithFileDumperAs`.

### Built-in Format Support

The config package includes built-in codecs for common formats:

| Format | Extension | Codec Type |
|--------|-----------|------------|
| JSON | `.json` | `codec.TypeJSON` |
| YAML | `.yaml`, `.yml` | `codec.TypeYAML` |
| TOML | `.toml` | `codec.TypeTOML` |
| Environment Variables | - | `codec.TypeEnvVar` |

## Accessing Configuration Values

Once loaded, access configuration using dot notation and type-safe getters.

### Dot Notation

Navigate nested configuration structures using dots:

```go
// Given config: { "database": { "host": "localhost", "port": 5432 } }
host := cfg.String("database.host")      // "localhost"
port := cfg.Int("database.port")         // 5432
```

### Type-Safe Getters

The config package provides type-safe getters for common data types:

```go
// Basic types
stringVal := cfg.String("key")
intVal := cfg.Int("key")
boolVal := cfg.Bool("key")
floatVal := cfg.Float64("key")

// Time and duration
duration := cfg.Duration("timeout")
timestamp := cfg.Time("created_at")

// Collections
slice := cfg.StringSlice("tags")
mapping := cfg.StringMap("metadata")
```

### Getters with Default Values

Use `Or` variants to provide fallback values:

```go
host := cfg.StringOr("server.host", "localhost")
port := cfg.IntOr("server.port", 8080)
debug := cfg.BoolOr("debug", false)
timeout := cfg.DurationOr("timeout", 30*time.Second)
```

### Generic getters (`Get`, `GetOr`, `GetE`)

Use `GetE` when a missing or invalid value should be an error. Supported type parameters match the conversion logic in the package (same general idea as `spf13/cast`); they do **not** turn a nested map into an arbitrary struct.

```go
port, err := config.GetE[int](cfg, "server.port")
if err != nil {
    log.Printf("invalid port: %v", err)
    port = 8080 // fallback
}

// Nested JSON/YAML objects are typically map[string]any until you bind with WithBinding
db, err := config.GetE[map[string]any](cfg, "database")
if err != nil {
    log.Fatalf("missing database block: %v", err)
}
```

## Error Handling

You can choose getters that return zero values, explicit defaults (`Or` methods), or errors (`GetE`).

### Short Form (No Error)

Short methods return zero values for missing keys:

```go
cfg.String("nonexistent")      // Returns ""
cfg.Int("nonexistent")         // Returns 0
cfg.Bool("nonexistent")        // Returns false
cfg.StringSlice("nonexistent") // Returns []string{}
cfg.StringMap("nonexistent")   // Returns map[string]any{}
```

This approach is ideal when you want simple access with sensible defaults.

### Default Value Form (Or Methods)

`Or` methods provide explicit fallback values:

```go
host := cfg.StringOr("host", "localhost")        // Returns "localhost" if missing
port := cfg.IntOr("port", 8080)                  // Returns 8080 if missing
debug := cfg.BoolOr("debug", false)              // Returns false if missing
timeout := cfg.DurationOr("timeout", 30*time.Second) // Returns 30s if missing
```

### Error Returning Form (E Methods)

Use `GetE` for explicit error handling:

```go
port, err := config.GetE[int](cfg, "server.port")
if err != nil {
    return fmt.Errorf("invalid port configuration: %w", err)
}

// Example: `key "server.port" not found` or conversion error
```

### `config.Error` shape

Many `Load` failures are returned as `*config.Error` (wrapping the underlying problem):

```go
type Error struct {
    Source    string // Where the error occurred (e.g., "source[0]")
    Field     string // Specific field with the error (optional)
    Operation string // Operation being performed (e.g., "load")
    Err       error  // Underlying error
}
```

Example error handling during load (`import "errors"`):

```go
if err := cfg.Load(context.Background()); err != nil {
    var cfgErr *config.Error
    if errors.As(err, &cfgErr) {
        log.Printf("in %s during %s: %v", cfgErr.Source, cfgErr.Operation, cfgErr.Err)
    }
    log.Fatalf("configuration error: %v", err)
}
```

## Nil-safe getters

Typed getters and `Get` handle a nil `*config.Config` without panicking:

```go
var cfg *config.Config  // nil

cfg.String("key")       // Returns ""
cfg.Int("key")          // Returns 0
cfg.Bool("key")         // Returns false

port, err := config.GetE[int](cfg, "key")
// err: "config instance is nil"
```

Do not call `Values()` on a nil config; it is not nil-receiver-safe.

## Complete Example

Putting it all together:

```go
package main

import (
    "context"
    "log"
    "time"
    "rivaas.dev/config"
)

func main() {
    // Create config with file source
    cfg := config.MustNew(
        config.WithFile("config.yaml"),
    )

    // Load configuration
    if err := cfg.Load(context.Background()); err != nil {
        log.Fatalf("failed to load config: %v", err)
    }

    // Access values with different approaches
    
    // Simple access (with zero values for missing keys)
    host := cfg.String("server.host")
    
    // With defaults
    port := cfg.IntOr("server.port", 8080)
    debug := cfg.BoolOr("debug", false)
    
    // With error handling
    timeout, err := config.GetE[time.Duration](cfg, "server.timeout")
    if err != nil {
        log.Printf("using default timeout: %v", err)
        timeout = 30 * time.Second
    }
    
    log.Printf("Server: %s:%d (debug: %v, timeout: %v)", 
        host, port, debug, timeout)
}
```

**Sample config.yaml:**

```yaml
server:
  host: localhost
  port: 8080
  timeout: 30s
debug: true
```

## Next Steps

- Learn about [Environment Variables](../environment-variables/) for flexible configuration
- Explore [Struct Binding](../struct-binding/) to map config to Go structs
- See [Multiple Sources](../multiple-sources/) for merging configurations

For complete API details, see the [API Reference](/docs/reference/packages/config/api-reference/).
