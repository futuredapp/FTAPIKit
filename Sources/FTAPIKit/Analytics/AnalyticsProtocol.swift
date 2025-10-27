import Foundation

/// Protocol for analytics functionality.
/// 
/// This protocol defines the interface for tracking network requests, responses, and errors
/// for analytics purposes. It provides privacy-aware data tracking with automatic masking
/// of sensitive information.
/// 
/// ## Requirements
/// 
/// - iOS 9.0+
/// - macOS 10.10+
/// - tvOS 9.0+
/// - watchOS 2.0+
/// 
/// ## Usage
/// 
/// ```swift
/// struct CustomAnalytics: AnalyticsProtocol {
///     let configuration: AnalyticsConfiguration
///     
///     func track(_ entry: AnalyticEntry) {
///         // Send to your analytics service
///         AnalyticsService.track(
///             event: entry.type.rawValue,
///             properties: [
///                 "method": entry.method,
///                 "url": entry.url,
///                 "statusCode": entry.statusCode ?? 0
///             ]
///         )
///     }
/// }
/// 
/// let analytics = CustomAnalytics(configuration: .default)
/// ```
/// 
/// - Note: The ``AnalyticEntry`` passed to the `track` method contains privacy-masked data
/// based on the configured privacy level and sensitive data sets.
public protocol AnalyticsProtocol {
    /// Configuration for analytics privacy and masking.
    /// 
    /// This configuration determines how sensitive data is masked before being sent
    /// to the analytics service.
    var configuration: AnalyticsConfiguration { get }
    
    /// Tracks an analytic entry for analytics.
    /// 
    /// This method is called automatically by ``URLServer`` implementations
    /// for all network requests, responses, and errors. The entry contains
    /// privacy-masked data based on the configuration.
    /// 
    /// - Parameter entry: The analytic entry containing network activity data
    func track(_ entry: AnalyticEntry)
}
