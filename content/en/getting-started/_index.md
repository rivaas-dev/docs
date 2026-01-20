---
title: Getting Started
description: Start using Rivaas in minutes
weight: 1
sidebar_root_for: self
---

Learn how to install Rivaas and build your first web application. This guide shows you how to create a running API with production-ready features.

## What You'll Learn

This section shows you how to:

- ✅ Install and verify Rivaas
- ✅ Build a complete REST API with multiple routes
- ✅ Configure your application for different environments
- ✅ Add middleware for CORS, authentication, and more
- ✅ Test your application
- ✅ Deploy with confidence

## Prerequisites

Before you begin, you need:

- **Go 1.25 or higher** installed ([Download Go](https://go.dev/dl/))
- Basic Go programming knowledge
- Basic HTTP and REST API knowledge

Check your Go installation:

```bash
go version
# Should output: go version go1.25.x ...
```

## Learning Path

Follow these steps in order:

### 1. [Installation](installation/)
Install the Rivaas framework and verify your setup.

**What you'll do:**
- Install the `app` package
- Verify installation with a test program
- Troubleshoot common issues

---

### 2. [Your First Application](first-application/)
Build a complete Hello World API with multiple endpoints.

**What you'll do:**
- Create a new project
- Define routes and handlers
- Handle JSON requests and responses
- Set up graceful shutdown
- Test your API

---

### 3. [Configuration](configuration/)
Learn essential configuration options for your application.

**What you'll do:**
- Set service metadata
- Configure health endpoints
- Enable observability (logging, metrics, tracing)
- Set up environment-specific configuration
- Understand server timeouts

---

### 4. [Using Middleware](middleware/)
Add functionality that works across all routes.

**What you'll do:**
- Learn middleware concepts
- Use built-in middleware (CORS, request ID, auth)
- Create custom middleware
- Apply middleware globally or to specific routes
- Learn execution order

---

### 5. [Next Steps](next-steps/)
Continue your journey beyond the basics.

**What you'll explore:**
- Production deployment
- Advanced routing patterns
- Testing strategies
- Example applications

---

## Quick Start

Want to skip ahead? Here's the minimal setup:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"

    "rivaas.dev/app"
)

func main() {
    a, err := app.New()
    if err != nil {
        log.Fatal(err)
    }

    a.GET("/", func(c *app.Context) {
        c.JSON(http.StatusOK, map[string]string{
            "message": "Hello from Rivaas!",
        })
    })

    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}
```

This creates a basic API server. Continue through the guide to learn about configuration, middleware, and production practices.

## Need Help?

- **Guides:** Check the [Guides](/guides/) section for detailed tutorials
- **API Reference:** Browse the [Reference](/reference/packages/) documentation for all options
- **Issues:** Report problems on [GitHub Issues](https://github.com/rivaas-dev/rivaas/issues)
- **Discussions:** Ask questions on [GitHub Discussions](https://github.com/rivaas-dev/rivaas/discussions)

## Ready?

Start with [Installation →](installation/)
