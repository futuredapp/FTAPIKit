# FTAPIKit Logging

FTAPIKit now supports automatic network request and response logging using the native `OSLog` system.

## Requirements

- iOS 14.0+
- macOS 11.0+
- tvOS 14.0+
- watchOS 7.0+

## Basic Usage

### 1. Server without logging (existing behavior)

```swift
struct APIServer: URLServer {
    var baseUri: URL {
        AppConfiguration.current.apiServerUrl
    }

    func buildRequest(endpoint: any Endpoint) throws -> URLRequest {
        var request = try buildStandardRequest(endpoint: endpoint)
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        request.setValue("IOS", forHTTPHeaderField: "App-Platform")
        request.setValue(try AppConfigKey.apiKey.value(), forHTTPHeaderField: "X-API-KEY")
        return request
    }
}
```

### 2. Server with logging

```swift
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct APIServer: URLServer {
    var baseUri: URL {
        AppConfiguration.current.apiServerUrl
    }
    
    // Add networkLogger property
    let networkLogger: NetworkLogger?
    
    init(networkLogger: NetworkLogger? = nil) {
        self.networkLogger = networkLogger
    }

    func buildRequest(endpoint: any Endpoint) throws -> URLRequest {
        var request = try buildStandardRequest(endpoint: endpoint)
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        request.setValue("IOS", forHTTPHeaderField: "App-Platform")
        request.setValue(try AppConfigKey.apiKey.value(), forHTTPHeaderField: "X-API-KEY")
        return request
    }
}
```

### 3. Usage with logging

```swift
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class ProductionAPIService: APIService {
    private let server: APIServer

    init(server: APIServer) {
        self.server = server
    }

    func call<EP: Endpoint>(endpoint: EP) async throws(AppError) {
        do {
            try await server.call(endpoint: endpoint)
        } catch {
            throw AppError(error: error)
        }
    }
}

// Create server with logging
let configuration = LoggerConfiguration(
    subsystem: "com.myapp.networking",
    category: "api"
)
let logger = NetworkLogger(configuration: configuration)
let server = APIServer(networkLogger: logger)
let service = ProductionAPIService(server: server)

// All network requests will be automatically logged
try await service.call(endpoint: GetUsersEndpoint())
```

## Logger Structure

FTAPIKit uses an organized logging structure in the `Logger/` directory:

### Files

#### `Logger/LogPrivacy.swift`
- `LogPrivacy` enum with levels: `.none`, `.auto`, `.private`, `.sensitive`
- Maps to native `OSLogPrivacy` system

#### `Logger/LogEntry.swift`
- `LogEntry` struct for analytics callback
- Contains all original data (unmasked)
- Supports request, response and error types

#### `Logger/LoggerConfiguration.swift`
- `LoggerConfiguration` struct with configuration
- Custom data decoder with default implementation
- Pretty JSON formatting with UTF8 fallback

#### `Logger/NetworkLogger.swift`
- `NetworkLogger` struct with `LoggerConfiguration`
- Uses OSLog with privacy settings
- Supports analytics callback

## Configuration

### Basic usage
```swift
let logger = NetworkLogger() // Default configuration
```

### Advanced usage
```swift
let configuration = LoggerConfiguration(
    subsystem: "com.myapp.networking",
    category: "api",
    privacy: .sensitive,
    analyticsCallback: { logEntry in
        AnalyticsService.trackNetworkEvent(logEntry)
    },
    dataDecoder: LoggerConfiguration.defaultDataDecoder
)
let logger = NetworkLogger(configuration: configuration)
```

### Different privacy levels

```swift
// Development - no masking
let devLogger = NetworkLogger(configuration: LoggerConfiguration(privacy: .none))

// Production - automatic masking
let prodLogger = NetworkLogger(configuration: LoggerConfiguration(privacy: .auto))

// High security - sensitive data masked
let secureLogger = NetworkLogger(configuration: LoggerConfiguration(privacy: .sensitive))
```

### Custom data decoder

```swift
let configuration = LoggerConfiguration(
    subsystem: "com.myapp.networking",
    category: "api",
    dataDecoder: LoggerConfiguration.utf8DataDecoder // Simple UTF8 decoding
)
let logger = NetworkLogger(configuration: configuration)
```

### Conditional logging

```swift
#if DEBUG
let configuration = LoggerConfiguration(
    subsystem: "com.myapp.networking", 
    category: "debug",
    privacy: .none
)
let logger = NetworkLogger(configuration: configuration)
let server = APIServer(networkLogger: logger)
#else
let server = APIServer() // No logging in production
#endif
```

## What gets logged

### Request
- HTTP method
- URL
- Headers (with automatic sensitive data masking)
- Body (with automatic sensitive field masking)

### Response
- HTTP status code
- Headers (with automatic sensitive data masking)
- Body (with automatic sensitive field masking)
- Request duration

