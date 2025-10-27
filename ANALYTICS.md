# FTAPIKit Analytics

FTAPIKit supports automatic network request and response analytics tracking with privacy-aware data masking.

## Requirements

- iOS 14.0+
- macOS 11.0+
- tvOS 14.0+
- watchOS 7.0+

## Basic Usage

### 1. Server without analytics (existing behavior)

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

### 2. Server with analytics

```swift
struct APIServer: URLServer {
    var baseUri: URL {
        AppConfiguration.current.apiServerUrl
    }
    
    // Add analytics property
    let analytics: AnalyticsProtocol?
    
    init(analytics: AnalyticsProtocol? = nil) {
        self.analytics = analytics
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

### 3. Using with custom analytics implementation

```swift
struct MyAnalytics: AnalyticsProtocol {
    let configuration: AnalyticsConfiguration
    
    func track(_ entry: AnalyticEntry) {
        // Send to your analytics service
        print("Analytics: \(entry.type.rawValue) - \(entry.method ?? "UNKNOWN") \(entry.url ?? "UNKNOWN")")
    }
}

let analytics = MyAnalytics(
    configuration: AnalyticsConfiguration(
        privacy: .auto,
        sensitiveHeaders: ["custom-auth"],
        sensitiveUrlQueries: ["custom_token"],
        sensitiveBodyParams: ["password"]
    )
)

let server = APIServer(analytics: analytics)
```

## Analytics Configuration

### Privacy Levels

```swift
public enum AnalyticsPrivacy: String, Codable, CaseIterable {
    case none = "none"           // No privacy applied, all data is sent
    case auto = "auto"           // Automatically masks sensitive data based on predefined rules
    case `private` = "private"   // Masks all private data
    case sensitive = "sensitive" // Masks all sensitive data
}
```

### Configuration Options

```swift
public struct AnalyticsConfiguration {
    public let privacy: AnalyticsPrivacy
    public let sensitiveHeaders: Set<String>
    public let sensitiveUrlQueries: Set<String>
    public let sensitiveBodyParams: Set<String>
    
    public init(
        privacy: AnalyticsPrivacy,
        sensitiveHeaders: Set<String>,
        sensitiveUrlQueries: Set<String>,
        sensitiveBodyParams: Set<String>
    )
    
    /// Default analytics configuration with sensitive privacy
    public static let `default` = AnalyticsConfiguration(...)
}
```

### Default Sensitive Data Sets

```swift
// Default sensitive headers
public static let defaultSensitiveHeaders: Set<String> = [
    "authorization", "x-api-key", "x-auth-token", "cookie", "set-cookie",
    "x-csrf-token", "x-requested-with", "x-forwarded-for", "x-real-ip"
]

// Default sensitive URL query parameters
public static let defaultSensitiveUrlQueries: Set<String> = [
    "token", "key", "secret", "password", "auth", "access_token", "refresh_token",
    "api_key", "session_id", "csrf_token", "jwt"
]

// Default sensitive body parameters
public static let defaultSensitiveBodyParams: Set<String> = [
    "password", "secret", "token", "key", "auth", "access_token", "refresh_token",
    "api_key", "session_id", "csrf_token", "jwt", "private_key", "client_secret"
]
```

## AnalyticEntry Structure

```swift
public struct AnalyticEntry {
    public enum EntryType: String {
        case request = "request"
        case response = "response"
        case error = "error"
    }

    public let type: EntryType
    public let method: String?
    public let url: String?           // Automatically masked based on privacy settings
    public let headers: [String: String]?  // Automatically masked based on privacy settings
    public let body: Data?            // Automatically masked based on privacy settings
    public let statusCode: Int?
    public let error: String?
    public let timestamp: Date
    public let duration: TimeInterval?
    public let requestId: String
}
```

## Privacy Masking Behavior

### URL Masking
- **`.none`**: No masking applied
- **`.auto`**: Masks only sensitive query parameters
- **`.private/.sensitive`**: Removes all query parameters

### Headers Masking
- **`.none`**: No masking applied
- **`.auto`**: Masks only sensitive headers
- **`.private/.sensitive`**: Masks all header values

### Body Masking
- **`.none`**: No masking applied
- **`.auto`**: Masks sensitive JSON parameters, returns `nil` if not valid JSON
- **`.private/.sensitive`**: Always returns `nil`

## Examples

### Basic Analytics Implementation

```swift
struct BasicAnalytics: AnalyticsProtocol {
    let configuration: AnalyticsConfiguration
    
