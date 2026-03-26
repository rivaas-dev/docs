---
title: "MCP Debug Options"
linkTitle: "MCP Debug Options"
keywords:
  - mcp debug options
  - mcp debug
  - runtime introspection
  - ai debug
weight: 7
description: >
  MCP debug endpoint configuration options reference.
---

## MCP Debug Options

These options are used with `WithMCPDebug()` inside `WithDebugEndpoints()`:

```go
app.WithDebugEndpoints(
    app.WithMCPDebug(
        app.WithMCPDebugRuntime(),
        app.WithMCPDebugConfig(),
        app.WithMCPDebugBuild(),
    ),
)
```

## Option Functions

### WithMCPDebug

```go
func WithMCPDebug(opts ...MCPDebugOption) DebugOption
```

Enables the debug MCP server and applies the given options. The server is mounted at `{debug.prefix}/mcp` (default: `/_internal/debug/mcp`).

When called without sub-options, all features are enabled (runtime, config, build). This means `WithMCPDebug()` is equivalent to `WithMCPDebug(WithMCPDebugRuntime(), WithMCPDebugConfig(), WithMCPDebugBuild())`.

The mount point follows the debug prefix — when you use `WithDebugPrefix("/custom")`, the debug MCP server moves to `/custom/mcp`.

Nil options produce a configuration error at init (not silently ignored).

### WithMCPDebugIf

```go
func WithMCPDebugIf(cond bool, opts ...MCPDebugOption) DebugOption
```

Conditionally enables the debug MCP server. When `cond` is false, the option is a no-op.

```go
app.WithDebugEndpoints(
    app.WithMCPDebugIf(os.Getenv("MCP_DEBUG") == "true",
        app.WithMCPDebugRuntime(),
    ),
)
```

### WithMCPDebugRuntime

```go
func WithMCPDebugRuntime() MCPDebugOption
```

Enables runtime introspection tools and the runtime overview resource.

### WithMCPDebugConfig

```go
func WithMCPDebugConfig() MCPDebugOption
```

Enables the application configuration resource. The configuration is sanitized — no secrets are exposed.

### WithMCPDebugBuild

```go
func WithMCPDebugBuild() MCPDebugOption
```

Enables the build information resource using `runtime/debug.ReadBuildInfo()`.

## Built-in Tools

| Tool | Enabled by | Description |
|------|-----------|-------------|
| `runtime_stats` | `WithMCPDebugRuntime()` | Goroutine count, memory, GC, uptime, AI signals |
| `goroutine_profile` | `WithMCPDebugRuntime()` | Full goroutine stack dump with state summary |
| `gc_analysis` | `WithMCPDebugRuntime()` | Detailed GC statistics with pause time analysis |

## Built-in Resources

| Resource URI | Enabled by | Description |
|-------------|-----------|-------------|
| `rivaas://runtime/overview` | `WithMCPDebugRuntime()` | Live runtime stats snapshot |
| `rivaas://config` | `WithMCPDebugConfig()` | Sanitized app configuration |
| `rivaas://build` | `WithMCPDebugBuild()` | Go build info and dependencies |

## Endpoints Registered

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/_internal/debug/mcp` | MCP Streamable HTTP (listen for notifications) |
| `POST` | `/_internal/debug/mcp` | MCP Streamable HTTP (send requests) |
| `DELETE` | `/_internal/debug/mcp` | MCP Streamable HTTP (close session) |

The path changes when `WithDebugPrefix` is used.

## Security Warning

⚠️ **Never enable debug MCP in production without proper authentication.** These endpoints expose sensitive runtime information including goroutine stacks, memory contents, and configuration details.

## Example

```go
// Development: enable all debug features (bare WithMCPDebug enables all)
app.WithDebugEndpoints(
    app.WithPprof(),
    app.WithMCPDebug(),
)

// Production: enable only runtime, behind authentication
app.WithDebugEndpoints(
    app.WithMCPDebugIf(cfg.EnableDebugMCP,
        app.WithMCPDebugRuntime(),
    ),
)
```
