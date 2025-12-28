---
title: "API Reference"
description: "Complete API documentation for the Config type and methods"
weight: 2
---

Complete API reference for the `Config` struct and all its methods.

## Types

### Config

```go
type Config struct {
    // contains filtered or unexported fields
}
```

Main configuration container. Thread-safe for concurrent read operations and loading.

**Key properties:**
- Thread-safe for concurrent `Load()` and getter operations
- Nil-safe - all getter methods handle nil instances gracefully
- Hierarchical data storage with dot notation support

### ConfigError

```go
type ConfigError struct {
    Source    string // Where the error occurred (e.g., "source[0]", "json-schema")
    Field     string // Specific field with the error (optional)
    Operation string // Operation being performed (e.g., "load", "validate")
    Err       error  // Underlying error
}
```

Error type providing detailed context about configuration errors.

**Example error messages:**
```
config error in source[0] during load: file not found: config.yaml
config error in json-schema during validate: server.port: must be >= 1
config error in binding during bind: failed to decode configuration
```

## Initialization Functions

### New

```go
func New(options ...Option) (*Config, error)
```

Creates a new Config instance with the given options. Returns an error if any option fails.

**Parameters:**
- `options` - Variable number of Option functions

**Returns:**
- `*Config` - Initialized configuration instance
- `error` - Error if initialization fails

**Example:**

```go
cfg, err := config.New(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
)
if err != nil {
    log.Fatalf("failed to create config: %v", err)
}
```

**Use when:** You need explicit error handling (recommended for libraries).

### MustNew

```go
func MustNew(options ...Option) *Config
```

Creates a new Config instance with the given options. Panics if any option fails.

**Parameters:**
- `options` - Variable number of Option functions

**Returns:**
- `*Config` - Initialized configuration instance

**Panics:** If any option returns an error

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
)
```

**Use when:** In `main()` or initialization code where panic is acceptable.

## Lifecycle Methods

### Load

```go
func (c *Config) Load(ctx context.Context) error
```

Loads configuration from all configured sources, merges them, and runs validation.

**Parameters:**
- `ctx` - Context for cancellation and deadlines (must not be nil)

**Returns:**
- `error` - ConfigError if loading, merging, or validation fails

**Behavior:**
1. Loads data from all sources sequentially
2. Merges data hierarchically (later sources override earlier ones)
3. Runs JSON Schema validation (if configured)
4. Runs custom validation functions (if configured)
5. Binds to struct (if configured)
6. Runs struct `Validate()` method (if implemented)

**Example:**

```go
if err := cfg.Load(context.Background()); err != nil {
    log.Fatalf("failed to load config: %v", err)
}
```

**Thread-safety:** Safe for concurrent calls (uses internal locking).

### Dump

```go
func (c *Config) Dump(ctx context.Context) error
```

Writes the current configuration state to all configured dumpers.

**Parameters:**
- `ctx` - Context for cancellation and deadlines (must not be nil)

**Returns:**
- `error` - Error if any dumper fails

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithFileDumper("output.yaml", codec.TypeYAML),
)
cfg.Load(context.Background())
cfg.Dump(context.Background())  // Writes to output.yaml
```

**Use cases:** Debugging, configuration snapshots, generating configuration files.

## Getter Methods

### Get

```go
func (c *Config) Get(key string) any
```

Retrieves the value at the given key path. Returns `nil` for missing keys.

**Parameters:**
- `key` - Dot-separated path (e.g., "server.port")

**Returns:**
- `any` - Value at the key, or `nil` if not found

**Nil-safe:** Returns `nil` if Config instance is nil.

**Example:**

```go
value := cfg.Get("server.port")
if port, ok := value.(int); ok {
    fmt.Printf("Port: %d\n", port)
}
```

### String

```go
func (c *Config) String(key string) string
```

Retrieves a string value at the given key.

**Returns:** Empty string `""` if key not found or on nil instance.

**Example:**

```go
host := cfg.String("server.host")  // "" if missing
```

### Int

```go
func (c *Config) Int(key string) int
```

Retrieves an integer value at the given key.

**Returns:** `0` if key not found or on nil instance.

### Int64

```go
func (c *Config) Int64(key string) int64
```

Retrieves an int64 value at the given key.

**Returns:** `0` if key not found or on nil instance.

### Float64

```go
func (c *Config) Float64(key string) float64
```

Retrieves a float64 value at the given key.

**Returns:** `0.0` if key not found or on nil instance.

### Bool

```go
func (c *Config) Bool(key string) bool
```

Retrieves a boolean value at the given key.

**Returns:** `false` if key not found or on nil instance.

### Duration

```go
func (c *Config) Duration(key string) time.Duration
```

Retrieves a time.Duration value at the given key. Supports duration strings like "30s", "5m", "1h".

**Returns:** `0` if key not found or on nil instance.

**Example:**

```go
timeout := cfg.Duration("server.timeout")  // Parses "30s" to 30 * time.Second
```

### Time

```go
func (c *Config) Time(key string) time.Time
```

Retrieves a time.Time value at the given key.

**Returns:** Zero time (`time.Time{}`) if key not found or on nil instance.

### StringSlice

```go
func (c *Config) StringSlice(key string) []string
```

Retrieves a string slice at the given key.

**Returns:** Empty slice `[]string{}` (not nil) if key not found or on nil instance.

**Example:**

```go
hosts := cfg.StringSlice("servers")  // []string{} if missing
```

### IntSlice

```go
func (c *Config) IntSlice(key string) []int
```

Retrieves an integer slice at the given key.

**Returns:** Empty slice `[]int{}` (not nil) if key not found or on nil instance.

### StringMap

```go
func (c *Config) StringMap(key string) map[string]any
```

Retrieves a map at the given key.

