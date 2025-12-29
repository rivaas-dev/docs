---
title: "Examples"
description: "Real-world examples and integration patterns for common use cases"
weight: 11
---

Complete, production-ready examples demonstrating common binding patterns and integrations.

## Basic REST API

Complete CRUD handlers with proper error handling:

```go
package main

import (
    "encoding/json"
    "net/http"
    "rivaas.dev/binding"
    "rivaas.dev/validation"
)

type CreateUserRequest struct {
    Username string `json:"username" validate:"required,alphanum,min=3,max=32"`
    Email    string `json:"email" validate:"required,email"`
    Age      int    `json:"age" validate:"required,min=18,max=120"`
}

type UpdateUserRequest struct {
    Username *string `json:"username,omitempty" validate:"omitempty,alphanum,min=3,max=32"`
    Email    *string `json:"email,omitempty" validate:"omitempty,email"`
    Age      *int    `json:"age,omitempty" validate:"omitempty,min=18,max=120"`
}

type ListUsersParams struct {
    Page     int      `query:"page" default:"1"`
    PageSize int      `query:"page_size" default:"20"`
    SortBy   string   `query:"sort_by" default:"created_at"`
    Search   string   `query:"search"`
    Tags     []string `query:"tags"`
}

func CreateUserHandler(w http.ResponseWriter, r *http.Request) {
    // Bind JSON request
    req, err := binding.JSON[CreateUserRequest](r.Body)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid request body", err)
        return
    }
    
    // Validate
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Create user
    user := &User{
        Username: req.Username,
        Email:    req.Email,
        Age:      req.Age,
    }
    if err := db.Create(user); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to create user", err)
        return
    }
    
    respondJSON(w, http.StatusCreated, user)
}

func UpdateUserHandler(w http.ResponseWriter, r *http.Request) {
    // Get user ID from path
    userID := chi.URLParam(r, "id")
    
    // Bind partial update
    req, err := binding.JSON[UpdateUserRequest](r.Body)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid request body", err)
        return
    }
    
    // Validate
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Fetch existing user
    user, err := db.GetUser(userID)
    if err != nil {
        respondError(w, http.StatusNotFound, "User not found", err)
        return
    }
    
    // Apply updates (only non-nil fields)
    if req.Username != nil {
        user.Username = *req.Username
    }
    if req.Email != nil {
        user.Email = *req.Email
    }
    if req.Age != nil {
        user.Age = *req.Age
    }
    
    if err := db.Update(user); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to update user", err)
        return
    }
    
    respondJSON(w, http.StatusOK, user)
}

func ListUsersHandler(w http.ResponseWriter, r *http.Request) {
    // Bind query parameters
    params, err := binding.Query[ListUsersParams](r.URL.Query())
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid query parameters", err)
        return
    }
    
    // Fetch users with pagination
    users, total, err := db.ListUsers(params)
    if err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to list users", err)
        return
    }
    
    // Response with pagination metadata
    response := map[string]interface{}{
        "data":       users,
        "total":      total,
        "page":       params.Page,
        "page_size":  params.PageSize,
        "total_pages": (total + params.PageSize - 1) / params.PageSize,
    }
    
    respondJSON(w, http.StatusOK, response)
}

// Helper functions
func respondJSON(w http.ResponseWriter, status int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, status int, message string, err error) {
    response := map[string]interface{}{
        "error":   message,
        "details": err.Error(),
    }
    respondJSON(w, status, response)
}
```

## Search API with Complex Filtering

Advanced search with multiple filter types:

