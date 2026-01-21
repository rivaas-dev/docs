---
title: "Dynamic Log Levels"
description: "Change log levels at runtime without restarting your application"
weight: 8
keywords:
  - dynamic log levels
  - runtime configuration
  - log level control
---

This guide covers dynamic log level changes. You can adjust logging verbosity at runtime for troubleshooting and performance tuning.

## Overview

Dynamic log levels enable changing the minimum log level without restarting your application.

**Why dynamic log levels:**
- Enable debug logging temporarily for troubleshooting.
- Reduce log volume during traffic spikes.
- Runtime configuration via HTTP endpoint or signal handler.
- Quick response to production issues without deployment.

**Limitations:**
- Not supported with custom loggers.
- Brief window where old and new levels may race during transition.

## Basic Usage

Change log level with `SetLevel`:

```go
logger := logging.MustNew(logging.WithJSONHandler())

// Initial level is Info (default)
logger.Info("this appears")
logger.Debug("this doesn't appear")

// Enable debug logging
if err := logger.SetLevel(logging.LevelDebug); err != nil {
    log.Printf("failed to change level: %v", err)
}

// Now debug logs appear
logger.Debug("this now appears")
```

## Available Log Levels

Four log levels from least to most restrictive:

```go
logging.LevelDebug   // Most verbose: Debug, Info, Warn, Error
logging.LevelInfo    // Info, Warn, Error
logging.LevelWarn    // Warn, Error
logging.LevelError   // Error only
```

### Setting Levels

```go
// Enable debug logging
logger.SetLevel(logging.LevelDebug)

// Reduce to warnings only
logger.SetLevel(logging.LevelWarn)

// Errors only
logger.SetLevel(logging.LevelError)

// Back to info
logger.SetLevel(logging.LevelInfo)
```

## Checking Current Level

Get the current log level:

```go
currentLevel := logger.Level()

switch currentLevel {
case logging.LevelDebug:
    fmt.Println("Debug mode enabled")
case logging.LevelInfo:
    fmt.Println("Info mode")
case logging.LevelWarn:
    fmt.Println("Warnings only")
case logging.LevelError:
    fmt.Println("Errors only")
}
```

## HTTP Endpoint for Level Changes

Expose an HTTP endpoint to change log levels:

```go
package main

import (
    "fmt"
    "net/http"
    "rivaas.dev/logging"
)

func main() {
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithLevel(logging.LevelInfo),
    )

    // Admin endpoint to change log level
    http.HandleFunc("/admin/loglevel", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
            return
        }
        
        levelStr := r.URL.Query().Get("level")
        var level logging.Level
        
        switch levelStr {
        case "debug":
            level = logging.LevelDebug
        case "info":
            level = logging.LevelInfo
        case "warn":
            level = logging.LevelWarn
        case "error":
            level = logging.LevelError
        default:
            http.Error(w, "Invalid level. Use: debug, info, warn, error", 
                http.StatusBadRequest)
            return
        }
        
        if err := logger.SetLevel(level); err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, "Log level changed to %s\n", levelStr)
    })

    http.ListenAndServe(":8080", nil)
}
```

**Usage:**
```bash
# Enable debug logging
curl -X POST "http://localhost:8080/admin/loglevel?level=debug"

# Reduce to errors only
curl -X POST "http://localhost:8080/admin/loglevel?level=error"

# Back to info
curl -X POST "http://localhost:8080/admin/loglevel?level=info"
```

## Signal Handler for Level Changes

Use Unix signals to change log levels:

