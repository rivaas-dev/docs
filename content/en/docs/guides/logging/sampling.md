---
title: "Log Sampling"
description: "Reduce log volume in high-traffic scenarios with intelligent sampling"
weight: 7
keywords:
  - log sampling
  - rate limiting
  - high volume
  - sampling
---

This guide covers log sampling to reduce log volume in high-throughput production environments while maintaining visibility.

## Overview

Log sampling reduces the number of log entries written while preserving statistical sampling for debugging and analysis.

**Why log sampling:**
- Reduce log storage costs in high-traffic scenarios.
- Prevent log flooding during traffic spikes.
- Maintain representative sample for debugging.
- Always log critical errors. Sampling bypasses ERROR level.

**When to use:**
- Services handling more than 1000 logs per second.
- Cost-constrained log storage.
- High-volume debug or info logging.
- Noisy services with repetitive logs.

## Basic Configuration

Configure sampling with functional options:

```go
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithSamplingInitial(100),         // Log first 100 entries unconditionally
    logging.WithSamplingThereafter(100),     // After that, log 1 in every 100
    logging.WithSamplingTick(time.Minute),  // Reset counter every minute
)
```

## How Sampling Works

The sampling algorithm has three phases:

### 1. Initial Phase

Log the first N entries unconditionally with `WithSamplingInitial`:

```go
logging.WithSamplingInitial(100),  // First 100 logs always written
```

**Purpose:** Ensure you always see the beginning of operations, even if they're short-lived.

### 2. Sampling Phase

After the initial phase, log 1 in every N entries with `WithSamplingThereafter`:

```go
logging.WithSamplingInitial(100),
logging.WithSamplingThereafter(100),  // Log 1%, drop 99%
```

**Examples:**
- `WithSamplingThereafter(100)` → 1% sampling (log 1 in 100)
- `WithSamplingThereafter(10)` → 10% sampling (log 1 in 10)
- `WithSamplingThereafter(1000)` → 0.1% sampling (log 1 in 1000)

### 3. Reset Phase

Reset the counter every interval with `WithSamplingTick`:

```go
logging.WithSamplingInitial(100),
logging.WithSamplingThereafter(100),
logging.WithSamplingTick(time.Minute),  // Reset every minute
```

**Purpose:** Ensure recent activity is always visible. Without resets, you might miss important recent events.

## Sampling Behavior

### Visual Timeline

```
Time:     0s    30s   60s   90s   120s  150s
          |-----|-----|-----|-----|-----|
Logs:     [Initial] [Sample] [Reset→Initial] [Sample]
          ▓▓▓▓▓     ░░░     ▓▓▓▓▓           ░░░
          100%      1%      100%            1%
```

- **▓▓▓▓▓** - Initial phase (100% logging)
- **░░░** - Sampling phase (1% logging)
- **Reset** - Counter resets at `Tick` interval

### Error Bypass

**Errors (level >= ERROR) always bypass sampling:**

```go
logger := logging.MustNew(
    logging.WithSamplingInitial(100),
    logging.WithSamplingThereafter(100),  // 1% sampling
    logging.WithSamplingTick(time.Minute),
)

// These may be sampled
logger.Debug("processing item", "id", id)  // May be dropped
logger.Info("request handled", "path", path)  // May be dropped

// These are NEVER sampled
logger.Error("database error", "error", err)  // Always logged
logger.Error("payment failed", "tx_id", txID)  // Always logged
```

**Rationale:** Critical errors should never be lost, regardless of sampling configuration.

## Configuration Examples

### High-Traffic API

```go
// Log all errors, but only 1% of info/debug
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
    logging.WithSamplingInitial(1000),         // First 1000 requests fully logged
    logging.WithSamplingThereafter(100),       // Then 1% sampling
    logging.WithSamplingTick(5 * time.Minute), // Reset every 5 minutes
)
```

**Result:**
- Startup: All logs for first 1000 requests
- Steady state: 1% of logs (99% reduction)
- Every 5 minutes: Full logging resumes briefly

### Debug Logging in Production

```go
// Enable debug logs with heavy sampling
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelDebug),
    logging.WithSamplingInitial(50),              // See first 50 debug logs
    logging.WithSamplingThereafter(1000),         // Then 0.1% sampling
    logging.WithSamplingTick(10 * time.Minute),   // Reset every 10 minutes
)
```

**Use case:** Temporarily enable debug logging in production without overwhelming logs.

### Cost Optimization

```go
// Aggressive sampling for cost reduction
logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelInfo),
    logging.WithSamplingInitial(500),
    logging.WithSamplingThereafter(1000),  // 0.1% sampling (99.9% reduction)
    logging.WithSamplingTick(time.Hour),
)
```

**Result:** Dramatic log volume reduction while maintaining statistical samples.

## Special Configurations

### No Sampling After Initial

Use `WithSamplingThereafter(0)` to log everything after the initial phase:

```go
logging.WithSamplingInitial(100),   // First 100 sampled
logging.WithSamplingThereafter(0),  // Then log everything
logging.WithSamplingTick(time.Minute),
```

**Use case:** Rate limiting only during burst startup.

### No Reset

Omit `WithSamplingTick` or use `WithSamplingTick(0)` to never reset the counter:

