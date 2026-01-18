---
title: "Swagger UI Options"
description: "Complete reference for Swagger UI configuration options"
weight: 4
---

Complete reference for all Swagger UI configuration options (functions passed to `WithSwaggerUI()`).

## Display Options

### WithUIExpansion

```go
func WithUIExpansion(expansion DocExpansion) UIOption
```

Controls initial document expansion.

**Parameters:**
- `expansion` - `DocExpansionList`, `DocExpansionFull`, or `DocExpansionNone`

**Values:**
- `DocExpansionList` - Show endpoints, hide details (default)
- `DocExpansionFull` - Show endpoints and details
- `DocExpansionNone` - Hide everything

**Example:**

```go
openapi.WithUIExpansion(openapi.DocExpansionFull)
```

### WithUIDefaultModelRendering

```go
func WithUIDefaultModelRendering(rendering ModelRendering) UIOption
```

Controls how models/schemas are rendered.

**Parameters:**
- `rendering` - `ModelRenderingExample` or `ModelRenderingModel`

**Example:**

```go
openapi.WithUIDefaultModelRendering(openapi.ModelRenderingExample)
```

### WithUIModelExpandDepth

```go
func WithUIModelExpandDepth(depth int) UIOption
```

Controls how deeply a single model is expanded.

**Parameters:**
- `depth` - Expansion depth (-1 to disable, 1 for shallow, higher for deeper)

**Example:**

```go
openapi.WithUIModelExpandDepth(2)
```

### WithUIModelsExpandDepth

```go
func WithUIModelsExpandDepth(depth int) UIOption
```

Controls how deeply the models section is expanded.

**Example:**

```go
openapi.WithUIModelsExpandDepth(1)
```

### WithUIDisplayOperationID

```go
func WithUIDisplayOperationID(display bool) UIOption
```

Shows operation IDs alongside summaries.

**Example:**

```go
openapi.WithUIDisplayOperationID(true)
```

## Try It Out Options

### WithUITryItOut

```go
func WithUITryItOut(enabled bool) UIOption
```

Enables "Try it out" functionality.

**Example:**

```go
openapi.WithUITryItOut(true)
```

### WithUIRequestSnippets

```go
func WithUIRequestSnippets(enabled bool, languages ...RequestSnippetLanguage) UIOption
```

Shows code snippets for making requests.

**Parameters:**
- `enabled` - Whether to show snippets
- `languages` - Snippet languages to show

**Languages:**
- `SnippetCurlBash` - curl for bash/sh shells
- `SnippetCurlPowerShell` - curl for PowerShell
- `SnippetCurlCmd` - curl for Windows CMD

**Example:**

```go
openapi.WithUIRequestSnippets(true,
    openapi.SnippetCurlBash,
    openapi.SnippetCurlPowerShell,
    openapi.SnippetCurlCmd,
)
```

### WithUIRequestSnippetsExpanded

```go
func WithUIRequestSnippetsExpanded(expanded bool) UIOption
```

Expands request snippets by default.

**Example:**

```go
openapi.WithUIRequestSnippetsExpanded(true)
```

### WithUIDisplayRequestDuration

```go
func WithUIDisplayRequestDuration(display bool) UIOption
```

Shows how long requests take.

**Example:**

```go
openapi.WithUIDisplayRequestDuration(true)
```

## Filtering and Sorting Options

### WithUIFilter

```go
func WithUIFilter(enabled bool) UIOption
```

Enables filter/search box.

**Example:**

```go
openapi.WithUIFilter(true)
```

### WithUIMaxDisplayedTags

```go
func WithUIMaxDisplayedTags(max int) UIOption
```

Limits the number of tags displayed.

**Example:**

```go
openapi.WithUIMaxDisplayedTags(10)
```

### WithUIOperationsSorter

```go
func WithUIOperationsSorter(sorter OperationsSorter) UIOption
```

Sets operation sorting method.

**Parameters:**
- `sorter` - `OperationsSorterAlpha` or `OperationsSorterMethod`

**Example:**

```go
openapi.WithUIOperationsSorter(openapi.OperationsSorterAlpha)
```

### WithUITagsSorter

```go
func WithUITagsSorter(sorter TagsSorter) UIOption
```

Sets tag sorting method.

**Parameters:**
- `sorter` - `TagsSorterAlpha`

**Example:**

```go
openapi.WithUITagsSorter(openapi.TagsSorterAlpha)
```

