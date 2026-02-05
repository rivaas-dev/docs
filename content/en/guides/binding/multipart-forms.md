---
title: "Multipart Forms"
description: "Handle file uploads with form data using multipart form binding"
weight: 5
keywords:
  - multipart forms
  - file upload
  - form data
  - file handling
---

This guide shows you how to handle file uploads and form data together using multipart form binding. You'll learn how to bind files, work with the `File` type, and handle complex scenarios like JSON in form fields.

## What Are Multipart Forms?

Multipart forms let you send files and regular form data in the same HTTP request. This is useful when you need to upload files along with metadata, like uploading a profile picture with user information.

**Common use cases:**
- Uploading images with titles and descriptions
- Importing CSV files with configuration options
- Submitting documents with form metadata

## Basic File Upload

Let's start with a simple example. You want to upload a file with some metadata:

```go
import "rivaas.dev/binding"

type UploadRequest struct {
    File        *binding.File `form:"file"`
    Title       string        `form:"title"`
    Description string        `form:"description"`
}

// Parse the multipart form
if err := r.ParseMultipartForm(32 << 20); err != nil { // 32MB max
    // Handle error
}

// Bind the form data
req, err := binding.Multipart[UploadRequest](r.MultipartForm)
if err != nil {
    // Handle binding error
}

// Now you have:
// - req.File - the uploaded file
// - req.Title - the title from form
// - req.Description - the description from form
```

## Working with Files

The `binding.File` type gives you easy access to uploaded files. Here's what you can do:

### File Properties

```go
file := req.File

fmt.Println(file.Name)        // "photo.jpg" - sanitized filename
fmt.Println(file.Size)        // 1024 - file size in bytes
fmt.Println(file.ContentType) // "image/jpeg" - MIME type
```

### Save to Disk

The easiest way to handle uploads is to save them directly:

```go
// Save to a specific path
err := file.Save("/uploads/photo.jpg")
if err != nil {
    // Handle save error
}

// Save with original filename
err := file.Save("/uploads/" + file.Name)
```

The `Save()` method automatically creates parent directories if they don't exist.

### Read File Contents

You can read the file into memory:

```go
// Get all bytes
data, err := file.Bytes()
if err != nil {
    // Handle error
}

// Process the data
processImage(data)
```

### Stream File Contents

For larger files, you can stream the content:

```go
// Open the file for reading
reader, err := file.Open()
if err != nil {
    // Handle error
}
defer reader.Close()

// Stream to another location
io.Copy(destination, reader)
```

### Get File Extension

```go
ext := file.Ext() // ".jpg" for "photo.jpg"

// Useful for validation
if ext != ".jpg" && ext != ".png" {
    return errors.New("only JPG and PNG files allowed")
}
```

## Multiple File Uploads

You can handle multiple files using a slice:

```go
type GalleryUpload struct {
    Photos []*binding.File `form:"photos"`
    Title  string          `form:"title"`
}

req, err := binding.Multipart[GalleryUpload](r.MultipartForm)
if err != nil {
    // Handle error
}

// Process each file
for i, photo := range req.Photos {
    filename := fmt.Sprintf("/uploads/photo_%d%s", i, photo.Ext())
    if err := photo.Save(filename); err != nil {
        // Handle error
    }
}
```

## JSON in Form Fields

Here's a powerful feature: Rivaas automatically parses JSON from form fields into nested structs.

```go
type Settings struct {
    Theme         string `json:"theme"`
    Notifications bool   `json:"notifications"`
}

type ProfileUpdate struct {
    Avatar   *binding.File `form:"avatar"`
    Username string        `form:"username"`
    Settings Settings      `form:"settings"` // JSON automatically parsed!
}

// In your HTML form:
// <input type="file" name="avatar">
// <input type="text" name="username">
// <input type="hidden" name="settings" value='{"theme":"dark","notifications":true}'>

req, err := binding.Multipart[ProfileUpdate](r.MultipartForm)
if err != nil {
    // Handle error
}

// req.Settings is now populated from the JSON string
fmt.Println(req.Settings.Theme)         // "dark"
fmt.Println(req.Settings.Notifications) // true
```

This works with deeply nested structures too:

```go
type ImportOptions struct {
    Format   string `json:"format"`
    Encoding string `json:"encoding"`
    Options  struct {
        SkipHeader bool `json:"skip_header"`
        Delimiter  string `json:"delimiter"`
    } `json:"options"`
}

type ImportRequest struct {
    File    *binding.File   `form:"file"`
    Options ImportOptions   `form:"options"` // Complex JSON parsed automatically
}
```

## Complete Example

Here's a realistic file upload handler:

