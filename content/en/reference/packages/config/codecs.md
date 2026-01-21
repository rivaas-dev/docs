---
title: "Codecs Reference"
description: "Built-in codecs for configuration format support and type conversion"
keywords:
  - codecs
  - file formats
  - yaml
  - json
  - toml
weight: 4
---

Complete reference for built-in codecs and guidance on creating custom codecs.

## Codec Interface

```go
type Codec interface {
    Encode(v any) ([]byte, error)
    Decode(data []byte, v any) error
}
```

Codecs handle encoding and decoding of configuration data between different formats.

## Built-in Format Codecs

### JSON Codec

**Type:** `codec.TypeJSON`  
**Import:** `rivaas.dev/config/codec`

Handles JSON format encoding and decoding.

**Capabilities:**
- ✅ Encode
- ✅ Decode

**File extensions:**
- `.json`

**Example:**

```go
import "rivaas.dev/config/codec"

cfg := config.MustNew(
    config.WithFileAs("config.txt", codec.TypeJSON),
)
```

**Features:**
- Standard Go `encoding/json` implementation
- Preserves JSON types (numbers, strings, booleans, arrays, objects)
- Pretty-printed output when encoding

### YAML Codec

**Type:** `codec.TypeYAML`  
**Import:** `rivaas.dev/config/codec`

Handles YAML format encoding and decoding.

**Capabilities:**
- ✅ Encode
- ✅ Decode

**File extensions:**
- `.yaml`
- `.yml`

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),
)
```

**Features:**
- Uses [gopkg.in/yaml.v3](https://gopkg.in/yaml.v3)
- Supports YAML 1.2 features
- Handles anchors and aliases
- Preserves indentation on encoding

**Common YAML types:**

```yaml
string_value: "hello"
number_value: 42
boolean_value: true
duration_value: 30s
list_value:
  - item1
  - item2
map_value:
  key1: value1
  key2: value2
```

### TOML Codec

**Type:** `codec.TypeTOML`  
**Import:** `rivaas.dev/config/codec`

Handles TOML format encoding and decoding.

**Capabilities:**
- ✅ Encode
- ✅ Decode

**File extensions:**
- `.toml`

**Example:**

```go
cfg := config.MustNew(
    config.WithFile("config.toml"),
)
```

**Features:**
- Uses [github.com/BurntSushi/toml](https://github.com/BurntSushi/toml)
- Supports TOML v1.0.0
- Strongly typed

**Sample TOML:**

```toml
[server]
host = "localhost"
port = 8080

