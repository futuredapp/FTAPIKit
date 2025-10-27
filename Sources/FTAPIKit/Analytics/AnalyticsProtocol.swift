import Foundation

/// Protocol for analytics functionality
public protocol AnalyticsProtocol {
    /// Configuration for analytics privacy and masking
    var configuration: AnalyticsConfiguration { get }
    
    /// Tracks an analytic entry for analytics
    func track(_ entry: AnalyticEntry)
}