```go
type ProductSearchRequest struct {
    // Basic search
    Query string `query:"q"`
    
    // Pagination
    Page     int `query:"page" default:"1"`
    PageSize int `query:"page_size" default:"20"`
    
    // Sorting
    SortBy    string `query:"sort_by" default:"relevance"`
    SortOrder string `query:"sort_order" default:"desc"`
    
    // Filters (from JSON body for complex queries)
    Filters struct {
        Categories []string  `json:"categories"`
        Brands     []string  `json:"brands"`
        MinPrice   *float64  `json:"min_price"`
        MaxPrice   *float64  `json:"max_price"`
        InStock    *bool     `json:"in_stock"`
        MinRating  *int      `json:"min_rating"`
        Tags       []string  `json:"tags"`
        DateRange  *struct {
            From time.Time `json:"from"`
            To   time.Time `json:"to"`
        } `json:"date_range"`
    } `json:"filters"`
    
    // Metadata from headers
    Locale    string `header:"Accept-Language" default:"en-US"`
    Currency  string `header:"X-Currency" default:"USD"`
    UserAgent string `header:"User-Agent"`
}

func SearchProductsHandler(w http.ResponseWriter, r *http.Request) {
    // Multi-source binding: query + JSON + headers
    req, err := binding.Bind[ProductSearchRequest](
        binding.FromQuery(r.URL.Query()),
        binding.FromJSON(r.Body),
        binding.FromHeader(r.Header),
    )
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid request", err)
        return
    }
    
    // Build search query
    query := db.NewQuery().
        Search(req.Query).
        Page(req.Page, req.PageSize).
        Sort(req.SortBy, req.SortOrder)
    
    // Apply filters
    if len(req.Filters.Categories) > 0 {
        query = query.FilterCategories(req.Filters.Categories)
    }
    if len(req.Filters.Brands) > 0 {
        query = query.FilterBrands(req.Filters.Brands)
    }
    if req.Filters.MinPrice != nil {
        query = query.MinPrice(*req.Filters.MinPrice)
    }
    if req.Filters.MaxPrice != nil {
        query = query.MaxPrice(*req.Filters.MaxPrice)
    }
    if req.Filters.InStock != nil && *req.Filters.InStock {
        query = query.InStockOnly()
    }
    if req.Filters.MinRating != nil {
        query = query.MinRating(*req.Filters.MinRating)
    }
    if req.Filters.DateRange != nil {
        query = query.DateRange(req.Filters.DateRange.From, req.Filters.DateRange.To)
    }
    
    // Execute search
    results, total, err := query.Execute(r.Context())
    if err != nil {
        respondError(w, http.StatusInternalServerError, "Search failed", err)
        return
    }
    
    // Apply currency conversion if needed
    if req.Currency != "USD" {
        results = convertCurrency(results, req.Currency)
    }
    
    response := map[string]interface{}{
        "results":     results,
        "total":       total,
        "page":        req.Page,
        "page_size":   req.PageSize,
        "total_pages": (total + req.PageSize - 1) / req.PageSize,
    }
    
    respondJSON(w, http.StatusOK, response)
}
```

## Multi-Tenant API

Handle tenant context from headers:

```go
type TenantRequest struct {
    TenantID string `header:"X-Tenant-ID" validate:"required,uuid"`
    APIKey   string `header:"X-API-Key" validate:"required"`
}

type CreateResourceRequest struct {
    TenantRequest
    Name        string `json:"name" validate:"required"`
    Description string `json:"description"`
    Type        string `json:"type" validate:"required,oneof=typeA typeB typeC"`
}

func CreateResourceHandler(w http.ResponseWriter, r *http.Request) {
    // Bind headers + JSON
    req, err := binding.Bind[CreateResourceRequest](
        binding.FromHeader(r.Header),
        binding.FromJSON(r.Body),
    )
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid request", err)
        return
    }
    
    // Validate
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Verify tenant and API key
    tenant, err := auth.VerifyTenant(req.TenantID, req.APIKey)
    if err != nil {
        respondError(w, http.StatusUnauthorized, "Invalid tenant credentials", err)
        return
    }
    
    // Create resource in tenant context
    resource := &Resource{
        TenantID:    tenant.ID,
        Name:        req.Name,
        Description: req.Description,
        Type:        req.Type,
    }
    
    if err := db.Create(resource); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to create resource", err)
        return
    }
    
    respondJSON(w, http.StatusCreated, resource)
}
```

## File Upload with Metadata

Handle multipart form data:

