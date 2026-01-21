---
title: "Sub-Packages"
description: "YAML, TOML, MessagePack, and Protocol Buffers support"
keywords:
  - sub packages
  - binder packages
  - binding modules
  - package structure
weight: 3
---

Reference for sub-packages that add support for additional data formats beyond the core package.

## Package Overview

| Sub-Package | Format | Import Path |
|-------------|--------|-------------|
| `yaml` | YAML | `rivaas.dev/binding/yaml` |
| `toml` | TOML | `rivaas.dev/binding/toml` |
| `msgpack` | MessagePack | `rivaas.dev/binding/msgpack` |
| `proto` | Protocol Buffers | `rivaas.dev/binding/proto` |

## YAML Package

### Import

```go
import "rivaas.dev/binding/yaml"
```

### Functions

#### YAML

```go
func YAML[T any](data []byte, opts ...Option) (T, error)
```

Binds YAML data to a struct.

**Example:**
```go
type Config struct {
    Name  string `yaml:"name"`
    Port  int    `yaml:"port"`
    Debug bool   `yaml:"debug"`
}

config, err := yaml.YAML[Config](yamlData)
```

#### YAMLReader

```go
func YAMLReader[T any](r io.Reader, opts ...Option) (T, error)
```

Binds YAML from an `io.Reader`.

**Example:**
```go
config, err := yaml.YAMLReader[Config](r.Body)
```

#### YAMLTo

```go
func YAMLTo(data []byte, target interface{}, opts ...Option) error
```

Non-generic variant.

### Options

#### WithStrict

```go
func WithStrict() Option
```

Enables strict YAML parsing. Fails on unknown fields or duplicate keys.

**Example:**
```go
config, err := yaml.YAML[Config](data, yaml.WithStrict())
```

### Struct Tags

Use `yaml` struct tags:

```go
type Config struct {
    Name  string `yaml:"name"`
    Port  int    `yaml:"port"`
    Debug bool   `yaml:"debug,omitempty"`
    
    // Inline nested struct
    Database struct {
        Host string `yaml:"host"`
        Port int    `yaml:"port"`
    } `yaml:"database"`
    
    // Ignore field
    Internal string `yaml:"-"`
}
```

### Example

```yaml
# config.yaml
name: my-app
port: 8080
debug: true
database:
  host: localhost
  port: 5432
```

```go
data, _ := os.ReadFile("config.yaml")
config, err := yaml.YAML[Config](data)
```

## TOML Package

### Import

```go
import "rivaas.dev/binding/toml"
```

### Functions

#### TOML

```go
func TOML[T any](data []byte, opts ...Option) (T, error)
```

Binds TOML data to a struct.

**Example:**
```go
type Config struct {
    Name  string `toml:"name"`
    Port  int    `toml:"port"`
    Debug bool   `toml:"debug"`
}

config, err := toml.TOML[Config](tomlData)
```

#### TOMLReader

```go
func TOMLReader[T any](r io.Reader, opts ...Option) (T, error)
```

Binds TOML from an `io.Reader`.

#### TOMLTo

```go
func TOMLTo(data []byte, target interface{}, opts ...Option) error
```

Non-generic variant.

### Struct Tags

Use `toml` struct tags:

```go
type Config struct {
    Title string `toml:"title"`
    
    Owner struct {
        Name string `toml:"name"`
        DOB  time.Time `toml:"dob"`
    } `toml:"owner"`
    
    Database struct {
        Server  string `toml:"server"`
        Ports   []int  `toml:"ports"`
        Enabled bool   `toml:"enabled"`
    } `toml:"database"`
}
```

### Example

```toml
# config.toml
title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00

[database]
server = "192.168.1.1"
ports = [ 8000, 8001, 8002 ]
enabled = true
```

```go
data, _ := os.ReadFile("config.toml")
config, err := toml.TOML[Config](data)
```

## MessagePack Package

### Import

```go
import "rivaas.dev/binding/msgpack"
```

### Functions

#### MsgPack

```go
func MsgPack[T any](data []byte, opts ...Option) (T, error)
```

Binds MessagePack data to a struct.

**Example:**
```go
type Message struct {
    ID   int    `msgpack:"id"`
    Data []byte `msgpack:"data"`
    Time time.Time `msgpack:"time"`
}

msg, err := msgpack.MsgPack[Message](msgpackData)
```

#### MsgPackReader

```go
func MsgPackReader[T any](r io.Reader, opts ...Option) (T, error)
```

Binds MessagePack from an `io.Reader`.

**Example:**
```go
msg, err := msgpack.MsgPackReader[Message](r.Body)
```

#### MsgPackTo

```go
func MsgPackTo(data []byte, target interface{}, opts ...Option) error
```

Non-generic variant.

### Struct Tags

Use `msgpack` struct tags:

```go
type Message struct {
    ID      int       `msgpack:"id"`
    Type    string    `msgpack:"type"`
    Payload []byte    `msgpack:"payload"`
    Created time.Time `msgpack:"created"`
    
    // Omit if zero
    Metadata map[string]string `msgpack:"metadata,omitempty"`
    
    // Use as array (more compact)
    Points []int `msgpack:"points,as_array"`
}
```

### Use Cases

- High-performance binary serialization
- Microservice communication
- Event streaming
- Cache serialization

## Protocol Buffers Package

### Import

```go
import "rivaas.dev/binding/proto"
import pb "myapp/proto"  // Your generated proto files
```

### Functions

#### Proto

```go
func Proto[T proto.Message](data []byte, opts ...Option) (T, error)
```

Binds Protocol Buffer data to a proto message.

**Example:**
```go
import pb "myapp/proto"

user, err := proto.Proto[*pb.User](protoData)
```

#### ProtoReader

