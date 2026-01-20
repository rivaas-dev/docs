---
title: "Testing"
description: "Test utilities and patterns for logging in unit and integration tests"
weight: 10
---

This guide covers testing with the logging package. It includes test utilities, assertions, and best practices.

## Overview

The logging package provides comprehensive testing utilities:

- **TestHelper** - High-level test utilities with assertions.
- **NewTestLogger** - Simple logger with in-memory buffer.
- **MockWriter** - Record and inspect write operations.
- **CountingWriter** - Track log volume without storing content.
- **SlowWriter** - Simulate slow I/O for timeout testing.
- **HandlerSpy** - Spy on slog.Handler operations.

## Quick Start

### Simple Test Logger

Create a logger with in-memory output:

```go
func TestMyFunction(t *testing.T) {
    logger, buf := logging.NewTestLogger()
    
    myFunction(logger)
    
    // Parse and inspect logs
    entries, err := logging.ParseJSONLogEntries(buf)
    require.NoError(t, err)
    
    require.Len(t, entries, 1)
    assert.Equal(t, "INFO", entries[0].Level)
    assert.Equal(t, "operation completed", entries[0].Message)
}
```

## TestHelper

High-level testing utility with convenience methods.

### Basic Usage

```go
func TestUserService(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    svc := NewUserService(th.Logger)
    svc.CreateUser("alice")
    
    // Check logs were written
    th.AssertLog(t, "INFO", "user created", map[string]any{
        "username": "alice",
    })
}
```

### TestHelper Methods

**ContainsLog** - Check if message exists:
```go
if !th.ContainsLog("user created") {
    t.Error("expected user created log")
}
```

**ContainsAttr** - Check if attribute exists:
```go
if !th.ContainsAttr("user_id", "123") {
    t.Error("expected user_id attribute")
}
```

**CountLevel** - Count logs by level:
```go
errorCount := th.CountLevel("ERROR")
assert.Equal(t, 2, errorCount)
```

**LastLog** - Get most recent log:
```go
last, err := th.LastLog()
require.NoError(t, err)
assert.Equal(t, "INFO", last.Level)
```

**Logs** - Get all logs:
```go
logs, err := th.Logs()
require.NoError(t, err)
for _, log := range logs {
    fmt.Printf("%s: %s\n", log.Level, log.Message)
}
```

**Reset** - Clear buffer:
```go
th.Reset()  // Start fresh for next test phase
```

### Custom Configuration

Pass options to customize the test logger:

```go
th := logging.NewTestHelper(t,
    logging.WithLevel(logging.LevelWarn),  // Only warnings and errors
    logging.WithServiceName("test-service"),
)
```

## Parsing Log Entries

Parse JSON logs for inspection.

### ParseJSONLogEntries

```go
func TestLogging(t *testing.T) {
    logger, buf := logging.NewTestLogger()
    
    logger.Info("test message", "key", "value")
    logger.Error("test error", "error", "something failed")
    
    entries, err := logging.ParseJSONLogEntries(buf)
    require.NoError(t, err)
    require.Len(t, entries, 2)
    
    // First entry
    assert.Equal(t, "INFO", entries[0].Level)
    assert.Equal(t, "test message", entries[0].Message)
    assert.Equal(t, "value", entries[0].Attrs["key"])
    
    // Second entry
    assert.Equal(t, "ERROR", entries[1].Level)
    assert.Equal(t, "something failed", entries[1].Attrs["error"])
}
```

### LogEntry Structure

```go
type LogEntry struct {
    Time    time.Time       // Log timestamp
    Level   string          // "DEBUG", "INFO", "WARN", "ERROR"
    Message string          // Log message
    Attrs   map[string]any  // All other fields
}
```

## Mock Writers

Test utilities for inspecting write behavior.

### MockWriter

Records all writes for inspection:

