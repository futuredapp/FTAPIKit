import Foundation

/// Privacy levels for analytics data masking.
///
/// This enum defines the different levels of privacy for analytics data.
/// Each level determines how much information is masked before being sent
/// to the analytics service.
public enum AnalyticsPrivacy {
    /// No privacy masking - all data is preserved.
    /// This should be used only for development and debugging.
    case none
    
    /// Private masking - sensitive data in headers, URL queries and body is masked.
    /// Unmasked exceptions can be specified in ``AnalyticsConfiguration``.
    case `private`
    
    /// Sensitive masking - all user-specific data is masked.
    /// This is the recommended setting for production environments.
    case sensitive
}