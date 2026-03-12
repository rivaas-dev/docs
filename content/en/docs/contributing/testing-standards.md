---
title: "Testing Standards"
description: "How to write tests for Rivaas code"
weight: 20
keywords:
  - testing
  - tests
  - unit tests
  - integration tests
  - benchmarks
  - standards
---

This page explains how to write tests for Rivaas. Good tests help us keep the code working correctly.

## Test File Structure

All packages must have these test files:

1. **`*_test.go`** — Unit tests (same package)
2. **`example_test.go`** — Examples for documentation (external package)
3. **`*_bench_test.go`** — Performance benchmarks (same package)
4. **`integration_test.go`** — Integration tests (external package)
5. **`testing.go`** — Test helpers (if needed)

## File Naming

| Test Type | File Name | Package |
|-----------|-----------|---------|
| Unit tests | `{package}_test.go` | `{package}` |
| Benchmarks | `{package}_bench_test.go` | `{package}` |
| Examples | `example_test.go` | `{package}_test` |
| Integration | `integration_test.go` | `{package}_test` |
| Helpers | `testing.go` | `{package}` |

## Test Naming

Use clear, descriptive names:

| Pattern | Use Case | Example |
|---------|----------|---------|
| `TestFunctionName` | Basic test | `TestParseConfig` |
| `TestFunctionName_Scenario` | Specific scenario | `TestParseConfig_EmptyInput` |
| `TestFunctionName_ErrorCase` | Error case | `TestParseConfig_InvalidJSON` |
| `TestType_MethodName` | Method test | `TestRouter_ServeHTTP` |

### Subtest Naming

For table-driven tests, use names that explain the scenario:

```go
tests := []struct {
    name string
    // ...
}{
    {name: "valid email address"},           // ✅ Good - descriptive
    {name: "empty string returns error"},    // ✅ Good - explains behavior
    {name: "test1"},                         // ❌ Bad - not descriptive
    {name: "case 1"},                        // ❌ Bad - not helpful
}
```

### Grouping with Subtests

Use nested `t.Run()` for related tests:

```go
func TestUser(t *testing.T) {
    t.Parallel()

    t.Run("Create", func(t *testing.T) {
        t.Parallel()
        t.Run("valid input succeeds", func(t *testing.T) {
            t.Parallel()
            // test code
        })
        t.Run("invalid email returns error", func(t *testing.T) {
            t.Parallel()
            // test code
        })
    })

    t.Run("Delete", func(t *testing.T) {
        t.Parallel()
        t.Run("existing user succeeds", func(t *testing.T) {
            t.Parallel()
            // test code
        })
    })
}
```

## Package Organization

### Unit Tests

- **Package:** Same as source (`package router`)
- **Access:** Can test public and internal APIs
- **Use for:** Testing individual functions, internal details, edge cases
- **Framework:** Standard `testing` with `testify/assert` or `testify/require`

### Integration Tests

- **Package:** External (`package router_test`)
- **Access:** Only public APIs (black-box testing)
- **Use for:** Testing full request/response cycles, component interactions
- **Framework:** 
  - Standard `testing` for simple tests
  - **Ginkgo/Gomega** for complex scenarios

### Example Tests

- **Package:** External (`package router_test`)
- **Access:** Only public APIs
- **Use for:** Showing how to use public APIs in documentation

## Test Data Management

### The testdata Directory

Go has special handling for `testdata/` directories:

- Ignored by `go build`
- Used for test fixtures and sample data
- Accessible via relative path from tests

```
package/
├── handler.go
├── handler_test.go
└── testdata/
    ├── fixtures/
    │   ├── valid_request.json
    │   └── invalid_request.json
    └── golden/
        ├── expected_output.json
        └── expected_error.txt
```

### Loading Test Data

