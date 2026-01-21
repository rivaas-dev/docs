---
title: "Struct Binding"
description: "Automatically map configuration data to Go structs with type safety"
weight: 5
keywords:
  - config struct binding
  - unmarshal
  - type-safe config
  - struct mapping
---

Struct binding allows you to automatically map configuration data to your own Go structs. This provides type safety and a clean, idiomatic way to work with configuration.

## Basic Struct Binding

Define a struct and bind it during configuration initialization:

```go
type Config struct {
    Port int    `config:"port"`
    Host string `config:"host"`
}

var c Config
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithBinding(&c),
)

if err := cfg.Load(context.Background()); err != nil {
    log.Fatalf("failed to load config: %v", err)
}

// c.Port and c.Host are now populated
log.Printf("Server: %s:%d", c.Host, c.Port)
```

{{< alert title="Important" color="warning" >}}
Always pass a **pointer** to your struct with `WithBinding(&c)`, not the struct value itself.
{{< /alert >}}

## Config Tags

Use the `config` tag to specify the configuration key for each field:

```go
type Config struct {
    Port    int    `config:"port"`
    Host    string `config:"host"`
    Timeout int    `config:"timeout"`
}
```

The tag value should match the key name at that struct's level in the configuration hierarchy.

### Tag Naming

- Tags are case-sensitive.
- Use snake_case or lowercase for consistency.
- Match the structure of your configuration files.

```yaml
# config.yaml
port: 8080
host: localhost
timeout: 30
```

## Default Values

Specify default values using the `default` tag:

```go
type Config struct {
    Port    int           `config:"port" default:"8080"`
    Host    string        `config:"host" default:"localhost"`
    Debug   bool          `config:"debug" default:"false"`
    Timeout time.Duration `config:"timeout" default:"30s"`
}
```

Default values are used when:
- The configuration key is not found.
- The configuration file doesn't exist.
- Environment variables don't provide the value.

```go
var c Config
cfg := config.MustNew(
    config.WithFile("config.yaml"),  // May not exist or be incomplete
    config.WithBinding(&c),
)

cfg.Load(context.Background())
// Fields use defaults if not present in config.yaml
```

## Nested Structs

Create hierarchical configuration by nesting structs:

```go
type Config struct {
    Server struct {
        Host string `config:"host"`
        Port int    `config:"port"`
    } `config:"server"`
    
    Database struct {
        Host     string `config:"host"`
        Port     int    `config:"port"`
        Username string `config:"username"`
        Password string `config:"password"`
    } `config:"database"`
}
```

**Corresponding YAML:**

```yaml
server:
  host: localhost
  port: 8080

database:
  host: db.example.com
  port: 5432
  username: admin
  password: secret
```

**Usage:**

```go
var c Config
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithBinding(&c),
)

cfg.Load(context.Background())

log.Printf("Server: %s:%d", c.Server.Host, c.Server.Port)
log.Printf("Database: %s:%d", c.Database.Host, c.Database.Port)
```

## Pointer Fields for Optional Values

Use pointer fields when values are truly optional:

```go
type Config struct {
    Port     int     `config:"port"`
    Host     string  `config:"host"`
    CacheURL *string `config:"cache_url"`  // Optional
    Debug    *bool   `config:"debug"`       // Optional
}
```

If the configuration key is missing, pointer fields remain `nil`:

```go
var c Config
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithBinding(&c),
)

cfg.Load(context.Background())

if c.CacheURL != nil {
    log.Printf("Using cache: %s", *c.CacheURL)
} else {
    log.Printf("Cache disabled")
}
```

## Deeply Nested Structures

For complex applications, create deeply nested configuration:

```go
type AppConfig struct {
    Server struct {
        HTTP struct {
            Host string `config:"host"`
            Port int    `config:"port"`
        } `config:"http"`
        TLS struct {
            Enabled  bool   `config:"enabled"`
            CertFile string `config:"cert_file"`
            KeyFile  string `config:"key_file"`
        } `config:"tls"`
    } `config:"server"`
    
    Database struct {
        Primary struct {
            Host     string `config:"host"`
            Port     int    `config:"port"`
            Database string `config:"database"`
        } `config:"primary"`
        Replica struct {
            Host     string `config:"host"`
            Port     int    `config:"port"`
            Database string `config:"database"`
        } `config:"replica"`
    } `config:"database"`
}
```

**Corresponding YAML:**

```yaml
server:
  http:
    host: 0.0.0.0
    port: 8080
  tls:
    enabled: true
    cert_file: /etc/ssl/certs/server.crt
    key_file: /etc/ssl/private/server.key

database:
  primary:
    host: primary.db.example.com
    port: 5432
    database: myapp
  replica:
    host: replica.db.example.com
    port: 5432
    database: myapp
```

## Slices and Maps

Bind slices and maps for collection data:

