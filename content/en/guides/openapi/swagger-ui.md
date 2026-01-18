---
title: "Swagger UI"
description: "Customize the Swagger UI interface for API documentation"
weight: 8
---

Learn how to configure and customize the Swagger UI interface for your OpenAPI specification.

## Overview

The package includes built-in Swagger UI support with extensive customization options. Swagger UI provides an interactive interface for exploring and testing your API.

## Basic Configuration

Enable Swagger UI by specifying the path:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithSwaggerUI("/docs"),
)
```

This serves Swagger UI at `/docs` with default settings.

## Disabling Swagger UI

To disable Swagger UI completely:

```go
api := openapi.MustNew(
    openapi.WithTitle("My API", "1.0.0"),
    openapi.WithoutSwaggerUI(),
)
```

## Display Options

### Document Expansion

Control how documentation is initially displayed:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIExpansion(openapi.DocExpansionList),
)
```

Available options:
- `DocExpansionList` - Show endpoints, hide details (default)
- `DocExpansionFull` - Show endpoints and details
- `DocExpansionNone` - Hide everything

### Model Rendering

Control how models/schemas are rendered:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIDefaultModelRendering(openapi.ModelRenderingExample),
)
```

Options:
- `ModelRenderingExample` - Show example values (default)
- `ModelRenderingModel` - Show schema structure

### Model Expand Depth

Control how deeply nested models are expanded:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIModelExpandDepth(1),      // How deep to expand a single model
    openapi.WithUIModelsExpandDepth(1),     // How deep to expand models section
)
```

Set to `-1` to disable expansion, `1` for shallow, higher numbers for deeper.

### Display Operation IDs

Show operation IDs alongside summaries:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIDisplayOperationID(true),
)
```

## Try It Out Features

### Enable Try It Out

Allow users to test API endpoints directly:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUITryItOut(true),
)
```

### Request Snippets

Show code snippets for making requests:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIRequestSnippets(true,
        openapi.SnippetCurlBash,
        openapi.SnippetCurlPowerShell,
        openapi.SnippetCurlCmd,
    ),
)
```

Available snippet types:
- `SnippetCurlBash` - curl for bash/sh shells
- `SnippetCurlPowerShell` - curl for PowerShell
- `SnippetCurlCmd` - curl for Windows CMD

### Request Snippets Expanded

Expand request snippets by default:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIRequestSnippets(true, openapi.SnippetCurlBash),
    openapi.WithUIRequestSnippetsExpanded(true),
)
```

### Display Request Duration

Show how long requests take:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIDisplayRequestDuration(true),
)
```

## Filtering and Sorting

### Filter

Enable a filter/search box:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIFilter(true),
)
```

### Max Displayed Tags

Limit the number of tags displayed:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIMaxDisplayedTags(10),
)
```

### Operations Sorting

Sort operations alphabetically or by HTTP method:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIOperationsSorter(openapi.OperationsSorterAlpha),
)
```

Options:
- `OperationsSorterAlpha` - Sort alphabetically
- `OperationsSorterMethod` - Sort by HTTP method
- Leave unset for default order

### Tags Sorting

Sort tags alphabetically:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUITagsSorter(openapi.TagsSorterAlpha),
)
```

## Syntax Highlighting

### Enable/Disable Syntax Highlighting

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUISyntaxHighlight(true),
)
```

### Syntax Theme

Choose a color theme for code highlighting:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUISyntaxTheme(openapi.SyntaxThemeMonokai),
)
```

Available themes:
- `SyntaxThemeAgate` - Dark theme with blue accents
- `SyntaxThemeArta` - Dark theme with orange accents
- `SyntaxThemeMonokai` - Dark theme with vibrant colors
- `SyntaxThemeNord` - Dark theme with cool blue tones
- `SyntaxThemeObsidian` - Dark theme with green accents
- `SyntaxThemeTomorrowNight` - Dark theme with muted colors
- `SyntaxThemeIdea` - Light theme similar to IntelliJ IDEA

## Authentication

### Persist Authentication

Keep auth credentials across browser refreshes:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIPersistAuth(true),
)
```

### Send Credentials

Include credentials in requests:

```go
openapi.WithSwaggerUI("/docs",
    openapi.WithUIWithCredentials(true),
)
```

## Validation

Control OpenAPI specification validation:

```go
// Use local validation (recommended)
openapi.WithSwaggerUI("/docs",
    openapi.WithUIValidator(openapi.ValidatorLocal),
)

// Use external validator
openapi.WithSwaggerUI("/docs",
    openapi.WithUIValidator("https://validator.swagger.io/validator"),
)

// Disable validation
openapi.WithSwaggerUI("/docs",
    openapi.WithUIValidator(openapi.ValidatorNone),
)
```

## Complete Swagger UI Example

Here's a comprehensive example with all common options:

```go
package main

import (
    "rivaas.dev/openapi"
)

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("My API", "1.0.0"),
        openapi.WithSwaggerUI("/docs",
            // Document expansion
            openapi.WithUIExpansion(openapi.DocExpansionList),
            openapi.WithUIModelsExpandDepth(1),
            openapi.WithUIModelExpandDepth(1),
            
            // Display options
            openapi.WithUIDisplayOperationID(true),
            openapi.WithUIDefaultModelRendering(openapi.ModelRenderingExample),
            
            // Try it out
            openapi.WithUITryItOut(true),
            openapi.WithUIRequestSnippets(true,
                openapi.SnippetCurlBash,
                openapi.SnippetCurlPowerShell,
                openapi.SnippetCurlCmd,
            ),
            openapi.WithUIRequestSnippetsExpanded(true),
            openapi.WithUIDisplayRequestDuration(true),
            
            // Filtering and sorting
            openapi.WithUIFilter(true),
            openapi.WithUIMaxDisplayedTags(10),
            openapi.WithUIOperationsSorter(openapi.OperationsSorterAlpha),
            openapi.WithUITagsSorter(openapi.TagsSorterAlpha),
            
            // Syntax highlighting
            openapi.WithUISyntaxHighlight(true),
            openapi.WithUISyntaxTheme(openapi.SyntaxThemeMonokai),
            
            // Authentication
            openapi.WithUIPersistAuth(true),
            openapi.WithUIWithCredentials(true),
            
            // Validation
            openapi.WithUIValidator(openapi.ValidatorLocal),
        ),
    )

    // Generate specification...
}
```

## Swagger UI Path

The Swagger UI path can be any valid URL path:

```go
openapi.WithSwaggerUI("/api-docs")
openapi.WithSwaggerUI("/swagger")
openapi.WithSwaggerUI("/docs/api")
```

## Integration with Web Frameworks

The package generates the OpenAPI specification, but you need to integrate it with your web framework to serve Swagger UI. The typical pattern is:

```go
// Generate the spec
result, err := api.Generate(context.Background(), operations...)
if err != nil {
    log.Fatal(err)
}

// Serve the spec at /openapi.json
http.HandleFunc("/openapi.json", func(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Write(result.JSON)
})

// Serve Swagger UI at /docs
// (Framework-specific implementation)
```

## Next Steps

- Learn about [Validation](../validation/) to validate your specifications
- Explore [Diagnostics](../diagnostics/) for warning handling
- See [Examples](../examples/) for complete integration patterns
