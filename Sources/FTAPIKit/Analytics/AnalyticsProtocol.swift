import Foundation

/// Protocol for analytics functionality.
/// 
/// This protocol defines the interface for tracking network requests, responses, and errors
/// for analytics purposes. It provides privacy-aware data tracking with automatic masking
/// of sensitive information.
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
