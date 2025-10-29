import Foundation

#if canImport(os.log)
import os.log
#endif

/// Configuration for the network logger
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct LoggerConfiguration {
    internal let subsystem: String
    internal let category: String
    internal let privacy: LogPrivacy
    internal let dataDecoder: (Data) -> String?
    
    #if canImport(os.log)
    internal let logger: os.Logger
    #endif
    
    public init(
        subsystem: String = "com.ftapikit.networking",
        category: String = "networking",
        privacy: LogPrivacy = .default,
        dataDecoder: @escaping (Data) -> String? = LoggerConfiguration.defaultDataDecoder
    ) {
        self.subsystem = subsystem
        self.category = category
        self.privacy = privacy
        self.dataDecoder = dataDecoder
        
        #if canImport(os.log)
        self.logger = os.Logger(subsystem: subsystem, category: category)
        #endif
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
