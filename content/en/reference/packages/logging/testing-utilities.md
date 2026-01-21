---
title: "Testing Utilities"
description: "Complete reference for logging test utilities and helpers"
keywords:
  - testing utilities
  - test helpers
  - log capture
  - test logging
weight: 4
---

Complete reference for testing utilities provided by the logging package.

## Test Logger Creation

### NewTestLogger

```go
func NewTestLogger() (*Logger, *bytes.Buffer)
```

Creates a Logger for testing with an in-memory buffer. The logger is configured with JSON handler, debug level, and writes to the returned buffer.

**Returns:**
- `*Logger` - Configured test logger
- `*bytes.Buffer` - Buffer containing log output

**Example:**
```go
func TestMyFunction(t *testing.T) {
    logger, buf := logging.NewTestLogger()
    
    myFunction(logger)
    
    entries, err := logging.ParseJSONLogEntries(buf)
    require.NoError(t, err)
    assert.Len(t, entries, 1)
}
```

### ParseJSONLogEntries

```go
func ParseJSONLogEntries(buf *bytes.Buffer) ([]LogEntry, error)
```

Parses JSON log entries from buffer into LogEntry slices. Creates a copy of the buffer so the original is not consumed.

**Parameters:**
- `buf` - Buffer containing JSON log entries (one per line)

**Returns:**
- `[]LogEntry` - Parsed log entries
- `error` - Parse error, if any

**Example:**
```go
entries, err := logging.ParseJSONLogEntries(buf)
require.NoError(t, err)

for _, entry := range entries {
    fmt.Printf("%s: %s\n", entry.Level, entry.Message)
}
```

## TestHelper

High-level testing utility with convenience methods.

### NewTestHelper

```go
func NewTestHelper(t *testing.T, opts ...Option) *TestHelper
```

Creates a TestHelper with in-memory logging and additional options.

**Parameters:**
- `t` - Testing instance
- `opts` - Optional configuration options

**Returns:**
- `*TestHelper` - Test helper instance

**Example:**
```go
func TestService(t *testing.T) {
    th := logging.NewTestHelper(t)
    
    svc := NewService(th.Logger)
    svc.DoSomething()
    
    th.AssertLog(t, "INFO", "operation completed", map[string]any{
        "status": "success",
    })
}
```

**With custom configuration:**
```go
th := logging.NewTestHelper(t,
    logging.WithLevel(logging.LevelWarn),  // Only warnings and errors
)
```

### TestHelper.Logs

```go
func (th *TestHelper) Logs() ([]LogEntry, error)
```

Returns all parsed log entries.

**Returns:**
- `[]LogEntry` - All log entries
- `error` - Parse error, if any

**Example:**
```go
logs, err := th.Logs()
require.NoError(t, err)
assert.Len(t, logs, 3)
```

### TestHelper.LastLog

```go
func (th *TestHelper) LastLog() (*LogEntry, error)
```

Returns the most recent log entry.

**Returns:**
- `*LogEntry` - Most recent log entry
- `error` - Error if no logs or parse error

**Example:**
```go
last, err := th.LastLog()
require.NoError(t, err)
assert.Equal(t, "INFO", last.Level)
```

### TestHelper.ContainsLog

```go
func (th *TestHelper) ContainsLog(msg string) bool
```

Checks if any log entry contains the given message.

**Parameters:**
- `msg` - Message to search for

**Returns:**
- `bool` - True if message found

**Example:**
```go
if !th.ContainsLog("user created") {
    t.Error("expected user created log")
}
```

### TestHelper.ContainsAttr

```go
func (th *TestHelper) ContainsAttr(key string, value any) bool
```

Checks if any log entry contains the given attribute.

**Parameters:**
- `key` - Attribute key
- `value` - Attribute value

**Returns:**
- `bool` - True if attribute found

**Example:**
```go
if !th.ContainsAttr("user_id", "123") {
    t.Error("expected user_id attribute")
}
```

### TestHelper.CountLevel

```go
func (th *TestHelper) CountLevel(level string) int
```

Returns the number of log entries at the given level.

**Parameters:**
- `level` - Log level ("DEBUG", "INFO", "WARN", "ERROR")

**Returns:**
- `int` - Count of logs at that level

**Example:**
```go
errorCount := th.CountLevel("ERROR")
assert.Equal(t, 2, errorCount)
```

### TestHelper.Reset

```go
func (th *TestHelper) Reset()
```

Clears the buffer for fresh testing.

**Example:**
```go
th.Reset()  // Start fresh for next test phase
```

### TestHelper.AssertLog

```go
func (th *TestHelper) AssertLog(t *testing.T, level, msg string, attrs map[string]any)
```

Checks that a log entry exists with the given properties. Fails the test if not found.

**Parameters:**
- `t` - Testing instance
- `level` - Expected log level
- `msg` - Expected message
- `attrs` - Expected attributes

**Example:**
```go
th.AssertLog(t, "INFO", "user created", map[string]any{
    "username": "alice",
    "email":    "alice@example.com",
})
```

