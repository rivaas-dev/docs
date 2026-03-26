---
title: "MCP Debug Endpoints"
linkTitle: "MCP Debug"
weight: 12
keywords:
  - mcp
  - debug
  - runtime
  - ai
  - llm
  - model context protocol
  - goroutines
  - memory
  - profiling
description: >
  Expose Go runtime internals to AI tools via the Model Context Protocol (MCP).
---

## Overview

The app package provides an optional MCP debug server that exposes Go runtime information to AI tools. It uses the [Model Context Protocol](https://modelcontextprotocol.io) to let LLM-based tools inspect goroutine counts, heap usage, GC statistics, build info, and application configuration.

**Security Warning:** Debug MCP endpoints expose sensitive runtime information. NEVER enable them in production without proper security measures.

## Basic Configuration

### Enable Runtime Tools

Enable the debug MCP server with runtime introspection:

```go
a, err := app.New(
    app.WithDebugEndpoints(
        app.WithMCPDebug(
            app.WithMCPDebugRuntime(),
        ),
    ),
)
```

### Enable All Features

When called without sub-options, `WithMCPDebug()` enables all features (runtime, config, build):

```go
a, err := app.New(
    app.WithDebugEndpoints(
        app.WithMCPDebug(),
    ),
)
```

This is equivalent to:

```go
app.WithMCPDebug(
    app.WithMCPDebugRuntime(),
    app.WithMCPDebugConfig(),
    app.WithMCPDebugBuild(),
)
```

## Built-in Tools and Resources

When enabled, the debug MCP server registers these tools and resources:

### Tools

| Tool | Enabled by | Description |
|------|-----------|-------------|
| `runtime_stats` | `WithMCPDebugRuntime()` | Goroutine count, memory usage, GC stats, uptime. Includes AI-useful anomaly signals. |
| `goroutine_profile` | `WithMCPDebugRuntime()` | Full goroutine stack dump with state summary. Useful for leak detection. |
| `gc_analysis` | `WithMCPDebugRuntime()` | Detailed GC statistics including pause times and CPU fraction. |

### Resources

| Resource URI | Enabled by | Description |
|-------------|-----------|-------------|
| `rivaas://runtime/overview` | `WithMCPDebugRuntime()` | Live snapshot of runtime statistics |
| `rivaas://config` | `WithMCPDebugConfig()` | Sanitized application configuration (no secrets) |
| `rivaas://build` | `WithMCPDebugBuild()` | Go build info: module path, Go version, dependencies |

## AI-Friendly Signals

Each tool and resource includes a `signals` field with human-readable observations. These help AI tools understand the current state without needing to interpret raw numbers:

- `"goroutine count (4200) exceeds typical threshold — investigate if expected"`
- `"heap usage (1.2 GB) is very high — check for memory leaks"`
- `"last GC pause (15.3 ms) is high — may cause latency spikes"`

## Connecting an AI Client

Point your AI tool at the MCP debug endpoint:

```
http://localhost:8080/_internal/debug/mcp
```

For Cursor, add to your MCP configuration:

```json
{
  "mcpServers": {
    "rivaas-debug": {
      "url": "http://localhost:8080/_internal/debug/mcp"
    }
  }
}
```

The debug MCP server uses Streamable HTTP transport. It accepts `GET`, `POST`, and `DELETE` requests on a single endpoint.

## Security Considerations

### Development

Safe to enable all features unconditionally. Bare `WithMCPDebug()` enables everything:

```go
a, err := app.New(
    app.WithEnvironment("development"),
    app.WithDebugEndpoints(
        app.WithPprof(),
        app.WithMCPDebug(),
    ),
)
```

### Staging

Enable behind VPN or IP allowlist. Use `WithMCPDebugIf` for conditional enablement:

```go
a, err := app.New(
    app.WithDebugEndpoints(
        app.WithMCPDebugIf(os.Getenv("MCP_DEBUG") == "true",
            app.WithMCPDebugRuntime(),
        ),
    ),
)

a.Use(IPAllowlistMiddleware([]string{"10.0.0.0/8"}))
```

### Production

Enable only with proper authentication:

```go
a, err := app.New(
    app.WithDebugEndpoints(
        app.WithDebugPrefix("/_internal/debug"),
        app.WithMCPDebug(
            app.WithMCPDebugRuntime(),
        ),
    ),
)

debugAuth := a.Group("/_internal", AdminAuthMiddleware())
```

## Complete Example

```go
package main

import (
    "context"
    "log"

    "rivaas.dev/app"
)

func main() {
    a, err := app.New(
        app.WithServiceName("my-api"),
        app.WithServiceVersion("v1.0.0"),

        app.WithDebugEndpoints(
            app.WithPprof(),
            app.WithMCPDebug(),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Debug MCP: http://localhost:8080/_internal/debug/mcp
    // pprof:     http://localhost:8080/_internal/debug/pprof/

    if err = a.Start(context.Background()); err != nil {
        log.Fatal(err)
    }
}
```

## Next Steps

- [MCP (Business)](../mcp/) - Expose your own tools and resources to AI agents
- [Debug Endpoints](../debug-endpoints/) - pprof profiling
- [Observability](../observability/) - Metrics, tracing, and logging
