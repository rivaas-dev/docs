---
title: "Options Reference"
description: "Complete reference for all configuration option functions"
keywords:
  - config options
  - configuration
  - options reference
  - functional options
weight: 3
---

Comprehensive documentation of all option functions used to configure Config instances.

## Option Type

```go
type Option func(*Config) error
```

Options are functions that configure a Config instance during initialization. They are passed to `New()` or `MustNew()`.

## Environment Variable Expansion

All path-based options (`WithFile`, `WithFileAs`, `WithConsul`, `WithConsulAs`, `WithFileDumper`, `WithFileDumperAs`) support environment variable expansion in paths. This makes it easy to use different paths based on your environment.

**Supported syntax:**
- `${VAR}` - Braced variable name
- `$VAR` - Simple variable name

**Note:** Shell-style defaults like `${VAR:-default}` are NOT supported. Set defaults in your code before calling the option.

**Examples:**

```go
// Environment-based Consul path
config.WithConsul("${APP_ENV}/service.yaml")
// When APP_ENV=production, expands to: "production/service.yaml"

// Config directory from environment
config.WithFile("${CONFIG_DIR}/app.yaml")
// When CONFIG_DIR=/etc/myapp, expands to: "/etc/myapp/app.yaml"

// Multiple variables
config.WithFile("${REGION}/${ENV}/settings.yaml")
// When REGION=us-west and ENV=staging, expands to: "us-west/staging/settings.yaml"

// Output directory
config.WithFileDumper("${LOG_DIR}/effective-config.yaml")
// When LOG_DIR=/var/log, expands to: "/var/log/effective-config.yaml"
```

**Handling unset variables:**

If an environment variable is not set, it expands to an empty string:

```go
// If APP_ENV is not set:
config.WithConsul("${APP_ENV}/service.yaml")  // Expands to: "/service.yaml"
```

To provide defaults, set them in your code:

```go
if os.Getenv("APP_ENV") == "" {
    os.Setenv("APP_ENV", "development")
}
config.WithConsul("${APP_ENV}/service.yaml")  // Uses "development" if not set
```

## Source Options

Source options specify where configuration data comes from.

### WithFile

```go
func WithFile(path string) Option
```

Loads configuration from a file with automatic format detection based on extension.

**Parameters:**
- `path` - Path to configuration file.

**Supported extensions:**
- `.json` - JSON format.
- `.yaml`, `.yml` - YAML format.
- `.toml` - TOML format.

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithFile("config.json"),
)
```

**Error conditions:**
- File does not exist (error occurs during `Load()`, not initialization)
- Extension not recognized

### WithFileAs

```go
func WithFileAs(path string, codecType codec.Type) Option
```

Loads configuration from a file with explicit format specification.

**Parameters:**
- `path` - Path to configuration file.
- `codecType` - Codec type like `codec.TypeYAML` or `codec.TypeJSON`.

**Example:**

```go
cfg := config.MustNew(
    config.WithFileAs("config.txt", codec.TypeYAML),
    config.WithFileAs("settings.conf", codec.TypeJSON),
)
```

**Use when:** File extension doesn't match its format.

### WithEnv

```go
func WithEnv(prefix string) Option
```

Loads configuration from environment variables with the given prefix.

**Parameters:**
- `prefix` - Prefix to filter environment variables (e.g., "APP_", "MYAPP_")

**Naming convention:**
- `PREFIX_KEY` → `key`
- `PREFIX_SECTION_KEY` → `section.key`
- `PREFIX_A_B_C` → `a.b.c`

**Example:**

```go
cfg := config.MustNew(
    config.WithEnv("MYAPP_"),
)

// Environment: MYAPP_SERVER_PORT=8080
// Maps to: server.port = 8080
```

**See also:** [Environment Variables Guide](/guides/config/environment-variables/)

### WithConsul

```go
func WithConsul(path string) Option
```

Loads configuration from HashiCorp Consul. The format is detected from the file extension.

**Works without Consul:** If `CONSUL_HTTP_ADDR` isn't set, this option does nothing. This means you can run your app locally without Consul. When you deploy to production, just set the environment variable and Consul will be used.

**Parameters:**
- `path` - Consul key path (format detected from extension)

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithConsul("production/service.json"),  // Skipped in dev, used in prod
)
```

