---
title: "API Reference"
description: "Complete API documentation for all types, functions, and interfaces"
keywords:
  - binding api
  - binding reference
  - api documentation
  - type reference
weight: 1
---

Detailed API reference for all exported types, functions, and interfaces in the `rivaas.dev/binding` package.

## Core Binding Functions

### Generic API

#### JSON

```go
func JSON[T any](data []byte, opts ...Option) (T, error)
```

Binds JSON data to a struct of type `T`.

**Parameters:**
- `data`: JSON bytes to parse.
- `opts`: Optional configuration options.

**Returns:**
- Populated struct of type `T`.
- Error if binding fails.

**Example:**
```go
type User struct {
    Name  string `json:"name"`
    Email string `json:"email"`
}

user, err := binding.JSON[User](jsonData)
```

#### JSONReader

```go
func JSONReader[T any](r io.Reader, opts ...Option) (T, error)
```

Binds JSON from an `io.Reader`. More memory-efficient for large payloads.

**Example:**
```go
user, err := binding.JSONReader[User](r.Body)
```

#### Query

```go
func Query[T any](values url.Values, opts ...Option) (T, error)
```

Binds URL query parameters to a struct.

**Parameters:**
- `values`: URL query values. Use `r.URL.Query()`.
- `opts`: Optional configuration options.

**Example:**
```go
type Params struct {
    Page  int      `query:"page" default:"1"`
    Limit int      `query:"limit" default:"20"`
    Tags  []string `query:"tags"`
}

params, err := binding.Query[Params](r.URL.Query())
```

#### Form

```go
func Form[T any](values url.Values, opts ...Option) (T, error)
```

Binds form data to a struct.

**Parameters:**
- `values`: Form values (`r.Form` or `r.PostForm`)
- `opts`: Optional configuration options

**Example:**
```go
type LoginForm struct {
    Username string `form:"username"`
    Password string `form:"password"`
}

form, err := binding.Form[LoginForm](r.PostForm)
```

#### Multipart

```go
func Multipart[T any](form *multipart.Form, opts ...Option) (T, error)
```

Binds multipart form data including file uploads to a struct. Use `*binding.File` type for file fields.

**Parameters:**
- `form`: Multipart form from `r.MultipartForm` after calling `r.ParseMultipartForm()`
- `opts`: Optional configuration options

**Returns:**
- Populated struct of type `T` with form fields and files
- Error if binding fails

**Example:**
```go
type UploadRequest struct {
    File        *binding.File `form:"file"`
    Title       string        `form:"title"`
    Description string        `form:"description"`
    Tags        []string      `form:"tags"`
}

// Parse multipart form first (32MB limit)
if err := r.ParseMultipartForm(32 << 20); err != nil {
    return err
}

req, err := binding.Multipart[UploadRequest](r.MultipartForm)
if err != nil {
    return err
}

// Save the uploaded file
if err := req.File.Save("/uploads/" + req.File.Name); err != nil {
    return err
}
```

**Multiple files:**
```go
type GalleryUpload struct {
    Photos []*binding.File `form:"photos"`
    Title  string          `form:"title"`
}

req, err := binding.Multipart[GalleryUpload](r.MultipartForm)
for _, photo := range req.Photos {
    photo.Save("/uploads/" + photo.Name)
}
```

**JSON in form fields:**

Multipart binding automatically parses JSON strings from form fields into nested structs:

```go
type Settings struct {
    Theme         string `json:"theme"`
    Notifications bool   `json:"notifications"`
}

type ProfileUpdate struct {
    Avatar   *binding.File `form:"avatar"`
    Settings Settings      `form:"settings"` // JSON automatically parsed
}

// Form field "settings" contains: {"theme":"dark","notifications":true}
req, err := binding.Multipart[ProfileUpdate](r.MultipartForm)
// req.Settings is now populated from the JSON string
```

#### Header

```go
func Header[T any](headers http.Header, opts ...Option) (T, error)
```

Binds HTTP headers to a struct.

**Example:**
```go
type Headers struct {
    APIKey    string `header:"X-API-Key"`
    RequestID string `header:"X-Request-ID"`
}

headers, err := binding.Header[Headers](r.Header)
```

#### Cookie

```go
func Cookie[T any](cookies []*http.Cookie, opts ...Option) (T, error)
```

Binds HTTP cookies to a struct.

**Example:**
```go
type Cookies struct {
    SessionID string `cookie:"session_id"`
    Theme     string `cookie:"theme" default:"light"`
}

cookies, err := binding.Cookie[Cookies](r.Cookies())
```

#### Path

```go
func Path[T any](params map[string]string, opts ...Option) (T, error)
```

