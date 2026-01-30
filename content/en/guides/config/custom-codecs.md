---
title: "Custom Codecs"
description: "Extend configuration support to custom formats with codec implementation"
weight: 8
keywords:
  - config codecs
  - yaml
  - json
  - toml
  - custom formats
---

The config package allows you to extend configuration support to any format by implementing and registering custom codecs.

## Codec Interface

A codec is responsible for encoding and decoding configuration data.

```go
type Codec interface {
    Encode(v any) ([]byte, error)
    Decode(data []byte, v any) error
}
```

**Methods:**

- `Encode(v any) ([]byte, error)` - Convert Go data structures to bytes.
- `Decode(data []byte, v any) error` - Convert bytes to Go data structures.

## Built-in Codecs

The config package includes several built-in codecs.

### Format Codecs

| Codec | Type | Capabilities |
|-------|------|--------------|
| JSON | `codec.TypeJSON` | Encode & Decode |
| YAML | `codec.TypeYAML` | Encode & Decode |
| TOML | `codec.TypeTOML` | Encode & Decode |
| EnvVar | `codec.TypeEnvVar` | Decode only |

### Caster Codecs

Caster codecs handle type conversion.

| Codec | Type | Converts To |
|-------|------|-------------|
| Bool | `codec.TypeCasterBool` | `bool` |
| Int | `codec.TypeCasterInt` | `int` |
| Int8/16/32/64 | `codec.TypeCasterInt8`, etc. | `int8`, `int16`, etc. |
| Uint | `codec.TypeCasterUint` | `uint` |
| Uint8/16/32/64 | `codec.TypeCasterUint8`, etc. | `uint8`, `uint16`, etc. |
| Float32/64 | `codec.TypeCasterFloat32`, `codec.TypeCasterFloat64` | `float32`, `float64` |
| String | `codec.TypeCasterString` | `string` |
| Time | `codec.TypeCasterTime` | `time.Time` |
| Duration | `codec.TypeCasterDuration` | `time.Duration` |

## Implementing a Custom Codec

### Basic Example: INI Format

Let's implement a simple INI file codec.

```go
package inicodec

import (
    "bufio"
    "bytes"
    "fmt"
    "strings"
    "rivaas.dev/config/codec"
)

type INICodec struct{}

func (c INICodec) Decode(data []byte, v any) error {
    result := make(map[string]any)
    scanner := bufio.NewScanner(bytes.NewReader(data))
    
    var currentSection string
    
    for scanner.Scan() {
        line := strings.TrimSpace(scanner.Text())
        
        // Skip empty lines and comments
        if line == "" || strings.HasPrefix(line, ";") || strings.HasPrefix(line, "#") {
            continue
        }
        
        // Section header
        if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
            currentSection = strings.Trim(line, "[]")
            if result[currentSection] == nil {
                result[currentSection] = make(map[string]any)
            }
            continue
        }
        
        // Key-value pair
        parts := strings.SplitN(line, "=", 2)
        if len(parts) != 2 {
            continue
        }
        
        key := strings.TrimSpace(parts[0])
        value := strings.TrimSpace(parts[1])
        
        if currentSection != "" {
            section := result[currentSection].(map[string]any)
            section[key] = value
        } else {
            result[key] = value
        }
    }
    
    // Type assertion to set result
    target := v.(*map[string]any)
    *target = result
    
    return scanner.Err()
}

func (c INICodec) Encode(v any) ([]byte, error) {
    data, ok := v.(map[string]any)
    if !ok {
        return nil, fmt.Errorf("expected map[string]any, got %T", v)
    }
    
    var buf bytes.Buffer
    
    for section, values := range data {
        sectionMap, ok := values.(map[string]any)
        if !ok {
            // Top-level key-value
            buf.WriteString(fmt.Sprintf("%s = %v\n", section, values))
            continue
        }
        
        // Section header
        buf.WriteString(fmt.Sprintf("[%s]\n", section))
        
        // Section key-values
        for key, value := range sectionMap {
            buf.WriteString(fmt.Sprintf("%s = %v\n", key, value))
        }
        
        buf.WriteString("\n")
    }
    
    return buf.Bytes(), nil
}

func init() {
    codec.RegisterEncoder("ini", INICodec{})
    codec.RegisterDecoder("ini", INICodec{})
}
```

