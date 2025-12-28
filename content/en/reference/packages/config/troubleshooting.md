---
title: "Troubleshooting"
description: "Common issues, solutions, and frequently asked questions"
weight: 5
---

Solutions to common problems and frequently asked questions about the config package.

## Configuration Loading Issues

### File Not Found

**Problem:** Configuration file cannot be found.

```
config error in source[0] during load: open config.yaml: no such file or directory
```

**Solutions:**

1. **Check file path**: Ensure the path is correct relative to where your application runs

```go
// Use absolute path if needed
cfg := config.MustNew(
    config.WithFile("/absolute/path/to/config.yaml"),
)
```

2. **Check working directory**: Verify your application's working directory

```go
wd, _ := os.Getwd()
fmt.Printf("Working directory: %s\n", wd)
```

3. **Make file optional**: Handle missing files gracefully

```go
cfg, err := config.New(
    config.WithFile("config.yaml"),
)
if err != nil {
    log.Printf("Config file not found, using defaults: %v", err)
    // Use defaults
}
```

### Format Not Recognized

**Problem:** File extension doesn't match a known format.

```
config error in source[0] during load: no decoder registered for extension .conf
```

**Solutions:**

1. **Use explicit format**:

```go
cfg := config.MustNew(
    config.WithFileAs("config.conf", codec.TypeYAML),
)
```

2. **Register custom codec**:

```go
import _ "yourmodule/mycodec"  // Registers .conf format
```

### Parse Errors

**Problem:** Configuration file has syntax errors.

```
config error in source[0] during load: yaml: unmarshal error
```

**Solutions:**

1. **Validate YAML/JSON syntax**: Use online validators or linters
2. **Check indentation**: YAML is indentation-sensitive
3. **Quote strings**: Quote values with special characters

```yaml
# Bad
url: http://example.com:8080

# Good
url: "http://example.com:8080"
```

## Struct Binding Issues

### Struct Not Populating

**Problem:** Struct fields remain at zero values after loading.

**Solutions:**

1. **Pass pointer to struct**:

```go
// Wrong
cfg := config.MustNew(config.WithBinding(myConfig))

// Correct
cfg := config.MustNew(config.WithBinding(&myConfig))
```

2. **Check struct tags**:

```go
// Config file: server.port = 8080
type Config struct {
    // Wrong - doesn't match config structure
    Port int `config:"port"`
    
    // Correct - matches nested structure
    Server struct {
        Port int `config:"port"`
    } `config:"server"`
}
```

3. **Verify tag names match config keys**:

```yaml
# config.yaml
server:
  host: localhost
  port: 8080
```

```go
type Config struct {
    Server struct {
        Host string `config:"host"`  // Must match "host" in YAML
        Port int    `config:"port"`  // Must match "port" in YAML
    } `config:"server"`  // Must match "server" in YAML
}
```

4. **Export struct fields**: Fields must be exported (start with uppercase)

```go
// Wrong - unexported fields won't be populated
type Config struct {
    port int `config:"port"`
}

// Correct - exported field
type Config struct {
    Port int `config:"port"`
}
```

### Type Mismatch Errors

**Problem:** Configuration value type doesn't match struct field type.

**Solutions:**

1. **Use compatible types**: Ensure types can be converted

```yaml
# config.yaml
port: "8080"  # String
```

```go
type Config struct {
    Port int `config:"port"`  // Will be converted from string
}
```

2. **Check slice vs scalar**: Don't mix slice and scalar values

```yaml
# Wrong - port is an array but struct expects int
ports:
  - 8080
  - 8081
```

```go
type Config struct {
    Ports []int `config:"ports"`  // Correct - expects slice
}
```

### Validation Errors

**Problem:** Struct validation fails.

```
config error in binding during validate: port must be positive
```

**Solutions:**

1. **Check validation logic**:

```go
func (c *Config) Validate() error {
    if c.Port <= 0 {
        return fmt.Errorf("port must be positive, got %d", c.Port)
    }
    return nil
}
```

2. **Provide helpful error messages**: Include the actual value in error

