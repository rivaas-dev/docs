---
title: "Request Data Binding"
linkTitle: "Binding"
description: "Learn how to bind HTTP request data to Go structs with type safety and performance"
weight: 3
---

{{% pageinfo %}}
The Rivaas Binding package provides high-performance request data binding for Go web applications, mapping values from various sources (query parameters, form data, JSON bodies, headers, cookies, path parameters) into Go structs using struct tags.
{{% /pageinfo %}}

## Features

- **Multiple Sources** - Query, path, form, header, cookie, JSON, XML, YAML, TOML, MessagePack, Protocol Buffers
- **Type Safe** - Generic API for compile-time type safety
- **Zero Allocation** - Struct reflection info cached for performance
- **Flexible** - Nested structs, slices, maps, pointers, custom types
- **Error Context** - Detailed field-level error information
- **Extensible** - Custom type converters and value getters

> **Note:** For validation (required fields, enum constraints, etc.), use the `rivaas.dev/validation` package separately after binding.

## Quick Start

{{< tabpane persist=header >}}
{{< tab header="JSON" lang="go" >}}
import "rivaas.dev/binding"

type CreateUserRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
    Age   int    `json:"age"`
}

// Generic API (preferred)
user, err := binding.JSON[CreateUserRequest](body)
if err != nil {
    // Handle error
}
{{< /tab >}}
{{< tab header="Query" lang="go" >}}
import "rivaas.dev/binding"

type ListParams struct {
    Page   int      `query:"page" default:"1"`
    Limit  int      `query:"limit" default:"20"`
    Tags   []string `query:"tags"`
    SortBy string   `query:"sort_by"`
}

params, err := binding.Query[ListParams](r.URL.Query())
{{< /tab >}}
{{< tab header="Multi-Source" lang="go" >}}
import "rivaas.dev/binding"

type CreateOrderRequest struct {
    // From path parameters
    UserID int `path:"user_id"`
    
    // From query string
    Coupon string `query:"coupon"`
    
    // From headers
    Auth string `header:"Authorization"`
    
    // From JSON body
    Items []OrderItem `json:"items"`
    Total float64     `json:"total"`
}

req, err := binding.Bind[CreateOrderRequest](
    binding.FromPath(pathParams),
    binding.FromQuery(r.URL.Query()),
    binding.FromHeader(r.Header),
    binding.FromJSON(body),
)
{{< /tab >}}
{{< /tabpane >}}

## Learning Path

Follow these guides to master request data binding with Rivaas:

1. [**Installation**](installation/) - Get started with the binding package
2. [**Basic Usage**](basic-usage/) - Learn the fundamentals of binding data
3. [**Query Parameters**](query-parameters/) - Work with URL query strings
4. [**JSON Binding**](json-binding/) - Handle JSON request bodies
5. [**Multi-Source**](multi-source/) - Combine data from multiple sources
6. [**Struct Tags**](struct-tags/) - Master struct tag syntax and options
7. [**Type Support**](type-support/) - Built-in and custom type conversion
8. [**Error Handling**](error-handling/) - Handle binding errors gracefully
9. [**Advanced Usage**](advanced-usage/) - Custom getters, streaming, and more
10. [**Examples**](examples/) - Real-world integration patterns

## Supported Sources

| Source | Function | Description |
|--------|----------|-------------|
| Query | `Query[T]()` | URL query parameters (`?name=value`) |
| Path | `Path[T]()` | URL path parameters (`/users/:id`) |
| Form | `Form[T]()` | Form data (`application/x-www-form-urlencoded`) |
| Header | `Header[T]()` | HTTP headers |
| Cookie | `Cookie[T]()` | HTTP cookies |
| JSON | `JSON[T]()` | JSON body |
| XML | `XML[T]()` | XML body |
| YAML | `yaml.YAML[T]()` | YAML body (sub-package) |
| TOML | `toml.TOML[T]()` | TOML body (sub-package) |
| MessagePack | `msgpack.MsgPack[T]()` | MessagePack body (sub-package) |
| Protocol Buffers | `proto.Proto[T]()` | Protobuf body (sub-package) |

## Why Generic API?

The binding package uses Go generics for compile-time type safety:

```go
// Generic API (preferred) - Type-safe at compile time
user, err := binding.JSON[CreateUserRequest](body)

// Non-generic API - When type comes from variable
var user CreateUserRequest
err := binding.JSONTo(body, &user)
```

**Benefits:**
- ✅ Compile-time type checking
- ✅ No reflection overhead for type instantiation
- ✅ Better IDE autocomplete
- ✅ Cleaner, more readable code

## Performance

- **First binding** of a type: ~500ns overhead for reflection
- **Subsequent bindings**: ~50ns overhead (cache lookup)
- **Query/Path/Form**: Zero allocations for primitive types
- **Struct reflection info** cached automatically

## Next Steps

- Start with [Installation](installation/) to set up the binding package
- Explore the [API Reference](/reference/packages/binding/) for complete technical details
- Check out [examples](examples/) for real-world integration patterns

For integration with rivaas/app, the Context provides a convenient `Bind()` method that handles all the complexity automatically.
