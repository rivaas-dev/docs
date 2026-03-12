---
title: "Documentation Standards"
description: "How to write clear documentation for Go code"
weight: 10
keywords:
  - documentation
  - godoc
  - comments
  - code comments
  - standards
---

This page explains how to write documentation for Rivaas code. Good documentation helps everyone understand how the code works.

## Main Goal

Write clear documentation that explains:

- **What** the code does
- **How** to use it
- **What** inputs it needs and outputs it gives

## What NOT to Write

Don't mention these things in documentation:

### Performance Details

Don't use words like:
- "fast", "slow", "efficient"
- "optimized", "quick"
- "high-performance"
- Any speed comparisons

### Algorithm Details

Don't include:
- Big-O notation (like O(1), O(n))
- Time or space complexity
- Algorithm names used to show speed

### Benchmark Results

Don't mention:
- "zero allocations"
- "optimized for speed"
- "50% faster"
- Any performance numbers

### Memory Usage

Don't talk about:
- "low memory usage"
- "minimal allocations"
- "memory-efficient"
- Specific memory amounts

### Visual Decorations

Don't use:
- Lines of equals signs or dashes
- ASCII art
- Empty comment lines for spacing
- Comments that add no information

### TODO Comments About Moving Code

Don't write:
- "TODO: move this to..."
- "FIXME: this should be in..."
- "NOTE: consider moving to..."

**Why not?** If code needs to move, move it now. Don't leave a comment about it. Use version control (git) to track changes.

### File History Comments

Don't write:
- "merged from..."
- "moved from..."
- "originally in..."
- "Benchmarks from X file"

**Why not?** Git tracks file history. Comments should explain what code does now, not where it came from.

## What You SHOULD Write

Your documentation must focus on:

### Purpose

- What the function, type, or method does
- Why it exists
- When to use it

### Functionality

- What it does in simple words
- How it changes inputs to outputs
- Step-by-step behavior (when helpful)

### Usage

- How to use it (with brief examples)
- Common use cases
- How to integrate it

### Code Examples in Documentation

Public functions should include examples:

- Use **tab-indented** code blocks with `// Example:` header
- Show typical usage patterns
- Keep examples short and focused
- Use valid Go code that compiles
- Put examples after main description

**Important:** GoDoc needs **tab indentation** (not spaces) for code blocks.

**Inline example format:**

```go
// FunctionName does something useful.
// It processes the input and returns a result.
//
// Example:
//
//	result := FunctionName("input")
//	fmt.Println(result)
//
// Parameters:
//   - input: description
func FunctionName(input string) string { ... }
```

**Runnable Example functions (preferred):**

For public APIs, create `Example` functions in `*_test.go` files:

```go
// In example_test.go
func ExampleFunctionName() {
	result := FunctionName("input")
	fmt.Println(result)
	// Output: expected output
}
```

### Parameters and Return Values

- What each parameter means
- What values are returned
- Error conditions and their meanings

### Behavior and Edge Cases

- Expected behavior normally
- Edge cases and how they're handled
- Side effects (if any)
- Thread safety (if relevant)

### Constraints and Requirements

- Requirements to use it
- Limitations or known issues
- Dependencies

### Error Documentation

Document when errors happen:

```go
// Parse parses the input string into a Result.
// It returns an error if parsing fails.
//
// Errors:
//   - [ErrInvalidFormat]: input string is malformed
//   - [ErrEmpty]: input is an empty string
//   - [ErrTooLong]: input exceeds maximum length
func Parse(input string) (Result, error) { ... }
```

### Deprecation

Mark deprecated APIs clearly:

```go
// Deprecated: Use [NewRouter] instead. This function will be removed in v2.0.
func OldRouter() *Router { ... }

// Deprecated: Use [Context.Value] with [RequestIDKey] instead.
func (c *Context) RequestID() string { ... }
```

### Interface vs Implementation

**Interfaces** document the contract:

```go
// Handler handles HTTP requests.
// Implementations must be safe for concurrent use.
// Handle should not modify the request after returning.
type Handler interface {
	Handle(ctx *Context) error
}
```

**Implementations** reference the interface:

```go
// JSONHandler implements [Handler] for JSON request/response handling.
// It automatically parses JSON request bodies and encodes JSON responses.
type JSONHandler struct { ... }
```

### Generic Types

Document type parameter requirements:

```go
// BindInto binds values from a ValueGetter into a struct of type T.
// T must be a struct type; using non-struct types results in an error.
// T should have exported fields with appropriate struct tags.
//
// Example:
//
//	result, err := BindInto[UserRequest](getter, "query")
func BindInto[T any](getter ValueGetter, tag string) (T, error) { ... }
```

### Thread Safety

Document concurrency behavior when relevant:

```go
// Router is safe for concurrent use by multiple goroutines.
// Routes should be registered before calling [Router.ServeHTTP].
type Router struct { ... }

// Counter provides a thread-safe counter.
// All methods may be called concurrently from multiple goroutines.
type Counter struct { ... }

// Builder is NOT safe for concurrent use.
// Create separate Builder instances for each goroutine.
type Builder struct { ... }
```

### Cross-References

Use bracket syntax `[Symbol]` to link to other symbols (Go 1.19+):

```go
// Handle processes the request using the provided [Context].
// It returns a [Response] or an error.
// See [Router.Register] for how to register handlers.
func Handle(ctx *Context) (*Response, error) { ... }
```

**Link targets:**

- `[FunctionName]` — links to function in same package
- `[TypeName]` — links to type in same package
- `[TypeName.MethodName]` — links to method
- `[pkg.Symbol]` — links to symbol in other package (e.g., `[http.Handler]`)

## Style Rules

### GoDoc Standards

