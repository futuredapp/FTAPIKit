import Foundation

/// Protocol for configuring URLRequest before execution.
/// Implementations can perform async operations like token refresh.
///
/// Use this protocol to add authorization headers, modify requests, or perform
/// any async configuration needed before the request is sent.
///
/// Example:
/// ```swift
/// struct AuthorizedConfiguration: RequestConfiguring {
///     let authService: AuthService
///
///     func configure(_ request: inout URLRequest) async throws {
///         let token = try await authService.getValidAccessToken()
///         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
///     }
/// }
/// ```
public protocol RequestConfiguring: Sendable {
    /// Configures the request before it is sent.
    /// - Parameter request: The URLRequest to configure
    /// - Throws: Any error that occurs during configuration (e.g., token refresh failure)
    func configure(_ request: inout URLRequest) async throws
}
