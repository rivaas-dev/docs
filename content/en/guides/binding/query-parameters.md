---
title: "Query Parameters"
description: "Master URL query string binding with slices, defaults, and type conversion"
weight: 4
keywords:
  - query parameters
  - url parameters
  - query string
  - parameter binding
---

Learn how to bind URL query parameters to Go structs with automatic type conversion, default values, and slice handling.

## Basic Query Binding

Query parameters are parsed from the URL query string:

```go
// URL: /users?page=2&limit=50&search=john
type ListParams struct {
    Page   int    `query:"page"`
    Limit  int    `query:"limit"`
    Search string `query:"search"`
}

params, err := binding.Query[ListParams](r.URL.Query())
// Result: {Page: 2, Limit: 50, Search: "john"}
```

## Default Values

Use the `default` tag to provide fallback values:

```go
type PaginationParams struct {
    Page  int `query:"page" default:"1"`
    Limit int `query:"limit" default:"20"`
}

// URL: /items (no query params)
params, err := binding.Query[PaginationParams](r.URL.Query())
// Result: {Page: 1, Limit: 20}

// URL: /items?page=3
params, err := binding.Query[PaginationParams](r.URL.Query())
// Result: {Page: 3, Limit: 20}
```

## Slice Handling

The binding package supports two modes for parsing slices:

### Repeated Parameters (Default)

```go
type FilterParams struct {
    Tags []string `query:"tags"`
}

// URL: /items?tags=go&tags=rust&tags=python
params, err := binding.Query[FilterParams](r.URL.Query())
// Result: {Tags: ["go", "rust", "python"]}
```

### CSV Mode

Use `WithSliceMode` for comma-separated values:

```go
// URL: /items?tags=go,rust,python
params, err := binding.Query[FilterParams](
    r.URL.Query(),
    binding.WithSliceMode(binding.SliceCSV),
)
// Result: {Tags: ["go", "rust", "python"]}
```

## Type Conversion

Query parameters are automatically converted to appropriate types:

```go
type QueryParams struct {
    // String to integer
    Age int `query:"age"`                    // "30" -> 30
    
    // String to boolean
    Active bool `query:"active"`             // "true" -> true
    
    // String to float
    Price float64 `query:"price"`            // "19.99" -> 19.99
    
    // String to time.Duration
    Timeout time.Duration `query:"timeout"`  // "30s" -> 30 * time.Second
    
    // String to time.Time
    Since time.Time `query:"since"`          // "2025-01-01" -> time.Time
    
    // String slice
    IDs []int `query:"ids"`                  // "1&2&3" -> [1, 2, 3]
}
```

## Nested Structures

Use dot notation for nested structs:

```go
type SearchParams struct {
    Query string `query:"q"`
    Filter struct {
        Category string `query:"category"`
        MinPrice int    `query:"min_price"`
        MaxPrice int    `query:"max_price"`
    } `query:"filter"`  // Prefix tag on parent struct
}

// URL: /search?q=laptop&filter.category=electronics&filter.min_price=500
params, err := binding.Query[SearchParams](r.URL.Query())
```

## Tag Aliases

Support multiple parameter names for the same field:

```go
type UserParams struct {
    UserID int `query:"user_id,id,uid"`  // Accepts any of these names
}

// All of these work:
// /users?user_id=123
// /users?id=123
// /users?uid=123
```

## Optional Fields with Pointers

Use pointers to distinguish between "not provided" and "zero value":

```go
type OptionalParams struct {
    Limit  *int    `query:"limit"`   // nil if not provided
    Offset *int    `query:"offset"`  // nil if not provided
    Filter *string `query:"filter"`  // nil if not provided
}

// URL: /items?limit=10
params, err := binding.Query[OptionalParams](r.URL.Query())
// Result: {Limit: &10, Offset: nil, Filter: nil}

if params.Limit != nil {
    // Use *params.Limit
}
```

## Complex Example