[database]
host = "db.example.com"
port = 5432
```

### Environment Variable Codec

**Type:** `codec.TypeEnvVar`  
**Import:** `rivaas.dev/config/codec`

Handles environment variable format.

**Capabilities:**
- ❌ Encode (returns error)
- ✅ Decode

**Example:**

```go
cfg := config.MustNew(
    config.WithEnv("APP_"),
)
```

**Format:**
```
PREFIX_SECTION_KEY=value
PREFIX_A_B_C=nested
```

**Transformation:**
- Strips prefix
- Converts to lowercase
- Splits by underscores
- Creates nested structure

**See:** [Environment Variables Guide](/guides/config/environment-variables/)

## Built-in Caster Codecs

Caster codecs provide automatic type conversion for getter methods.

### Boolean Caster

**Type:** `codec.TypeCasterBool`

Converts values to `bool`.

**Supported inputs:**
- `true`, `"true"`, `"True"`, `"TRUE"`, `1`, `"1"` → `true`
- `false`, `"false"`, `"False"`, `"FALSE"`, `0`, `"0"` → `false`

**Example:**

```go
debug := cfg.Bool("debug")  // Uses BoolCaster internally
```

### Integer Casters

Convert values to integer types.

| Type | Codec | Target Type |
|------|-------|-------------|
| `codec.TypeCasterInt` | Int | `int` |
| `codec.TypeCasterInt8` | Int8 | `int8` |
| `codec.TypeCasterInt16` | Int16 | `int16` |
| `codec.TypeCasterInt32` | Int32 | `int32` |
| `codec.TypeCasterInt64` | Int64 | `int64` |

**Supported inputs:**
- Integer values: `42`, `100`
- String integers: `"42"`, `"100"`
- Float values: `42.0` → `42`
- String floats: `"42.0"` → `42`

**Example:**

```go
port := cfg.Int("server.port")      // Uses IntCaster
timeout := cfg.Int64("timeout_ms")  // Uses Int64Caster
```

### Unsigned Integer Casters

Convert values to unsigned integer types.

| Type | Codec | Target Type |
|------|-------|-------------|
| `codec.TypeCasterUint` | Uint | `uint` |
| `codec.TypeCasterUint8` | Uint8 | `uint8` |
| `codec.TypeCasterUint16` | Uint16 | `uint16` |
| `codec.TypeCasterUint32` | Uint32 | `uint32` |
| `codec.TypeCasterUint64` | Uint64 | `uint64` |

**Supported inputs:**
- Positive integers: `42`, `100`
- String integers: `"42"`, `"100"`

### Float Casters

Convert values to floating-point types.

| Type | Codec | Target Type |
|------|-------|-------------|
| `codec.TypeCasterFloat32` | Float32 | `float32` |
| `codec.TypeCasterFloat64` | Float64 | `float64` |

**Supported inputs:**
- Float values: `3.14`, `2.5`
- String floats: `"3.14"`, `"2.5"`
- Integer values: `42` → `42.0`
- String integers: `"42"` → `42.0`

**Example:**

```go
ratio := cfg.Float64("ratio")
```

### String Caster

**Type:** `codec.TypeCasterString`

Converts any value to string.

**Supported inputs:**
- String values: `"hello"` → `"hello"`
- Numbers: `42` → `"42"`
- Booleans: `true` → `"true"`
- Any value with `String()` method

**Example:**

```go
value := cfg.String("key")  // Uses StringCaster internally
```

### Time Caster

**Type:** `codec.TypeCasterTime`

Converts values to `time.Time`.

**Supported inputs:**
- RFC3339 strings: `"2025-01-01T00:00:00Z"`
- ISO8601 strings: `"2025-01-01T00:00:00+00:00"`
- Unix timestamps: `1672531200`

**Example:**

```go
createdAt := cfg.Time("created_at")
```

**Formats tried (in order):**
1. `time.RFC3339` - `"2006-01-02T15:04:05Z07:00"`
2. `time.RFC3339Nano` - `"2006-01-02T15:04:05.999999999Z07:00"`
3. `"2006-01-02"` - Date only
4. Unix timestamp (integer)

### Duration Caster

**Type:** `codec.TypeCasterDuration`

Converts values to `time.Duration`.

**Supported inputs:**
- Duration strings: `"30s"`, `"5m"`, `"1h"`, `"2h30m"`
- Integer nanoseconds: `30000000000` → `30s`
- Float seconds: `2.5` → `2.5s`

**Example:**

```go
timeout := cfg.Duration("timeout")  // "30s" → 30 * time.Second
```

**Duration units:**
- `ns` - nanoseconds
- `us` or `µs` - microseconds
- `ms` - milliseconds
- `s` - seconds
- `m` - minutes
- `h` - hours

## Codec Capabilities Table

| Codec | Encode | Decode | Auto-Detect | Extensions |
|-------|--------|--------|-------------|------------|
| JSON | ✅ | ✅ | ✅ | `.json` |
| YAML | ✅ | ✅ | ✅ | `.yaml`, `.yml` |
| TOML | ✅ | ✅ | ✅ | `.toml` |
| EnvVar | ❌ | ✅ | ❌ | - |
| Bool | ✅ | ✅ | ❌ | - |
| Int* | ✅ | ✅ | ❌ | - |
| Uint* | ✅ | ✅ | ❌ | - |
| Float* | ✅ | ✅ | ❌ | - |
| String | ✅ | ✅ | ❌ | - |
| Time | ✅ | ✅ | ❌ | - |
| Duration | ✅ | ✅ | ❌ | - |

## Format Auto-Detection

The config package automatically detects formats based on file extensions:

```go
cfg := config.MustNew(
    config.WithFile("config.json"),  // Auto-detects JSON
    config.WithFile("config.yaml"),  // Auto-detects YAML
    config.WithFile("config.toml"),  // Auto-detects TOML
)
```

**Detection rules:**

1. Check file extension
2. Look up registered decoder for that extension
3. Use codec if found, error if not

**Override auto-detection:**

```go
cfg := config.MustNew(
    config.WithFileAs("settings.txt", codec.TypeYAML),
)
```

## Custom Codecs

### Registering Custom Codecs

```go
import "rivaas.dev/config/codec"