```go
func TestWriteBehavior(t *testing.T) {
    mw := &logging.MockWriter{}
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithOutput(mw),
    )
    
    logger.Info("test 1")
    logger.Info("test 2")
    logger.Info("test 3")
    
    // Verify write count
    assert.Equal(t, 3, mw.WriteCount())
    
    // Inspect last write
    lastWrite := mw.LastWrite()
    assert.Contains(t, string(lastWrite), "test 3")
    
    // Check total bytes
    assert.Greater(t, mw.BytesWritten(), 0)
    
    // Reset for next test
    mw.Reset()
}
```

### CountingWriter

Count bytes without storing content:

```go
func TestLogVolume(t *testing.T) {
    cw := &logging.CountingWriter{}
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithOutput(cw),
    )
    
    for i := 0; i < 1000; i++ {
        logger.Info("test message", "index", i)
    }
    
    // Verify volume
    bytesLogged := cw.Count()
    t.Logf("Total bytes logged: %d", bytesLogged)
    
    // Useful for volume tests without memory overhead
}
```

### SlowWriter

Simulate slow I/O:

```go
func TestSlowLogging(t *testing.T) {
    buf := &bytes.Buffer{}
    sw := logging.NewSlowWriter(100*time.Millisecond, buf)
    
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithOutput(sw),
    )
    
    start := time.Now()
    logger.Info("test")
    duration := time.Since(start)
    
    // Verify delay
    assert.GreaterOrEqual(t, duration, 100*time.Millisecond)
}
```

## Testing Patterns

### Testing Error Logging

```go
func TestErrorHandling(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    svc := NewService(th.Logger)
    err := svc.DoSomethingThatFails()
    
    require.Error(t, err)
    
    // Verify error was logged
    th.AssertLog(t, "ERROR", "operation failed", map[string]any{
        "error": "expected failure",
    })
}
```

### Testing Log Levels

```go
func TestLogLevels(t *testing.T) {
    th := logging.NewTestHelper(t,
        logging.WithLevel(logging.LevelWarn),
    )
    
    th.Logger.Debug("debug message")  // Won't appear
    th.Logger.Info("info message")    // Won't appear
    th.Logger.Warn("warn message")    // Will appear
    th.Logger.Error("error message")  // Will appear
    
    logs, _ := th.Logs()
    assert.Len(t, logs, 2)
    assert.Equal(t, "WARN", logs[0].Level)
    assert.Equal(t, "ERROR", logs[1].Level)
}
```

### Testing Structured Fields

```go
func TestStructuredLogging(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    th.Logger.Info("user action",
        "user_id", "123",
        "action", "login",
        "timestamp", time.Now().Unix(),
    )
    
    // Verify specific attributes
    assert.True(t, th.ContainsAttr("user_id", "123"))
    assert.True(t, th.ContainsAttr("action", "login"))
    
    // Or use AssertLog for multiple attributes
    th.AssertLog(t, "INFO", "user action", map[string]any{
        "user_id": "123",
        "action":  "login",
    })
}
```

### Testing Sampling

```go
func TestSampling(t *testing.T) {
    th := logging.NewTestHelper(t,
        logging.WithSampling(logging.SamplingConfig{
            Initial:    10,
            Thereafter: 100,
            Tick:       time.Minute,
        }),
    )
    
    // Log many entries
    for i := 0; i < 1000; i++ {
        th.Logger.Info("test", "index", i)
    }
    
    logs, _ := th.Logs()
    
    // Should have ~20 logs (10 initial + ~10 sampled)
    assert.Less(t, len(logs), 50)
    assert.Greater(t, len(logs), 10)
}
```

### Testing Context Logging

```go
func TestContextLogger(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    // Create context with trace info (mocked)
    ctx := context.Background()
    // Add trace to context...
    
    cl := logging.NewContextLogger(ctx, th.Logger)
    cl.Info("traced message")
    
    // Verify trace IDs in logs
    logs, _ := th.Logs()
    require.Len(t, logs, 1)
    
    // Check for trace_id if tracing was active
    if traceID := cl.TraceID(); traceID != "" {
        assert.Equal(t, traceID, logs[0].Attrs["trace_id"])
    }
}
```