```go
func ProtoReader[T proto.Message](r io.Reader, opts ...Option) (T, error)
```

Binds Protocol Buffers from an `io.Reader`.

**Example:**
```go
user, err := proto.ProtoReader[*pb.User](r.Body)
```

#### ProtoTo

```go
func ProtoTo(data []byte, target proto.Message, opts ...Option) error
```

Non-generic variant.

### Proto Definition

```protobuf
// user.proto
syntax = "proto3";

package example;
option go_package = "myapp/proto";

message User {
  int64 id = 1;
  string username = 2;
  string email = 3;
  int32 age = 4;
  repeated string tags = 5;
}
```

### Example

```go
import (
    "rivaas.dev/binding/proto"
    pb "myapp/proto"
)

func HandleProtoRequest(w http.ResponseWriter, r *http.Request) {
    user, err := proto.ProtoReader[*pb.User](r.Body)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Use user
    log.Printf("Received user: %s", user.Username)
}
```

### Use Cases

- gRPC services
- High-performance APIs
- Cross-language communication
- Schema evolution

## Common Patterns

### Configuration Files

```go
import (
    "rivaas.dev/binding/yaml"
    "rivaas.dev/binding/toml"
)

type Config struct {
    Name     string `yaml:"name" toml:"name"`
    Port     int    `yaml:"port" toml:"port"`
    Database struct {
        Host string `yaml:"host" toml:"host"`
        Port int    `yaml:"port" toml:"port"`
    } `yaml:"database" toml:"database"`
}

func LoadConfig(format, path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, err
    }
    
    switch format {
    case "yaml", "yml":
        return yaml.YAML[Config](data)
    case "toml":
        return toml.TOML[Config](data)
    default:
        return nil, fmt.Errorf("unsupported format: %s", format)
    }
}
```

### Content Negotiation

```go
func HandleRequest(w http.ResponseWriter, r *http.Request) {
    contentType := r.Header.Get("Content-Type")
    
    var req CreateUserRequest
    var err error
    
    switch {
    case strings.Contains(contentType, "application/json"):
        req, err = binding.JSON[CreateUserRequest](r.Body)
        
    case strings.Contains(contentType, "application/x-yaml"):
        req, err = yaml.YAMLReader[CreateUserRequest](r.Body)
        
    case strings.Contains(contentType, "application/toml"):
        req, err = toml.TOMLReader[CreateUserRequest](r.Body)
        
    case strings.Contains(contentType, "application/x-msgpack"):
        req, err = msgpack.MsgPackReader[CreateUserRequest](r.Body)
        
    default:
        http.Error(w, "Unsupported content type", http.StatusUnsupportedMediaType)
        return
    }
    
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Process request...
}
```

### Multi-Format API

```go
type API struct {
    yaml    *yaml.Binder
    toml    *toml.Binder
    msgpack *msgpack.Binder
}

func NewAPI() *API {
    return &API{
        yaml:    yaml.MustNew(yaml.WithStrict()),
        toml:    toml.MustNew(),
        msgpack: msgpack.MustNew(),
    }
}

func (a *API) Bind(r *http.Request, target interface{}) error {
    contentType := r.Header.Get("Content-Type")
    
    switch {
    case strings.Contains(contentType, "yaml"):
        return a.yaml.YAMLReaderTo(r.Body, target)
    case strings.Contains(contentType, "toml"):
        return a.toml.TOMLReaderTo(r.Body, target)
    case strings.Contains(contentType, "msgpack"):
        return a.msgpack.MsgPackReaderTo(r.Body, target)
    default:
        return binding.JSONReaderTo(r.Body, target)
    }
}
```

## Dependencies

Sub-packages have external dependencies:

| Package | Dependency |
|---------|-----------|
| `yaml` | `gopkg.in/yaml.v3` |
| `toml` | `github.com/BurntSushi/toml` |
| `msgpack` | `github.com/vmihailenco/msgpack/v5` |
| `proto` | `google.golang.org/protobuf` |

Install with:

```bash
# YAML
go get gopkg.in/yaml.v3

# TOML
go get github.com/BurntSushi/toml

# MessagePack
go get github.com/vmihailenco/msgpack/v5

# Protocol Buffers
go get google.golang.org/protobuf
```

## Performance Comparison

Approximate performance for a typical struct (10 fields):

| Format | Speed (ns/op) | Allocs | Use Case |
|--------|---------------|--------|----------|
| JSON | 800 | 3 | Web APIs, human-readable |
| MessagePack | 500 | 2 | High performance, binary |
| Protocol Buffers | 400 | 2 | Strongly typed, cross-language |
| YAML | 1,200 | 5 | Configuration files |
| TOML | 1,000 | 4 | Configuration files |

## Best Practices

### 1. Use Appropriate Format

- **JSON**: Web APIs, JavaScript clients
- **YAML**: Configuration files, human-readable
- **TOML**: Configuration files, less ambiguous than YAML
- **MessagePack**: High-performance microservices
- **Protocol Buffers**: gRPC, schema evolution

### 2. Validate Input

All sub-packages support the same options as core binding:

```go
config, err := yaml.YAML[Config](data,
    binding.WithMaxDepth(16),
    binding.WithMaxSliceLen(1000),
)
```

### 3. Stream Large Files

Use Reader variants for large payloads:

```go
// Good - streams from disk
file, _ := os.Open("large-config.yaml")
config, err := yaml.YAMLReader[Config](file)

// Bad - loads entire file into memory
data, _ := os.ReadFile("large-config.yaml")
config, err := yaml.YAML[Config](data)
```

## See Also

- **[API Reference](../api-reference/)** - Core binding functions
- **[Options](../options/)** - Configuration options
- **[Performance](../performance/)** - Optimization guide

For usage examples, see the [Binding Guide](/guides/binding/).
