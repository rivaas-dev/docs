---
title: "Structured Logging"
linkTitle: "Logging"
description: "Learn how to implement structured logging with Rivaas using Go's standard log/slog"
weight: 7
---

{{% pageinfo %}}
The Rivaas Logging package provides production-ready structured logging with minimal dependencies. Uses Go's built-in `log/slog` for high performance and native integration with the Go ecosystem.
{{% /pageinfo %}}

## Features

- **Multiple Output Formats**: JSON, text, and human-friendly console output
- **Context-Aware Logging**: Automatic trace correlation with OpenTelemetry
- **Sensitive Data Redaction**: Automatic sanitization of passwords, tokens, and secrets
- **Log Sampling**: Reduce log volume in high-traffic scenarios
- **Convenience Methods**: HTTP request logging, error logging with context, duration tracking
- **Dynamic Log Levels**: Change log levels at runtime without restart
- **Functional Options API**: Clean, composable configuration
- **Router Integration**: Seamless integration following metrics/tracing patterns
- **Zero External Dependencies**: Uses only Go standard library (except OpenTelemetry for trace correlation)

## Quick Start

{{< tabpane persist=header >}}
{{< tab header="Console" lang="go" >}}
package main

import (
    "rivaas.dev/logging"
)

func main() {
    // Create a logger with console output
    log := logging.MustNew(
        logging.WithConsoleHandler(),
        logging.WithDebugLevel(),
    )

    log.Info("service started", "port", 8080, "env", "production")
    log.Debug("debugging information", "key", "value")
    log.Error("operation failed", "error", "connection timeout")
}
{{< /tab >}}
{{< tab header="JSON" lang="go" >}}
package main

import (
    "rivaas.dev/logging"
)

func main() {
    // Create a logger with JSON output
    log := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithServiceName("my-api"),
        logging.WithServiceVersion("v1.0.0"),
        logging.WithEnvironment("production"),
    )

    log.Info("user action", "user_id", "123", "action", "login")
    // Output: {"time":"2024-01-15T10:30:45.123Z","level":"INFO","msg":"user action","service":"my-api","version":"v1.0.0","env":"production","user_id":"123","action":"login"}
}
{{< /tab >}}
{{< tab header="Text" lang="go" >}}
package main

import (
    "rivaas.dev/logging"
)

func main() {
    // Create a logger with text output
    log := logging.MustNew(
        logging.WithTextHandler(),
        logging.WithServiceName("my-api"),
    )

    log.Info("service started", "port", 8080)
    // Output: time=2024-01-15T10:30:45.123Z level=INFO msg="service started" service=my-api port=8080
}
{{< /tab >}}
{{< /tabpane >}}

### How It Works

- **Handler types** determine output format (JSON, Text, Console)
- **Structured fields** are key-value pairs, not string concatenation
- **Log levels** control verbosity (Debug, Info, Warn, Error)
- **Service metadata** automatically added to every log entry
- **Sensitive data** automatically redacted (passwords, tokens, keys)

## Learning Path

Follow these guides to master logging with Rivaas:

1. [**Installation**](installation/) - Get started with the logging package
2. [**Basic Usage**](basic-usage/) - Learn handler types and output formats
3. [**Configuration**](configuration/) - Configure loggers with all available options
4. [**Context Logging**](context-logging/) - Add trace correlation with OpenTelemetry
5. [**Convenience Methods**](convenience-methods/) - Use helper methods for common patterns
6. [**Log Sampling**](sampling/) - Reduce log volume in high-traffic scenarios
7. [**Dynamic Log Levels**](dynamic-levels/) - Change log levels at runtime
8. [**Router Integration**](router-integration/) - Integrate with Rivaas router
9. [**Testing**](testing/) - Test utilities and patterns
10. [**Best Practices**](best-practices/) - Performance tips and patterns
11. [**Migration**](migration/) - Switch from other logging libraries
12. [**Examples**](examples/) - See real-world usage patterns

## Next Steps

- Start with [Installation](installation/) to set up the logging package
- Explore the [API Reference](/reference/packages/logging/) for complete technical details
- Check out [code examples on GitHub](https://github.com/rivaas-dev/rivaas/tree/main/logging/examples/)