Binds URL path parameters to a struct.

**Example:**
```go
type PathParams struct {
    UserID int `path:"user_id"`
}

// With gorilla/mux or chi
params, err := binding.Path[PathParams](mux.Vars(r))
```

#### XML

```go
func XML[T any](data []byte, opts ...Option) (T, error)
```

Binds XML data to a struct.

**Example:**
```go
type Document struct {
    Title string `xml:"title"`
    Body  string `xml:"body"`
}

doc, err := binding.XML[Document](xmlData)
```

#### XMLReader

```go
func XMLReader[T any](r io.Reader, opts ...Option) (T, error)
```

Binds XML from an `io.Reader`.

#### Bind (Multi-Source)

```go
func Bind[T any](sources ...Source) (T, error)
```

Binds from multiple sources with precedence.

**Example:**
```go
type Request struct {
    UserID int    `query:"user_id" json:"user_id"`
    APIKey string `header:"X-API-Key"`
}

req, err := binding.Bind[Request](
    binding.FromQuery(r.URL.Query()),
    binding.FromJSON(r.Body),
    binding.FromHeader(r.Header),
)
```

### Non-Generic API

#### JSONTo

```go
func JSONTo(data []byte, target interface{}, opts ...Option) error
```

Binds JSON to a pointer. Use when type comes from a variable.

**Example:**
```go
var user User
err := binding.JSONTo(jsonData, &user)
```

Similar non-generic functions exist for all sources:
- `QueryTo(values url.Values, target interface{}, opts ...Option) error`
- `FormTo(values url.Values, target interface{}, opts ...Option) error`
- `MultipartTo(form *multipart.Form, target interface{}, opts ...Option) error`
- `HeaderTo(headers http.Header, target interface{}, opts ...Option) error`
- `CookieTo(cookies []*http.Cookie, target interface{}, opts ...Option) error`
- `PathTo(params map[string]string, target interface{}, opts ...Option) error`
- `XMLTo(data []byte, target interface{}, opts ...Option) error`

### Source Constructors

For multi-source binding:

```go
func FromJSON(r io.Reader) Source
func FromQuery(values url.Values) Source
func FromForm(values url.Values) Source
func FromMultipart(form *multipart.Form) Source
func FromHeader(headers http.Header) Source
func FromCookie(cookies []*http.Cookie) Source
func FromPath(params map[string]string) Source
func FromXML(r io.Reader) Source
```

**Example with multipart:**
```go
type Request struct {
    UserID int           `path:"user_id"`
    File   *binding.File `form:"file"`
    Token  string        `header:"X-Token"`
}

req, err := binding.Bind[Request](
    binding.FromPath(pathParams),
    binding.FromMultipart(r.MultipartForm),
    binding.FromHeader(r.Header),
)
```

## Binder Type

### Constructor

```go
func New(opts ...Option) (*Binder, error)
func MustNew(opts ...Option) *Binder
```

Creates a reusable binder with configuration.

**Example:**
```go
binder := binding.MustNew(
    binding.WithConverter[uuid.UUID](uuid.Parse),
    binding.WithMaxDepth(16),
)

user, err := binder.JSON[User](data)
```

### Binder Methods

A `Binder` has the same methods as the package-level functions:

```go
func (b *Binder) JSON[T any](data []byte, opts ...Option) (T, error)
func (b *Binder) Query[T any](values url.Values, opts ...Option) (T, error)
// ... etc for all binding functions
```

## Error Types

### BindError

Field-specific binding error with detailed context:

```go
type BindError struct {
    Field  string // Field name that failed to bind
    Source string // Source ("query", "json", "header", etc.)
    Value  string // Raw value that failed to bind
    Type   string // Expected Go type
    Reason string // Human-readable reason
    Err    error  // Underlying error
}

func (e *BindError) Error() string
func (e *BindError) Unwrap() error
func (e *BindError) IsType() bool    // True if type conversion failed
func (e *BindError) IsMissing() bool // True if required field missing
```

**Example:**
```go
user, err := binding.JSON[User](data)
if err != nil {
    var bindErr *binding.BindError
    if errors.As(err, &bindErr) {
        log.Printf("Field %s from %s failed: %v",
            bindErr.Field, bindErr.Source, bindErr.Err)
    }
}
```

### UnknownFieldError

Returned in strict mode when unknown fields are encountered:

```go
type UnknownFieldError struct {
    Fields []string // List of unknown field names
}

func (e *UnknownFieldError) Error() string
```

**Example:**
```go
user, err := binding.JSON[User](data, binding.WithStrictJSON())
if err != nil {
    var unknownErr *binding.UnknownFieldError
    if errors.As(err, &unknownErr) {
        log.Printf("Unknown fields: %v", unknownErr.Fields)
    }
}
```

