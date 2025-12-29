---
title: "Type Support"
description: "Complete reference for all supported data types and conversions"
weight: 8
---

Comprehensive guide to type support in the binding package, including automatic conversions, custom types, and edge cases.

## Supported Types

The binding package supports a wide range of Go types with automatic conversion:

### Basic Types

```go
type BasicTypes struct {
    // String
    Name string `json:"name"`
    
    // Integers
    Int    int    `json:"int"`
    Int8   int8   `json:"int8"`
    Int16  int16  `json:"int16"`
    Int32  int32  `json:"int32"`
    Int64  int64  `json:"int64"`
    
    // Unsigned integers
    Uint   uint   `json:"uint"`
    Uint8  uint8  `json:"uint8"`
    Uint16 uint16 `json:"uint16"`
    Uint32 uint32 `json:"uint32"`
    Uint64 uint64 `json:"uint64"`
    
    // Floats
    Float32 float32 `json:"float32"`
    Float64 float64 `json:"float64"`
    
    // Boolean
    Active bool `json:"active"`
    
    // Byte (alias for uint8)
    Byte byte `json:"byte"`
    
    // Rune (alias for int32)
    Rune rune `json:"rune"`
}
```

## String Conversions

### From Query/Header

```go
type StringParams struct {
    Name  string `query:"name"`
    Value string `header:"X-Value"`
}

// URL: ?name=John+Doe
// Header: X-Value: hello world
// Result: {Name: "John Doe", Value: "hello world"}
```

### From JSON

```go
type JSONStrings struct {
    Text string `json:"text"`
}

// JSON: {"text": "hello"}
// Result: {Text: "hello"}
```

### Empty Strings

```go
type Optional struct {
    // Empty string is valid
    Name string `json:"name"`  // "" is kept
    
    // Use pointer for "not provided"
    Bio *string `json:"bio"`  // nil if not in JSON
}
```

## Integer Conversions

### From Strings

```go
type Numbers struct {
    Age   int   `query:"age"`
    Count int64 `header:"X-Count"`
}

// URL: ?age=30
// Header: X-Count: 1000000
// Result: {Age: 30, Count: 1000000}
```

### From JSON

```go
type JSONNumbers struct {
    ID    int   `json:"id"`
    Count int64 `json:"count"`
}

// JSON: {"id": 42, "count": 9223372036854775807}
```

### Overflow Handling

```go
type SmallInt struct {
    Value int8 `json:"value"`
}

// JSON: {"value": 200}
// Error: value 200 overflows int8 (max 127)
```

## Float Conversions

### From Strings

```go
type Floats struct {
    Price  float64 `query:"price"`
    Rating float32 `query:"rating"`
}

// URL: ?price=19.99&rating=4.5
// Result: {Price: 19.99, Rating: 4.5}
```

### Scientific Notation

```go
// URL: ?value=1.23e10
// Result: Value = 12300000000.0
```

### Special Values

```go
type SpecialFloats struct {
    Value float64 `query:"value"`
}

// URL: ?value=inf  -> +Inf
// URL: ?value=-inf -> -Inf
// URL: ?value=nan  -> NaN
```

## Boolean Conversions

### True Values

```go
type Flags struct {
    Debug bool `query:"debug"`
}

// All parse to true:
// ?debug=true
// ?debug=1
// ?debug=yes
// ?debug=on
// ?debug=t
// ?debug=y
```

### False Values

```go
// All parse to false:
// ?debug=false
// ?debug=0
// ?debug=no
// ?debug=off
// ?debug=f
// ?debug=n
// (parameter not present)
```

### Case Insensitive

```go
// All parse to true:
// ?debug=TRUE
// ?debug=True
// ?debug=tRuE
```

## Time Types

### time.Time

```go
type TimeFields struct {
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `query:"updated_at"`
}

// Supported formats:
// - RFC3339: "2025-01-01T00:00:00Z"
// - RFC3339Nano: "2025-01-01T00:00:00.123456789Z"
// - Date only: "2025-01-01"
// - Unix timestamp: "1735689600"
```