func init() {
    codec.RegisterEncoder("myformat", MyCodec{})
    codec.RegisterDecoder("myformat", MyCodec{})
}
```

**Registration functions:**

```go
func RegisterEncoder(name string, encoder Codec)
func RegisterDecoder(name string, decoder Codec)
```

### Custom Codec Example

```go
type MyCodec struct{}

func (c MyCodec) Encode(v any) ([]byte, error) {
    data, ok := v.(map[string]any)
    if !ok {
        return nil, fmt.Errorf("expected map[string]any, got %T", v)
    }
    
    // Your encoding logic
    var buf bytes.Buffer
    // ... write to buf ...
    
    return buf.Bytes(), nil
}

func (c MyCodec) Decode(data []byte, v any) error {
    target, ok := v.(*map[string]any)
    if !ok {
        return fmt.Errorf("expected *map[string]any, got %T", v)
    }
    
    // Your decoding logic
    result := make(map[string]any)
    // ... parse data into result ...
    
    *target = result
    return nil
}

func init() {
    codec.RegisterEncoder("myformat", MyCodec{})
    codec.RegisterDecoder("myformat", MyCodec{})
}
```

**See:** [Custom Codecs Guide](/guides/config/custom-codecs/)

## Common Patterns

### Pattern 1: Mixed Formats

```go
cfg := config.MustNew(
    config.WithFile("config.yaml"),  // YAML
    config.WithFile("secrets.json"), // JSON
    config.WithFile("extra.toml"),   // TOML
)
```

### Pattern 2: Explicit Format

```go
cfg := config.MustNew(
    config.WithFileAs("config.txt", codec.TypeYAML),
)
```

### Pattern 3: Content Source

```go
yamlData := []byte(`server: {port: 8080}`)
cfg := config.MustNew(
    config.WithContent(yamlData, codec.TypeYAML),
)
```

### Pattern 4: Custom Codec

```go
import _ "yourmodule/xmlcodec"  // Registers custom codec

cfg := config.MustNew(
    config.WithFileAs("config.xml", "xml"),
)
```

## Type Conversion Examples

### String to Duration

```yaml
timeout: "30s"
```

```go
timeout := cfg.Duration("timeout")  // 30 * time.Second
```

### String to Int

```yaml
port: "8080"
```

```go
port := cfg.Int("port")  // 8080
```

### String to Bool

```yaml
debug: "true"
```

```go
debug := cfg.Bool("debug")  // true
```

### String to Time

```yaml
created: "2025-01-01T00:00:00Z"
```

```go
created := cfg.Time("created")  // time.Time
```

## Error Handling

### Decode Errors

```go
if err := cfg.Load(context.Background()); err != nil {
    // Error format:
    // "config error in source[0] during load: yaml: unmarshal error"
    log.Printf("Failed to decode: %v", err)
}
```

### Encode Errors

```go
if err := cfg.Dump(context.Background()); err != nil {
    // Error format:
    // "config error in dumper[0] during dump: json: unsupported type"
    log.Printf("Failed to encode: %v", err)
}
```

### Type Conversion Errors

```go
// For error-returning methods
port, err := config.GetE[int](cfg, "server.port")
if err != nil {
    log.Printf("Invalid port: %v", err)
}
```

## Performance Notes

- **JSON**: Fast, minimal overhead
- **YAML**: Moderate overhead (parsing complexity)
- **TOML**: Fast, strict typing
- **Casters**: Minimal overhead, optimized for common cases

## Next Steps

- Learn [Custom Codecs](/guides/config/custom-codecs/) for implementing your own formats
- See [Options Reference](../options/) for codec usage
- Review [API Reference](../api-reference/) for getter methods
- Check [Examples](/guides/config/examples/) for practical usage