## Syntax Highlighting Options

### WithUISyntaxHighlight

```go
func WithUISyntaxHighlight(enabled bool) UIOption
```

Enables syntax highlighting.

**Example:**

```go
openapi.WithUISyntaxHighlight(true)
```

### WithUISyntaxTheme

```go
func WithUISyntaxTheme(theme SyntaxTheme) UIOption
```

Sets syntax highlighting theme.

**Available Themes:**
- `SyntaxThemeAgate` - Dark theme with blue accents
- `SyntaxThemeArta` - Dark theme with orange accents
- `SyntaxThemeMonokai` - Dark theme with vibrant colors
- `SyntaxThemeNord` - Dark theme with cool blue tones
- `SyntaxThemeObsidian` - Dark theme with green accents
- `SyntaxThemeTomorrowNight` - Dark theme with muted colors
- `SyntaxThemeIdea` - Light theme similar to IntelliJ IDEA

**Example:**

```go
openapi.WithUISyntaxTheme(openapi.SyntaxThemeMonokai)
```

## Authentication Options

### WithUIPersistAuth

```go
func WithUIPersistAuth(persist bool) UIOption
```

Persists authentication across browser refreshes.

**Example:**

```go
openapi.WithUIPersistAuth(true)
```

### WithUIWithCredentials

```go
func WithUIWithCredentials(withCredentials bool) UIOption
```

Includes credentials in requests.

**Example:**

```go
openapi.WithUIWithCredentials(true)
```

## Additional Options

### WithUIDeepLinking

```go
func WithUIDeepLinking(enabled bool) UIOption
```

Enables deep linking for tags and operations.

**Example:**

```go
openapi.WithUIDeepLinking(true)
```

### WithUIShowExtensions

```go
func WithUIShowExtensions(show bool) UIOption
```

Shows vendor extensions (`x-*`) in the UI.

**Example:**

```go
openapi.WithUIShowExtensions(true)
```

### WithUIShowCommonExtensions

```go
func WithUIShowCommonExtensions(show bool) UIOption
```

Shows common extensions in the UI.

**Example:**

```go
openapi.WithUIShowCommonExtensions(true)
```

### WithUISupportedMethods

```go
func WithUISupportedMethods(methods ...HTTPMethod) UIOption
```

Configures which HTTP methods are supported for "Try it out".

**Parameters:**
- `methods` - HTTP method constants (`MethodGet`, `MethodPost`, `MethodPut`, etc.)

**Example:**

```go
openapi.WithUISupportedMethods(
    openapi.MethodGet,
    openapi.MethodPost,
    openapi.MethodPut,
    openapi.MethodDelete,
)
```

## Validation Options

### WithUIValidator

```go
func WithUIValidator(url string) UIOption
```

Sets specification validator.

**Parameters:**
- `url` - `ValidatorLocal`, `ValidatorNone`, or custom validator URL

**Example:**

```go
openapi.WithUIValidator(openapi.ValidatorLocal)
openapi.WithUIValidator("https://validator.swagger.io/validator")
openapi.WithUIValidator(openapi.ValidatorNone)
```

## Complete Example

```go
openapi.WithSwaggerUI("/docs",
    // Display
    openapi.WithUIExpansion(openapi.DocExpansionList),
    openapi.WithUIModelExpandDepth(1),
    openapi.WithUIDisplayOperationID(true),
    
    // Try it out
    openapi.WithUITryItOut(true),
    openapi.WithUIRequestSnippets(true,
        openapi.SnippetCurlBash,
        openapi.SnippetCurlPowerShell,
        openapi.SnippetCurlCmd,
    ),
    openapi.WithUIDisplayRequestDuration(true),
    
    // Filtering/Sorting
    openapi.WithUIFilter(true),
    openapi.WithUIOperationsSorter(openapi.OperationsSorterAlpha),
    
    // Syntax
    openapi.WithUISyntaxHighlight(true),
    openapi.WithUISyntaxTheme(openapi.SyntaxThemeMonokai),
    
    // Auth
    openapi.WithUIPersistAuth(true),
    
    // Validation
    openapi.WithUIValidator(openapi.ValidatorLocal),
)
```

## Next Steps

- See [Options](options/) for API-level configuration
- Check [Swagger UI Guide](/guides/openapi/swagger-ui/) for detailed usage
- Review [Examples](/guides/openapi/examples/) for complete patterns