### time.Duration

```go
type Timeouts struct {
    Timeout   time.Duration `json:"timeout"`
    RetryAfter time.Duration `query:"retry_after"`
}

// Supported formats:
// - "300ms" -> 300 milliseconds
// - "1.5s" -> 1.5 seconds
// - "2m30s" -> 2 minutes 30 seconds
// - "1h30m" -> 1 hour 30 minutes
// - "24h" -> 24 hours

// URL: ?retry_after=30s
// JSON: {"timeout": "5m"}
// Result: {Timeout: 5*time.Minute, RetryAfter: 30*time.Second}
```

## Slices and Arrays

### String Slices

```go
type Lists struct {
    Tags []string `query:"tags"`
}

// Repeated parameters (default):
// ?tags=go&tags=rust&tags=python
// Result: {Tags: ["go", "rust", "python"]}

// CSV mode:
// ?tags=go,rust,python
params, err := binding.Query[Lists](
    values,
    binding.WithSliceMode(binding.SliceCSV),
)
// Result: {Tags: ["go", "rust", "python"]}
```

### Integer Slices

```go
type IDList struct {
    IDs []int `query:"ids"`
}

// URL: ?ids=1&ids=2&ids=3
// Result: {IDs: [1, 2, 3]}
```

### Float Slices

```go
type Prices struct {
    Values []float64 `json:"values"`
}

// JSON: {"values": [19.99, 29.99, 39.99]}
```

### Arrays (Fixed Size)

```go
type FixedArray struct {
    RGB [3]int `json:"rgb"`
}

// JSON: {"rgb": [255, 128, 0]}
// Result: {RGB: [255, 128, 0]}

// JSON: {"rgb": [255, 128]}
// Error: array length mismatch
```

### Nested Slices

```go
type Matrix struct {
    Grid [][]int `json:"grid"`
}

// JSON: {"grid": [[1,2,3], [4,5,6], [7,8,9]]}
```

## Maps

### String Maps

```go
type StringMaps struct {
    Metadata map[string]string `json:"metadata"`
    Labels   map[string]string `json:"labels"`
}

// JSON: {"metadata": {"key1": "value1", "key2": "value2"}}
```

### Typed Maps

```go
type TypedMaps struct {
    Counters map[string]int     `json:"counters"`
    Prices   map[string]float64 `json:"prices"`
    Flags    map[string]bool    `json:"flags"`
}

// JSON: {
//   "counters": {"views": 100, "likes": 50},
//   "prices": {"basic": 9.99, "premium": 29.99},
//   "flags": {"enabled": true, "public": false}
// }
```

### Interface Maps

```go
type FlexibleMap struct {
    Settings map[string]interface{} `json:"settings"`
}

// JSON: {
//   "settings": {
//     "name": "app",
//     "port": 8080,
//     "debug": true,
//     "features": ["a", "b", "c"]
//   }
// }
```

### Nested Maps

```go
type NestedMaps struct {
    Config map[string]map[string]string `json:"config"`
}

// JSON: {
//   "config": {
//     "database": {"host": "localhost", "port": "5432"},
//     "cache": {"host": "localhost", "port": "6379"}
//   }
// }
```

## Pointers

### Basic Pointers

```go
type Pointers struct {
    // nil = not provided, &0 = explicitly zero
    Age *int `json:"age"`
    
    // nil = not provided, &"" = explicitly empty
    Bio *string `json:"bio"`
    
    // nil = not provided, &false = explicitly false
    Active *bool `json:"active"`
}

// JSON: {"age": 0, "bio": "", "active": false}
// Result: {Age: &0, Bio: &"", Active: &false}

// JSON: {}
// Result: {Age: nil, Bio: nil, Active: nil}
```

### Pointer Semantics

