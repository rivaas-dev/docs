---
title: "MCP Server"
linkTitle: "MCP"
weight: 13
keywords:
  - mcp
  - model context protocol
  - ai
  - llm
  - tools
  - resources
  - api
description: >
  Expose business tools and resources to AI agents via the Model Context Protocol (MCP).
---

## Overview

The app package lets you expose business logic to AI agents using the [Model Context Protocol](https://modelcontextprotocol.io). MCP provides a standard way for LLMs to call your application's functions and read its data.

Think of it as dual-protocol: your HTTP API serves humans and traditional clients, while MCP serves AI agents — same business logic, two entry points.

Developers register tools and resources using Rivaas-native types. There is no need to import `mcp-go` directly.

## Defining a Tool

A tool is a function that an AI agent can call. Register tools with `WithMCPTool`:

```go
app.WithMCP(
    app.WithMCPTool("get_order", "Get an order by ID",
        func(ctx context.Context, args app.MCPToolArgs) (any, error) {
            id, err := args.RequireString("order_id")
            if err != nil {
                return nil, err
            }
            return orderService.GetByID(ctx, id)
        },
        app.WithMCPStringInput("order_id", "The order ID", app.MCPRequired()),
    ),
)
```

The handler receives `MCPToolArgs` for type-safe argument access. Return any JSON-serializable value, or an error.

## Defining a Resource

A resource is a read-only data source that an AI agent can fetch. Register resources with `WithMCPResource`:

```go
app.WithMCP(
    app.WithMCPResource("orders://recent", "Recent Orders",
        "The 10 most recently placed orders",
        func(ctx context.Context) (any, error) {
            return orderService.ListRecent(ctx, 10)
        },
    ),
)
```

## Input Parameters

Tools accept typed input parameters. There are six input types, aligned with the MCP specification:

### String

```go
app.WithMCPStringInput("name", "User name",
    app.MCPRequired(),
    app.MCPMinLength(1),
    app.MCPMaxLength(100),
)

app.WithMCPStringInput("category", "Category filter",
    app.MCPEnum("electronics", "clothing", "books"),
)

app.WithMCPStringInput("email", "Email address",
    app.MCPPattern(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`),
)
```

### Number

```go
app.WithMCPNumberInput("price", "Price in USD",
    app.MCPMinimum(0),
    app.MCPMaximum(10000),
    app.MCPDefault(0.0),
)
```

### Integer

```go
app.WithMCPIntegerInput("page", "Page number",
    app.MCPMinimum(1),
    app.MCPDefault(1.0),
)
```

### Boolean

```go
app.WithMCPBooleanInput("in_stock_only", "Only show in-stock items",
    app.MCPDefault(false),
)
```

### Array

```go
app.WithMCPArrayInput("tags", "Filter by tags",
    app.MCPItems(map[string]any{"type": "string"}),
)
```

### Object

```go
app.WithMCPObjectInput("filters", "Advanced query filters",
    app.MCPProperties(map[string]any{
        "status": map[string]any{"type": "string"},
        "min_date": map[string]any{"type": "string"},
    }),
)
```

### Modifier Applicability

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

Mismatched modifiers (e.g. `MCPMinLength` on a number) are silently ignored (consistent with the MCP specification). However, nil options and nil handlers always produce a configuration error at init.

## Accessing Arguments

`MCPToolArgs` provides type-safe access with two variants:

**Zero-value accessors** return the zero value if the argument is missing:

```go
name := args.String("name")        // "" if missing
price := args.Float("price")       // 0.0 if missing
page := args.Int("page")           // 0 if missing
active := args.Bool("active")      // false if missing
tags := args.Slice("tags")         // nil if missing
meta := args.Map("meta")           // nil if missing
name := args.StringDefault("name", "anonymous")
```

In tests, use `NewMCPToolArgs(map[string]any{...})` to construct args without going through mcp-go.

**Required accessors** return an error if the argument is missing or has the wrong type:

```go
name, err := args.RequireString("name")
price, err := args.RequireFloat("price")
page, err := args.RequireInt("page")
active, err := args.RequireBool("active")
```

## Validation

Rivaas validates MCP configuration at init. These errors surface from `app.New()`:

- **Nil handler**: `WithMCPTool` and `WithMCPResource` require a non-nil handler.
- **Nil options**: Nil `MCPOption`, `MCPInputOption`, or `MCPParamOption` values produce an error (not silently skipped).
- **Duplicate tool names**: Each tool name must be unique.
- **Empty names or descriptions**: Tool names and descriptions must be non-empty.

## Security Considerations

MCP is opt-in. It is only enabled when you call `WithMCP()`.

For conditional enablement, use `WithMCPIf`:

```go
app.WithMCPIf(os.Getenv("MCP_ENABLED") == "true",
    app.WithMCPTool(...),
)
```

In production, protect MCP endpoints with authentication middleware, just like your HTTP API.

## Complete Example

```go
package main

import (
    "context"
    "log"
    "net/http"

    "rivaas.dev/app"
)

func main() {
    a, err := app.New(
        app.WithServiceName("orders-api"),
        app.WithServiceVersion("v1.0.0"),

        app.WithMCP(
            app.WithMCPTool("search_products", "Search the product catalog",
                func(ctx context.Context, args app.MCPToolArgs) (any, error) {
                    query, _ := args.RequireString("query")
                    minPrice := args.Float("min_price")
                    inStockOnly := args.Bool("in_stock_only")
                    page := args.Int("page")
                    return productService.Search(ctx, query, minPrice, inStockOnly, page)
                },
                app.WithMCPStringInput("query", "Search query", app.MCPRequired(), app.MCPMinLength(1)),
                app.WithMCPStringInput("category", "Category", app.MCPEnum("electronics", "clothing", "books")),
                app.WithMCPNumberInput("min_price", "Minimum price", app.MCPMinimum(0), app.MCPDefault(0.0)),
                app.WithMCPBooleanInput("in_stock_only", "Only in-stock", app.MCPDefault(false)),
                app.WithMCPIntegerInput("page", "Page number", app.MCPMinimum(1), app.MCPDefault(1.0)),
            ),

            app.WithMCPResource("orders://recent", "Recent Orders",
                "The 10 most recently placed orders",
                func(ctx context.Context) (any, error) {
                    return orderService.ListRecent(ctx, 10)
                },
            ),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // HTTP API for humans
    a.GET("/products", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{"message": "use the API"})
    })

    // MCP server for AI agents: http://localhost:8080/mcp

    if err = a.Start(context.Background()); err != nil {
        log.Fatal(err)
    }
}
```

## Next Steps

- [MCP Debug](../mcp-debug/) - Expose runtime internals to AI tools
- [Debug Endpoints](../debug-endpoints/) - pprof profiling
- [OpenAPI](../openapi/) - Generate OpenAPI specs
