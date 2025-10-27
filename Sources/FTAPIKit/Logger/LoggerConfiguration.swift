import Foundation

/// Configuration for the network logger
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct LoggerConfiguration {
    public let subsystem: String
    public let category: String
    public let privacy: LogPrivacy
    public let dataDecoder: (Data) -> String?
    
    public init(
        subsystem: String = "com.ftapikit.networking",
        category: String = "requests",
        privacy: LogPrivacy = .default,
        dataDecoder: @escaping (Data) -> String? = LoggerConfiguration.defaultDataDecoder
    ) {
        self.subsystem = subsystem
        self.category = category
        self.privacy = privacy
        self.dataDecoder = dataDecoder
    }
    
    /// Default data decoder that tries to format as pretty JSON with UTF8 fallback
    public static func defaultDataDecoder(_ data: Data) -> String? {
        // Try to decode as JSON and pretty print it
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
           let prettyJSON = String(data: prettyData, encoding: .utf8) {
            return prettyJSON
        }
        
        // Fallback to UTF8 string
        return String(data: data, encoding: .utf8)
    }
    
    /// Simple UTF8 decoder (no JSON formatting)
    public static func utf8DataDecoder(_ data: Data) -> String? {
        return String(data: data, encoding: .utf8)
    }
    
    /// Custom decoder that only shows data size
    public static func sizeOnlyDataDecoder(_ data: Data) -> String? {
        return "<\(data.count) bytes>"
    }
    
}
