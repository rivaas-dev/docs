---
title: "Config Package"
linkTitle: "Config"
description: "API reference for rivaas.dev/config - Configuration management for Go applications"
weight: 1
sidebar_root_for: self
---

Complete API reference for the `rivaas.dev/config` package.

## Package Information

- **Import Path:** `rivaas.dev/config`
- **Go Version:** 1.25+
- **Documentation:** [pkg.go.dev/rivaas.dev/config](https://pkg.go.dev/rivaas.dev/config)
- **Source Code:** [GitHub](https://github.com/rivaas-dev/rivaas/tree/main/config)

## Package Overview

The config package provides powerful configuration management for Go applications with support for multiple sources, formats, and validation strategies.

### Core Features

- Multiple configuration sources (files, environment variables, remote sources)
- Format-agnostic with built-in JSON, YAML, and TOML support
- Hierarchical configuration merging
- Automatic struct binding with type safety
- Multiple validation strategies
- Thread-safe operations
- Nil-safe getter methods

## Architecture

The package is organized into several key components:

### Main Package (`rivaas.dev/config`)

Core configuration management including:
- `Config` struct - Main configuration container
- `New()` / `MustNew()` - Configuration initialization
- Getter methods - Type-safe value retrieval
- `Load()` / `Dump()` - Loading and saving configuration

### Sub-packages

- **`codec`** - Format encoding/decoding (JSON, YAML, TOML, etc.)
- **`source`** - Configuration sources (file, environment, Consul, etc.)
- **`dumper`** - Configuration output destinations

## Quick API Index

### Configuration Creation

```go
cfg, err := config.New(options...)     // With error handling
cfg := config.MustNew(options...)      // Panics on error
```

### Loading Configuration

```go
err := cfg.Load(ctx context.Context)
```

### Accessing Values

```go
// Direct access (returns zero values for missing keys)
value := cfg.String("key")
value := cfg.Int("key")
value := cfg.Bool("key")

// With defaults
value := cfg.StringOr("key", "default")
value := cfg.IntOr("key", 8080)

// With error handling
value, err := config.GetE[Type](cfg, "key")
```

### Dumping Configuration

```go
err := cfg.Dump(ctx context.Context)
```

## Reference Pages

### [API Reference](api-reference/)

Complete documentation of the Config struct and all methods including:
- Configuration lifecycle methods
- All getter method signatures
- Error types and handling
- Nil-safety guarantees

### [Options](options/)

Comprehensive list of all configuration options:
- Source options (`WithFile`, `WithEnv`, `WithConsul`, etc.)
- Validation options (`WithBinding`, `WithValidator`, `WithJSONSchema`)
- Dumper options (`WithFileDumper`, `WithDumper`)

### [Codecs](codecs/)

Built-in and custom codec documentation:
- Format codecs (JSON, YAML, TOML, EnvVar)
- Caster codecs (Int, Bool, Duration, Time, etc.)
- Creating custom codecs
- File extension auto-detection

### [Troubleshooting](troubleshooting/)

Common issues and solutions:
- Configuration not loading
- Struct not populating
- Environment variable mapping
- Performance considerations
- Thread-safety information

## Type Reference

### Config

```go
type Config struct {
    // contains filtered or unexported fields
}
```

Main configuration container. Thread-safe for concurrent access.

### ConfigError

```go
type ConfigError struct {
    Source    string // Where the error occurred
    Field     string // Specific field with error
    Operation string // Operation being performed
    Err       error  // Underlying error
}
```

Error type for configuration operations with detailed context.

### Option

```go
type Option func(*Config) error
```

Configuration option function type used with `New()` and `MustNew()`.

## Common Patterns

### Basic Usage

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
)
cfg.Load(context.Background())

port := cfg.Int("server.port")
```

### With Struct Binding

```go
type AppConfig struct {
    Server struct {
        Port int `config:"port"`
    } `config:"server"`
}

var appConfig AppConfig
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithBinding(&appConfig),
)
cfg.Load(context.Background())
```

### With Validation

```go
func (c *AppConfig) Validate() error {
    if c.Server.Port <= 0 {
        return errors.New("port must be positive")
    }
    return nil
}

cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithBinding(&appConfig),  // Validation runs after binding
)
```

## Thread Safety

The `Config` type is thread-safe for:
- Concurrent `Load()` operations
- Concurrent getter operations
- Mixed `Load()` and getter operations

Not thread-safe for:
- Concurrent modification of the same configuration instance during initialization

## Performance Notes

- **Getter methods** are O(1) for simple keys, O(n) for nested dot notation paths
- **Load** performance depends on source count and data size
- **Struct binding** uses reflection, minimal overhead for most applications
- **Validation** overhead depends on validation complexity

## Version Compatibility

The config package follows semantic versioning. The API is stable for the v1 series.

**Minimum Go version:** 1.25

## Next Steps

- Read the [API Reference](api-reference/) for detailed method documentation
- Explore [Options](options/) for all available configuration options
- Check [Codecs](codecs/) for format support details
- Review [Troubleshooting](troubleshooting/) for common issues

For learning-focused guides, see the [Configuration Guide](/guides/config/).
