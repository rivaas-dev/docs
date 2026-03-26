---
title: "MCP Options"
linkTitle: "MCP Options"
keywords:
  - mcp options
  - mcp tools
  - mcp resources
  - model context protocol
  - ai api
weight: 8
description: >
  Business-facing MCP server configuration options reference.
---

## MCP Options

These options are used with `WithMCP()`:

```go
app.WithMCP(
    app.WithMCPTool("search", "Search products", handler,
        app.WithMCPStringInput("query", "Search text", app.MCPRequired()),
    ),
    app.WithMCPResource("products://catalog", "Catalog", "Full catalog", catalogHandler),
)
```

## Server Options

### WithMCP

```go
func WithMCP(opts ...MCPOption) Option
```

Enables the business-facing MCP server and applies the given options. The server is mounted at `/mcp` by default.

### WithMCPIf

```go
func WithMCPIf(cond bool, opts ...MCPOption) Option
```

Conditionally enables the MCP server based on a boolean condition. When `cond` is false, the option is a no-op.

### WithMCPPrefix

```go
func WithMCPPrefix(prefix string) MCPOption
```

Sets the mount prefix for the MCP server.

**Default:** `"/mcp"`

## Tool Registration

### WithMCPTool

```go
func WithMCPTool(name, description string, handler MCPToolHandler, inputs ...MCPInputOption) MCPOption
```

Registers a tool on the MCP server.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `string` | Unique tool name (must be non-empty) |
| `description` | `string` | Human-readable description shown to AI agents (must be non-empty) |
| `handler` | `MCPToolHandler` | Function called when the tool is invoked (must be non-nil) |
| `inputs` | `...MCPInputOption` | Input parameter definitions (nil values produce a validation error) |

Validation at init:

- A nil `handler` produces a configuration error.
- A nil `MCPInputOption` or nil `MCPParamOption` produces a configuration error.
- Duplicate tool names produce a configuration error.
- An empty `name` or `description` produces a configuration error.

### WithMCPResource

```go
func WithMCPResource(uri, name, description string, handler MCPResourceHandler) MCPOption
```

Registers a resource on the MCP server.

| Parameter | Type | Description |
|-----------|------|-------------|
| `uri` | `string` | Resource URI (e.g. `orders://recent`) |
| `name` | `string` | Human-readable resource name |
| `description` | `string` | Description shown to AI agents |
| `handler` | `MCPResourceHandler` | Function called when the resource is read (must be non-nil) |

A nil `handler` produces a configuration error at init.

## Handler Types

### MCPToolHandler

```go
type MCPToolHandler func(ctx context.Context, args MCPToolArgs) (any, error)
```

Handler for tool invocations. Return any JSON-serializable value. If an error is returned, it is sent as a tool error result.

### MCPResourceHandler

```go
type MCPResourceHandler func(ctx context.Context) (any, error)
```

Handler for resource reads. Return any JSON-serializable value.

## MCPToolArgs

Type-safe access to tool input arguments.

### Constructor

```go
func NewMCPToolArgs(args map[string]any) MCPToolArgs
```

Creates an `MCPToolArgs` from a raw argument map. Useful in tests to construct tool arguments without going through mcp-go.

### Zero-Value Accessors

Return the zero value if the argument is missing or has the wrong type:

| Method | Signature | Zero Value |
|--------|-----------|------------|
| `String` | `String(name string) string` | `""` |
| `StringDefault` | `StringDefault(name, def string) string` | `def` |
| `Float` | `Float(name string) float64` | `0.0` |
| `Int` | `Int(name string) int` | `0` |
| `Bool` | `Bool(name string) bool` | `false` |
| `Slice` | `Slice(name string) []any` | `nil` |
| `Map` | `Map(name string) map[string]any` | `nil` |

### Required Accessors

Return an error if the argument is missing or has the wrong type:

| Method | Signature |
|--------|-----------|
| `RequireString` | `RequireString(name string) (string, error)` |
| `RequireFloat` | `RequireFloat(name string) (float64, error)` |
| `RequireInt` | `RequireInt(name string) (int, error)` |
| `RequireBool` | `RequireBool(name string) (bool, error)` |