```go
package main

import (
    "os"
    "os/signal"
    "syscall"
    "rivaas.dev/logging"
)

func main() {
    logger := logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithLevel(logging.LevelInfo),
    )

    // Setup signal handlers
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGUSR1, syscall.SIGUSR2)

    go func() {
        for sig := range sigChan {
            switch sig {
            case syscall.SIGUSR1:
                // SIGUSR1: Enable debug logging
                logger.SetLevel(logging.LevelDebug)
                logger.Info("debug logging enabled via SIGUSR1")
                
            case syscall.SIGUSR2:
                // SIGUSR2: Back to info logging
                logger.SetLevel(logging.LevelInfo)
                logger.Info("info logging restored via SIGUSR2")
            }
        }
    }()

    // Application logic...
    select {}
}
```

**Usage:**
```bash
# Get process ID
PID=$(pgrep myapp)

# Enable debug logging
kill -USR1 $PID

# Restore info logging
kill -USR2 $PID
```

## Temporary Debug Sessions

Enable debug logging temporarily:

```go
func enableDebugTemporarily(logger *logging.Logger, duration time.Duration) {
    oldLevel := logger.Level()
    
    logger.SetLevel(logging.LevelDebug)
    logger.Info("debug logging enabled temporarily", "duration", duration)
    
    time.AfterFunc(duration, func() {
        logger.SetLevel(oldLevel)
        logger.Info("debug logging disabled, restored to", "level", oldLevel)
    })
}

// Usage
enableDebugTemporarily(logger, 5*time.Minute)
```

## With Configuration Management

Integrate with configuration reloading:

```go
type Config struct {
    LogLevel string `config:"log_level"`
}

func (c *Config) Validate() error {
    validLevels := map[string]bool{
        "debug": true, "info": true, "warn": true, "error": true,
    }
    if !validLevels[c.LogLevel] {
        return fmt.Errorf("invalid log level: %s", c.LogLevel)
    }
    return nil
}

func applyConfig(logger *logging.Logger, cfg *Config) error {
    var level logging.Level
    switch cfg.LogLevel {
    case "debug":
        level = logging.LevelDebug
    case "info":
        level = logging.LevelInfo
    case "warn":
        level = logging.LevelWarn
    case "error":
        level = logging.LevelError
    }
    
    return logger.SetLevel(level)
}
```

## Error Handling

### Custom Logger Limitation

Dynamic level changes don't work with custom loggers:

```go
customLogger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
logger := logging.MustNew(
    logging.WithCustomLogger(customLogger),
)

// This fails
err := logger.SetLevel(logging.LevelDebug)
if errors.Is(err, logging.ErrCannotChangeLevel) {
    fmt.Println("Cannot change level on custom logger")
}
```

**Workaround:** Control level in your custom logger directly:

```go
var levelVar slog.LevelVar
levelVar.Set(slog.LevelInfo)

customLogger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: &levelVar,
}))

// Change level directly
levelVar.Set(slog.LevelDebug)
```

### Validation

Validate level before setting:

```go
func setLevelSafe(logger *logging.Logger, levelStr string) error {
    levelMap := map[string]logging.Level{
        "debug": logging.LevelDebug,
        "info":  logging.LevelInfo,
        "warn":  logging.LevelWarn,
        "error": logging.LevelError,
    }
    
    level, ok := levelMap[levelStr]
    if !ok {
        return fmt.Errorf("invalid level: %s", levelStr)
    }
    
    return logger.SetLevel(level)
}
```

## Use Cases

### Troubleshooting Production

Enable debug logging temporarily to diagnose an issue:

```bash
# Enable debug logs
curl -X POST "http://localhost:8080/admin/loglevel?level=debug"

# Reproduce issue and capture logs

# Restore normal level
curl -X POST "http://localhost:8080/admin/loglevel?level=info"
```

### Traffic Spike Response

Reduce logging during high traffic:

```go
func monitorTraffic(logger *logging.Logger) {
    ticker := time.NewTicker(time.Minute)
    for range ticker.C {
        rps := getCurrentRPS()
        
        if rps > 10000 {
            // High traffic - reduce logging
            logger.SetLevel(logging.LevelWarn)
            logger.Warn("high traffic detected, reducing log level", "rps", rps)
        } else if rps < 5000 {
            // Normal traffic - restore info logging
            logger.SetLevel(logging.LevelInfo)
        }
    }
}
```