### Using the Custom Codec

```go
package main

import (
    "context"
    "log"
    "rivaas.dev/config"
    _ "yourmodule/inicodec"  // Register codec via init()
)

func main() {
    cfg := config.MustNew(
        config.WithFileAs("config.ini", "ini"),
    )
    
    if err := cfg.Load(context.Background()); err != nil {
        log.Fatalf("failed to load config: %v", err)
    }
    
    host := cfg.String("server.host")
    port := cfg.Int("server.port")
    
    log.Printf("Server: %s:%d", host, port)
}
```

**config.ini:**

```ini
[server]
host = localhost
port = 8080

[database]
host = db.example.com
port = 5432
```

## Registering Codecs

Codecs must be registered before use:

```go
import "rivaas.dev/config/codec"

func init() {
    codec.RegisterEncoder("mytype", MyCodec{})
    codec.RegisterDecoder("mytype", MyCodec{})
}
```

**Registration functions:**

- `RegisterEncoder(name string, encoder Codec)` - Register for encoding
- `RegisterDecoder(name string, decoder Codec)` - Register for decoding

You can register the same codec for both or different codecs for each operation.

## Decode-Only Codecs

Some codecs only support decoding (like the built-in EnvVar codec):

```go
type EnvVarCodec struct{}

func (c EnvVarCodec) Decode(data []byte, v any) error {
    // Decode environment variable format
    // ...
}

func (c EnvVarCodec) Encode(v any) ([]byte, error) {
    return nil, errors.New("encoding to environment variables not supported")
}

func init() {
    codec.RegisterDecoder("envvar", EnvVarCodec{})
    // Note: Not registering encoder
}
```

## Advanced Example: XML Codec

A more complete example with error handling:

```go
package xmlcodec

import (
    "encoding/xml"
    "fmt"
    "rivaas.dev/config/codec"
)

type XMLCodec struct{}

func (c XMLCodec) Decode(data []byte, v any) error {
    target, ok := v.(*map[string]any)
    if !ok {
        return fmt.Errorf("expected *map[string]any, got %T", v)
    }
    
    // XML unmarshaling to intermediate structure
    var intermediate struct {
        XMLName xml.Name
        Content []byte `xml:",innerxml"`
    }
    
    if err := xml.Unmarshal(data, &intermediate); err != nil {
        return fmt.Errorf("xml decode error: %w", err)
    }
    
    // Convert XML to map structure
    result := make(map[string]any)
    // ... conversion logic ...
    
    *target = result
    return nil
}

func (c XMLCodec) Encode(v any) ([]byte, error) {
    data, ok := v.(map[string]any)
    if !ok {
        return nil, fmt.Errorf("expected map[string]any, got %T", v)
    }
    
    // Convert map to XML structure
    xmlData, err := xml.MarshalIndent(data, "", "  ")
    if err != nil {
        return nil, fmt.Errorf("xml encode error: %w", err)
    }
    
    return xmlData, nil
}

func init() {
    codec.RegisterEncoder("xml", XMLCodec{})
    codec.RegisterDecoder("xml", XMLCodec{})
}
```

## Caster Codecs

Caster codecs provide type conversion. You typically don't need to implement these - use the built-in casters:

```go
import "rivaas.dev/config/codec"

// Get int value with automatic conversion
port := cfg.Int("server.port")  // Uses codec.TypeCasterInt internally

// Get duration with automatic conversion
timeout := cfg.Duration("timeout")  // Uses codec.TypeCasterDuration internally
```

### Custom Caster Example

If you need custom type conversion:

```go
type URLCaster struct{}

func (c URLCaster) Decode(data []byte, v any) error {
    target, ok := v.(*url.URL)
    if !ok {
        return fmt.Errorf("expected *url.URL, got %T", v)
    }
    
    parsedURL, err := url.Parse(string(data))
    if err != nil {
        return fmt.Errorf("invalid URL: %w", err)
    }
    
    *target = *parsedURL
    return nil
}

func (c URLCaster) Encode(v any) ([]byte, error) {
    u, ok := v.(*url.URL)
    if !ok {
        return nil, fmt.Errorf("expected *url.URL, got %T", v)
    }
    return []byte(u.String()), nil
}
```

