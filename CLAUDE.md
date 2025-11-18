# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FTAPIKit is a declarative async/await REST API framework for Swift using Swift Concurrency and Codable. It provides a protocol-oriented approach to defining web services with standard implementation using URLSession and JSON encoder/decoder. The framework is built for Swift 6.1 with full concurrency safety.

**Key Features:**
- Declarative async/await API for defining web services
- Protocol-oriented design with `Server` and `Endpoint` protocols
- Multiple endpoint types for different use cases (GET, POST, multipart uploads, etc.)
- Async buildRequest enabling token refresh, dynamic configuration, and rate limiting
- Swift 6 concurrency safety with Sendable requirements
- Built-in support for FTNetworkTracer for request logging and tracking
- Cross-platform support: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+, and Linux

## Build and Test Commands

### Building
```bash
swift build
```

### Running Tests
```bash
# Run all tests
swift test

# For CocoaPods validation
gem install bundler
bundle install --jobs 4 --retry 3
bundle exec pod lib lint --allow-warnings
```

### Linting
```bash
# Run SwiftLint with strict mode
swiftlint --strict
```

The project uses an extensive SwiftLint configuration (`.swiftlint.yml`) with many opt-in rules enabled. Linting must pass with `--strict` flag for CI to succeed.

## Architecture

### Core Protocol Design

The framework is built around two core protocols that mirror physical infrastructure:

1. **`Server` Protocol** - Represents a single web service
   - Defines encoding/decoding strategies
   - Builds requests from endpoints
   - Standard implementation: `URLServer` (uses Foundation's URLSession)

2. **`Endpoint` Protocol** - Represents access points for resources
   - Defines path, headers, query parameters, and HTTP method
   - Multiple specialized variants for different use cases

### Endpoint Type Hierarchy

The framework provides several endpoint protocol variants:

- **`Endpoint`** - Base protocol with empty body (typically for GET requests)
- **`DataEndpoint`** - Sends raw data in body
- **`UploadEndpoint`** - Uploads files using InputStream (not available on Linux)
- **`MultipartEndpoint`** - Combines body parts into multipart request (not available on Linux)
- **`URLEncodedEndpoint`** - Body in URL query format
- **`RequestEndpoint`** - Has encodable request model (defaults to POST)
- **`ResponseEndpoint`** - Has decodable response model
- **`RequestResponseEndpoint`** - Typealias combining request and response endpoints

### Key Architectural Patterns

**Protocol-Oriented Design**: Endpoints are designed to be implemented as structs (not enums or classes). This provides:
- Generated initializers
- Better long-term sustainability (endpoint info stays localized)
- No memory overhead for instant usage after creation

**Swift 6 Concurrency Safety**: All `ResponseEndpoint` associated types must conform to `Sendable`:
- Response models must be `Sendable` for thread-safe async/await usage
- Compiler enforces this at endpoint definition, providing clear error messages
- Breaking change from pre-6.0 versions but ensures concurrency correctness

**Encoding/Decoding Abstraction**: The `Encoding` and `Decoding` protocols provide type-erased wrappers around Swift's `Codable` system:
- `JSONEncoding` / `JSONDecoding` for JSON with customizable encoders/decoders
- `URLRequestEncoding` extends encoding to configure URLRequest headers

**Async Request Building**: The request building flow is fully asynchronous (addressing GitHub issue #105):
1. `Server.buildRequest(endpoint:)` is declared as `async throws`
2. Can be overridden to perform async operations (token refresh, config fetch, rate limiting)
3. Default implementation calls synchronous `buildStandardRequest(endpoint:)` helper
4. Enables powerful use cases like awaiting token managers or fetching dynamic headers
5. Specialized handling for multipart, upload, and encoded endpoints

### Module Organization

**Source Structure** (`Sources/FTAPIKit/`):
- Core protocols: `Server.swift`, `Endpoint.swift`, `URLServer.swift`
- Request building: `URLRequestBuilder.swift`
- Async execution: `URLServer+Async.swift`, `URLServer+Download.swift`
- Internal helpers: `URLServer+Task.swift` (provides async request building and error helpers)
- Utilities: `Coding.swift`, `URLQuery.swift`, `MultipartFormData.swift`, etc.
- Error handling: `APIError.swift`, `APIError+Standard.swift`

**Test Structure** (`Tests/FTAPIKitTests/`):
- Test files: `AsyncTests.swift`, `AsyncBuildRequestTests.swift`, `URLQueryTests.swift`
- Test utilities in `Mockups/`: `Servers.swift`, `Endpoints.swift`, `Models.swift`, `Errors.swift`

### Call Execution Pattern

The framework uses async/await exclusively:

```swift
// Basic call
let response = try await server.call(response: endpoint)

// Data call (raw Data response)
let data = try await server.call(data: endpoint)

// Void call (no response body)
try await server.call(endpoint: endpoint)

// Download call
let fileURL = try await server.download(endpoint: endpoint)
```

**Cancellation**: Use Task cancellation for aborting requests:
```swift
let task = Task {
    try await server.call(response: endpoint)
}
task.cancel() // Cancels the request
```

**Breaking Change from 1.x**: Completion handlers and Combine support were removed in 2.0. All API calls use async/await.

### Error Handling

- `APIError` protocol defines error handling interface
- Default implementation: `APIError.Standard`
- Custom error types can be defined via `URLServer.ErrorType` associated type
- Errors initialized from: `Data?`, `URLResponse?`, `Error?`, and `Decoding`

### Network Tracing

The framework integrates with `FTNetworkTracer` for request logging:
- `URLServer.networkTracer` property (optional, defaults to nil)
- Dependency: `https://github.com/futuredapp/FTNetworkTracer`

## Package Management

The project supports both **Swift Package Manager** and **CocoaPods**:

- **SPM**: See `Package.swift`
- **CocoaPods**: See `FTAPIKit.podspec` and `Gemfile`

### Platform Support

Minimum deployment targets:
- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+
- Linux (with FoundationNetworking, limited endpoint types)

Note: `UploadEndpoint` and `MultipartEndpoint` are not available on Linux.

## Testing Approach

Tests use mock servers (HTTPBin-based) defined in `Tests/FTAPIKitTests/Mockups/Servers.swift`:
- `HTTPBinServer` - Standard test server with async authorization support
- `NonExistingServer` - For testing error conditions
- `ErrorThrowingServer` - Custom error type testing

**Test Files:**
- `AsyncTests.swift` - Tests for basic async/await functionality
- `AsyncBuildRequestTests.swift` - Demonstrates async buildRequest use cases (token refresh, dynamic headers)
- `URLQueryTests.swift` - Tests for URL query parameter handling

Mock endpoints demonstrate all endpoint types and are reusable across test suites. All tests use async/await patterns.

## CI/CD

GitHub Actions workflows run on:
- macOS 14 (Xcode 16.2)
- Ubuntu Latest

All workflows run: `swiftlint --strict`, `pod lib lint --allow-warnings`, `swift build`, `swift test`
