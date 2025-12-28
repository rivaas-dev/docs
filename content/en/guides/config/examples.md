---
title: "Examples"
description: "Real-world examples and production-ready patterns for configuration management"
weight: 9
---

Learn from practical examples that demonstrate different configuration patterns and use cases.

## Example Repository

All examples are available in the [GitHub repository](https://github.com/rivaas-dev/rivaas/tree/main/config/examples/) with complete, runnable code.

## Example Overview

### 1. Basic Configuration

**Path:** [`config/examples/basic/`](https://github.com/rivaas-dev/rivaas/tree/main/config/examples/basic)

A simple example showing the most basic usage - loading configuration from a YAML file into a Go struct.

**Features:**
- File source (YAML)
- Struct binding
- Type conversion
- Nested structures
- Arrays and slices
- Time and URL types

**Best for:** Getting started, understanding basic concepts

**Quick start:**

```bash
cd config/examples/basic
go run main.go
```

### 2. Environment Variables

**Path:** [`config/examples/environment/`](https://github.com/rivaas-dev/rivaas/tree/main/config/examples/environment)

Demonstrates loading configuration from environment variables, following the Twelve-Factor App methodology.

**Features:**
- Environment variable source
- Struct binding
- Nested configuration
- Direct access methods
- Type conversion

**Best for:** Containerized applications, cloud deployments, 12-factor apps

**Quick start:**

```bash
cd config/examples/environment
export WEBAPP_SERVER_HOST=localhost
export WEBAPP_SERVER_PORT=8080
go run main.go
```

### 3. Mixed Configuration

**Path:** [`config/examples/mixed/`](https://github.com/rivaas-dev/rivaas/tree/main/config/examples/mixed)

Shows how to combine YAML files and environment variables, with environment variables overriding YAML defaults.

**Features:**
- Mixed configuration sources
- Configuration precedence
- Environment variable mapping
- Struct binding
- Direct access

**Best for:** Applications that need both default configuration files and environment-specific overrides

**Quick start:**

```bash
cd config/examples/mixed
export WEBAPP_SERVER_PORT=8080  # Override YAML default
go run main.go
```

### 4. Comprehensive Example

**Path:** [`config/examples/comprehensive/`](https://github.com/rivaas-dev/rivaas/tree/main/config/examples/comprehensive)

A complete example demonstrating advanced features with a realistic web application configuration.

**Features:**
- Mixed configuration sources
- Complex nested structures
- Validation
- Comprehensive testing
- Production-ready patterns

**Best for:** Production applications, learning advanced features, understanding best practices

**Quick start:**

```bash
cd config/examples/comprehensive
go test -v
go run main.go
```

## Production Configuration Example

Here's a complete production-ready configuration pattern:

```go
package main

import (
    "context"
    "errors"
    "fmt"
    "log"
    "os"
    "time"
    "rivaas.dev/config"
)

type AppConfig struct {
    Server struct {
        Host         string        `config:"host" default:"localhost"`
        Port         int           `config:"port" default:"8080"`
        ReadTimeout  time.Duration `config:"read_timeout" default:"30s"`
        WriteTimeout time.Duration `config:"write_timeout" default:"30s"`
        TLS          struct {
            Enabled  bool   `config:"enabled" default:"false"`
            CertFile string `config:"cert_file"`
            KeyFile  string `config:"key_file"`
        } `config:"tls"`
    } `config:"server"`
    
    Database struct {
        Primary struct {
            Host     string `config:"host"`
            Port     int    `config:"port" default:"5432"`
            Database string `config:"database"`
            Username string `config:"username"`
            Password string `config:"password"`
            SSLMode  string `config:"ssl_mode" default:"require"`
        } `config:"primary"`
        Replica struct {
            Host     string `config:"host"`
            Port     int    `config:"port" default:"5432"`
            Database string `config:"database"`
        } `config:"replica"`
        Pool struct {
            MaxOpenConns    int           `config:"max_open_conns" default:"25"`
            MaxIdleConns    int           `config:"max_idle_conns" default:"5"`
            ConnMaxLifetime time.Duration `config:"conn_max_lifetime" default:"5m"`
        } `config:"pool"`
    } `config:"database"`
    
    Redis struct {
        Host     string        `config:"host" default:"localhost"`
        Port     int           `config:"port" default:"6379"`
        Database int           `config:"database" default:"0"`
        Password string        `config:"password"`
        Timeout  time.Duration `config:"timeout" default:"5s"`
    } `config:"redis"`
    
    Auth struct {
        JWTSecret       string        `config:"jwt_secret"`
        TokenDuration   time.Duration `config:"token_duration" default:"24h"`
    } `config:"auth"`
    
    Logging struct {
        Level  string `config:"level" default:"info"`
        Format string `config:"format" default:"json"`
        Output string `config:"output" default:"/var/log/app.log"`
    } `config:"logging"`
    
    Monitoring struct {
        Enabled     bool   `config:"enabled" default:"true"`
        MetricsPort int    `config:"metrics_port" default:"9090"`
        HealthPath  string `config:"health_path" default:"/health"`
    } `config:"monitoring"`
    
    Features struct {
        RateLimit bool `config:"rate_limit" default:"true"`
        Cache     bool `config:"cache" default:"true"`
        DebugMode bool `config:"debug_mode" default:"false"`
    } `config:"features"`
}

func (c *AppConfig) Validate() error {
    // Server validation
    if c.Server.Port < 1 || c.Server.Port > 65535 {
        return fmt.Errorf("server.port must be 1-65535, got %d", c.Server.Port)
    }
    
    // TLS validation
    if c.Server.TLS.Enabled {
        if c.Server.TLS.CertFile == "" {
            return errors.New("server.tls.cert_file required when TLS enabled")
        }
        if c.Server.TLS.KeyFile == "" {
            return errors.New("server.tls.key_file required when TLS enabled")
        }
    }
    
    // Database validation
    if c.Database.Primary.Host == "" {
        return errors.New("database.primary.host is required")
    }
    if c.Database.Primary.Database == "" {
        return errors.New("database.primary.database is required")
    }
    if c.Database.Primary.Username == "" {
        return errors.New("database.primary.username is required")
    }
    if c.Database.Primary.Password == "" {
        return errors.New("database.primary.password is required")
    }
    
    // Auth validation
    if c.Auth.JWTSecret == "" {
        return errors.New("auth.jwt_secret is required")
    }
    if len(c.Auth.JWTSecret) < 32 {
        return errors.New("auth.jwt_secret must be at least 32 characters")
    }
    
    return nil
}

func loadConfig() (*AppConfig, error) {
    var appConfig AppConfig
    
    // Determine environment
    env := os.Getenv("APP_ENV")
    if env == "" {
        env = "development"
    }
    
    cfg := config.MustNew(
        // Base configuration
        config.WithFile("config.yaml"),
        
        // Environment-specific configuration
        config.WithFile(fmt.Sprintf("config.%s.yaml", env)),
        
        // Environment variables (highest priority)
        config.WithEnv("MYAPP_"),
        
        // Struct binding with validation
        config.WithBinding(&appConfig),
    )
    
    if err := cfg.Load(context.Background()); err != nil {
        return nil, fmt.Errorf("failed to load configuration: %w", err)
    }
    
    return &appConfig, nil
}

func main() {
    appConfig, err := loadConfig()
    if err != nil {
        log.Fatalf("Configuration error: %v", err)
    }
    
    log.Printf("Server: %s:%d", appConfig.Server.Host, appConfig.Server.Port)
    log.Printf("Database: %s:%d/%s", 
        appConfig.Database.Primary.Host,
        appConfig.Database.Primary.Port,
        appConfig.Database.Primary.Database)
    log.Printf("Redis: %s:%d", appConfig.Redis.Host, appConfig.Redis.Port)
    log.Printf("Features: RateLimit=%v, Cache=%v, Debug=%v",
        appConfig.Features.RateLimit,
        appConfig.Features.Cache,
        appConfig.Features.DebugMode)
}
```

## Multi-Environment Setup

Organize configuration for different environments:

**File structure:**

```
config/
├── config.yaml              # Base configuration (shared defaults)
├── config.development.yaml  # Development overrides
├── config.staging.yaml      # Staging overrides
├── config.production.yaml   # Production overrides
└── config.test.yaml         # Test overrides
```

**config.yaml (base):**

```yaml
server:
  host: localhost
  port: 8080
  read_timeout: 30s
  write_timeout: 30s

database:
  pool:
    max_open_conns: 25
    max_idle_conns: 5
    conn_max_lifetime: 5m

logging:
  level: info
  format: json
```

**config.production.yaml:**

```yaml
server:
  host: 0.0.0.0
  port: 443
  tls:
    enabled: true
    cert_file: /etc/ssl/certs/server.crt
    key_file: /etc/ssl/private/server.key

database:
  primary:
    host: db.prod.example.com
    ssl_mode: require
  replica:
    host: db-replica.prod.example.com

logging:
  level: warn
  output: /var/log/production/app.log

features:
  debug_mode: false
```

**config.development.yaml:**

```yaml
server:
  host: localhost
  port: 3000

database:
  primary:
    host: localhost
    ssl_mode: disable

logging:
  level: debug
  format: text
  output: stdout

features:
  debug_mode: true
```

## Integration with Rivaas App

Integrate configuration with the rivaas/app framework:

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
    "rivaas.dev/config"
)

type AppConfig struct {
    Server struct {
        Host string `config:"host" default:"localhost"`
        Port int    `config:"port" default:"8080"`
    } `config:"server"`
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
    
    // Create rivaas/app with configuration
    a := app.MustNew(
        app.WithServiceName("myapp"),
        app.WithServiceVersion("v1.0.0"),
    )
    
    // Define routes
    a.GET("/", func(c *app.Context) {
        c.JSON(200, map[string]string{"status": "ok"})
    })
    
    // Setup graceful shutdown
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()
    
    // Start server with configured address
    addr := fmt.Sprintf("%s:%d", appConfig.Server.Host, appConfig.Server.Port)
    log.Printf("Starting server on http://%s\n", addr)
    
    if err := a.Start(ctx, addr); err != nil {
        log.Fatalf("server error: %v", err)
    }
}
```

## Testing Configuration

Example test patterns:

```go
package main

import (
    "context"
    "testing"
    "rivaas.dev/config"
    "rivaas.dev/config/codec"
)

func TestConfigLoading(t *testing.T) {
    testConfig := []byte(`
server:
  host: localhost
  port: 8080
database:
  primary:
    host: localhost
    database: testdb
    username: test
    password: test123
`)
    
    var appConfig AppConfig
    
    cfg := config.MustNew(
        config.WithContentSource(testConfig, codec.TypeYAML),
        config.WithBinding(&appConfig),
    )
    
    if err := cfg.Load(context.Background()); err != nil {
        t.Fatalf("failed to load config: %v", err)
    }
    
    // Assertions
    if appConfig.Server.Host != "localhost" {
        t.Errorf("expected localhost, got %s", appConfig.Server.Host)
    }
    if appConfig.Server.Port != 8080 {
        t.Errorf("expected 8080, got %d", appConfig.Server.Port)
    }
}

func TestConfigValidation(t *testing.T) {
    invalidConfig := []byte(`
server:
  host: localhost
  port: 99999  # Invalid port
`)
    
    var appConfig AppConfig
    
    cfg := config.MustNew(
        config.WithContentSource(invalidConfig, codec.TypeYAML),
        config.WithBinding(&appConfig),
    )
    
    err := cfg.Load(context.Background())
    if err == nil {
        t.Error("expected validation error, got nil")
    }
}
```

## Common Patterns

### Pattern 1: Secrets from Environment

Keep secrets out of config files:

```yaml
# config.yaml - No secrets
database:
  primary:
    host: localhost
    port: 5432
    database: myapp
    # username and password from environment
```

```bash
# Environment variables for secrets
export MYAPP_DATABASE_PRIMARY_USERNAME=admin
export MYAPP_DATABASE_PRIMARY_PASSWORD=secret123
```

### Pattern 2: Feature Flags

Use configuration for feature flags:

```go
type Config struct {
    Features struct {
        NewUI        bool `config:"new_ui" default:"false"`
        BetaFeatures bool `config:"beta_features" default:"false"`
        Analytics    bool `config:"analytics" default:"true"`
    } `config:"features"`
}

// In application code
if appConfig.Features.NewUI {
    // Use new UI
} else {
    // Use old UI
}
```

### Pattern 3: Dynamic Reloading

For applications that need dynamic configuration updates (advanced):

```go
type ConfigManager struct {
    cfg    *config.Config
    appCfg *AppConfig
    mu     sync.RWMutex
}

func (cm *ConfigManager) Reload(ctx context.Context) error {
    cm.mu.Lock()
    defer cm.mu.Unlock()
    
    return cm.cfg.Load(ctx)
}

func (cm *ConfigManager) Get() *AppConfig {
    cm.mu.RLock()
    defer cm.mu.RUnlock()
    
    return cm.appCfg
}
```

## Next Steps

- Explore the [GitHub examples](https://github.com/rivaas-dev/rivaas/tree/main/config/examples/) with full code
- Review the [API Reference](/reference/packages/config/) for technical details
- Check [Troubleshooting](/reference/packages/config/troubleshooting/) for common issues

For questions or contributions, visit the [GitHub repository](https://github.com/rivaas-dev/rivaas).