```go
type FileUploadRequest struct {
    Title       string   `form:"title" validate:"required"`
    Description string   `form:"description"`
    Tags        []string `form:"tags"`
    Public      bool     `form:"public"`
}

func UploadFileHandler(w http.ResponseWriter, r *http.Request) {
    // Parse multipart form (32MB max)
    if err := r.ParseMultipartForm(32 << 20); err != nil {
        respondError(w, http.StatusBadRequest, "Failed to parse form", err)
        return
    }
    
    // Bind form fields
    req, err := binding.Form[FileUploadRequest](r.Form)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid form data", err)
        return
    }
    
    // Validate
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Get uploaded file
    file, header, err := r.FormFile("file")
    if err != nil {
        respondError(w, http.StatusBadRequest, "Missing or invalid file", err)
        return
    }
    defer file.Close()
    
    // Validate file type
    if !isAllowedFileType(header.Header.Get("Content-Type")) {
        respondError(w, http.StatusBadRequest, "Invalid file type", nil)
        return
    }
    
    // Save file
    savedFile, err := storage.SaveFile(file, header.Filename)
    if err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to save file", err)
        return
    }
    
    // Create database record
    record := &FileRecord{
        Title:       req.Title,
        Description: req.Description,
        Tags:        req.Tags,
        Public:      req.Public,
        Filename:    savedFile.Name,
        Size:        savedFile.Size,
        ContentType: header.Header.Get("Content-Type"),
    }
    
    if err := db.Create(record); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to create record", err)
        return
    }
    
    respondJSON(w, http.StatusCreated, record)
}
```

## Webhook Handler with Signature Verification

Process webhooks with headers:

```go
type WebhookRequest struct {
    Signature string    `header:"X-Webhook-Signature" validate:"required"`
    Timestamp time.Time `header:"X-Webhook-Timestamp" validate:"required"`
    Event     string    `header:"X-Webhook-Event" validate:"required"`
    
    Payload json.RawMessage `json:"-"`
}

func WebhookHandler(w http.ResponseWriter, r *http.Request) {
    // Read body for signature verification
    body, err := io.ReadAll(r.Body)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Failed to read body", err)
        return
    }
    r.Body = io.NopCloser(bytes.NewReader(body))
    
    // Bind headers
    req, err := binding.Header[WebhookRequest](r.Header)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid headers", err)
        return
    }
    
    // Validate
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Verify signature
    if !verifyWebhookSignature(body, req.Signature, webhookSecret) {
        respondError(w, http.StatusUnauthorized, "Invalid signature", nil)
        return
    }
    
    // Check timestamp (prevent replay attacks)
    if time.Since(req.Timestamp) > 5*time.Minute {
        respondError(w, http.StatusBadRequest, "Request too old", nil)
        return
    }
    
    // Store raw payload
    req.Payload = body
    
    // Process event
    switch req.Event {
    case "payment.success":
        var payment PaymentEvent
        if err := json.Unmarshal(body, &payment); err != nil {
            respondError(w, http.StatusBadRequest, "Invalid payment payload", err)
            return
        }
        handlePaymentSuccess(payment)
        
    case "payment.failed":
        var payment PaymentEvent
        if err := json.Unmarshal(body, &payment); err != nil {
            respondError(w, http.StatusBadRequest, "Invalid payment payload", err)
            return
        }
        handlePaymentFailed(payment)
        
    default:
        respondError(w, http.StatusBadRequest, "Unknown event type", nil)
        return
    }
    
    w.WriteHeader(http.StatusNoContent)
}
```

## GraphQL-style Nested Queries

Handle complex nested structures:

```go
type GraphQLRequest struct {
    Query     string                 `json:"query" validate:"required"`
    Variables map[string]interface{} `json:"variables"`
    OperationName string              `json:"operationName"`
}

type GraphQLResponse struct {
    Data   interface{}            `json:"data,omitempty"`
    Errors []GraphQLError         `json:"errors,omitempty"`
}

type GraphQLError struct {
    Message string `json:"message"`
    Path    []string `json:"path,omitempty"`
}

func GraphQLHandler(w http.ResponseWriter, r *http.Request) {
    req, err := binding.JSON[GraphQLRequest](r.Body)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid GraphQL request", err)
        return
    }
    
    // Validate
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Execute GraphQL query
    result := executeGraphQL(r.Context(), req.Query, req.Variables, req.OperationName)
    
    respondJSON(w, http.StatusOK, result)
}
```

## Batch Operations

Process multiple items in one request:

```go
type BatchCreateRequest []CreateUserRequest

type BatchResponse struct {
    Success []User       `json:"success"`
    Failed  []BatchError `json:"failed"`
}

type BatchError struct {
    Index int    `json:"index"`
    Item  interface{} `json:"item"`
    Error string `json:"error"`
}

func BatchCreateUsersHandler(w http.ResponseWriter, r *http.Request) {
    // Bind array of requests
    batch, err := binding.JSON[BatchCreateRequest](r.Body)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid batch request", err)
        return
    }
    
    // Validate batch size
    if len(batch) == 0 {
        respondError(w, http.StatusBadRequest, "Empty batch", nil)
        return
    }
    if len(batch) > 100 {
        respondError(w, http.StatusBadRequest, "Batch too large (max 100)", nil)
        return
    }
    
    response := BatchResponse{
        Success: make([]User, 0),
        Failed:  make([]BatchError, 0),
    }
    
    // Process each item
    for i, req := range batch {
        // Validate item
        if err := validation.Validate(req); err != nil {
            response.Failed = append(response.Failed, BatchError{
                Index: i,
                Item:  req,
                Error: err.Error(),
            })
            continue
        }
        
        // Create user
        user := &User{
            Username: req.Username,
            Email:    req.Email,
            Age:      req.Age,
        }
        
        if err := db.Create(user); err != nil {
            response.Failed = append(response.Failed, BatchError{
                Index: i,
                Item:  req,
                Error: err.Error(),
            })
            continue
        }
        
        response.Success = append(response.Success, *user)
    }
    
    // Return 207 Multi-Status if there were any failures
    status := http.StatusCreated
    if len(response.Failed) > 0 {
        status = http.StatusMultiStatus
    }
    
    respondJSON(w, status, response)
}
```

## Integration with Rivaas App

Complete application setup:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "rivaas.dev/app"
    "rivaas.dev/binding"
    "rivaas.dev/router"
)

func main() {
    // Create app
    a := app.MustNew(
        app.WithServiceName("api-server"),
        app.WithServiceVersion("1.0.0"),
    )
    
    // Setup routes
    setupRoutes(a)
    
    // Graceful shutdown
    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
    defer stop()
    
    // Start server
    addr := ":8080"
    log.Printf("Server starting on %s", addr)
    
    if err := a.Start(ctx, addr); err != nil {
        log.Fatal(err)
    }
}

func setupRoutes(a *app.App) {
    // Users
    a.POST("/users", CreateUserHandler)
    a.GET("/users", ListUsersHandler)
    a.GET("/users/:id", GetUserHandler)
    a.PATCH("/users/:id", UpdateUserHandler)
    a.DELETE("/users/:id", DeleteUserHandler)
    
    // Search
    a.POST("/search", SearchProductsHandler)
}

func CreateUserHandler(c *router.Context) error {
    req, err := binding.JSON[CreateUserRequest](c.Request().Body)
    if err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{
            "error": err.Error(),
        })
    }
    
    user := createUser(req)
    return c.JSON(http.StatusCreated, user)
}
```

## Next Steps

- Review [API Reference](/reference/packages/binding/api-reference/) for all features
- Check [Performance](/reference/packages/binding/performance/) for optimization tips
- See [Troubleshooting](/reference/packages/binding/troubleshooting/) for common issues
- Explore [Sub-Packages](/reference/packages/binding/sub-packages/) for YAML, TOML, etc.

For complete API documentation, see [API Reference](/reference/packages/binding/api-reference/).