```go
func TestHandler(t *testing.T) {
    t.Parallel()

    // Load test fixture
    input, err := os.ReadFile("testdata/fixtures/valid_request.json")
    require.NoError(t, err)

    // Use in test
    result, err := ProcessRequest(input)
    require.NoError(t, err)

    // Compare with golden file
    expected, err := os.ReadFile("testdata/golden/expected_output.json")
    require.NoError(t, err)
    assert.JSONEq(t, string(expected), string(result))
}
```

### Golden File Testing

Golden files store expected output. Use `-update` flag to regenerate:

```go
var updateGolden = flag.Bool("update", false, "update golden files")

func TestOutput_Golden(t *testing.T) {
    result := GenerateOutput()
    goldenPath := "testdata/golden/output.txt"

    if *updateGolden {
        err := os.WriteFile(goldenPath, []byte(result), 0644)
        require.NoError(t, err)
        return
    }

    expected, err := os.ReadFile(goldenPath)
    require.NoError(t, err)
    assert.Equal(t, string(expected), result)
}
```

Update golden files:

```bash
go test -update ./...
```

## Assertions

**Important:** Always use assertion libraries. Don't use manual `if` statements with `t.Errorf()`.

### testify/assert vs testify/require

- **`assert`:** Continues test after failure (checks multiple things)
- **`require`:** Stops test after failure (when later checks depend on it)

```go
// Use require when later code needs the value
result, err := FunctionThatShouldSucceed()
require.NoError(t, err)  // Must succeed to continue
assert.Equal(t, expected, result)

// Use assert for independent checks
assert.NoError(t, err)
assert.Equal(t, expected, result)
assert.Contains(t, message, "success")  // All run even if first fails
```

## Error Checking

Always use testify error functions, not manual error checks.

### Available Functions

- **`assert.NoError(t, err)`** — Verify no error occurred
- **`assert.Error(t, err)`** — Verify an error occurred
- **`assert.ErrorIs(t, err, target)`** — Verify error wraps specific error
- **`assert.ErrorAs(t, err, target)`** — Verify error is specific type
- **`assert.ErrorContains(t, err, substring)`** — Verify error message contains text

### When to Use Each

**NoError / require.NoError:**

```go
result, err := FunctionThatShouldSucceed()
require.NoError(t, err)  // Use require if result is needed
assert.Equal(t, expected, result)
```

**Error / assert.Error:**

```go
_, err := FunctionThatShouldFail()
assert.Error(t, err)  // Any error is fine
```

**ErrorIs / assert.ErrorIs:**

```go
var ErrNotFound = errors.New("not found")

_, err := FunctionThatReturnsWrappedError()
assert.ErrorIs(t, err, ErrNotFound)  // Check for specific error
```

**ErrorAs / require.ErrorAs:**

```go
type ValidationError struct {
    Field string
}

_, err := FunctionThatReturnsTypedError()
var validationErr *ValidationError
require.ErrorAs(t, err, &validationErr)  // Use require if you need validationErr
assert.Equal(t, "email", validationErr.Field)
```

**ErrorContains / assert.ErrorContains:**

```go
_, err := FunctionThatReturnsDescriptiveError()
assert.ErrorContains(t, err, "invalid input")
```

### When to Use require vs assert for Errors

**Use require when:**

1. Setup must succeed:

```go
tmpfile, err := os.CreateTemp("", "test-*.txt")
require.NoError(t, err)  // Must succeed to continue
defer os.Remove(tmpfile.Name())
```

2. Need non-nil value:

```go
db, err := sql.Open("postgres", dsn)
require.NoError(t, err)  // Must succeed
require.NotNil(t, db)    // Must not be nil

rows, err := db.Query("SELECT ...")  // Safe to use db
```

3. Later assertions depend on it:

```go
err := c.Format(200, data)
require.NoError(t, err)  // Must succeed for rest of test

// These assume Format succeeded
assert.Contains(t, w.Header().Get("Content-Type"), "application/xml")
assert.Contains(t, w.Body.String(), "<?xml")
```

**Use assert when:**

1. Independent validations:

```go
assert.NoError(t, err)
assert.Equal(t, expected, result)
assert.Contains(t, message, "success")  // All checked even if first fails
```