    func track(_ entry: AnalyticEntry) {
        // Log to console
        print("📊 Analytics: \(entry.type.rawValue.uppercased())")
        print("   Method: \(entry.method ?? "UNKNOWN")")
        print("   URL: \(entry.url ?? "UNKNOWN")")
        print("   Status: \(entry.statusCode?.description ?? "N/A")")
        print("   Duration: \(entry.duration?.description ?? "N/A")s")
        print("   Request ID: \(entry.requestId)")
    }
}

let analytics = BasicAnalytics(configuration: .default)
let server = APIServer(analytics: analytics)
```

### Custom Privacy Configuration

```swift
let customConfig = AnalyticsConfiguration(
    privacy: .auto,
    sensitiveHeaders: ["x-api-key", "authorization", "custom-auth"],
    sensitiveUrlQueries: ["token", "key", "session_id"],
    sensitiveBodyParams: ["password", "secret", "private_key"]
)

let analytics = MyAnalytics(configuration: customConfig)
```

### Analytics with External Service

```swift
struct ExternalAnalytics: AnalyticsProtocol {
    let configuration: AnalyticsConfiguration
    private let analyticsService: AnalyticsService
    
    func track(_ entry: AnalyticEntry) {
        // Convert to your analytics format
        let event = AnalyticsEvent(
            type: entry.type.rawValue,
            method: entry.method,
            url: entry.url,
            statusCode: entry.statusCode,
            duration: entry.duration,
            timestamp: entry.timestamp,
            requestId: entry.requestId
        )
        
        analyticsService.track(event)
    }
}
```

## Integration with Logging

Analytics work alongside logging and can be used together:

```swift
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct APIServer: URLServer {
    let logger: LoggerProtocol?
    let analytics: AnalyticsProtocol?
    
    init(logger: LoggerProtocol? = nil, analytics: AnalyticsProtocol? = nil) {
        self.logger = logger
        self.analytics = analytics
    }
    
    // ... rest of implementation
}

// Usage
let logger = DefaultLogger()
let analytics = MyAnalytics(configuration: .default)
let server = APIServer(logger: logger, analytics: analytics)
```

## Best Practices

1. **Privacy First**: Always use appropriate privacy levels for your use case
2. **Custom Sensitive Data**: Define your own sensitive data sets for your application
3. **Error Handling**: Handle analytics failures gracefully
4. **Performance**: Consider the performance impact of analytics on your app
5. **Compliance**: Ensure your analytics implementation complies with privacy regulations

## Migration from Logging

If you're migrating from logging to analytics:

1. Create your `AnalyticsProtocol` implementation
2. Configure `AnalyticsConfiguration` with appropriate privacy settings
3. Add `analytics` property to your `URLServer` implementation
4. Remove or keep logging alongside analytics as needed

## Troubleshooting

### Common Issues

1. **Analytics not tracking**: Ensure `analytics` property is set on your server
2. **Data not masked**: Check your `AnalyticsConfiguration` privacy settings
3. **Performance issues**: Consider using background queues for analytics processing
4. **Memory leaks**: Ensure proper cleanup of analytics resources

### Debug Mode

Enable debug logging to see what data is being tracked:

```swift
struct DebugAnalytics: AnalyticsProtocol {
    let configuration: AnalyticsConfiguration
    
    func track(_ entry: AnalyticEntry) {
        print("🔍 DEBUG Analytics Entry:")
        print("   Type: \(entry.type)")
        print("   Method: \(entry.method ?? "nil")")
        print("   URL: \(entry.url ?? "nil")")
        print("   Headers: \(entry.headers ?? [:])")
        print("   Body: \(entry.body?.count ?? 0) bytes")
        print("   Status: \(entry.statusCode ?? -1)")
        print("   Duration: \(entry.duration ?? -1)s")
    }
}
```
