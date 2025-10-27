import Foundation

/// A no-operation analytics that conforms to AnalyticsProtocol but does nothing.
/// Useful for testing or disabling analytics in certain environments.
public struct NoOpAnalytics: AnalyticsProtocol {
    public init() {}
    public func track(_ entry: AnalyticEntry) {
        // Do nothing
    }
}