## LogEntry Type

```go
type LogEntry struct {
    Time    time.Time
    Level   string
    Message string
    Attrs   map[string]any
}
```

Represents a parsed log entry for testing.

**Fields:**
- `Time` - Log timestamp
- `Level` - Log level ("DEBUG", "INFO", "WARN", "ERROR")
- `Message` - Log message
- `Attrs` - All other fields as map

**Example:**
```go
entry := logs[0]
assert.Equal(t, "INFO", entry.Level)
assert.Equal(t, "test message", entry.Message)
assert.Equal(t, "value", entry.Attrs["key"])
```

## Mock Writers

### MockWriter

Records all writes for inspection.

**Type:**
```go
type MockWriter struct {
    // contains filtered or unexported fields
}
```

**Methods:**

#### Write

```go
func (mw *MockWriter) Write(p []byte) (n int, err error)
```

Implements io.Writer. Records the write.

#### WriteCount

```go
func (mw *MockWriter) WriteCount() int
```

Returns the number of write calls.

#### BytesWritten

```go
func (mw *MockWriter) BytesWritten() int
```

Returns total bytes written.

#### LastWrite

```go
func (mw *MockWriter) LastWrite() []byte
```

Returns the most recent write.

#### Reset

```go
func (mw *MockWriter) Reset()
```

Clears all recorded writes.

**Example:**
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
    
    assert.Equal(t, 3, mw.WriteCount())
    assert.Contains(t, string(mw.LastWrite()), "test 3")
    assert.Greater(t, mw.BytesWritten(), 0)
}
```

### CountingWriter

Counts bytes written without storing content.

**Type:**
```go
type CountingWriter struct {
    // contains filtered or unexported fields
}
```

**Methods:**

#### Write

```go
func (cw *CountingWriter) Write(p []byte) (n int, err error)
```

Implements io.Writer. Counts bytes.

#### Count

```go
func (cw *CountingWriter) Count() int64
```

Returns the total bytes written.

**Example:**
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
    
    bytesLogged := cw.Count()
    t.Logf("Total bytes: %d", bytesLogged)
}
```

### SlowWriter

Simulates slow I/O for testing timeouts.

**Type:**
```go
type SlowWriter struct {
    // contains filtered or unexported fields
}
```

**Constructor:**

#### NewSlowWriter

```go
func NewSlowWriter(delay time.Duration, inner io.Writer) *SlowWriter
```

Creates a writer that delays each write.

**Parameters:**
- `delay` - Delay duration for each write
- `inner` - Optional inner writer to actually write to

**Returns:**
- `*SlowWriter` - Slow writer instance

**Example:**
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
    
    assert.GreaterOrEqual(t, duration, 100*time.Millisecond)
}
```

## HandlerSpy

Implements slog.Handler and records all Handle calls.

**Type:**
```go
type HandlerSpy struct {
    // contains filtered or unexported fields
}
```

**Methods:**

#### Enabled

```go
func (hs *HandlerSpy) Enabled(_ context.Context, _ slog.Level) bool
```

Always returns true.

#### Handle

```go
func (hs *HandlerSpy) Handle(_ context.Context, r slog.Record) error
```

Records the log record.

#### WithAttrs

```go
func (hs *HandlerSpy) WithAttrs(_ []slog.Attr) slog.Handler
```

Returns the same handler (for compatibility).

#### WithGroup

```go
func (hs *HandlerSpy) WithGroup(_ string) slog.Handler
```

Returns the same handler (for compatibility).

#### Records

```go
func (hs *HandlerSpy) Records() []slog.Record
```

Returns all captured records.

#### RecordCount

```go
func (hs *HandlerSpy) RecordCount() int
```

Returns the number of captured records.

#### Reset

```go
func (hs *HandlerSpy) Reset()
```

Clears all captured records.

**Example:**
```go
func TestHandlerBehavior(t *testing.T) {
    spy := &logging.HandlerSpy{}
    logger := slog.New(spy)
    
    logger.Info("test", "key", "value")
    
    assert.Equal(t, 1, spy.RecordCount())
    
    records := spy.Records()
    assert.Equal(t, "test", records[0].Message)
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
    th.AssertLog(t, "ERROR", "operation failed", map[string]any{
        "error": "expected failure",
    })
}
```

### Table-Driven Tests

```go
func TestLogLevels(t *testing.T) {
    tests := []struct {
        name         string
        level        logging.Level
        expectLogged bool
    }{
        {"debug at info", logging.LevelInfo, false},
        {"info at info", logging.LevelInfo, true},
        {"error at warn", logging.LevelWarn, true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            th := logging.NewTestHelper(t,
                logging.WithLevel(tt.level),
            )
            
            th.Logger.Debug("test")
            
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

## Next Steps

- See [API Reference](../api-reference/) for all logger methods
- Check [Troubleshooting](../troubleshooting/) for common issues
- Review [Testing Guide](/guides/logging/testing/) for patterns

For complete testing patterns, see the [Testing Guide](/guides/logging/testing/).
