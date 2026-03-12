---
title: "Content Negotiation"
linkTitle: "Content Negotiation"
weight: 100
keywords:
  - content negotiation
  - accept header
  - media types
  - charset
  - encoding
description: >
  RFC 7231 compliant content negotiation for media types, charsets, encodings, and languages.
---

The router provides RFC 7231 compliant content negotiation through `Accepts*` methods.

## Media Type Negotiation

```go
r.GET("/data", func(c *router.Context) {
    if c.AcceptsJSON() {
        c.JSON(200, data)
    } else if c.Accepts("xml") != "" {
        c.XML(200, data)
    } else if c.AcceptsHTML() {
        c.HTML(200, htmlTemplate)
    } else {
        c.String(200, fmt.Sprintf("%v", data))
    }
})
```

### Quality Values

```go
// Request: Accept: application/json;q=0.8, text/html;q=1.0
r.GET("/content", func(c *router.Context) {
    accepted := c.Accepts("application/json", "text/html")
    // Returns "text/html" (higher quality value)
})
```

### Wildcard Support

```go
// Request: Accept: */*
c.Accepts("application/json") // true

// Request: Accept: text/*
c.Accepts("text/html", "text/plain") // Returns "text/html"
```

## Character Set Negotiation

```go
r.GET("/data", func(c *router.Context) {
    charset := c.AcceptsCharsets("utf-8", "iso-8859-1")
    // Set response charset based on preference
    c.Header("Content-Type", "text/html; charset="+charset)
})
```

## Encoding Negotiation

```go
r.GET("/data", func(c *router.Context) {
    encoding := c.AcceptsEncodings("gzip", "br", "deflate")
    if encoding == "gzip" {
        // Compress response with gzip
    } else if encoding == "br" {
        // Compress response with brotli
    }
})
```

## Language Negotiation

```go
r.GET("/content", func(c *router.Context) {
    lang := c.AcceptsLanguages("en-US", "en", "es", "fr")
    // Serve content in preferred language
    content := getContentInLanguage(lang)
    c.String(200, content)
})
```

## Complete Example

```go
package main

import (
    "net/http"
    "rivaas.dev/router"
)

type User struct {
    ID    string `json:"id" xml:"id"`
    Name  string `json:"name" xml:"name"`
    Email string `json:"email" xml:"email"`
}

func main() {
    r := router.MustNew()
    
    r.GET("/user/:id", func(c *router.Context) {
        user := User{
            ID:    c.Param("id"),
            Name:  "John Doe",
            Email: "john@example.com",
        }
        
        // Content negotiation
        if c.AcceptsJSON() {
            c.JSON(200, user)
        } else if c.Accepts("xml") != "" {
            c.XML(200, user)
        } else if c.AcceptsHTML() {
            html := fmt.Sprintf(`
                <div>
                    <h1>%s</h1>
                    <p>Email: %s</p>
                </div>
            `, user.Name, user.Email)
            c.HTML(200, html)
        } else {
            c.String(200, fmt.Sprintf("User: %s (%s)", user.Name, user.Email))
        }
    })
    
    http.ListenAndServe(":8080", r)
}
```

## Next Steps

- **API Versioning**: Learn about [API versioning](../api-versioning/)
- **Response Rendering**: See [response rendering options](../response-rendering/)