3. **Check validation order**: Validation runs after binding

## Environment Variable Issues

### Environment Variables Not Loading

**Problem:** Environment variables are not being picked up.

**Solutions:**

1. **Check prefix**: Ensure environment variables have the correct prefix

```bash
# Wrong - missing prefix
export SERVER_PORT=8080

# Correct - with MYAPP_ prefix
export MYAPP_SERVER_PORT=8080
```

```go
cfg := config.MustNew(
    config.WithEnv("MYAPP_"),  // Must match prefix
)
```

2. **Verify environment variables are set**:

```bash
env | grep MYAPP_
```

3. **Check variable names**: Use underscores for nesting

```bash
# Maps to server.port
export MYAPP_SERVER_PORT=8080

# Maps to database.primary.host
export MYAPP_DATABASE_PRIMARY_HOST=localhost
```

### Environment Variable Mapping Issues

**Problem:** Environment variables aren't mapping to the right config keys.

**Solutions:**

1. **Understand naming convention**:

| Environment Variable | Config Path |
|---------------------|-------------|
| `MYAPP_SERVER_PORT` | `server.port` |
| `MYAPP_FOO_BAR_BAZ` | `foo.bar.baz` |
| `MYAPP_FOO__BAR` | `foo.bar` (double underscore) |

2. **Check case sensitivity**: Environment variables are converted to lowercase

```bash
export MYAPP_SERVER_PORT=8080  # Becomes: server.port
```

3. **Test mapping**:

```go
cfg := config.MustNew(
    config.WithEnv("MYAPP_"),
)
cfg.Load(context.Background())

// Print effective configuration
values := cfg.Values()
fmt.Printf("Config: %+v\n", *values)
```

### Type Conflicts

**Problem:** Environment variable creates conflict between scalar and nested.

```bash
export MYAPP_FOO=scalar
export MYAPP_FOO_BAR=nested
```

**Solution:** Nested structures take precedence. Result is `foo.bar = "nested"`, scalar `foo` is overwritten.

**Best practice:** Don't create such conflicts; structure your configuration hierarchically.

## Validation Issues

### Schema Validation Failures

**Problem:** JSON Schema validation fails.

```
config error in json-schema during validate: server.port: must be >= 1
```

**Solutions:**

1. **Check schema requirements**: Ensure configuration meets schema constraints

2. **Debug with schema validator**: Use online JSON Schema validators

3. **Provide all required fields**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "required": ["server", "database"]
}
```

### Custom Validation Errors

**Problem:** Custom validation function fails.

**Solutions:**

1. **Add detailed error messages**:

```go
config.WithValidator(func(data map[string]any) error {
    port, ok := data["port"].(int)
    if !ok {
        return fmt.Errorf("port must be an integer, got %T", data["port"])
    }
    if port < 1 || port > 65535 {
        return fmt.Errorf("port must be 1-65535, got %d", port)
    }
    return nil
})
```

2. **Check data types**: Values in map might not be expected type

```go
// Type assertion with check
if port, ok := data["port"].(int); ok {
    // Use port
}
```

## Performance Issues

### Slow Configuration Loading

**Problem:** Configuration loading takes too long.

**Solutions:**

1. **Reduce source count**: Combine configuration files when possible

2. **Avoid remote sources in hot paths**: Cache remote configuration

3. **Profile loading**:

```go
start := time.Now()
err := cfg.Load(context.Background())
log.Printf("Config load time: %v", time.Since(start))
```

4. **Load once**: Load configuration during initialization, not per-request

### Memory Usage

**Problem:** High memory usage.

**Solutions:**

1. **Don't keep multiple Config instances**: Reuse single instance

2. **Clear unnecessary dumpers**: Only use dumpers when needed

```go
// Development only
if debug {
    cfg = config.MustNew(
        config.WithFile("config.yaml"),
        config.WithFileDumper("debug-config.yaml"),
    )
}
```

## Common Misconceptions

### Q: Why don't changes to config files take effect?

**A:** Configuration is loaded once during `Load()`. It's not automatically reloaded when files change.

**Solution:** Reload configuration explicitly:

```go
// Reload configuration
if err := cfg.Load(context.Background()); err != nil {
    log.Printf("Failed to reload: %v", err)
}
```

### Q: Why does my config work locally but not in Docker?

**A:** Likely a path or working directory issue.

**Solutions:**

1. **Use absolute paths** in Docker:

```go
cfg := config.MustNew(
    config.WithFile("/app/config/config.yaml"),
)
```

2. **Set working directory** in Dockerfile:

```dockerfile
WORKDIR /app
COPY config.yaml .
```

3. **Use environment variables** for container configuration:

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),     // Defaults
    config.WithEnv("APP_"),             // Override in container
)
```