2. Non-critical checks:

```go
err := optionalOperation()
assert.NoError(t, err)  // Nice to have, but test can continue
assert.Equal(t, http.StatusOK, w.Code)
```

## Table-Driven Tests

All tests with multiple cases should use table-driven pattern:

```go
func TestFunctionName(t *testing.T) {
    t.Parallel()

    tests := []struct {
        name    string
        input   any
        want    any
        wantErr bool
    }{
        {
            name:    "valid input",
            input:   "test",
            want:    "result",
            wantErr: false,
        },
        {
            name:    "invalid input",
            input:   "",
            want:    nil,
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            got, err := FunctionName(tt.input)
            if tt.wantErr {
                assert.Error(t, err)
                return
            }
            assert.NoError(t, err)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

## Example Tests

All public APIs must have example tests in `example_test.go`:

```go
package package_test

import (
    "fmt"
    "rivaas.dev/package"
)

// ExampleFunctionName demonstrates basic usage.
func ExampleFunctionName() {
    result := package.FunctionName("input")
    fmt.Println(result)
    // Output: expected output
}

// ExampleFunctionName_withOptions demonstrates usage with options.
func ExampleFunctionName_withOptions() {
    result := package.FunctionName("input",
        package.WithOption("value"),
    )
    fmt.Println(result)
    // Output: expected output
}
```

### Example Guidelines

- Package must be `{package}_test`
- Function names start with `Example`
- Include `// Output:` comments for deterministic examples
- Use `log.Fatal(err)` for error handling (acceptable in examples)

## Benchmarks

Critical paths must have benchmarks in `*_bench_test.go`:

```go
func BenchmarkFunctionName(b *testing.B) {
    setup := prepareTestData()
    b.ResetTimer()
    b.ReportAllocs()

    // Preferred: Go 1.23+ syntax
    for b.Loop() {
        FunctionName(setup)
    }
}

func BenchmarkFunctionName_Parallel(b *testing.B) {
    setup := prepareTestData()
    b.ResetTimer()
    b.ReportAllocs()

    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            FunctionName(setup)
        }
    })
}
```

### Benchmark Guidelines

- Use `b.ResetTimer()` after setup
- Use `b.ReportAllocs()` to track memory
- **Prefer `b.Loop()`** for Go 1.23+
- Test both sequential and parallel execution
- Use `b.Context()` instead of `context.Background()` (Go 1.24+)
- Use `b.Fatal(err)` for setup failures (acceptable in benchmarks)

## Integration Tests

Integration tests use the `integration` build tag:

```go
//go:build integration

package package_test

import (
    "net/http"
    "net/http/httptest"
    "testing"

    "rivaas.dev/package"
)

func TestIntegration(t *testing.T) {
    r := package.MustNew()
    // Integration test code
}
```

### Build Tags for Test Separation

| Test Type | Build Tag | Run Command |
|-----------|-----------|-------------|
| Unit tests | `//go:build !integration` | `go test ./...` |
| Integration tests | `//go:build integration` | `go test -tags=integration ./...` |

**Why build tags?**

- Tests excluded at compile time, not skipped at runtime
- Cleaner coverage reports
- Faster unit test runs
- Easy to run different suites in parallel

### Ginkgo Integration Tests

For complex scenarios, use Ginkgo. **Important:** Only one `RunSpecs` call per package.

**Suite file (one per package):**

```go
// {package}_integration_suite_test.go

//go:build integration

package package_test

import (
    "testing"

    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
)

func TestPackageIntegration(t *testing.T) {
    RegisterFailHandler(Fail)
    RunSpecs(t, "Package Integration Suite")
}
```

**Test files (multiple allowed):**

```go
// integration_test.go

//go:build integration

package package_test

import (
    "net/http"
    "net/http/httptest"

    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"

    "rivaas.dev/package"
)

var _ = Describe("Feature Integration", func() {
    var r *package.Router

    BeforeEach(func() {
        r = package.MustNew()
    })

    Describe("Scenario A", func() {
        Context("with condition X", func() {
            It("should behave correctly", func() {
                req := httptest.NewRequest("GET", "/path", nil)
                w := httptest.NewRecorder()
                r.ServeHTTP(w, req)

                Expect(w.Code).To(Equal(http.StatusOK))
            })
        })
    })
})
```

