---
title: "Static Files"
linkTitle: "Static Files"
weight: 130
keywords:
  - static files
  - file server
  - assets
  - serve files
  - embed
  - embed.FS
  - embedded files
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

## Embedded Files

Go 1.16 added `embed.FS` which lets you put files inside your binary. This is great for single-file deployments — no need to copy static files around.

The router has a helper method that makes this easy:

```go
import "embed"

//go:embed web/dist/*
var webAssets embed.FS

r := router.MustNew()

// Serve web/dist/* at /assets/*
r.StaticEmbed("/assets", webAssets, "web/dist")
```

The third parameter (`"web/dist"`) tells the router which folder inside the embed to use. This strips that prefix from the URLs.

**Why use embedded files?**

- **One binary** — Deploy a single file, no folders to manage
- **Fast startup** — Files are already in memory
- **Safe** — Nobody can change your static files at runtime

**Example project layout:**

```
myapp/
├── main.go
└── web/
    └── dist/
        ├── index.html
        ├── css/
        │   └── style.css
        └── js/
            └── app.js
```

**Serving a frontend app:**

```go
package main

import (
    "embed"
    "net/http"
    "rivaas.dev/router"
)

//go:embed web/dist/*
var webAssets embed.FS

func main() {
    r := router.MustNew()
    
    // Serve your frontend at the root
    r.StaticEmbed("/", webAssets, "web/dist")
    
    // API routes
    r.GET("/api/status", func(c *router.Context) {
        c.JSON(200, map[string]string{"status": "OK"})
    })
    
    http.ListenAndServe(":8080", r)
}
```

Now `http://localhost:8080/` serves `index.html`, and `http://localhost:8080/css/style.css` serves your CSS.

{{% alert title="Tip" color="info" %}}
If you don't need the convenience method, you can also use `StaticFS` with `http.FS`:

```go
subFS, _ := fs.Sub(webAssets, "web/dist")
r.StaticFS("/", http.FS(subFS))
```

`StaticEmbed` just saves you those extra lines.
{{% /alert %}}

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

Here's a full example with all the ways to serve static files:

```go
package main

import (
    "embed"
    "net/http"
    "rivaas.dev/router"
)

//go:embed static/*
var staticAssets embed.FS

func main() {
    r := router.MustNew()
    
    // Option 1: Serve from filesystem
    r.Static("/assets", "./public")
    
    // Option 2: Serve embedded files
    r.StaticEmbed("/static", staticAssets, "static")
    
    // Serve specific files
    r.StaticFile("/favicon.ico", "./static/favicon.ico")
    r.StaticFile("/robots.txt", "./static/robots.txt")
    
    // Custom file serving with download
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
6. **Use embed.FS** for single-binary deployments (great for containers and CLI tools)

## Next Steps

- **Testing**: Learn about [testing patterns](../testing/)
- **Examples**: See [complete examples](../examples/)
