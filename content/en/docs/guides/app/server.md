---
title: "Server"
linkTitle: "Server"
weight: 12
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
if err := a.Start(context.Background()); err != nil {
    log.Fatal(err)
}
```

`Start` handles SIGINT (Ctrl+C) and SIGTERM internally. No signal setup is needed. Press Ctrl+C twice to force-terminate if graceful shutdown is taking too long.

### Custom Address

Configure the listen address via options when creating the app. Default is `:8080` for HTTP and `:8443` for TLS/mTLS:

```go
// Localhost only
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithHost("127.0.0.1"),
    app.WithPort(8080),
)
// ...
a.Start(context.Background())

// All interfaces (default)
a, err := app.New(
    app.WithServiceName("my-api"),
    app.WithPort(8080),
)
// ...
a.Start(context.Background())
```

## HTTPS Server

### Start HTTPS Server

Configure TLS at construction with [WithTLS](/docs/reference/packages/app/options/#withtls), then start the server (default port 8443; use `WithPort(443)` to override):

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithTLS("server.crt", "server.key"),
)
// ... register routes ...

if err := a.Start(context.Background()); err != nil {
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

Configure mTLS at construction with [WithMTLS](/docs/reference/packages/app/options/#withmtls), then start the server:

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

a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithMTLS(serverCert,
        app.WithClientCAs(caCertPool),
        app.WithMinVersion(tls.VersionTLS13),
    ), // default port 8443; use WithPort(443) to override
)
// ... register routes ...

if err := a.Start(context.Background()); err != nil {
    log.Fatal(err)
}
```

### Client Authorization

Authorize clients based on certificate by adding [WithAuthorize](/docs/reference/packages/app/options/#withmtls) to `WithMTLS`:

```go
a := app.MustNew(
    app.WithServiceName("my-api"),
    app.WithPort(8443),
    app.WithMTLS(serverCert,
        app.WithClientCAs(caCertPool),
        app.WithAuthorize(func(cert *x509.Certificate) (string, bool) {
            principal := cert.Subject.CommonName
            if principal == "" {
                return "", false
            }
            return principal, true
        }),
    ),
)
// ...
if err := a.Start(context.Background()); err != nil { ... }
```

## Graceful Shutdown

### Automatic Signal Handling

`Start` handles SIGINT (Ctrl+C) and SIGTERM automatically. No `signal.NotifyContext` boilerplate is needed:

```go
if err := a.Start(context.Background()); err != nil {
    log.Fatal(err)
}
```

The context parameter is still useful for programmatic shutdown — for example in tests or admin endpoints — by canceling the context directly.

### Force Shutdown

If the server is taking too long to shut down, press Ctrl+C a second time. The process will terminate immediately with exit code 1.

Terminal output during a normal graceful shutdown:

```
^C
INFO  shutdown signal received              signal=interrupt
INFO  shutting down gracefully, press Ctrl+C again to force
INFO  server exited                         protocol=HTTP
```

### Shutdown Process

When a shutdown signal or context cancellation is received:

1. Server stops accepting new connections
2. OnShutdown hooks execute (LIFO order, within shutdown timeout)
3. Server waits for in-flight requests to drain
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
    
    "rivaas.dev/app"
)

func main() {
    a := app.MustNew(
        app.WithServiceName("api"),
    )
    
    a.GET("/", homeHandler)
    
    log.Println("Server starting on :8080")
    if err := a.Start(context.Background()); err != nil {
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
    
    "rivaas.dev/app"
)

func main() {
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
    
    a := app.MustNew(
        app.WithServiceName("secure-api"),
        app.WithMTLS(serverCert,
            app.WithClientCAs(caCertPool),
            app.WithMinVersion(tls.VersionTLS13),
        ), // default port 8443
    )
    a.GET("/", homeHandler)

    if err := a.Start(context.Background()); err != nil {
        log.Fatal(err)
    }
}
```

## Next Steps

- [Lifecycle](../lifecycle/) - Use lifecycle hooks for initialization and cleanup
- [Health Endpoints](../health-endpoints/) - Configure health checks
- [Configuration](../configuration/) - Configure server timeouts and limits