### Using Labels for Filtering

Use labels to organize tests:

```go
var _ = Describe("Router Stress Tests", Label("stress", "slow"), func() {
    It("should handle high concurrent load", Label("stress"), func() {
        // Stress test
    })
})
```

Run with labels:

```bash
# Run only stress tests
ginkgo -label-filter=stress ./package

# Run everything except stress tests
ginkgo -label-filter='!stress' ./package

# Run tests with multiple labels (AND)
ginkgo -label-filter='integration && versioning' ./package
```

## Test Helpers

Common utilities go in `testing.go`:

```go
package package

import (
    "testing"
    
    "github.com/stretchr/testify/assert"
)

// testHelper creates a test instance with default configuration.
func testHelper(t *testing.T) *Config {
    t.Helper()
    return MustNew(WithTestDefaults())
}

// assertError checks if error matches expected.
func assertError(t *testing.T, err error, wantErr bool, msg string) {
    t.Helper()
    if wantErr {
        assert.Error(t, err, msg)
    } else {
        assert.NoError(t, err, msg)
    }
}
```

**Always use `t.Helper()`** in helper functions.

## HTTP Testing Patterns

### Testing Handlers

```go
func TestHandler_GetUser(t *testing.T) {
    t.Parallel()

    handler := NewUserHandler(mockRepo)

    req := httptest.NewRequest(http.MethodGet, "/users/123", nil)
    req.Header.Set("Content-Type", "application/json")

    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)

    assert.Equal(t, http.StatusOK, w.Code)
    assert.Contains(t, w.Header().Get("Content-Type"), "application/json")

    var response User
    err := json.NewDecoder(w.Body).Decode(&response)
    require.NoError(t, err)
    assert.Equal(t, "123", response.ID)
}
```

### Testing with Request Body

```go
func TestHandler_CreateUser(t *testing.T) {
    t.Parallel()

    body := strings.NewReader(`{"name": "Test User", "email": "test@example.com"}`)
    req := httptest.NewRequest(http.MethodPost, "/users", body)
    req.Header.Set("Content-Type", "application/json")

    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)

    assert.Equal(t, http.StatusCreated, w.Code)
}
```

### Testing Middleware

```go
func TestAuthMiddleware(t *testing.T) {
    t.Parallel()

    tests := []struct {
        name           string
        authHeader     string
        wantStatusCode int
    }{
        {
            name:           "valid token",
            authHeader:     "Bearer valid-token",
            wantStatusCode: http.StatusOK,
        },
        {
            name:           "missing header",
            authHeader:     "",
            wantStatusCode: http.StatusUnauthorized,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            nextHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
                w.WriteHeader(http.StatusOK)
            })

            handler := AuthMiddleware(nextHandler)

            req := httptest.NewRequest(http.MethodGet, "/protected", nil)
            if tt.authHeader != "" {
                req.Header.Set("Authorization", tt.authHeader)
            }

            w := httptest.NewRecorder()
            handler.ServeHTTP(w, req)

            assert.Equal(t, tt.wantStatusCode, w.Code)
        })
    }
}
```

## Context and Timeout Patterns

### Testing with Context

```go
func TestService_WithTimeout(t *testing.T) {
    t.Parallel()

    ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
    t.Cleanup(cancel)

    result, err := service.SlowOperation(ctx)

    require.NoError(t, err)
    assert.NotNil(t, result)
}
```

### Using Test Context (Go 1.24+)

In Go 1.24+, use `t.Context()` instead of `context.Background()`:

```go
func TestWithContext(t *testing.T) {
    t.Parallel()

    // ✅ Preferred: Use t.Context()
    ctx := t.Context()
    
    // ❌ Avoid: context.Background()
    // ctx := context.Background()

    result, err := service.Operation(ctx)
    require.NoError(t, err)
    assert.NotNil(t, result)
}
```