```go
logging.WithSamplingInitial(1000),
logging.WithSamplingThereafter(100),
// No WithSamplingTick, or WithSamplingTick(0) — never reset
```

**Result:** Sample continuously without periodic full logging.

## Monitoring Sampling

### Check Sampling State

Use `DebugInfo()` to inspect sampling state:

```go
info := logger.DebugInfo()
samplingInfo := info["sampling"].(map[string]any)

fmt.Printf("Initial: %d\n", samplingInfo["initial"])
fmt.Printf("Thereafter: %d\n", samplingInfo["thereafter"])
fmt.Printf("Counter: %d\n", samplingInfo["counter"])
```

**Output:**
```
Initial: 100
Thereafter: 100
Counter: 1543
```

### Log Sampling Metrics

Periodically log sampling state:

```go
ticker := time.NewTicker(time.Minute)
go func() {
    for range ticker.C {
        info := logger.DebugInfo()
        if sampling, ok := info["sampling"].(map[string]any); ok {
            logger.Info("sampling state",
                "counter", sampling["counter"],
                "config", fmt.Sprintf("%d/%d/%v", 
                    sampling["initial"], 
                    sampling["thereafter"],
                    sampling["tick"]),
            )
        }
    }
}()
```

## Performance Impact

### Overhead

Sampling adds minimal overhead:

```go
// Without sampling: ~500ns per log
// With sampling: ~520ns per log
// Overhead: ~20ns (4%)
```

**Breakdown:**
- Atomic counter increment: ~10ns
- Sampling decision: ~10ns
- No additional allocations

### When to Skip Sampling

Skip sampling if:
- Logging <100 entries/second
- Log storage cost is not a concern
- Need every log entry (compliance, debugging)
- Using external sampling (e.g., log aggregation system does sampling)

## Best Practices

### Start Conservative

Begin with light sampling, increase if needed:

```go
// Phase 1: Start conservative
logging.WithSamplingInitial(1000),
logging.WithSamplingThereafter(10),  // 10% sampling
logging.WithSamplingTick(time.Minute),

// Phase 2: If still too much, increase sampling
logging.WithSamplingInitial(1000),
logging.WithSamplingThereafter(100),  // 1% sampling
logging.WithSamplingTick(time.Minute),
```

### Reset Frequently

Reset counters to maintain visibility with `WithSamplingTick`:

```go
// Good - see recent activity
logging.WithSamplingTick(time.Minute)

// Better - more responsive
logging.WithSamplingTick(30 * time.Second)

// Too aggressive - missing too much
logging.WithSamplingTick(time.Hour)
```

### Per-Logger Sampling

Use different sampling for different loggers:

```go
// Access logs - heavy sampling
accessLogger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithSamplingInitial(100),
    logging.WithSamplingThereafter(1000),  // 0.1%
    logging.WithSamplingTick(time.Minute),
)

// Application logs - light sampling
appLogger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithSamplingInitial(500),
    logging.WithSamplingThereafter(10),  // 10%
    logging.WithSamplingTick(time.Minute),
)
```

### Monitor Log Volume

Track log volume to tune sampling:

```go
var logCount atomic.Int64

logger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithSamplingInitial(1000),
    logging.WithSamplingThereafter(100),
    logging.WithSamplingTick(time.Minute),
)

// Periodically check
ticker := time.NewTicker(time.Minute)
go func() {
    for range ticker.C {
        count := logCount.Swap(0)
        fmt.Printf("Logs/minute: %d\n", count)
        
        // Adjust sampling if needed
        if count > 10000 {
            // Consider more aggressive sampling
        }
    }
}()
```

## Troubleshooting

### Missing Expected Logs

**Problem:** Important logs being sampled out.

**Solution:** Use ERROR level for critical logs:

```go
// May be sampled
logger.Info("payment processed", "tx_id", txID)

// Never sampled
logger.Error("payment failed", "tx_id", txID)
```

### Too Much Log Volume

**Problem:** Sampling not reducing volume enough.

**Solutions:**

1. Increase the value passed to `WithSamplingThereafter`:
```go
logging.WithSamplingThereafter(1000),  // More aggressive: 0.1% instead of 1%
```

2. Reduce the value passed to `WithSamplingInitial`:
```go
logging.WithSamplingInitial(50),  // Fewer initial logs
```

3. Increase the interval passed to `WithSamplingTick`:
```go
logging.WithSamplingTick(5 * time.Minute),  // Reset less frequently
```

### Lost Debug Context

**Problem:** Sampling makes debugging difficult.

**Solution:** Temporarily disable sampling by omitting sampling options:

```go
// Create logger without sampling for debugging session
debugLogger := logging.MustNew(
    logging.WithJSONHandler(),
    logging.WithLevel(logging.LevelDebug),
    // No WithSamplingInitial / WithSamplingThereafter / WithSamplingTick
)
```

## Next Steps

- Learn [Dynamic Log Levels](../dynamic-levels/) to change verbosity at runtime
- Explore [Best Practices](../best-practices/) for production logging
- See [Router Integration](../router-integration/) for automatic request logging

For API details, see the [Options Reference](/docs/reference/packages/logging/options/).