## Input Constructors

Six input types, aligned 1:1 with the MCP specification:

| Constructor | JSON Schema type | Description |
|------------|-----------------|-------------|
| `WithMCPStringInput` | `string` | Text input |
| `WithMCPNumberInput` | `number` | Floating-point number |
| `WithMCPIntegerInput` | `integer` | Whole number |
| `WithMCPBooleanInput` | `boolean` | True/false |
| `WithMCPArrayInput` | `array` | List of items |
| `WithMCPObjectInput` | `object` | Key-value structure |

All constructors share the same signature:

```go
func WithMCP<Type>Input(name, description string, opts ...MCPParamOption) MCPInputOption
```

## MCPParamOption Modifiers

| Modifier | Signature | Applies to |
|----------|-----------|------------|
| `MCPRequired()` | `MCPParamOption` | all types |
| `MCPDefault(v any)` | `MCPParamOption` | string, number, integer, boolean |
| `MCPEnum(values ...string)` | `MCPParamOption` | string |
| `MCPMinLength(n int)` | `MCPParamOption` | string |
| `MCPMaxLength(n int)` | `MCPParamOption` | string |
| `MCPPattern(pattern string)` | `MCPParamOption` | string |
| `MCPMinimum(v float64)` | `MCPParamOption` | number, integer |
| `MCPMaximum(v float64)` | `MCPParamOption` | number, integer |
| `MCPExclusiveMaximum(v float64)` | `MCPParamOption` | number |
| `MCPItems(schema map[string]any)` | `MCPParamOption` | array |
| `MCPProperties(schema map[string]any)` | `MCPParamOption` | object |

### Full Applicability Table

| Modifier | string | number | integer | boolean | array | object |
|----------|--------|--------|---------|---------|-------|--------|
| `MCPRequired` | yes | yes | yes | yes | yes | yes |
| `MCPDefault` | yes | yes | yes | yes | — | — |
| `MCPEnum` | yes | — | — | — | — | — |
| `MCPMinLength` | yes | — | — | — | — | — |
| `MCPMaxLength` | yes | — | — | — | — | — |
| `MCPPattern` | yes | — | — | — | — | — |
| `MCPMinimum` | — | yes | yes | — | — | — |
| `MCPMaximum` | — | yes | yes | — | — | — |
| `MCPExclusiveMaximum` | — | yes | — | — | — | — |
| `MCPItems` | — | — | — | — | yes | — |
| `MCPProperties` | — | — | — | — | — | yes |

Mismatched modifiers (e.g. `MCPMinLength` on a number) are silently ignored (consistent with `mcp-go`). However, nil options and nil handlers always produce a configuration error.

## Endpoints Registered

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/mcp` | MCP Streamable HTTP (listen for notifications) |
| `POST` | `/mcp` | MCP Streamable HTTP (send requests) |
| `DELETE` | `/mcp` | MCP Streamable HTTP (close session) |

The path changes when `WithMCPPrefix` is used.

## Example

```go
app.WithMCP(
    app.WithMCPPrefix("/api/mcp"),

    app.WithMCPTool("search_products", "Search the product catalog",
        func(ctx context.Context, args app.MCPToolArgs) (any, error) {
            query, _ := args.RequireString("query")
            return productService.Search(ctx, query)
        },
        app.WithMCPStringInput("query", "Search query", app.MCPRequired(), app.MCPMinLength(1)),
        app.WithMCPNumberInput("min_price", "Minimum price", app.MCPMinimum(0)),
        app.WithMCPIntegerInput("page", "Page number", app.MCPMinimum(1), app.MCPDefault(1.0)),
        app.WithMCPBooleanInput("in_stock", "Only in-stock", app.MCPDefault(false)),
    ),

    app.WithMCPResource("orders://recent", "Recent Orders",
        "The 10 most recently placed orders",
        func(ctx context.Context) (any, error) {
            return orderService.ListRecent(ctx, 10)
        },
    ),
)
```