```go
type Update struct {
    Name *string `json:"name"`
}

// Distinguish between:
// 1. Not updating: {"other_field": "value"}
//    -> Name = nil (don't update)
// 
// 2. Setting to empty: {"name": ""}
//    -> Name = &"" (update to empty)
// 
// 3. Setting value: {"name": "John"}
//    -> Name = &"John" (update to John)
```

### Double Pointers

```go
type DoublePointer struct {
    Value **int `json:"value"`
}

// Supported but rarely needed
```

## Structs

### Nested Structs

```go
type Order struct {
    ID string `json:"id"`
    Customer struct {
        Name  string `json:"name"`
        Email string `json:"email"`
    } `json:"customer"`
    Items []struct {
        ID    string  `json:"id"`
        Price float64 `json:"price"`
    } `json:"items"`
}
```

### Embedded Structs

```go
type Base struct {
    ID        int       `json:"id"`
    CreatedAt time.Time `json:"created_at"`
}

type User struct {
    Base  // Embedded - fields promoted
    Name  string `json:"name"`
    Email string `json:"email"`
}

// JSON: {"id": 1, "created_at": "2025-01-01T00:00:00Z", "name": "John"}
```

### Anonymous Structs

```go
type Response struct {
    Data struct {
        Message string `json:"message"`
        Code    int    `json:"code"`
    } `json:"data"`
}
```

## Interfaces

### Empty Interface

```go
type Flexible struct {
    Data interface{} `json:"data"`
}

// JSON: {"data": "string"}  -> Data = "string"
// JSON: {"data": 42}        -> Data = float64(42)
// JSON: {"data": true}      -> Data = true
// JSON: {"data": [1,2,3]}   -> Data = []interface{}{1,2,3}
// JSON: {"data": {"k":"v"}} -> Data = map[string]interface{}{"k":"v"}
```

### Type Assertions

```go
func handleData(d interface{}) {
    switch v := d.(type) {
    case string:
        fmt.Println("String:", v)
    case float64:
        fmt.Println("Number:", v)
    case bool:
        fmt.Println("Boolean:", v)
    case []interface{}:
        fmt.Println("Array:", v)
    case map[string]interface{}:
        fmt.Println("Object:", v)
    }
}
```

## Custom Types

### Type Aliases

```go
type UserID int
type Email string

type User struct {
    ID    UserID `json:"id"`
    Email Email  `json:"email"`
}

// Binds like underlying type
// JSON: {"id": 123, "email": "test@example.com"}
```

### Custom Unmarshalers

Implement `json.Unmarshaler` for custom parsing:

```go
type CustomDuration time.Duration

func (cd *CustomDuration) UnmarshalJSON(b []byte) error {
    var s string
    if err := json.Unmarshal(b, &s); err != nil {
        return err
    }
    
    d, err := time.ParseDuration(s)
    if err != nil {
        return err
    }
    
    *cd = CustomDuration(d)
    return nil
}

type Config struct {
    Timeout CustomDuration `json:"timeout"`
}
```

### TextUnmarshaler

For query/header parsing:

```go
type Status string

const (
    StatusActive   Status = "active"
    StatusInactive Status = "inactive"
)

func (s *Status) UnmarshalText(text []byte) error {
    str := string(text)
    switch str {
    case "active", "inactive":
        *s = Status(str)
        return nil
    default:
        return fmt.Errorf("invalid status: %s", str)
    }
}

type Params struct {
    Status Status `query:"status"`
}

// URL: ?status=active
```

## Type Conversion Matrix

| Source Type | Target Type | Conversion | Example |
|-------------|-------------|------------|---------|
| `string` | `int` | Parse | `"42"` → `42` |
| `string` | `float64` | Parse | `"3.14"` → `3.14` |
| `string` | `bool` | Parse | `"true"` → `true` |
| `string` | `time.Duration` | Parse | `"30s"` → `30*time.Second` |
| `string` | `time.Time` | Parse | `"2025-01-01"` → `time.Time` |
| `number` | `int` | Cast | `42.0` → `42` |
| `number` | `string` | Format | `42` → `"42"` |
| `bool` | `string` | Format | `true` → `"true"` |
| `array` | `[]T` | Element-wise | `[1,2,3]` → `[]int{1,2,3}` |
| `object` | `struct` | Field-wise | `{"a":1}` → `struct{A int}` |
| `object` | `map` | Key-value | `{"a":1}` → `map[string]int` |