## When to Create Custom Codecs

### Use Custom Codecs For:

1. **Unsupported formats** - XML, INI, HCL, proprietary formats
2. **Legacy formats** - Converting old configuration formats
3. **Encrypted configurations** - Decrypting config data
4. **Compressed data** - Handling gzip/compressed configs
5. **Custom protocols** - Special encoding schemes

### Use Built-in Codecs For:

1. **Standard formats** - JSON, YAML, TOML
2. **Type conversion** - Use caster codecs (Int, Bool, Duration, etc.)
3. **Simple text formats** - Can often use JSON/YAML

## Best Practices

### 1. Error Handling

Provide clear error messages:

```go
func (c MyCodec) Decode(data []byte, v any) error {
    if len(data) == 0 {
        return errors.New("empty data")
    }
    
    target, ok := v.(*map[string]any)
    if !ok {
        return fmt.Errorf("expected *map[string]any, got %T", v)
    }
    
    // ... decoding logic ...
    
    if err != nil {
        return fmt.Errorf("decode error at line %d: %w", line, err)
    }
    
    return nil
}
```

### 2. Type Validation

Validate expected types:

```go
func (c MyCodec) Decode(data []byte, v any) error {
    target, ok := v.(*map[string]any)
    if !ok {
        return fmt.Errorf("MyCodec requires *map[string]any, got %T", v)
    }
    // ...
}
```

### 3. Use init() for Registration

Register codecs in `init()` for automatic setup:

```go
func init() {
    codec.RegisterEncoder("myformat", MyCodec{})
    codec.RegisterDecoder("myformat", MyCodec{})
}
```

### 4. Thread Safety

Ensure your codec is thread-safe:

```go
type MyCodec struct {
    // No mutable state
}

// OR use proper synchronization
type MyCodec struct {
    mu    sync.Mutex
    cache map[string]any
}
```

### 5. Document Your Codec

Include usage examples:

```go
// MyCodec implements encoding/decoding for the XYZ format.
//
// Example usage:
//
//   import _ "yourmodule/mycodec"
//
//   cfg := config.MustNew(
//       config.WithFileAs("config.xyz", "xyz"),
//   )
//
type MyCodec struct{}
```

## Complete Example

```go
package main

import (
    "context"
    "log"
    "rivaas.dev/config"
    _ "yourmodule/xmlcodec"   // Custom XML codec
    _ "yourmodule/inicodec"   // Custom INI codec
)

func main() {
    cfg := config.MustNew(
        config.WithFile("config.yaml"),           // Built-in YAML
        config.WithFileAs("config.xml", "xml"), // Custom XML
        config.WithFileAs("config.ini", "ini"), // Custom INI
        config.WithEnv("MYAPP_"),                  // Built-in EnvVar
    )

    if err := cfg.Load(context.Background()); err != nil {
        log.Fatalf("failed to load config: %v", err)
    }

    port := cfg.Int("server.port")
    host := cfg.String("server.host")
    
    log.Printf("Server: %s:%d", host, port)
}
```

## Testing Custom Codecs

Write tests for your codecs:

```go
func TestMyCodec_Decode(t *testing.T) {
    codec := MyCodec{}
    
    input := []byte(`
        [server]
        host = localhost
        port = 8080
    `)
    
    var result map[string]any
    err := codec.Decode(input, &result)
    
    assert.NoError(t, err)
    assert.Equal(t, "localhost", result["server"].(map[string]any)["host"])
    assert.Equal(t, "8080", result["server"].(map[string]any)["port"])
}

func TestMyCodec_Encode(t *testing.T) {
    codec := MyCodec{}
    
    data := map[string]any{
        "server": map[string]any{
            "host": "localhost",
            "port": 8080,
        },
    }
    
    output, err := codec.Encode(data)
    
    assert.NoError(t, err)
    assert.Contains(t, string(output), "[server]")
    assert.Contains(t, string(output), "host = localhost")
}
```

## Next Steps

- See [Examples](../examples/) for real-world codec usage
- Review [Codecs Reference](/reference/packages/config/codecs/) for technical details
- Explore [Multiple Sources](../multiple-sources/) for combining custom formats

**Tip:** If you create a useful codec, consider contributing it to the community!