### MultiError

Multiple errors collected with `WithAllErrors()`:

```go
type MultiError struct {
    Errors []*BindError
}

func (e *MultiError) Error() string
func (e *MultiError) Unwrap() []error
```

**Example:**
```go
user, err := binding.JSON[User](data, binding.WithAllErrors())
if err != nil {
    var multi *binding.MultiError
    if errors.As(err, &multi) {
        for _, e := range multi.Errors {
            log.Printf("Field %s: %v", e.Field, e.Err)
        }
    }
}
```

## Interfaces

### ValueGetter

Interface for custom data sources:

```go
type ValueGetter interface {
    Get(key string) string          // Get first value for key
    GetAll(key string) []string     // Get all values for key
    Has(key string) bool            // Check if key exists
}
```

**Example Implementation:**
```go
type EnvGetter struct{}

func (g *EnvGetter) Get(key string) string {
    return os.Getenv(key)
}

func (g *EnvGetter) GetAll(key string) []string {
    if val := os.Getenv(key); val != "" {
        return []string{val}
    }
    return nil
}

func (g *EnvGetter) Has(key string) bool {
    _, exists := os.LookupEnv(key)
    return exists
}
```

### ConverterFunc

Function type for custom type converters:

```go
type ConverterFunc[T any] func(string) (T, error)
```

**Example:**
```go
func ParseEmail(s string) (Email, error) {
    if !strings.Contains(s, "@") {
        return "", errors.New("invalid email")
    }
    return Email(s), nil
}

binder := binding.MustNew(
    binding.WithConverter[Email](ParseEmail),
)
```

## Converter Factory Functions

Ready-to-use converter factories for common type patterns.

### TimeConverter

```go
func TimeConverter(layouts ...string) func(string) (time.Time, error)
```

Creates a converter that tries parsing time strings using the provided formats in order.

**Example:**
```go
binder := binding.MustNew(
    binding.WithConverter(binding.TimeConverter(
        "2006-01-02",      // ISO format
        "01/02/2006",      // US format
        "02-Jan-2006",     // Short month
    )),
)

type Event struct {
    Date time.Time `query:"date"`
}

// Works with: ?date=2026-01-28 or ?date=01/28/2026 or ?date=28-Jan-2026
event, err := binder.Query[Event](values)
```

### DurationConverter

```go
func DurationConverter(aliases map[string]time.Duration) func(string) (time.Duration, error)
```

Creates a converter that parses duration strings. It supports both standard Go duration format (like `"30m"`, `"2h30m"`) and custom aliases you define.

**Example:**
```go
binder := binding.MustNew(
    binding.WithConverter(binding.DurationConverter(map[string]time.Duration{
        "quick":  5 * time.Minute,
        "normal": 30 * time.Minute,
        "long":   2 * time.Hour,
    })),
)

type Config struct {
    Timeout time.Duration `query:"timeout"`
}

// Works with: ?timeout=quick or ?timeout=30m or ?timeout=2h30m
config, err := binder.Query[Config](values)
```

### EnumConverter

```go
func EnumConverter[T ~string](allowed ...T) func(string) (T, error)
```

Creates a converter that checks if a string value is one of the allowed options. Matching is case-insensitive.

**Example:**
```go
type Status string

const (
    StatusActive   Status = "active"
    StatusPending  Status = "pending"
    StatusDisabled Status = "disabled"
)

binder := binding.MustNew(
    binding.WithConverter(binding.EnumConverter(
        StatusActive,
        StatusPending,
        StatusDisabled,
    )),
)

type User struct {
    Status Status `query:"status"`
}

// Works with: ?status=active or ?status=ACTIVE (case-insensitive)
// Returns error for: ?status=invalid
user, err := binder.Query[User](values)
```

### BoolConverter

```go
func BoolConverter(truthy, falsy []string) func(string) (bool, error)
```

Creates a converter that parses boolean values using your custom truthy and falsy strings. Matching is case-insensitive.

**Example:**
```go
binder := binding.MustNew(
    binding.WithConverter(binding.BoolConverter(
        []string{"yes", "on", "enabled", "1"},   // truthy
        []string{"no", "off", "disabled", "0"},  // falsy
    )),
)

type Settings struct {
    Notifications bool `query:"notifications"`
}

// Works with: ?notifications=yes, ?notifications=ON, ?notifications=off
settings, err := binder.Query[Settings](values)
```

## Helper Functions

### MapGetter

Converts a `map[string]string` to a `ValueGetter`:

```go
func MapGetter(m map[string]string) ValueGetter
```

