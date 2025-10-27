import Foundation

/// Protocol for analytics functionality
public protocol AnalyticsProtocol {
    /// Tracks an analytic entry for analytics
    func track(_ entry: AnalyticEntry)
}
