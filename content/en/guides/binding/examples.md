---
title: "Examples"
description: "Real-world examples and integration patterns for common use cases"
weight: 11
keywords:
  - binding examples
  - code samples
  - use cases
  - integration patterns
---

Complete, production-ready examples demonstrating common binding patterns and integrations.

## Basic REST API

Complete CRUD handlers with proper error handling.

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

Handle file uploads with form data using the new multipart binding:

```go
type FileUploadRequest struct {
    File        *binding.File `form:"file" validate:"required"`
    Title       string        `form:"title" validate:"required"`
    Description string        `form:"description"`
    Tags        []string      `form:"tags"`
    Public      bool          `form:"public"`
    // JSON settings in form field (automatically parsed)
    Settings    struct {
        Quality     int    `json:"quality"`
        Compression string `json:"compression"`
    } `form:"settings"`
}

func UploadFileHandler(w http.ResponseWriter, r *http.Request) {
    // Parse multipart form (32MB max)
    if err := r.ParseMultipartForm(32 << 20); err != nil {
        respondError(w, http.StatusBadRequest, "Failed to parse form", err)
        return
    }
    
    // Bind form fields and file
    req, err := binding.Multipart[FileUploadRequest](r.MultipartForm)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid form data", err)
        return
    }
    
    // Validate
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Validate file type
    allowedTypes := []string{".jpg", ".jpeg", ".png", ".gif", ".pdf"}
    ext := req.File.Ext()
    if !contains(allowedTypes, ext) {
        respondError(w, http.StatusBadRequest, "Invalid file type", nil)
        return
    }
    
    // Validate file size (10MB max)
    if req.File.Size > 10*1024*1024 {
        respondError(w, http.StatusBadRequest, "File too large (max 10MB)", nil)
        return
    }
    
    // Generate safe filename
    filename := fmt.Sprintf("%s_%d%s", 
        sanitizeFilename(req.Title),
        time.Now().Unix(),
        ext,
    )
    
    // Save file
    uploadPath := "/var/uploads/" + filename
    if err := req.File.Save(uploadPath); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to save file", err)
        return
    }
    
    // Create database record
    record := &FileRecord{
        Filename:    filename,
        Title:       req.Title,
        Description: req.Description,
        Tags:        req.Tags,
        Public:      req.Public,
        Size:        req.File.Size,
        ContentType: req.File.ContentType,
        Settings:    req.Settings,
    }
    
    if err := db.Create(record); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to create record", err)
        return
    }
    
    respondJSON(w, http.StatusCreated, map[string]interface{}{
        "id":       record.ID,
        "filename": filename,
        "url":      "/uploads/" + filename,
    })
}

func sanitizeFilename(name string) string {
    // Remove special characters
    re := regexp.MustCompile(`[^a-zA-Z0-9_-]`)
    return re.ReplaceAllString(name, "_")
}

func contains(slice []string, item string) bool {
    for _, s := range slice {
        if s == item {
            return true
        }
    }
    return false
}
```

**Multiple file uploads:**

```go
type GalleryUpload struct {
    Photos      []*binding.File `form:"photos" validate:"required,min=1,max=10"`
    AlbumTitle  string          `form:"album_title" validate:"required"`
    Description string          `form:"description"`
}

func UploadGalleryHandler(w http.ResponseWriter, r *http.Request) {
    if err := r.ParseMultipartForm(100 << 20); err != nil { // 100MB for multiple files
        respondError(w, http.StatusBadRequest, "Failed to parse form", err)
        return
    }
    
    req, err := binding.Multipart[GalleryUpload](r.MultipartForm)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid form data", err)
        return
    }
    
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Process each photo
    uploadedFiles := make([]string, 0, len(req.Photos))
    for i, photo := range req.Photos {
        // Validate each file
        if photo.Size > 10*1024*1024 {
            respondError(w, http.StatusBadRequest, 
                fmt.Sprintf("Photo %d too large", i+1), nil)
            return
        }
        
        // Generate filename
        filename := fmt.Sprintf("%s_%d_%d%s",
            sanitizeFilename(req.AlbumTitle),
            time.Now().Unix(),
            i,
            photo.Ext(),
        )
        
        // Save file
        if err := photo.Save("/var/uploads/" + filename); err != nil {
            respondError(w, http.StatusInternalServerError, "Failed to save photo", err)
            return
        }
        
        uploadedFiles = append(uploadedFiles, filename)
    }
    
    // Create album record
    album := &Album{
        Title:       req.AlbumTitle,
        Description: req.Description,
        Photos:      uploadedFiles,
    }
    
    if err := db.Create(album); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to create album", err)
        return
    }
    
    respondJSON(w, http.StatusCreated, album)
}
```