### Q: Can I modify configuration at runtime?

**A:** The Config instance is read-only after loading. You need to reload to pick up changes.

**Pattern for dynamic updates:**

```go
type ConfigManager struct {
    cfg *config.Config
    mu  sync.RWMutex
}

func (cm *ConfigManager) Reload(ctx context.Context) error {
    cm.mu.Lock()
    defer cm.mu.Unlock()
    return cm.cfg.Load(ctx)
}

func (cm *ConfigManager) Get(key string) any {
    cm.mu.RLock()
    defer cm.mu.RUnlock()
    return cm.cfg.Get(key)
}
```

## FAQ

### Q: Is Config thread-safe?

**A:** Yes, `Load()` and all getter methods are thread-safe.

### Q: What happens with nil Config instances?

**A:** Getter methods return zero values, error methods return errors. No panics.

### Q: Can I load from multiple sources?

**A:** Yes, sources are merged with later sources overriding earlier ones.

### Q: How do I handle secrets?

**A:** 
1. Use environment variables for secrets (not config files)
2. Use secret management systems (Vault, AWS Secrets Manager)
3. Never commit secrets to version control

### Q: Can I use the same struct tags for JSON and config?

**A:** Yes, using `WithTag()`:

```go
type Config struct {
    Port int `json:"port"`
}

cfg := config.MustNew(
    config.WithTag("json"),
    config.WithBinding(&myConfig),
)
```

### Q: How do I debug configuration loading?

**A:**
1. Use `WithFileDumper()` to see merged config
2. Print values after loading
3. Check error messages for source context

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
    config.WithFileDumper("debug-config.yaml"),
)

if err := cfg.Load(context.Background()); err != nil {
    log.Printf("Load error: %v", err)
}

cfg.Dump(context.Background())  // Writes to debug-config.yaml

values := cfg.Values()
fmt.Printf("Loaded config: %+v\n", *values)
```

### Q: What's the difference between Get, GetE, and GetOr?

**A:**
- `Get[T]()` - Returns value or zero value (no error)
- `GetE[T]()` - Returns value and error
- `GetOr[T]()` - Returns value or provided default

### Q: Can I use config without struct binding?

**A:** Yes, use getter methods directly:

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
)
cfg.Load(context.Background())

port := cfg.Int("server.port")
host := cfg.String("server.host")
```

### Q: How do I validate required fields?

**A:** Use struct validation:

```go
func (c *Config) Validate() error {
    if c.Database.Host == "" {
        return errors.New("database.host is required")
    }
    return nil
}
```

## Performance Notes

**Configuration access:**
- Getter methods: O(n) where n = dot notation depth
- Direct `Get()`: O(n)
- No caching of individual keys

**Best practices:**
- Load configuration once at startup
- Cache frequently accessed values in local variables
- Use struct binding for best performance

**Thread safety overhead:**
- Minimal locking overhead
- Read operations are concurrent
- Write operations (Load) use exclusive lock

## Getting Help

If you encounter issues not covered here:

1. Check the [Configuration Guide](/guides/config/)
2. Review [API Reference](../api-reference/)
3. Search [GitHub Issues](https://github.com/rivaas-dev/rivaas/issues)
4. Ask in the community forums

When reporting issues, include:
- Go version
- Config package version
- Minimal reproducible example
- Error messages
- Expected vs actual behavior
