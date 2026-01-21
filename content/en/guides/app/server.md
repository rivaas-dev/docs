---
title: "Server"
linkTitle: "Server"
weight: 11
keywords:
  - app server
  - http server
  - tls
  - https
  - mtls
  - graceful shutdown
description: >
  Start HTTP, HTTPS, and mTLS servers with graceful shutdown.
---

## HTTP Server

### Basic HTTP Server

Start an HTTP server:

```go
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()

if err := a.Start(ctx, ":8080"); err != nil {
    log.Fatal(err)
}
```

### Custom Address

Bind to specific interface:

```go
a.Start(ctx, "127.0.0.1:8080")  // Localhost only
a.Start(ctx, "0.0.0.0:8080")    // All interfaces
```

## HTTPS Server

### Start HTTPS Server

Start with TLS certificates:

```go
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()

if err := a.StartTLS(ctx, ":8443", "server.crt", "server.key"); err != nil {
    log.Fatal(err)
}
```

### Generate Self-Signed Certificate

For development:

```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

## mTLS Server

### Start mTLS Server

Mutual TLS with client certificate verification:

```go
// Load server certificate
serverCert, err := tls.LoadX509KeyPair("server.crt", "server.key")
if err != nil {
    log.Fatal(err)
}

// Load CA certificate for client validation
caCert, err := os.ReadFile("ca.crt")
if err != nil {
    log.Fatal(err)
}
caCertPool := x509.NewCertPool()
caCertPool.AppendCertsFromPEM(caCert)

// Start mTLS server
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()

err = a.StartMTLS(ctx, ":8443", serverCert,
    app.WithClientCAs(caCertPool),
    app.WithMinVersion(tls.VersionTLS13),
)
```

### Client Authorization

Authorize clients based on certificate:

```go
err = a.StartMTLS(ctx, ":8443", serverCert,
    app.WithClientCAs(caCertPool),
    app.WithAuthorize(func(cert *x509.Certificate) (string, bool) {
        // Extract principal from certificate
        principal := cert.Subject.CommonName
        
        // Check if authorized
        if principal == "" {
            return "", false
        }
        
        return principal, true
    }),
)
```

## Graceful Shutdown

### Signal-Based Shutdown

Use `signal.NotifyContext` for graceful shutdown:

```go
ctx, cancel := signal.NotifyContext(
    context.Background(),
    os.Interrupt,
    syscall.SIGTERM,
)
defer cancel()

if err := a.Start(ctx, ":8080"); err != nil {
    log.Fatal(err)
}
```

### Shutdown Process

When context is canceled:

1. Server stops accepting new connections
2. OnShutdown hooks execute (LIFO order)
3. Server waits for in-flight requests (up to shutdown timeout)
4. Observability components shut down (metrics, tracing)
5. OnStop hooks execute (best-effort)
6. Process exits

### Shutdown Timeout

Configure shutdown timeout:

```go
a, err := app.New(
    app.WithServer(
        app.WithShutdownTimeout(30 * time.Second),
    ),
)
```

Default: 30 seconds

## Complete Examples

### HTTP with Graceful Shutdown

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
)

func main() {
    a := app.MustNew(
        app.WithServiceName("api"),
    )
    
    a.GET("/", homeHandler)
    
    ctx, cancel := signal.NotifyContext(
        context.Background(),
        os.Interrupt,
        syscall.SIGTERM,
    )
    defer cancel()
    
    log.Println("Server starting on :8080")
    if err := a.Start(ctx, ":8080"); err != nil {
        log.Fatal(err)
    }
}
```

### HTTPS with mTLS

```go
package main

import (
    "context"
    "crypto/tls"
    "crypto/x509"
    "log"
    "os"
    "os/signal"
    "syscall"
    
    "rivaas.dev/app"
)

func main() {
    a := app.MustNew(app.WithServiceName("secure-api"))
    
    // Load certificates
    serverCert, err := tls.LoadX509KeyPair("server.crt", "server.key")
    if err != nil {
        log.Fatal(err)
    }
    
    caCert, err := os.ReadFile("ca.crt")
    if err != nil {
        log.Fatal(err)
    }
    
    caCertPool := x509.NewCertPool()
    caCertPool.AppendCertsFromPEM(caCert)
    
    // Register routes
    a.GET("/", homeHandler)
    
    // Start mTLS server
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()
    
    log.Println("mTLS server starting on :8443")
    err = a.StartMTLS(ctx, ":8443", serverCert,
        app.WithClientCAs(caCertPool),
        app.WithMinVersion(tls.VersionTLS13),
    )
    if err != nil {
        log.Fatal(err)
    }
}
```

## Next Steps

- [Lifecycle](../lifecycle/) - Use lifecycle hooks for initialization and cleanup
- [Health Endpoints](../health-endpoints/) - Configure health checks
- [Configuration](../configuration/) - Configure server timeouts and limits