## API with Converter Factories

Using built-in converter factories for common patterns:

```go
package main

import (
    "net/http"
    "time"
    "github.com/google/uuid"
    "rivaas.dev/binding"
)

type TaskStatus string

const (
    TaskPending   TaskStatus = "pending"
    TaskActive    TaskStatus = "active"
    TaskCompleted TaskStatus = "completed"
)

type Priority string

const (
    PriorityLow    Priority = "low"
    PriorityMedium Priority = "medium"
    PriorityHigh   Priority = "high"
)

// Global binder with converter factories
var TaskBinder = binding.MustNew(
    // UUID for task IDs
    binding.WithConverter[uuid.UUID](uuid.Parse),
    
    // Status enum with validation
    binding.WithConverter(binding.EnumConverter(
        TaskPending,
        TaskActive,
        TaskCompleted,
    )),
    
    // Priority enum with validation
    binding.WithConverter(binding.EnumConverter(
        PriorityLow,
        PriorityMedium,
        PriorityHigh,
    )),
    
    // Friendly duration aliases
    binding.WithConverter(binding.DurationConverter(map[string]time.Duration{
        "urgent":   1 * time.Hour,
        "today":    8 * time.Hours,
        "thisweek": 5 * 24 * time.Hour,
        "nextweek": 14 * 24 * time.Hour,
    })),
    
    // US date format for deadlines
    binding.WithConverter(binding.TimeConverter("01/02/2006", "2006-01-02")),
    
    // Boolean with friendly values
    binding.WithConverter(binding.BoolConverter(
        []string{"yes", "on", "enabled"},
        []string{"no", "off", "disabled"},
    )),
)

type CreateTaskRequest struct {
    Title       string     `json:"title" validate:"required,min=3,max=100"`
    Description string     `json:"description"`
    Priority    Priority   `json:"priority" validate:"required"`
    Deadline    time.Time  `json:"deadline"`
    Estimate    time.Duration `json:"estimate"`
    Assignee    uuid.UUID  `json:"assignee"`
}

type UpdateTaskRequest struct {
    Title       *string        `json:"title,omitempty"`
    Description *string        `json:"description,omitempty"`
    Status      *TaskStatus    `json:"status,omitempty"`
    Priority    *Priority      `json:"priority,omitempty"`
    Deadline    *time.Time     `json:"deadline,omitempty"`
    Completed   *bool          `json:"completed,omitempty"`
}

type ListTasksParams struct {
    Status    TaskStatus `query:"status"`
    Priority  Priority   `query:"priority"`
    Assignee  uuid.UUID  `query:"assignee"`
    DueIn     time.Duration `query:"due_in"`
    Page      int        `query:"page" default:"1"`
    PageSize  int        `query:"page_size" default:"20"`
    ShowDone  bool       `query:"show_done"`
}

func CreateTaskHandler(w http.ResponseWriter, r *http.Request) {
    // Bind and validate
    req, err := TaskBinder.JSON[CreateTaskRequest](r.Body)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid request", err)
        return
    }
    
    if err := validation.Validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, "Validation failed", err)
        return
    }
    
    // Create task
    task := &Task{
        ID:          uuid.New(),
        Title:       req.Title,
        Description: req.Description,
        Priority:    req.Priority,
        Status:      TaskPending,
        Deadline:    req.Deadline,
        Estimate:    req.Estimate,
        Assignee:    req.Assignee,
        CreatedAt:   time.Now(),
    }
    
    if err := db.Create(task); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to create task", err)
        return
    }
    
    respondJSON(w, http.StatusCreated, task)
}

func UpdateTaskHandler(w http.ResponseWriter, r *http.Request) {
    // Get task ID from path
    taskID, err := uuid.Parse(chi.URLParam(r, "id"))
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid task ID", err)
        return
    }
    
    // Bind partial update
    req, err := TaskBinder.JSON[UpdateTaskRequest](r.Body)
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid request", err)
        return
    }
    
    // Fetch existing task
    task, err := db.GetTask(taskID)
    if err != nil {
        respondError(w, http.StatusNotFound, "Task not found", err)
        return
    }
    
    // Apply updates (only non-nil fields)
    if req.Title != nil {
        task.Title = *req.Title
    }
    if req.Description != nil {
        task.Description = *req.Description
    }
    if req.Status != nil {
        task.Status = *req.Status
    }
    if req.Priority != nil {
        task.Priority = *req.Priority
    }
    if req.Deadline != nil {
        task.Deadline = *req.Deadline
    }
    if req.Completed != nil && *req.Completed {
        task.Status = TaskCompleted
        task.CompletedAt = time.Now()
    }
    
    task.UpdatedAt = time.Now()
    
    if err := db.Update(task); err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to update task", err)
        return
    }
    
    respondJSON(w, http.StatusOK, task)
}

func ListTasksHandler(w http.ResponseWriter, r *http.Request) {
    // Bind query parameters with enum/duration validation
    params, err := TaskBinder.Query[ListTasksParams](r.URL.Query())
    if err != nil {
        respondError(w, http.StatusBadRequest, "Invalid query parameters", err)
        return
    }
    
    // Build query
    query := db.NewQuery()
    
    if params.Status != "" {
        query = query.Where("status = ?", params.Status)
    }
    if params.Priority != "" {
        query = query.Where("priority = ?", params.Priority)
    }
    if params.Assignee != uuid.Nil {
        query = query.Where("assignee = ?", params.Assignee)
    }
    if params.DueIn > 0 {
        dueDate := time.Now().Add(params.DueIn)
        query = query.Where("deadline <= ?", dueDate)
    }
    if !params.ShowDone {
        query = query.Where("status != ?", TaskCompleted)
    }
    
    // Execute with pagination
    tasks, total, err := query.Paginate(params.Page, params.PageSize).Execute()
    if err != nil {
        respondError(w, http.StatusInternalServerError, "Failed to list tasks", err)
        return
    }
    
    response := map[string]interface{}{
        "data":        tasks,
        "total":       total,
        "page":        params.Page,
        "page_size":   params.PageSize,
        "total_pages": (total + params.PageSize - 1) / params.PageSize,
    }
    
    respondJSON(w, http.StatusOK, response)
}

// Example requests that work with the converter factories:
// POST /tasks
// {
//   "title": "Fix bug #123",
//   "priority": "high",
//   "deadline": "01/31/2026",
//   "estimate": "urgent",
//   "assignee": "550e8400-e29b-41d4-a716-446655440000"
// }
//
// GET /tasks?status=active&priority=HIGH&due_in=today&show_done=yes
// Note: enums are case-insensitive, duration uses friendly aliases, bool uses "yes"
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
- Check [Router Performance](/reference/packages/router/performance/) for benchmark methodology
- See [Troubleshooting](/reference/packages/binding/troubleshooting/) for common issues
- Explore [Sub-Packages](/reference/packages/binding/sub-packages/) for YAML, TOML, etc.

For complete API documentation, see [API Reference](/reference/packages/binding/api-reference/).