**Example:**
```go
data := map[string]string{"name": "Alice", "age": "30"}
getter := binding.MapGetter(data)
result, err := binding.RawInto[User](getter, "custom")
```

### MultiMapGetter

Converts a `map[string][]string` to a `ValueGetter`:

```go
func MultiMapGetter(m map[string][]string) ValueGetter
```

**Example:**
```go
data := map[string][]string{
    "tags": {"go", "rust"},
    "name": {"Alice"},
}
getter := binding.MultiMapGetter(data)
result, err := binding.RawInto[User](getter, "custom")
```

### GetterFunc

Adapts a function to the `ValueGetter` interface:

```go
type GetterFunc func(key string) ([]string, bool)

func (f GetterFunc) Get(key string) string
func (f GetterFunc) GetAll(key string) []string
func (f GetterFunc) Has(key string) bool
```

**Example:**
```go
getter := binding.GetterFunc(func(key string) ([]string, bool) {
    if val, ok := myMap[key]; ok {
        return []string{val}, true
    }
    return nil, false
})
```

### Raw/RawInto

Low-level binding from custom `ValueGetter`:

```go
func Raw[T any](getter ValueGetter, source string, opts ...Option) (T, error)
func RawInto(getter ValueGetter, source string, target interface{}, opts ...Option) error
```

## Events and Observability

### Events Type

Hooks for observing binding operations:

```go
type Events struct {
    FieldBound   func(name, tag string)
    UnknownField func(name string)
    Done         func(stats Stats)
}
```

**Example:**
```go
binder := binding.MustNew(
    binding.WithEvents(binding.Events{
        FieldBound: func(name, tag string) {
            log.Printf("Bound field %s from %s", name, tag)
        },
        UnknownField: func(name string) {
            log.Printf("Unknown field: %s", name)
        },
        Done: func(stats binding.Stats) {
            log.Printf("Binding completed: %d fields, %d errors",
                stats.FieldsBound, stats.ErrorCount)
        },
    }),
)
```

### Stats Type

Statistics from binding operation:

```go
type Stats struct {
    FieldsBound int           // Number of fields successfully bound
    ErrorCount  int           // Number of errors encountered
    Duration    time.Duration // Time taken for binding
}
```

## Constants

### Slice Modes

```go
const (
    SliceRepeat SliceMode = iota // Repeated params: ?tags=a&tags=b (default)
    SliceCSV                     // CSV params: ?tags=a,b,c
)
```

### Unknown Field Handling

```go
const (
    UnknownIgnore UnknownMode = iota // Ignore unknown fields (default)
    UnknownWarn                       // Log warning for unknown fields
    UnknownError                      // Error on unknown fields
)
```

### Merge Strategies

```go
const (
    MergeLastWins  MergeStrategy = iota // Last source wins (default)
    MergeFirstWins                       // First source wins
)
```

## Default Values

### Time Layouts

```go
var DefaultTimeLayouts = []string{
    time.RFC3339,
    time.RFC3339Nano,
    time.RFC1123,
    time.RFC1123Z,
    time.RFC822,
    time.RFC822Z,
    time.RFC850,
    time.ANSIC,
    time.UnixDate,
    time.RubyDate,
    time.Kitchen,
    time.Stamp,
    time.StampMilli,
    time.StampMicro,
    time.StampNano,
    time.DateTime,
    time.DateOnly,
    time.TimeOnly,
    "2006-01-02",
    "01/02/2006",
    "2006/01/02",
}
```

Can be extended with `WithTimeLayouts()`.

## Type Constraints

### Supported Interface Types

Types implementing these interfaces are automatically supported:

- `encoding.TextUnmarshaler`: For custom text unmarshaling
- `json.Unmarshaler`: For custom JSON unmarshaling
- `xml.Unmarshaler`: For custom XML unmarshaling

**Example:**
```go
type Status string

func (s *Status) UnmarshalText(text []byte) error {
    // Custom parsing logic
    *s = Status(string(text))
    return nil
}

type Request struct {
    Status Status `query:"status"` // Automatically uses UnmarshalText
}
```

## Thread Safety

All package-level functions and `Binder` methods are safe for concurrent use. The struct reflection cache is thread-safe and has no size limit.

## See Also

- **[Options Reference](../options/)** - All configuration options
- **[Sub-Packages](../sub-packages/)** - YAML, TOML, MessagePack, Protocol Buffers
- **[Performance](/reference/packages/router/performance/)** - Router benchmarks and optimization
- **[Troubleshooting](../troubleshooting/)** - Common issues and solutions

For usage examples, see the [Binding Guide](/guides/binding/).
