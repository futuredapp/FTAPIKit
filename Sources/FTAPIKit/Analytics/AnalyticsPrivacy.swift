import Foundation

/// Privacy levels for analytics data masking
public enum AnalyticsPrivacy {
    /// No privacy masking - all data is preserved
    case none
    
    /// Automatic masking - only sensitive headers are masked
    case auto
    
    /// Private masking - all headers are masked
    case `private`
    
    /// Sensitive masking - URLs and headers are masked
    case sensitive
}