**Environment variables:**
- `CONSUL_HTTP_ADDR` - Consul server address (required for Consul to work)
- `CONSUL_HTTP_TOKEN` - Access token for authentication (optional)

### WithConsulAs

```go
func WithConsulAs(path string, codecType codec.Type) Option
```

Loads configuration from Consul with explicit format. Use this when the key path doesn't have an extension.

**Works without Consul:** Like `WithConsul`, this option does nothing if `CONSUL_HTTP_ADDR` isn't set. Your code works the same in dev and prod.

**Parameters:**
- `path` - Consul key path
- `codecType` - Codec type (like `codec.TypeYAML` or `codec.TypeJSON`)

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithConsulAs("config/app", codec.TypeYAML),  // No extension in key
)
```

**Environment variables:**
- `CONSUL_HTTP_ADDR` - Consul server address (required for Consul to work)
- `CONSUL_HTTP_TOKEN` - Access token for authentication (optional)

### WithContent

```go
func WithContent(data []byte, codecType codec.Type) Option
```

Loads configuration from a byte slice.

**Parameters:**
- `data` - Configuration data as bytes
- `codecType` - Codec type for decoding

**Example:**

```go
configData := []byte(`{"server": {"port": 8080}}`)
cfg := config.MustNew(
    config.WithContent(configData, codec.TypeJSON),
)
```

**Use cases:**
- Testing
- Dynamic configuration
- Embedded configuration

### WithSource

```go
func WithSource(loader Source) Option
```

Adds a custom configuration source.

**Parameters:**
- `loader` - Custom source implementing the `Source` interface

**Source interface:**

```go
type Source interface {
    Load(ctx context.Context) (map[string]any, error)
}
```

**Example:**

```go
type CustomSource struct{}

func (s *CustomSource) Load(ctx context.Context) (map[string]any, error) {
    return map[string]any{"key": "value"}, nil
}

cfg := config.MustNew(
    config.WithSource(&CustomSource{}),
)
```

## Validation Options

Validation options enable configuration validation.

### WithBinding

```go
func WithBinding(v any) Option
```

Binds configuration to a Go struct and optionally validates it.

**Parameters:**
- `v` - Pointer to struct to bind configuration to

**Example:**

```go
type Config struct {
    Port int `config:"port"`
}

var cfg Config
config := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithBinding(&cfg),
)
```

**Validation:** If the struct implements `Validate() error`, it will be called after binding.

**Requirements:**
- Must pass a pointer to the struct
- Struct fields must have `config:"name"` tags

**See also:** [Struct Binding Guide](/guides/config/struct-binding/)

### WithTag

```go
func WithTag(tagName string) Option
```

Changes the struct tag name used for binding (default: "config").

**Parameters:**
- `tagName` - Tag name to use instead of "config"

**Example:**

```go
type Config struct {
    Port int `yaml:"port"`
}

var cfg Config
config := config.MustNew(
    config.WithTag("yaml"),
    config.WithBinding(&cfg),
)
```

**Use when:** You want to reuse existing struct tags (e.g., `json`, `yaml`).

### WithValidator

```go
func WithValidator(fn func(map[string]any) error) Option
```

Registers a custom validation function for the configuration map.

**Parameters:**
- `fn` - Validation function that receives the merged configuration

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithValidator(func(data map[string]any) error {
        port, ok := data["port"].(int)
        if !ok || port <= 0 {
            return errors.New("port must be a positive integer")
        }
        return nil
    }),
)
```

**Timing:** Validation runs after sources are merged, before struct binding.

**Multiple validators:** You can register multiple validators; all will be executed.

### WithJSONSchema

```go
func WithJSONSchema(schema []byte) Option
```

Validates configuration against a JSON Schema.