```go
package main

import (
    "fmt"
    "net/http"
    "rivaas.dev/binding"
    "rivaas.dev/validation"
)

type UploadRequest struct {
    File        *binding.File `form:"file" validate:"required"`
    Title       string        `form:"title" validate:"required,min=3,max=100"`
    Description string        `form:"description"`
    Tags        []string      `form:"tags"`
    IsPublic    bool          `form:"is_public"`
}

func UploadHandler(w http.ResponseWriter, r *http.Request) {
    // Step 1: Parse multipart form (32MB limit)
    if err := r.ParseMultipartForm(32 << 20); err != nil {
        http.Error(w, "Failed to parse form", http.StatusBadRequest)
        return
    }
    
    // Step 2: Bind form data
    req, err := binding.Multipart[UploadRequest](r.MultipartForm)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Step 3: Validate
    if err := validation.Validate(req); err != nil {
        http.Error(w, err.Error(), http.StatusUnprocessableEntity)
        return
    }
    
    // Step 4: Validate file type
    allowedTypes := []string{".jpg", ".jpeg", ".png", ".gif"}
    ext := req.File.Ext()
    if !contains(allowedTypes, ext) {
        http.Error(w, "Invalid file type", http.StatusBadRequest)
        return
    }
    
    // Step 5: Validate file size
    if req.File.Size > 10*1024*1024 { // 10MB
        http.Error(w, "File too large", http.StatusBadRequest)
        return
    }
    
    // Step 6: Generate safe filename
    filename := fmt.Sprintf("%s_%d%s", 
        sanitizeFilename(req.Title),
        time.Now().Unix(),
        ext,
    )
    
    // Step 7: Save file
    uploadPath := "/var/uploads/" + filename
    if err := req.File.Save(uploadPath); err != nil {
        http.Error(w, "Failed to save file", http.StatusInternalServerError)
        return
    }
    
    // Step 8: Save metadata to database
    file := &FileRecord{
        Filename:    filename,
        Title:       req.Title,
        Description: req.Description,
        Tags:        req.Tags,
        IsPublic:    req.IsPublic,
        Size:        req.File.Size,
        ContentType: req.File.ContentType,
    }
    
    if err := db.Create(file); err != nil {
        http.Error(w, "Failed to save metadata", http.StatusInternalServerError)
        return
    }
    
    // Step 9: Return success
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "id":       file.ID,
        "filename": filename,
        "url":      "/uploads/" + filename,
    })
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

## File Security

Always validate uploaded files to protect your application:

### 1. Validate File Type

Don't trust the `Content-Type` header alone. Check the file extension:

```go
allowedExtensions := []string{".jpg", ".jpeg", ".png", ".gif"}
ext := strings.ToLower(file.Ext())

if !slices.Contains(allowedExtensions, ext) {
    return errors.New("file type not allowed")
}
```

For better security, check the file's magic bytes:

```go
data, err := file.Bytes()
if err != nil {
    return err
}

// Check magic bytes for JPEG
if len(data) < 2 || data[0] != 0xFF || data[1] != 0xD8 {
    return errors.New("not a valid JPEG file")
}
```

### 2. Validate File Size

```go
maxSize := int64(10 * 1024 * 1024) // 10MB
if file.Size > maxSize {
    return errors.New("file too large")
}
```

### 3. Sanitize Filenames

The `File` type automatically sanitizes filenames by:
- Using only the base filename (removes paths)
- Replacing dangerous characters

But you should also generate unique names:

```go
import (
    "crypto/rand"
    "encoding/hex"
    "path/filepath"
)

func generateSafeFilename(originalName string) string {
    ext := filepath.Ext(originalName)
    
    // Generate random name
    b := make([]byte, 16)
    rand.Read(b)
    name := hex.EncodeToString(b)
    
    return name + ext
}

// Use it
safeName := generateSafeFilename(file.Name)
file.Save("/uploads/" + safeName)
```

### 4. Store Outside Web Root

Never save uploads directly in your web server's document root:

```go
// Bad - files accessible directly via URL
file.Save("/var/www/html/uploads/file.jpg")

// Good - files outside web root
file.Save("/var/app/uploads/file.jpg")

// Serve files through a handler that checks permissions
```

### 5. Scan for Malware

For production applications, scan uploaded files:

```go
// Example with ClamAV
if infected, err := scanFile(uploadPath); err != nil {
    return err
} else if infected {
    os.Remove(uploadPath)
    return errors.New("file contains malware")
}
```

## Integration with Rivaas App

When using `rivaas.dev/app`, the `Context.Bind()` method handles multipart forms automatically:

```go
import "rivaas.dev/app"

type UploadRequest struct {
    File  *binding.File `form:"file"`
    Title string        `form:"title"`
}

