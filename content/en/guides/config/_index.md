---
title: "Configuration Management"
linkTitle: "Config"
description: "Learn how to manage application configuration with the Rivaas config package"
weight: 5
no_list: true
keywords:
  - config
  - configuration
  - twelve-factor
  - environment variables
  - config management
---

{{% pageinfo %}}
The Rivaas Config package provides configuration management for Go applications. It simplifies handling settings across different environments and formats. Follows the [Twelve-Factor App methodology](https://12factor.net/).
{{% /pageinfo %}}

## Features

- **Easy Integration**: Simple and intuitive API
- **Flexible Sources**: Load from files, environment variables (with custom prefixes), Consul, and easily extend with custom sources
- **Dynamic Paths**: Use `${VAR}` in file and Consul paths for environment-based configuration
- **Format Agnostic**: Supports JSON, YAML, TOML, and other formats via extensible codecs
- **Type Casting**: Built-in caster codecs for automatic type conversion (bool, int, float, time, duration, etc.)
- **Hierarchical Merging**: Configurations from multiple sources are merged, with later sources overriding earlier ones
- **Struct Binding**: Automatically map configuration data to Go structs
- **Built-in Validation**: Validate configuration using struct methods, JSON Schemas, or custom functions
- **Dot Notation Access**: Navigate nested configuration easily (e.g., `cfg.String("database.host")`)
- **Type-Safe Retrieval**: Get values as specific types (`string`, `int`, `bool`, etc.), with error-returning options for robust handling
- **Configuration Dumping**: Save the effective configuration to files or other custom destinations
- **Thread-Safe**: Safe for concurrent access and configuration loading in multi-goroutine applications
- **Nil-Safe Operations**: All getter methods handle nil Config instances gracefully

## Quick Start

Here's a 30-second example to get you started:

```go
package main

import (
    "rivaas.dev/config"
    "context"
    "log"
)

func main() {
    // Create config with multiple sources
    cfg := config.MustNew(
        config.WithFile("config.yaml"),   // Auto-detects YAML format
        config.WithFile("config.json"),   // Auto-detects JSON format
        config.WithEnv("APP_"),           // Load environment variables with APP_ prefix
    )

    if err := cfg.Load(context.Background()); err != nil {
        log.Fatalf("failed to load configuration: %v", err)
    }

    // Access configuration values - simple and clean!
    port := cfg.Int("server.port")
    host := cfg.StringOr("server.host", "localhost")  // With default value
    debug := cfg.Bool("debug")
    
    log.Printf("Server running on %s:%d (debug: %v)", host, port, debug)
}
```

### How It Works

- **Sources** are loaded in order; later sources override earlier ones
- **Dot notation** allows deep access: `cfg.Get("database.host")`
- **Type-safe accessors**: `String`, `Int`, `Bool`, etc., plus generic `Get[T]`, `GetOr[T]`, `GetE[T]` for custom types
- **Context validation**: Both `Load()` and `Dump()` methods validate that context is not nil
- **Error handling**: All methods return descriptive errors for easier debugging

## Learning Path

Follow these guides to master configuration management with Rivaas:

1. [**Installation**](installation/) - Get started with the config package
2. [**Basic Usage**](basic-usage/) - Learn the fundamentals of loading and accessing configuration
3. [**Environment Variables**](environment-variables/) - Master environment variable integration
4. [**Struct Binding**](struct-binding/) - Map configuration to Go structs automatically
5. [**Validation**](validation/) - Ensure configuration correctness with validation
6. [**Multiple Sources**](multiple-sources/) - Combine configuration from different sources
7. [**Custom Codecs**](custom-codecs/) - Extend support to custom formats
8. [**Examples**](examples/) - See real-world usage patterns

## Next Steps

- Start with [Installation](installation/) to set up the config package
- Explore the [API Reference](/reference/packages/config/) for complete technical details
- Check out [code examples on GitHub](https://github.com/rivaas-dev/rivaas/tree/main/config/examples/)