### Error
- HTTP method and URL
- Error message
- Response data (if available) - useful for debugging decoding issues

## Privacy Levels

Logger uses native `OSLogPrivacy` system:

### `.none` - No masking
- All data is logged without masking
- Suitable only for development
- Uses `OSLogPrivacy.public`

### `.auto` - Automatic masking (default)
- OSLog automatically detects sensitive data
- Suitable for production
- Uses `OSLogPrivacy.auto`

### `.private` - Private data
- Masks all private information
- Suitable for sensitive applications
- Uses `OSLogPrivacy.private`

### `.sensitive` - Sensitive data
- Maximum masking
- Suitable for banking, healthcare
- Uses `OSLogPrivacy.sensitive`

## Analytics Callback

You can add a callback for sending logs to analytics:

```swift
let configuration = LoggerConfiguration(
    analyticsCallback: { logEntry in
        // LogEntry contains all original data (unmasked)
        AnalyticsService.trackNetworkEvent(logEntry)
    }
)
let logger = NetworkLogger(configuration: configuration)
```

## Custom Data Decoding

LoggerConfiguration supports custom Data decoding:

```swift
// Default - pretty JSON with UTF8 fallback
LoggerConfiguration.defaultDataDecoder

// Simple UTF8 decoding
LoggerConfiguration.utf8DataDecoder

// Size only
LoggerConfiguration.sizeOnlyDataDecoder

// Custom decoder
let customDecoder: (Data) -> String? = { data in
    return "Custom: \(data.count) bytes"
}
```

## Analytics Integration Example

```swift
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class NetworkAnalytics {
    static let shared = NetworkAnalytics()
    
    private init() {}
    
    func createLogger() -> NetworkLogger {
        let configuration = LoggerConfiguration(
            subsystem: "com.myapp.networking",
            category: "api",
            privacy: .auto,
            analyticsCallback: { logEntry in
                self.trackNetworkEvent(logEntry)
            }
        )
        return NetworkLogger(configuration: configuration)
    }
    
    private func trackNetworkEvent(_ logEntry: LogEntry) {
        switch logEntry.type {
        case .request:
            trackRequest(logEntry)
        case .response:
            trackResponse(logEntry)
        case .error:
            trackError(logEntry)
        }
    }
    
    private func trackRequest(_ logEntry: LogEntry) {
        // Firebase Analytics
        Analytics.logEvent("network_request", parameters: [
            "method": logEntry.method ?? "unknown",
            "url": logEntry.url ?? "unknown",
            "request_id": logEntry.requestId
        ])
    }
    
    private func trackResponse(_ logEntry: LogEntry) {
        guard let statusCode = logEntry.statusCode else { return }
        
        // Performance monitoring
        PerformanceMonitor.recordNetworkCall(
            duration: logEntry.duration ?? 0,
            statusCode: statusCode,
            endpoint: extractEndpoint(from: logEntry.url)
        )
    }
    
    private func trackError(_ logEntry: LogEntry) {
        // Error tracking with response data for debugging
        ErrorTracker.trackNetworkError(
            method: logEntry.method,
            url: logEntry.url,
            error: logEntry.error,
            responseData: logEntry.body, // Contains decoded response data
            requestId: logEntry.requestId
        )
    }
    
    private func extractEndpoint(from url: String?) -> String {
        guard let url = url,
              let urlComponents = URLComponents(string: url),
              let path = urlComponents.path else {
            return "unknown"
        }
        return path
    }
}
```

## Log Output Example

With `privacy: .auto` (default):
```
[REQUEST] [A1B2C3D4] GET https://api.example.com/users Headers: ["Content-Type": "application/json", "Authorization": "***"] Body: {"username": "user", "password": "***"}

[RESPONSE] [A1B2C3D4] GET https://api.example.com/users 200 (245.67ms) Headers: ["Content-Type": "application/json"] Body: {"users": [...]}
```

With `privacy: .sensitive`:
```
[REQUEST] [A1B2C3D4] GET *** Headers: *** Body: ***

[RESPONSE] [A1B2C3D4] GET *** 200 (245.67ms) Headers: *** Body: ***

[ERROR] [A1B2C3D4] POST https://api.example.com/users ERROR: Decoding error Data: {"error": "Invalid JSON structure"}
```

## Benefits

1. **Better organization** - Each type has its own file
2. **Flexible configuration** - `LoggerConfiguration` struct
3. **Custom data decoding** - Pretty JSON with UTF8 fallback
4. **Simple configuration** - One way to set up
5. **Native OSLogPrivacy** - Automatic sensitive data masking
6. **Analytics support** - `LogEntry` contains original data

## Compatibility

- ✅ Existing code works without changes (if not using logging)
- ✅ Logging is optional
- ✅ Uses native OSLog system with OSLogPrivacy
- ✅ Automatic sensitive data masking
- ✅ Analytics callback for extension
- ✅ Custom data decoding with pretty JSON
- ✅ Available only on supported platforms