a.POST("/upload", func(c *app.Context) {
    var req UploadRequest
    if err := c.Bind(&req); err != nil {
        c.Fail(err)
        return
    }
    
    // req.File is ready to use
    if err := req.File.Save("/uploads/" + req.File.Name); err != nil {
        c.InternalError(err)
        return
    }
    
    c.JSON(http.StatusOK, map[string]string{
        "message": "File uploaded successfully",
    })
})
```

The app context automatically:
- Parses the multipart form
- Binds files and form fields
- Handles errors appropriately

## Common Patterns

### Image Processing Pipeline

```go
type ImageUpload struct {
    Image   *binding.File `form:"image"`
    Width   int           `form:"width" default:"800"`
    Height  int           `form:"height" default:"600"`
    Quality int           `form:"quality" default:"85"`
}

func ProcessImageHandler(w http.ResponseWriter, r *http.Request) {
    r.ParseMultipartForm(32 << 20)
    
    req, err := binding.Multipart[ImageUpload](r.MultipartForm)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Read image data
    data, err := req.Image.Bytes()
    if err != nil {
        http.Error(w, "Failed to read image", http.StatusInternalServerError)
        return
    }
    
    // Process image
    processed, err := resizeImage(data, req.Width, req.Height, req.Quality)
    if err != nil {
        http.Error(w, "Failed to process image", http.StatusInternalServerError)
        return
    }
    
    // Save processed image
    outputPath := "/uploads/processed_" + req.Image.Name
    if err := os.WriteFile(outputPath, processed, 0644); err != nil {
        http.Error(w, "Failed to save image", http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "url": "/uploads/" + filepath.Base(outputPath),
    })
}
```

### CSV Import with Options

```go
type CSVImportRequest struct {
    File       *binding.File `form:"file"`
    Options    struct {
        SkipHeader bool   `json:"skip_header"`
        Delimiter  string `json:"delimiter"`
        Encoding   string `json:"encoding"`
    } `form:"options"` // JSON from form field
}

func ImportCSVHandler(w http.ResponseWriter, r *http.Request) {
    r.ParseMultipartForm(32 << 20)
    
    req, err := binding.Multipart[CSVImportRequest](r.MultipartForm)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Validate CSV file
    if req.File.Ext() != ".csv" {
        http.Error(w, "Only CSV files allowed", http.StatusBadRequest)
        return
    }
    
    // Open file for streaming
    reader, err := req.File.Open()
    if err != nil {
        http.Error(w, "Failed to open file", http.StatusInternalServerError)
        return
    }
    defer reader.Close()
    
    // Parse CSV with options
    csvReader := csv.NewReader(reader)
    csvReader.Comma = rune(req.Options.Delimiter[0])
    
    if req.Options.SkipHeader {
        csvReader.Read() // Skip first row
    }
    
    // Process records
    records, err := csvReader.ReadAll()
    if err != nil {
        http.Error(w, "Failed to parse CSV", http.StatusBadRequest)
        return
    }
    
    // Import into database
    for _, record := range records {
        // Process each record
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "imported": len(records),
    })
}
```

## Performance Tips

1. **Set appropriate size limits** - Don't let users upload huge files:
   ```go
   r.ParseMultipartForm(10 << 20) // 10MB limit
   ```

2. **Stream large files** - Don't load everything into memory:
   ```go
   reader, err := file.Open()
   defer reader.Close()
   io.Copy(destination, reader)
   ```

3. **Process asynchronously** - For heavy processing, use background jobs:
   ```go
   // Save file first
   file.Save(tempPath)
   
   // Queue processing job
   queue.Enqueue(ProcessFileJob{Path: tempPath})
   
   // Return immediately
   c.JSON(http.StatusAccepted, "Processing started")
   ```

4. **Clean up temporary files** - Remove uploaded files after processing:
   ```go
   defer os.Remove(tempPath)
   ```

## Error Handling

The binding package provides specific errors for file operations:

```go
req, err := binding.Multipart[UploadRequest](r.MultipartForm)
if err != nil {
    // Check for specific errors
    if errors.Is(err, binding.ErrFileNotFound) {
        http.Error(w, "No file uploaded", http.StatusBadRequest)
        return
    }
    
    if errors.Is(err, binding.ErrNoFilesFound) {
        http.Error(w, "Multiple files required", http.StatusBadRequest)
        return
    }
    
    // Generic binding error
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        http.Error(w, fmt.Sprintf("Field %s: %v", bindErr.Field, bindErr.Err), 
            http.StatusBadRequest)
        return
    }
    
    // Unknown error
    http.Error(w, "Failed to bind form data", http.StatusBadRequest)
    return
}
```

## Next Steps

- Learn about [Type Support](../type-support/) for custom type conversion
- Explore [Error Handling](../error-handling/) for detailed error management
- Check [Advanced Usage](../advanced-usage/) for custom getters and streaming
- See [Examples](../examples/) for real-world patterns

For complete API documentation, see [API Reference](/reference/packages/binding/api-reference/).