- **Start with the name** — Begin function comments with the function/type name
  - ✅ `// Register adds a new route...`
  - ❌ `// This function registers...`

- **Use third-person** — Write "Handler creates..." not "I create..."
  - ✅ "Handler creates...", "Router registers...", "Context stores..."
  - ❌ "This creates...", "We register...", "I store..."

### Clarity and Conciseness

- Use **full sentences**
- Keep comments **short but meaningful**
- Avoid unnecessary words
- Be direct and clear

### Language Guidelines

- **No marketing language** — Avoid adjectives like:
  - "simple", "powerful", "robust", "amazing"
  - "best", "perfect", "ideal"
- **No superlatives** — No "fastest" or "most reliable"
- **Focus on facts** — Describe what code does

### Code Examples

- **Public APIs need examples**
- Use **tab indentation** (not spaces) for code blocks
- Prefer **runnable Example functions** in `*_test.go` files
- Keep examples **minimal and focused**

### Package Documentation Files (doc.go)

When package documentation is long (more than a few lines), use a `doc.go` file:

- **File name:** Must be exactly `doc.go` (lowercase)
- **Location:** In the package root directory
- **Content:** Only package comment and package declaration
- **Purpose:** Keeps package overview separate from code

**Format requirements:**

- Start with `// Package [name]` and clear description
- First sentence is summary (shown in listings)
- Use markdown headers (`#`) for sections
- Include code examples when helpful
- Cover: purpose, main concepts, usage patterns

**What to include:**

- Package overview and purpose
- Key features
- Architecture (when relevant)
- Quick start examples
- Common usage patterns
- Links to examples or related packages

**What NOT to include:**

- Performance details
- Algorithm complexity
- File organization history
- Individual function documentation (put those in their files)

**Example structure:**

```go
// Package router provides an HTTP router for Go.
//
// The router implements a routing system for cloud-native applications.
// It features path matching, parameter extraction, and comprehensive middleware support.
//
// # Key Features
//
//   - Path matching for static and parameterized routes
//   - Parameter extraction from URL paths
//   - Context pooling for request handling
//
// # Quick Start
//
//	package main
//
//	import "rivaas.dev/router"
//
//	func main() {
//	    r := router.New()
//	    r.GET("/", handler)
//	    r.Run(":8080")
//	}
//
// # Examples
//
// See the examples directory for complete working examples.
package router
```

**When to use doc.go:**

- **Use doc.go:** Package documentation is long (multiple paragraphs, sections)
- **Use inline comments:** Package documentation is brief (1-3 sentences)

## Examples

### Good Documentation

```go
// Register adds a new route to the [Router] using the given method and pattern.
// It returns the created [Route], which can be further configured.
// Register should be called during application setup before the server starts.
func (r *Router) Register(method, pattern string) *Route { ... }

// Context represents an HTTP request context.
// It provides access to the request, response writer, and route parameters.
// Context instances are pooled and reused across requests.
// Context is NOT safe for use after the handler returns.
type Context struct { ... }

// Param returns the value of the named route parameter.
// It returns an empty string if the parameter is not found.
// Parameters are extracted from the URL path during route matching.
//
// Example:
//
//	userID := c.Param("id")
//	fmt.Println(userID)
func (c *Context) Param(name string) string { ... }
```

### Bad Documentation

```go
// Register is a highly optimized router method with zero allocations.
// Uses O(1) lookup for fast routing.
// Extremely efficient performance characteristics.
func (r *Router) Register(method, pattern string) *Route { ... }

// Context is a fast, memory-efficient request context.
// Uses minimal allocations and provides high-performance access.
// Benchmarks show 50% faster than alternatives.
type Context struct { ... }

// Param returns the value with O(1) lookup time.
// Optimized for speed with zero allocations.
func (c *Context) Param(name string) string { ... }

// ========================================
// HTTP Context Methods
// ========================================
func (c *Context) Param(name string) string { ... }

// TODO: move this to a separate file
// Param returns the value of the named route parameter.
func (c *Context) Param(name string) string { ... }
```

## Review Checklist

When writing or reviewing documentation, check:

### Content Rules

- [ ] No performance words (fast, efficient, optimized)
- [ ] No algorithm complexity (Big-O, O(1))
- [ ] No benchmark claims
- [ ] No memory usage details
- [ ] No marketing language
- [ ] No decorative comment lines
- [ ] No TODO/FIXME about moving code
- [ ] No file history comments (merged from, moved from)
- [ ] Comments provide useful information

### Style Rules

- [ ] Comments start with function/type name
- [ ] Third-person, descriptive language
- [ ] Clear explanation of what code does

### Documentation Completeness

- [ ] Parameters and return values documented
- [ ] Error conditions documented with specific types
- [ ] Edge cases and constraints mentioned
- [ ] Thread safety documented when relevant
- [ ] Generic type constraints documented

### Examples and References

- [ ] Public APIs include examples
- [ ] Code examples use tab indentation
- [ ] Cross-references use `[Symbol]` syntax

### Special Cases

- [ ] Deprecated functions use `// Deprecated:` prefix
- [ ] Interfaces document contract, implementations reference interface
- [ ] Long package docs use `doc.go` file
- [ ] `doc.go` files start with `// Package [name]`

## Additional Resources

- [Go Doc Comments](https://go.dev/doc/comment) — Official guide
- [Effective Go - Commentary](https://go.dev/doc/effective_go#commentary) — General guidelines
- [Example Functions](https://go.dev/blog/examples) — Writing testable examples

## Summary

**Remember:** Documentation explains **what** code does and **how** to use it, not **how well** it performs. Focus on functionality, behavior, and usage patterns. If performance is implied by code, don't mention it in documentation.
