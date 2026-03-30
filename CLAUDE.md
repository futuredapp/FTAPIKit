# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FTAPIKit is a declarative async/await REST API framework for Swift using Swift Concurrency and Codable. It provides a protocol-oriented approach to defining web services with standard implementation using URLSession and JSON encoder/decoder. The framework is built for Swift 6.1 with full concurrency safety.

**Key Features:**
- Declarative async/await API for defining web services
- Protocol-oriented design with `URLServer` and `Endpoint` protocols
- Multiple endpoint types for different use cases (GET, POST, multipart uploads, etc.)
- Async buildRequest enabling token refresh, dynamic configuration, and rate limiting
- `RequestConfiguring` protocol for per-request configuration at call site
- `NetworkObserver` protocol for request lifecycle monitoring (logging, analytics)
- Swift 6 concurrency safety with Sendable requirements
- Cross-platform support: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+

## Build and Test Commands

### Building
```bash
# Use xcodebuild (preferred, avoids toolchain mismatch issues)
xcodebuild build -scheme FTAPIKit -destination 'platform=macOS'

# Or with Swift CLI
swift build
```

### Running Tests
```bash
# Use xcodebuild
xcodebuild test -scheme FTAPIKit -destination 'platform=macOS'

# Or with Swift CLI
swift test
```

### Linting
```bash
# Run SwiftLint with strict mode
swiftlint --strict
```

The project uses an extensive SwiftLint configuration (`.swiftlint.yml`) with many opt-in rules enabled. Linting must pass with `--strict` flag with zero violations before committing any code.

## Architecture

### Core Protocol Design

The framework is built around two core protocols:

1. **`URLServer` Protocol** - Represents a single web service
   - Defines `baseUri`, `urlSession`, `encoding`/`decoding`, `networkObservers`
   - Builds requests from endpoints via `buildRequest(endpoint:) async throws`
   - Provides default implementations for all properties except `baseUri`
   - Has `ErrorType` associated type (defaults to `APIError.Standard`)

2. **`Endpoint` Protocol** - Represents access points for resources
   - Defines path, headers, query parameters, and HTTP method
   - Multiple specialized variants for different use cases

### Endpoint Type Hierarchy

- **`Endpoint`** - Base protocol with empty body (defaults to GET)
- **`DataEndpoint`** - Sends raw data in body (defaults to POST)
- **`UploadEndpoint`** - Uploads files using URLSession upload (defaults to POST)
- **`MultipartEndpoint`** - Combines body parts into multipart request (defaults to POST)
- **`URLEncodedEndpoint`** - Body in URL query format (defaults to POST)
- **`RequestEndpoint`** - Has encodable request model (defaults to POST)
- **`ResponseEndpoint`** - Has decodable response model
- **`RequestResponseEndpoint`** - Typealias combining request and response endpoints

### Key Architectural Patterns

**URLServer Protocol**: The `URLServer` protocol provides all URLSession-based functionality with default implementations. Only `baseUri` must be provided by conforming types.

**Network Observers**: The `NetworkObserver` protocol provides lifecycle callbacks (`willSendRequest`, `didReceiveResponse`, `didFail`) with type-safe context passing. Observer integration uses `BoundObserverContext` (private) for type erasure.

**Request Configuration**: The `RequestConfiguring` protocol allows per-request async configuration at the call site, separate from server-level `buildRequest`.

**Encoding/Decoding**: The `Encoding` protocol includes `configure(request:)` for setting content-type headers (with empty default). Both `Encoding` and `Decoding` require `Sendable`.

**Swift 6 Concurrency Safety**: All `ResponseEndpoint.Response` and `RequestEndpoint.Request` associated types must conform to `Sendable`.

### Module Organization

**Source Structure** (`Sources/FTAPIKit/`):
- Core protocols: `URLServer.swift`, `Endpoint.swift`
- Request building: `URLRequestBuilder.swift`, `RequestConfiguring.swift`
- Async execution: `URLServer+Async.swift` (includes download)
- Observers: `NetworkObserver.swift`
- Utilities: `Coding.swift`, `URLQuery.swift`, `MultipartFormData.swift`, etc.
- Error handling: `APIError.swift`, `APIError+Standard.swift`

**Test Structure** (`Tests/FTAPIKitTests/`):
- Uses Swift Testing framework (`@Suite`, `@Test`, `#expect`)
- Test files: `AsyncTests.swift`, `AsyncBuildRequestTests.swift`, `URLQueryTests.swift`, `NetworkObserverTests.swift`, `RequestConfiguringTests.swift`, `EndpointTypeTests.swift`, `ErrorHandlingTests.swift`
- Test utilities in `Mockups/`: `Servers.swift`, `Endpoints.swift`, `Models.swift`, `Errors.swift`, `MockNetworkObserver.swift`, `MockTokenManager.swift`, `HTTPBinResponse.swift`

### Call Execution Pattern

The framework uses async/await exclusively:

```swift
// Basic call
let response = try await server.call(response: endpoint)

// Data call (raw Data response)
let data = try await server.call(data: endpoint)

// Void call (no response body)
try await server.call(endpoint: endpoint)

// Download call (temporary file — caller must move before returning)
let fileURL = try await server.download(endpoint: endpoint)

// Download call (moved to destination automatically)
try await server.download(endpoint: endpoint, destination: destinationURL)
```

### Error Handling

- `APIError` protocol defines error handling interface
- Default implementation: `APIError.Standard` (enum with connection, encoding, decoding, server, client, unhandled cases)
- Network errors (`URLError`) and decoding errors are routed through `ErrorType` for consistent error handling
- Encoding errors (from `buildStandardRequest`) propagate directly as `EncodingError` since they occur before the network request
- Custom error types can be defined via `URLServer.ErrorType` associated type

## Package Management

The project uses **Swift Package Manager** exclusively. See `Package.swift`.

### Platform Support

Minimum deployment targets:
- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+

## Testing Approach

Tests use Swift Testing framework and mock servers (HTTPBin-based) defined in `Tests/FTAPIKitTests/Mockups/Servers.swift`:
- `HTTPBinServer` - Standard test server with async authorization support
- `NonExistingServer` - For testing error conditions
- `ErrorThrowingServer` - Custom error type testing
- `HTTPBinServerWithObservers` - Observer integration testing

## CI/CD

Single GitHub Actions workflow (`ci.yml`) runs on `macos-latest`:
- `swiftlint --strict`
- `swift build`
- `swift test`