**Returns:** Empty map `map[string]any{}` (not nil) if key not found or on nil instance.

**Example:**

```go
metadata := cfg.StringMap("metadata")  // map[string]any{} if missing
```

## Getter Methods with Defaults

### StringOr

```go
func (c *Config) StringOr(key, defaultVal string) string
```

Retrieves a string value or returns the default if not found.

**Example:**

```go
host := cfg.StringOr("server.host", "localhost")
```

### IntOr

```go
func (c *Config) IntOr(key string, defaultVal int) int
```

Retrieves an integer value or returns the default if not found.

**Example:**

```go
port := cfg.IntOr("server.port", 8080)
```

### Int64Or

```go
func (c *Config) Int64Or(key string, defaultVal int64) int64
```

Retrieves an int64 value or returns the default if not found.

### Float64Or

```go
func (c *Config) Float64Or(key string, defaultVal float64) float64
```

Retrieves a float64 value or returns the default if not found.

### BoolOr

```go
func (c *Config) BoolOr(key string, defaultVal bool) bool
```

Retrieves a boolean value or returns the default if not found.

**Example:**

```go
debug := cfg.BoolOr("debug", false)
```

### DurationOr

```go
func (c *Config) DurationOr(key string, defaultVal time.Duration) time.Duration
```

Retrieves a duration value or returns the default if not found.

**Example:**

```go
timeout := cfg.DurationOr("timeout", 30*time.Second)
```

### TimeOr

```go
func (c *Config) TimeOr(key string, defaultVal time.Time) time.Time
```

Retrieves a time.Time value or returns the default if not found.

### StringSliceOr

```go
func (c *Config) StringSliceOr(key string, defaultVal []string) []string
```

Retrieves a string slice or returns the default if not found.

### IntSliceOr

```go
func (c *Config) IntSliceOr(key string, defaultVal []int) []int
```

Retrieves an integer slice or returns the default if not found.

### StringMapOr

```go
func (c *Config) StringMapOr(key string, defaultVal map[string]any) map[string]any
```

Retrieves a map or returns the default if not found.

## Generic Getter Functions

### GetE

```go
func GetE[T any](c *Config, key string) (T, error)
```

Generic getter that returns the value and an error. Useful for custom types and explicit error handling.

**Type parameters:**
- `T` - Target type

**Parameters:**
- `c` - Config instance
- `key` - Dot-separated path

**Returns:**
- `T` - Value at the key (zero value if error)
- `error` - Error if key not found, type mismatch, or nil instance

**Example:**

```go
port, err := config.GetE[int](cfg, "server.port")
if err != nil {
    log.Printf("invalid port: %v", err)
    port = 8080
}

// Custom type
type DatabaseConfig struct {
    Host string
    Port int
}

dbConfig, err := config.GetE[DatabaseConfig](cfg, "database")
```

### GetOr

```go
func GetOr[T any](c *Config, key string, defaultVal T) T
```

Generic getter that returns the value or a default if not found.

**Example:**

```go
port := config.GetOr(cfg, "server.port", 8080)
```

### Get

```go
func Get[T any](c *Config, key string) T
```

Generic getter that returns the value or zero value if not found.

**Example:**

```go
port := config.Get[int](cfg, "server.port")  // 0 if missing
```

## Data Access Methods

### Values

```go
func (c *Config) Values() *map[string]any
```

Returns a pointer to the internal configuration map.

**Returns:** `nil` if Config instance is nil

**Warning:** Direct modification of the returned map is not recommended. Use for read-only operations.

**Example:**

```go
values := cfg.Values()
if values != nil {
    fmt.Printf("Config data: %+v\n", *values)
}
```

## Nil-Safety Guarantees

All getter methods handle nil Config instances gracefully:

```go
var cfg *config.Config  // nil

// Short methods return zero values
cfg.String("key")       // Returns ""
cfg.Int("key")          // Returns 0
cfg.Bool("key")         // Returns false
cfg.StringSlice("key")  // Returns []string{}
cfg.StringMap("key")    // Returns map[string]any{}

// Error methods return errors
port, err := config.GetE[int](cfg, "key")
// err: "config instance is nil"
```

## Thread Safety

**Thread-safe operations:**
- `Load()` - Uses internal locking
- All getter methods - Read-only operations are safe
- Multiple goroutines can call `Load()` and getters concurrently

**Not thread-safe:**
- Concurrent modification during initialization
- Direct modification of values returned by `Values()`

## Error Handling Patterns

### Pattern 1: Simple Access

```go
port := cfg.Int("server.port")  // Use zero value as implicit default
```

### Pattern 2: Explicit Defaults

```go
port := cfg.IntOr("server.port", 8080)  // Explicit default
```

### Pattern 3: Error Handling

```go
port, err := config.GetE[int](cfg, "server.port")
if err != nil {
    return fmt.Errorf("invalid port: %w", err)
}
```

### Pattern 4: Load Errors

```go
if err := cfg.Load(context.Background()); err != nil {
    var configErr *config.ConfigError
    if errors.As(err, &configErr) {
        log.Printf("Config error in %s during %s: %v",
            configErr.Source, configErr.Operation, configErr.Err)
    }
    return err
}
```

## Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| `Get(key)` | O(n) | n = depth of dot notation path |
| `String(key)`, `Int(key)`, etc. | O(n) | Uses `Get()` internally |
| `Load()` | O(s × m) | s = number of sources, m = data size |
| `Dump()` | O(d × m) | d = number of dumpers, m = data size |

## Next Steps

- Review [Options Reference](../options/) for all configuration options
- See [Codecs](../codecs/) for format support
- Check [Troubleshooting](../troubleshooting/) for common issues
- Explore the [Configuration Guide](/guides/config/) for usage examples