```go
type Config struct {
    Hosts    []string          `config:"hosts"`
    Ports    []int             `config:"ports"`
    Metadata map[string]string `config:"metadata"`
    Features map[string]bool   `config:"features"`
}
```

**YAML:**

```yaml
hosts:
  - localhost
  - example.com
  - api.example.com

ports:
  - 8080
  - 8081
  - 8082

metadata:
  version: "1.0.0"
  environment: production

features:
  auth: true
  cache: true
  debug: false
```

## Type Conversion

The config package automatically converts between compatible types:

```go
type Config struct {
    Port    int           `config:"port"`     // Converts from string "8080"
    Debug   bool          `config:"debug"`    // Converts from string "true"
    Timeout time.Duration `config:"timeout"`  // Converts from string "30s"
}
```

**YAML (as strings):**

```yaml
port: "8080"      # String converted to int
debug: "true"     # String converted to bool
timeout: "30s"    # String converted to time.Duration
```

## Common Issues and Solutions

### Issue: Struct Not Populating

**Problem:** Fields remain at zero values after loading.

**Solutions:**

1. **Pass a pointer**: Use `WithBinding(&c)`, not `WithBinding(c)`

```go
// Wrong
cfg := config.MustNew(config.WithBinding(c))

// Correct
cfg := config.MustNew(config.WithBinding(&c))
```

2. **Check tag names**: Ensure `config` tags match your configuration structure

```go
// If your YAML has "server_port", use:
Port int `config:"server_port"`

// Not:
Port int `config:"port"`
```

3. **Verify nested tags**: All nested structs need the `config` tag

```go
// Wrong - missing tag on Server struct
type Config struct {
    Server struct {
        Port int `config:"port"`
    }  // Missing `config:"server"`
}

// Correct
type Config struct {
    Server struct {
        Port int `config:"port"`
    } `config:"server"`
}
```

### Issue: Type Mismatch Errors

**Problem:** Error during binding due to type incompatibility.

**Solution:** Ensure your struct types match the configuration data types or are compatible:

```go
// If YAML has: port: 8080 (number)
Port int `config:"port"`  // Correct

// If YAML has: port: "8080" (string)
Port int `config:"port"`  // Still works - automatic conversion
```

### Issue: Optional Fields Always Present

**Problem:** Want to distinguish between "not set" and "set to zero value".

**Solution:** Use pointer types:

```go
type Config struct {
    // Can't distinguish "not set" vs "set to 0"
    MaxConnections int `config:"max_connections"`
    
    // Can distinguish: nil = not set, &0 = set to 0
    MaxConnections *int `config:"max_connections"`
}
```

## Complete Example

```go
package main

import (
    "context"
    "log"
    "time"
    "rivaas.dev/config"
)

type AppConfig struct {
    Server struct {
        Host    string        `config:"host" default:"localhost"`
        Port    int           `config:"port" default:"8080"`
        Timeout time.Duration `config:"timeout" default:"30s"`
    } `config:"server"`
    
    Database struct {
        Host     string `config:"host"`
        Port     int    `config:"port" default:"5432"`
        Username string `config:"username"`
        Password string `config:"password"`
        MaxConns *int   `config:"max_connections"` // Optional
    } `config:"database"`
    
    Features struct {
        EnableCache bool `config:"enable_cache" default:"true"`
        EnableAuth  bool `config:"enable_auth" default:"true"`
    } `config:"features"`
}

func (c *AppConfig) Validate() error {
    if c.Database.Host == "" {
        return errors.New("database host is required")
    }
    if c.Database.Username == "" {
        return errors.New("database username is required")
    }
    return nil
}

func main() {
    var appConfig AppConfig
    
    cfg := config.MustNew(
        config.WithFile("config.yaml"),
        config.WithEnv("MYAPP_"),
        config.WithBinding(&appConfig),
    )

    if err := cfg.Load(context.Background()); err != nil {
        log.Fatalf("failed to load config: %v", err)
    }

    log.Printf("Server: %s:%d (timeout: %v)",
        appConfig.Server.Host,
        appConfig.Server.Port,
        appConfig.Server.Timeout)
    
    log.Printf("Database: %s:%d",
        appConfig.Database.Host,
        appConfig.Database.Port)
    
    if appConfig.Database.MaxConns != nil {
        log.Printf("Max DB connections: %d", *appConfig.Database.MaxConns)
    }
}
```

**config.yaml:**

```yaml
server:
  host: 0.0.0.0
  port: 8080
  timeout: 60s

database:
  host: postgres.example.com
  port: 5432
  username: myapp
  password: secret123
  max_connections: 100

features:
  enable_cache: true
  enable_auth: true
```

## Next Steps

- Learn about [Validation](../validation/) to validate bound structs
- Explore [Environment Variables](../environment-variables/) for mapping to struct fields
- See [Examples](../examples/) for real-world usage patterns

For technical details, see the [API Reference](/reference/packages/config/api-reference/).
