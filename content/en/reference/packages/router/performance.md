---
title: "Router Performance"
linkTitle: "Performance"
weight: 35
keywords:
  - router benchmarks
  - router performance
  - framework comparison
  - benchmark methodology
  - rivaas performance
description: >
  Comprehensive benchmark comparison between rivaas/router and other popular Go web frameworks, with methodology and reproduction instructions.
---

This page contains detailed performance benchmarks comparing **rivaas/router** against other popular Go web frameworks. The benchmarks measure pure routing dispatch overhead by using direct writes (via `io.WriteString`) in all handlers to eliminate string concatenation allocations.

## Benchmark Methodology

### Test Environment

- **Go Version:** {{ site.Data.benchmarks.router.go_version }}
- **CPU:** {{ site.Data.benchmarks.router.cpu }}
- **OS:** {{ site.Data.benchmarks.router.goos }}/{{ site.Data.benchmarks.router.goarch }}
- **Last Updated:** {{ site.Data.benchmarks.router.updated }}

### Frameworks Compared

The following frameworks are included in the comparison:

- **Rivaas** ([rivaas.dev/router](https://rivaas.dev/router)) - This router
- **StdMux** ([net/http](https://pkg.go.dev/net/http)) - Go 1.22+ standard library with dynamic routing (`{param}`)
- **Gin** ([github.com/gin-gonic/gin](https://github.com/gin-gonic/gin)) - High-performance web framework
- **Echo** ([github.com/labstack/echo](https://github.com/labstack/echo)) - Minimalist web framework
- **Chi** ([github.com/go-chi/chi](https://github.com/go-chi/chi)) - Lightweight router
- **Fiber v2** ([github.com/gofiber/fiber/v2](https://github.com/gofiber/fiber)) - Express-inspired framework
- **Fiber v3** ([github.com/gofiber/fiber/v3](https://github.com/gofiber/fiber)) - Latest version of Fiber
- **Hertz** ([github.com/cloudwego/hertz](https://github.com/cloudwego/hertz)) - CloudWeGo HTTP framework
- **Beego** ([github.com/beego/beego](https://github.com/beego/beego)) - Full-stack framework

### Test Scenarios

All frameworks are tested with the same three route patterns:

1. **Static route:** `GET /`
2. **One parameter:** `GET /users/:id`
3. **Two parameters:** `GET /users/:id/posts/:post_id`

### Handler Implementation

To ensure fair comparison and isolate routing overhead, all handlers use **direct writes** rather than string concatenation:

```go
// Instead of this (causes one string allocation):
w.Write([]byte("User: " + id))

// Handlers do this (zero allocations for supported frameworks):
io.WriteString(w, "User: ")
io.WriteString(w, id)
```

This eliminates the handler allocation cost, so the measured time represents:

- Route tree traversal and matching
- Parameter extraction
- Context setup
- Response writer overhead (framework-specific)

### Measurement Notes

- **Fiber v2/v3:** Measured via `net/http` adaptor (`fiberadaptor.FiberApp`) for compatibility with `httptest.ResponseRecorder`. The adaptor adds overhead but is necessary for the standard test harness.
- **Hertz:** Measured using `ut.PerformRequest(h.Engine, ...)` (Hertz's native test API) because Hertz does not implement `http.Handler`. Numbers are not directly comparable to httptest-based frameworks due to different measurement approach.
- **Beego:** May log "init global config instance failed" when `conf/app.conf` is missing; this is safe to ignore in benchmarks.

---

## Benchmark Results

### Static Route (`/`)

This scenario measures the overhead of dispatching a request to a static route with no parameters.

{{< benchmark-table scenario="Static" >}}

**Key Observations:**
- Rivaas, Gin, and StdMux achieve **zero allocations** with direct writes
- Echo has 1 allocation from its internal context
- Chi, Fiber, Hertz, and Beego have framework-specific overhead

---

### One Parameter (`/users/:id`)

This scenario measures routing + parameter extraction for a single dynamic segment.

{{< benchmark-table scenario="OneParam" >}}

**Key Observations:**
- Rivaas and Gin maintain **zero allocations** even with parameter extraction
- StdMux has 1 allocation from `r.PathValue()`
- Echo has 2 allocations (context + param storage)

---

### Two Parameters (`/users/:id/posts/:post_id`)

This scenario tests routing with multiple dynamic segments.

{{< benchmark-table scenario="TwoParams" >}}

**Key Observations:**
- Rivaas and Gin continue to show **zero allocations**
- StdMux scales linearly (2 allocs for 2 params)
- Echo scales with each additional parameter

---

## How to Reproduce

The benchmarks are located in the [router/benchmarks](https://github.com/rivaas-dev/rivaas/tree/main/router/benchmarks) directory of the rivaas repository.

### Running All Benchmarks

```bash
cd router/benchmarks
go test -bench=. -benchmem
```

### Running a Specific Scenario

```bash
# Static route only
go test -bench=BenchmarkStatic -benchmem

# One parameter only
go test -bench=BenchmarkOneParam -benchmem

# Two parameters only
go test -bench=BenchmarkTwoParams -benchmem
```

### Running a Specific Framework

```bash
# Rivaas only
go test -bench='/(Rivaas)$' -benchmem

# Gin only
go test -bench='/(Gin)$' -benchmem
```

### Multiple Runs for Statistical Analysis

Use `-count` to run benchmarks multiple times and `benchstat` to compare:

```bash
go test -bench=. -benchmem -count=5 > results.txt
go install golang.org/x/perf/cmd/benchstat@latest
benchstat results.txt
```

---

## Understanding the Results

### Metrics Explained

- **ns/op:** Nanoseconds per operation (lower is better)
- **B/op:** Bytes allocated per operation (lower is better)
- **allocs/op:** Number of allocations per operation (lower is better)

### Why Zero Allocations Matter

Each allocation has a cost:
- **Time:** Allocating memory takes time (~30-50ns for small allocations)
- **GC pressure:** More allocations mean more garbage collection work
- **Scalability:** At high request rates (millions/sec), eliminating allocations significantly reduces CPU and memory usage

Rivaas achieves zero allocations for routing and parameter extraction by:
- Pre-allocating context pools
- Using array-based parameter storage for ≤8 params
- Avoiding string concatenation in hot paths
- Efficient radix tree implementation with minimal allocations

---

## Continuous Benchmarking

The rivaas repository uses continuous benchmarking to detect performance regressions:

- **Pull Requests:** Every PR runs Rivaas-only benchmarks and compares against a baseline. If performance regresses beyond a threshold, the PR check fails.
- **Releases:** Full framework comparison runs on every release tag and updates this page automatically.

See the [benchmarks.yml workflow](https://github.com/rivaas-dev/rivaas/blob/main/.github/workflows/benchmarks.yml) for implementation details.

---

## See Also

- [Router Package Overview]({{< relref "../router" >}})
- [Router API Reference]({{< relref "api-reference" >}})
- [Benchmark Source Code](https://github.com/rivaas-dev/rivaas/tree/main/router/benchmarks)