```go
type ComplexSearchParams struct {
    // Basic fields
    Query string `query:"q"`
    Page  int    `query:"page" default:"1"`
    Limit int    `query:"limit" default:"20"`
    
    // Sorting
    SortBy    string `query:"sort_by" default:"created_at"`
    SortOrder string `query:"sort_order" default:"desc"`
    
    // Filters
    Tags       []string  `query:"tags"`
    Categories []string  `query:"categories"`
    MinPrice   *float64  `query:"min_price"`
    MaxPrice   *float64  `query:"max_price"`
    
    // Date range
    Since *time.Time `query:"since"`
    Until *time.Time `query:"until"`
    
    // Flags
    IncludeArchived bool `query:"include_archived"`
    IncludeDrafts   bool `query:"include_drafts"`
}

// URL: /search?q=laptop&tags=electronics&tags=sale&min_price=500&page=2
params, err := binding.Query[ComplexSearchParams](r.URL.Query())
```

## Boolean Parsing

Boolean values accept multiple formats:

```go
type Flags struct {
    Debug bool `query:"debug"`
}

// All of these parse to true:
// ?debug=true
// ?debug=1
// ?debug=yes
// ?debug=on

// All of these parse to false:
// ?debug=false
// ?debug=0
// ?debug=no
// ?debug=off
// (parameter not present)
```

## Common Patterns

### Pagination

```go
type PaginationParams struct {
    Page     int `query:"page" default:"1"`
    PageSize int `query:"page_size" default:"20"`
}

func ListHandler(w http.ResponseWriter, r *http.Request) {
    params, err := binding.Query[PaginationParams](r.URL.Query())
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    offset := (params.Page - 1) * params.PageSize
    items := getItems(offset, params.PageSize)
    
    json.NewEncoder(w).Encode(items)
}
```

### Search and Filter

```go
type SearchParams struct {
    Q          string   `query:"q"`
    Categories []string `query:"category"`
    Tags       []string `query:"tag"`
    Sort       string   `query:"sort" default:"relevance"`
}

func SearchHandler(w http.ResponseWriter, r *http.Request) {
    params, err := binding.Query[SearchParams](r.URL.Query())
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    results := search(params.Q, params.Categories, params.Tags, params.Sort)
    json.NewEncoder(w).Encode(results)
}
```

### Date Range Filtering

```go
type DateRangeParams struct {
    StartDate time.Time `query:"start_date"`
    EndDate   time.Time `query:"end_date"`
}

// URL: /reports?start_date=2025-01-01&end_date=2025-12-31
params, err := binding.Query[DateRangeParams](r.URL.Query())
```

## Error Handling

```go
params, err := binding.Query[SearchParams](r.URL.Query())
if err != nil {
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        // Field-specific error
        log.Printf("Invalid query param %s: %v", bindErr.Field, bindErr.Err)
    }
    
    http.Error(w, "Invalid query parameters", http.StatusBadRequest)
    return
}
```

## Validation

{{< alert color="info" >}}
The binding package focuses on type conversion. For validation (required fields, value ranges, etc.), use `rivaas.dev/validation` after binding.
{{< /alert >}}

```go
params, err := binding.Query[SearchParams](r.URL.Query())
if err != nil {
    return err
}

// Validate after binding
if err := validation.Validate(params); err != nil {
    return err
}
```

## Performance Tips

1. **Use defaults**: Avoids checking for zero values
2. **Avoid reflection**: Struct info is cached automatically
3. **Reuse structs**: Define parameter structs once
4. **Primitive types**: Zero allocation for basic types

## Troubleshooting

### Query Parameter Not Binding

Check that:
- Tag name matches query parameter name
- Field is exported (starts with uppercase)
- Type conversion is supported

```go
// Wrong - unexported field
type Params struct {
    page int `query:"page"`  // Won't bind
}

// Correct
type Params struct {
    Page int `query:"page"`
}
```

### Slice Not Parsing

Ensure you're using the correct slice mode:

```go
// For repeated params: ?tags=go&tags=rust
params, err := binding.Query[Params](values)  // Default mode

// For CSV: ?tags=go,rust,python
params, err := binding.Query[Params](
    values,
    binding.WithSliceMode(binding.SliceCSV),
)
```

## Next Steps

- Learn about [JSON Binding](../json-binding/) for request bodies
- Explore [Multi-Source](../multi-source/) to combine query with other sources
- Master [Struct Tags](../struct-tags/) syntax and options
- See [Type Support](../type-support/) for all supported types

For complete API details, see [API Reference](/reference/packages/binding/api-reference/).