**Benefits:** Automatically cancelled when test ends.

## Mocking

### Interface-Based Mocking (Preferred)

```go
// Define interface
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// Test implementation (fake)
type fakeUserRepository struct {
    users map[string]*User
    err   error
}

func (f *fakeUserRepository) FindByID(ctx context.Context, id string) (*User, error) {
    if f.err != nil {
        return nil, f.err
    }
    return f.users[id], nil
}

// Test using the fake
func TestUserService_GetUser(t *testing.T) {
    t.Parallel()

    repo := &fakeUserRepository{
        users: map[string]*User{
            "123": {ID: "123", Name: "Test User"},
        },
    }
    service := NewUserService(repo)

    user, err := service.GetUser(context.Background(), "123")
    require.NoError(t, err)
    assert.Equal(t, "Test User", user.Name)
}
```

### HTTP Client Mocking

```go
func TestAPIClient_FetchData(t *testing.T) {
    t.Parallel()

    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        assert.Equal(t, "/api/data", r.URL.Path)
        assert.Equal(t, "Bearer token123", r.Header.Get("Authorization"))

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        _, _ = w.Write([]byte(`{"id": "123", "name": "test"}`))
    }))
    t.Cleanup(server.Close)

    client := NewAPIClient(server.URL, "token123")
    data, err := client.FetchData(context.Background())

    require.NoError(t, err)
    assert.Equal(t, "123", data.ID)
}
```

## Test Coverage

### Requirements

| Package Type | Minimum | Target |
|--------------|---------|--------|
| Core packages | 80% | 90% |
| Utility packages | 75% | 85% |
| Integration packages | 70% | 80% |

### Measuring Coverage

```bash
# Package coverage
go test -cover ./package

# Detailed report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# Coverage by function
go tool cover -func=coverage.out
```

## Best Practices

1. **Parallel Execution:** Use `t.Parallel()` for all tests (except `testing.AllocsPerRun`)

2. **Assertions:** Always use `testify/assert` or `testify/require`

3. **Error Messages:** Include descriptive messages

4. **Test Isolation:** Each test should be independent

5. **Cleanup:** Use `t.Cleanup()` instead of `defer`:

```go
func TestWithResource(t *testing.T) {
    t.Parallel()

    resource := createResource()
    t.Cleanup(func() {
        resource.Close()
    })

    // Use resource...
}
```

6. **Descriptive Names:** Use clear test and subtest names

7. **Documentation:** Document complex test scenarios

8. **Race Detection:** Always run with `-race` in CI

9. **Deterministic Tests:** Avoid depending on:
   - Current time (use clock injection)
   - Random values (use fixed seeds)
   - Network availability (use mocks)
   - Filesystem state (use temp directories)

## Running Tests

```bash
# Run unit tests (excludes integration)
go test ./...

# Run unit tests with verbose output
go test -v ./...

# Run unit tests with race detection (REQUIRED in CI)
go test -race ./...

# Run integration tests with race detection
go test -tags=integration -race ./...

# Run unit tests with coverage
go test -cover ./...

# Run benchmarks
go test -bench=. -benchmem ./...

# Run specific test by name
go test -run TestFunctionName ./...

# Run tests with timeout
go test -timeout 5m ./...
```

### CI Commands

```bash
# Unit tests with race and coverage (CI)
go test -race -coverprofile=coverage.out -timeout 10m ./...

# Integration tests with race and coverage (CI)
go test -tags=integration -race -coverprofile=coverage-integration.out -timeout 10m ./...
```

## Summary

Good tests:

- Use clear, descriptive names
- Use table-driven patterns for multiple cases
- Always use assertion libraries
- Run in parallel when possible
- Include examples for public APIs
- Test both success and error cases
- Use proper build tags for integration tests
- Have good coverage (80%+)

Remember: Tests are documentation too. Write them clearly!
