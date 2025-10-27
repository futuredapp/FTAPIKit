import Foundation
import os.log

/// Privacy level for logging sensitive data using OSLogPrivacy
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public enum LogPrivacy: String, CaseIterable {
    /// Logs all data without any masking (not recommended for production)
    case none = "none"
    
    /// Uses OSLogPrivacy.auto for automatic privacy detection
    case auto = "auto"
    
    /// Uses OSLogPrivacy.private for sensitive data
    case `private` = "private"
    
    /// Uses OSLogPrivacy.sensitive for highly sensitive data
    case sensitive = "sensitive"
    
    /// Default privacy level that respects user privacy
    public static let `default`: LogPrivacy = .auto
}
