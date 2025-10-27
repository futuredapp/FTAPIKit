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
    
    // Add logger property
    let logger: LoggerProtocol?
    
    init(logger: LoggerProtocol? = nil) {
        self.logger = logger
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
let logger = DefaultLogger(configuration: configuration)
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
- `LogEntry` struct - pure data container
- No business logic, just data storage
- Used by both logging and analytics

#### `Logger/LoggerConfiguration.swift`
- `LoggerConfiguration` struct for logging only
- OSLog subsystem, category, privacy settings
- Data decoder for logging (no masking)

#### `Logger/DefaultLogger.swift`
- `DefaultLogger` struct with `LoggerConfiguration`
- Uses OSLog with privacy settings
- Pure logging functionality (no analytics)

#### `Logger/AnalyticsProtocol.swift`
- `AnalyticsProtocol` for analytics functionality
- Single `track(_ entry: LogEntry)` method

#### `Logger/DefaultAnalytics.swift`
- `DefaultAnalytics` struct with `AnalyticsConfiguration`
- Applies privacy masking before callback

#### `Logger/NoOpAnalytics.swift`
- `NoOpAnalytics` for testing or disabling analytics

#### `Logger/AnalyticsConfiguration.swift`
- `AnalyticsConfiguration` struct for analytics setup
- Privacy masking logic for analytics
- Clean separation from logging concerns

## Configuration

### Basic usage
```swift
let logger = DefaultLogger() // Default configuration
```

### Advanced usage
```swift
let analyticsConfig = AnalyticsConfiguration(
    callback: { logEntry in
        AnalyticsService.trackNetworkEvent(logEntry)
    },
    privacy: .sensitive // Analytics gets masked data
)
let analytics = analyticsConfig.createAnalytics()

let configuration = LoggerConfiguration(
    subsystem: "com.myapp.networking",
    category: "api",
    privacy: .auto,
    analytics: analytics
)
let logger = DefaultLogger(configuration: configuration)
```

### Different privacy levels

```swift
// Development - no masking
let devLogger = DefaultLogger(configuration: LoggerConfiguration(privacy: .none))

// Production - automatic masking
let prodLogger = DefaultLogger(configuration: LoggerConfiguration(privacy: .auto))

// High security - sensitive data masked
let secureLogger = DefaultLogger(configuration: LoggerConfiguration(privacy: .sensitive))
```

### Analytics usage

```swift
// Basic analytics
let analyticsConfig = AnalyticsConfiguration(
    callback: { logEntry in
        print("Analytics: \(logEntry.type) - \(logEntry.method ?? "UNKNOWN")")
    }
)
let analytics = analyticsConfig.createAnalytics()

// Custom analytics implementation
struct CustomAnalytics: AnalyticsProtocol {
    func track(_ entry: LogEntry) {
        // Custom tracking logic
        MyAnalyticsService.track(entry)
    }
}

// No-op analytics for testing
let noOpAnalytics = NoOpAnalytics()
```

### Custom data decoder

```swift
let configuration = LoggerConfiguration(
    subsystem: "com.myapp.networking",
    category: "api",
    dataDecoder: LoggerConfiguration.utf8DataDecoder // Simple UTF8 decoding
)
let logger = DefaultLogger(configuration: configuration)
```

### Conditional logging

```swift
#if DEBUG
let configuration = LoggerConfiguration(
    subsystem: "com.myapp.networking", 
    category: "debug",
    privacy: .none
)
let logger = DefaultLogger(configuration: configuration)
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

### OSLog Privacy (Console Logs)
- **`.none`** - No privacy masking (public data)
- **`.auto`** - Automatic sensitive data detection and masking
- **`.private`** - All data masked
- **`.sensitive`** - All data masked (same as private)

### Analytics Callback Privacy (LogEntry)
The `LogEntry` sent to analytics callbacks **automatically respects privacy settings**:

- **`.none`** - Original data sent to callback
- **`.auto`** - Sensitive fields masked in callback
- **`.private/.sensitive`** - All sensitive data masked in callback

This prevents sensitive data from being accidentally sent to analytics services.

## Analytics Callback

You can add a callback for sending logs to analytics:

```swift
let configuration = LoggerConfiguration(
    analyticsCallback: { logEntry in
        // LogEntry contains all original data (unmasked)
        AnalyticsService.trackNetworkEvent(logEntry)
    }
)
let logger = DefaultLogger(configuration: configuration)
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
        // Note: logEntry.body is already privacy-masked based on logger configuration
        ErrorTracker.trackNetworkError(
            method: logEntry.method,
            url: logEntry.url, // May be masked if privacy is .private/.sensitive
            error: logEntry.error,
            responseData: logEntry.body, // Already masked based on privacy settings
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

### Analytics Callback Privacy Example

**With `privacy: .none`:**
```swift
// LogEntry sent to callback contains original data:
LogEntry(
    url: "https://api.example.com/users?token=secret123",
    headers: ["Authorization": "Bearer token123"],
    body: "{\"password\": \"secret123\"}"
)
```

**With `privacy: .sensitive`:**
```swift
// LogEntry sent to callback contains masked data:
LogEntry(
    url: "https://api.example.com/users", // Query params removed
    headers: ["Authorization": "***", "Content-Type": "***"], // All values masked
    body: "***" // Entire body masked
)
```

## Benefits

1. **Better organization** - Each type has its own file
2. **Flexible configuration** - `LoggerConfiguration` struct
3. **Custom data decoding** - Pretty JSON with UTF8 fallback
4. **Simple configuration** - One way to set up
5. **Native OSLogPrivacy** - Automatic sensitive data masking
6. **Analytics support** - `LogEntry` contains privacy-aware data
7. **Unified message building** - Single `buildMessage()` function for all log types
8. **Cleaner code** - Internal functions instead of static methods

## Compatibility

- ✅ Existing code works without changes (if not using logging)
- ✅ Logging is optional
- ✅ Uses native OSLog system with OSLogPrivacy
- ✅ Automatic sensitive data masking
- ✅ Analytics callback for extension
- ✅ Custom data decoding with pretty JSON
- ✅ Available only on supported platforms