**Parameters:**
- `schema` - JSON Schema as bytes

**Example:**

```go
schemaBytes, _ := os.ReadFile("schema.json")
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithJSONSchema(schemaBytes),
)
```

**Schema validation:**
- Runs after sources are merged
- Runs before custom validators and struct binding
- Uses [github.com/santhosh-tekuri/jsonschema/v6](https://github.com/santhosh-tekuri/jsonschema)

**See also:** [Validation Guide](/guides/config/validation/)

## Dumper Options

Dumper options specify where to write configuration.

### WithFileDumper

```go
func WithFileDumper(path string) Option
```

Writes configuration to a file with automatic format detection.

**Parameters:**
- `path` - Output file path (format detected from extension)

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
    config.WithFileDumper("effective-config.yaml"),
)

cfg.Load(context.Background())
cfg.Dump(context.Background())  // Writes to effective-config.yaml
```

**Default permissions:** 0644 (owner read/write, group/others read)

### WithFileDumperAs

```go
func WithFileDumperAs(path string, codecType codec.Type) Option
```

Writes configuration to a file with explicit format specification.

**Parameters:**
- `path` - Output file path
- `codecType` - Codec type for encoding

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithFileDumperAs("output.json", codec.TypeJSON),
)
```

### WithDumper

```go
func WithDumper(dumper Dumper) Option
```

Adds a custom configuration dumper.

**Parameters:**
- `dumper` - Custom dumper implementing the `Dumper` interface

**Dumper interface:**

```go
type Dumper interface {
    Dump(ctx context.Context, data map[string]any) error
}
```

**Example:**

```go
type CustomDumper struct{}

func (d *CustomDumper) Dump(ctx context.Context, data map[string]any) error {
    // Write data somewhere
    return nil
}

cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithDumper(&CustomDumper{}),
)
```

## Option Composition

Options are applied in the order they are passed to `New()` or `MustNew()`:

```go
cfg := config.MustNew(
    // 1. Load base config
    config.WithFile("config.yaml"),
    
    // 2. Load environment-specific config
    config.WithFile("config.prod.yaml"),
    
    // 3. Override with environment variables (highest priority)
    config.WithEnv("APP_"),
    
    // 4. Set up validation
    config.WithJSONSchema(schemaBytes),
    config.WithValidator(customValidation),
    
    // 5. Bind to struct
    config.WithBinding(&appConfig),
    
    // 6. Set up dumper
    config.WithFileDumper("effective-config.yaml"),
)
```

## Source Precedence

When multiple sources are configured, later sources override earlier ones:

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),      // Priority 1 (lowest)
    config.WithFile("config.prod.yaml"), // Priority 2
    config.WithEnv("APP_"),              // Priority 3 (highest)
)
```

## Validation Order

Validation happens in this sequence during `Load()`:

1. Load and merge all sources
2. JSON Schema validation (if configured)
3. Custom validation functions (if configured)
4. Struct binding (if configured)
5. Struct `Validate()` method (if implemented)

## Common Patterns

### Pattern 1: Basic Configuration

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
)
```

### Pattern 2: Environment Override

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
)
```

### Pattern 3: Multi-Environment

```go
env := os.Getenv("APP_ENV")
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithFile("config."+env+".yaml"),
    config.WithEnv("APP_"),
)
```

### Pattern 4: With Validation

```go
var appConfig AppConfig
cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
    config.WithBinding(&appConfig),
)
```

### Pattern 5: Production Setup

```go
var appConfig AppConfig
schemaBytes, _ := os.ReadFile("schema.json")

cfg := config.MustNew(
    config.WithFile("config.yaml"),
    config.WithEnv("APP_"),
    config.WithJSONSchema(schemaBytes),
    config.WithBinding(&appConfig),
    config.WithFileDumper("effective-config.yaml"),
)
```

## Next Steps

- See [API Reference](../api-reference/) for Config methods
- Review [Codecs](../codecs/) for format support
- Check [Examples](/guides/config/examples/) for usage patterns
