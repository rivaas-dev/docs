---
title: "Static Files"
linkTitle: "Static Files"
weight: 130
keywords:
  - static files
  - file server
  - assets
  - serve files
description: >
  Serve static files and directories efficiently.
---

The router provides methods for serving static files and directories.

## Directory Serving

Serve an entire directory.

```go
r := router.MustNew()

// Serve ./public/* at /assets/*
r.Static("/assets", "./public")

// Serve /var/uploads/* at /uploads/*
r.Static("/uploads", "/var/uploads")
```

**Example:**

```
./public/
├── css/
│   └── style.css
├── js/
│   └── app.js
└── images/
    └── logo.png
```

**Access:**

- `http://localhost:8080/assets/css/style.css`
- `http://localhost:8080/assets/js/app.js`
- `http://localhost:8080/assets/images/logo.png`

## Single File Serving

Serve specific files:

```go
r.StaticFile("/favicon.ico", "./static/favicon.ico")
r.StaticFile("/robots.txt", "./static/robots.txt")
```

## Custom File System

Use a custom filesystem.

```go
import "net/http"

r.StaticFS("/files", http.Dir("./files"))
```

## File Serving in Handlers

### Serve File

```go
r.GET("/download/:filename", func(c *router.Context) {
    filename := c.Param("filename")
    filepath := "./uploads/" + filename
    c.ServeFile(filepath)
})
```

### Force Download

```go
r.GET("/download/:filename", func(c *router.Context) {
    filename := c.Param("filename")
    filepath := "./reports/" + filename
    c.Download(filepath, "report-2024.pdf")
})
```

## Wildcard Routes for File Serving

```go
r.GET("/files/*filepath", func(c *router.Context) {
    filepath := c.Param("filepath")
    fullPath := "./public/" + filepath
    c.ServeFile(fullPath)
})
```

## Complete Example

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    
    // Serve static directory
    r.Static("/assets", "./public")
    
    // Serve specific files
    r.StaticFile("/favicon.ico", "./static/favicon.ico")
    r.StaticFile("/robots.txt", "./static/robots.txt")
    
    // Custom file serving
    r.GET("/downloads/:filename", func(c *router.Context) {
        filename := c.Param("filename")
        c.Download("./files/"+filename, filename)
    })
    
    // API routes
    r.GET("/api/status", func(c *router.Context) {
        c.JSON(200, map[string]string{"status": "OK"})
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Security Considerations

### Path Traversal Prevention

```go
// ❌ BAD: Vulnerable to path traversal
r.GET("/files/*filepath", func(c *router.Context) {
    filepath := c.Param("filepath")
    c.ServeFile(filepath) // Can access ../../../etc/passwd
})

// ✅ GOOD: Validate and sanitize paths
r.GET("/files/*filepath", func(c *router.Context) {
    filepath := c.Param("filepath")
    
    // Validate path
    if strings.Contains(filepath, "..") {
        c.Status(400)
        return
    }
    
    // Serve from safe directory
    c.ServeFile("./public/" + filepath)
})
```

## Best Practices

1. **Use absolute paths** for static directories
2. **Validate file paths** to prevent traversal attacks
3. **Set appropriate cache headers** for static assets
4. **Use CDN** for production static assets
5. **Serve from dedicated file server** for large files

## Next Steps

- **Testing**: Learn about [testing patterns](../testing/)
- **Examples**: See [complete examples](../examples/)
