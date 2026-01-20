---
title: "Response Rendering"
linkTitle: "Response Rendering"
weight: 90
description: >
  Render JSON, YAML, HTML, binary responses with performance optimizations.
---

The router provides multiple response rendering methods optimized for different use cases.

## JSON Variants

### Standard JSON

HTML-escaped JSON (default):

```go
c.JSON(200, map[string]string{
    "message": "Hello, <script>alert('xss')</script>",
})
// Output: {"message":"Hello, \u003cscript\u003ealert('xss')\u003c/script\u003e"}
```

### Indented JSON

Pretty-printed for debugging:

```go
c.IndentedJSON(200, data) // Pretty-printed with indentation
```

### Pure JSON

No HTML escaping. 35% faster:

```go
c.PureJSON(200, data) // Best for HTML/markdown content
```

### Secure JSON

Anti-hijacking prefix for compliance:

```go
c.SecureJSON(200, data) // Adds ")]}',\n" prefix
```

### ASCII JSON

Pure ASCII with Unicode escaping:

```go
c.AsciiJSON(200, data) // All Unicode as \uXXXX
```

### JSONP

JSONP with callback:

```go
c.JSONP(200, data, "callback") // callback({...})
```

## Alternative Formats

### YAML

```go
c.YAML(200, config) // YAML rendering for config/DevOps APIs
```

### Plain Text

```go
c.String(200, "Hello, World!")
c.Stringf(200, "Hello, %s!", name)
```

### HTML

```go
c.HTML(200, "<h1>Welcome</h1>")
```

## Binary & Streaming

### Binary Data

```go
c.Data(200, "image/png", imageBytes) // 98% faster than JSON!
```

### Zero-Copy Streaming

```go
file, _ := os.Open("video.mp4")
defer file.Close()
fileInfo, _ := file.Stat()

c.DataFromReader(200, fileInfo.Size(), "video/mp4", file, nil)
```

### File Serving

```go
c.ServeFile("/path/to/file.pdf")
c.Download("/path/to/file.pdf", "custom-name.pdf") // Force download
```

## Performance Tips

### Choose the Right Method

```go
// Use PureJSON for HTML content (35% faster than JSON)
c.PureJSON(200, dataWithHTMLStrings)

// Use Data() for binary (98% faster than JSON)
c.Data(200, "image/png", imageBytes)

// Avoid YAML in hot paths (9x slower than JSON)
// c.YAML(200, data) // Only for config/admin endpoints

// Reserve IndentedJSON for debugging
// c.IndentedJSON(200, data) // Development only
```

### Performance Benchmarks

| Method | ns/op | Overhead vs JSON | Use Case |
|--------|-------|------------------|----------|
| JSON | 4,189 | - | Production APIs |
| PureJSON | 2,725 | **-35%** ✨ | HTML/markdown content |
| SecureJSON | 4,835 | +15% | Compliance/old browsers |
| IndentedJSON | 8,111 | +94% | Debug/development |
| AsciiJSON | 1,593 | **-62%** ✨ | Legacy compatibility |
| YAML | 36,700 | +776% | Config/admin APIs |
| Data | 90 | **-98%** ✨ | Binary/custom formats |

## Complete Example

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

func main() {
    r := router.MustNew()
    
    // Standard JSON
    r.GET("/json", func(c *router.Context) {
        c.JSON(200, map[string]string{"message": "Hello"})
    })
    
    // Pure JSON (faster for HTML content)
    r.GET("/pure-json", func(c *router.Context) {
        c.PureJSON(200, map[string]string{
            "content": "<h1>Title</h1><p>Paragraph</p>",
        })
    })
    
    // YAML
    r.GET("/yaml", func(c *router.Context) {
        c.YAML(200, map[string]interface{}{
            "server": map[string]interface{}{
                "port": 8080,
                "host": "localhost",
            },
        })
    })
    
    // Binary data
    r.GET("/image", func(c *router.Context) {
        imageData := loadImage()
        c.Data(200, "image/png", imageData)
    })
    
    // File download
    r.GET("/download", func(c *router.Context) {
        c.Download("/path/to/report.pdf", "report-2024.pdf")
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Next Steps

- **Content Negotiation**: Learn about [content negotiation](../content-negotiation/)
- **Context API**: See [complete Context API](/reference/packages/router/context-api/)
