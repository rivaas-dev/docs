---
title: "Basic Usage"
description: "Learn the fundamentals of loading and accessing configuration with Rivaas"
weight: 3
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

### Generic Getters for Custom Types

For custom types or explicit error handling, use the generic `GetE` function:

```go
// With error handling
port, err := config.GetE[int](cfg, "server.port")
if err != nil {
    log.Printf("invalid port: %v", err)
    port = 8080  // fallback
}

// For custom types
type DatabaseConfig struct {
    Host string
    Port int
}

dbConfig, err := config.GetE[DatabaseConfig](cfg, "database")
if err != nil {
    log.Fatalf("invalid database config: %v", err)
}
```

## Error Handling

The config package provides comprehensive error handling through different getter variants.

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

// Errors provide context
// Example: "config error: key 'server.port' not found"
```

### ConfigError Structure

When errors occur during loading, they're wrapped in `ConfigError`:

```go
type ConfigError struct {
    Source    string // Where the error occurred (e.g., "source[0]")
    Field     string // Specific field with the error
    Operation string // Operation being performed (e.g., "load")
    Err       error  // Underlying error
}
```

Example error handling during load:

```go
if err := cfg.Load(context.Background()); err != nil {
    // Error message includes context:
    // "config error in source[0] during load: file not found: config.yaml"
    log.Fatalf("configuration error: %v", err)
}
```

## Nil-Safe Operations

All getter methods handle nil `Config` instances gracefully:

```go
var cfg *config.Config  // nil

// Short methods return zero values (no panic)
cfg.String("key")       // Returns ""
cfg.Int("key")          // Returns 0
cfg.Bool("key")         // Returns false

// Error methods return errors
port, err := config.GetE[int](cfg, "key")
// err: "config instance is nil"
```

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

For complete API details, see the [API Reference](/reference/packages/config/api-reference/).