## Edge Cases

### Null vs Zero

```go
type Nullable struct {
    // Pointer distinguishes null from zero
    Count *int `json:"count"`
}

// JSON: {"count": null} -> Count = nil
// JSON: {"count": 0}    -> Count = &0
// JSON: {}              -> Count = nil
```

### Empty vs Missing

```go
type Optional struct {
    Name  string  `json:"name"`
    Email *string `json:"email"`
}

// JSON: {"name": "", "email": ""}
// Result: {Name: "", Email: &""}

// JSON: {"name": ""}
// Result: {Name: "", Email: nil}
```

### Overflow Protection

```go
// Protects against overflow
type SafeInt struct {
    Value int8 `json:"value"`
}

// JSON: {"value": 200}
// Error: value overflows int8
```

### Type Mismatches

```go
type Typed struct {
    Age int `json:"age"`
}

// JSON: {"age": "not a number"}
// Error: cannot unmarshal string into int
```

## Performance Characteristics

| Type | Allocation | Speed | Notes |
|------|------------|-------|-------|
| Primitives | Zero | Fast | Direct assignment |
| Strings | One | Fast | Immutable |
| Slices | One | Fast | Pre-allocated when possible |
| Maps | One | Medium | Hash allocation |
| Structs | Zero | Fast | Stack allocation |
| Pointers | One | Fast | Heap allocation |
| Interfaces | One | Medium | Type assertion overhead |

## Unsupported Types

The following types are **not** supported:

```go
type Unsupported struct {
    // Channel
    Ch chan int  // Not supported
    
    // Function
    Fn func()  // Not supported
    
    // Complex numbers
    C complex128  // Not supported
    
    // Unsafe pointer
    Ptr unsafe.Pointer  // Not supported
}
```

## Best Practices

### 1. Use Appropriate Types

```go
// Good - specific types
type Good struct {
    Age      int       `json:"age"`
    Price    float64   `json:"price"`
    Created  time.Time `json:"created"`
}

// Bad - generic types
type Bad struct {
    Age     interface{} `json:"age"`
    Price   interface{} `json:"price"`
    Created interface{} `json:"created"`
}
```

### 2. Use Pointers for Optional Fields

```go
type Update struct {
    Name *string `json:"name"`  // Can be null
    Age  *int    `json:"age"`   // Can be null
}
```

### 3. Use Slices for Variable-Length Data

```go
// Good - slice
type Good struct {
    Tags []string `json:"tags"`
}

// Bad - fixed array
type Bad struct {
    Tags [10]string `json:"tags"`  // Rigid
}
```

### 4. Document Custom Types

```go
// UserID represents a unique user identifier.
// It must be a positive integer.
type UserID int

// Validate ensures the UserID is valid.
func (id UserID) Validate() error {
    if id <= 0 {
        return errors.New("invalid user ID")
    }
    return nil
}
```

## Troubleshooting

### Type Conversion Errors

```go
// Error: cannot unmarshal string into int
// Solution: Check source data matches target type

// Error: value overflows int8
// Solution: Use larger type (int16, int32, int64)

// Error: parsing time "invalid" as "2006-01-02"
// Solution: Use correct time format
```

### Unexpected Nil Values

```go
// Problem: field is nil when expected
// Solution: Check if source provided the value

// Problem: can't distinguish nil from zero
// Solution: Use pointer type
```

## Next Steps

- Learn about [Error Handling](../error-handling/) for conversion errors
- Explore [Advanced Usage](../advanced-usage/) for custom converters
- See [Examples](../examples/) for type usage patterns
- Review [API Reference](/reference/packages/binding/api-reference/) for details

For complete API documentation, see [API Reference](/reference/packages/binding/api-reference/).
