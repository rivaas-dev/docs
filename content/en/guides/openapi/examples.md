---
title: "Examples"
description: "Complete examples and real-world usage patterns"
weight: 12
---

Complete examples demonstrating real-world usage patterns for the OpenAPI package.

## Basic CRUD API

A simple CRUD API with all HTTP methods:

```go
package main

import (
    "context"
    "log"
    "os"
    "time"

    "rivaas.dev/openapi"
)

type User struct {
    ID        int       `json:"id" doc:"User ID" example:"123"`
    Name      string    `json:"name" doc:"User's full name" example:"John Doe"`
    Email     string    `json:"email" doc:"Email address" example:"john@example.com"`
    CreatedAt time.Time `json:"created_at" doc:"Creation timestamp"`
}

type CreateUserRequest struct {
    Name  string `json:"name" doc:"User's full name" validate:"required"`
    Email string `json:"email" doc:"Email address" validate:"required,email"`
}

type ErrorResponse struct {
    Code    int    `json:"code" doc:"Error code"`
    Message string `json:"message" doc:"Error message"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("User API", "1.0.0"),
        openapi.WithInfoDescription("Simple CRUD API for user management"),
        openapi.WithServer("http://localhost:8080", "Local development"),
        openapi.WithServer("https://api.example.com", "Production"),
        openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
        openapi.WithTag("users", "User management operations"),
    )

    result, err := api.Generate(context.Background(),
        openapi.GET("/users",
            openapi.WithSummary("List users"),
            openapi.WithDescription("Retrieve a list of all users"),
            openapi.WithTags("users"),
            openapi.WithSecurity("bearerAuth"),
            openapi.WithResponse(200, []User{}),
            openapi.WithResponse(401, ErrorResponse{}),
        ),
        
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithDescription("Retrieve a specific user by ID"),
            openapi.WithTags("users"),
            openapi.WithSecurity("bearerAuth"),
            openapi.WithResponse(200, User{}),
            openapi.WithResponse(404, ErrorResponse{}),
            openapi.WithResponse(401, ErrorResponse{}),
        ),
        
        openapi.POST("/users",
            openapi.WithSummary("Create user"),
            openapi.WithDescription("Create a new user"),
            openapi.WithTags("users"),
            openapi.WithSecurity("bearerAuth"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(201, User{}),
            openapi.WithResponse(400, ErrorResponse{}),
            openapi.WithResponse(401, ErrorResponse{}),
        ),
        
        openapi.PUT("/users/:id",
            openapi.WithSummary("Update user"),
            openapi.WithDescription("Update an existing user"),
            openapi.WithTags("users"),
            openapi.WithSecurity("bearerAuth"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(200, User{}),
            openapi.WithResponse(400, ErrorResponse{}),
            openapi.WithResponse(404, ErrorResponse{}),
            openapi.WithResponse(401, ErrorResponse{}),
        ),
        
        openapi.DELETE("/users/:id",
            openapi.WithSummary("Delete user"),
            openapi.WithDescription("Delete a user"),
            openapi.WithTags("users"),
            openapi.WithSecurity("bearerAuth"),
            openapi.WithResponse(204, nil),
            openapi.WithResponse(404, ErrorResponse{}),
            openapi.WithResponse(401, ErrorResponse{}),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    if err := os.WriteFile("openapi.json", result.JSON, 0644); err != nil {
        log.Fatal(err)
    }

    log.Println("OpenAPI specification generated: openapi.json")
}
```

## API with Query Parameters and Pagination

```go
package main

import (
    "context"
    "log"
    
    "rivaas.dev/openapi"
)

type ListUsersRequest struct {
    Page    int      `query:"page" doc:"Page number" example:"1" validate:"min=1"`
    PerPage int      `query:"per_page" doc:"Items per page" example:"20" validate:"min=1,max=100"`
    Sort    string   `query:"sort" doc:"Sort field" enum:"name,email,created_at"`
    Order   string   `query:"order" doc:"Sort order" enum:"asc,desc"`
    Tags    []string `query:"tags" doc:"Filter by tags"`
    Active  *bool    `query:"active" doc:"Filter by active status"`
}

type User struct {
    ID     int      `json:"id"`
    Name   string   `json:"name"`
    Email  string   `json:"email"`
    Active bool     `json:"active"`
    Tags   []string `json:"tags"`
}

type PaginatedResponse struct {
    Data       []User `json:"data"`
    Page       int    `json:"page"`
    PerPage    int    `json:"per_page"`
    TotalPages int    `json:"total_pages"`
    TotalItems int    `json:"total_items"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("Paginated API", "1.0.0"),
        openapi.WithInfoDescription("API with pagination and filtering"),
    )

    result, err := api.Generate(context.Background(),
        openapi.GET("/users",
            openapi.WithSummary("List users with pagination"),
            openapi.WithDescription("Retrieve paginated list of users with filtering"),
            openapi.WithResponse(200, PaginatedResponse{}),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Use result...
}
```

## Multi-Source Parameters

```go
package main

import (
    "context"
    "log"
    
    "rivaas.dev/openapi"
)

type CreateOrderRequest struct {
    // Path parameter
    UserID int `path:"user_id" doc:"User ID" example:"123"`
    
    // Query parameters
    Coupon    string `query:"coupon" doc:"Coupon code" example:"SAVE20"`
    SendEmail *bool  `query:"send_email" doc:"Send confirmation email"`
    
    // Header parameters
    IdempotencyKey string `header:"Idempotency-Key" doc:"Idempotency key"`
    
    // Request body
    Items []OrderItem `json:"items" validate:"required,min=1"`
    Total float64     `json:"total" validate:"required,min=0"`
    Notes string      `json:"notes,omitempty"`
}

type OrderItem struct {
    ProductID int     `json:"product_id" validate:"required"`
    Quantity  int     `json:"quantity" validate:"required,min=1"`
    Price     float64 `json:"price" validate:"required,min=0"`
}

type Order struct {
    ID     int         `json:"id"`
    UserID int         `json:"user_id"`
    Items  []OrderItem `json:"items"`
    Total  float64     `json:"total"`
    Status string      `json:"status" enum:"pending,processing,completed,cancelled"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("E-commerce API", "1.0.0"),
    )

    result, err := api.Generate(context.Background(),
        openapi.POST("/users/:user_id/orders",
            openapi.WithSummary("Create order"),
            openapi.WithDescription("Create a new order for a user"),
            openapi.WithRequest(CreateOrderRequest{}),
            openapi.WithResponse(201, Order{}),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Use result...
}
```

## Composable Options Pattern

```go
package main

import (
    "context"
    "log"
    
    "rivaas.dev/openapi"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

type ErrorResponse struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
}

// Define reusable option sets
var (
    // Common error responses
    CommonErrors = openapi.WithOptions(
        openapi.WithResponse(400, ErrorResponse{}),
        openapi.WithResponse(401, ErrorResponse{}),
        openapi.WithResponse(500, ErrorResponse{}),
    )
    
    // Authenticated user endpoints
    UserEndpoint = openapi.WithOptions(
        openapi.WithTags("users"),
        openapi.WithSecurity("bearerAuth"),
        CommonErrors,
    )
    
    // JSON content type
    JSONContent = openapi.WithOptions(
        openapi.WithConsumes("application/json"),
        openapi.WithProduces("application/json"),
    )
    
    // Read operations
    ReadOperation = openapi.WithOptions(
        UserEndpoint,
        JSONContent,
    )
    
    // Write operations
    WriteOperation = openapi.WithOptions(
        UserEndpoint,
        JSONContent,
        openapi.WithResponse(404, ErrorResponse{}),
    )
)

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("Composable API", "1.0.0"),
        openapi.WithBearerAuth("bearerAuth", "JWT authentication"),
    )

    result, err := api.Generate(context.Background(),
        openapi.GET("/users/:id",
            ReadOperation,
            openapi.WithSummary("Get user"),
            openapi.WithResponse(200, User{}),
        ),
        
        openapi.POST("/users",
            WriteOperation,
            openapi.WithSummary("Create user"),
            openapi.WithRequest(User{}),
            openapi.WithResponse(201, User{}),
        ),
        
        openapi.PUT("/users/:id",
            WriteOperation,
            openapi.WithSummary("Update user"),
            openapi.WithRequest(User{}),
            openapi.WithResponse(200, User{}),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Use result...
}
```

## OAuth2 with Multiple Flows

```go
package main

import (
    "context"
    "log"
    
    "rivaas.dev/openapi"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("OAuth2 API", "1.0.0"),
        
        // Authorization code flow (for web apps)
        openapi.WithOAuth2(
            "oauth2AuthCode",
            "OAuth2 authorization code flow",
            openapi.OAuth2Flow{
                Type:             openapi.FlowAuthorizationCode,
                AuthorizationURL: "https://auth.example.com/authorize",
                TokenURL:         "https://auth.example.com/token",
                Scopes: map[string]string{
                    "read":  "Read access",
                    "write": "Write access",
                    "admin": "Admin access",
                },
            },
        ),
        
        // Client credentials flow (for service-to-service)
        openapi.WithOAuth2(
            "oauth2ClientCreds",
            "OAuth2 client credentials flow",
            openapi.OAuth2Flow{
                Type:     openapi.FlowClientCredentials,
                TokenURL: "https://auth.example.com/token",
                Scopes: map[string]string{
                    "api": "API access",
                },
            },
        ),
    )

    result, err := api.Generate(context.Background(),
        // Public endpoint
        openapi.GET("/health",
            openapi.WithSummary("Health check"),
            openapi.WithResponse(200, nil),
        ),
        
        // User-facing endpoint (auth code flow)
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithSecurity("oauth2AuthCode", "read"),
            openapi.WithResponse(200, User{}),
        ),
        
        // Service endpoint (client credentials flow)
        openapi.POST("/users/sync",
            openapi.WithSummary("Sync users"),
            openapi.WithSecurity("oauth2ClientCreds", "api"),
            openapi.WithResponse(200, nil),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Use result...
}
```

## Version-Aware API with Diagnostics

```go
package main

import (
    "context"
    "fmt"
    "log"
    
    "rivaas.dev/openapi"
    "rivaas.dev/openapi/diag"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

func main() {
    api := openapi.MustNew(
        openapi.WithTitle("Version-Aware API", "1.0.0"),
        openapi.WithVersion(openapi.V30x), // Target 3.0.x
        openapi.WithInfoSummary("API with 3.1 features"), // 3.1-only feature
    )

    result, err := api.Generate(context.Background(),
        openapi.GET("/users/:id",
            openapi.WithSummary("Get user"),
            openapi.WithResponse(200, User{}),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Handle warnings
    if result.Warnings.Has(diag.WarnDownlevelInfoSummary) {
        fmt.Println("Note: info.summary was dropped (3.1 feature with 3.0 target)")
    }

    // Filter by category
    downlevelWarnings := result.Warnings.FilterCategory(diag.CategoryDownlevel)
    if len(downlevelWarnings) > 0 {
        fmt.Printf("Downlevel warnings: %d\n", len(downlevelWarnings))
        for _, warn := range downlevelWarnings {
            fmt.Printf("  [%s] %s\n", warn.Code(), warn.Message())
        }
    }

    // Fail on unexpected warnings
    expected := []diag.WarningCode{
        diag.WarnDownlevelInfoSummary,
    }
    unexpected := result.Warnings.Exclude(expected...)
    if len(unexpected) > 0 {
        log.Fatalf("Unexpected warnings: %d", len(unexpected))
    }

    fmt.Println("Specification generated successfully")
}
```

## Complete Production Example

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    "time"

    "rivaas.dev/openapi"
    "rivaas.dev/openapi/diag"
)

// Domain models
type User struct {
    ID        int       `json:"id" doc:"User ID"`
    Name      string    `json:"name" doc:"User's full name"`
    Email     string    `json:"email" doc:"Email address"`
    Role      string    `json:"role" doc:"User role" enum:"admin,user,guest"`
    Active    bool      `json:"active" doc:"Whether user is active"`
    CreatedAt time.Time `json:"created_at" doc:"Creation timestamp"`
    UpdatedAt time.Time `json:"updated_at" doc:"Last update timestamp"`
}

type CreateUserRequest struct {
    Name  string `json:"name" validate:"required"`
    Email string `json:"email" validate:"required,email"`
    Role  string `json:"role" validate:"required" enum:"admin,user,guest"`
}

type ErrorResponse struct {
    Code      int       `json:"code"`
    Message   string    `json:"message"`
    Details   string    `json:"details,omitempty"`
    Timestamp time.Time `json:"timestamp"`
}

// Reusable option sets
var (
    CommonErrors = openapi.WithOptions(
        openapi.WithResponse(400, ErrorResponse{}),
        openapi.WithResponse(401, ErrorResponse{}),
        openapi.WithResponse(500, ErrorResponse{}),
    )
    
    UserEndpoint = openapi.WithOptions(
        openapi.WithTags("users"),
        openapi.WithSecurity("bearerAuth"),
        CommonErrors,
    )
)

func main() {
    api := openapi.MustNew(
        // Basic info
        openapi.WithTitle("User Management API", "2.1.0"),
        openapi.WithInfoDescription("Production-ready API for managing users and permissions"),
        openapi.WithTermsOfService("https://example.com/terms"),
        
        // Contact
        openapi.WithContact(
            "API Support",
            "https://example.com/support",
            "api-support@example.com",
        ),
        
        // License
        openapi.WithLicense("Apache 2.0", "https://www.apache.org/licenses/LICENSE-2.0.html"),
        
        // Version
        openapi.WithVersion(openapi.V31x),
        
        // Servers
        openapi.WithServer("https://api.example.com/v2", "Production"),
        openapi.WithServer("https://staging-api.example.com/v2", "Staging"),
        openapi.WithServer("http://localhost:8080/v2", "Development"),
        
        // Security
        openapi.WithBearerAuth("bearerAuth", "JWT token authentication"),
        
        // Tags
        openapi.WithTag("users", "User management operations"),
        
        // Extensions
        openapi.WithExtension("x-api-version", "2.1"),
        openapi.WithExtension("x-environment", os.Getenv("ENVIRONMENT")),
        
        // Enable validation
        openapi.WithValidation(true),
    )

    result, err := api.Generate(context.Background(),
        // Public endpoints
        openapi.GET("/health",
            openapi.WithSummary("Health check"),
            openapi.WithDescription("Check API health status"),
            openapi.WithResponse(200, map[string]string{"status": "ok"}),
        ),
        
        // User CRUD operations
        openapi.GET("/users",
            UserEndpoint,
            openapi.WithSummary("List users"),
            openapi.WithDescription("Retrieve paginated list of users"),
            openapi.WithResponse(200, []User{}),
        ),
        
        openapi.GET("/users/:id",
            UserEndpoint,
            openapi.WithSummary("Get user"),
            openapi.WithDescription("Retrieve a specific user by ID"),
            openapi.WithResponse(200, User{}),
            openapi.WithResponse(404, ErrorResponse{}),
        ),
        
        openapi.POST("/users",
            UserEndpoint,
            openapi.WithSummary("Create user"),
            openapi.WithDescription("Create a new user"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(201, User{}),
        ),
        
        openapi.PUT("/users/:id",
            UserEndpoint,
            openapi.WithSummary("Update user"),
            openapi.WithDescription("Update an existing user"),
            openapi.WithRequest(CreateUserRequest{}),
            openapi.WithResponse(200, User{}),
            openapi.WithResponse(404, ErrorResponse{}),
        ),
        
        openapi.DELETE("/users/:id",
            UserEndpoint,
            openapi.WithSummary("Delete user"),
            openapi.WithDescription("Delete a user"),
            openapi.WithResponse(204, nil),
            openapi.WithResponse(404, ErrorResponse{}),
        ),
    )
    if err != nil {
        log.Fatalf("Generation failed: %v", err)
    }

    // Handle warnings
    if len(result.Warnings) > 0 {
        fmt.Printf("Generated with %d warnings:\n", len(result.Warnings))
        for _, warn := range result.Warnings {
            fmt.Printf("  [%s] %s at %s\n", 
                warn.Code(), 
                warn.Message(),
                warn.Path(),
            )
        }
    }

    // Write specification files
    if err := os.WriteFile("openapi.json", result.JSON, 0644); err != nil {
        log.Fatal(err)
    }
    
    if err := os.WriteFile("openapi.yaml", result.YAML, 0644); err != nil {
        log.Fatal(err)
    }

    fmt.Printf("✓ Generated OpenAPI %s specification\n", api.Version())
    fmt.Printf("✓ JSON: openapi.json (%d bytes)\n", len(result.JSON))
    fmt.Printf("✓ YAML: openapi.yaml (%d bytes)\n", len(result.YAML))
}
```

## Next Steps

- Review [Basic Usage](../basic-usage/) for fundamental concepts
- Explore [Operations](../operations/) for defining endpoints
- Check [Diagnostics](../diagnostics/) for warning handling
- See [API Reference](/reference/packages/openapi/) for complete documentation