## Table-Driven Tests

Use table-driven tests for comprehensive coverage:

```go
func TestLogLevels(t *testing.T) {
    tests := []struct {
        name          string
        level         logging.Level
        logFunc       func(*logging.Logger)
        expectLogged  bool
    }{
        {
            name:  "debug at info level",
            level: logging.LevelInfo,
            logFunc: func(l *logging.Logger) {
                l.Debug("debug message")
            },
            expectLogged: false,
        },
        {
            name:  "info at info level",
            level: logging.LevelInfo,
            logFunc: func(l *logging.Logger) {
                l.Info("info message")
            },
            expectLogged: true,
        },
        {
            name:  "error at warn level",
            level: logging.LevelWarn,
            logFunc: func(l *logging.Logger) {
                l.Error("error message")
            },
            expectLogged: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            th := logging.NewTestHelper(t,
                logging.WithLevel(tt.level),
            )
            
            tt.logFunc(th.Logger)
            
            logs, _ := th.Logs()
            if tt.expectLogged {
                assert.Len(t, logs, 1)
            } else {
                assert.Len(t, logs, 0)
            }
        })
    }
}
```

## Integration Testing

Test logger integration with other components.

### With HTTP Handlers

```go
func TestHTTPHandler(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    handler := NewHandler(th.Logger)
    
    req := httptest.NewRequest("GET", "/api/users", nil)
    rec := httptest.NewRecorder()
    
    handler.ServeHTTP(rec, req)
    
    // Verify logging
    th.AssertLog(t, "INFO", "request processed", map[string]any{
        "method": "GET",
        "path":   "/api/users",
    })
}
```

### With Router

```go
func TestRouterLogging(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    r := router.MustNew()
    r.SetLogger(th.Logger)
    
    r.GET("/test", func(c *router.Context) {
        c.Logger().Info("handler called")
        c.JSON(200, gin.H{"status": "ok"})
    })
    
    // Make request
    req := httptest.NewRequest("GET", "/test", nil)
    rec := httptest.NewRecorder()
    r.ServeHTTP(rec, req)
    
    // Verify handler logged
    assert.True(t, th.ContainsLog("handler called"))
}
```

## Best Practices

### Reset Between Tests

```go
func TestMultiplePhases(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    // Phase 1
    th.Logger.Info("phase 1")
    assert.True(t, th.ContainsLog("phase 1"))
    
    // Reset for phase 2
    th.Reset()
    
    // Phase 2
    th.Logger.Info("phase 2")
    logs, _ := th.Logs()
    assert.Len(t, logs, 1)  // Only phase 2 log
}
```

### Use Subtests

```go
func TestLogging(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    t.Run("info logging", func(t *testing.T) {
        th.Logger.Info("info message")
        assert.True(t, th.ContainsLog("info message"))
        th.Reset()
    })
    
    t.Run("error logging", func(t *testing.T) {
        th.Logger.Error("error message")
        assert.Equal(t, 1, th.CountLevel("ERROR"))
        th.Reset()
    })
}
```

### Test Isolation

Each test should have its own logger:

```go
func TestA(t *testing.T) {
    th := logging.NewTestHelper(t)  // Independent logger
    // Test A logic...
}

func TestB(t *testing.T) {
    th := logging.NewTestHelper(t)  // Independent logger
    // Test B logic...
}
```

## Running Tests

```bash
# Run all tests
go test ./...

# Run with verbose output
go test -v ./...

# Run specific test
go test -run TestMyFunction

# With coverage
go test -cover ./...

# With race detector
go test -race ./...
```

## Next Steps

- Review [Best Practices](../best-practices/) for production patterns
- See [Examples](../examples/) for real-world usage
- Explore [Testing Utilities Reference](/reference/packages/logging/testing-utilities/) for complete API

For complete API details, see the [API Reference](/reference/packages/logging/api-reference/).