### Gradual Rollout

Gradually enable debug logging across a fleet:

```go
func gradualDebugRollout(logger *logging.Logger, percentage int) {
    // Only enable debug on N% of instances
    if rand.Intn(100) < percentage {
        logger.SetLevel(logging.LevelDebug)
        logger.Info("debug logging enabled in rollout", "percentage", percentage)
    }
}
```

### Environment-Based Levels

Set initial level based on environment, allow runtime changes:

```go
func initLogger() *logging.Logger {
    initialLevel := logging.LevelInfo
    
    switch os.Getenv("ENV") {
    case "development":
        initialLevel = logging.LevelDebug
    case "staging":
        initialLevel = logging.LevelInfo
    case "production":
        initialLevel = logging.LevelWarn
    }
    
    return logging.MustNew(
        logging.WithJSONHandler(),
        logging.WithLevel(initialLevel),
    )
}
```

## Best Practices

### Secure Admin Endpoints

Protect level-changing endpoints:

```go
func logLevelHandler(logger *logging.Logger) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        // Authenticate admin
        token := r.Header.Get("X-Admin-Token")
        if !isValidAdminToken(token) {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        
        // Rate limit
        if !rateLimiter.Allow() {
            http.Error(w, "Too many requests", http.StatusTooManyRequests)
            return
        }
        
        // Change level logic...
    }
}
```

### Log Level Changes

Always log when level changes:

```go
oldLevel := logger.Level()
logger.SetLevel(newLevel)
logger.Info("log level changed",
    "old_level", oldLevel.String(),
    "new_level", newLevel.String(),
    "reason", reason,
)
```

### Automatic Restoration

Reset to safe level after debugging:

```go
func debugWithTimeout(logger *logging.Logger, duration time.Duration) func() {
    oldLevel := logger.Level()
    logger.SetLevel(logging.LevelDebug)
    
    timer := time.AfterFunc(duration, func() {
        logger.SetLevel(oldLevel)
        logger.Info("debug session ended, level restored")
    })
    
    // Return cancellation function
    return func() {
        timer.Stop()
        logger.SetLevel(oldLevel)
    }
}

// Usage
cancel := debugWithTimeout(logger, 10*time.Minute)
defer cancel()
```

### Monitor Level Changes

Track level changes over time:

```go
type LevelChangeTracker struct {
    changes []LevelChange
    mu      sync.Mutex
}

type LevelChange struct {
    Timestamp time.Time
    OldLevel  logging.Level
    NewLevel  logging.Level
    Reason    string
}

func (t *LevelChangeTracker) Track(old, new logging.Level, reason string) {
    t.mu.Lock()
    defer t.mu.Unlock()
    
    t.changes = append(t.changes, LevelChange{
        Timestamp: time.Now(),
        OldLevel:  old,
        NewLevel:  new,
        Reason:    reason,
    })
}
```

## Performance Considerations

### Level Check Cost

Level checks are very fast:

```go
// ~5ns per call
if logger.Logger().Enabled(ctx, logging.LevelDebug) {
    // Expensive debug operation
}
```

### Transitional Race

Brief window where log level is transitioning:

```go
// T0: Level is Info
logger.SetLevel(logging.LevelDebug)  // T1: Transitioning...
// T2: Level is Debug
```

**Impact:** Some logs during T1 may use old or new level inconsistently.

**Mitigation:** Accept minor inconsistency during transition (typically <1ms).

## Next Steps

- Learn [Log Sampling](../sampling/) to reduce volume
- Explore [Router Integration](../router-integration/) for automatic logging
- See [Best Practices](../best-practices/) for production patterns
- Review [Testing](../testing/) for test utilities

For API details, see the [API Reference](/reference/packages/logging/api-reference/).
